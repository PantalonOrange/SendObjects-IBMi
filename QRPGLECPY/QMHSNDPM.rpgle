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

/if not defined (API_QMHSNDPM)

/define API_QMHSNDPM

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

/endif
