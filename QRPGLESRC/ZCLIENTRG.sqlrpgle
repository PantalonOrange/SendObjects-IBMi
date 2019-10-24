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

//  Created by BRC on 30.08.2018 - 29.05.2019

// Socketclient to send objects over tls to another IBMi
//   I use the socket_h header from scott klement - (c) Scott Klement
//   https://www.scottklement.com/rpg/socktut/socktut.savf


// Changes:
//  17.10.2019  Disabled elder ssl and tls protocolls
//               Add varying streamfilepathparm over command
//  23.10.2019  Cosmetic changes


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);


DCL-PR Main EXTPGM('ZCLIENTRG');
  QualifiedObjectName CHAR(20) CONST;
  ObjectType CHAR(10) CONST;
  StreamFile LIKEDS(CommandVaryingParm_T) CONST;
  RemoteSystem LIKEDS(CommandVaryingParm_T) CONST;
  Authentication CHAR(7) CONST;
  UserProfile CHAR(10) CONST;
  Password LIKEDS(CommandVaryingParm_T) CONST;
  TargetRelease CHAR(8) CONST;
  RestoreLibrary CHAR(10) CONST;
  Port UNS(5) CONST;
  UseTLS IND CONST;
  DataCompression CHAR(7) CONST;
  SaveFile LIKEDS(QualifiedObjectName_T) CONST;
  WorkPath CHAR(128) CONST;
END-PR;


/INCLUDE QRPGLECPY,SOCKET_H
/INCLUDE QRPGLECPY,GSKSSL_H
/INCLUDE QRPGLECPY,IFS_H
/INCLUDE QRPGLECPY,QMHSNDPM
/INCLUDE QRPGLECPY,SYSTEM
/INCLUDE QRPGLECPY,ERRNO_H

/INCLUDE QRPGLECPY,PSDS
/INCLUDE QRPGLECPY,BOOLIC

/DEFINE IS_ZCLIENT
/INCLUDE QRPGLECPY,Z_H


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pQualifiedObjectName CHAR(20) CONST;
   pObjectType CHAR(10) CONST;
   pStreamFile LIKEDS(CommandVaryingParm_T) CONST;
   pRemoteSystem LIKEDS(CommandVaryingParm_T) CONST;
   pAuthentication CHAR(7) CONST;
   pUserProfile CHAR(10) CONST;
   pPassword LIKEDS(CommandVaryingParm_T) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pDataCompression CHAR(7) CONST;
   pSaveFile LIKEDS(QualifiedObjectName_T) CONST;
   pWorkPath CHAR(128) CONST;
 END-PI;
 //-------------------------------------------------------------------------

 *INLR = TRUE;

 If ( %Parms() = 14 ) And ( pQualifiedObjectName <> '' );
   manageSendingStuff(pQualifiedObjectName
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
DCL-PROC manageSendingStuff;
 DCL-PI *N;
   pQualifiedObjectName LIKEDS(QualifiedObjectName_T) CONST;
   pObjectType CHAR(10) CONST;
   pStreamFile LIKEDS(CommandVaryingParm_T) CONST;
   pRemoteSystem LIKEDS(CommandVaryingParm_T) CONST;
   pAuthentication CHAR(7) CONST;
   pUserProfile CHAR(10) CONST;
   pPassword LIKEDS(CommandVaryingParm_T) CONST;
   pTargetRelease CHAR(8) CONST;
   pRestoreLibrary CHAR(10) CONST;
   pPort UNS(5) CONST;
   pUseTLS IND CONST;
   pDataCompression CHAR(7) CONST;
   pSaveFile LIKEDS(QualifiedObjectName_T) CONST;
   pWorkPath CHAR(128) CONST;
 END-PI;

 DCL-S Loop IND INZ(TRUE);
 DCL-S SaveSuccess IND INZ(TRUE);

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

 DCL-DS ClientSocket LIKEDS(Socket_T) INZ;
 DCL-DS GSK LIKEDS(GSK_T) INZ;
 DCL-DS StatDS LIKEDS(Stat_T) INZ;
 //-------------------------------------------------------------------------

 // Quickcheck for some necessary parameters
 If ( pAuthentication = '*USRPRF' ) And ( pUserProfile = '' );
   sendDie('No userprofile selected.');
 ElseIf ( pAuthentication = '*USRPRF' ) And ( pPassword.Length = 0 );
   sendDie('No password selected.');
 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Length = 0 );
   sendDie('No streamfile selected.');
 ElseIf ( pRemoteSystem.Length = 0 );
   sendDie('No host selected.');
 EndIf;

 // Check for selected object
 Select;
   When ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*ALL' );
     Clear RC;
   When ( pQualifiedObjectName.ObjectName <> '*STMF' )
    And ( %Scan('*' :pQualifiedObjectName.ObjectName) > 0 );
      Clear RC;
   When ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*LIB' );
     RC = system('CHKOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') OBJTYPE(*LIB)');
   When ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Length > 0 )
    And ( %Scan('*' :pStreamfile.Data) > 0 );
      Clear RC;
   When ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Length > 0 )
    And ( %Scan('*' :pStreamfile.Data) = 0 );
     RC = ifs_Access(%TrimR(pStreamFile.Data) :F_OK);
   Other;
     RC = system('CHKOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectLibrary) + '/' +
                  %TrimR(pQualifiedObjectName.ObjectName) + ') OBJTYPE(' +
                  %TrimR(pObjectType) + ')');
 EndSl;

 If ( RC <> 0 );
   sendDie('Object(s) not found or accessable.');
 EndIf;

 // Search adress via hostname
 ClientSocket.Address = inet_Addr(%TrimR(pRemoteSystem.Data));
 If ( ClientSocket.Address = INADDR_NONE );
   P_HostEnt = getHostByName(%TrimR(pRemoteSystem.Data));
   If ( P_HostEnt = *NULL );
     sendDie('Unable to find selected host.');
   EndIf;
   ClientSocket.Address = H_Addr;
 EndIf;

 If pUseTLS;
   GSK = generateGSKEnvironment();
 EndIf;

 // Create socket
 ClientSocket.SocketHandler = socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( ClientSocket.SocketHandler < 0 );
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   sendDie(%Str(strerror(ErrNo)));
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
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   sendDie(%Str(strerror(ErrorNumber)));
 EndIf;

 If pUseTLS;
   initGSKEnvironment(pUseTLS :ClientSocket.SocketHandler :GSK);
 EndIf;

 // Send protocoll and session-name
 Data = '*ZZv1>' + %TrimR(PSDS.JobName);
 sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
 RC = recieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 Select;
   When ( RC <= 0 );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Can''t connect to host.');
   When ( Data = '*UNKNOWNSESSION>' );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Unknown session recieved. Connection was canceled.');
   When ( Data = '*UNKNOWNPROTOCOLL>' );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Unknown protcoll recieved. Connection was canceled.');
   When ( Data = '*OK>' );
     sendStatus('Connection successfull.');
 EndSl;

 // Send username and password to host when selected
 If ( pAuthentication = '*USRPRF' );
   sendStatus('Start login at host ...');
   Exec SQL SET :Work = ENCRYPT_TDES(RTRIM(:pPassword.Data), :Key);
   If ( pUserProfile = '*CURRENT' );
     Data = PSDS.UserName + %TrimR(Work);
   Else;
     Data = pUserProfile + %TrimR(Work);
   EndIf;
   sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
   RC = recieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Login failed.');
   EndIf;

   Work = %SubSt(Data:%Scan('>' :Data) + 1 :(RC - %Scan('>' :Data)));
   Data = %SubSt(Data :1 :%Scan('>' :Data));

   Select;
     When ( Data = '*NOLOGINDATA>' );
       cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
       sendDie('No login data recieved.');
     When ( Data = '*NOPWD>' );
       cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
       sendDie('Wrong password > ' + %TrimR(Work));
     When ( Data = '*NOACCESS>' );
       cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
       sendDie('Access denied > ' + %TrimR(Work));
     When ( Data = '*OK>' );
       sendStatus('Login ok.');
   EndSl;
 ElseIf ( pAuthentication = '*NONE' );
   Data = '*AUTH_NONE>';
   sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
   Clear Data;
   RC = recieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Login failed.');
   ElseIf ( Data <> '*OK>' );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Authentication *NONE not allowed.');
   EndIf;
 EndIf;

 // Save objects and prepare
 sendStatus('Saving object(s), this may take a few moments ...');
 system('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                       %TrimR(pSaveFile.ObjectName) + ')');
 system('CRTSAVF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
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
 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Length > 0 );
   SaveCommand = 'SAV DEV(''/QSYS.LIB/' + %TrimR(pSaveFile.ObjectLibrary) + '.LIB/' +
                  %TrimR(pSaveFile.ObjectName) + '.FILE'') OBJ(''' + %TrimR(pStreamFile.Data) +
                  ''') SUBTREE(*ALL) TGTRLS(' + %TrimR(pTargetRelease) + ') ' +
                  'DTACPR(' +  %TrimR(pDataCompression) + ')';
 EndIf;

 RC = system(SaveCommand);
 If ( RC <> 0 );
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   system('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                         %TrimR(pSaveFile.ObjectName) + ')');
   sendDie('Error occured while saving data. See joblog.');
 EndIf;

 sendStatus('Prepare savefile to send, this may take a few moments ...');
 Monitor;
   manageSavefile('/QSYS.LIB/' + %TrimR(pSaveFile.ObjectLibrary) + '.LIB/' +
                  %TrimR(pSaveFile.ObjectName) + '.FILE'
                  :pWorkPath :SAVF_MODE_TO_FILE :SaveSuccess);
   On-Error;
     SaveSuccess = FALSE;
 EndMon;

 If Not SaveSuccess;
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   ifs_Unlink(%TrimR(pWorkPath));
   System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                         %TrimR(pSaveFile.ObjectName) + ')');
   sendDie('Error occured while preparing savefile. See joblog.');
 EndIf;

 system('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                       %TrimR(pSaveFile.ObjectName) + ')');

 // Get fileinformations
 If ( ifs_Stat(%TrimR(pWorkPath) :%Addr(StatDS)) < 0 );
   Clear StatDS;
 EndIf;

 // Send restoreinformations
 sendStatus('Send restore instructions');
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
   Data = 'RST DEV(''/QSYS.LIB/QTEMP.LIB/RCV.FILE'') OBJ(''' + %TrimR(pStreamFile.Data) + ''') ' +
          'SUBTREE(*ALL) CRTPRNDIR(*YES) ALWOBJDIF(*ALL)';
 EndIf;
 sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
 Clear Data;
 RC = recieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 If ( RC < 0 ) Or ( Data <> '*OK>' );
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   sendDie('Invalid restore instructions transfered.');
 EndIf;

 // Send object
 sendStatus('Sending data to host ...');
 SendingFile.FileHandler = ifs_Open(%TrimR(pWorkPath) :O_RDONLY + O_LARGEFILE);
 If ( SendingFile.FileHandler < 0 );
   ErrorNumber = ErrNo;
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   ifs_Unlink(%TrimR(pWorkPath));
   sendDie('Error occured while reading file > ' + %Str(strerror(ErrorNumber)));
 EndIf;

 DoW ( Loop );
   SendingFile.Length = ifs_Read(SendingFile.FileHandler :%Addr(SendingFile.Data)
                                 :%Size(SendingFile.Data));
   If ( SendingFile.Length < (%Size(SendingFile.Data) - 5) );
     ifs_Close(SendingFile.FileHandler);
     ifs_Unlink(%TrimR(pWorkPath));
     SendingFile.Data = %SubSt(SendingFile.Data :1 :SendingFile.Length) + '*EOF>';
     sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(SendingFile.Data)
              :SendingFile.Length + 5);
     Leave;
   EndIf;
   SendingFile.Bytes += SendingFile.Length;
   sendStatus('Sending data to host, ' + %Char(%DecH(SendingFile.Bytes/1024 :17 :2)) +
              ' KBytes of ' + %Char(%DecH(StatDS.Size/1024 :17 :2)) +
              ' KBytes transfered ...');
   sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(SendingFile.Data) :SendingFile.Length);
   Clear SendingFile.Data;
 EndDo;

 // Waiting for success-message
 Clear Data;
 sendStatus('Please wait, object(s) will be restored on the host system ...');
 RC = recieveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 Select;
   When ( %Scan('*ERROR_RESTORE>' :Data) > 0 );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Operation canceled: ' + %SubSt(Data :%Scan('>' :Data) + 1 :60));
   When ( %Scan('*OK>' :Data) > 0 );
     sendStatus('Operation was successfull.');
     System('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                           %TrimR(pSaveFile.ObjectName) + ')');
 EndSl;

 cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);

 Return;


END-PROC;

//**************************************************************************
DCL-PROC generateGSKEnvironment;
 DCL-PI *N LIKEDS(GSK_T) END-PI;

 DCL-S RC INT(10) INZ;

 DCL-DS GSK LIKEDS(GSK_T) INZ;
 //-------------------------------------------------------------------------

 RC = gsk_Environment_Open(GSK.Environment);
 If ( RC <> GSK_OK );
   sendDie(%Str(gsk_StrError(RC)));
 EndIf;

 gsk_Attribute_Set_Buffer(GSK.Environment :GSK_KEYRING_FILE :'*SYSTEM' :0);

 gsk_Attribute_Set_eNum(GSK.Environment :GSK_SESSION_TYPE :GSK_CLIENT_SESSION);

 gsk_Attribute_Set_eNum(GSK.Environment :GSK_SERVER_AUTH_TYPE :GSK_SERVER_AUTH_PASSTHRU);
 gsk_Attribute_Set_eNum(GSK.Environment :GSK_CLIENT_AUTH_TYPE :GSK_CLIENT_AUTH_PASSTHRU);

 gsk_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_SSLV2 :GSK_PROTOCOL_SSLV2_OFF);
 gsk_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_SSLV3 :GSK_PROTOCOL_SSLV3_OFF);
 gsk_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_TLSV1 :GSK_PROTOCOL_TLSV1_OFF);
 gsk_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_TLSV1_1 :GSK_FALSE);
 gsk_Attribute_Set_eNum(GSK.Environment :GSK_PROTOCOL_TLSV1_2 :GSK_TRUE);

 RC = gsk_Environment_Init(GSK.Environment);
 If ( RC <> GSK_OK );
   gsk_Environment_Close(GSK.Environment);
   sendDie(%Str(gsk_StrError(RC)));
 EndIf;

 Return GSK;

END-PROC;

//**************************************************************************
DCL-PROC initGSKEnvironment;
 DCL-PI *N;
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
   pGSK LIKEDS(GSK_T);
 END-PI;

 DCL-S RC INT(10) INZ;
 //-------------------------------------------------------------------------

   sendStatus('Try to make handshake with the host ...');
   RC = gsk_Secure_Soc_Open(pGSK.Environment :pGSK.SecureHandler);
   If ( RC <> GSK_OK );
     cleanUpSocket(pUseTLS :pSocketHandler :pGSK);
     sendDie(%Str(gsk_StrError(RC)));
   EndIf;

   RC = gsk_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_FD :pSocketHandler);
   If ( RC <> GSK_OK );
     cleanUpSocket(pUseTLS :pSocketHandler :pGSK);
     sendDie(%Str(gsk_StrError(RC)));
   EndIf;

   RC = gsk_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_HANDSHAKE_TIMEOUT :10);
   If ( RC <> GSK_OK );
     cleanUpSocket(pUseTLS :pSocketHandler :pGSK);
     sendDie(%Str(gsk_StrError(RC)));
   EndIf;

   RC = gsk_Secure_Soc_Init(pGSK.SecureHandler);
   If ( RC <> GSK_OK );
     cleanUpSocket(pUseTLS :pSocketHandler :pGSK);
     sendDie(%Str(gsk_StrError(RC)));
   EndIf;

END-PROC;


//**************************************************************************
DCL-PROC sendData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
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
   If ( RC = GSK_OK );
     RC = GSKLength;
   Else;
     Clear RC;
   EndIf;
 Else;
   RC = send(pSocketHandler :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC recieveData;
 DCL-PI *N INT(10);
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
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
   If ( RC = GSK_OK ) And ( GSKLength > 0 );
     Buffer = %SubSt(Buffer :1 :GSKLength);
   EndIf;
   RC = GSKLength;
 Else;
   RC = recv(pSocketHandler :%Addr(Buffer) :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC cleanUpSocket;
 DCL-PI *N;
   pUseTLS IND CONST;
   pSocketHandler INT(10) CONST;
   pGSK LIKEDS(GSK_T);
 END-PI;
 //-------------------------------------------------------------------------

 If pUseTLS;
   gsk_Secure_Soc_Close(pGSK.SecureHandler);
   gsk_Environment_Close(pGSK.Environment);
 EndIf;
 close_Socket(pSocketHandler);

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
DCL-PROC sendStatus;
 DCL-PI *N;
   pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 Message.Length = %Len(%TrimR(pMessage));
 If ( Message.Length >= 0 );
   sendProgramMessage('CPF9897'  :CPFMSG :pMessage :Message.Length
                      :'*STATUS' :'*EXT' :0 :Message.Key :Message.Error);
 EndIf;

END-PROC;

/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
