             CMD        PROMPT('Server - Reciever') TEXT('Recieve +
                          objects')
             PARM       KWD(PORT) TYPE(*DEC) LEN(5) DFT(19335) +
                          RANGE(1 65535) PROMPT('Port')
             PARM       KWD(TLS) TYPE(*CHAR) LEN(4) RSTD(*YES) +
                          DFT(*NO) VALUES(*YES *NO) PROMPT('Use +
                          SSL/TLS')
