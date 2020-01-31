/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_reset_records(datekey=);

	%put INFO:Start deleting records for datekey=&datekey. ;

	proc sql noprint;
		%do i = 1 %to %eval(&Count_Mart_tables.);
			%if %sysfunc( exist( DSCWH.&&Table_Nm&i. ) ) %then
			%do;
				%if (%dsc_varexist(DSCWH.&&Table_Nm&i. , datekey))%then 
				%do;				
					%put INFO: deleting records from DSCWH.&&Table_Nm&i.;
					delete from DSCWH.&&Table_Nm&i. where datekey=&datekey.;
				%end;
			%end;
		%end;
	quit;

	%if &SYSERR. > 4 %then 
    %do;
       	%put &SYSERRORTEXT. ;
		%let retcode=1; 
		%put ERROR: Error in deleting records ;
   	%end;
	%else %put INFO:Finished deleting records for datekey=&datekey. ;

%mend;
