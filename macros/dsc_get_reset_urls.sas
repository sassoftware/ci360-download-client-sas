/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_get_reset_urls();
    %******************************************************************************;
    %* Get reset urls ;
    %******************************************************************************;

	%* Define filenames ;
	%let headerin=hdrin ;
	%let headerout=hdrout ;
	%let outfile=urllist ;
	%let urlListMap=ResetMap ;

	filename &headerin temp ;
	filename &headerout temp ;
	filename &outfile temp ;
	filename &urlListMap "&DSC_RESET_URLLIST_MAPFILE.";

	%* Create request header ;
	data _null_;
		file hdrin encoding="utf-8" recfm=f lrecl=1;
		put 'Accept: application/vnd.sas.collection+json';
	run;

	%let requestMethod=%nrquote(GET);
	%let requestCT =%nrquote(application/json);
	%let service_auth = headers "Authorization" = "Bearer &DSC_AUTH_TOKEN.";
	%let proxy_host=%nrquote(&DSC_PROXY_HOST);
	%let proxy_port=%nrquote(&DSC_PROXY_PORT);
	%let proxy_auth=%nrquote(&DSC_PROXY_AUTH);

	%let RetryAttemptNo=0;
	%HTTPTRYAGAIN:

	%* call PROC HTTTP ;
	%dsc_httprequest(outfile=&outfile,
					headerin=&headerin,
					headerout=&headerout,
					requestCT=&requestCT,
					requestURL=%SUPERQ(DSC_RESET_URL),
					requestMethod=&requestMethod,
					service_auth=&service_auth,
					proxy_host=&proxy_host,
					proxy_port=&proxy_port,
					proxy_auth=&proxy_auth
					);
	%if &retcode=1 %then
	%do;
		%dsc_echofile_tolog(fileRefs=&headerin &headerout &outfile);
		%goto HTTPERROR;
	%end;

	%* When PROC HTTP is successful then read the header out file to check the status of the execution;
	%dsc_httpreadheader(Action=GET_URLLIST,hdrout=&headerout);
	%if &retcode=1 %then
	%do;
		%dsc_echofile_tolog(fileRefs=&headerin &headerout &outfile);
		%goto HTTPERROR;
	%end;

	%* Read the json outout file returned by proc http and convert json file into datasets;
	/*libname jsondata json fileref=&outfile ;*/
	libname jsondata json fileref=&outfile map=&urlListMap;

	proc copy in=jsondata out=work;
	run;

    %let nobs = 0;
	proc sql noprint;
        select nobs into :nobs separated by ' ' from dictionary.tables
        where libname="WORK" and memname='RESET_ROOT';
    quit;

    %if &nobs = 0 %then %do;
        data _null_;
            set jsondata.alldata;
            if upcase(p1) = trim('MESSAGE') then do;
                warning = "WARNING:  " || trim(value);
                put warning;
            end;
        run;

        %let retcode=2;
        %put ERROR: No Data Available for Reset;
       %goto ERROREXIT;
    %end;

	%* check if there are reset date ranges available to process ;
	proc sql noprint;
		select count into :reset_ranges_cnt from reset_root;
	;quit;
	%if &reset_ranges_cnt. = 0 %then
	%do;
		%let retcode=2;
		%put ERROR: No Data Available for Reset;
		%goto ERROREXIT;
	%end;

	data reset_items;
		set reset_items;
		attrib datekey length=8. FORMAT=12.;
		datekey =put(datepart(dataRangeStartTimeStamp) , yymmddn8.) || put(hour(dataRangeStartTimeStamp),z2.);
	run;

	proc sql;
		create table reset_details as
		select
				t1.ordinal_items as range_id
				,t1.datekey
				,t1.dataRangeStartTimeStamp
				,t1.dataRangeEndTimeStamp
				,t1.resetCompletedTimeStamp
				,t1.downloadUrl
		from	reset_items t1
	;quit;

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
