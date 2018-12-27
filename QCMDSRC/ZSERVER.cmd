             CMD        PROMPT('Server - Reciever') TEXT('Recieve +
                          objects') PRDLIB($$YOURLIB)

             PARM       KWD(PORT) TYPE(*DEC) LEN(5) DFT(19335) +
                          RANGE(1 65535) PROMPT('Port')

             PARM       KWD(TLS) TYPE(*LGL) RSTD(*YES) DFT(*NO) +
                          SPCVAL((*YES '1') (*NO '0')) +
                          PROMPT('Start with TLS')
