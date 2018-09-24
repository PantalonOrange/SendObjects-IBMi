             CMD        PROMPT('Send objects') TEXT('Send objects')

             PARM       KWD(OBJECT) TYPE(*NAME) LEN(10) MIN(1) +
                          CHOICE('Objectname') +
                          PROMPT('Obect')

             PARM       KWD(LIB) TYPE(*SNAME) LEN(10) DFT(*LIBL) +
                          SPCVAL((*LIBL '*LIBL')) CHOICE('Library') +
                          PROMPT('Library')

             PARM       KWD(OBJTYPE) TYPE(*CHAR) LEN(10) DFT(*ALL) +
                          CHOICE('Objecttype, *ALL') +
                          PROMPT('Objecttype')

             PARM       KWD(HOST) TYPE(*CHAR) LEN(16) +
                          CHOICE('IP-Adress or Hostname') +
                          PROMPT('Server-Adress')

             PARM       KWD(USER) TYPE(*NAME) LEN(10) +
                          CHOICE('Username on IBMi') +
                          PROMPT('IBMi-User')

             PARM       KWD(PASS) TYPE(*CHAR) LEN(32) CASE(*MIXED) +
	                  DSPINPUT(*NO) CHOICE('Password') +
                          PROMPT('IBMi-Password')

             PARM       KWD(TGTRLS) TYPE(*CHAR) LEN(8) RSTD(*YES) +
                          DFT(*CURRENT) VALUES(*CURRENT *PRV) +
                          PROMPT('Target-Release')

             PARM       KWD(RSTLIB) TYPE(*NAME) LEN(10) DFT(*SAVLIB) +
                          SPCVAL((*SAVLIB *SAVLIB)) +
			  PROMPT('Restore in following library')

             PARM       KWD(PORT) TYPE(*DEC) LEN(5) DFT(19335) +
                          RANGE(1 65535) PROMPT('Port')
