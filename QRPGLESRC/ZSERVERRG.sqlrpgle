**FREE
//- Copyright (c) 2018 Christian Brunner
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

// 00000000 BRC 25.07.2018

// Socketclient with or without tls/ssl to send objects to another IBMi
//   Based on the socketapi from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW) USRPRF(*OWNER) DEBUG(*YES) MAIN(Main);


DCL-PR Main EXTPGM('ZSERVERRG');
  Port UNS(5) CONST;
  UseSSL CHAR(4) CONST OPTIONS(*NOPASS);
END-PR;

/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,SYSTEM

DCL-PR CheckShutDown END-PR;
DCL-PR MakeListener;
  Port UNS(5) CONST;
END-PR;
DCL-PR AcceptConnection END-PR;
DCL-PR HandleClient END-PR;
DCL-PR GenerateGSKEnvironment END-PR;
DCL-PR SendData INT(10);
  Data POINTER VALUE;
  Length INT(10) CONST;
END-PR;
DCL-PR RecieveData INT(10);
  Data POINTER VALUE;
  Length INT(10) VALUE;
END-PR;
DCL-PR CleanUp_Socket;
  SocketHandler INT(10) CONST;
END-PR;
DCL-PR CleanTemp END-PR;
DCL-PR SendDie;
  Message CHAR(256) CONST;
END-PR;
DCL-PR SendJobLog;
  Message CHAR(256) CONST;
END-PR;

DCL-C P_SAVE '/QSYS.LIB/QTEMP.LIB/RCV.FILE';
DCL-C P_FILE '/tmp/rcv.file';
DCL-C TRUE *ON;
DCL-C FALSE *OFF;
DCL-C APP_ID 'YOUR_APP_ID';

/INCLUDE QRPGLECPY,ERRNO_H
/INCLUDE QRPGLECPY,PSDS

DCL-S Loop IND INZ(TRUE);
DCL-S UseSSL IND INZ(FALSE);
DCL-S ConnectFrom POINTER;
DCL-S ListenerSocket INT(10) INZ;
DCL-S LocalSocket INT(10) INZ;
DCL-S GSKEnvironment POINTER INZ;
DCL-S GSKHandler POINTER INZ;

DCL-DS ErrorDS_Template QUALIFIED TEMPLATE;
  NbrBytesPrv INT(10) INZ(%SIZE(ErrorDS_Template));
  NbrBytesAvl INT(10);
  MsgID CHAR(7);
  Reserved1 CHAR(1);
  MsgData CHAR(512);
END-DS;


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pPort UNS(5) CONST;
   pUseSSL CHAR(4) CONST OPTIONS(*NOPASS);
 END-PI;
 //-------------------------------------------------------------------------

 *INLR = TRUE;

 If ( %Parms() = 2 );
   UseSSL = ( pUseSSL = '*YES' );
 Else;
   UseSSL = FALSE;
 EndIf;

 MakeListener(pPort);
 CheckShutDown();

 DoW ( Loop );

   AcceptConnection();

   Monitor;
     HandleClient();
     On-Error;
   EndMon;

   CleanTemp();
   CleanUp_Socket(LocalSocket);

 EndDo;

END-PROC;

//**************************************************************************
DCL-PROC CheckShutDown;

 If ( %ShtDn() );
   Loop = FALSE;
   CleanUp_Socket(LocalSocket);
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC MakeListener;
 DCL-PI *N;
   pPort UNS(5) CONST;
 END-PI;

 DCL-S BindTo POINTER;
 DCL-S Length INT(10) INZ;
 DCL-S ErrNumber INT(10) INZ;
 //-------------------------------------------------------------------------

 If UseSSL;
   GenerateGSKEnvironment();
 EndIf;

 // Allocate space for socket addresses
 Length      = %Size(SockAddr_In);
 BindTo      = %Alloc(Length);
 ConnectFrom = %Alloc(Length);

 // Make a new socket
 ListenerSocket = Socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( ListenerSocket < 0 );
   CleanUp_Socket(ListenerSocket);
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
   CleanUp_Socket(ListenerSocket);
   SendDie('bind(): ' + %Str(StrError(ErrNumber)));
 EndIf;

 // Indicate that we want to listen for connections
 If ( Listen(ListenerSocket :5) < 0 );
   ErrNumber = ErrNo;
   CleanUp_Socket(ListenerSocket);
   SendDie('listen(): ' + %Str(StrError(ErrNumber)));
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC AcceptConnection;

 DCL-S Length INT(10) INZ;
 DCL-S ErrNumber INT(10) INZ;
 DCL-S ClientIP CHAR(17) INZ;
 //-------------------------------------------------------------------------

 DoU ( Length = %Size(SockAddr_In) );

   Length = %Size(SockAddr_In);
   LocalSocket  = Accept(ListenerSocket :ConnectFrom :Length);
   If ( LocalSocket < 0 );
     SendJobLog('accept(): ' + %Str(StrError(ErrNo)));
     CleanUp_Socket(ListenerSocket);
     Return;
   EndIf;

   If ( Length <> %Size(SockAddr_In));
     Close_Socket(LocalSocket);
     Return;
   EndIf;

 EndDo;

 If UseSSL;
   If ( GSK_Secure_Soc_Open(GSKEnvironment: GSKHandler) <> GSK_OK );
     ErrNumber = ErrNo;
     CleanUp_Socket(LocalSocket);
     SendJobLog('GSK_Secure_Soc_Open(): ' + %Str(GSK_StrError(ErrNumber)));
   EndIf;
   If ( GSK_Attribute_Set_Numeric_Value(GSKHandler :GSK_FD :LocalSocket) <> GSK_OK );
     ErrNumber = ErrNo;
     CleanUp_Socket(LocalSocket);
     SendJobLog('GSK_Attribute_Set_Numeric_Value(): ' + %Str(GSK_StrError(ErrNumber)));
   EndIf;
   If ( GSK_Secure_Soc_Init(GSKHandler) <> GSK_OK );
     ErrNumber = ErrNo;
     CleanUp_Socket(LocalSocket);
     SendJobLog('GSK_Secure_Soc_Init(): ' + %Str(GSK_StrError(ErrNumber)));
   EndIf;
 EndIf;

 P_SockAddr = ConnectFrom;
 ClientIP   = %Str(INet_NTOA(Sin_Addr));

END-PROC;

//**************************************************************************
DCL-PROC HandleClient;

 DCL-PR IFS_Open INT(10) EXTPROC('open');
   Filename  POINTER VALUE OPTIONS(*STRING);
   Openflags INT(10) VALUE;
   Mode      UNS(10) VALUE OPTIONS(*NOPASS);
   Codepage  UNS(10) VALUE OPTIONS(*NOPASS);
 END-PR;
 DCL-PR IFS_Write INT(10) EXTPROC('write');
   Handle INT(10) VALUE;
   Buffer POINTER VALUE;
   Bytes  UNS(10) VALUE;
 END-PR;
 DCL-PR IFS_Close INT(10) EXTPROC('close');
   Handle INT(10)  VALUE;
 END-PR;
 DCL-PR EC#QSYGETPH EXTPGM('QSYGETPH');
   User     CHAR(10) CONST;
   Password CHAR(32) CONST;
   pHandler CHAR(12);
   Error    CHAR(32766) OPTIONS(*VARSIZE :*NOPASS);
   Length   INT(10) CONST OPTIONS(*NOPASS);
   pCCSID   INT(10) CONST OPTIONS(*NOPASS);
 END-PR;
 DCL-PR EC#QWTSETP EXTPGM('QWTSETP');
   pHandler CHAR(12);
   Error CHAR(32766) OPTIONS(*VARSIZE);
 END-PR;
 DCL-PR EC#ZSERVER EXTPGM('ZSERVERCL');
   RestoreSuccess CHAR(1);
   Save CHAR(64) CONST;
   File CHAR(64) CONST;
 END-PR;

 DCL-S KEY CHAR(40) INZ('your_key');

 DCl-C O_WRONLY 2;
 DCL-C O_CREAT 8;
 DCL-C O_TRUNC 64;
 DCL-C O_TEXTDATA 16777216;
 DCL-C O_CODEPAGE 8388608;
 DCL-C O_LARGEFILE 536870912;
 DCL-C S_IRWXU 448;
 DCL-C S_IRWXG 56;
 DCL-C S_IRWXO 7;

 DCL-S RestoreSuccess IND INZ(TRUE);
 DCL-S FileHandler INT(10) INZ;
 DCL-S RC INT(10) INZ;
 DCL-S FileLength INT(10) INZ;
 DCL-S Data CHAR(1024) INZ;
 DCL-S Work CHAR(1024) INZ;
 DCL-S Restore CHAR(1024) INZ;
 DCL-S FileData CHAR(32766) INZ;
 DCL-S User CHAR(10) INZ;
 DCL-S Password CHAR(32) INZ;
 DCL-S UserHandler CHAR(12) INZ;
 DCL-S OldUser CHAR(10) INZ;
 DCL-S UserLength INT(10) INZ(10);
 DCL-S UserCCSID INT(10) INZ(37);
 DCL-S Bytes UNS(20) INZ;

 DCL-DS ErrorDS LIKEDS(ErrorDS_Template);
 //-------------------------------------------------------------------------

 // User and password recieve and check / change to called user
 RC = RecieveData(%Addr(Data) :%Size(Data));
 If ( RC <= 0 ) Or ( Data = '' );
   Data = '*NOLOGINDATA>';
   SendData(%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> No userinformations passed');
   Return;
 EndIf;

 User = %SubSt(Data :1 :10);
 Work = %SubSt(Data :11 :1000);
 Exec SQL SET :Password = DECRYPT_BIT(BINARY(:Work), :Key);
 Clear Key;
 If ( SQLCode <> 0 );
   Data = '*NOPWD>' + %Char(SQLCode);
   SendData(%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Password decryption failed for user ' + %TrimR(User) + ': ' + %Char(SQLCode));
   Return;
 EndIf;

 OldUser = PSDS.UserName;
 EC#QSYGETPH(User :Password :UserHandler :ErrorDS :UserLength :UserCCSID);
 If ( ErrorDS.NbrBytesAvl > 0 );
   Data = '*NOACCESS>' + ErrorDS.MsgID;
   SendData(%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> Login failed by user ' + %TrimR(User) + ': ' + ErrorDS.MsgID);
   Return;
 EndIf;

 Clear Password;
 EC#QWTSETP(UserHandler :ErrorDS);
 If ( ErrorDS.NbrBytesAvl > 0 );
   Data = '*NOACCESS>' + ErrorDS.MsgID;
   SendData(%Addr(Data) :%Len(%Trim(Data)));
   SendJobLog('+> No access for userprofile ' + %TrimR(User) + ': ' + ErrorDS.MsgID);
   Return;
 EndIf;

 // Login completed
 Data = '*OK>';
 SendData(%Addr(Data) :%Len(%Trim(Data)));
 SendJobLog('+> User logged in successfully: ' + %TrimR(User));

 // Handle incomming file- and restore informations
 RecieveData(%Addr(Restore) :%Size(Restore));

 // Handle incomming data
 FileHandler = IFS_Open(P_FILE :O_WRONLY + O_TRUNC + O_CREAT + O_CODEPAGE + O_LARGEFILE
                        :S_IRWXU + S_IRWXG + S_IRWXO :1141);

 Reset Bytes;

 DoW ( Loop ) And ( FileHandler >= 0 );
   FileLength = RecieveData(%Addr(FileData) :%Size(FileData));
   If ( FileLength <= 0 ) Or ( FileData = '*EOF>' );
     IFS_Close(FileHandler);
     Leave;
   EndIf;
   Bytes += FileLength;
   RC = IFS_Write(FileHandler :%Addr(FileData) :FileLength);
   Clear FileData;
 EndDo;

 SendJobLog('+> ' + %Char(%DecH(Bytes/1024 :17 :2)) + ' KBytes recieved.');

 Data = '*OK>';
 Monitor;
   EC#ZSERVER(RestoreSuccess :P_SAVE :P_FILE);
   On-Error;
     RestoreSuccess = FALSE;
 EndMon;

 If Not RestoreSuccess;
   Data = '*ERROR_RESTORE> Error occured while writing to savefile';
 Else;
   If ( System(Restore) <> 0 );
     Data = '*ERROR_RESTORE> ' + %Str(StrError(ErrNo));
   EndIf;
 EndIf;
 SendData(%Addr(Data) :%Len(%Trim(Data)));

 // Switch to original userprofile
 EC#QSYGETPH(OldUser :'*NOPWD' :UserHandler :ErrorDS);
 EC#QWTSETP(UserHandler :ErrorDS);

 Return;

END-PROC;

//**************************************************************************
DCL-PROC GenerateGSKEnvironment;

 DCL-S Success IND INZ;
 //-------------------------------------------------------------------------

 Success = ( GSK_Environment_Open(GSKEnvironment) = GSK_OK );
 If Not Success;
   SendJobLog('GSK_Environment_Open(): ' + %Str(GSK_StrError(ErrNo)));
   UseSSL = Success;
 EndIf;

 If Success And UseSSL;
   Success = ( GSK_Attribute_Set_Buffer(GSKEnvironment :GSK_OS400_APPLICATION_ID
                                        :APP_ID :0) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Buffer(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
     UseSSL = Success;
   EndIf;
 EndIf;

 If Success And UseSSL;
   Success = ( GSK_Attribute_Set_Enum(GSKEnvironment :GSK_SESSION_TYPE
                                      :GSK_SERVER_SESSION) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Enum(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
     UseSSL = Success;
   EndIf;
 EndIf;

 If Success And UseSSL;
   Success = ( GSK_Attribute_Set_Enum(GSKEnvironment :GSK_CLIENT_AUTH_TYPE
                                      :GSK_CLIENT_AUTH_FULL) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Attribute_Set_Enum(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
     UseSSL = Success;
   EndIf;
 EndIf;

 If Success And UseSSL;
   Success = ( GSK_Environment_Init(GSKEnvironment) = GSK_OK );
   If Not Success;
     SendJobLog('GSK_Environment_Init(): ' + %Str(GSK_StrError(ErrNo)));
     GSK_Environment_Close(GSKEnvironment);
     UseSSL = Success;
   EndIf;
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC SendData;
 DCL-PI *N INT(10);
   pData POINTER VALUE;
   pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If UseSSL;
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
   pData POINTER VALUE;
   pLength INT(10) VALUE;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If UseSSL;
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
   pSocket INT(10) CONST;
 END-PI;
 //-------------------------------------------------------------------------

 If UseSSL;
   GSK_Secure_Soc_Close(GSKHandler);
   //GSK_Environment_Close(GSKEnvironment);
 EndIf;

 Close_Socket(pSocket);

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