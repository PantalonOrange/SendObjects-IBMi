**FREE
//- Copyright (c) 2021 Christian Brunner
//-
//- Permission is hereby granted, free of charge, to any person obtaining a copy
//- of this software and associated documentation files (the "Software"), to deal
//- in the Software without restriction, including without limitation the rights
//- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//- copies of the Software, and to permit persons to whom the Software is
//- furnished to do so, subject to the following conditions:

//- The above copyright notice and this permission notice shall be included in all
//- copies or substantial portions of the Software.

//- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//- SOFTWARE.

/IF DEFINED(SOCKET_H)
/EOF
/ENDIF

/DEFINE SOCKET_H

DCL-C IPVERSION 4;

DCL-C AF_INET 2;
DCL-C SOCK_STREAM 1;
DCL-C SOCK_DGRAM 2;
DCL-C SOCK_RAW 3;

DCL-C IPPROTO_IP 0;
DCL-C IPPROTO_ICMP 1;
DCL-C IPPROTO_TCP 6;
DCL-C IPPROTO_UDP 17;
DCL-C IPPROTO_RAW 255;
DCL-C SOL_SOCKET -1;

DCL-C IP_OPTIONS 5;
DCL-C IP_TOS 10;
DCL-C IP_TTL 15;
DCL-C IP_RECVLCLIFADDR 99;

DCL-C TCP_MAXSEG 5;
DCL-C TCP_NODELAY 10;

DCL-C SO_BROADCAST 5;
DCL-C SO_DEBUG 10;
DCL-C SO_DONTROUTE 15;
DCL-C SO_ERROR 20;
DCL-C SO_KEEPALIVE 25;
DCL-C SO_LINGER 30;
DCL-C SO_OOBINLINE 35;
DCL-C SO_RCVBUF 40;
DCL-C SO_RCVLOWAT 45;
DCL-C SO_RCVTIMEO 50;
DCL-C SO_REUSEADDR 55;
DCL-C SO_SNDBUF 60;
DCL-C SO_SNDLOWAT 65;
DCL-C SO_SNDTIMEO 70;
DCL-C SO_TYPE 75;
DCL-C SO_USELOOPBACK 80;

DCL-C IPTOS_NORMAL x'00';
DCL-C IPTOS_MIN x'02';
DCL-C IPTOS_RELIABLE x'04';
DCL-C IPTOS_THRUPUT x'08';
DCL-C IPTOS_LOWDELAY x'10';

DCL-C IPTOS_NET x'E0';
DCL-C IPTOS_INET x'C0';
DCL-C IPTOS_CRIT x'A0';
DCL-C IPTOS_FOVR x'80';
DCL-C IPTOS_FLAS x'60';
DCL-C IPTOS_IMME x'40';
DCL-C IPTOS_PTY x'20';
DCL-C IPTOS_ROUT x'10';

DCL-C MSG_DONTROUTE 1;
DCL-C MSG_OOB 4;
DCL-C MSG_PEEK 8;

DCL-C INADDR_ANY 0;
DCL-C INADDR_LOOPBACK 2130706433;
DCL-C INADDR_BROADCAST 4294967295;
DCL-C INADDR_NONE 4294967295;

DCL-C ICMP_ECHOR x'00';
DCL-C ICMP_UNREA x'03';
DCL-C ICMP_SRCQ x'04';
DCL-C ICMP_REDIR x'05';
DCL-C ICMP_ECHO x'08';
DCL-C ICMP_IREQR x'10';
DCL-C ICMP_MASK x'11';
DCL-C ICMP_MASKR x'12';
DCL-C ICMP_TIMX x'0B';
DCL-C ICMP_PARM x'0C';
DCL-C ICMP_TSTP x'0D';
DCL-C ICMP_TSTPR x'0E';
DCL-C ICMP_IREQ x'0F';

DCL-C UNREACH_NET x'00';
DCL-C UNREACH_HOST x'01';
DCL-C UNREACH_PORT x'03';
DCL-C UNREACH_FRAG x'04';
DCL-C UNREACH_SRCF x'05';

DCL-C TIMX_INTRA x'00';
DCL-C TIMX_REASS x'01';

DCL-C REDIRECT_NET x'00';
DCL-C REDIRECT_HOST x'01';
DCL-C REDIRECT_TOSN x'02';
DCL-C REDIRECT_TOSH x'03';

DCL-C F_DUPFD 0;
DCL-C F_GETFL 6;
DCL-C F_SETFL 7;
DCL-C F_GETOWN 8;
DCL-C F_SETOWN 9;
DCL-C O_NONBLOCK 128;
DCL-C O_NDELAY 128;
DCL-C FNDELAY 128;
DCL-C FASYNC 512;

DCL-S pSocketAddress POINTER;
DCL-DS SocketAddress QUALIFIED BASED(pSocketAddress);
 Family UNS(5);
 Data CHAR(14);
END-DS;

DCL-DS SocketAddressIn QUALIFIED BASED(pSocketAddress);
 Family INT(5);
 Port UNS(5);
 Address UNS(10);
 Zero CHAR(8);
END-DS;

DCL-S pHostEntry POINTER;
DCL-DS HostEntry QUALIFIED BASED(pHostEntry);
 Name POINTER;
 Aliases POINTER;
 AddressType INT(5);
 Length INT(5);
 AddressList POINTER;
END-DS;
DCL-S pHAddress POINTER BASED(HostEntry.AddressList);
DCL-S HAddress UNS(10) BASED(pHAddress);

DCL-S pServerEntry POINTER;
DCL-DS ServerEntry QUALIFIED BASED(pServerEntry);
 Same POINTER;
 Aliases POINTER;
 Port INT(10);
 Prototype POINTER;
END-DS;

DCL-S pIP POINTER;
DCL-DS IP QUALIFIED BASED(pIP);
 V_hl CHAR(1);
 IPTosS CHAR(1);
 IPLength INT(5);
 IP_ID UNS(5);
 IPOffset INT(5);
 IP_TTLS CHAR(1);
 IP_P CHAR(1);
 ip_Sum UNS(5);
 IP_Src UNS(10);
 IP_Dst UNS(10);
END-DS;

DCL-S pUDPheader POINTER;
DCL-DS UDPHeader QUALIFIED BASED(pudphdr);
 Sport UNS(5);
 Port UNS(5);
 Length INT(5);
 Sum UNS(5);
END-DS;

DCL-S pIcmp POINTER;
DCL-DS Icmp QUALIFIED BASED(pIcmp);
 icmp_type CHAR(1);
 icmp_code CHAR(1);
 icmp_cksum UNS(5);
 icmp_hun CHAR(4);
 ih_gwaddr UNS(10) OVERLAY(icmp_hun :1);
 ih_pptr CHAR(1) OVERLAY(icmp_hun :1);
 ih_idseq CHAR(4) OVERLAY(icmp_hun :1);
 icd_id UNS(5) OVERLAY(ih_idseq :1);
 icd_seq UNS(5) OVERLAY(ih_idseq :3);
 ih_void INT(5) OVERLAY(icmp_hun :1);
 icmp_dun CHAR(20);
 id_ts CHAR(12) OVERLAY(icmp_dun :1);
 its_otime UNS(10) OVERLAY(id_ts :1);
 its_rtime UNS(10) OVERLAY(id_ts :5);
 its_ttime UNS(10) OVERLAY(id_ts :9);
 id_ip CHAR(20) OVERLAY(icmp_dun :1);
 idi_ip CHAR(20) OVERLAY(id_ip :1);
 id_mask UNS(10) OVERLAY(icmp_dun :1);
 id_data CHAR(1) OVERLAY(icmp_dun :1);
END-DS;

DCL-S pTimeVal POINTER;
DCL-DS TimeVal QUALIFIED BASED(pTimeVal);
 Sec INT(10);
 USec INT(10);
END-DS;

DCL-S pLinger POINTER;
DCL-DS Linger QUALIFIED BASED(pLinger);
 OnOff INT(10);
 Linger INT(10);
END-DS;


DCL-PR socket INT(10) EXTPROC('socket');
 AddressFamily INT(10) VALUE;
 SocketType INT(10) VALUE;
 Protocol INT(10) VALUE;
END-PR;

DCL-PR setSockOpt INT(10) EXTPROC('setsockopt');
 SocketDescriptor INT(10) VALUE;
 Level INT(10) VALUE;
 OptName INT(10) VALUE;
 OptValue POINTER VALUE;
 Length INT(10) VALUE;
END-PR;

DCL-PR setSockOpt98 INT(10) EXTPROC('qso_setsockopt98');
 SocketDescriptor INT(10) VALUE;
 Level INT(10) VALUE;
 OptName INT(10) VALUE;
 OptValue POINTER VALUE;
 Length INT(10) VALUE;
END-PR;

DCL-PR getSockOpt INT(10) EXTPROC('getsockopt');
 SocketDescriptor INT(10) VALUE;
 Level INT(10) VALUE;
 OptName INT(10) VALUE;
 OptValue POINTER VALUE;
 Length INT(10);
END-PR;

DCL-PR getSockName INT(10) EXTPROC('getsockname');
 SocketDescriptor INT(10) VALUE;
 SockAddress POINTER VALUE;
 AddressLength POINTER VALUE;
END-PR;

DCL-PR getPeerName INT(10) EXTPROC('getpeername');
 SocketDescriptor INT(10) VALUE;
 SockAddress POINTER VALUE;
 AddressLength INT(10);
END-PR;

DCL-PR bind INT(10) EXTPROC('bind');
 SocketDescriptor INT(10) VALUE;
 Address POINTER VALUE;
 AddressLength INT(10) VALUE;
END-PR;

DCL-PR listen INT(10) EXTPROC('listen');
 SocketDescriptor INT(10) VALUE;
 BackLog INT(10) VALUE;
END-PR;

DCL-PR accept INT(10) EXTPROC('accept');
 SocketDescriptor INT(10) VALUE;
 Address POINTER VALUE;
 AddressLength INT(10);
END-PR;

DCL-PR connect INT(10) EXTPROC('connect');
 SocketDescriptor INT(10) VALUE;
 SocketAddress POINTER VALUE;
 AddressLength INT(10) VALUE;
END-PR;

DCL-PR send INT(10) EXTPROC('send');
 SocketDescriptor INT(10) VALUE;
 Buffer POINTER VALUE;
 BufferLength INT(10) VALUE;
 Flags INT(10) VALUE;
END-PR;

DCL-PR sendTo INT(10) EXTPROC('sendto');
 SocketDescriptor INT(10) VALUE;
 Buffer POINTER VALUE;
 BufferLen INT(10) VALUE;
 Flags INT(10) VALUE;
 DestinationAddress POINTER VALUE;
 AddressLength INT(10) VALUE;
END-PR;

DCL-PR recv INT(10) EXTPROC('recv');
 SocketDescriptor INT(10) VALUE;
 Buffer POINTER VALUE;
 BufferLength INT(10) VALUE;
 Flags INT(10) VALUE;
END-PR;

DCL-PR recvFrom INT(10) EXTPROC('recvfrom');
 SocketDescriptor INT(10) VALUE;
 Buffer POINTER VALUE;
 BufferLength INT(10) VALUE;
 Flags INT(10) VALUE;
 FromAddress POINTER VALUE;
 AddressLength INT(10);
END-PR;

DCL-PR closeSocket INT(10) EXTPROC('close');
 SocketDescriptor INT(10) VALUE;
END-PR;

DCL-PR shutDown INT(10) EXTPROC('shutdown');
 SocketDescription INT(10) VALUE;
 How INT(10) VALUE;
END-PR;

DCL-PR select INT(10) EXTPROC('select');
 MaxDescriptors INT(10) VALUE;
 ReadSet POINTER VALUE;
 WriteSet POINTER VALUE;
 ExceptSet POINTER VALUE;
 WaitTime POINTER VALUE;
END-PR;

DCL-PR giveDescriptor INT(10) EXTPROC('givedescriptor');
 SocketDescriptor INT(10) VALUE;
 TargetJob POINTER VALUE;
END-PR;

DCL-PR takeDescriptor INT(10) EXTPROC('takedescriptor');
 SourceJob POINTER VALUE;
END-PR;

DCL-PR getHostByName POINTER EXTPROC('gethostbyname');
 HostName POINTER VALUE OPTIONS(*STRING);
END-PR;

DCL-PR getServiceByName POINTER EXTPROC('getservbyname');
 ServiceName POINTER VALUE OPTIONS(*STRING);
 ProtocolName POINTER VALUE OPTIONS(*STRING);
END-PR;

DCL-PR getHostByAddress POINTER EXTPROC('gethostbyaddr');
 IPAddress UNS(10);
 AddressLength INT(10) VALUE;
 AddressFamily INT(10) VALUE;
END-PR;

DCL-PR inet_Address UNS(10) EXTPROC('inet_addr');
 CharAddress POINTER VALUE OPTIONS(*STRING);
END-PR;

DCL-PR inet_NToa POINTER EXTPROC('inet_ntoa');
 UnsignedLongAddress UNS(10) VALUE;
END-PR;

DCL-PR fCntl INT(10) EXTPROC('fcntl');
 SocketDescriptor INT(10) VALUE;
 Command INT(10) VALUE;
 Arguments INT(10) VALUE OPTIONS(*NOPASS);
END-PR;
