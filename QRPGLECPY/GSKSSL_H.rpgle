     /*-
      * Copyright (c) 2001 Scott C. Klement
      * All rights reserved.
      *
      * Redistribution and use in source and binary forms, with or without
      * modification, are permitted provided that the following conditions
      * are met:
      * 1. Redistributions of source code must retain the above copyright
      *    notice, this list of conditions and the following disclaimer.
      * 2. Redistributions in binary form must reproduce the above copyright
      *    notice, this list of conditions and the following disclaimer in the
      *    documentation and/or other materials provided with the distribution.
      *
      * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
      * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPO
      * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
      * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTI
      * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
      * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
      * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRI
      * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WA
      * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      * SUCH DAMAGE.
      *
      */


     *** This is a /copy file containing the constants, prototypes
     *** and structures needed to call IBM's Global Secure Toolkit


     *****************************************************************
     **  These errors may be returned by any of the GSKit functions:
     **
     **  (exception: _INVALID_HANDLE & _INVALID_STATE are never
     **              returned by the 'open' function)
     *****************************************************************
     D GSK_OK...
     D                 C                   CONST(0)
     D GSK_INVALID_HANDLE...
     D                 C                   CONST(1)
     D GSK_API_NOT_AVAILABLE...
     D                 C                   CONST(2)
     D GSK_INTERNAL_ERROR...
     D                 C                   CONST(3)
     D GSK_INSUFFICIENT_STORAGE...
     D                 C                   CONST(4)
     D GSK_INVALID_STATE...
     D                 C                   CONST(5)
     D GSK_KEY_LABEL_NOT_FOUND...
     D                 C                   CONST(6)
     D GSK_CERTIFICATE_NOT_AVAILABLE...
     D                 C                   CONST(7)
     D GSK_ERROR_CERT_VALIDATION...
     D                 C                   CONST(8)
     D GSK_ERROR_CRYPTO...
     D                 C                   CONST(9)
     D GSK_ERROR_ASN...
     D                 C                   CONST(10)
     D GSK_ERROR_LDAP...
     D                 C                   CONST(11)
     D GSK_ERROR_UNKNOWN_ERROR...
     D                 C                   CONST(12)


     *****************************************************************
     ** These errors may be returned by any of the '_open' functions
     *****************************************************************
     D GSK_OPEN_CIPHER_ERROR...
     D                 C                   CONST(101)
     D GSK_KEYFILE_IO_ERROR...
     D                 C                   CONST(102)
     D GSK_KEYFILE_INVALID_FORMAT...
     D                 C                   CONST(103)
     D GSK_KEYFILE_DUPLICATE_KEY...
     D                 C                   CONST(104)
     D GSK_KEYFILE_DUPLICATE_LABEL...
     D                 C                   CONST(105)
     D GSK_BAD_FORMAT_OR_INVALID_PASSWORD...
     D                 C                   CONST(106)
     D GSK_KEYFILE_CERT_EXPIRED...
     D                 C                   CONST(107)
     D GSK_ERROR_LOAD_GSKLIB...
     D                 C                   CONST(108)


     *****************************************************************
     **  These may be returned by the gsk_enviornment_init function:
     *****************************************************************
     D GSK_NO_KEYFILE_PASSWORD...
     D                 C                   CONST(201)
     D GSK_KEYRING_OPEN_ERROR...
     D                 C                   CONST(202)
     D GSK_RSA_TEMP_KEY_PAIR...
     D                 C                   CONST(203)


     *****************************************************************
     **  These may be returned by all '_close' functions:
     *****************************************************************
     D GSK_CLOSE_FAILED...
     D                 C                   CONST(203)


     *****************************************************************
     **  These may be returned by the 'gsk_secure_soc_init' function:
     *****************************************************************
     D GSK_ERROR_BAD_DATE...
     D                 C                   CONST(401)
     D GSK_ERROR_NO_CIPHERS...
     D                 C                   CONST(402)
     D GSK_ERROR_NO_CERTIFICATE...
     D                 C                   CONST(403)
     D GSK_ERROR_BAD_CERTIFICATE...
     D                 C                   CONST(404)
     D GSK_ERROR_UNSUPPORTED_CERTIFICATE_TYPE...
     D                 C                   CONST(405)
     D GSK_ERROR_IO...
     D                 C                   CONST(406)
     D GSK_ERROR_BAD_KEYFILE_LABEL...
     D                 C                   CONST(407)
     D GSK_ERROR_BAD_KEYFILE_PASSWORD...
     D                 C                   CONST(408)
     D GSK_ERROR_BAD_KEY_LEN_FOR_EXPORT...
     D                 C                   CONST(409)
     D GSK_ERROR_BAD_MESSAGE...
     D                 C                   CONST(410)
     D GSK_ERROR_BAD_MAC...
     D                 C                   CONST(411)
     D GSK_ERROR_UNSUPPORTED...
     D                 C                   CONST(412)
     D GSK_ERROR_BAD_CERT_SIG...
     D                 C                   CONST(413)
     D GSK_ERROR_BAD_CERT...
     D                 C                   CONST(414)
     D GSK_ERROR_BAD_PEER...
     D                 C                   CONST(415)
     D GSK_ERROR_PERMISSION_DENIED...
     D                 C                   CONST(416)
     D GSK_ERROR_SELF_SIGNED...
     D                 C                   CONST(417)
     D GSK_ERROR_NO_READ_FUNCTION...
     D                 C                   CONST(418)
     D GSK_ERROR_NO_WRITE_FUNCTION...
     D                 C                   CONST(419)
     D GSK_ERROR_SOCKET_CLOSED...
     D                 C                   CONST(420)
     D GSK_ERROR_BAD_V2_CIPHER...
     D                 C                   CONST(421)
     D GSK_ERROR_BAD_V3_CIPHER...
     D                 C                   CONST(422)
     D GSK_ERROR_BAD_SEC_TYPE...
     D                 C                   CONST(423)
     D GSK_ERROR_BAD_SEC_TYPE_COMBINATION...
     D                 C                   CONST(424)
     D GSK_ERROR_HANDLE_CREATION_FAILED...
     D                 C                   CONST(425)
     D GSK_ERROR_INITIALIZATION_FAILED...
     D                 C                   CONST(426)
     D GSK_ERROR_LDAP_NOT_AVAILABLE...
     D                 C                   CONST(427)
     D GSK_ERROR_NO_PRIVATE_KEY...
     D                 C                   CONST(428)


     *****************************************************************
     **  These may be returned by the read and write functions:
     *****************************************************************
     D GSK_INVALID_BUFFER_SIZE...
     D                 C                   CONST(501)
     D GSK_WOULD_BLOCK...
     D                 C                   CONST(502)


     *****************************************************************
     **  These may be returned by the gsk_secure_soc_misc function:
     *****************************************************************
     D GSK_ERROR_NOT_SSLV3...
     D                 C                   CONST(601)
     D GSK_MISC_INVALID_ID...
     D                 C                   CONST(602)


     *****************************************************************
     **  These may be returned by the gsk_attribyute_set_ functions:
     *****************************************************************
     D GSK_ATTRIBUTE_INVALID_ID...
     D                 C                   CONST(701)
     D GSK_ATTRIBUTE_INVALID_LENGTH...
     D                 C                   CONST(702)
     D GSK_ATTRIBUTE_INVALID_ENUMERATION...
     D                 C                   CONST(703)
     D GSK_ATTRIBUTE_INVALID_SID_CACHE...
     D                 C                   CONST(704)
     D GSK_ATTRIBUTE_INVALID_NUMERIC_VALUE...
     D                 C                   CONST(705)


     *****************************************************************
     **  These may be returned by the cert prompt callback routine:
     *****************************************************************
     D GSK_SC_OK...
     D                 C                   CONST(1501)
     D GSK_SC_CANCEL...
     D                 C                   CONST(1502)


     *****************************************************************
     **  Reserve ranges for return values & enumerated types on a
     **   per-platform basis:
     *****************************************************************
     D GSK_AS400_BASE...
     D                 C                   CONST(6000)
     D GSK_AS400_BASE_END...
     D                 C                   CONST(6999)
     D GSK_OS390_BASE...
     D                 C                   CONST(7000)
     D GSK_OS390_BASE_END...
     D                 C                   CONST(7999)


     *****************************************************************
     **  AS/400 specific errors:
     *****************************************************************
     D GSK_AS400_ERROR_NOT_TRUSTED_ROOT...
     D                 C                   CONST(6000)
     D GSK_AS400_ERROR_PASSWORD_EXPIRED...
     D                 C                   CONST(6001)
     D GSK_AS400_ERROR_NOT_REGISTERED...
     D                 C                   CONST(6002)
     D GSK_AS400_ERROR_NO_ACCESS...
     D                 C                   CONST(6003)
     D GSK_AS400_ERROR_CLOSED...
     D                 C                   CONST(6004)
     D GSK_AS400_ERROR_NO_CERTIFICATE_AUTHORITIES...
     D                 C                   CONST(6005)
     D GSK_AS400_ERROR_NO_INITIALIZE...
     D                 C                   CONST(6007)
     D GSK_AS400_ERROR_ALREADY_SECURE...
     D                 C                   CONST(6008)
     D GSK_AS400_ERROR_NOT_TCP...
     D                 C                   CONST(6009)
     D GSK_AS400_ERROR_INVALID_POINTER...
     D                 C                   CONST(6010)
     D GSK_AS400_ERROR_TIMED_OUT...
     D                 C                   CONST(6011)
     D GSK_AS400_ASYNCHRONOUS_RECV...
     D                 C                   CONST(6012)
     D GSK_AS400_ASYNCHRONOUS_SEND...
     D                 C                   CONST(6013)
     D GSK_AS400_ERROR_INVALID_OVERLAPPEDIO_T...
     D                 C                   CONST(6014)
     D GSK_AS400_ERROR_INVALID_IOCOMPLETIONPORT...
     D                 C                   CONST(6015)
     D GSK_AS400_ERROR_BAD_SOCKET_DESCRIPTOR...
     D                 C                   CONST(6016)
     D GSK_AS400_4BYTE_VALUE...
     D                 C                   CONST(70000)


     *****************************************************************
     **
     *****************************************************************
     D gsk_handle      S               *


     *****************************************************************
     **   typedef enum GSK_MISC_ID_T
     **   {
     **     GSK_RESET_CIPHER = 100,  /* Rerun handshake */
     **     GSK_RESET_SESSION = 101, /* Reset SID entry */
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_MISC_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **   } GSK_MISC_ID;
     *****************************************************************
     D GSK_MISC_ID     S             10I 0
     D GSK_RESET_CIPHER...
     D                 C                   CONST(100)
     D GSK_RESET_SESSION...
     D                 C                   CONST(101)


     *****************************************************************
     **   typedef enum GSK_BUF_ID_T
     **   {
     **     GSK_USER_DATA = 200,
     **     GSK_KEYRING_FILE = 201,
     **     GSK_KEYRING_PW = 202,
     **     GSK_KEYRING_LABEL = 203,
     **     GSK_KEYRING_STASH_FILE = 204,
     **     GSK_V2_CIPHER_SPECS = 205,
     **     GSK_V3_CIPHER_SPECS = 206,
     **     GSK_CONNECT_CIPHER_SPEC = 207,
     **     GSK_CONNECT_SEC_TYPE = 208,
     **     GSK_LDAP_SERVER = 209,
     **     GSK_LDAP_USER = 210,
     **     GSK_LDAP_USER_PW = 211,
     **     GSK_SID_VALUE = 212,
     **     GSK_PKCS11_DRIVER_PATH = 213,
     **     GSK_OS400_APPLICATION_ID = 6999,
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_BUF_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **   } GSK_BUF_ID;
     *****************************************************************
     D GSK_BUF_ID      S             10I 0
     D GSK_USER_DATA...
     D                 C                   CONST(200)
     D GSK_KEYRING_FILE...
     D                 C                   CONST(201)
     D GSK_KEYRING_PW...
     D                 C                   CONST(202)
     D GSK_KEYRING_LABEL...
     D                 C                   CONST(203)
     D GSK_KEYRING_STASH_FILE...
     D                 C                   CONST(204)
     D GSK_V2_CIPHER_SPECS...
     D                 C                   CONST(205)
     D GSK_V3_CIPHER_SPECS...
     D                 C                   CONST(206)
     D GSK_CONNECT_CIPHER_SPEC...
     D                 C                   CONST(207)
     D GSK_CONNECT_SEC_TYPE...
     D                 C                   CONST(208)
     D GSK_LDAP_SERVER...
     D                 C                   CONST(209)
     D GSK_LDAP_USER...
     D                 C                   CONST(210)
     D GSK_LDAP_USER_PW...
     D                 C                   CONST(211)
     D GSK_SID_VALUE...
     D                 C                   CONST(212)
     D GSK_PKCS11_DRIVER_PATH...
     D                 C                   CONST(213)
     D GSK_OS400_APPLICATION_ID...
     D                 C                   CONST(6999)


     *****************************************************************
     **   typedef enum GSK_NUM_ID_T
     **   {
     **     GSK_FD = 300,
     **     GSK_V2_SESSION_TIMEOUT = 301,
     **     GSK_V3_SESSION_TIMEOUT = 302,
     **     GSK_LDAP_SERVER_PORT = 303,
     **     GSK_V2_SIDCACHE_SIZE = 304,
     **     GSK_V3_SIDCACHE_SIZE = 305,
     **     GSK_CERTIFICATE_VALIDATION_CODE = 6996,
     **     GSK_HANDSHAKE_TIMEOUT = 6998,
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_NUM_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **   } GSK_NUM_ID;
     *****************************************************************
     D GSK_NUM_ID      S             10I 0
     D GSK_FD...
     D                 C                   CONST(300)
     D GSK_V2_SESSION_TIMEOUT...
     D                 C                   CONST(301)
     D GSK_V3_SESSION_TIMEOUT...
     D                 C                   CONST(302)
     D GSK_LDAP_SERVER_PORT...
     D                 C                   CONST(303)
     D GSK_V2_SIDCACHE_SIZE...
     D                 C                   CONST(304)
     D GSK_V3_SIDCACHE_SIZE...
     D                 C                   CONST(305)
     D GSK_CERTIFICATE_VALIDATION_CODE...
     D                 C                   CONST(6996)
     D GSK_HANDSHAKE_TIMEOUT...
     D                 C                   CONST(6998)


     *****************************************************************
     **   typedef enum GSK_ENUM_ID_T
     **   {
     **     GSK_CLIENT_AUTH_TYPE = 401,
     **     GSK_SERVER_AUTH_TYPE = 410,
     **     GSK_SESSION_TYPE = 402,
     **     GSK_PROTOCOL_SSLV2 = 403,
     **     GSK_PROTOCOL_SSLV3 = 404,
     **     GSK_PROTOCOL_USED = 405,
     **     GSK_SID_FIRST = 406,
     **     GSK_PROTOCOL_TLSV1 = 407,
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_ENUM_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **   } GSK_ENUM_ID ;
     *****************************************************************
     D GSK_ENUM_ID     S             10I 0
     D GSK_CLIENT_AUTH_TYPE...
     D                 C                   CONST(401)
     D GSK_SESSION_TYPE...
     D                 C                   CONST(402)
     D GSK_PROTOCOL_SSLV2...
     D                 C                   CONST(403)
     D GSK_PROTOCOL_SSLV3...
     D                 C                   CONST(404)
     D GSK_PROTOCOL_USED...
     D                 C                   CONST(405)
     D GSK_SID_FIRST...
     D                 C                   CONST(406)
     D GSK_PROTOCOL_TLSV1...
     D                 C                   CONST(407)
     D GSK_SERVER_AUTH_TYPE...
     D                 C                   CONST(410)


     *****************************************************************
     **
     **   typedef enum GSK_ENUM_VALUE_T
     **   {
     **     GSK_NULL = 500,                         /* Use for initial value   *
     **     GSK_CLIENT_AUTH_FULL = 503,             /* GSK_CLIENT_AUTH_TYPE    *
     **     GSK_CLIENT_AUTH_PASSTHRU = 505,         /* GSK_CLIENT_AUTH_TYPE    *
     **     GSK_CLIENT_SESSION = 507,               /* GSK_SESSION_TYPE        *
     **     GSK_SERVER_SESSION = 508,               /* GSK_SESSION_TYPE        *
     **     GSK_SERVER_SESSION_WITH_CL_AUTH = 509,  /* GSK_SESSION_TYPE        *
     **     GSK_PROTOCOL_SSLV2_ON = 510,            /* GSK_PROTOCOL_SSLV2      *
     **     GSK_PROTOCOL_SSLV2_OFF = 511,           /* GSK_PROTOCOL_SSLV2      *
     **     GSK_PROTOCOL_SSLV3_ON = 512,            /* GSK_PROTOCOL_SSLV3      *
     **     GSK_PROTOCOL_SSLV3_OFF = 513,           /* GSK_PROTOCOL_SSLV3      *
     **     GSK_PROTOCOL_USED_SSLV2 = 514,          /* GSK_PROTOCOL_USED       *
     **     GSK_PROTOCOL_USED_SSLV3 = 515,          /* GSK_PROTOCOL_USED       *
     **     GSK_SID_IS_FIRST = 516,                 /* GSK_SID_FIRST           *
     **     GSK_SID_NOT_FIRST = 517,                /* GSK_SID_FIRST           *
     **     GSK_PROTOCOL_TLSV1_ON = 518,            /* GSK_PROTOCOL_TLSV1      *
     **     GSK_PROTOCOL_TLSV1_OFF = 519,           /* GSK_PROTOCOL_TLSV1      *
     **     GSK_PROTOCOL_USED_TLSV1 = 520,          /* GSK_PROTOCOL_USED (get) *
     **     GSK_SERVER_AUTH_PASSTHRU = 535,         /* GSK_SERVER_AUTH_TYPE    *
     **     GSK_OS400_CLIENT_AUTH_REQUIRED = 6995,  /* GSK_CLIENT_AUTH_TYPE    *
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_ENUM_VALUE_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **   } GSK_ENUM_VALUE ;
     *****************************************************************
     D GSK_ENUM_VALUE  S             10I 0
     D GSK_NULL...
     D                 C                   CONST(500)
     D GSK_CLIENT_AUTH_FULL...
     D                 C                   CONST(503)
     D GSK_CLIENT_AUTH_PASSTHRU...
     D                 C                   CONST(505)
     D GSK_CLIENT_SESSION...
     D                 C                   CONST(507)
     D GSK_SERVER_SESSION...
     D                 C                   CONST(508)
     D GSK_SERVER_SESSION_WITH_CL_AUTH...
     D                 C                   CONST(509)
     D GSK_PROTOCOL_SSLV2_ON...
     D                 C                   CONST(510)
     D GSK_PROTOCOL_SSLV2_OFF...
     D                 C                   CONST(511)
     D GSK_PROTOCOL_SSLV3_ON...
     D                 C                   CONST(512)
     D GSK_PROTOCOL_SSLV3_OFF...
     D                 C                   CONST(513)
     D GSK_PROTOCOL_USED_SSLV2...
     D                 C                   CONST(514)
     D GSK_PROTOCOL_USED_SSLV3...
     D                 C                   CONST(515)
     D GSK_SID_IS_FIRST...
     D                 C                   CONST(516)
     D GSK_SID_NOT_FIRST...
     D                 C                   CONST(517)
     D GSK_PROTOCOL_TLSV1_ON...
     D                 C                   CONST(518)
     D GSK_PROTOCOL_TLSV1_OFF...
     D                 C                   CONST(519)
     D GSK_PROTOCOL_USED_TLSV1...
     D                 C                   CONST(520)
     D GSK_SERVER_AUTH_PASSTHRU...
     D                 C                   CONST(535)
     D GSK_OS400_CLIENT_AUTH_REQUIRED...
     D                 C                   CONST(6995)

     *****************************************************************
     **   /* The following enumerated type is the identifier for the data type
     **      of the elements of the array of information in the gsk_cert_data
     **      structure. Note that depending on the specific certificate, some
     **      data types may not be present. */
     **   typedef enum GSK_CERT_DATA_ID_T
     **   {
     **     CERT_BODY_DER = 600,     /* complete certificate body, der format */
     **     CERT_BODY_BASE64 = 601,  /* complete certificate body, base 64    */
     **     CERT_SERIAL_NUMBER = 602,
     **     CERT_COMMON_NAME = 610,
     **     CERT_LOCALITY = 611,
     **     CERT_STATE_OR_PROVINCE = 612,
     **     CERT_COUNTRY = 613,
     **     CERT_ORG = 614,
     **     CERT_ORG_UNIT = 615,
     **     CERT_DN_PRINTABLE = 616,
     **     CERT_DN_DER = 617,
     **     CERT_POSTAL_CODE = 618,
     **     CERT_EMAIL = 619,
     **     CERT_ISSUER_COMMON_NAME = 650,
     **     CERT_ISSUER_LOCALITY = 651,
     **     CERT_ISSUER_STATE_OR_PROVINCE = 652,
     **     CERT_ISSUER_COUNTRY = 653,
     **     CERT_ISSUER_ORG = 654,
     **     CERT_ISSUER_ORG_UNIT = 655,
     **     CERT_ISSUER_DN_PRINTABLE = 656,
     **     CERT_ISSUER_DN_DER = 657,
     **     CERT_ISSUER_POSTAL_CODE = 658,
     **     CERT_ISSUER_EMAIL = 659,
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_CERT_DATA_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **
     **   } GSK_CERT_DATA_ID;
     *****************************************************************
     D GSK_CERT_DATA_ID...
     D                 S             10I 0
     D CERT_BODY_DER...
     D                 C                   CONST(600)
     D CERT_BODY_BASE64...
     D                 C                   CONST(601)
     D CERT_SERIAL_NUMBER...
     D                 C                   CONST(602)
     D CERT_COMMON_NAME...
     D                 C                   CONST(610)
     D CERT_LOCALITY...
     D                 C                   CONST(611)
     D CERT_STATE_OR_PROVINCE...
     D                 C                   CONST(612)
     D CERT_COUNTRY...
     D                 C                   CONST(613)
     D CERT_ORG...
     D                 C                   CONST(614)
     D CERT_ORG_UNIT...
     D                 C                   CONST(615)
     D CERT_DN_PRINTABLE...
     D                 C                   CONST(616)
     D CERT_DN_DER...
     D                 C                   CONST(617)
     D CERT_POSTAL_CODE...
     D                 C                   CONST(618)
     D CERT_EMAIL...
     D                 C                   CONST(619)
     D CERT_ISSUER_COMMON_NAME...
     D                 C                   CONST(650)
     D CERT_ISSUER_LOCALITY...
     D                 C                   CONST(651)
     D CERT_ISSUER_STATE_OR_PROVINCE...
     D                 C                   CONST(652)
     D CERT_ISSUER_COUNTRY...
     D                 C                   CONST(653)
     D CERT_ISSUER_ORG...
     D                 C                   CONST(654)
     D CERT_ISSUER_ORG_UNIT...
     D                 C                   CONST(655)
     D CERT_ISSUER_DN_PRINTABLE...
     D                 C                   CONST(656)
     D CERT_ISSUER_DN_DER...
     D                 C                   CONST(657)
     D CERT_ISSUER_POSTAL_CODE...
     D                 C                   CONST(658)
     D CERT_ISSUER_EMAIL...
     D                 C                   CONST(659)

     *****************************************************************
     **   typedef struct gsk_cert_data_elem_t
     **   {
     **     GSK_CERT_DATA_ID cert_data_id;  /* identifer of each data type */
     **     char *cert_data_p;  /* pointer to data */
     **     int cert_data_l;  /* length of data (not including trailing null) */
     **
     **   } gsk_cert_data_elem;
     *****************************************************************
     D p_gsk_cert_data_elem...
     D                 S               *
     D gsk_cert_data_elem...
     D                 DS                  ALIGN
     D                                     BASED(p_gsk_cert_data_elem)
     D   cert_data_id                      like(GSK_CERT_DATA_ID)
     D   cert_data_p                   *
     D   cert_data_l                 10I 0

     *****************************************************************
     **   typedef enum GSK_CERT_ID_T
     **   {
     **     GSK_PARTNER_CERT_INFO = 700,
     **     GSK_LOCAL_CERT_INFO = 701,
     **                  /* Force enum size to 4 bytes - do not use this value *
     **     GSK_AS400_CERT_FINAL = GSK_AS400_4BYTE_VALUE
     **
     **   } GSK_CERT_ID ;
     *****************************************************************
     D GSK_CERT_ID     S             10I 0
     D GSK_PARTNER_CERT_INFO...
     D                 C                   CONST(700)
     D GSK_LOCAL_CERT_INFO...
     D                 C                   CONST(701)


      **---------------------------------------------------------------------
      **  int gsk_environment_open(gsk_handle *my_env_handle)
      **
      **     creates a new GSKit Enviorment.  (This is the first API
      **     you need to call)
      **
      **---------------------------------------------------------------------
     D gsk_environment_open...
     D                 PR            10I 0 extproc('gsk_environment_open')
     D  my_env_handle                      like(gsk_handle)


      **---------------------------------------------------------------------
      **
      **  int gsk_environment_init(gsk_handle my_env_handle)
      **
      **---------------------------------------------------------------------
     D gsk_environment_init...
     D                 PR            10I 0 extproc('gsk_environment_init')
     D  my_env_handle                      like(gsk_handle) value

      **---------------------------------------------------------------------
      **
      **  int gsk_environment_close(gsk_handle *my_env_handle)
      **
      **---------------------------------------------------------------------
     D gsk_environment_close...
     D                 PR            10I 0 extproc('gsk_environment_close')
     D  my_env_handle                      like(gsk_handle)

      **---------------------------------------------------------------------
      **
      **   int gsk_attribute_get_buffer(gsk_handle my_gsk_handle,
      **                            GSK_BUF_ID bufID,
      **                            const char **buffer,
      **                            int *bufSize);
      **
      **---------------------------------------------------------------------
     D gsk_attribute_get_buffer...
     D                 PR            10I 0 extproc('gsk_attribute_get_buffer')
     D  my_gsk_handle                      like(gsk_handle) value
     D  bufID                              like(GSK_BUF_ID) value
     D  buffer                         *   value
     D  bufSize                      10I 0

      **---------------------------------------------------------------------
      **
      **   int gsk_attribute_set_buffer(gsk_handle my_gsk_handle,
      **                            GSK_BUF_ID bufID,
      **                            const char *buffer,
      **                            int bufSize);
      **
      **---------------------------------------------------------------------
     D gsk_attribute_set_buffer...
     D                 PR            10I 0 extproc('gsk_attribute_set_buffer')
     D  my_gsk_handle                      like(gsk_handle) value
     D  bufID                              like(GSK_BUF_ID) value
     D  buffer                         *   value options(*string)
     D  bufSize                      10I 0 value

      **---------------------------------------------------------------------
      **
      **  int gsk_attribute_get_cert_info(gsk_handle my_gsk_handle,
      **                  GSK_CERT_ID certID,
      **                  const gsk_cert_data_elem **certDataElem,
      **                  int *certDataElemCount);
      **
      **---------------------------------------------------------------------
     D gsk_attribute_get_cert_info...
     D                 PR            10I 0 extproc('gsk_attribute_get_cert_+
     d                                     info')
     D  my_gsk_handle                      like(gsk_handle) value
     D  certID                             like(GSK_CERT_ID) value
     D  certDataElem                   *   value
     D  certDataElemCount...
     D                               10I 0

      **---------------------------------------------------------------------
      **
      **   int gsk_attribute_get_enum(gsk_handle my_gsk_handle,
      **                          GSK_ENUM_ID enumID,
      **                          GSK_ENUM_VALUE *enumValue);
      **
      **---------------------------------------------------------------------
     D gsk_attribute_get_enum...
     D                 PR            10I 0 extproc('gsk_attribute_get_enum')
     D  my_gsk_handle                      like(gsk_handle) value
     D  enumID                             like(GSK_ENUM_ID) value
     D  enumValue                          like(GSK_ENUM_VALUE)

      **---------------------------------------------------------------------
      **
      **    int gsk_attribute_get_numeric_value(gsk_handle my_gsk_handle,
      **                                   GSK_NUM_ID numID,
      **                                   int *numValue);
      **
      **---------------------------------------------------------------------
     D gsk_attribute_get_numeric_value...
     D                 PR            10I 0 extproc('gsk_attribute_get_+
     D                                     numeric_value')
     D  my_gsk_handle                      like(gsk_handle) value
     D  numID                              like(GSK_NUM_ID) value
     D  numValue                     10I 0

      **---------------------------------------------------------------------
      **
      **  int gsk_attribute_set_enum(gsk_handle my_gsk_handle,
      **                          GSK_ENUM_ID enumID,
      **                          GSK_ENUM_VALUE enumValue);
      **---------------------------------------------------------------------
     D gsk_attribute_set_enum...
     D                 PR            10I 0 extproc('gsk_attribute_set_enum')
     D  my_gsk_handle                      like(gsk_handle) value
     D  enumID                             like(GSK_ENUM_ID) value
     D  enumValue                          like(GSK_ENUM_VALUE) value

      **---------------------------------------------------------------------
      **
      **  int gsk_attribute_set_numeric_value(gsk_handle my_gsk_handle,
      **                                    GSK_NUM_ID numID,
      **                                    int numValue);
      **---------------------------------------------------------------------
     D gsk_attribute_set_numeric_value...
     D                 PR            10I 0 extproc('gsk_attribute_set_+
     D                                     numeric_value')
     D  my_gsk_handle                      like(gsk_handle) value
     D  numID                              like(GSK_NUM_ID) value
     D  numValue                     10I 0 value

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_open(gsk_handle my_env_handle,
      **                        gsk_handle *my_session_handle);
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_open...
     D                 PR            10I 0 extproc('gsk_secure_soc_open')
     D  my_env_handle                      like(gsk_handle) value
     D  my_ssn_handle                      like(gsk_handle)

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_init(gsk_handle my_session_handle);
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_init...
     D                 PR            10I 0 extproc('gsk_secure_soc_init')
     D  my_ssn_handle                      like(gsk_handle) value

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_misc(gsk_handle my_session_handle,
      **                          GSK_MISC_ID miscID);
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_misc...
     D                 PR            10I 0 extproc('gsk_secure_soc_misc')
     D  my_ssn_handle                      like(gsk_handle) value
     D  miscID                             like(GSK_MISC_ID) value

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_read(gsk_handle my_session_handle,
      **                        char *readBuffer,
      **                        int readBufSize,
      **                        int *amtRead);
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_read...
     D                 PR            10I 0 extproc('gsk_secure_soc_read')
     D  my_ssn_handle                      like(gsk_handle) value
     D  readBuffer                     *   value
     D  readBufSize                  10I 0 value
     D  amtRead                      10I 0

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_write(gsk_handle my_session_handle,
      **                        char *writeBuffer,
      **                        int writeBufSize,
      **                        int *amtWritten);
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_write...
     D                 PR            10I 0 extproc('gsk_secure_soc_write')
     D  my_ssn_handle                      like(gsk_handle) value
     D  writeBuffer                    *   value
     D  writeBufSize                 10I 0 value
     D  amtWritten                   10I 0

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_close(gsk_handle *my_session_handle);
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_close...
     D                 PR            10I 0 extproc('gsk_secure_soc_close')
     D  my_ssn_handle                      like(gsk_handle)

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_startRecv (gsk_handle my_session_handle,
      **              int IOCompletionPort,
      **              Qso_OverlappedIO_t *communicationsArea)
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_startRecv...
     D                 PR            10I 0 extproc('gsk_secure_soc_startRecv')
     D  my_ssn_handle                      like(gsk_handle) value
     D  IOComplPort                  10I 0 value
     D  communArea                     *   value

      **---------------------------------------------------------------------
      **
      **  int gsk_secure_soc_startSend (gsk_handle my_session_handle,
      **              int IOCompletionPort,
      **              Qso_OverlappedIO_t *communicationsArea)
      **
      **---------------------------------------------------------------------
     D gsk_secure_soc_startSend...
     D                 PR            10I 0 extproc('gsk_secure_soc_startSend')
     D  my_ssn_handle                      like(gsk_handle) value
     D  IOComplPort                  10I 0 value
     D  communArea                     *   value

      **---------------------------------------------------------------------
      **
      **  const char *gsk_strerror(int gsk_return_value);
      **
      **---------------------------------------------------------------------
     d gsk_strerror    PR              *   extproc('gsk_strerror')
     D  gsk_ret_value                10I 0 value
