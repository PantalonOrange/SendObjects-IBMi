# SendObjects-IBMi

Sending objects as savefile between different IBMi's with basic server-client application over TCP/IP.  
Authentification over system userprofile and password (transfered as TDES encrypted string).  
  

These programs using the headers from the socket api owned by scott klement  
-> https://www.scottklement.com/rpg/socktut/socktut.savf

### Create objects:
To create the objects copy the sources to your sourcefiles (qrpglesrc, qcmdsrc, etc) and compile them via seu-option "14"

### Start the server on your IBMi like this:
1. Create your own jobdescription to start the server as a autostartjob:  
```CRTJOBD JOBD(YOURLIB/ZSERVER) TEXT('Start ZSERVER') USER(USER) RQSDTA('YOURLIB/ZSERVER AUTH(*USRPRF) TLS(*YES) APPID(*DFT)') INLLIBL(YOURLIB QTEMP)```
2. Add this jobdescription as a autostartjob to your subsystem:  
```ADDAJE SBSD(SUBSYSTEM) JOB(ZSERVER) JOBD(YOURLIB/ZSERVER)```

### Command ZCLIENT
![ZCLIENT](https://github.com/PantalonOrange/SendObjects-IBMi/blob/master/zclient.gif)

### Command ZSERVER
![ZSERVER](https://github.com/PantalonOrange/SendObjects-IBMi/blob/master/zserver.png)

## Update 08.01.2019
### ZCLIENT
Add parms to define your own places for workfiles.
### ZSERVER
Add parm to define your own AppID (certificate) from your DCM.

## Update 27.12.2018
Bugfixes, hide regular parameters in commands and new authentication-mode (with userprofile or *NONE)

## Update 26.9.2018
Now supports TLS/SSL to send and recieve data using IBM's GSK.
