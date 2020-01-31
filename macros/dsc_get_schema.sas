/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_get_schema(schemaUrl=);
    %******************************************************************************;
    %* Get schema  ;
    %******************************************************************************;	
	%* Define filenames ;	
	%let headerout=hdrout ;		
	%let outfile=mdfile;

	filename &headerout temp ;
	filename &outfile "&UtilityLocation./data/dsccnfg/&schemaName._schema.json";

	%let requestMethod=%nrquote(GET);
	%let proxy_host=%nrquote(&DSC_PROXY_HOST);
	%let proxy_port=%nrquote(&DSC_PROXY_PORT);
	%let proxy_auth=%nrquote(&DSC_PROXY_AUTH);

	%let RetryAttemptNo=0;
	%HTTPTRYAGAIN:

	%* call PROC HTTTP ;
	%dsc_httprequest(outfile=&outfile,
					headerout=&headerout,
					requestURL=%SUPERQ(schemaUrl),
					requestMethod=&requestMethod,
					proxy_host=&proxy_host,
					proxy_port=&proxy_port,
					proxy_auth=&proxy_auth
					);
	%if &retcode=1 %then 
	%do;
		%dsc_echofile_tolog(fileRefs=&headerout &outfile);
		%goto HTTPERROR;
	%end;

	%* When PROC HTTP is successful then read the header out file to check the status of the execution;
	%dsc_httpreadheader(Action=GET_SCHEMA,hdrout=&headerout);
	%if &retcode=1 %then 
	%do;
		%dsc_echofile_tolog(fileRefs=&headerout &outfile);
		%goto HTTPERROR;
	%end;

	%* Read the mdfile returned by proc http and convert json file into datasets;
	/*	libname jsondata json fileref=&outfile map=&urlListMap;*/
	libname mdjson json fileref=mdfile;
	proc copy in=mdjson out=work;
	run;
	
	/* Rename the json data tables for later use ?*/
	data schema_details;
		set root;
	run;

	%goto HTTPSUCCESS;

	/* on http errors retry http call */
	%HTTPERROR:
	
	/* if retry attempts are left then try again */
	%if &RetryAttemptNo. < &DSC_HTTP_MAX_RETRY_ATTEMPTS. %then
	%do;
		/* reset retcode */
		%let retcode=0;

		/*increment RetryAttemptNo */
		%let RetryAttemptNo=%sysevalf(&RetryAttemptNo + 1);

		/* do some rest */
		data _null_;
			call sleep(&DSC_HTTP_RETRY_WAIT_SEC.,1);
		run;
		%put Note:Retrying HTTP call,Retry attempt number: &RetryAttemptNo.;
		%goto HTTPTRYAGAIN;
	%end;

%HTTPSUCCESS:
%ERROREXIT:
%mend;
