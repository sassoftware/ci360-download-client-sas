/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_get_download_urls(part=1);
	/* part=1 -- for partitioned data urls
	   part=0 - for non partitioned data urls
	*/
    %******************************************************************************;
    %* Get download urls ;
    %******************************************************************************;
	%* Define filenames ;
	%let headerin=hdrin ;
	%let headerout=hdrout ;
	%let outfile=urllist ;
	%let urlListMap=lstMap ;

	filename &headerin temp ;
	filename &headerout temp ;
	filename &outfile temp ;

	%if %sysfunc(upcase("&category")) eq "CDM" and &part = 0 %then
	%do;
	    filename &urlListMap "&DSC_CDM_NONPAR_URLLIST_MAPFILE.";
	%end;
	%else
	%do;
      filename &urlListMap "&DSC_URLLIST_MAPFILE.";
  %end;

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
					requestURL=%SUPERQ(DSC_DOWNLOAD_URL),
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

	/* for partitioned data */
	%if &part = 1 %then
	%do;
		%* check if there are date ranges available to process ;
		proc sql noprint;
			select count(*) into :date_range_cnt from Items;
		;quit;
		%if &date_range_cnt = 0 %then
		%do;
			%let retcode=1;
			%put ERROR: No Data Available for Download;
			%goto ERROREXIT;
		%end;

		data items;
			set items;
			attrib datekey length=8. FORMAT=12.;
			datekey =put(datepart(dataRangeStartTimeStamp) , yymmddn8.) || put(hour(dataRangeStartTimeStamp),z2.);
		run;

		data items_entities;
			set items_entities;
			entity_cd ='ENTITY_CD' || strip(ordinal_entities);
		run;

		proc sql;
			create table download_details as
			select
					t1.ordinal_items as range_id
					,t1.datekey
					,dataRangeStartTimeStamp
					,dataRangeEndTimeStamp
					,SchemaUrl
					,SchemaVersion
					,entityName
					,ordinal_dataUrlDetails as url_id
					,url
					,t2.entity_cd as entity_cd
			from	Items t1
			left join items_entities t2
			on	t1.ordinal_items=t2.ordinal_items
			left join	entities_dataurldetails t3
			on	t2.ordinal_entities=t3.ordinal_entities
			order by t1.ordinal_items ,entityName
		;quit;
	%end;
	/* for non partitioned data */
	%else %if &part = 0 %then
	%do;
		%* check if there are date ranges available to process ;
		proc sql noprint;
			select count(*) into :non_part_cnt from Items_entities;
		;quit;
		%if &non_part_cnt = 0 %then
		%do;
			%let retcode=1;
			%put ERROR: No Data Available for Download;
			%goto ERROREXIT;
		%end;

		/* as the table nm's can be upto 32 chars , the process later adds suffix while downloading
		and exgtracting which can cause the table name go beyond 32 chars
		to avoid the legnth limit error create a short nm for each entity and use that for downloading and extracting */
		data items_entities;
			set items_entities;
			entity_cd ='ENTITY_CD' || strip(ordinal_entities);
		run;
		/* create the list of non partitioned tables available for download with the details */
		proc sql;
			create table nonPart_details as
			select 	t1.SchemaUrl
					,t1.SchemaVersion
					,t2.entityName
					,t3.url
					,t3.ordinal_dataUrlDetails as url_id
					,t3.lastModifiedTimestamp
					,t2.entity_cd as entity_cd
			from	Items t1
			inner join Items_entities t2
			on	t1.ordinal_items=t2.ordinal_items
			inner join	Entities_dataurldetails t3
			on	t2.ordinal_entities=t3.ordinal_entities
		;quit;
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
		%put Note:Retrying HTTP call,Retry attempt number: &RetryAttemptNo.;
		%goto HTTPTRYAGAIN;
	%end;

%HTTPSUCCESS:
%ERROREXIT:
%mend;
