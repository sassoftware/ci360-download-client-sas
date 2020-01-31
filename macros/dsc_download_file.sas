/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_download_file(url_id=,file_part_no=,url_table=Download_details,datekey=);

	/* get the url for the input file */
	data _null_;
		set &url_table.;
		where url_id=&url_id.;
		call symputx('requestURL',url);
		call symputx('entityName',entityName);
		call symputx('entity_cd',entity_cd);
	run;
	%put INFO: Downloading &entityName. file_part_no = &file_part_no.;
	%let headerout=hdrout;
	%let outfileref= s3out;
	%let requestMethod=%nrquote(GET);
	%let requestCT =%nrquote(application/json);
	%let proxy_host=%nrquote(&DSC_PROXY_HOST);
	%let proxy_port=%nrquote(&DSC_PROXY_PORT);
	%let proxy_auth=%nrquote(&DSC_PROXY_AUTH);
	
	%global outfileNM;
	%let outfileNM=%qcmpres(&DSC_DOWNLOAD_PATH.)/%qcmpres(&entityName.).gz;

	filename &headerout temp;
	filename &outfileref. "&outfileNM.";
	

	%let RetryAttemptNo=0;
	%HTTPTRYAGAIN:

 	%* call PROC HTTTP to download file;
	%dsc_httprequest(
			outfile=&outfileref,
			headerout=&headerout,
			requestURL=%SUPERQ(requestURL),
			requestMethod=&requestMethod,
			proxy_host=&proxy_host,
			proxy_port=&proxy_port,
			proxy_auth=&proxy_auth
			);
    %if &retcode. eq 1 %then
	%do;
		%dsc_echofile_tolog(fileRefs=&headerout);
		%goto HTTPERROR;
	%end;

	%* When PROC HTTP GET is successful then read the header out file to check the status of the download;
	%dsc_httpreadheader(Action=FILE_DOWNLOAD,hdrout=&headerout,outfile=&outfileref);
    %if &retcode. eq 1 %then
	%do;
		%dsc_echofile_tolog(fileRefs=&headerout);
		%goto HTTPERROR;
	%end;
	
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
		%put Note:Retrying HTTP call,Retry attempt number: &RetryAttemptNo. ;
		%goto HTTPTRYAGAIN;
	%end;

	%HTTPSUCCESS:

	%* Extract the downloaded file and create a sas dataset ;
	%put INFO: Extracting &entityName. file_part_no = &file_part_no.;
	%dsc_extract_file(extTableNm=&entityName., extTableCd=&entity_cd., extPartNo= &file_part_no.,datekey=&datekey.);
	
%ERROREXIT:
%mend;
