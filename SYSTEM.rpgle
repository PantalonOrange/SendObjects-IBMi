**FREE
/if not defined (#PROC_SYSTEM)
/define #PROC_SYSTEM
DCL-PR System INT(10) EXTPROC('system');
  *N POINTER VALUE OPTIONS(*STRING);
END-PR;
/endif
