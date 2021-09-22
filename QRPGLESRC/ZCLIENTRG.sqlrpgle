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

//  Created by BRC on 30.08.2018 - 29.05.2019

// Socketclient to send objects over tls to another IBMi


// Changes:
//  17.10.2019  Disabled elder ssl and tls protocolls
//               Add varying streamfilepathparm over command
//  23.10.2019  Cosmetic changes
//  30.10.2019  Editwords and other small changes
//  19.11.2019  Don't update the object history by save and add member-support
//  16.12.2019  Bugfix checks because length var is not 0 when data is ''
//  23.02.2021  Add option for client-certification
//  22.09.2021  Change SOCKET_H to free
//  22.09.2021  Move the most procedures to a new serviceprogram


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main) BNDDIR('ZSERVICE');


DCL-PR Main EXTPGM('ZCLIENTRG');
  QualifiedObjectName CHAR(20) CONST;
  ObjectType CHAR(10) CONST;
  MemberName CHAR(10) CONST;
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
  AppID CHAR(32) CONST;
END-PR;


/INCLUDE QRPGLEH,Z_H


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
   pQualifiedObjectName CHAR(20) CONST;
   pObjectType CHAR(10) CONST;
   pMemberName CHAR(10) CONST;
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
   pAppID CHAR(32) CONST;
 END-PI;
 //-------------------------------------------------------------------------

 *INLR = TRUE;

 If ( %Parms() = 16 ) And ( pQualifiedObjectName <> '' );
   manageSendingStuff(pQualifiedObjectName
                      :pObjectType
                      :pMemberName
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
                      :pWorkPath
                      :pAppID);
 EndIf;

 Return;

END-PROC;


//**************************************************************************
DCL-PROC manageSendingStuff;
 DCL-PI *N;
   pQualifiedObjectName LIKEDS(QualifiedObjectName_T) CONST;
   pObjectType CHAR(10) CONST;
   pMemberName CHAR(10) CONST;
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
   pAppID CHAR(32) CONST;
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

 DCL-DS ClientSocket LIKEDS(SocketClient_T) INZ;
 DCL-DS GSK LIKEDS(GSK_T) INZ;
 DCL-DS StatDS LIKEDS(StatDS_T) INZ;
 //-------------------------------------------------------------------------

 // Quickcheck for some necessary parameters
 If ( pAuthentication = '*USRPRF' ) And ( pUserProfile = '' );
   sendDie('No userprofile selected.');
 ElseIf ( pAuthentication = '*USRPRF' ) And ( pPassword.Data = '' );
   sendDie('No password selected.');
 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Data = '' );
   sendDie('No streamfile selected.');
 ElseIf ( pObjectType = '*MBR' ) And ( pMemberName = '' );
   sendDie('No member selected.');
 ElseIf ( pRemoteSystem.Data = '' );
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
   When ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*MBR' );
     RC = system('CHKOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectLibrary) + '/' +
                 %TrimR(pQualifiedObjectName.ObjectName) + ') OBJTYPE(*FILE) MBR(' +
                 %TrimR(pMemberName) + ')');
   When ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Data <> '' )
    And ( %Scan('*' :pStreamfile.Data) > 0 );
      Clear RC;
   When ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Data <> '' )
    And ( %Scan('*' :pStreamfile.Data) = 0 );
     RC = ifsAccess(%TrimR(pStreamFile.Data) :F_OK);
   Other;
     RC = system('CHKOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectLibrary) + '/' +
                  %TrimR(pQualifiedObjectName.ObjectName) + ') OBJTYPE(' +
                  %TrimR(pObjectType) + ')');
 EndSl;

 If ( RC <> 0 );
   sendDie('Object(s) not found or accessable.');
 EndIf;

 // Search adress via hostname
 ClientSocket.Address = inet_Address(%TrimR(pRemoteSystem.Data));
 If ( ClientSocket.Address = INADDR_NONE );
   pHostEntry = getHostByName(%TrimR(pRemoteSystem.Data));
   If ( pHostEntry = *NULL );
     sendDie('Unable to find selected host.');
   EndIf;
   ClientSocket.Address = HAddress;
 EndIf;

 If pUseTLS;
   GSK = generateGSKEnvironmentClient(pAppID);
 EndIf;

 // Create socket
 ClientSocket.SocketHandler = socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( ClientSocket.SocketHandler < 0 );
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   sendDie(%Str(strError(ErrNo)));
 EndIf;

 ClientSocket.AddressLength = %Size(SocketAddress);
 ClientSocket.ConnectTo = %Alloc(ClientSocket.AddressLength);

 pSocketAddress = ClientSocket.ConnectTo;
 SocketAddressIn.Family = AF_INET;
 SocketAddressIn.Address = ClientSocket.Address;
 SocketAddressIn.Port = pPort;
 SocketAddressIn.Zero = *ALLx'00';

 // Connect to host
 If ( connect(ClientSocket.SocketHandler :ClientSocket.ConnectTo
              :ClientSocket.AddressLength) < 0 );
   ErrorNumber = ErrNo;
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   sendDie(%Str(strerror(ErrorNumber)));
 EndIf;

 If pUseTLS;
   initGSKEnvironmentClient(pUseTLS :ClientSocket.SocketHandler :GSK);
 EndIf;

 // Send protocoll and session-name
 Data = '*ZZv1>' + %TrimR(PSDS.JobName);
 sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
 RC = receiveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 Select;
   When ( RC <= 0 );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Can''t connect to host.');
   When ( Data = '*UNKNOWNSESSION>' );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Unknown session received. Connection was canceled.');
   When ( Data = '*UNKNOWNPROTOCOLL>' );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Unknown protcoll received. Connection was canceled.');
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
   RC = receiveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
   If ( RC <= 0 );
     cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
     sendDie('Login failed.');
   EndIf;

   Work = %SubSt(Data:%Scan('>' :Data) + 1 :(RC - %Scan('>' :Data)));
   Data = %SubSt(Data :1 :%Scan('>' :Data));

   Select;
     When ( Data = '*NOLOGINDATA>' );
       cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
       sendDie('No login data received.');
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
   RC = receiveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
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
                 ') UPDHST(*NO) SAVACT(*LIB) DTACPR(' + %TrimR(pDataCompression) + ')';

 ElseIf ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType <> '*LIB' )
    And ( pObjectType <> '*MBR' );
   SaveCommand = 'SAVOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') LIB(' +
                 %TrimR(pQualifiedObjectName.ObjectLibrary) + ') '+
                 'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) ' +
                 'SAVF(' + %TrimR(pSaveFile.ObjectLibrary) + '/' + %TrimR(pSaveFile.ObjectName) +
                 ') TGTRLS(' + %TrimR(pTargetRelease) + ') UPDHST(*NO) SAVACT(*LIB) ' +
                 'DTACPR(' + %TrimR(pDataCompression) + ')';

 ElseIf ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*MBR' );
   RC = system('CPYF FROMFILE(' + %TrimR(pQualifiedObjectName.ObjectLibrary) + '/' +
               %TrimR(pQualifiedObjectName.ObjectName) + ') TOFILE(QTEMP/' +
               %TrimR(pQualifiedObjectName.ObjectName) + ') FROMMBR(' +
               %TrimR(pMemberName) + ') TOMBR(*FROMMBR) MBROPT(*REPLACE) CRTFILE(*YES)');
   If ( RC <> 0 );
     sendDie('Error occured while copying member.');
   Else;
     SaveCommand = 'SAVOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') LIB(QTEMP) ' +
                   'OBJTYPE(*FILE) DEV(*SAVF) ' +
                   'SAVF(' + %TrimR(pSaveFile.ObjectLibrary) + '/' + %TrimR(pSaveFile.ObjectName) +
                   ') TGTRLS(' + %TrimR(pTargetRelease) + ') UPDHST(*NO) SAVACT(*LIB) ' +
                   'DTACPR(' + %TrimR(pDataCompression) + ')';
   EndIf;

 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' ) And ( pStreamFile.Data <> '' );
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
   If ( pObjectType = '*MBR' );
     system('DLTF FILE(QTEMP/' + %TrimR(pQualifiedObjectName.ObjectName) + ')');
   EndIf;
   sendDie('Error occured while saving data. See joblog.');
 EndIf;

 If ( pObjectType = '*MBR' );
   system('DLTF FILE(QTEMP/' + %TrimR(pQualifiedObjectName.ObjectName) + ')');
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
   ifsUnlink(%TrimR(pWorkPath));
   system('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                         %TrimR(pSaveFile.ObjectName) + ')');
   sendDie('Error occured while preparing savefile. See joblog.');
 EndIf;

 system('DLTF FILE(' + %TrimR(pSaveFile.ObjectLibrary) + '/' +
                       %TrimR(pSaveFile.ObjectName) + ')');

 // Get fileinformations
 If ( ifsStat64(%TrimR(pWorkPath) :%Addr(StatDS)) < 0 );
   Clear StatDS;
 EndIf;

 // Send restoreinformations
 sendStatus('Send restore instructions');
 If ( pQualifiedObjectName.ObjectName <> '*STMF') And ( pObjectType = '*LIB' );
   Data = 'RSTLIB SAVLIB(' + %TrimR(pQualifiedObjectName.ObjectName) +
          ') DEV(*SAVF) SAVF(QTEMP/RCV) MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB('
          + %TrimR(pRestoreLibrary) + ')';

 ElseIf ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType <> '*LIB' )
    And ( pObjectType <> '*MBR' );
   Data = 'RSTOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') SAVLIB(' +
          %TrimR(pQualifiedObjectName.ObjectLibrary) + ') ' +
          'OBJTYPE(' + %TrimR(pObjectType) +  ') DEV(*SAVF) SAVF(QTEMP/RCV) ' +
          'MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB(' + %TrimR(pRestoreLibrary) + ')';

 ElseIf ( pQualifiedObjectName.ObjectName <> '*STMF' ) And ( pObjectType = '*MBR' );
   Data = 'MBR' + pQualifiedObjectName.ObjectLibrary + pQualifiedObjectName.ObjectName +
          'RSTOBJ OBJ(' + %TrimR(pQualifiedObjectName.ObjectName) + ') SAVLIB(QTEMP) ' +
          'OBJTYPE(*FILE) DEV(*SAVF) SAVF(QTEMP/RCV) ' +
          'MBROPT(*ALL) ALWOBJDIF(*ALL) RSTLIB(' + %TrimR(pRestoreLibrary) + ')';

 ElseIf ( pQualifiedObjectName.ObjectName = '*STMF' );
   Data = 'RST DEV(''/QSYS.LIB/QTEMP.LIB/RCV.FILE'') OBJ(''' +
          %TrimR(pStreamFile.Data) + ''') SUBTREE(*ALL) CRTPRNDIR(*YES) ALWOBJDIF(*ALL)';
 EndIf;

 sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Len(%TrimR(Data)));
 Clear Data;
 RC = receiveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
 If ( RC < 0 ) Or ( Data <> '*OK>' );
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   sendDie('Invalid restore instructions transfered.');
 EndIf;

 // Send object
 sendStatus('Sending data to host ...');
 SendingFile.FileHandler = ifsOpen(%TrimR(pWorkPath) :O_RDONLY + O_LARGEFILE);
 If ( SendingFile.FileHandler < 0 );
   ErrorNumber = ErrNo;
   cleanUpSocket(pUseTLS :ClientSocket.SocketHandler :GSK);
   ifsUnlink(%TrimR(pWorkPath));
   sendDie('Error occured while reading file > ' + %Str(strerror(ErrorNumber)));
 EndIf;

 DoW ( Loop );
   SendingFile.Length = ifsRead(SendingFile.FileHandler :%Addr(SendingFile.Data)
                                 :%Size(SendingFile.Data));
   If ( SendingFile.Length < (%Size(SendingFile.Data) - 5) );
     ifsClose(SendingFile.FileHandler);
     ifsUnlink(%TrimR(pWorkPath));
     SendingFile.Data = %SubSt(SendingFile.Data :1 :SendingFile.Length) + '*EOF>';
     sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(SendingFile.Data)
              :SendingFile.Length + 5);
     Leave;
   EndIf;
   SendingFile.Bytes += SendingFile.Length;
   sendStatus('Sending data to host, ' +
              %Trim(%EditW(%DecH(SendingFile.Bytes/1024 :17 :2) :EDTW172)) + ' KB of ' +
              %Trim(%EditW(%DecH(StatDS.Size/1024 :17 :2) :EDTW172)) + ' KB transfered (' +
              %Trim(%EditW(%DecH(SendingFile.Bytes/(StatDS.Size/100) :5 :2) :EDTW052)) + '%)');
   sendData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(SendingFile.Data) :SendingFile.Length);
   Clear SendingFile.Data;
 EndDo;

 // Waiting for success-message
 Clear Data;
 sendStatus('Please wait, object(s) will be restored on the host system ...');
 RC = receiveData(pUseTLS :ClientSocket.SocketHandler :GSK :%Addr(Data) :%Size(Data));
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

/DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
