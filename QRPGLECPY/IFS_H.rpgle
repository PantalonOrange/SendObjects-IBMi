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

/IF DEFINED (IFS_H)
/EOF
/ENDIF

/DEFINE IFS_H

DCL-PR ifs_Open INT(10) EXTPROC('open');
  FileName POINTER VALUE OPTIONS(*STRING);
  OpenFlags INT(10) VALUE;
  Mode UNS(10) VALUE OPTIONS(*NOPASS);
  Codepage UNS(10) VALUE OPTIONS(*NOPASS);
END-PR;
DCL-PR ifs_Read INT(10) EXTPROC('read');
  Handle INT(10) VALUE;
  Buffer POINTER VALUE;
  Bytes UNS(10) VALUE;
END-PR;
DCL-PR ifs_Write INT(10) EXTPROC('write');
  Handle INT(10) VALUE;
  Buffer POINTER VALUE;
  Bytes  UNS(10) VALUE;
END-PR;
DCL-PR ifs_Close INT(10) EXTPROC('close');
  Handle INT(10) VALUE;
END-PR;
DCL-PR ifs_Unlink INT(10) EXTPROC('unlink');
  Path POINTER VALUE OPTIONS(*STRING);
END-PR;
DCL-PR ifs_Stat INT(10) EXTPROC('stat');
  Path POINTER VALUE OPTIONS(*STRING);
  Buffer POINTER VALUE;
END-PR;
DCL-PR ifs_Stat64 INT(10) EXTPROC('stat64');
  Path POINTER VALUE OPTIONS(*STRING);
  Buffer POINTER VALUE;
END-PR;
DCL-PR ifs_Access INT(10) EXTPROC('access');
 Path POINTER VALUE OPTIONS(*STRING);
 Mode INT(10) VALUE;
END-PR;

DCL-DS StatDS_Template TEMPLATE QUALIFIED;
  Mode UNS(10);
  FileID UNS(10);
  NLinks UNS(5);
  Pad CHAR(2);
  UserID UNS(10);
  GroupID UNS(10);
  Size INT(10);
  AccessTime INT(10);
  ModificationTime INT(10);
  ChangeTime INT(10);
  Dev UNS(10);
  BlockSize UNS(10);
  AllocatedSize UNS(10);
  ObjectType CHAR(10);
  ObjectCCSID UNS(5);
  Reserved CHAR(64);
END-DS;

DCL-C O_RDONLY 1;
DCL-C O_WRONLY 2;
DCL-C O_CREAT 8;
DCL-C O_TRUNC 64;
DCL-C O_TEXTDATA 16777216;
DCL-C O_CODEPAGE 8388608;
DCL-C O_LARGEFILE 536870912;

DCL-C S_IRWXU 448;
DCL-C S_IRWXG 56;
DCL-C S_IRWXO 7;

DCL-C F_OK 0;
