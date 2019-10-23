**FREE
//- Copyright (c) 2018, 2019 Christian Brunner
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
//   I use the socket_h header from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


// Changes:
//  23.10.2019  Cosmetic changes


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);


DCL-PR Main EXTPGM('ZSERVERRG');
  Port UNS(5) CONST;
  UseTLS IND CONST;
  AppID CHAR(32) CONST;
  Authentication CHAR(7) CONST;
END-PR;

/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,IFS_H
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,QMHRTVM
/INCLUDE QRPGLECPY,SYSTEM
/INCLUDE QRPGLECPY,ERRNO_H

/INCLUDE QRPGLECPY,PSDS
/INCLUDE QRPGLECPY,BOOLIC

/DEFINE IS_ZSERVER
/INCLUDE QRPGLECPY,Z_H

DCL-C P_SAVE '/QSYS.LIB/QTEMP.LIB/RCV.FILE';
DCL-C P_FILE '/tmp/rcv.file';


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pAppID CHAR(32) CONST;
   pAuthentication CHAR(7) CONST;
 END-PI;

 DCL-S UseTLS IND INZ(FALSE);
 DCL-S ConnectFrom POINTER;

 DCL-DS Socket LIKEDS(Socket_T) INZ;
 DCL-DS GSK LIKEDS(GSK_T) INZ;
 DCL-DS Lingering LIKEDS(Lingering_T) INZ;
 //-------------------------------------------------------------------------

 *INLR = TRUE;
 UseTLS = pUseTLS;

 makeListener(pPort :UseTLS :pAppID :ConnectFrom :Socket :GSK :Lingering);

 DoU doShutDown(UseTLS :Socket :GSK);

   acceptConnection(UseTLS :ConnectFrom :Socket :GSK :Lingering);

   Monitor;
     handleClient(UseTLS :pAuthentication :Socket :GSK);
     On-Error;
   EndMon;

   cleanTemp();
   cleanUp_Socket(UseTLS :Socket.Talk :GSK.SecureHandler);

 EndDo;

END-PROC;

//**************************************************************************
DCL-PROC doShutDown;
 DCL-PI *N IND;
   pUseTLS IND CONST;
   pSocket LIKEDS(Socket_T) CONST;
   pGSK LIKEDS(GSK_T);
 END-PI;

 DCL-S ShutDown IND INZ(FALSE);
 //-------------------------------------------------------------------------

 If ( %ShtDn() );
   ShutDown = TRUE;
   cleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
 EndIf;

 Return ShutDown;

END-PROC;

//**************************************************************************
DCL-PROC makeListener;
 DCL-PI *N;
   pPort UNS(5) CONST;
   pUseTLS IND;
   pAppID CHAR(32) CONST;
   pConnectFrom POINTER;
   pSocket LIKEDS(Socket_T);
   pGSK LIKEDS(GSK_T);
   pLingering LIKEDS(Lingering_T);
 END-PI;

 DCL-S BindTo POINTER;
 DCL-S Length INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 DCL-S SockOptON IND INZ(TRUE);
 //-------------------------------------------------------------------------

 If pUseTLS;
   pUseTLS = generateGSKEnvironment(pGSK :pAppID);
   If Not pUseTLS;
     SendJobLog('+> Server was not able to generate gsk-environment. Continue without tls');
   EndIf;
 EndIf;

 Length = %Size(SockAddr_In);
 BindTo = %Alloc(Length);
 pConnectFrom = %Alloc(Length);

 pSocket.Listener = socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( pSocket.Listener < 0 );
   cleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   sendDie('socket(): ' + %Str(strError(ErrNo)));
 EndIf;

 setSockOpt(pSocket.Listener :SOL_SOCKET :SO_REUSEADDR :%Addr(SockOptON) :%Size(SockOptON));

 pLingering.Length = %Size(Linger);
 pLingering.LingerHandler = %Alloc(pLingering.Length);
 p_Linger = pLingering.LingerHandler;
 l_OnOff = 1;
 l_Linger = 1;
 setSockOpt(pSocket.Listener :SOL_SOCKET :SO_LINGER :pLingering.LingerHandler :pLingering.Length);

 p_SockAddr = BindTo;
 Sin_Family = AF_INET;
 Sin_Addr = INADDR_ANY;
 Sin_Port = pPort;
 Sin_Zero = *ALLx'00';

 If ( bind(pSocket.Listener :BindTo :Length) < 0 );
   ErrorNumber = ErrNo;
   cleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   sendDie('bind(): ' + %Str(strError(ErrorNumber)));
 EndIf;

 If ( listen(pSocket.Listener :5) < 0 );
   ErrorNumber = ErrNo;
   cleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   sendDie('listen(): ' + %Str(strError(ErrorNumber)));
 EndIf;

 sendJobLog('+> Server is now running on port ' + %Char(pPort) + ' and ready for connections');

END-PROC;

//**************************************************************************
DCL-PROC acceptConnection;
 DCL-PI *N;
   pUseTLS IND CONST;
   pConnectFrom POINTER CONST;
   pSocket LIKEDS(Socket_T);
   pGSK LIKEDS(GSK_T);
   pLingering LIKEDS(Lingering_T);
 END-PI;

 DCL-S Length INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 //-------------------------------------------------------------------------

 DoU ( Length = %Size(SockAddr_In) );

   Length = %Size(SockAddr_In);
   pSocket.Talk  = accept(pSocket.Listener :pConnectFrom :Length);
   If ( pSocket.Talk < 0 );
     sendJobLog('accept(): ' + %Str(strError(ErrNo)));
     cleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

   l_OnOff  = 1;
   l_Linger = 10;
   setSockOpt(pSocket.Talk :SOL_SOCKET :SO_LINGER :pLingering.LingerHandler :pLingering.Length);

   If ( Length <> %Size(SockAddr_In));
     cleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

 EndDo;

 If pUseTLS;
   If ( gsk_Secure_Soc_Open(pGSK.Environment: pGSK.SecureHandler) <> GSK_OK );
     ErrorNumber = ErrNo;
     cleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     sendJobLog('gsk_Secure_Soc_Open(): ' + %Str(gsk_StrError(ErrorNumber)));
   EndIf;
   If ( gsk_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_FD :pSocket.Talk) <> GSK_OK );
     ErrorNumber = ErrNo;
     cleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     sendJobLog('gsk_Attribute_Set_Numeric_Value(): ' + %Str(gsk_StrError(ErrorNumber)));
   EndIf;
   If ( gsk_Secure_Soc_Init(pGSK.SecureHandler) <> GSK_OK );
     ErrorNumber = ErrNo;
     cleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     sendJobLog('gsk_Secure_Soc_Init(): ' + %Str(gsk_StrError(ErrorNumber)));
   EndIf;
 EndIf;

 P_SockAddr = pConnectFrom;
 pSocket.ClientIP = %Str(inet_NTOA(Sin_Addr));

END-PROC;

//**************************************************************************
DCL-PROC handleClient;
 DCL-PI *N;
   pUseTLS IND CONST;
   pAuthentication CHAR(7) CONST;
   pSocket LIKEDS(Socket_T) CONST;
   pGSK LIKEDS(GSK_T);
 END-PI;

 DCL-PR manageSavefile EXTPGM('ZSERVERCL');
   Success CHAR(1);
   Save CHAR(64) CONST;
   File CHAR(64) CONST;
 END-PR;

/INCLUDE QRPGLECPY,SETUSR_H

 DCL-S KEY CHAR(40) INZ('yourkey');

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

 DCL-DS RTVM0100 LIKEDS(RTVM0100_T);
 DCL-DS ErrorDS LIKEDS(Error_T);
 //-------------------------------------------------------------------------

 // Check protocoll and session
 RC = recieveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
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

 // User and password recieve and check / change to called user when authentication is *USRPRF
 If ( pAuthentication = '*USRPRF' );
   RC = recieveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 ) Or ( Data = '' );
     Data = '*NOLOGINDATA>';
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     sendJobLog('+> No userinformations passed');
     Return;
   EndIf;

   If ( Data = '*AUTH_NONE>' );
     Data = '*NONONEALLOWED>';
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     sendJobLog('+> No anonymous login allowed');
     Return;
   EndIf;

   SwitchUserProfile.NewUser = %SubSt(Data :1 :10);
   Work = %SubSt(Data :11 :1000);
   Exec SQL SET :SwitchUserProfile.Password = DECRYPT_BIT(BINARY(RTRIM(:Work)), :Key);
   Clear Key;
   If ( SQLCode <> 0 );
     Exec SQL GET DIAGNOSTICS CONDITION 1 :Work = MESSAGE_TEXT;
     Data = '*NOPWD>' + %TrimR(Work);
     sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%TrimR(Data)));
     sendJobLog('+> Password decryption failed for user "' + %TrimR(SwitchUserProfile.NewUser) +
                '": ' + %TrimR(Work));
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
     sendJobLog('+> Login failed for user "' + %TrimR(SwitchUserProfile.NewUser) + '": ' + Work);
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
     sendJobLog('+> No access for user "' + %TrimR(SwitchUserProfile.NewUser) + '": ' + Work);
     Return;
   EndIf;

   // Login completed
   Data = '*OK>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Login for user "' + %TrimR(SwitchUserProfile.NewUser) + '" was successfull');
 Else;
   RC = recieveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
   Data = '*OK>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Anonymous connected');
 EndIf;

 // Handle incomming file- and restore informations
 recieveData(pUseTLS :pSocket :pGSK :%Addr(RestoreCommand) :%Size(RestoreCommand));
 If ( %SubSt(RestoreCommand :1 :3) <> 'RST' );
   Data = '*NORESTORE>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   sendJobLog('+> Invalid restorecommand recieved. End connection with client');
   Return;
 Else;
   Data = '*OK>';
   sendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
 EndIf;

 // Handle incomming data
 sendJobLog('+> Waiting for incomming data');
 RetrievingFile.FileHandler = IFS_Open(P_FILE :O_WRONLY + O_TRUNC + O_CREAT + O_LARGEFILE
                              :S_IRWXU + S_IRWXG + S_IRWXO);

 Reset RetrievingFile.Bytes;

 DoW ( Loop ) And ( RetrievingFile.FileHandler >= 0 );
   RetrievingFile.Length = recieveData(pUseTLS :pSocket :pGSK
                                       :%Addr(RetrievingFile.Data) :%Size(RetrievingFile.Data));
   If ( RetrievingFile.Length <= 0 );
     IFS_Close(RetrievingFile.FileHandler);
     Leave;
   EndIf;

   RetrievingFile.Bytes += RetrievingFile.Length;

   If ( %Scan('*EOF>' :RetrievingFile.Data) > 0 );
     RetrievingFile.Data = %SubSt(RetrievingFile.Data :1 :%Scan('*EOF>' :RetrievingFile.Data) - 1);
     IFS_Write(RetrievingFile.FileHandler :%Addr(RetrievingFile.Data) :RetrievingFile.Length - 5);
     IFS_Close(RetrievingFile.FileHandler);
     Leave;
   Else;
     IFS_Write(RetrievingFile.FileHandler :%Addr(RetrievingFile.Data) :RetrievingFile.Length);
     Clear RetrievingFile.Data;
   EndIf;
 EndDo;

 sendJobLog('+> ' + %Char(%DecH(RetrievingFile.Bytes/1024 :17 :2)) + ' KBytes recieved');

 Data = '*OK>';
 Monitor;
   ManageSavefile(RestoreSuccess :P_SAVE :P_FILE);
   On-Error;
     RestoreSuccess = FALSE;
 EndMon;

 sendJobLog('+> Restore: ' + %TrimR(RestoreCommand));

 If Not RestoreSuccess;
   Data = '*ERROR_RESTORE> Error occured while writing to savefile';
 Else;
   If ( System(RestoreCommand) <> 0 );
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
 If ( pAuthentication = '*USRPRF' );
   QSYGETPH(OriginalUser :'*NOPWD' :SwitchUserProfile.UserHandler :ErrorDS);
   QWTSETP(SwitchUserProfile.UserHandler :ErrorDS);
 EndIf;

 Return;

END-PROC;

//**************************************************************************
DCL-PROC generateGSKEnvironment;
 DCL-PI *N IND;
   pGSK LIKEDS(GSK_T);
   pAppID CHAR(32) CONST;
 END-PI;

 DCL-C APP_ID 'SND_IBMI_APP';

 DCL-S Success IND INZ;
 DCL-S AppID VARCHAR(32) INZ;
 //-------------------------------------------------------------------------

 If ( pAppID = '*DFT' );
   AppID = APP_ID;
 Else;
   AppID = pAppID;
 EndIf;

 Success = ( gsk_Environment_Open(pGSK.Environment) = GSK_OK );
 If Not Success;
   sendJobLog('GSK_Environment_Open(): ' + %Str(gsk_StrError(ErrNo)));
 EndIf;

 If Success;
   Success = ( gsk_Attribute_Set_Buffer(pGSK.Environment :GSK_OS400_APPLICATION_ID
                                        :AppID :0) = GSK_OK );
   If Not Success;
     sendJobLog('gsk_Attribute_Set_Buffer(): ' + %Str(gsk_StrError(ErrNo)));
     gsk_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 If Success;
   Success = ( gsk_Attribute_Set_Enum(pGSK.Environment :GSK_SESSION_TYPE
                                      :GSK_SERVER_SESSION) = GSK_OK );
   If Not Success;
     sendJobLog('gsk_Attribute_Set_Enum(): ' + %Str(gsk_StrError(ErrNo)));
     gsk_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 If Success;
   Success = ( gsk_Attribute_Set_Enum(pGSK.Environment :GSK_CLIENT_AUTH_TYPE
                                      :GSK_CLIENT_AUTH_FULL) = GSK_OK );
   If Not Success;
     sendJobLog('gsk_Attribute_Set_Enum(): ' + %Str(gsk_StrError(ErrNo)));
     gsk_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 If Success;
   Success = ( gsk_Environment_Init(pGSK.Environment) = GSK_OK );
   If Not Success;
     sendJobLog('gsk_Environment_Init(): ' + %Str(gsk_StrError(ErrNo)));
     gsk_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 Return Success;

END-PROC;

//**************************************************************************
DCL-PROC sendData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocket LIKEDS(Socket_T) CONST;
   pGSK LIKEDS(GSK_T) CONST;
   pData POINTER VALUE;
   pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = gsk_Secure_Soc_Write(pGSK.SecureHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC <> GSK_OK );
     sendJobLog('gsk_Secure_Soc_Write(): ' + %Str(gsk_StrError(ErrNo)));
   EndIf;
   RC = GSKLength;
 Else;
   RC = send(pSocket.Talk :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC recieveData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocket LIKEDS(Socket_T) CONST;
   pGSK LIKEDS(GSK_T) CONST;
   pData POINTER VALUE;
   pLength INT(10) VALUE;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = gsk_Secure_Soc_Read(pGSK.SecureHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC <> GSK_OK );
     sendJobLog('gsk_Secure_Soc_Read(): ' + %Str(gsk_StrError(ErrNo)));
     Clear RC;
   EndIf;
   If ( RC = GSK_OK ) And ( GSKLength > 0 );
     Buffer = %SubSt(Buffer :1 :GSKLength);
   EndIf;
   RC = GSKLength;
 Else;
   RC = recv(pSocket.Talk :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC cleanTemp;

 ifs_Unlink(P_FILE);
 system('DLTF FILE(QTEMP/RCV)');

END-PROC;

//**************************************************************************
DCL-PROC cleanUp_Socket;
 DCL-PI *N;
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
   pGSKHandler POINTER;
 END-PI;
 //-------------------------------------------------------------------------

 If pUseTLS;
   GSK_Secure_Soc_Close(pGSKHandler);
 EndIf;

 Close_Socket(pSocketHandler);

END-PROC;

//**************************************************************************
DCL-PROC sendDie;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 Message.Length = %Len(%TrimR(pMessage));
 If ( Message.Length >= 0 );
   sendProgramMessage('CPF9897'  :CPFMSG :pMessage: Message.Length
                      :'*ESCAPE' :'*PGMBDY' :1 :Message.Key :Message.Error);
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC sendJobLog;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 Message.Length = %Len(%TrimR(pMessage));
 If ( Message.Length >= 0 );
   sendProgramMessage('CPF9897' :CPFMSG :pMessage: Message.Length
                      :'*DIAG'  :'*PGMBDY' :1 :Message.Key :Message.Error);
 EndIf;

END-PROC;

//#########################################################################
/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
