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

/IF DEFINED (API_QMHRTVM)
/EOF
/ENDIF

/DEFINE API_QMHRTVM

/IF NOT DEFINED (CPFMSG)
DCL-C CPFMSG 'QCPFMSG   *LIBL';
/DEFINE CPFMSG
/ENDIF

DCL-PR retrieveMessageData EXTPGM('QMHRTVM');
  MessageDataOut LIKEDS(RTVM0100_T);
  MessageDataLengthOut INT(10) CONST;
  APIFormat CHAR(8) CONST;
  MessageID CHAR(7) CONST;
  MessageFile CHAR(20) CONST;
  MessageDataIn CHAR(1024) CONST OPTIONS(*VARSIZE);
  MessageDataLengthIn INT(10) CONST;
  FlGrpLData CHAR(10) CONST;
  FlGFmtChar CHAR(10) CONST;
  ErrorCode CHAR(128);
END-PR;

/INCLUDE QRPGLECPY,RTVM0100
