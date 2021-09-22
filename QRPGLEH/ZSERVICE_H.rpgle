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

/IF DEFINED (ZSERVICE_H)
/EOF
/ENDIF

/DEFINE ZSERVICE_H

DCL-PR sendData INT(10) OVERLOAD(sendDataClient :sendDataServer);
DCL-PR sendDataClient INT(10);
 UseTLS IND CONST;
 SocketHandler INT(10) CONST;
 GSK LIKEDS(GSK_T) CONST;
 Data POINTER VALUE;
 Length INT(10) CONST;
END-PR;
DCL-PR sendDataServer INT(10);
 UseTLS IND CONST;
 Socket LIKEDS(SocketServer_T) CONST;
 GSK LIKEDS(GSK_T) CONST;
 Data POINTER VALUE;
 Length INT(10) CONST;
END-PR;


DCL-PR receiveData INT(10) OVERLOAD(receiveDataClient :receiveDataServer);
DCL-PR receiveDataClient INT(10);
 UseTLS IND CONST;
 SocketHandler INT(10) CONST;
 GSK LIKEDS(GSK_T) CONST;
 Data POINTER VALUE;
 Length INT(10) VALUE;
END-PR;
DCL-PR receiveDataServer INT(10);
 UseTLS IND CONST;
 Socket LIKEDS(SocketServer_T) CONST;
 GSK LIKEDS(GSK_T) CONST;
 Data POINTER VALUE;
 Length INT(10) VALUE;
END-PR;

DCL-PR makeListenerServer;
 Port UNS(5) CONST;
 UseTLS IND;
 AppID CHAR(32) CONST;
 UseClientCert IND CONST;
 ConnectFrom POINTER;
 Socket LIKEDS(SocketServer_T);
 GSK LIKEDS(GSK_T);
 Lingering LIKEDS(Lingering_T);
END-PR;

DCL-PR acceptConnectionServer;
 UseTLS IND CONST;
 ConnectFrom POINTER CONST;
 Socket LIKEDS(SocketServer_T);
 GSK LIKEDS(GSK_T);
 Lingering LIKEDS(Lingering_T);
END-PR;

DCL-PR generateGSKEnvironmentServer IND;
 GSK LIKEDS(GSK_T);
 AppID CHAR(32) CONST;
 UseClientCert IND CONST;
END-PR;

DCL-PR generateGSKEnvironmentClient LIKEDS(GSK_T);
 AppID CHAR(32) CONST;
END-PR;

DCL-PR initGSKEnvironmentClient;
 UseTLS IND CONST;
 SocketHandler INT(10) CONST;
 GSK LIKEDS(GSK_T);
END-PR;

DCL-PR cleanUpSocket OVERLOAD(cleanUpSocketClient :cleanUpSocketServer);
DCL-PR cleanUpSocketClient;
 UseTLS IND CONST;
 SocketHandler INT(10) CONST;
 GSK LIKEDS(GSK_T);
END-PR;
DCL-PR cleanUpSocketServer;
 UseTLS IND CONST;
 SocketHandler INT(10) CONST;
 GSKHandler POINTER;
END-PR;

DCL-PR cleanTempServer;
 LinkName CHAR(128) CONST;
END-PR;

DCL-PR doShutDown IND;
 UseTLS IND CONST;
 Socket LIKEDS(SocketServer_T) CONST;
 GSK LIKEDS(GSK_T);
END-PR;

DCL-PR sendDie;
 Message CHAR(256) CONST;
END-PR;

DCL-PR sendJobLog;
 Message CHAR(256) CONST;
END-PR;

DCL-PR sendStatus;
 Message CHAR(256) CONST;
END-PR;
