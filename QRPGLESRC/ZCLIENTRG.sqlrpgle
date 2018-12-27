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

//  Created by BRC on 30.08.2018 - 27.12.2018

// Socketclient to send objects over tls to another IBMi
//   Based on the socketapi from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);

DCL-PR Main EXTPGM('ZCLIENTRG');
  QualifiedObjectName CHAR(20) CONST;
  ObjectType CHAR(10) CONST;
  Host CHAR(16) CONST;
  User CHAR(10) CONST;
  Password CHAR(32) CONST;
  TargetRelease CHAR(8) CONST;
  RestoreLibrary CHAR(10) CONST;
  Port UNS(5) CONST;
  UseTLS IND CONST;
  DtaCpr CHAR(7) CONST;
END-PR;

/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,SYSTEM

DCL-PR ManageSendingStuff;
  QualifiedObjectName CHAR(20) CONST;
  ObjectType CHAR(10) CONST;
  Host CHAR(16) CONST;
  User CHAR(10) CONST;
  Password CHAR(32) CONST;
  TargetRelease CHAR(8) CONST;
  RestoreLibrary CHAR(10) CONST;
  Port UNS(5) CONST;
  UseTLS IND CONST;
  DtaCpr CHAR(7) CONST;
END-PR;
DCL-PR GenerateGSKEnvironment END-PR;
DCL-PR SendData INT(10);
  UseTLS IND CONST;
  SocketHandler INT(10) CONST;
  Data POINTER VALUE;
  Length INT(10) CONST;
END-PR;
DCL-PR RecieveData INT(10);
  UseTLS IND CONST;
  SocketHandler INT(10) CONST;
  Data POINTER VALUE;
  Length INT(10) VALUE;
END-PR;
DCL-PR CleanUp_Socket;
  UseTLS IND CONST;
  SocketHandler INT(10) CONST;
END-PR;
DCL-PR SendDie;
  Message CHAR(256) CONST;
END-PR;
DCL-PR SendStatus;
  Message CHAR(256) CONST;
END-PR;

DCL-C TRUE  *ON;
DCL-C FALSE *OFF;

/INCLUDE QRPGLECPY,ERRNO_H

DCL-S GSKEnvironment POINTER INZ;
DCL-S GSKHandler POINTER INZ;


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pQualifiedObjectName CHAR(20) CONST;
   pObjectType CHAR(10) CONST;
   pHost CHAR(16) CONST;
   pUser CHAR(10) CONST;
   pPassword CHAR(32) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pDtaCpr CHAR(7) CONST;
 END-PI;
 //-------------------------------------------------------------------------

 *INLR = TRUE;

 If ( %Parms() = 10 ) And ( pQualifiedObjectName <> '' );
   ManageSendingStuff(pQualifiedObjectName :pObjectType :pHost :pUser
                      :pPassword :pTargetRelease :pRestoreLibrary :pPort
                      :pUseTLS :pDtaCpr);
 EndIf;

 Return;

END-PROC;


//**************************************************************************
DCL-PROC ManageSendingStuff;
 DCL-PI *N;
   pQualifiedObjectName CHAR(20) CONST;
   pObjectType CHAR(10) CONST;
   pHost CHAR(16) CONST;
   pUser CHAR(10) CONST;
   pPassword CHAR(32) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pDtaCpr CHAR(7) CONST;
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

 DCL-C O_RDONLY 1;
 DCL-C O_WRONLY 2;
 DCL-C O_CREAT 8;
 DCL-C O_TRUNC 64;
 DCL-C O_TEXTDATA 16777216;
 DCL-C O_CODEPAGE 8388608;
 DCL-C O_LARGEFILE 536870912;
 DCL-C P_SAVE '/QSYS.LIB/QTEMP.LIB/SND.FILE';
 DCL-C P_FILE '/tmp/snd.file';

 DCL-S KEY CHAR(40) INZ('yourkey');
 DCL-S Loop IND INZ(TRUE);

 DCL-S FD INT(10) INZ;
 DCL-S RC INT(10) INZ;
 DCL-S Data CHAR(1024) INZ;
 DCL-S Work CHAR(1024) INZ;
 DCL-S SaveCommand CHAR(1024) INZ;
 DCL-S File CHAR(32766) INZ;
 DCL-S FileLength INT(10) INZ;
 DCL-S Bytes UNS(20) INZ;
 DCL-S ConnectTo POINTER INZ;
 DCL-S LocalSocket INT(10) INZ;
 DCL-S Address UNS(10) INZ;
 DCL-S AddressLength INT(10) INZ;
 DCL-S ErrNumber INT(10) INZ;

 DCL-DS QualifiedObjectName QUALIFIED INZ;
   ObjectName CHAR(10);
   ObjectLibrary CHAR(10);
 END-DS;
 //-------------------------------------------------------------------------

 QualifiedObjectName = pQualifiedObjectName;

 // Check for selected object
 Select;
   When ( pObjectType = '*ALL' ) Or ( %Scan('*' :QualifiedObjectName.ObjectName) > 0 );
     Clear RC;
   When ( pObjectType = '*LIB' );
     RC = System('CHKOBJ OBJ(' + %TrimR(QualifiedObjectName.ObjectName) + ') OBJTYPE(*LIB)');
   Other;
     RC = System('CHKOBJ OBJ(' + %TrimR(QualifiedObjectName.ObjectLibrary) + '/' +
                  %TrimR(QualifiedObjectName.ObjectName) + ') OBJTYPE(' +
                  %TrimR(pObjectType) + ')');
 EndSl;

 If ( RC <> 0 );
   SendDie('Object(s) not found.');
   Return;
 EndIf;

 // Search adress via hostname
 Address = INet_Addr(%TrimR(pHost));
 If ( Address = INADDR_NONE );
   P_HostEnt = GetHostByName(%TrimR(pHost));
   If ( P_HostEnt = *NULL );
     SendDie('Unable to find selected host.');
     Return;
   EndIf;
   Address = H_Addr;
 EndIf;

 If pUseTLS;
   GenerateGSKEnvironment();
 EndIf;

 // Create socket
 LocalSocket = Socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( LocalSocket < 0 );
   CleanUp_Socket(pUseTLS :LocalSocket);
   SendDie('socket(): ' + %Str(StrError(ErrNo)));
 EndIf;

 AddressLength = %Size(SockAddr);
 ConnectTo = %Alloc(AddressLength);

 P_SockAddr = ConnectTo;
 Sin_Family = AF_INET;
 Sin_Addr = Address;
 Sin_Port = pPort;
 Sin_Zero = *ALLx'00';

 // Connect to host
 If ( Connect(LocalSocket :ConnectTo :AddressLength) < 0 );
   ErrNumber = ErrNo;
   CleanUp_Socket(pUseTLS :LocalSocket);
   SendDie('connect(): ' + %Str(StrError(ErrNumber)));
 EndIf;

 If pUseTLS;
 // Open TLS with handshake
   SendStatus('Try to make a handshake with the server ...');
   RC = GSK_Secure_Soc_Open(GSKEnvironment :GSKHandler);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('GSK_Secure_Soc_Open(): ' + %Str(GSK_StrError(RC)));
   EndIf;

   RC = GSK_Attribute_Set_Numeric_Value(GSKHandler :GSK_FD :LocalSocket);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('GSK_Attribute_Set_Numeric_Value(): ' + %Str(GSK_StrError(RC)));
   EndIf;

   RC = GSK_Attribute_Set_Numeric_Value(GSKHandler :GSK_HANDSHAKE_TIMEOUT :10);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('GSK_Attribute_Set_Numeric_Value(): ' + %Str(GSK_StrError(RC)));
   EndIf;

   RC = GSK_Secure_Soc_Init(GSKHandler);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('GSK_Secure_Soc_Init(): ' + %Str(GSK_StrError(RC)));
   EndIf;
 EndIf;

 // Send username and password to host when selected
 If ( pUser <> '*NONE' );
   SendStatus('Start login at host ...');
   Exec SQL SET :Work = ENCRYPT_TDES(:pPassword, :Key);
   Data = pUser + %TrimR(Work);
   SendData(pUseTLS :LocalSocket :%Addr(Data) :%Len(%TrimR(Data)));
   RC = RecieveData(pUseTLS :LocalSocket :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('Login failed.');
   EndIf;

   Work = %SubSt(Data:%Scan('>' :Data) + 1 :(RC - %Scan('>' :Data)));
   Data = %SubSt(Data :1 :%Scan('>' :Data));

   Select;
     When ( Data = '*NOLOGINDATA>' );
       CleanUp_Socket(pUseTLS :LocalSocket);
       SendDie('No login data recieved.');
     When ( Data = '*NOPWD>' );
       CleanUp_Socket(pUseTLS :LocalSocket);
       SendDie('Wrong password > ' + %TrimR(Work));
     When ( Data = '*NOACCESS>' );
       CleanUp_Socket(pUseTLS :LocalSocket);
       SendDie('Access denied > ' + %TrimR(Work));
     When ( Data = '*OK>' );
       SendStatus('Login ok.');
   EndSl;
 Else;
   Data = pUser;
   SendData(pUseTLS :LocalSocket :%Addr(Data) :%Len(%TrimR(Data)));
   RC = RecieveData(pUseTLS :LocalSocket :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('Login failed.');
   EndIf;
   If ( Data <> '*OK>' );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('Authentication *NONE not allowed.');
   EndIf;
 EndIf;

 // Save objects and prepare
 SendStatus('Saving object(s), this may take a few moments ...');
 System('DLTF QTEMP/SND');
 System('CRTSAVF QTEMP/SND');
 If ( pObjectType = '*LIB' );
   SaveCommand = 'SAVLIB LIB(' + %TrimR(QualifiedObjectName.ObjectName) +
                 ') DEV(*SAVF) SAVF(QTEMP/SND) ' + 'TGTRLS(' + %TrimR(pTargetRelease) +
                 ') SAVACT(*LIB) DTACPR(' + %TrimR(pDtaCpr) + ')';
 Else;
   SaveCommand = 'SAVOBJ OBJ(' + %TrimR(QualifiedObjectName.ObjectName) + ') LIB(' +
                 %TrimR(QualifiedObjectName.ObjectLibrary) + ') '+
                 'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) SAVF(QTEMP/SND) ' +
                 'TGTRLS(' + %TrimR(pTargetRelease) + ') SAVACT(*LIB) ' +
                 'DTACPR(' + %TrimR(pDtaCpr) + ')';
 EndIf;
 FD = System(SaveCommand);
 If ( FD < 0 );
   CleanUp_Socket(pUseTLS :LocalSocket);
   System('DLTF FILE(QTEMP/SND)');
   SendDie('Error occured while saving data. See joblog.');
 EndIf;

 SendStatus('Prepare savefile to send, this may take a few moments ...');
 Monitor;
   EC#ZCLIENT(P_SAVE :P_FILE);
   On-Error;
     CleanUp_Socket(pUseTLS :LocalSocket);
     IFS_Unlink(P_FILE);
     System('DLTF FILE(QTEMP/SND)');
     SendDie('Error occured while preparing savefile. See joblog.');
 EndMon;

 System('DLTF QTEMP/SND');

 // Send restoreinformations
 SendStatus('Send restore instructions');
 If ( pObjectType = '*LIB' );
   Data = 'RSTLIB SAVLIB(' + %TrimR(QualifiedObjectName.ObjectName) +
          ') DEV(*SAVF) SAVF(QTEMP/RCV) MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB('
          + %TrimR(pRestoreLibrary) + ')';
 Else;
   Data = 'RSTOBJ OBJ(' + %TrimR(QualifiedObjectName.ObjectName) + ') SAVLIB(' +
          %TrimR(QualifiedObjectName.ObjectLibrary) + ') ' +
          'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) SAVF(QTEMP/RCV) ' +
          'MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB(' + %TrimR(pRestoreLibrary) + ')';
 EndIf;
 SendData(pUseTLS :LocalSocket :%Addr(Data) :%Len(%TrimR(Data)));

 // Send object
 SendStatus('Sending data to host ...');
 FD = IFS_Open(P_FILE :O_RDONLY + O_LARGEFILE);
 If ( FD < 0 );
   ErrNumber = ErrNo;
   CleanUp_Socket(pUseTLS :LocalSocket);
   IFS_Unlink(P_FILE);
   SendDie('Error occured while reading file > ' + %Str(StrError(ErrNumber)));
 EndIf;

 DoW ( Loop );
   FileLength = IFS_Read(FD :%Addr(File) :%Size(File));
   If ( FileLength < (%Size(File) - 5) );
     IFS_Close(FD);
     IFS_Unlink(P_FILE);
     File = %SubSt(File :1 :FileLength) + '*EOF>';
     SendData(pUseTLS :LocalSocket :%Addr(File) :FileLength + 5);
     Leave;
   EndIf;
   Bytes += FileLength;
   SendStatus('Sending data to host, ' + %Char(%DecH(Bytes/1024 :17 :2)) +
             ' KBytes transfered ...');
   SendData(pUseTLS :LocalSocket :%Addr(File) :FileLength);
   Clear File;
 EndDo;

 // Waiting for success-message
 Clear Data;
 SendStatus('Please wait, object(s) will be restored on the host system ...');
 RC = RecieveData(pUseTLS :LocalSocket :%Addr(Data) :%Size(Data));
 Select;
   When ( %Scan('*ERROR_RESTORE>' :Data) > 0 );
     CleanUp_Socket(pUseTLS :LocalSocket);
     SendDie('Operation canceled: ' + %SubSt(Data :%Scan('>' :Data) + 1 :60));
   When ( %Scan('*OK>' :Data) > 0 );
     SendStatus('Operation was successfull.');
     System('DLTF FILE(QTEMP/SND)');
 EndSl;

 CleanUp_Socket(pUseTLS :LocalSocket);

 Return;


END-PROC;

//**************************************************************************
DCL-PROC GenerateGSKEnvironment;

 DCL-S RC INT(10) INZ;
 //-------------------------------------------------------------------------

 RC = GSK_Environment_Open(GSKEnvironment);
 If ( RC <> GSK_OK );
   SendDie('GSK_Environment_Open(): ' + %Str(GSK_StrError(RC)));
 EndIf;

 GSK_Attribute_Set_Buffer(GSKEnvironment :GSK_KEYRING_FILE :'*SYSTEM' :0);

 GSK_Attribute_Set_eNum(GSKEnvironment :GSK_SESSION_TYPE :GSK_CLIENT_SESSION);

 GSK_Attribute_Set_eNum(GSKEnvironment :GSK_SERVER_AUTH_TYPE :GSK_SERVER_AUTH_PASSTHRU);
 GSK_Attribute_Set_eNum(GSKEnvironment :GSK_CLIENT_AUTH_TYPE :GSK_CLIENT_AUTH_PASSTHRU);

 GSK_Attribute_Set_eNum(GSKEnvironment :GSK_PROTOCOL_SSLV2 :GSK_PROTOCOL_SSLV2_ON);
 GSK_Attribute_Set_eNum(GSKEnvironment :GSK_PROTOCOL_SSLV3 :GSK_PROTOCOL_SSLV3_ON);
 GSK_Attribute_Set_eNum(GSKEnvironment :GSK_PROTOCOL_TLSV1 :GSK_PROTOCOL_TLSV1_ON);

 RC = GSK_Environment_Init(GSKEnvironment);
 If ( RC <> GSK_OK );
   GSK_Environment_Close(GSKEnvironment);
   SendDie('GSK_Environment_Init(): ' + %Str(GSK_StrError(RC)));
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC SendData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
   pData POINTER VALUE;
   pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = GSK_Secure_Soc_Write(GSKHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC = GSK_OK );
     RC = GSKLength;
   Else;
     Clear RC;
   EndIf;
 Else;
   RC = Send(pSocketHandler :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC RecieveData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
   pData POINTER VALUE;
   pLength INT(10) VALUE;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 DCL-S Buffer CHAR(32766) BASED(pData);
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = GSK_Secure_Soc_Read(GSKHandler :%Addr(Buffer) :pLength :GSKLength);
   If ( RC = GSK_OK ) And ( GSKLength > 0 );
     Buffer = %SubSt(Buffer :1 :GSKLength);
   EndIf;
   RC = GSKLength;
 Else;
   RC = Recv(pSocketHandler :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

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
   GSK_Environment_Close(GSKEnvironment);
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
DCL-PROC SendStatus;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-S MessageLength INT(10) INZ;
 DCL-S MessageKey CHAR(4) INZ;
 DCL-S MessageError CHAR(128) INZ;
 //-------------------------------------------------------------------------

 MessageLength = %Len(%TrimR(pMessage));
 If ( MessageLength >= 0 );
   SndPgmMsg('CPF9897'  :'QCPFMSG   *LIBL' :pMessage :MessageLength
             :'*STATUS' :'*EXT' :0 :MessageKey :MessageError);
 EndIf;

END-PROC;

/DEFINE ERRNO_LOAD_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
