# SendObjects-IBMi

Sending objects as savefile between different IBMi with server-client application over TCP/IP and tls-encrypted.  
Authentification over system userprofile and password (transfered as TDES encrypted string) or as anonymous authentication.  

All headers are included (QRPGLECPY)

### Command ZCLIENT
![ZCLIENT](https://github.com/PantalonOrange/SendObjects-IBMi/blob/master/zclient.gif)

### Command ZSERVER
![ZSERVER](https://github.com/PantalonOrange/SendObjects-IBMi/blob/master/zserver.png)

### Create objects:
To create the objects copy the sources to your sourcefiles (qrpglesrc, qcmdsrc, etc) and compile them via seu-option "14"

### Start the server on your IBMi like this:
1. Create your own jobdescription to start the server as a autostartjob:  
```CRTJOBD JOBD(YOURLIB/ZSERVER) TEXT('Start ZSERVER') USER(USER) RQSDTA('YOURLIB/ZSERVER AUTH(*USRPRF) TLS(*YES) APPID(*DFT)') INLLIBL(YOURLIB QTEMP)```
2. Add this jobdescription as a autostartjob to your subsystem:  
```ADDAJE SBSD(SUBSYSTEM) JOB(ZSERVER) JOBD(YOURLIB/ZSERVER)```

### Tip to use from pdm:
Create with F16 a user defined pdm-option.  
I have created 2, ZC (objects) and ZS (members)  
1. ZC: ```YOURLIB/ZCLIENT OBJ(&L/&N) OBJTYPE(&T) RMTSYS(SYSTEMNAME) AUTH(*USRPRF)```  
2. ZS: ```YOURLIB/ZCLIENT OBJ(&L/&F) OBJTYPE(*MBR) MBR(&N) RMTSYS(SYSTEMNAME) AUTH(*USRPRF)```

## Update 19.11.2019
Add membersupport to zclient and zserver
![ZCLIENT](https://github.com/PantalonOrange/SendObjects-IBMi/blob/master/zclient_mbr.gif)

## Update 29.05.2019
### ZSERVER
Add API ```QMHRTVM``` and SQL ```GET DIAGNOSTIC``` to return specific errorsmessages to client

## Update 17.01.2019
### ZCLIENT
Add streamfilesupport (beta)

## Update 08.01.2019
### ZCLIENT
Add parms to define your own places for workfiles.
### ZSERVER
Add parm to define your own AppID (certificate) installed on your IBMi (DCM).

## Update 27.12.2018
Bugfixes, hide regular parameters in commands and change/add authentication-modes (with userprofile or \*NONE)

## Update 26.9.2018
Now supports TLS/SSL to send and receive data using IBM's GSK.
