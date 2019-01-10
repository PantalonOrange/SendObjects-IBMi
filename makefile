BIN_LIB=SNDOBJS
DBGVIEW=*SOURCE

#----------

all: ZCLIENTRG.pgm ZSERVERRG.pgm ZCLIENT.cmd ZSERVER.cmd
	@echo "Built all"

ZCLIENTRG.pgm: ZCLIENTCL.clle ZCLIENTRG.sqlrpgle
	@echo "Client build"

ZSERVERRG.pgm: ZSERVERCL.clle ZSERVERRG.sqlrpgle
	@echo "Server build"

#----------

%.clle:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QCLSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('QCLSRC/$*.clle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCLSRC.file/$*.mbr') MBROPT(*ADD)"
	system "CRTBNDCL PGM($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QCLSRC) DBGVIEW($(DBGVIEW))"
	
%.cmd:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QCMDSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('QCMDSRC/$*.cmd') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QCMDSRC.file/$*.mbr') MBROPT(*ADD)"
	system "CRTCMD CMD($(BIN_LIB)/$*) PGM($(BIN_LIB)/$*RG) SRCFILE($(BIN_LIB)/QCMDSRC)"

%.pnlgrp:
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QPNLSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('QPNLSRC/$*.pnlgrp') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QPNLSRC.file/$*.mbr') MBROPT(*ADD)"
	system "CRTPNLGRP PNLGRP($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QPNLSRC)"

%.sqlrpgle:
	system "CRTSQLRPGI OBJ($(BIN_LIB)/$*) SRCSTMF('QRPGLESRC/$*.sqlrpgle') COMMIT(*NONE) OPTION(*EVENTF *XREF) DBGVIEW($(DBGVIEW))"
	
clean:
	system "CLRLIB $(BIN_LIB)"