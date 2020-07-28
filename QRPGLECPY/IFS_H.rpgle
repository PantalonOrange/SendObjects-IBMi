**FREE
//- Copyright (c) 2018 - 2020 Christian Brunner
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

// Flags for use in open()
DCL-C O_RDONLY 1; // Reading Only
DCL-C O_WRONLY 2; // Writing Only
DCL-C O_RDWR 4; // Reading & Writing
DCL-C O_CREATE 8; // Create File if not exist
DCL-C O_EXCL 16; // Exclusively create
DCL-C O_CCSID 32; // Assign a CCSID
DCL-C O_TRUNC 64; //Truncate File to 0 bytes
DCL-C O_APPEND 256; //Append to File
DCL-C O_SYNC 1024; // Synchronous write
DCL-C O_DSYNC 2048; // Sync write, data only
DCL-C O_RSYNC 4096; // Sync read
DCL-C O_NOCTTY 32768; // No controlling terminal
DCL-C O_SHARE_RDONLY 65536; // Share with readers only
DCL-C O_SHARE_WRONLY 131072; // Share with writers only
DCL-C O_SHARE_RDWR 262144; // Share with read & write
DCL-C O_SHARE_NONE 524288; // Share with nobody
DCL-C O_CODEPAGE 8388608; // Assign a code page
DCL-C O_TEXTDATA 16777216; // Open in text-mode
DCL-C O_TEXT_CREATE 33554432; // Allow text translation on newly created file
DCL-C O_INHERITMODE 134217728; // Inherit mode from dir
DCL-C O_LARGEFILE 536870912; // Large file access

// Mode Flags for open(), creat(), chmod() ...
//   owner authority
DCL-C S_IRUSR 256;
DCL-C S_IWUSR 128;
DCL-C S_IXUSR 64;
DCL-C S_IRWXU 448;
//   group authority
DCL-C S_IRGRP 32;
DCL-C S_IWGRP 16;
DCL-C S_IXGRP 8;
DCL-C S_IRWXG 56;
//   other people
DCL-C S_IROTH 4;
DCL-C S_IWOTH 2;
DCL-C S_IXOTH 1;
DCL-C S_IRWXO 7;

// "whence" constants for use with lseek()
DCL-C SEEK_SET 0;
DCL-C SEEK_CUR 1;
DCL-C SEEK_END 2;

// Access mode flags for access()
DCL-C F_OK 0; // File Exists
DCL-C R_OK 4; // Read Access
DCL-C W_OK 2; // Write Access
DCL-C X_OK 1; // Execute or Search


// Template structures for readdir()
DCL-S DirectorsEntryPointer_T POINTER INZ(*NULL);
DCL-S DirectoryPointer_T POINTER INZ(*NULL);
DCL-DS DirectoryEntryDS_T TEMPLATE QUALIFIED;
 Reserved1 CHAR(16);
 FileNoGenID UNS(10);
 FileNo UNS(10);
 RecordLength UNS(10);
 Reserved3 INT(10);
 Reserved4 CHAR(8);
 NLSInfo CHAR(12);
 NLSCCSID INT(10) OVERLAY(NLSInfo :1);
 NLSCountry CHAR(2) OVERLAY(NLSInfo :5);
 NLSLanguage CHAR(3) OVERLAY(NLSInfo :7);
 NLSReserved CHAR(3) OVERLAY(NLSInfo :10);
 NameLength UNS(10);
 Name CHAR(640);
END-DS;

// Template structure for stat()
DCL-DS StatDS_T TEMPLATE QUALIFIED;
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

// Close a file (int close(int fildes))
DCL-PR ifsClose INT(10) EXTPROC('close');
 Handle INT(10) VALUE;
END-PR;

// Close a directory (int closedir(*dirp))
DCL-PR ifsCloseDir INT(10) EXTPROC('closedir');
 DirectoryHandle POINTER VALUE;
END-PR;

// Create or rewrite file (int creat(const char *path, mode_t mode))
DCL-PR ifsCreate INT(10) EXTPROC('creat');
 Path POINTER VALUE OPTIONS(*STRING);
 Mode UNS(10) VALUE;
END-PR;

// Make directory (int mkdir(const char *path, mode_t mode))
DCL-PR ifsMkDir INT(10) EXTPROC('mkdir');
 Path POINTER VALUE OPTIONS(*STRING);
 Mode UNS(10) VALUE;
END-PR;

// Open a file (int open(const char *path, int oflag,...))
DCL-PR ifsOpen INT(10) EXTPROC('open');
 FileName POINTER VALUE OPTIONS(*STRING);
 OpenFlags INT(10) VALUE;
 Mode UNS(10) VALUE OPTIONS(*NOPASS);
 CCSID UNS(10) VALUE OPTIONS(*NOPASS);
 TextCreateID UNS(10) VALUE OPTIONS(*NOPASS);
END-PR;

// Open a directory (DIR *opendir(const char *dirname))
DCL-PR ifsOpenDir POINTER EXTPROC('opendir');
 DirectoryName POINTER VALUE OPTIONS(*STRING);
END-PR;

// Read from flatfile (ssize_t read(int handle, void *buffer, size_t bytes))
DCL-PR ifsRead INT(10) EXTPROC('read');
 Handle INT(10) VALUE;
 Buffer POINTER VALUE;
 Bytes UNS(10) VALUE;
END-PR;

// Read directory entry (struct dirent *readdir(DIR *dirp))
DCL-PR ifsReadDir POINTER EXTPROC('readdir');
 DirectoryEntry POINTER VALUE;
END-PR;

// Remove link to file (int unlink(const char *path))
DCL-PR ifsUnlink INT(10) EXTPROC('unlink');
 Path POINTER VALUE OPTIONS(*STRING);
END-PR;

// Write to a file (ssize_t write(int fildes, const void *buf, size_t bytes))
DCL-PR ifsWrite INT(10) EXTPROC('write');
 Handle INT(10) VALUE;
 Buffer POINTER VALUE;
 Bytes UNS(10) VALUE;
END-PR;

// Access to a file (ssize_t access(int fildes, const char *path, int mode))
DCL-PR ifsAccess INT(10) EXTPROC('access');
 Path POINTER VALUE OPTIONS(*STRING);
 Mode INT(10) VALUE;
END-PR;

// Access to a file (ssize_t access(int fildes, const char *path, int mode))
DCL-PR ifsStat64 INT(10) EXTPROC('stat64');
  Path POINTER VALUE OPTIONS(*STRING);
  Buffer POINTER VALUE;
END-PR;
