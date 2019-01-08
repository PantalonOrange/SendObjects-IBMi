**FREE
/if not defined (#QSYGETPH)
/define #QSYGETPH

DCL-PR EC#QSYGETPH EXTPGM('QSYGETPH');
  User     CHAR(10) CONST;
  Password CHAR(32) CONST;
  pHandler CHAR(12);
  Error    CHAR(32766) OPTIONS(*VARSIZE :*NOPASS);
  Length   INT(10) CONST OPTIONS(*NOPASS);
  pCCSID   INT(10) CONST OPTIONS(*NOPASS);
END-PR;
DCL-PR EC#QWTSETP EXTPGM('QWTSETP');
  pHandler CHAR(12);
  Error CHAR(32766) OPTIONS(*VARSIZE);
END-PR;

DCL-S User CHAR(10) INZ;
DCL-S Password CHAR(32) INZ;
DCL-S UserHandler CHAR(12) INZ;
DCL-S UserLength INT(10) INZ(10);
DCL-S UserCCSID INT(10) INZ(37);

/endif