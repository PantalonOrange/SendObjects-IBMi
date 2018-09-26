# # SendObjects-IBMi

Sending objects as savefile between different IBMi's with basic server-client application over TCP/IP.
Authentification over system userprofile and password (transfered as TDES encrypted string).


Based on the socket api from scott klement
 -> https://www.scottklement.com/rpg/socktut/socktut.savf

## Update 26.9.2018
Now you can send and recieve data using IBM's GSK (TLS/SSL).
For this there is a new parameter on both commands (TLS).
