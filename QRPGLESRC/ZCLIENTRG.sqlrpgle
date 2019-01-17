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

//  Created by BRC on 30.08.2018 - 17.01.2019

// Socketclient to send objects over tls to another IBMi
//   I use the socket_h and gskssl_h header from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);

DCL-PR Main EXTPGM('ZCLIENTRG');
  QualifiedObjectName CHAR(20) CONST;
  ObjectType CHAR(10) CONST;
  StreamFile CHAR(128) CONST;
  RemoteSystem CHAR(16) CONST;
  Authentication CHAR(7) CONST;
  UserProfile CHAR(10) CONST;
  Password CHAR(32) CONST;
  TargetRelease CHAR(8) CONST;
  RestoreLibrary CHAR(10) CONST;
  Port UNS(5) CONST;
  UseTLS IND CONST;
  DataCompression CHAR(7) CONST;
  SaveFile LIKEDS(QualifiedObjectName_Template) CONST;
  WorkPath CHAR(128) CONST;
END-PR;

/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,SYSTEM
/INCLUDE QRPGLECPY,ERRNO_H

/INCLUDE QRPGLECPY,PSDS
/INCLUDE QRPGLECPY,BOOLIC

DCL-DS QualifiedObjectName_Template TEMPLATE QUALIFIED;
  ObjectName CHAR(10);
  ObjectLibrary CHAR(10);
END-DS;
DCL-DS Socket_Template TEMPLATE QUALIFIED;
  ConnectTo POINTER;
  SocketHandler INT(10);
  Address UNS(10);
  AddressLength INT(10);
END-DS;
DCL-DS GSK_Template TEMPLATE QUALIFIED;
  Environment POINTER;
  SecureHandler POINTER;
END-DS;
DCL-DS MessageHandling_Template TEMPLATE QUALIFIED;
  Length INT(10);
  Key CHAR(4);
  Error CHAR(128);
END-DS;


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pQualifiedObjectName CHAR(20) CONST;
   pObjectType CHAR(10) CONST;
   pStreamFile CHAR(128) CONST;
   pRemoteSystem CHAR(16) CONST;
   pAuthentication CHAR(7) CONST;
   pUserProfile CHAR(10) CONST;
   pPassword CHAR(32) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pDataCompression CHAR(7) CONST;
   pSaveFile LIKEDS(QualifiedObjectName_Template) CONST;
   pWorkPath CHAR(128) CONST;
 END-PI;
 //-------------------------------------------------------------------------

 *INLR = TRUE;

 If ( %Parms() = 14 ) And ( pQualifiedObjectName <> '' );
   ManageSendingStuff(pQualifiedObjectName
                      :pObjectType
                      :pStreamfile
                      :pRemoteSystem
                      :pAuthentication
                      :pUserProfile
                      :pPassword
                      :pTargetRelease
                      :pRestoreLibrary
                      :pPort
                      :pUseTLS
                      :pDataCompression
                      :pSaveFile
                      :pWorkPath);
 EndIf;

 Return;

END-PROC;


//**************************************************************************
DCL-PROC ManageSendingStuff;
 DCL-PI *N;
   pQualifiedObjectName
     LIKEDS(QualifiedObjectName_Template) CONST;
   pObjectType CHAR(10) CONST;
   pStreamFile CHAR(128) CONST;
   pRemoteSystem CHAR(16) CONST;
   pAuthentication CHAR(7) CONST;
   pUserProfile CHAR(10) CONST;
   pPassword CHAR(32) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pDataCompression CHAR(7) CONST;
   pSaveFile LIKEDS(QualifiedObjectName_Template) CONST;
   pWorkPath CHAR(128) CONST;
 END-PI;

 DCL-PR ManageSavefile EXTPGM('ZCLIENTCL');
   Save CHAR(64) CONST;
   File CHAR(64) CONST;
 END-PR;

/INCLUDE QRPGLECPY,IFS_H

 DCL-S KEY CHAR(40) INZ('yourkey');
 DCL-S Loop IND INZ(TRUE);

 DCL-S RC INT(10) INZ;
 DCL-S Data CHAR(1024) INZ;
 DCL-S Work CHAR(1024) INZ;
 DCL-S SaveCommand CHAR(1024) INZ;
 DCL-S ErrorNumber INT(10) INZ;

 DCL-DS SendingFile QUALIFIED INZ;
   FileHandler INT(10);
   Length INT(10);
   Data CHAR(32766);
   Bytes UNS(20);
 END-DS;

 DCL-DS ClientSocket LIKEDS(Socket_Template) INZ;
 DCL-DS GSK LIKEDS(GSK_Template) INZ;
 //-------------------------------------------------------------------------

 // Quickcheck for some necessary parameters
 If ( pAuthentication = '*USRPRF' ) And ( pUserProfile = '' );
   SendDie('No userprofile selected.');
 EndIf;
 If ( pAuthentication = '*USRPRF' ) And ( pPassword = '' );
   SendDie('No password selected.');
 EndIf;
 If ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile = '' );
   SendDie('No streamfile selected.');
 EndIf;

 // Check for selected object
 Select;
   When ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*ALL' );
     Clear RC;
   When ( pQualifiedObjectName.ObjectName <> '*STMF' )
    And ( %Scan('*' :pQualifiedObjectName.ObjectName) > 0 );
      Clear RC;
   When ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*LIB' );
     RC = System('CHKOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') OBJTYPE(*LIB)');
   When ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile <> '' )
    And ( %Scan('*' :pStreamfile) > 0 );
      Clear RC;
   When ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile <> '' )
    And ( %Scan('*' :pStreamfile) = 0 );
     RC = IFS_Access(%TrimR(pStreamFile) :F_OK);
   Other;
     RC = System('CHKOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectLibrary) + '/' +
                  %TrimR(pQualifiedObjectName.ObjectName) + ') OBJTYPE(' +
                  %TrimR(pObjectType) + ')');
 EndSl;

 If ( RC <> 0 );
   SendDie('Object(s) not found.');
 EndIf;

 // Search adress via hostname
 ClientSocket.Address = INet_Addr(%TrimR(pRemoteSystem));
 If ( ClientSocket.Address = INADDR_NONE );
   P_HostEnt = GetHostByName(%TrimR(pRemoteSystem));
   If ( P_HostEnt = *NULL );
     SendDie('Unable to find selected host.');
   EndIf;
   ClientSocket.Address = H_Addr;
 EndIf;

 If pUseTLS;
   GSK = GenerateGSKEnvironment();
 EndIf;

 // Create socket
 ClientSocket.SocketHandler = Socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( ClientSocket.SocketHandler < 0 );
   CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
   SendDie(%Str(strerror(ErrNo)));
 EndIf;

 ClientSocket.AddressLength = %Size(SockAddr);
 ClientSocket.ConnectTo = %Alloc(ClientSocket.AddressLength);

 P_SockAddr = ClientSocket.ConnectTo;
 Sin_Family = AF_INET;
 Sin_Addr   = ClientSocket.Address;
 Sin_Port   = pPort;
 Sin_Zero   = *ALLx'00';

 // Connect to host
 If ( Connect(ClientSocket.SocketHandler :ClientSocket.ConnectTo
              :ClientSocket.AddressLength) < 0 );
   ErrorNumber = ErrNo;
   CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
   SendDie(%Str(strerror(ErrorNumber)));
 EndIf;

 If pUseTLS;
   InitGSKEnvironment(pUseTLS :ClientSocket.SocketHandler :GSK);
 EndIf;

 // Send protocoll and session-name
 Data = '*ZZv1>' + %TrimR(PSDS.JobName);
 SendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
 RC = RecieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 Select;
   When ( RC <= 0 );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Can''t connect to host.');
   When ( Data = '*UNKNOWNSESSION>' );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Unknown session recieved. Connection was canceled.');
   When ( Data = '*UNKNOWNPROTOCOLL>' );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Unknown protcoll recieved. Connection was canceled.');
   When ( Data = '*OK>' );
     SendStatus('Connection successfull.');
 EndSl;

 // Send username and password to host when selected
 If ( pAuthentication = '*USRPRF' );
   SendStatus('Start login at host ...');
   Exec SQL SET :Work = ENCRYPT_TDES(:pPassword, :Key);
   If ( pUserProfile = '*CURRENT' );
     Data = PSDS.UserName + %TrimR(Work);
   Else;
     Data = pUserProfile + %TrimR(Work);
   EndIf;
   SendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
   RC = RecieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Login failed.');
   EndIf;

   Work = %SubSt(Data:%Scan('>' :Data) + 1 :(RC - %Scan('>' :Data)));
   Data = %SubSt(Data :1 :%Scan('>' :Data));

   Select;
     When ( Data = '*NOLOGINDATA>' );
       CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
       SendDie('No login data recieved.');
     When ( Data = '*NOPWD>' );
       CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
       SendDie('Wrong password > ' + %TrimR(Work));
     When ( Data = '*NOACCESS>' );
       CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
       SendDie('Access denied > ' + %TrimR(Work));
     When ( Data = '*OK>' );
       SendStatus('Login ok.');
   EndSl;
 ElseIf ( pAuthentication = '*NONE' );
   Data = '*AUTH_NONE>';
   SendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
   Clear Data;
   RC = RecieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Login failed.');
   ElseIf ( Data <> '*OK>' );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Authentication *NONE not allowed.');
   EndIf;
 EndIf;

 // Save objects and prepare
 SendStatus('Saving object(s), this may take a few moments ...');
 System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                       %TrimR(pSaveFile.ObjectName) + ')');
 System('CRTSAVF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                          %TrimR(pSaveFile.ObjectName) + ')');

 If ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*LIB' );
   SaveCommand = 'SAVLIB LIB(' + %TrimR(pQualifiedObjectName.ObjectName) +
                 ') DEV(*SAVF) SAVF(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                 %TrimR(pSaveFile.ObjectName) +') TGTRLS(' + %TrimR(pTargetRelease) +
                 ') SAVACT(*LIB) DTACPR(' + %TrimR(pDataCompression) + ')';
 ElseIf ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType <> '*LIB' );
   SaveCommand = 'SAVOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') LIB(' +
                 %TrimR(pQualifiedObjectName.ObjectLibrary) + ') '+
                 'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) ' +
                 'SAVF(' + %TrimR(pSaveFile.ObjectLibrary) + '/' + %TrimR(pSaveFile.ObjectName) +
                 ') TGTRLS(' + %TrimR(pTargetRelease) + ') SAVACT(*LIB) ' +
                 'DTACPR(' + %TrimR(pDataCompression) + ')';
 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile <> '' );
   SaveCommand = 'SAV DEV(''/QSYS.LIB/' + %TrimR(pSaveFile.ObjectLibrary) + '.LIB/' +
                  %TrimR(pSaveFile.ObjectName) + '.FILE'') OBJ(''' + %TrimR(pStreamFile) +
                  ''') SUBTREE(*ALL) TGTRLS(' + %TrimR(pTargetRelease) + ') ' +
                  'DTACPR(' +  %TrimR(pDataCompression) + ')';
 EndIf;

 RC = System(SaveCommand);
 If ( RC <> 0 );
   CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
   System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                         %TrimR(pSaveFile.ObjectName) + ')');
   SendDie('Error occured while saving data. See joblog.');
 EndIf;

 SendStatus('Prepare savefile to send, this may take a few moments ...');
 Monitor;
   ManageSavefile('/QSYS.LIB/' + %TrimR(pSaveFile.ObjectLibrary) + '.LIB/' +
                                 %TrimR(pSaveFile.ObjectName) + '.FILE' :pWorkPath);
   On-Error;
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     IFS_Unlink(%triMR(pWorkPath));
     System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                           %TrimR(pSaveFile.ObjectName) + ')');
     SendDie('Error occured while preparing savefile. See joblog.');
 EndMon;

 System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                       %TrimR(pSaveFile.ObjectName) + ')');

 // Send restoreinformations
 SendStatus('Send restore instructions');
 If ( pQualifiedObjectName.ObjectName <> '*STMF') And ( pObjectType = '*LIB' );
   Data = 'RSTLIB SAVLIB(' + %TrimR(pQualifiedObjectName.ObjectName) +
          ') DEV(*SAVF) SAVF(QTEMP/RCV) MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB('
          + %TrimR(pRestoreLibrary) + ')';
 ElseIf ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType <> '*LIB' );
   Data = 'RSTOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') SAVLIB(' +
          %TrimR(pQualifiedObjectName.ObjectLibrary) + ') ' +
          'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) SAVF(QTEMP/RCV) ' +
          'MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB(' + %TrimR(pRestoreLibrary) + ')';
 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' );
   Data = 'RST DEV(''/QSYS.LIB/QTEMP.LIB/RCV.FILE'') OBJ(''' + %TrimR(pStreamFile) + ''') ' +
          'SUBTREE(*ALL) CRTPRNDIR(*YES) ALWOBJDIF(*ALL)';
 EndIf;
 SendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
 Clear Data;
 RC = RecieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 If ( RC < 0 ) Or ( Data <> '*OK>' );
   CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
   SendDie('Invalid restore instructions transfered.');
 EndIf;

 // Send object
 SendStatus('Sending data to host ...');
 SendingFile.FileHandler = IFS_Open(%TrimR(pWorkPath) :O_RDONLY + O_LARGEFILE);
 If ( SendingFile.FileHandler < 0 );
   ErrorNumber = ErrNo;
   CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
   IFS_Unlink(%TrimR(pWorkPath));
   SendDie('Error occured while reading file > ' + %Str(strerror(ErrorNumber)));
 EndIf;

 DoW ( Loop );
   SendingFile.Length = IFS_Read(SendingFile.FileHandler :%Addr(SendingFile.Data)
                                 :%Size(SendingFile.Data));
   If ( SendingFile.Length < (%Size(SendingFile.Data) - 5) );
     IFS_Close(SendingFile.FileHandler);
     IFS_Unlink(%TrimR(pWorkPath));
     SendingFile.Data = %SubSt(SendingFile.Data :1 :SendingFile.Length) + '*EOF>';
     SendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(SendingFile.Data)
              :SendingFile.Length + 5);
     Leave;
   EndIf;
   SendingFile.Bytes += SendingFile.Length;
   SendStatus('Sending data to host, ' + %Char(%DecH(SendingFile.Bytes/1024 :17 :2)) +
              ' KBytes transfered ...');
   SendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(SendingFile.Data) :SendingFile.Length);
   Clear SendingFile.Data;
 EndDo;

 // Waiting for success-message
 Clear Data;
 SendStatus('Please wait, object(s) will be restored on the host system ...');
 RC = RecieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 Select;
   When ( %Scan('*ERROR_RESTORE>' :Data) > 0 );
     CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);
     SendDie('Operation canceled: ' + %SubSt(Data :%Scan('>' :Data) + 1 :60));
   When ( %Scan('*OK>' :Data) > 0 );
     SendStatus('Operation was successfull.');
     System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                           %TrimR(pSaveFile.ObjectName) + ')');
 EndSl;

 CleanUp_Socket(pUseTLS :ClientSocket.SocketHandler :GSK);

 Return;


END-PROC;

//**************************************************************************
DCL-PROC GenerateGSKEnvironment;
 DCL-PI *N LIKEDS(GSK_Template) END-PI;

 DCL-S RC INT(10) INZ;

 DCL-DS GSK LIKEDS(GSK_Template) INZ;
 //-------------------------------------------------------------------------

 RC = GSK_Environment_Open(GSK.Environment);
 If ( RC <> GSK_OK );
   SendDie(%Str(GSK_StrError(RC)));
 EndIf;

 GSK_Attribute_Set_Buffer(GSK.Environment :GSK_KEYRING_FILE :'*SYSTEM' :0);

 GSK_Attribute_Set_eNum(GSK.Environment :GSK_SESSION_TYPE :GSK_CLIENT_SESSION);

 GSK_Attribute_Set_eNum(GSK.Environment :GSK_SERVER_AUTH_TYPE :GSK_SERVER_AUTH_PASSTHRU);
 GSK_Attribute_Set_eNum(GSK.Environment :GSK_CLIENT_AUTH_TYPE :GSK_CLIENT_AUTH_PASSTHRU);

 GSK_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_SSLV2 :GSK_PROTOCOL_SSLV2_ON);
 GSK_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_SSLV3 :GSK_PROTOCOL_SSLV3_ON);
 GSK_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_TLSV1 :GSK_PROTOCOL_TLSV1_ON);

 RC = GSK_Environment_Init(GSK.Environment);
 If ( RC <> GSK_OK );
   GSK_Environment_Close(GSK.Environment);
   SendDie(%Str(GSK_StrError(RC)));
 EndIf;

 Return GSK;

END-PROC;

//**************************************************************************
DCL-PROC InitGSKEnvironment;
 DCL-PI *N;
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
   pGSK LIKEDS(GSK_Template);
 END-PI;

 DCL-S RC INT(10) INZ;
 //-------------------------------------------------------------------------

   SendStatus('Try to make a handshake with the server ...');
   RC = GSK_Secure_Soc_Open(pGSK.Environment :pGSK.SecureHandler);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :pSocketHandler :pGSK);
     SendDie(%Str(GSK_StrError(RC)));
   EndIf;

   RC = GSK_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_FD :pSocketHandler);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :pSocketHandler :pGSK);
     SendDie(%Str(GSK_StrError(RC)));
   EndIf;

   RC = GSK_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_HANDSHAKE_TIMEOUT :10);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :pSocketHandler :pGSK);
     SendDie(%Str(GSK_StrError(RC)));
   EndIf;

   RC = GSK_Secure_Soc_Init(pGSK.SecureHandler);
   If ( RC <> GSK_OK );
     CleanUp_Socket(pUseTLS :pSocketHandler :pGSK);
     SendDie(%Str(GSK_StrError(RC)));
   EndIf;

END-PROC;


//**************************************************************************
DCL-PROC SendData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
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
   pGSK LIKEDS(GSK_Template);
 END-PI;
 //-------------------------------------------------------------------------

 If pUseTLS;
   GSK_Secure_Soc_Close(pGSK.SecureHandler);
   GSK_Environment_Close(pGSK.Environment);
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
DCL-PROC SendStatus;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_Template) INZ;
 //-------------------------------------------------------------------------

 Message.Length = %Len(%TrimR(pMessage));
 If ( Message.Length >= 0 );
   SndPgmMsg('CPF9897'  :'QCPFMSG   *LIBL' :pMessage :Message.Length
             :'*STATUS' :'*EXT' :0 :Message.Key :Message.Error);
 EndIf;

END-PROC;

/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
