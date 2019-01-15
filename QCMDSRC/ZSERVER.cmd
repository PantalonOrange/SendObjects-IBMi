             CMD        PROMPT('Server - Reciever') TEXT('Recieve +
                          objects') HLPID(*CMD) +
                          HLPPNLGRP(ZSERVER) +
                          PRDLIB(changelibraryname)

             PARM       KWD(PORT) TYPE(*DEC) LEN(5) DFT(19335) +
                          RANGE(1 65535) PROMPT('Port')

             PARM       KWD(TLS) TYPE(*LGL) RSTD(*YES) DFT(*YES) +
                          SPCVAL((*YES '1') (*NO '0')) +
                          PROMPT('Start with TLS')

             PARM       KWD(APPID) TYPE(*CHAR) LEN(32) DFT(*DFT) +
                          SPCVAL((*DFT *DFT)) CHOICE('Your +
                          application id from DCM') PMTCTL(IFTLS) +
                          PROMPT('ApplicationID')

             PARM       KWD(AUTH) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*USRPRF) VALUES(*USRPRF *NONE) +
                          PMTCTL(*PMTRQS) PROMPT('Authentication')

 IFTLS:      PMTCTL     CTL(TLS) COND((*EQ '1'))