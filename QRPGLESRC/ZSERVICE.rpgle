**FREE
//- Copyright (c) 2021 Christian Brunner
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

//  Created by BRC on 22.09.2021

// Services for send objects between IBM i

// To create this service program compile this to an *module and
//  execute the following command:
//  -> CRTSRVPGM SRVPGM(YOURLIB/ZSERVICE) MODULE(YOURLIB/ZSERVICE)
//      EXPORT(*ALL) SRCFILE(YOURLIB/QSRVSRC) TEXT('Send objects services') USRPRF(*OWNER)


// Changes:
// 2021-09-22 BRC: Initial version
// 2021-09-23 BRC: Added TLS support for client and server
// 2023-10-01 BRC: Added support for TLS 1.3 and removed TLS 1.0 and 1.1
// 2025-04-10 BRC: Try some copilot suggestions


/DEFINE CTL_SRVPGM
/INCLUDE QRPGLECPY,H_SPECS


/INCLUDE QRPGLEH,ZSERVICE_H
/INCLUDE QRPGLEH,Z_H


//**************************************************************************
DCL-PROC sendDataServer EXPORT;
 DCL-PI *N INT(10);
  pUseTLS IND CONST;
  pSocket LIKEDS(SocketServer_T) CONST;
  pGSK LIKEDS(GSK_T) CONST;
  pData POINTER VALUE;
  pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = gsk_Secure_Soc_Write(pGSK.SecureHandler :pData :pLength :GSKLength);
   If ( RC <> GSK_OK );
     sendJobLog('gsk_Secure_Soc_Write(): ' + %Str(gsk_StrError(ErrNo)));
   EndIf;
   RC = GSKLength;
 Else;
   RC = send(pSocket.Talk :pData :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
DCL-PROC receiveDataServer EXPORT;
 DCL-PI *N INT(10);
  pUseTLS IND CONST;
  pSocket LIKEDS(SocketServer_T) CONST;
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
DCL-PROC sendDataClient EXPORT;
 DCL-PI *N INT(10);
  pUseTLS IND CONST;
  pSocketHandler INT(10) CONST;
  pGSK LIKEDS(GSK_T) CONST;
  pData POINTER VALUE;
  pLength INT(10) CONST;
 END-PI;

 DCL-S RC INT(10) INZ;
 DCL-S GSKLength INT(10) INZ;
 //-------------------------------------------------------------------------

 If pUseTLS;
   RC = gsk_Secure_Soc_Write(pGSK.SecureHandler :pData :pLength :GSKLength);
   If ( RC = GSK_OK );
     RC = GSKLength;
   Else;
     Clear RC;
   EndIf;
 Else;
   RC = send(pSocketHandler :pData :pLength :0);
 EndIf;

 Return RC;

END-PROC;

//**************************************************************************
// Procedure: receiveDataClient
// Purpose:   Receives data from a client socket, with optional TLS support.
// Parameters:
//   - pUseTLS: Indicates whether TLS is enabled (IND CONST).
//   - pSocketHandler: The socket handler for the client connection (INT(10) CONST).
//   - pGSK: The GSK environment and secure handler (LIKEDS(GSK_T) CONST).
//   - pData: Pointer to the buffer where the received data will be stored (POINTER VALUE).
//   - pLength: Length of the data to be received (INT(10) VALUE).
// Returns:   The number of bytes received, or 0 if an error occurs.
//**************************************************************************
DCL-PROC receiveDataClient EXPORT;
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
DCL-PROC makeListenerServer EXPORT;
 DCL-PI *N;
  pPort UNS(5) CONST;
  pUseTLS IND;
  pAppID CHAR(32) CONST;
  pUseClientCert IND CONST;
  pConnectFrom POINTER;
  pSocket LIKEDS(SocketServer_T);
  pGSK LIKEDS(GSK_T);
  pLingering LIKEDS(Lingering_T);
 END-PI;

 DCL-S BindTo POINTER;
 DCL-S Length INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 DCL-S SockOptON IND INZ(TRUE);
 //-------------------------------------------------------------------------

 If pUseTLS;
   pUseTLS = generateGSKEnvironmentServer(pGSK :pAppID :pUseClientCert);
   If Not pUseTLS;
     sendJobLog('+> Server was not able to generate GSK environment. Error: ' + %Str(gsk_StrError(ErrNo)) +
                '. Please verify the GSK environment setup and ensure the application ID is correct.');
   EndIf;
 EndIf;

 Length = %Size(SocketAddressIn);
 BindTo = %Alloc(Length);
 pConnectFrom = %Alloc(Length);

 pSocket.Listener = socket(AF_INET :SOCK_STREAM :IPPROTO_IP);
 If ( pSocket.Listener < 0 );
   cleanUpSocket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   sendDie('socket(): ' + %Str(strError(ErrNo)));
 EndIf;

 setSockOpt(pSocket.Listener :SOL_SOCKET :SO_REUSEADDR :%Addr(SockOptON) :%Size(SockOptON));

 pLingering.Length = %Size(Linger);
 pLingering.LingerHandler = %Alloc(pLingering.Length);
 pLinger = pLingering.LingerHandler;
 Linger.OnOff = 1;
 Linger.Linger = 1;
 setSockOpt(pSocket.Listener :SOL_SOCKET :SO_LINGER :pLingering.LingerHandler :pLingering.Length);

 pSocketAddress = BindTo;
 SocketAddressIn.Family = AF_INET;
 SocketAddressIn.Address = INADDR_ANY;
 SocketAddressIn.Port = pPort;
 SocketAddressIn.Zero = *ALLx'00';

 If ( bind(pSocket.Listener :BindTo :Length) < 0 );
   ErrorNumber = ErrNo;
   cleanUpSocket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   sendDie('bind(): ' + %Str(strError(ErrorNumber)));
 EndIf;

 If ( listen(pSocket.Listener :5) < 0 );
   ErrorNumber = ErrNo;
   cleanUpSocket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
   sendDie('listen(): ' + %Str(strError(ErrorNumber)));
 EndIf;

 sendJobLog('+> Server is now running on port ' + %Char(pPort) + ' and ready for connections');

END-PROC;

//**************************************************************************
DCL-PROC acceptConnectionServer EXPORT;
 DCL-PI *N;
  pUseTLS IND CONST;
  pConnectFrom POINTER CONST;
  pSocket LIKEDS(SocketServer_T);
  pGSK LIKEDS(GSK_T);
  pLingering LIKEDS(Lingering_T);
 END-PI;

 DCL-S Length INT(10) INZ;
 DCL-S ErrorNumber INT(10) INZ;
 //-------------------------------------------------------------------------

 DoU ( Length = %Size(SocketAddressIn) );

   If (pConnectFrom = *NULL);
     sendJobLog('Error: pConnectFrom is null. Cannot accept connection.');
     cleanUpSocket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

   pSocket.Talk  = accept(pSocket.Listener :pConnectFrom :Length);
   If ( pSocket.Talk < 0 );
     sendJobLog('accept(): ' + %Str(strError(ErrNo)));
     cleanUpSocket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

   Linger.OnOff = 1;
   Linger.Linger = 10;
   setSockOpt(pSocket.Talk :SOL_SOCKET :SO_LINGER :pLingering.LingerHandler :pLingering.Length);

   If ( Length <> %Size(SocketAddressIn));
     cleanUpSocket(pUseTLS :pSocket.Listener :pGSK.SecureHandler);
     Return;
   EndIf;

 EndDo;

 If pUseTLS;
   If ( gsk_Secure_Soc_Open(pGSK.Environment: pGSK.SecureHandler) <> GSK_OK );
     ErrorNumber = ErrNo;
     cleanUpSocket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     sendJobLog('gsk_Secure_Soc_Open(): ' + %Str(gsk_StrError(ErrorNumber)));
   EndIf;
   If ( gsk_Attribute_Set_Numeric_Value(pGSK.SecureHandler :GSK_FD :pSocket.Talk) <> GSK_OK );
     ErrorNumber = ErrNo;
     cleanUpSocket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     sendJobLog('gsk_Attribute_Set_Numeric_Value(): ' + %Str(gsk_StrError(ErrorNumber)));
   EndIf;
   If ( gsk_Secure_Soc_Init(pGSK.SecureHandler) <> GSK_OK );
     ErrorNumber = ErrNo;
     cleanUpSocket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
     sendJobLog('gsk_Secure_Soc_Init(): ' + %Str(gsk_StrError(ErrorNumber)));
   EndIf;
 EndIf;

 pSocketAddress = pConnectFrom;
 pSocket.ClientIP = %Str(inet_NToa(SocketAddressIn.Address));

END-PROC;

//**************************************************************************
DCL-PROC generateGSKEnvironmentServer EXPORT;
 DCL-PI *N IND;
  pGSK LIKEDS(GSK_T);
  pAppID CHAR(32) CONST;
  pUseClientCert IND CONST;
 END-PI;

 DCL-C APP_ID 'SND_IBMI_APP';
 DCL-C DEFAULT_APP_ID '*DFT';

 DCL-S Success IND INZ;
 DCL-S AppID VARCHAR(32) INZ;
 //-------------------------------------------------------------------------

 If ( pAppID = DEFAULT_APP_ID );
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
   If pUseClientCert;
     Success = ( gsk_Attribute_Set_Enum(pGSK.Environment :GSK_CLIENT_AUTH_TYPE
                                        :GSK_IBMI_CLIENT_AUTH_REQUIRED) = GSK_OK );
   Else;
     Success = ( gsk_Attribute_Set_Enum(pGSK.Environment :GSK_CLIENT_AUTH_TYPE
                                        :GSK_CLIENT_AUTH_PASSTHRU) = GSK_OK );
   EndIf;
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
DCL-PROC generateGSKEnvironmentClient EXPORT;
 DCL-PI *N LIKEDS(GSK_T);
  pAppID CHAR(32) CONST;
 END-PI;

 DCL-C APP_ID 'SND_IBMI_APP_CLIENT';

 DCL-S RC INT(10) INZ;
 DCL-S AppID VARCHAR(32) INZ;

 DCL-DS GSK LIKEDS(GSK_T) INZ;
 //-------------------------------------------------------------------------

 If ( pAppID = '*DFT' );
   AppID = APP_ID;
 Else;
   AppID = pAppID;
 EndIf;

 RC = gsk_Environment_Open(GSK.Environment);
 If ( RC <> GSK_OK );
   sendDie(%Str(gsk_StrError(RC)));
 EndIf;

 gsk_Attribute_Set_Buffer(GSK.Environment :GSK_KEYRING_FILE :'*SYSTEM' :0);

 If ( AppID <> '*NONE' );
   RC = gsk_Attribute_Set_Buffer(GSK.Environment :GSK_OS400_APPLICATION_ID :AppID :0);
   If ( RC <> GSK_OK );
     If ( GSK.Environment <> *NULL );
       gsk_Environment_Close(GSK.Environment);
     EndIf;
     sendDie(%Str(gsk_StrError(RC)));
   EndIf;
 EndIf;

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
DCL-PROC initGSKEnvironmentClient EXPORT;
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
DCL-PROC cleanUpSocketClient EXPORT;
 DCL-PI *N;
  pUseTLS IND CONST;
  pSocketHandler INT(10) CONST;
  pGSK LIKEDS(GSK_T);
 END-PI;
 //-------------------------------------------------------------------------

 If pUseTLS;
   If pGSK.SecureHandler <> *NULL;
     gsk_Secure_Soc_Close(pGSK.SecureHandler);
   EndIf;
   If pGSK.Environment <> *NULL;
     gsk_Environment_Close(pGSK.Environment);
   Else;
     sendJobLog('Warning: Attempted to close a null GSK environment.');
   EndIf;
 EndIf;
 closeSocket(pSocketHandler);

END-PROC;

//**************************************************************************
DCL-PROC cleanUpSocketServer EXPORT;
 DCL-PI *N;
  pUseTLS IND CONST;
  pSocketHandler INT(10) CONST;
  pGSKHandler POINTER;
 END-PI;
 //-------------------------------------------------------------------------

 If pUseTLS;
   GSK_Secure_Soc_Close(pGSKHandler);
 EndIf;

 closeSocket(pSocketHandler);

END-PROC;

//**************************************************************************
DCL-PROC cleanTempServer EXPORT;
 DCL-PI *N;
  pLinkName CHAR(128) CONST;
 END-PI;

 ifsUnlink(pLinkName);
 system('CLRLIB LIB(QTEMP)');

END-PROC;

//**************************************************************************
DCL-PROC doShutDown EXPORT;
 DCL-PI *N IND;
   pUseTLS IND CONST;
   pSocket LIKEDS(SocketServer_T) CONST;
   pGSK LIKEDS(GSK_T);
 END-PI;

 DCL-S ShutDown IND INZ(FALSE);
 //-------------------------------------------------------------------------

 If ( %ShtDn() );
   ShutDown = TRUE;
   cleanUpSocket(pUseTLS :pSocket.Talk :pGSK.SecureHandler);
 EndIf;

 Return ShutDown;

END-PROC;

//**************************************************************************
DCL-PROC sendDie EXPORT;
 DCL-PI *N;
  pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 If ( %Len(%TrimR(pMessage)) > 0 );
   Message.Length = %Len(%TrimR(pMessage));
   sendProgramMessage('CPF9897' :CPFMSG :pMessage :Message.Length
                      :'*ESCAPE' :'*PGMBDY' :1 :Message.Key :Message.Error);
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC sendJobLog EXPORT;
 DCL-PI *N;
  pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 If %Len(%TrimR(pMessage)) > 0;
   // Send a message to the job log with the specified message.
   Message.Length = %Len(%TrimR(pMessage));
   sendProgramMessage('CPF9897' :CPFMSG :pMessage :Message.Length
                      :'*DIAG'  :'*PGMBDY' :1 :Message.Key :Message.Error);
 EndIf;

END-PROC;

//**************************************************************************
DCL-PROC sendStatus EXPORT;
 DCL-PI *N;
  pMessage CHAR(256) CONST;
 END-PI;

 DCL-DS Message LIKEDS(MessageHandling_T) INZ;
 //-------------------------------------------------------------------------

 If %Len(%TrimR(pMessage)) > 0;
   Message.Length = %Len(%TrimR(pMessage));
   sendProgramMessage('CPF9897'  :CPFMSG :pMessage :Message.Length
                      :'*STATUS' :'*EXT' :0 :Message.Key :Message.Error);
 EndIf;

END-PROC;

// Define a macro to load the ERRNO procedure for error handling.
// This ensures that the ERRNO_H definitions are included for managing system errors.
 /DEFINE LOAD_ERRNO_PROCEDURE
/INCLUDE QRPGLECPY,ERRNO_H
