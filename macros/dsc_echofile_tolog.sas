/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_echofile_tolog(fileRefs=);

	/* echo the file contents to log if file exists */
	%if %length(&fileRefs) > 0 %then
	%do;
		%let i=1;
        %do %while (%scan(&fileRefs,&i,' ') ne );
			%let fileRef=%scan(&fileRefs,&i);
			/* if the fileref & its associated file exists? */
			%if %sysfunc(fileref(&fileRef)) = 0 %then
		    %do;				
				data _null_;			
				    length linetxt $32767; 
					if _n_ = 1 then 
					do;
/*						fileHeader=sasmsg("&msg_dset","_cxa_norm_19_note","noquote","&fileRef");*/
/*						put fileHeader;*/
					end;
				    infile &fileRef. length=reclen ; 
				    input linetxt $varying32767. reclen ;
					put linetxt;
				run;
			%end;
			%let i=%eval(&i+1);
		%end;/* %do %while */
	%end;/*%if %length(&fileRefs)*/
%mend;
