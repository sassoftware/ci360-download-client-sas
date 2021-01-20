/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_download_data(mart_nm=,reset_day_offset=);

	%let client_version=4;
	%put download client version no : &client_version. ;

	%global retcode;
	%let retcode=0;

  %if %sysfunc(upcase("&mart_nm.")) eq "CDM" %then
      %dsc_cdm_version_update(version_num=&dsc_schema_version);
  %else
	    %dsc_version_update(version_num=&client_version.);

	%if &retcode = 1 %then %goto ERROREXIT;

	%put Start Processing &mart_nm.;

	%let mart_download_history=dsccnfg.&mart_nm._download_history;
	%let mart_reset_history=dsccnfg.&mart_nm._reset_history;

	%global DSC_DOWNLOAD_PATH DSC_CONFIG_PATH DSC_URLLIST_MAPFILE DSC_RESET_URLLIST_MAPFILE
	        DSC_CDM_NONPAR_URLLIST_MAPFILE;

	%* Get the path of the download library ;
	proc sql noprint;
    	select 	path into :DSC_DOWNLOAD_PATH
		from 	sashelp.vlibnam
        where 	upcase(libname)=upcase("DSCDONL");
   	quit;

	%* Get the path of the config library ;
	proc sql noprint;
    	select 	path into :DSC_CONFIG_PATH
		from 	sashelp.vlibnam
        where 	upcase(libname)=upcase("DSCCNFG");
   	quit;

	%* cleanup any previous left overs in the dscextr library ;
	proc datasets lib=DSCEXTR kill noprint;
    quit;

	%* set macro variable to hold map file path ;
	data _null_;
		DSC_CONFIG_PATH=symget('DSC_CONFIG_PATH');
		%if &mart_nm.= detail or &mart_nm.= dbtReport %then
		%do;
			DSC_URLLIST_MAPFILE=strip(DSC_CONFIG_PATH)||'/urlDataList.map';
			DSC_RESET_URLLIST_MAPFILE=strip(DSC_CONFIG_PATH)||'/resetDataList.map';
		%end;
		/* identity tables reside under non partitioned api end point in detail mart
		with UDM there are many more non partitioned tables added in detail mart.
		so instead of using mart_nm as identity , renaming this as 'snapshot'
		mart_nm = snapshot should be specified for identity as well as other metadata tables added in UDM 	*/
		%else %if &mart_nm.= identity or &mart_nm.= snapshot %then
		%do;
			DSC_URLLIST_MAPFILE=strip(DSC_CONFIG_PATH)||'/urlNonPartDataList.map';
		%end;
		/* cdm mart uses the same api as the detail mart. */
		%else %if %sysfunc(upcase("&mart_nm.")) eq "CDM" %then
		%do;
			DSC_URLLIST_MAPFILE=strip(DSC_CONFIG_PATH)||'/urlDataList.map';
		  DSC_CDM_NONPAR_URLLIST_MAPFILE=strip(DSC_CONFIG_PATH)||'/urlNonPartDataList.map';
			DSC_RESET_URLLIST_MAPFILE=strip(DSC_CONFIG_PATH)||'/resetDataList.map';
			call symputx('DSC_CDM_NONPAR_URLLIST_MAPFILE',DSC_CDM_NONPAR_URLLIST_MAPFILE);
			call symputx('DSC_CDM_DOWNLOAD_URL_ORIG', "&DSC_DOWNLOAD_URL.");
		%end;
		call symputx('DSC_URLLIST_MAPFILE',DSC_URLLIST_MAPFILE);
		call symputx('DSC_RESET_URLLIST_MAPFILE',DSC_RESET_URLLIST_MAPFILE);
	run;

	%let TokenGenMethod=python;
	%if &TokenGenMethod=python %then
	%do;
		/******************************************************************************
		Generate the Authentication token using python function
		verify if the python token generation works correctly from OS command line e.g.
		c:\python36\python.exe c:\generatejwt.py --tenantId XXXXX --secretKey XXXXXXXX
		******************************************************************************/
		%* python command to generate the authentication token ;
		data python_cmd ;
			dsc_config_path=symget('DSC_CONFIG_PATH');
			python_path=symget('PYTHON_PATH');

			python_function_file=strip(DSC_CONFIG_PATH)||'/generatejwt.py';
			tenantId=symget('DSC_TENANT_ID');
			secretKey=symget('DSC_SECRET_KEY');
			pythoncmd=strip(python_path) || ' ' || strip(python_function_file) || ' --tenantId ' || strip(tenantId) || ' --secretKey ' || strip(secretKey);
			call symput ('pythoncmd',trim(pythoncmd));
			put pythoncmd;
		run;
		%* assign filename to route the output of python command in file ;
		filename oscmd pipe "&pythoncmd.";

		%* read the token value returned by python command ;
		data jwtToken;
			infile oscmd;
			input;
			TokenVal= _infile_;
		run;
		%* de-assign python command file ;
		filename oscmd ;
		%*;
		data _null_;
			set jwtToken;
			call symputx('DSC_AUTH_TOKEN',TokenVal);
		run;
	%end;
	/* this needs 9.4M5, can enable this when when the platform requirement is 9.4M5*/
	%else %if &TokenGenMethod=ds2 %then
	%do;
		data _null_;
			header='{"alg":"HS256","typ":"JWT"}';
			payload='{"clientID":"' || strip(symget("DSC_TENANT_ID")) || '"}';
			encHeader=translate(put(strip(header),$base64x64.), "-_ ", "+/=");
			encPayload=translate(put(strip(payload),$base64x64.), "-_ ", "+/=");
			key=put(strip(symget("DSC_SECRET_KEY")),$base64x100.);
			digest=sha256hmachex(strip(key),catx(".",encHeader,encPayload), 0);
			encDigest=translate(put(input(digest,$hex64.),$base64x100.), "-_ ", "+/=");
			token=catx(".", encHeader,encPayload,encDigest);
			call symputx("DSC_AUTH_TOKEN",token);
		run;
	%end;
	%put &DSC_AUTH_TOKEN.;

	/* Create Config tables if not exits */
	%if( &mart_nm.= detail or &mart_nm.= dbtReport or %sysfunc(upcase("&mart_nm.")) eq "CDM") %then
	%do;
		%if %sysfunc(exist(&mart_download_history.)) = 0 %then
		%do;
			data &mart_download_history. &mart_reset_history.;
		    	attrib  dataRangeStartTimeStamp dataRangeEndTimeStamp length=8 format=datetime25.
		            	download_dttm length=8 format=datetime25.6
						datekey length=8. FORMAT=12.
						dataRangeProcessingStatus format=$30.
						reset format=$1.
						resetCompletedTimeStamp length=8. format=datetime25.6
						;
				stop;
			run;
		%end;
	%end;
	/* check for resets if autoreset is enabled */
	%if %lowcase(&autoreset.) = yes %then
	%do;
		%if( &mart_nm.= detail or &mart_nm.= dbtReport or %sysfunc(upcase("&mart_nm.")) eq "CDM") %then
		%do;
			/* run the reset first and then continue with regular download */
			%dsc_reset_mart(reset_day_offset=&reset_day_offset.);
			%if &retcode = 1 %then %goto ERROREXIT;
		%end;
	%end;

	/* set the download url as per the mart_nm
	   detail mart has two types of data partitioned & non partitioned
	*/
	%if &mart_nm.= detail %then
	%do;
		%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%str(&mart_nm./partitionedData)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%nrstr(&includeAllHourStatus=true)%nrstr(&subHourlyDataRangeInMinutes=)&DSC_SUB_HOURLY_MINUTES.%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&CATEGORY.%nrstr(&code=)&CODE.;
	%end;
	%else %if &mart_nm.= dbtReport %then
	%do;
		%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%str(&mart_nm.)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%str(&includeAllHourStatus=true)%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&category.%nrstr(&code=)&CODE.;
	%end;
	%else %if %sysfunc(upcase("&mart_nm.")) eq "CDM" %then
	%do;
		%dsc_download_non_partitioned(mart_nm=detail);
    %let DSC_DOWNLOAD_URL=&DSC_CDM_DOWNLOAD_URL_ORIG%str(detail/partitionedData)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%nrstr(&includeAllHourStatus=true)%nrstr(&subHourlyDataRangeInMinutes=)&DSC_SUB_HOURLY_MINUTES.%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&CATEGORY.%nrstr(&code=)&CODE.;
	%end;
	%else %if &mart_nm.= identity or &mart_nm.=snapshot %then
	%do;
		%if &mart_nm.= identity %then
		%do;
			%put WARNING: mart_nm = identity is going to be deprecated in future , please specify mart_nm = snapshot to download identity tables;
		%end;
		%dsc_download_non_partitioned(mart_nm=detail);
		%goto ERROREXIT;
	%end;
	%else
	%do;
		%put ERROR: Invalid mart name specified for download,please sepcify supported mart names e.g. detail or dbtReport;
		%goto ERROREXIT;
	%end;
	%put &DSC_DOWNLOAD_URL.;

	/* 	if this is the first run then start loading data from the the begining hour in detail_mart
			or from the user defined setting DSC_LOAD_START_DTTM.
		if this is a subsequent run then start loading from previous end_dttm + 1 second.
		if there is no data for the requested range then log errors and stop the program.
	*/
	/* check if this is the first run */
	proc sql noprint;
		select count(*) into :download_hist_cnt from &mart_download_history.;
	quit;

	/* for the first ever run */
	%if &download_hist_cnt eq 0 %then
	%do;
		%let param_start=start=0;
		/* if DSC_LOAD_START_DTTM is set then set start/end timestamp parameters */
		data _null_;
			format dataRangeStartTimeStamp dataRangeEndTimeStamp datetime25.6;
			dataRangeStartTimeStamp ="&DSC_LOAD_START_DTTM."dt;
			dataRangeEndTimeStamp ="&DSC_LOAD_END_DTTM."dt;
			/*dataRangeEndTimeStamp=dataRangeStartTimeStamp + ( &DSC_LOAD_MAX_HOURS * 60 * 60 ) - 1 ;*/
			call symputx('dataRangeStartTimeStamp',put(dataRangeStartTimeStamp,IS8601DT.));
			call symputx('dataRangeEndTimeStamp',put(dataRangeEndTimeStamp,IS8601DT.));
		run;

		/* when its the first run use start=0 */
		%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%nrstr(&start=0);
		/* when DSC_LOAD_START_DTTM is set then use that in download request url */
		%if &DSC_LOAD_START_DTTM ne %then
		%do;
			%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%nrstr(&dataRangeStartTimeStamp=)&dataRangeStartTimeStamp.;
		%end;
		/* when DSC_LOAD_END_DTTM is set then use that in download request url */
		%if &DSC_LOAD_END_DTTM ne %then
		%do;
			%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%nrstr(&dataRangeEndTimeStamp=)&dataRangeEndTimeStamp.;
		%end;
	%end;
	/* for the subsequent run */
	%else
	%do;
		/* get the previous end dttm from download_history*/
		proc sql noprint;
			select max(dataRangeEndTimeStamp) format datetime25. into :prev_dataRangeEndTimeStamp
			from &mart_download_history.
			/*where reset='0' */
		;quit;
		/* set the range parameters */
		data _null_;
			format dataRangeStartTimeStamp dataRangeEndTimeStamp datetime25.;
			dataRangeStartTimeStamp ="&prev_dataRangeEndTimeStamp."dt + 1;
			dataRangeEndTimeStamp ="&DSC_LOAD_END_DTTM."dt;
			call symputx('dataRangeStartTimeStamp',put(dataRangeStartTimeStamp,IS8601DT.));
			call symputx('dataRangeEndTimeStamp',put(dataRangeEndTimeStamp,IS8601DT.));
		run;
		/*set the download api parameters with range time stamps */
		%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%nrstr(&dataRangeStartTimeStamp=)&dataRangeStartTimeStamp.;
		/* when DSC_LOAD_END_DTTM is set then use that in download request url */
		%if &DSC_LOAD_END_DTTM ne %then
		%do;
			%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%nrstr(&dataRangeEndTimeStamp=)&dataRangeEndTimeStamp.;
		%end;
	%end;

	%let NoOfRangesProcessed=0;

%PROCESS_NEXT_PAGE:

	%put INFO: Getting urls..;
	%* Call download api to get the list of urls ;
	%dsc_get_download_urls;
	%if &retcode = 1 %then %goto ERROREXIT;

	%put INFO: Finished getting urls..;

	%* Check the number of url pages to process ;
	proc sql noprint;
		select count as Total_NoOfRanges into :Total_NoOfRanges from urlList_root
	;quit;

	%put INFO: Total Time Ranges to Process: &Total_NoOfRanges.;
	%* get the number of date ranges (hourly batches) to process on the current page ;
	proc sql noprint;
		select count(*) into :NoOfRanges from items ;
	quit;

	%put INFO: Time Ranges to Process on Current Page : &NoOfRanges.;

	%* Process each hour range ;
	%do T = 1 %to %eval(&NoOfRanges.) ;
		%dsc_processrange(range_id=&T,reset=false,mart_nm=&mart_nm.);
		%if &retcode = 1 %then %goto ERROREXIT;
		%let NoOfRangesProcessed=%eval(&NoOfRangesProcessed. + 1);
	%end;

	%put INFO: Finished Processing Current Page;

	%if &Total_NoOfRanges = %eval(&NoOfRangesProcessed) %then
	%do;
		%put INFO: Finished Processing all pages;
	%end;
	%else
	%do;
		%put INFO: Start Processing Next Page;
		%* get the next page url from Links table ;
		data _null_;
      length download_url $1024;
			set links  (where=(rel='next'));
			download_url=symget('DSC_DOWNLOAD_URL');
			auth_token=symget('DSC_AUTH_TOKEN');
			url_domain = kcompress(kscan(download_url,1,':')||'://'|| kscan(download_url,2,'/'));
			/*dsc_download_url=strip(url_domain) || strip(href)|| '&token=' || strip(auth_token);*/
			dsc_download_url=strip(url_domain) || strip(href);
			call symputx('dsc_download_url',dsc_download_url);
		run;
		%goto PROCESS_NEXT_PAGE;
	%end;

%put INFO: End Processing &mart_nm.;

%ERROREXIT:
%mend;
