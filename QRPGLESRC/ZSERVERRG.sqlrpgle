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

//  Created by BRC on 25.07.2018 - 28.12.2018

// Socketclient to send objects over tls to another IBMi
//   Based on the socketapi from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);


DCL-PR Main EXTPGM('ZSERVERRG');
  Port UNS(5) CONST;
  Authentication CHAR(7) CONST;
  UseTLS IND CONST;
END-PR;

/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,SYSTEM

DCL-PR DoShutDown IND;
  UseTLS IND CONST;
END-PR;
DCL-PR MakeListener;
  Port UNS(5) CONST;
  UseTLS IND;
  ConnectFrom POINTER;
END-PR;
DCL-PR AcceptConnection;
  UseTLS IND CONST;
  ConnectFrom POINTER CONST;
END-PR;
DCL-PR HandleClient;
  Authentication CHAR(7) CONST;
  UseTLS IND CONST;
END-PR;
DCL-PR GenerateGSKEnvironment IND END-PR;
DCL-PR SendData INT(10);
  UseTLS IND CONST;
  Data POINTER VALUE;
  Length INT(10) CONST;
END-PR;
DCL-PR RecieveData INT(10);
  UseTLS IND CONST;
  Data POINTER VALUE;
  Length INT(10) VALUE;
END-PR;
DCL-PR CleanUp_Socket;
  UseTLS IND CONST;
  SocketHandler INT(10) CONST;
END-PR;
DCL-PR CleanTemp END-PR;
DCL-PR SendDie;
  Message CHAR(256) CONST;
END-PR;
DCL-PR SendJobLog;
  Message CHAR(256) CONST;
END-PR;

DCL-C TRUE *ON;
DCL-C FALSE *OFF;

DCL-C P_SAVE '/QSYS.LIB/QTEMP.LIB/RCV.FILE';
DCL-C P_FILE '/tmp/rcv.file';
DCL-C APP_ID 'YOUR_TLS_APP';

/INCLUDE QRPGLECPY,ERRNO_H
/INCLUDE QRPGLECPY,PSDS

DCL-S ListenerSocket INT(10) INZ;
DCL-S LocalSocket INT(10) INZ;
DCL-S GSKEnvironment POINTER INZ;
DCL-S GSKHandler POINTER INZ;

DCL-DS ErrorDS_Template QUALIFIED TEMPLATE;
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
   pAuthentication CHAR(7) CONST;
   pUseTLS IND CONST;
 END-PI;

 DCL-S UseTLS IND INZ(FALSE);
 DCL-S ConnectFrom POINTER;
 //-------------------------------------------------------------------------

 UseTLS = pUseTLS;
 *INLR = TRUE;

 MakeListener(pPort :UseTLS :ConnectFrom);

 DoU DoShutDown(UseTLS);

   AcceptConnection(UseTLS :ConnectFrom);

   Monitor;
     HandleClient(pAuthentication :UseTLS);
     On-Error;
   EndMon;

   CleanTemp();
   CleanUp_Socket(UseTLS :LocalSocket);

 EndDo;

END-PROC;

//**************************************************************************
DCL-PROC DoShutDown;
 DCL-PI *N IND;
   pUseTLS IND CONST;
 END-PI;

 DCL-S ShutDown IND INZ(FALSE);
 //-------------------------------------------------------------------------

 If ( %ShtDn() );
   ShutDown = TRUE;
   CleanUp_Socket(pUseTLS :LocalSocket);
 EndIf;

 Return ShutDown;

END-PROC;

//**************************************************************************
DCL-PROC MakeListener;
 DCL-PI *N;
   pPort UNS(5) CONST;
   pUseTLS IND;
   pConnectFrom POINTER;
 END-PI;

 DCL-S BindTo POINTER;
 DCL-S Length INT(10) INZ;
 DCL-S ErrNumber INT(10) INZ;
 //-------------------------------------------------------------------------

 If pUseTLS;
   pUseTLS = GenerateGSKEnvironment();
 EndIf;

 // Allocate space for socket addresses
 Length      = %Size(SockAddr_In);
 BindTo      = %Alloc(Length);
 pConnectFrom = %Alloc(Length);

 // Make a new socket
 ListenerSocket = Socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( ListenerSocket < 0 );
   CleanUp_Socket(pUseTLS :ListenerSocket);
   SendDie('socket(): ' + %Str(StrError(ErrNo)));
 EndIf;

 // Bind the socket to port, of any IP address
 p_SockAddr = BindTo;
 Sin_Family = AF_INET;
 Sin_Addr   = INADDR_ANY;
 Sin_Port   = pPort;
 Sin_Zero   = *ALLx'00';

 If ( Bind(ListenerSocket :BindTo :Length) < 0 );
   ErrNumber = ErrNo;
   CleanUp_Socket(pUseTLS :ListenerSocket);
   SendDie('bind(): ' + %Str(StrError(ErrNumber)));
 EndIf;

 // Indicate that we want to listen for connections
 If ( Listen(ListenerSocket :5) < 0 );
   ErrNumber = ErrNo;
   CleanUp_Socket(pUseTLS :ListenerSocket);
   SendDie('listen(): ' + %Str(StrError(ErrNumber)));
 EndIf;

 SendJobLog('+> Server is now running on port ' + %Char(pPort) + ' and ready for connections');

END-PROC;

//**************************************************************************
DCL-PROC AcceptConnection;
 DCL-PI *N;
   pUseTLS IND CONST;
   pConnectFrom POINTER CONST;
 END-PI;

 DCL-S Length INT(10) INZ;
 DCL-S ErrNumber INT(10) INZ;
 DCL-S ClientIP CHAR(17) INZ;
 //-------------------------------------------------------------------------

 DoU ( Length = %Size(SockAddr_In) );

   Length = %Size(SockAddr_In);
   LocalSocket  = Accept(ListenerSocket :pConnectFrom :Length);
   If ( LocalSocket < 0 );
     SendJobLog('accept(): ' + %Str(StrError(ErrNo)));
     CleanUp_Socket(pUseTLS :ListenerSocket);
     Return;
   EndIf;

   If ( Length <> %Size(SockAddr_In));
     CleanUp_Socket(pUseTLS :ListenerSocket);
     Return;
   EndIf;

 EndDo;

 If pUseTLS;
   If ( GSK_Secure_Soc_Open(GSKEnvironment: GSKHandler) <> GSK_OK );
     ErrNumber = ErrNo;
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendJobLog('GSK_Secure_Soc_Open(): ' + %Str(GSK_StrError(ErrNumber)));
   EndIf;
   If ( GSK_Attribute_Set_Numeric_Value(GSKHandler :GSK_FD :LocalSocket) <> GSK_OK );
     ErrNumber = ErrNo;
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendJobLog('GSK_Attribute_Set_Numeric_Value(): ' + %Str(GSK_StrError(ErrNumber)));
   EndIf;
   If ( GSK_Secure_Soc_Init(GSKHandler) <> GSK_OK );
     ErrNumber = ErrNo;
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendJobLog('GSK_Secure_Soc_Init(): ' + %Str(GSK_StrError(ErrNumber)));
   EndIf;
 EndIf;

 P_SockAddr = pConnectFrom;
 ClientIP   = %Str(INet_NTOA(Sin_Addr));

END-PROC;

//**************************************************************************
DCL-PROC HandleClient;
 DCL-PI *N;
   pAuthentication CHAR(7) CONST;
   pUseTLS IND CONST;
 END-PI;

 DCL-PR EC#ZSERVER EXTPGM('ZSERVERCL');
   Success CHAR(1);
   Save CHAR(64) CONST;
   File CHAR(64) CONST;
 END-PR;

/INCLUDE QRPGLECPY,IFS_H
/INCLUDE QRPGLECPY,SETUSR_H

 DCL-S KEY CHAR(40) INZ('yourkey');

 DCL-S Loop IND INZ(TRUE);
 DCL-S RestoreSuccess IND INZ(TRUE);
 DCL-S FileHandler INT(10) INZ;
 DCL-S RC INT(10) INZ;
 DCL-S FileLength INT(10) INZ;
 DCL-S Data CHAR(1024) INZ;
 DCL-S Work CHAR(1024) INZ;
 DCL-S Restore CHAR(1024) INZ;
 DCL-S FileData CHAR(32766) INZ;
 DCL-S OriginalUser CHAR(10) INZ;
 DCL-S Bytes UNS(20) INZ;

 DCL-DS ErrorDS LIKEDS(ErrorDS_Template);
 //-------------------------------------------------------------------------

 // Check protocoll and session
 RC = RecieveData(pUseTLS :%Addr(Data) :%Size(Data));
 If ( RC <= 0 ) Or ( Data = '' );
   Data = '*UNKNOWNPROTOCOLL>';
   SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Unknown protocoll passed');
   Return;
 EndIf;

 If ( %SubSt(Data :1 :6) = '*ZZv1>' );
   Work = %SubSt(Data :7 :10);
   Data = '*OK>';
   SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Session "' + %TrimR(Work) + '" connected');
 Else;
   Data = '*UNKNOWNPROTOCOLL>';
   SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Unknown protocoll passed');
   Return;
 EndIf;

 // User and password recieve and check / change to called user when authentication is *USRPRF
 If ( pAuthentication = '*USRPRF' );
   RC = RecieveData(pUseTLS :%Addr(Data) :%Size(Data));
   If ( RC <= 0 ) Or ( Data = '' );
     Data = '*NOLOGINDATA>';
     SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> No userinformations passed');
     Return;
   EndIf;

   If ( Data = '*NONE' );
     Data = '*NONONEALLOWED>';
     SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> No anonymous login allowed');
     Return;
   EndIf;

   User = %SubSt(Data :1 :10);
   Work = %SubSt(Data :11 :1000);
   Exec SQL SET :Password = DECRYPT_BIT(BINARY(:Work), :Key);
   Clear Key;
   If ( SQLCode <> 0 );
     Data = '*NOPWD>' + %Char(SQLCode);
     SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> Password decryption failed for user ' + %TrimR(User) + ': ' + %Char(SQLCode));
     Return;
   EndIf;

   OriginalUser = PSDS.UserName;
   EC#QSYGETPH(User :Password :UserHandler :ErrorDS :UserLength :UserCCSID);
   Clear Password;
   If ( ErrorDS.NbrBytesAvl > 0 );
     Data = '*NOACCESS>' + ErrorDS.MessageID;
     SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> Login failed for user ' + %TrimR(User) + ': ' + ErrorDS.MessageID);
     Return;
   EndIf;

   EC#QWTSETP(UserHandler :ErrorDS);
   If ( ErrorDS.NbrBytesAvl > 0 );
     Data = '*NOACCESS>' + ErrorDS.MessageID;
     SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
     SendJobLog('+> No access for userprofile ' + %TrimR(User) + ': ' + ErrorDS.MessageID);
     Return;
   EndIf;

   // Login completed
   Data = '*OK>';
   SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Login for user "' + %TrimR(User) + '" was successfull');
 Else;
   RC = RecieveData(pUseTLS :%Addr(Data) :%Size(Data));
   Data = '*OK>';
   SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Unknown user connected');
 EndIf;

 // Handle incomming file- and restore informations
 RecieveData(pUseTLS :%Addr(Restore) :%Size(Restore));

 // Handle incomming data
 FileHandler = IFS_Open(P_FILE :O_WRONLY + O_TRUNC + O_CREAT + O_LARGEFILE
                        :S_IRWXU + S_IRWXG + S_IRWXO);

 Reset Bytes;

 DoW ( Loop ) And ( FileHandler >= 0 );
   FileLength = RecieveData(pUseTLS :%Addr(FileData) :%Size(FileData));
   If ( FileLength <= 0 );
     IFS_Close(FileHandler);
     Leave;
   EndIf;

   Bytes += FileLength;

   If ( %Scan('*EOF>' :FileData) > 0 );
     FileData = %SubSt(FileData :1 :%Scan('*EOF>' :FileData) - 1);
     IFS_Write(FileHandler :%Addr(FileData) :FileLength - 5);
     IFS_Close(FileHandler);
     Leave;
   Else;
     IFS_Write(FileHandler :%Addr(FileData) :FileLength);
     Clear FileData;
   EndIf;
 EndDo;

 SendJobLog('+> ' + %Char(%DecH(Bytes/1024 :17 :2)) + ' KBytes recieved');

 Data = '*OK>';
 Monitor;
   EC#ZSERVER(RestoreSuccess :P_SAVE :P_FILE);
   On-Error;
     RestoreSuccess = FALSE;
 EndMon;

 SendJobLog('+> Restore: ' + %TrimR(Restore));

 If Not RestoreSuccess;
   Data = '*ERROR_RESTORE> Error occured while writing to savefile';
 Else;
   If ( System(Restore) <> 0 );
     Data = '*ERROR_RESTORE> ' + %Str(StrError(ErrNo));
     RestoreSuccess = FALSE;
   EndIf;
 EndIf;
 SendData(pUseTLS :%Addr(Data) :%Len(%Trim(Data)));
 
 If RestoreSuccess;
   SendJobLog('+> Restore was successfull, end connection to client');
 Else;
   SendJobLog('+> Restore was not successfull, end connection to client');
 EndIf;

 // Switch back to original userprofile when authentication is *USRPRF
 If ( pAuthentication = '*USRPRF' );
   EC#QSYGETPH(OriginalUser :'*NOPWD' :UserHandler :ErrorDS);
   EC#QWTSETP(UserHandler :ErrorDS);
 EndIf;

 Return;

END-PROC;

//**************************************************************************
DCL-PROC GenerateGSKEnvironment;
 DCL-PI *N IND END-PI;

 DCL-S Success IND INZ;
 //-------------------------------------------------------------------------

 Success = ( GSK_Environment_Open(GSKEnvironment) = GSK_OK );
 If Not Success;
   SendJobLog('GSK_Environment_Open(): ' + %Str(GSK_StrError(ErrNo)));
 EndIf;

 If Success;
   Success = ( GSK_Attribute_Set_Buffer(GSKEnvironment :GSK_OS400_APPLICATION_ID
                                        :APP_ID :0) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Buffer(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
   EndIf;
 EndIf;

 If Success;
   Success = ( GSK_Attribute_Set_Enum(GSKEnvironment :GSK_SESSION_TYPE
                                      :GSK_SERVER_SESSION) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Enum(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
   EndIf;
 EndIf;

 If Success;
   Success = ( GSK_Attribute_Set_Enum(GSKEnvironment :GSK_CLIENT_AUTH_TYPE
                                      :GSK_CLIENT_AUTH_FULL) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Enum(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
   EndIf;
 EndIf;

 If Success;
   Success = ( GSK_Environment_Init(GSKEnvironment) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Environment_Init(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
   EndIf;
 EndIf;

 Return Success;

END-PROC;

//**************************************************************************
DCL-PROC SendData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pData POINTER VALUE;
   pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = GSK_Secure_Soc_Write(GSKHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC <> GSK_OK );
     SendJobLog('GSK_Secure_Soc_Write(): ' + %Str(GSK_StrError(ErrNo)));
   EndIf;
   RC = GSKLength;
 Else;
   RC = Send(LocalSocket :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC RecieveData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pData POINTER VALUE;
   pLength INT(10) VALUE;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = GSK_Secure_Soc_Read(GSKHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC <> GSK_OK );
     SendJobLog('GSK_Secure_Soc_Read(): ' + %Str(GSK_StrError(ErrNo)));
     Clear RC;
   EndIf;
   If ( RC = GSK_OK ) And ( GSKLength > 0 );
     Buffer = %SubSt(Buffer :1 :GSKLength);
   EndIf;
   RC = GSKLength;
 Else;
   RC = Recv(LocalSocket :%Addr(Buffer) :pLength :0);
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
 END-PI;
 //-------------------------------------------------------------------------

 If pUseTLS;
   GSK_Secure_Soc_Close(GSKHandler);
 EndIf;

 Close_Socket(pSocketHandler);

END-PROC;

//**************************************************************************
DCL-PROC SendDie;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-S MessageLength INT(10) INZ;
 DCL-S MessageKey CHAR(4) INZ;
 DCL-S MessageError CHAR(128) INZ;
 //-------------------------------------------------------------------------

 MessageLength = %Len(%TrimR(pMessage));
 If ( MessageLength >= 0 );
   SndPgmMsg('CPF9897'  :'QCPFMSG   *LIBL' :pMessage: MessageLength
             :'*ESCAPE' :'*PGMBDY' :1 :MessageKey :MessageError);
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC SendJobLog;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-S MessageLength INT(10) INZ;
 DCL-S MessageKey CHAR(4) INZ;
 DCL-S MessageError CHAR(128) INZ;
 //-------------------------------------------------------------------------

 MessageLength = %Len(%TrimR(pMessage));
 If ( MessageLength >= 0 );
   SndPgmMsg('CPF9897' :'QCPFMSG   *LIBL' :pMessage: MessageLength
             :'*DIAG'  :'*PGMBDY' :1 :MessageKey :MessageError);
 EndIf;

END-PROC;

//#########################################################################
/DEFINE ERRNO_LOAD_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
