**FREE
//- Copyright (c) 2018 - 2021 Christian Brunner
//-
//- Permission is hereby granted, free of charge, to any person obtaining a copy
//- of this software and associated documentation files (the "Software"), to deal
//- in the Software without restriction, including without limitation the rights
//- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//- copies of the Software, and to permit persons to whom the Software is
//- furnished to do so, subject to the following conditions:

//- The above copyright notice and this permission notice shall be included in all
//- copies or substantial portions of the Software.

//- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//- SOFTWARE.

//  Created by BRC on 25.07.2018 - 29.05.2019

// Socketclient to send objects over tls to another IBMi


// Changes:
//  23.10.2019  Cosmetic changes
//  30.10.2019  Editwords and other small changes
//  19.11.2019  Add member-support
//  23.02.2021  Add option for client-certification
//  22.09.2021  Change SOCKET_H to free
//  22.09.2021  Move the most procedures to a new serviceprogram


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main) BNDDIR('ZSERVICE');


DCL-PR Main EXTPGM('ZSERVERRG');
  Port UNS(5) CONST;
  UseTLS IND CONST;
  AppID CHAR(32) CONST;
  Authentication CHAR(12) CONST;
END-PR;


/INCLUDE QRPGLEH,Z_H


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pAppID CHAR(32) CONST;
   pAuthentication CHAR(12) CONST;
 END-PI;

 DCL-S UseTLS IND INZ(FALSE);
 DCL-S ConnectFrom POINTER;

 DCL-DS Socket LIKEDS(SocketServer_T) INZ;
 DCL-DS GSK LIKEDS(GSK_T) INZ;
 DCL-DS Lingering LIKEDS(Lingering_T) INZ;
 //-------------------------------------------------------------------------

 *INLR = TRUE;
 UseTLS = pUseTLS;

 makeListenerServer(pPort :UseTLS :pAppID :(pAuthentication = '*USRPRF_CERT')
                   :ConnectFrom :Socket :GSK :Lingering);

 DoU doShutDown(UseTLS :Socket :GSK);

   acceptConnectionServer(UseTLS :ConnectFrom :Socket :GSK :Lingering);

   Monitor;
     handleClient(UseTLS :pAuthentication :Socket :GSK);
     On-Error;
   EndMon;

   cleanTempServer(P_FILE);
   cleanUpSocket(UseTLS :Socket.Talk :GSK.SecureHandler);

 EndDo;

END-PROC;

//**************************************************************************
DCL-PROC handleClient;
 DCL-PI *N;
   pUseTLS IND CONST;
   pAuthentication CHAR(12) CONST;
   pSocket LIKEDS(SocketServer_T) CONST;
   pGSK LIKEDS(GSK_T);
 END-PI;

/INCLUDE QRPGLECPY,SETUSR_H

 DCL-S Loop IND INZ(TRUE);
 DCL-S RestoreSuccess IND INZ(TRUE);
 DCL-S RC INT(10) INZ;
 DCL-S OriginalUser CHAR(10) INZ;
 DCL-S Data CHAR(1024) INZ;
 DCL-S Work CHAR(1024) INZ;
 DCL-S RestoreCommand CHAR(1024) INZ;

 DCL-DS RetrievingFile QUALIFIED INZ;
   FileHandler INT(10);
   Length INT(10);
   Data CHAR(32766);
   Bytes UNS(20);
 END-DS;

 DCL-DS RestoreMember QUALIFIED;
   ModeMember IND INZ(FALSE);
   ObjectLibrary CHAR(10) INZ;
   ObjectName CHAR(10) INZ;
 END-DS;

 DCL-DS RTVM0100 LIKEDS(RTVM0100_T);
 DCL-DS ErrorDS LIKEDS(Error_T);
 //-------------------------------------------------------------------------

 // Check protocoll and session
 RC = receiveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
 If ( RC <= 0 ) Or ( Data = '' );
   Data = '*UNKNOWNPROTOCOLL>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Unknown protocoll from address "' + %TrimR(pSocket.ClientIP) + '" passed');
   Return;
 EndIf;

 If ( %SubSt(Data :1 :6) = '*ZZv1>' );
   Work = %SubSt(Data :7 :10);
   Data = '*OK>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Session "' + %TrimR(Work) + '" from address "' + %TrimR(pSocket.ClientIP) +
              '" connected');
 Else;
   Data = '*UNKNOWNPROTOCOLL>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Unknown protocoll from address "' + %TrimR(pSocket.ClientIP) + '" passed');
   Return;
 EndIf;

 // User and password receive and check / change to called user when authentication is *USRPRF
 If ( %SubSt(pAuthentication :1 :7) = '*USRPRF' );
   RC = receiveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 ) Or ( Data = '' );
     Data = '*NOLOGINDATA>';
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     sendJobLog('+> No userinformations passed. End connection with client.');
     Return;
   EndIf;

   If ( Data = '*AUTH_NONE>' );
     Data = '*NONONEALLOWED>';
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     sendJobLog('+> No anonymous login allowed. End connection with client.');
     Return;
   EndIf;

   Reset Key;
   SwitchUserProfile.NewUser = %SubSt(Data :1 :10);
   Work = %SubSt(Data :11 :1000);
   Exec SQL SET :SwitchUserProfile.Password = DECRYPT_BIT(BINARY(RTRIM(:Work)), :Key);
   Clear Key;
   If ( SQLCode <> 0 );
     Exec SQL GET DIAGNOSTICS CONDITION 1 :Work = MESSAGE_TEXT;
     Data = '*NOPWD>' + %TrimR(Work);
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%TrimR(Data)));
     sendJobLog('+> Password decryption failed for user "' + %TrimR(SwitchUserProfile.NewUser) +
                '": ' + %TrimR(Work) + ' End connection with client.');
     Return;
   EndIf;

   OriginalUser = PSDS.UserName;
   QSYGETPH(SwitchUserProfile.NewUser :SwitchUserProfile.Password :SwitchUserProfile.UserHandler
               :ErrorDS :%Len(%TrimR(SwitchUserProfile.Password)) :0);
   Clear SwitchUserProfile.Password;
   If ( ErrorDS.NbrBytesAvl > 0 );
     Work = ErrorDS.MessageID;
     retrieveMessageData(RTVM0100 :%Size(RTVM0100) :'RTVM0100' :ErrorDS.MessageID :CPFMSG
                         :ErrorDS.MessageData :%Len(%TrimR(ErrorDS.MessageData))
                         :'*YES' :'*NO' :ErrorDS);
     If ( RTVM0100.MessageAndHelp <> '' );
       Data = %SubSt(RTVM0100.MessageAndHelp :1 :RTVM0100.BytesMessageReturn);
     Else;
       Data = Work;
     EndIf;
     Work = Data;
     Data = '*NOACCESS>' + %TrimR(Data);
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     sendJobLog('+> Login failed for user "' + %TrimR(SwitchUserProfile.NewUser) + '": ' +
                 %TrimR(Work) + ' End connection with client.');
     Return;
   EndIf;

   QWTSETP(SwitchUserProfile.UserHandler :ErrorDS);
   If ( ErrorDS.NbrBytesAvl > 0 );
     Work = ErrorDS.MessageID;
     retrieveMessageData(RTVM0100 :%Size(RTVM0100) :'RTVM0100' :ErrorDS.MessageID :CPFMSG
                         :ErrorDS.MessageData :%Len(%TrimR(ErrorDS.MessageData))
                         :'*YES' :'*NO' :ErrorDS);
     If ( RTVM0100.MessageAndHelp <> '' );
       Data = %SubSt(RTVM0100.MessageAndHelp :1 :RTVM0100.BytesMessageReturn);
     Else;
       Data = Work;
     EndIf;
     Work = Data;
     Data = '*NOACCESS>' + Data;
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     sendJobLog('+> No access for user "' + %TrimR(SwitchUserProfile.NewUser) + '": ' +
                 %TrimR(Work) + ' End connection with client.');
     Return;
   EndIf;

   // Login completed
   Data = '*OK>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Login for user "' + %TrimR(SwitchUserProfile.NewUser) + '" was successfull');
 Else;
   RC = receiveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
   Data = '*OK>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Anonymous connected');
 EndIf;

 // Handle incomming file- and restore informations
 receiveData(pUseTLS :pSocket :pGSK :%Addr(RestoreCommand) :%Size(RestoreCommand));
 If ( %SubSt(RestoreCommand :1 :3) <> 'RST' ) And ( %SubSt(RestoreCommand :1 :3) <> 'MBR' );
   Data = '*NORESTORE>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Invalid restorecommand received. End connection with client');
   Return;
 Else;
   Data = '*OK>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
 EndIf;

 // Handle incomming data
 sendJobLog('+> Waiting for incomming data');
 RetrievingFile.FileHandler = ifsOpen(P_FILE :O_WRONLY + O_TRUNC + O_CREATE + O_LARGEFILE
                              :S_IRWXU + S_IRWXG + S_IRWXO);

 Reset RetrievingFile.Bytes;

 DoW ( Loop ) And ( RetrievingFile.FileHandler >= 0 );
   RetrievingFile.Length = receiveData(pUseTLS :pSocket :pGSK
                                       :%Addr(RetrievingFile.Data) :%Size(RetrievingFile.Data));
   If ( RetrievingFile.Length <= 0 );
     ifsClose(RetrievingFile.FileHandler);
     Leave;
   EndIf;

   RetrievingFile.Bytes += RetrievingFile.Length;

   If ( %Scan('*EOF>' :RetrievingFile.Data) > 0 );
     RetrievingFile.Data = %SubSt(RetrievingFile.Data :1 :%Scan('*EOF>' :RetrievingFile.Data) - 1);
     ifsWrite(RetrievingFile.FileHandler :%Addr(RetrievingFile.Data) :RetrievingFile.Length - 5);
     ifsClose(RetrievingFile.FileHandler);
     Leave;
   Else;
     ifsWrite(RetrievingFile.FileHandler :%Addr(RetrievingFile.Data) :RetrievingFile.Length);
     Clear RetrievingFile.Data;
   EndIf;
 EndDo;

 sendJobLog('+> ' + %Trim(%EditW(%DecH(RetrievingFile.Bytes/1024 :17 :2) :EDTW172)) +
            ' KB received');

 sendJobLog('+> Manage received savefile');

 Data = '*OK>';
 Monitor;
   manageSavefile(P_SAVE :P_FILE :SAVF_MODE_FROM_FILE :RestoreSuccess);
   On-Error;
     RestoreSuccess = FALSE;
 EndMon;

 If Not RestoreSuccess;
   Data = '*ERROR_RESTORE> Error occured while writing to savefile';
 Else;
   RestoreMember.ModeMember = ( %SubSt(RestoreCommand :1 :3) = 'MBR' );
   If RestoreMember.ModeMember;
     RestoreMember.ObjectLibrary = %SubSt(RestoreCommand :4 :10);
     RestoreMember.ObjectName = %SubSt(RestoreCommand :14 :10);
     RestoreCommand = %SubSt(RestoreCommand :24 :1000);
   EndIf;
   sendJobLog('+> Try to restore: ' + %TrimR(RestoreCommand));
   If ( system(RestoreCommand) <> 0 );
     Data = '*ERROR_RESTORE> ' + %Str(strError(ErrNo));
     RestoreSuccess = FALSE;
   EndIf;
 EndIf;
 If RestoreMember.ModeMember;
   sendJobLog('+> Copy member');
   RC = system('CPYF FROMFILE(QTEMP/' + %TrimR(RestoreMember.ObjectName) +
               ') TOFILE(' + %TrimR(RestoreMember.ObjectLibrary) + '/' +
               %TrimR(RestoreMember.ObjectName) +
               ') FROMMBR(*ALL) TOMBR(*FROMMBR) MBROPT(*REPLACE)');
   If ( RC <> 0 );
     Data = '*ERROR_RESTORE> ' + %Str(strError(ErrNo));
     RestoreSuccess = FALSE;
   EndIf;
 EndIf;
 sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));

 If RestoreSuccess;
   sendJobLog('+> Restore was successfull, end connection with client');
 Else;
   sendJobLog('+> Restore was not successfull, end connection with client');
 EndIf;

 // Switch back to original userprofile when authentication is *USRPRF
 If ( %SubSt(pAuthentication :1 :7) = '*USRPRF' );
   QSYGETPH(OriginalUser :'*NOPWD' :SwitchUserProfile.UserHandler :ErrorDS);
   QWTSETP(SwitchUserProfile.UserHandler :ErrorDS);
 EndIf;

 Return;

END-PROC;


/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
