     /*-
      * Copyright (c) 2001 Scott C. Klement
      * All rights reserved.
      *
      * Redistribution and use in source and binary forms, with or without
      * modification, are permitted provided that the following conditions
      * are met:
      * 1. Redistributions of source code must retain the above copyright
      *    notice, this list of conditions and the following disclaimer.
      * 2. Redistributions in binary form must reproduce the above copyright
      *    notice, this list of conditions and the following disclaimer in the
      *    documentation and/or other materials provided with the distribution.
      *
      * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
      * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPO
      * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
      * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTI
      * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
      * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
      * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRI
      * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WA
      * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      * SUCH DAMAGE.
      *
      */

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * RdLine(): This reads one "line" of text data from a socket.
      *
      *   peSock = socket to read from
      *   peLine = a pointer to a variable to put the line of text into
      *   peLength = max possible length of data to stuff into peLine
      *   peXLate = (default: *OFF) Set to *ON to translate ASCII -> EBCDIC
      *   peLF (default: x'0A') = line feed character.
      *   peCR (default: x'0D') = carriage return character.
      *
      *  returns length of data read, or -1 upon error
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D RdLine          PR            10I 0
     D   peSock                      10I 0 value
     D   peLine                        *   value
     D   peLength                    10I 0 value
     D   peXLate                      1A   const options(*nopass)
     D   peLF                         1A   const options(*nopass)
     D   peCR                         1A   const options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  WrLine() -- Write a line of text to a socket:
      *
      *      peSock = socket descriptor to write to
      *      peLine = line of text to write to
      *    peLength = length of line to write (before adding CRLF)
      *            you can pass -1 to have this routine calculate
      *            the length for you (which is the default!)
      *     peXlate = Pass '*ON' to have the routine translate
      *            this data to ASCII (which is the default) or *OFF
      *            to send it as-is.
      *      peEOL1 = First character to send at end-of-line
      *            (default is x'0D')
      *      peEOL2 = Second character to send at end-of-line
      *            (default is x'0A' if neither EOL1 or EOL2 is
      *            passed, or to not send a second char is EOL1
      *            is passed by itself)
      *
      * Returns length of data sent (including end of line chars)
      *    returns a short count if it couldnt send everything
      *    (if you're using a non-blocking socket) or -1 upon error
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D WrLine          PR            10I 0
     D  peSock                       10I 0 value
     D  peLine                      256A   const
     D  peLength                     10I 0 value options(*nopass)
     D  peXLate                       1A   const options(*nopass)
     D  peEOL1                        1A   const options(*nopass)
     D  peEOL2                        1A   const options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Set a File Descriptor in a set ON...  for use w/Select()
      *
      *      peFD = descriptor to set on
      *      peFDSet = descriptor set
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D FD_SET          PR
     D   peFD                        10I 0
     D   peFDSet                     28A


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Set a File Descriptor in a set OFF...  for use w/Select()
      *
      *      peFD = descriptor to set off
      *      peFDSet = descriptor set
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D FD_CLR          PR
     D   peFD                        10I 0
     D   peFDSet                     28A


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Determine if a file desriptor is on or off...
      *
      *      peFD = descriptor to test
      *      peFDSet = descriptor set
      *
      *   Returns *ON if its on, or *OFF if its off.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D FD_ISSET        PR             1N
     D   peFD                        10I 0
     D   peFDSet                     28A


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * Clear All descriptors in a set.  (also initializes at start)
      *
      *      peFDSet = descriptor set
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D FD_ZERO         PR
     D   peFDSet                     28A

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  data type of a file descriptor set:
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D fdset           S             28A
