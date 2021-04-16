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


/INCLUDE QRPGLECPY,H_SPECS
CTL-OPT MAIN(Main);


DCL-PR Main EXTPGM('ZCMDCHC');
  IncommingParmDS LIKEDS(IncommingParmDS_T) CONST;
  OutgoingParm CHAR(2000);
END-PR;

/INCLUDE QRPGLECPY,BOOLIC

DCL-DS IncommingParmDS_T QUALIFIED TEMPLATE;
 Command CHAR(10);
 KeyWord CHAR(10);
 DataType CHAR(1);
END-DS;

DCL-DS OutgoingParmDS_T QUALIFIED TEMPLATE;
 Length BINDEC(2);
 Content CHAR(1998);
END-DS;

DCL-DS EntryDS_T QUALIFIED TEMPLATE;
 Length BINDEC(2);
 Value CHAR(32);
END-DS;


//#########################################################################
DCL-PROC Main;
 DCL-PI *N;
  pIncommingParmDS LIKEDS(IncommingParmDS_T) CONST;
  pOutgoingParm CHAR(2000);
 END-PI;

 DCL-DS EntryDS LIKEDS(EntryDS_T) INZ;
 DCL-DS OutgoingParmDS LIKEDS(OutgoingParmDS_T) INZ;
 //-------------------------------------------------------------------------

 /INCLUDE QRPGLECPY,SQLOPTIONS

 *INLR = TRUE;
 Clear pOutgoingParm;

 Select;

   When ( pIncommingParmDS.Command = 'ZCLIENT') And ( pIncommingParmDS.KeyWord = 'RMTSYS' )
    And ( pIncommingParmDS.DataType = 'C' );

     pOutgoingParm = 'Remotesystem';

   When ( pIncommingParmDS.Command = 'ZCLIENT') And ( pIncommingParmDS.KeyWord = 'RMTSYS' )
    And ( pIncommingParmDS.DataType = 'P' );

     Exec SQL DECLARE c_host_reader INSENSITIVE CURSOR FOR
                   -- get the first 58 entries from the system-host-table
               SELECT LENGTH(RTRIM(LEFT(host.hostnme1, 32))),
                      LEFT(host.hostnme1, 32)
                 FROM qusrsys.qatochost host
                WHERE host.hostnme1 <> ''
                ORDER BY 1 LIMIT 58;

     Exec SQL OPEN c_host_reader;

     Exec SQL GET DIAGNOSTICS :OutgoingParmDS.Length = DB2_NUMBER_ROWS;

     Dow ( 1 = 1 );
       Exec SQL FETCH NEXT FROM c_host_reader INTO :EntryDS;
       If ( SQLCode <> 0 );
         Exec SQL CLOSE c_host_reader;
         Leave;
       EndIf;

       OutgoingParmDS.Content = %TrimR(OutgoingParmDS.Content) + %TrimR(EntryDS);

     EndDo;

 EndSl;

 pOutgoingParm = OutgoingParmDS;

 Return;

END-PROC;
