# SendObjects-IBMi

Sending objects as savefile between different IBMi's with basic server-client application over TCP/IP.
Authentification over system userprofile and password (transfered as TDES encrypted string).


Based on the socket api from scott klement
 -> https://www.scottklement.com/rpg/socktut/socktut.savf

To create objects:
 -> Copy source to your sourcefiles (qrpglesrc, qcmdsrc, etc) and compile them via seu-option "14"


## Update 26.9.2018
Now supports TLS/SSL to send and recieve data using IBM's GSK.
