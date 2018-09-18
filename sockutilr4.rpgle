     /*-                                                                            +
      * Copyright (c) 1998,2001 Scott C. Klement                                    +
      * All rights reserved.                                                        +
      *                                                                             +
      * Redistribution and use in source and binary forms, with or without          +
      * modification, are permitted provided that the following conditions          +
      * are met:                                                                    +
      * 1. Redistributions of source code must retain the above copyright           +
      *    notice, this list of conditions and the following disclaimer.            +
      * 2. Redistributions in binary form must reproduce the above copyright        +
      *    notice, this list of conditions and the following disclaimer in the      +
      *    documentation and/or other materials provided with the distribution.     +
      *                                                                             +
      * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND      +
      * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE       +
      * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  +
      * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE     +
      * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL  +
      * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS     +
      * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)       +
      * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT  +
      * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY   +
      * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      +
      * SUCH DAMAGE.                                                                +
      *                                                                             +
      */                                                                            +
     H NOMAIN COPYRIGHT('Created Feb 19, 1999 by Scott Klement')

     D/INCLUDE SOCKET_H
     D/INCLUDE SOCKUTIL_H

     D Translate       PR                  ExtPgm('QDCXLATE')
     D    peLength                    5P 0 const
     D    peBuffer                32766A   options(*varsize)
     D    peTable                    10A   const

     D CalcBitPos      PR
     D    peDescr                    10I 0
     D    peByteNo                    5I 0
     D    peBitMask                   1A


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
     P RdLine          B                   Export
     D RdLine          PI            10I 0
     D   peSock                      10I 0 value
     D   peLine                        *   value
     D   peLength                    10I 0 value
     D   peXLate                      1A   const options(*nopass)
     D   peLF                         1A   const options(*nopass)
     D   peCR                         1A   const options(*nopass)

     D wwBuf           S          32766A   based(peLine)
     D wwLen           S             10I 0
     D RC              S             10I 0
     D CH              S              1A
     D wwXLate         S              1A
     D wwLF            S              1A
     D wwCR            S              1A

     c                   if        %parms > 3
     c                   eval      wwXLate = peXLate
     c                   else
     c                   eval      wwXLate = *OFF
     c                   endif

     c                   if        %parms > 4
     c                   eval      wwLF = peLF
     c                   else
     c                   eval      wwLF = x'0A'
     c                   endif

     c                   if        %parms > 5
     c                   eval      wwCR = peCR
     c                   else
     c                   eval      wwCR = x'0D'
     c                   endif

     c                   eval      %subst(wwBuf:1:peLength) = *blanks

     c                   dow       1 = 1

     c                   eval      rc = recv(peSock: %addr(ch): 1: 0)
     c                   if        rc<1
     c                   if        wwLen > 0
     c                   leave
     c                   else
     c                   return    -1
     c                   endif
     c                   endif

     c                   if        ch = wwLF
     c                   leave
     c                   endif

     c                   if        ch <> wwCR
     c                   eval      wwLen = wwLen + 1
     c                   eval      %subst(wwBuf:wwLen:1) = ch
     c                   endif

     c                   if        wwLen = peLength
     c                   leave
     c                   endif

     c                   enddo

     c                   if        wwXLate=*ON  and wwLen>0
     c                   callp     Translate(wwLen: wwBuf: 'QTCPEBC')
     c                   endif

     c                   return    wwLen
     P                 E


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
     P WrLine          B                   Export
     D WrLine          PI            10I 0
     D  peSock                       10I 0 value
     D  peLine                      256A   const
     D  peLength                     10I 0 value options(*nopass)
     D  peXLate                       1A   const options(*nopass)
     D  peEOL1                        1A   const options(*nopass)
     D  peEOL2                        1A   const options(*nopass)

     D wwLine          S            256A
     D wwLen           S             10I 0
     D wwXlate         S              1A
     D wwEOL           S              2A
     D wwEOLlen        S             10I 0
     D rc              S             10I 0

     C*******************************************
     C* Allow this procedure to figure out the
     C*  length automatically if not passed,
     C*  or if -1 is passed.
     C*******************************************
     c                   if        %parms > 2 and peLength <> -1
     c                   eval      wwLen = peLength
     c                   else
     c                   eval      wwLen = %len(%trim(peLine))
     c                   endif

     C*******************************************
     C* Default 'translate' to *ON.  Usually
     C*  you want to type the data to send
     C*  in EBCDIC, so this makes more sense:
     C*******************************************
     c                   if        %parms > 3
     c                   eval      wwXLate = peXLate
     c                   else
     c                   eval      wwXLate = *On
     c                   endif

     C*******************************************
     C* End-Of-Line chars:
     C*   1) If caller passed only one, set
     C*         that one with length = 1
     C*   2) If caller passed two, then use
     C*         them both with length = 2
     C*   3) If caller didn't pass either,
     C*         use both CR & LF with length = 2
     C*******************************************
     c                   eval      wwEOL = *blanks
     c                   eval      wwEOLlen = 0

     c                   if        %parms > 4
     c                   eval      %subst(wwEOL:1:1) = peEOL1
     c                   eval      wwEOLLen = 1
     c                   endif

     c                   if        %parms > 5
     c                   eval      %subst(wwEOL:2:1) = peEOL2
     c                   eval      wwEOLLen = 2
     c                   endif

     c                   if        wwEOLLen = 0
     c                   eval      wwEOL = x'0D0A'
     c                   eval      wwEOLLen = 2
     c                   endif

     C*******************************************
     C* Do translation if required:
     C*******************************************
     c                   eval      wwLine = peLine
     c                   if        wwXLate = *On and wwLen > 0
     c                   callp     Translate(wwLen: wwLine: 'QTCPASC')
     c                   endif

     C*******************************************
     C* Send the data, followed by the end-of-line:
     C* and return the length of data sent:
     C*******************************************
     c                   if        wwLen > 0
     c                   eval      rc = send(peSock: %addr(wwLine): wwLen:0)
     c                   if        rc < wwLen
     c                   return    rc
     c                   endif
     c                   endif

     c                   eval      rc = send(peSock:%addr(wwEOL):wwEOLLen:0)
     c                   if        rc < 0
     c                   return    rc
     c                   endif

     c                   return    (rc + wwLen)
     P                 E


     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P* Set a File Descriptor in a set ON...  for use w/Select()
     P*
     P*      peFD = descriptor to set on
     P*      peFDSet = descriptor set
     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FD_SET          B                   EXPORT
     D FD_SET          PI
     D   peFD                        10I 0
     D   peFDSet                     28A
     D wkByteNo        S              5I 0
     D wkMask          S              1A
     D wkByte          S              1A
     C                   callp     CalcBitPos(peFD:wkByteNo:wkMask)
     c                   eval      wkByte = %subst(peFDSet:wkByteNo:1)
     c                   biton     wkMask        wkByte
     c                   eval      %subst(peFDSet:wkByteNo:1) = wkByte
     P                 E


     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P* Set a File Descriptor in a set OFF...  for use w/Select()
     P*
     P*      peFD = descriptor to set off
     P*      peFDSet = descriptor set
     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FD_CLR          B                   EXPORT
     D FD_CLR          PI
     D   peFD                        10I 0
     D   peFDSet                     28A
     D wkByteNo        S              5I 0
     D wkMask          S              1A
     D wkByte          S              1A
     C                   callp     CalcBitPos(peFD:wkByteNo:wkMask)
     c                   eval      wkByte = %subst(peFDSet:wkByteNo:1)
     c                   bitoff    wkMask        wkByte
     c                   eval      %subst(peFDSet:wkByteNo:1) = wkByte
     P                 E


     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P* Determine if a file desriptor is on or off...
     P*
     P*      peFD = descriptor to set off
     P*      peFDSet = descriptor set
     P*
     P*   Returns *ON if its on, or *OFF if its off.
     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FD_ISSET        B                   EXPORT
     D FD_ISSET        PI             1N
     D   peFD                        10I 0
     D   peFDSet                     28A
     D wkByteNo        S              5I 0
     D wkMask          S              1A
     D wkByte          S              1A
     C                   callp     CalcBitPos(peFD:wkByteNo:wkMask)
     c                   eval      wkByte = %subst(peFDSet:wkByteNo:1)
     c                   testb     wkMask        wkByte                   88
     c                   return    *IN88
     P                 E


     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P* Clear All descriptors in a set.  (also initializes at start)
     P*
     P*      peFDSet = descriptor set
     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P FD_ZERO         B                   EXPORT
     D FD_ZERO         PI
     D   peFDSet                     28A
     C                   eval      peFDSet = *ALLx'00'
     P                 E


     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     p*  This is used by the FD_SET/FD_CLR/FD_ISSET procedures to
     p*  determine which byte in the 28-char string to check,
     p*  and a bitmask to check the individual bit...
     p*
     p*  peDescr = descriptor to check in the set.
     p*  peByteNo = byte number (returned)
     p*  peBitMask = bitmask to set on/off or test
     P*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     P CalcBitPos      B
     D CalcBitPos      PI
     D    peDescr                    10I 0
     D    peByteNo                    5I 0
     D    peBitMask                   1A
     D dsMakeMask      DS
     D   dsZeroByte            1      1A
     D   dsMask                2      2A
     D   dsBitMult             1      2U 0 INZ(0)
     C     peDescr       div       32            wkGroup           5 0
     C                   mvr                     wkByteNo          2 0
     C                   div       8             wkByteNo          2 0
     C                   mvr                     wkBitNo           2 0
     C                   eval      wkByteNo = 4 - wkByteNo
     c                   eval      peByteNo = (wkGroup * 4) + wkByteNo
     c                   eval      dsBitMult = 2 ** wkBitNo
     c                   eval      dsZeroByte = x'00'
     c                   eval      peBitMask = dsMask
     P                 E
