**FREE
//- Copyright (c) 2019 Christian Brunner
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

/IF DEFINED (Z_H)
/EOF
/ENDIF

/DEFINE Z_H

DCL-DS QualifiedObjectName_T TEMPLATE QUALIFIED;
  ObjectName CHAR(10);
  ObjectLibrary CHAR(10);
END-DS;
DCL-DS CommandVaryingParm_T TEMPLATE QUALIFIED;
  Length UNS(5);
  Data CHAR(510);
END-DS;
/IF DEFINED (IS_ZCLIENT)
DCL-DS Socket_T TEMPLATE QUALIFIED;
  ConnectTo POINTER;
  SocketHandler INT(10);
  Address UNS(10);
  AddressLength INT(10);
END-DS;
/ELSEIF DEFINED (IS_ZSERVER)
DCL-DS Socket_T TEMPLATE QUALIFIED;
  Listener INT(10);
  Talk INT(10);
  ClientIP CHAR(17);
END-DS;
/ENDIF
DCL-DS GSK_T TEMPLATE QUALIFIED;
  Environment POINTER;
  SecureHandler POINTER;
END-DS;
DCL-DS MessageHandling_T TEMPLATE QUALIFIED;
  Length INT(10);
  Key CHAR(4);
  Error CHAR(128);
END-DS;
DCL-DS Lingering_T TEMPLATE QUALIFIED;
  LingerHandler POINTER;
  Length INT(10);
END-DS;
DCL-DS Error_T TEMPLATE QUALIFIED;
  NbrBytesPrv INT(10) INZ(%SIZE(Error_T));
  NbrBytesAvl INT(10);
  MessageID CHAR(7);
  Reserved1 CHAR(1);
  MessageData CHAR(512);
END-DS;
