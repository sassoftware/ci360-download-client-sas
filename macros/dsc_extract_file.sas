/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_extract_file(extTableNm=,extTableCd=,extPartNo=,datekey=);
	%let extTableNm=%lowcase(&extTableNm);

	filename acsgzip Pipe "gzip -cd &outfileNM.";

	data DSCEXTR.&extTableCd._PR&extPartNo. ;
		infile acsgzip dlm = '01'x dsd &DSC_FILE_READ_OPTION ;
		%&dsc_schema_macro_nm.(tbl_nm=&extTableNm);
		
		%if &datekey. ne %then
		%do;
			attrib datekey length=8. FORMAT=12.;
			datekey =&datekey;
		%end;

	run;

	filename acsgzip clear;

%ERROREXIT:
%mend;
