             CMD        PROMPT('Server - Reciever') TEXT('Recieve +
                          objects') HLPID(*CMD) +
                          HLPPNLGRP(ZSERVER)

             PARM       KWD(PORT) TYPE(*DEC) LEN(5) DFT(19335) +
                          RANGE(1 65535) PROMPT('Port')

             PARM       KWD(AUTH) TYPE(*CHAR) LEN(7) RSTD(*YES) +
                          DFT(*USRPRF) VALUES(*USRPRF *NONE) +
                          PMTCTL(*PMTRQS) PROMPT('Authentication')

             PARM       KWD(TLS) TYPE(*LGL) RSTD(*YES) DFT(*YES) +
                          SPCVAL((*YES '1') (*NO '0')) +
                          PMTCTL(*PMTRQS) PROMPT('Start with TLS')

             PARM       KWD(APPID) TYPE(*CHAR) LEN(32) DFT(*DFT) +
                          SPCVAL((*DFT *DFT)) CHOICE('Your +
                          application id from DCM') PMTCTL(*PMTRQS) +
                          PROMPT('ApplicationID')
