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

//  Created by BRC on 25.07.2018 - 16.01.2019

// Socketclient to send objects over tls to another IBMi
//   I use the socket_h and gskssl_h header from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


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
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,SYSTEM
/INCLUDE QRPGLECPY,ERRNO_H

/INCLUDE QRPGLECPY,PSDS
/INCLUDE QRPGLECPY,BOOLIC

DCL-C P_SAVE '/QSYS.LIB/QTEMP.LIB/RCV.FILE';
DCL-C P_FILE '/tmp/rcv.file';

DCL-DS Socket_Template TEMPLATE QUALIFIED;
  Listener INT(10);
  Talk INT(10);
  ClientIP CHAR(17);
END-DS;
DCL-DS GSK_Template TEMPLATE QUALIFIED;
  Environment POINTER;
  SecureHandler POINTER;
END-DS;
DCL-DS Lingering_Template TEMPLATE QUALIFIED;
  LingerHandler POINTER;
  Length INT(10);
END-DS;
DCL-DS MessageHandling_Template TEMPLATE QUALIFIED;
  Length INT(10);
  Key CHAR(4);
  Error CHAR(128);
END-DS;
DCL-DS ErrorDS_Template TEMPLATE QUALIFIED;
  NbrBytesPrv INT(10) INZ(%SIZE(ErrorDS_Template));
  NbrBytesAvl INT(10);
  MessageID CHAR(7);
  Reserved1 CHAR(1);
  MessageData CHAR(512);
END-DS;


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

 DCL-DS Socket LIKEDS(Socket_Template) INZ;
 DCL-DS GSK LIKEDS(GSK_Template) INZ;
 DCL-DS Lingering LIKEDS(Lingering_Template) INZ;
 //-------------------------------------------------------------------------

 *INLR = TRUE;
 UseTLS = pUseTLS;

 MakeListener(pPort :UseTLS :pAppID :ConnectFrom :Socket :GSK :Lingering);

 DoU DoShutDown(UseTLS :Socket :GSK);

   AcceptConnection(UseTLS :ConnectFrom :Socket :GSK :Lingering);

   Monitor;
     HandleClient(UseTLS :pAuthentication :Socket :GSK);
     On-Error;
   EndMon;

   CleanTemp();
   CleanUp_Socket(UseTLS :Socket.Talk :GSK.SecureHandler);

 EndDo;

END-PROC;

//**************************************************************************
DCL-PROC DoShutDown;
 DCL-PI *N IND;
   pUseTLS IND CONST;
   pSocket LIKEDS(Socket_Template) CONST;
   pGSK LIKEDS(GSK_Template);
 END-PI;

 DCL-S ShutDown IND INZ(FALSE);
 //-------------------------------------------------------------------------

 If ( %ShtDn() );
   ShutDown = TRUE;
   CleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
 EndIf;

 Return ShutDown;

END-PROC;

//**************************************************************************
DCL-PROC MakeListener;
 DCL-PI *N;
   pPort UNS(5) CONST;
   pUseTLS IND;
   pAppID CHAR(32) CONST;
   pConnectFrom POINTER;
   pSocket LIKEDS(Socket_Template);
   pGSK LIKEDS(GSK_Template);
   pLingering LIKEDS(Lingering_Template);
 END-PI;

 DCL-S BindTo POINTER;
 DCL-S Length INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 DCL-S SockOptON IND INZ(TRUE);
 //-------------------------------------------------------------------------

 If pUseTLS;
   pUseTLS = GenerateGSKEnvironment(pGSK :pAppID);
   If Not pUseTLS;
     SendJobLog('+> Server was not able to generate gsk-environment. Continue without tls');
   EndIf;
 EndIf;

 Length = %Size(SockAddr_In);
 BindTo = %Alloc(Length);
 pConnectFrom = %Alloc(Length);

 pSocket.Listener = Socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( pSocket.Listener < 0 );
   CleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   SendDie('socket(): ' + %Str(StrError(ErrNo)));
 EndIf;

 SetSockOpt(pSocket.Listener :SOL_SOCKET :SO_REUSEADDR :%Addr(SockOptON) :%Size(SockOptON));

 pLingering.Length = %Size(Linger);
 pLingering.LingerHandler = %Alloc(pLingering.Length);
 p_Linger = pLingering.LingerHandler;
 l_OnOff  = 1;
 l_Linger = 1;
 SetSockOpt(pSocket.Listener :SOL_SOCKET :SO_LINGER :pLingering.LingerHandler :pLingering.Length);

 p_SockAddr = BindTo;
 Sin_Family = AF_INET;
 Sin_Addr   = INADDR_ANY;
 Sin_Port   = pPort;
 Sin_Zero   = *ALLx'00';

 If ( Bind(pSocket.Listener :BindTo :Length) < 0 );
   ErrorNumber = ErrNo;
   CleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   SendDie('bind(): ' + %Str(StrError(ErrorNumber)));
 EndIf;

 If ( Listen(pSocket.Listener :5) < 0 );
   ErrorNumber = ErrNo;
   CleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   SendDie('listen(): ' + %Str(StrError(ErrorNumber)));
 EndIf;

 SendJobLog('+> Server is now running on port ' + %Char(pPort) + ' and ready for connections');

END-PROC;

//**************************************************************************
DCL-PROC AcceptConnection;
 DCL-PI *N;
   pUseTLS IND CONST;
   pConnectFrom POINTER CONST;
   pSocket LIKEDS(Socket_Template);
   pGSK LIKEDS(GSK_Template);
   pLingering LIKEDS(Lingering_Template);
 END-PI;

 DCL-S Length INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 //-------------------------------------------------------------------------

 DoU ( Length = %Size(SockAddr_In) );

   Length = %Size(SockAddr_In);
   pSocket.Talk  = Accept(pSocket.Listener :pConnectFrom :Length);
   If ( pSocket.Talk < 0 );
     SendJobLog('accept(): ' + %Str(StrError(ErrNo)));
     CleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

   l_OnOff  = 1;
   l_Linger = 10;
   SetSockOpt(pSocket.Talk :SOL_SOCKET :SO_LINGER :pLingering.LingerHandler :pLingering.Length);

   If ( Length <> %Size(SockAddr_In));
     CleanUp_Socket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

 EndDo;

 If pUseTLS;
   If ( GSK_Secure_Soc_Open(pGSK.Environment: pGSK.SecureHandler) <> GSK_OK );
     ErrorNumber = ErrNo;
     CleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     SendJobLog('GSK_Secure_Soc_Open(): ' + %Str(GSK_StrError(ErrorNumber)));
   EndIf;
   If ( GSK_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_FD :pSocket.Talk) <> GSK_OK );
     ErrorNumber = ErrNo;
     CleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     SendJobLog('GSK_Attribute_Set_Numeric_Value(): ' + %Str(GSK_StrError(ErrorNumber)));
   EndIf;
   If ( GSK_Secure_Soc_Init(pGSK.SecureHandler) <> GSK_OK );
     ErrorNumber = ErrNo;
     CleanUp_Socket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     SendJobLog('GSK_Secure_Soc_Init(): ' + %Str(GSK_StrError(ErrorNumber)));
   EndIf;
 EndIf;

 P_SockAddr = pConnectFrom;
 pSocket.ClientIP = %Str(INet_NTOA(Sin_Addr));

END-PROC;

//**************************************************************************
DCL-PROC HandleClient;
 DCL-PI *N;
   pUseTLS IND CONST;
   pAuthentication CHAR(7) CONST;
   pSocket LIKEDS(Socket_Template) CONST;
   pGSK LIKEDS(GSK_Template);
 END-PI;

 DCL-PR ManageSavefile EXTPGM('ZSERVERCL');
   Success CHAR(1);
   Save CHAR(64) CONST;
   File CHAR(64) CONST;
 END-PR;

/INCLUDE QRPGLECPY,IFS_H
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

 DCL-DS ErrorDS LIKEDS(ErrorDS_Template);
 //-------------------------------------------------------------------------

 // Check protocoll and session
 RC = RecieveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
 If ( RC <= 0 ) Or ( Data = '' );
   Data = '*UNKNOWNPROTOCOLL>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Unknown protocoll from address "' + %TrimR(pSocket.ClientIP) + '" passed');
   Return;
 EndIf;

 If ( %SubSt(Data :1 :6) = '*ZZv1>' );
   Work = %SubSt(Data :7 :10);
   Data = '*OK>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Session "' + %TrimR(Work) + '" from address "' + %TrimR(pSocket.ClientIP) +
              '" connected');
 Else;
   Data = '*UNKNOWNPROTOCOLL>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Unknown protocoll from address "' + %TrimR(pSocket.ClientIP) + '" passed');
   Return;
 EndIf;

 // User and password recieve and check / change to called user when authentication is *USRPRF
 If ( pAuthentication = '*USRPRF' );
   RC = RecieveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 ) Or ( Data = '' );
     Data = '*NOLOGINDATA>';
     SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> No userinformations passed');
     Return;
   EndIf;

   If ( Data = '*AUTH_NONE>' );
     Data = '*NONONEALLOWED>';
     SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> No anonymous login allowed');
     Return;
   EndIf;

   SwitchUserProfile.NewUser = %SubSt(Data :1 :10);
   Work = %SubSt(Data :11 :1000);
   Exec SQL SET :SwitchUserProfile.Password = DECRYPT_BIT(BINARY(RTRIM(:Work)), :Key);
   Clear Key;
   If ( SQLCode <> 0 );
     Data = '*NOPWD>' + %Char(SQLCode);
     SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> Password decryption failed for user ' + %TrimR(SwitchUserProfile.NewUser) +
                ': ' + %Char(SQLCode));
     Return;
   EndIf;

   OriginalUser = PSDS.UserName;
   QSYGETPH(SwitchUserProfile.NewUser :SwitchUserProfile.Password :SwitchUserProfile.UserHandler
               :ErrorDS :%Len(%TrimR(SwitchUserProfile.Password)) :0);
   Clear SwitchUserProfile.Password;
   If ( ErrorDS.NbrBytesAvl > 0 );
     Data = '*NOACCESS>' + ErrorDS.MessageID;
     SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> Login failed for user ' + %TrimR(SwitchUserProfile.NewUser) +
                ': ' + ErrorDS.MessageID);
     Return;
   EndIf;

   QWTSETP(SwitchUserProfile.UserHandler :ErrorDS);
   If ( ErrorDS.NbrBytesAvl > 0 );
     Data = '*NOACCESS>' + ErrorDS.MessageID;
     SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> No access for userprofile ' + %TrimR(SwitchUserProfile.NewUser) +
                ': ' + ErrorDS.MessageID);
     Return;
   EndIf;

   // Login completed
   Data = '*OK>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Login for user "' + %TrimR(SwitchUserProfile.NewUser) + '" was successfull');
 Else;
   RC = RecieveData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Size(Data));
   Data = '*OK>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Anonymous connected');
 EndIf;

 // Handle incomming file- and restore informations
 RecieveData(pUseTLS :pSocket :pGSK :%Addr(RestoreCommand) :%Size(RestoreCommand));
 If ( %SubSt(RestoreCommand :1 :3) <> 'RST' );
   Data = '*NORESTORE>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Invalid restorecommand recieved. End connection with client');
   Return;
 Else;
   Data = '*OK>';
   SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));
 EndIf;

 // Handle incomming data
 RetrievingFile.FileHandler = IFS_Open(P_FILE :O_WRONLY + O_TRUNC + O_CREAT + O_LARGEFILE
                              :S_IRWXU + S_IRWXG + S_IRWXO);

 Reset RetrievingFile.Bytes;

 DoW ( Loop ) And ( RetrievingFile.FileHandler >= 0 );
   RetrievingFile.Length = RecieveData(pUseTLS :pSocket :pGSK
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

 SendJobLog('+> ' + %Char(%DecH(RetrievingFile.Bytes/1024 :17 :2)) + ' KBytes recieved');

 Data = '*OK>';
 Monitor;
   ManageSavefile(RestoreSuccess :P_SAVE :P_FILE);
   On-Error;
     RestoreSuccess = FALSE;
 EndMon;

 SendJobLog('+> Restore: ' + %TrimR(RestoreCommand));

 If Not RestoreSuccess;
   Data = '*ERROR_RESTORE> Error occured while writing to savefile';
 Else;
   If ( System(RestoreCommand) <> 0 );
     Data = '*ERROR_RESTORE> ' + %Str(StrError(ErrNo));
     RestoreSuccess = FALSE;
   EndIf;
 EndIf;
 SendData(pUseTLS :pSocket :pGSK :%Addr(Data) :%Len(%Trim(Data)));

 If RestoreSuccess;
   SendJobLog('+> Restore was successfull, end connection with client');
 Else;
   SendJobLog('+> Restore was not successfull, end connection with client');
 EndIf;

 // Switch back to original userprofile when authentication is *USRPRF
 If ( pAuthentication = '*USRPRF' );
   QSYGETPH(OriginalUser :'*NOPWD' :SwitchUserProfile.UserHandler :ErrorDS);
   QWTSETP(SwitchUserProfile.UserHandler :ErrorDS);
 EndIf;

 Return;

END-PROC;

//**************************************************************************
DCL-PROC GenerateGSKEnvironment;
 DCL-PI *N IND;
   pGSK LIKEDS(GSK_Template);
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

 Success = ( GSK_Environment_Open(pGSK.Environment) = GSK_OK );
 If Not Success;
   SendJobLog('GSK_Environment_Open(): ' + %Str(GSK_StrError(ErrNo)));
 EndIf;

 If Success;
   Success = ( GSK_Attribute_Set_Buffer(pGSK.Environment :GSK_OS400_APPLICATION_ID
                                        :AppID :0) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Buffer(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 If Success;
   Success = ( GSK_Attribute_Set_Enum(pGSK.Environment :GSK_SESSION_TYPE
                                      :GSK_SERVER_SESSION) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Enum(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 If Success;
   Success = ( GSK_Attribute_Set_Enum(pGSK.Environment :GSK_CLIENT_AUTH_TYPE
                                      :GSK_CLIENT_AUTH_FULL) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Enum(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 If Success;
   Success = ( GSK_Environment_Init(pGSK.Environment) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Environment_Init(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(pGSK.Environment);
   EndIf;
 EndIf;

 Return Success;

END-PROC;

//**************************************************************************
DCL-PROC SendData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocket LIKEDS(Socket_Template) CONST;
   pGSK LIKEDS(GSK_Template) CONST;
   pData POINTER VALUE;
   pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = GSK_Secure_Soc_Write(pGSK.SecureHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC <> GSK_OK );
     SendJobLog('GSK_Secure_Soc_Write(): ' + %Str(GSK_StrError(ErrNo)));
   EndIf;
   RC = GSKLength;
 Else;
   RC = Send(pSocket.Talk :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC RecieveData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocket LIKEDS(Socket_Template) CONST;
   pGSK LIKEDS(GSK_Template) CONST;
   pData POINTER VALUE;
   pLength INT(10) VALUE;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = GSK_Secure_Soc_Read(pGSK.SecureHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC <> GSK_OK );
     SendJobLog('GSK_Secure_Soc_Read(): ' + %Str(GSK_StrError(ErrNo)));
     Clear RC;
   EndIf;
   If ( RC = GSK_OK ) And ( GSKLength > 0 );
     Buffer = %SubSt(Buffer :1 :GSKLength);
   EndIf;
   RC = GSKLength;
 Else;
   RC = Recv(pSocket.Talk :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC CleanTemp;

 DCL-PR IFS_Unlink INT(10) EXTPROC('unlink');
   Path POINTER VALUE OPTIONS(*STRING);
 END-PR;
 //-------------------------------------------------------------------------

 IFS_Unlink(P_FILE);
 System('DLTF FILE(QTEMP/RCV)');

END-PROC;

//**************************************************************************
DCL-PROC CleanUp_Socket;
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
DCL-PROC SendDie;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_Template) INZ;
 //-------------------------------------------------------------------------

 Message.Length = %Len(%TrimR(pMessage));
 If ( Message.Length >= 0 );
   SndPgmMsg('CPF9897'  :'QCPFMSG   *LIBL' :pMessage: Message.Length
             :'*ESCAPE' :'*PGMBDY' :1 :Message.Key :Message.Error);
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC SendJobLog;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_Template) INZ;
 //-------------------------------------------------------------------------

 Message.Length = %Len(%TrimR(pMessage));
 If ( Message.Length >= 0 );
   SndPgmMsg('CPF9897' :'QCPFMSG   *LIBL' :pMessage: Message.Length
             :'*DIAG'  :'*PGMBDY' :1 :Message.Key :Message.Error);
 EndIf;

END-PROC;

//#########################################################################
/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
