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

// 00000000 BRC 30.08.2018

// Socketclient to send objects to another IBMi
//   Based on the socketapi from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


//CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW) USRPRF(*OWNER) DEBUG(*YES)
//        BNDDIR('SOCKAPI') MAIN(Main);
CTL-OPT DEBUG(*YES) BNDDIR('SOCKAPI') MAIN(Main);

DCL-PR Main EXTPGM('ZCLIENTRG');
  ObjectName CHAR(10) CONST;
  ObjectLibrary CHAR(10) CONST;
  ObjectType CHAR(10) CONST;
  Host CHAR(16) CONST;
  User CHAR(10) CONST;
  Password CHAR(32) CONST;
  TargetRelease CHAR(8) CONST;
  RestoreLibrary CHAR(10) CONST;
  Port UNS(5) CONST;
END-PR;

/INCLUDE SOCKET_H
//INCLUDE QRPGLECPY,SOCKAPI_H
DCL-PR System INT(10) EXTPROC('system');
  *N POINTER VALUE OPTIONS(*STRING);
END-PR;

DCL-PR ManageSendingStuff;
  ObjectName CHAR(10) CONST;
  ObjectLibrary CHAR(10) CONST;
  ObjectType CHAR(10) CONST;
  Host CHAR(16) CONST;
  User CHAR(10) CONST;
  Password CHAR(32) CONST;
  TargetRelease CHAR(8) CONST;
  RestoreLibrary CHAR(10) CONST;
  Port UNS(5) CONST;
END-PR;
DCL-PR SendDie;
  Message CHAR(256) CONST;
END-PR;
DCL-PR SendStatus;
  Message CHAR(256) CONST;
END-PR;

//INCLUDE *LIBL/QRPGLECPY,CONSTKEYS
DCL-C TRUE  *ON;
DCL-C FALSE *OFF;

/INCLUDE ERRNO_H
//INCLUDE QRPGLECPY,PSDS

//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pObjectName CHAR(10) CONST;
   pObjectLibrary CHAR(10) CONST;
   pObjectType CHAR(10) CONST;
   pHost CHAR(16) CONST;
   pUser CHAR(10) CONST;
   pPassword CHAR(32) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
 END-PI;
//-------------------------------------------------------------------------

 *INLR = TRUE;

 If ( %Parms() = 9 ) Or ( pObjectName <> '' );
   ManageSendingStuff(pObjectName :pObjectLibrary :pObjectType :pHost :pUser
                      :pPassword :pTargetRelease :pRestoreLibrary :pPort);
 EndIf;

 Return;

END-PROC;


//**************************************************************************
DCL-PROC ManageSendingStuff;
 DCL-PI *N;
   pObjectName CHAR(10) CONST;
   pObjectLibrary CHAR(10) CONST;
   pObjectType CHAR(10) CONST;
   pHost CHAR(16) CONST;
   pUser CHAR(10) CONST;
   pPassword CHAR(32) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
 END-PI;

 DCL-PR IFS_Open INT(10) EXTPROC('open');
   FileName POINTER VALUE OPTIONS(*STRING);
   OpenFlags INT(10) VALUE;
   Mode UNS(10) VALUE OPTIONS(*NOPASS);
   Codepage UNS(10) VALUE OPTIONS(*NOPASS);
 END-PR;
 DCL-PR IFS_Read INT(10) EXTPROC('read');
   Handle INT(10) VALUE;
   Buffer POINTER VALUE;
   Bytes UNS(10) VALUE;
 END-PR;
 DCL-PR IFS_Close INT(10) EXTPROC('close');
   Handle INT(10) VALUE;
 END-PR;
 DCL-PR IFS_Unlink INT(10) EXTPROC('unlink');
   Path POINTER VALUE OPTIONS(*STRING);
 END-PR;
 DCL-PR IFS_Stat INT(10) EXTPROC('stat');
   Path POINTER VALUE OPTIONS(*STRING);
   Buffer POINTER VALUE;
 END-PR;
 DCL-PR EC#ZCLIENT EXTPGM('ZCLIENTCL');
   Save CHAR(64) CONST;
   File CHAR(64) CONST;
 END-PR;

 DCL-C O_RDONLY    1;
 DCL-C O_WRONLY    2;
 DCL-C O_CREAT     8;
 DCL-C O_TRUNC     64;
 DCL-C O_TEXTDATA  16777216;
 DCL-C O_CODEPAGE  8388608;
 DCL-C O_LARGEFILE 536870912;
 DCL-C P_SAVE '/QSYS.LIB/QTEMP.LIB/SND.FILE';
 DCL-C P_FILE '/tmp/snd.file';

 DCL-S KEY CHAR(10) INZ('1234567890');
 DCL-S Loop IND INZ(TRUE);

 DCL-S fd INT(10) INZ;
 DCL-S rc INT(10) INZ;
 DCL-S Data CHAR(1024) INZ;
 DCL-S Work CHAR(1024) INZ;
 DCL-S SaveCommand CHAR(1024) INZ;
 DCL-S File CHAR(32766) INZ;
 DCL-S Bytes UNS(20) INZ;
 DCL-S ConnectTo POINTER INZ;
 DCL-S SocketID INT(10) INZ;
 DCL-S Address UNS(10) INZ;
 DCL-S AddressLength INT(10) INZ;
 DCL-S Err INT(10) INZ;
//-------------------------------------------------------------------------

 // Check for selected object
 Select;
   When ( pObjectType = '*ALL' ) Or ( %Scan('*' :pObjectName) > 0 );
     Clear rc;
   When ( pObjectType = '*LIB' );
     rc = System('CHKOBJ OBJ(' + %TrimR(pObjectName) + ') OBJTYPE(*LIB)');
   Other;
     rc = System('CHKOBJ OBJ(' + %TrimR(pObjectLibrary) + '/' + %TrimR(pObjectName) +
                  ') OBJTYPE(' + %TrimR(pObjectType) + ')');
 EndSl;

 If ( rc <> 0 );
   SendDie('Object(s) not found.');
   Return;
 EndIf;

 // Search adress via hostname
 Address = INet_Addr(%TrimR(pHost));
 If ( Address = INADDR_NONE );
   P_HostEnt = GetHostByName(%TrimR(pHost));
   If ( P_HostEnt = *NULL );
     SendDie('Unable to find that host.');
     Return;
   EndIf;
   Address = H_Addr;
 EndIf;

 // Create socket
 SocketID = Socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( SocketID < 0 );
   SendDie('socket(): ' + %Str(StrError(ErrNo)));
   Return;
 EndIf;

 AddressLength = %Size(SockAddr);
 ConnectTo = %Alloc(AddressLength);

 P_SockAddr = ConnectTo;
 Sin_Family = AF_INET;
 Sin_Addr = Address;
 Sin_Port = pPort;
 Sin_Zero = *ALLX'00';

 // Connect to host
 If ( Connect(SocketID :ConnectTo :AddressLength) < 0 );
   Err = ErrNo;
   //Close_Socket(SocketID);
   CALLP Close(SocketID);
   SendDie('connect(): ' + %Str(StrError(Err)));
   Return;
 EndIf;

 // Send data to host
 SendStatus('Start login at host');
 Exec SQL Set :Work = ENCRYPT_AES(:pPassword, :KEY);
 Data = pUser + %TrimR(Work);
 Send(SocketID :%Addr(Data) :%Len(%TrimR(Data)) :0);
 rc = Recv(SocketID :%Addr(Data) :%Size(Data) :0);
 If ( rc <= 0 );
   //Close_Socket(SocketID);
   CALLP Close(SocketID);
   SendDie('Login failed.');
   Return;
 EndIf;

 Work = %SubSt(Data:%Scan('>' :Data) + 1 :(rc - %Scan('>' :Data)));
 Data = %SubSt(Data :1 :%Scan('>' :Data));
 Select;
   When ( Data = '*NOLOGINDATA>' );
     //Close_Socket(SocketID);
     CALLP Close(SocketID);
     SendDie('No login data recieved.');
     Return;
   When ( Data = '*NOPWD>' );
     //Close_Socket(SocketID);
     CALLP Close(SocketID);
     SendDie('Wrong password > ' + %TrimR(Work));
     Return;
   When ( Data = '*NOACCESS>' );
     //Close_Socket(SocketID);
     CALLP Close(SocketID);
     SendDie('Access denied > ' + %TrimR(Work));
     Return;
   When ( Data = '*OK>' );
     SendStatus('Login ok.');
 EndSl;

 // Save objects and prepare
 SendStatus('Saving object(s), please wait ...');
 System('DLTF QTEMP/SND');
 System('CRTSAVF QTEMP/SND');
 If ( pObjectType = '*LIB' );
   SaveCommand = 'SAVLIB LIB(' + %TrimR(pObjectName) + ') DEV(*SAVF) SAVF(QTEMP/SND) ' +
                 'TGTRLS(' + %Trim(pTargetRelease) + ') SAVACT(*LIB) DTACPR(*HIGH)';
 Else;
   SaveCommand = 'SAVOBJ OBJ(' + %TrimR(pObjectName) + ') LIB(' + %TrimR(pObjectLibrary) + ') '+
                 'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) SAVF(QTEMP/SND) ' +
                 'TGTRLS(' + %TrimR(pTargetRelease) + ') SAVACT(*LIB) DTACPR(*HIGH)';
 EndIf;
 fd = System(SaveCommand);
 If ( fd < 0 );
   System('DLTF FILE(QTEMP/SND)');
   SendDie('Error while saving data. See joblog.');
   Return;
 EndIf;

 SendStatus('Prepare savefile to send ...');
 Monitor;
   EC#ZCLIENT(P_SAVE :P_FILE);
   On-Error;
     //Close_Socket(SocketID);
     CALLP Close(SocketID);
     IFS_Unlink(P_FILE);
     System('DLTF FILE(QTEMP/SND)');
     SendDie('Error occured while preparing savefile. See joblog.');
     Return;
 EndMon;

 System('DLTF QTEMP/SND');

 // Send restoreinformations
 SendStatus('Send objectinformations');
 If ( pObjectType = '*LIB' );
   Data = 'RSTLIB SAVLIB(' + %TrimR(pObjectName) + ') DEV(*SAVF) SAVF(QTEMP/RCV) ' +
          'MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB(' + %TrimR(pRestoreLibrary) + ')';
 Else;
   Data = 'RSTOBJ OBJ(' + %TrimR(pObjectName) + ') SAVLIB(' + %TrimR(pObjectLibrary) + ') ' +
          'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) SAVF(QTEMP/RCV) ' +
          'MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB(' + %TrimR(pRestoreLibrary) + ')';
 EndIf;
 Send(SocketID :%Addr(Data) :%Len(%TrimR(Data)) :0);

 // Send object
 SendStatus('Sending data to host ...');
 fd = IFS_Open(P_FILE :O_RDONLY + O_TEXTDATA + O_LARGEFILE);
 If ( fd < 0 );
   Err = ErrNo;
   //Close_Socket(SocketID);
   CALLP Close(SocketID);
   IFS_Unlink(P_FILE);
   SendDie('Error while reading file > ' + %Str(StrError(Err)));
   Return;
 EndIf;

 DoW ( Loop );
   rc = IFS_Read(fd :%Addr(File) :%Size(File));
   If ( rc <= 0 );
     IFS_Close(fd);
     IFS_Unlink(P_FILE);
     File = '*EOF>';
     Send(SocketID :%Addr(File) :%Len(%TrimR(File)) :0);
     Leave;
   EndIf;
   Bytes += rc;
   SendStatus('Sending data to host, ' + %Char(%DecH(Bytes/1024 :20 :0)) +
             ' KBytes transfered ...');
   Send(SocketID :%Addr(File) :rc :0);
   Clear File;
 EndDo;

 // Waiting for success-message
 Clear Data;
 SendStatus('Object(s) will be restored ...');
 rc = Recv(SocketID :%Addr(Data) :%Size(Data) :0);
 Select;
   When ( %Scan('*ERROR_RESTORE>' :Data) > 0 );
     //Close_Socket(SocketID);
     CALLP Close(SocketID);
     SendDie('Error: ' + %SubSt(Data :%Scan('>' :Data) + 1 :60));
     Return;
   When ( %Scan('*OK>' :Data) > 0 );
     SendStatus('Operation successfull.');
     System('DLTF FILE(QTEMP/SND)');
 EndSl;

 //Close_Socket(SocketID);
 CALLP Close(SocketID);

 Return;


END-PROC;

//**************************************************************************
DCL-PROC SendDie;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-PR SndPgmMsg EXTPGM('QMHSNDPM');
   MessageID CHAR(7) CONST;
   QualMsgFile CHAR(20) CONST;
   MsgData CHAR(256) CONST;
   MsgDtaLen INT(10) CONST;
   MsgType CHAR(10) CONST;
   CallStkEnt CHAR(10) CONST;
   CallStkCnt INT(10) CONST;
   MessageKey CHAR(4);
   ErrorCode CHAR(128);
 END-PR;

 DCL-S MessageLength INT(10) INZ;
 DCL-S MessageKey CHAR(4) INZ;
 DCL-S MessageError CHAR(128) INZ;
//-------------------------------------------------------------------------

 MessageLength = %Len(%TrimR(pMessage));
 If ( MessageLength < 1 );
   Return;
 EndIf;

 SndPgmMsg('CPF9897' :'QCPFMSG   *LIBL' :pMessage: MessageLength
           :'*ESCAPE' :'*PGMBDY' :1 :MessageKey :MessageError);

 Return;

END-PROC;

//**************************************************************************
DCL-PROC SendStatus;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-PR SndPgmMsg EXTPGM('QMHSNDPM');
   MessageID CHAR(7) CONST;
   QualMsgFile CHAR(20) CONST;
   MsgData CHAR(256) CONST;
   MsgDtaLen INT(10) CONST;
   MsgType CHAR(10) CONST;
   CallStkEnt CHAR(10) CONST;
   CallStkCnt INT(10) CONST;
   MessageKey CHAR(4);
   ErrorCode CHAR(128);
 END-PR;

 DCL-S MessageLength INT(10) INZ;
 DCL-S MessageKey CHAR(4) INZ;
 DCL-S MessageError CHAR(128) INZ;
//-------------------------------------------------------------------------

 MessageLength = %Len(%TrimR(pMessage));
 If ( MessageLength < 1 );
   Return;
 EndIf;

 SndPgmMsg('CPF9897' :'QCPFMSG   *LIBL' :pMessage :MessageLength
           :'*STATUS' :'*EXT' :0 :MessageKey :MessageError);

 Return;

END-PROC;

/DEFINE ERRNO_LOAD_PROCEDURE
/INCLUDE ERRNO_H
