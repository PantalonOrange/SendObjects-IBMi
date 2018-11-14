**FREE
/if not defined (#API_QMHSNDPM)
/define #API_QMHSNDPM
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
