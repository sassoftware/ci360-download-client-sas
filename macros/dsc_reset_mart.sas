/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_reset_mart(reset_day_offset=);
	%put INFO: starting reset process;

	/* reset setps 
		* get the reset urls , the response will return the download urls 
		* check if the data returned by reset is already downloaded , if not exit
		* check if the data is previously reseted , 		
		* remove downloaed data and then download new from reset urls
	*/
	
	/* get the list of mart tables */
	%let tblstfile=&UtilityLocation./data/dsccnfg/&mart_nm._table_list.txt;
	filename tblist "&tblstfile";

	data table_list;
		infile tblist length=reclen ; 
		input table_nm $varying999. reclen;
	run;

	proc sql noprint;
		select count(table_nm) into :Count_Mart_tables from table_list ;
	quit;

	proc sql noprint;
		select table_nm into :Table_Nm1 - :Table_Nm%left(&Count_Mart_tables.) from table_list ;	
	;quit;

	%if &mart_nm.= detail %then
	%do;
		%let DSC_RESET_URL=&DSC_DOWNLOAD_URL%str(partitionedData/resets)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%nrstr(&martType=)%str(&mart_nm.)%nrstr(&dayOffset=)%str(&reset_day_offset.);	
	%end;
	%else %if &mart_nm.= dbtReport %then
	%do;
		%let DSC_RESET_URL=&DSC_DOWNLOAD_URL%str(partitionedData/resets)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%nrstr(&martType=dbt-report)%nrstr(&dayOffset=)%str(&reset_day_offset.);
	%end;
	%else
	%do;
		%put ERROR: Invalid mart name specified for reset;
		%goto ERROREXIT;
	%end;

	%let NoOfResetRangesProcessed=0;

	data _null_;
		download_url_orig=symget('DSC_DOWNLOAD_URL');
		call symputx('download_url_orig',download_url_orig);
	run;
	

%NEXT_RESET_PAGE:

	%put INFO: Getting reset urls..;
	%* Call api to get the list of reset urls ;
	%dsc_get_reset_urls();
	%if &retcode = 1 %then %goto ERROREXIT;
	%if &retcode=2 %then 
	%do;
		%let retcode = 0; 
		%goto ERROREXIT;
	%end;
	%put INFO: Finished getting reset urls.;

	%* Check the number of reset pages to process ;
	proc sql noprint;
		select count as Total_NoOfResetRanges into :Total_NoOfResetRanges from Reset_root
	;quit;

	%put INFO: Total Reset Ranges : &Total_NoOfResetRanges.;	

	%* get the number of reset ranges on current page ;
	proc sql noprint;
		select count(*) into :NoOfResetRanges from Reset_details ;
	quit;

	%put INFO: Reset Ranges on current page : &NoOfResetRanges.;

	%let CurrentResetRange=1;

%NEXT_RESET_RANGE:
	/* form download url and get the urls from it*/
	data _null_;
		set Reset_details  (where=(range_id=&CurrentResetRange.));
		download_url_orig=symget('download_url_orig');
		url_domain = kcompress(kscan(download_url_orig,1,':')||'://'|| kscan(download_url_orig,2,'/'));
		dsc_download_url=strip(url_domain) || strip(downloadUrl);
		call symputx('dsc_download_url',dsc_download_url);
		reset_start=put(dataRangeStartTimeStamp,datetime25.6);
		reset_end=put(dataRangeEndTimeStamp,datetime25.6);
		reset_completed=put(resetCompletedTimeStamp,datetime25.6);
		call symput('reset_start',reset_start);
		call symput('reset_end',reset_end);
		call symput('reset_completed',reset_completed);
	run;

	%if &mart_nm.= detail %then
	%do;
		%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%nrstr(&includeAllHourStatus=true)%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&CATEGORY.%nrstr(&code=)&CODE.;
	%end;
	%else %if &mart_nm.= dbtReport %then
	%do;
		%let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%str(&includeAllHourStatus=true)%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&CATEGORY.%nrstr(&code=)&CODE.;
	%end;

	%put INFO: Starting reset for range &CurrentResetRange. &reset_start. &reset_end;

	%let NoOfRangesProcessed=0;

%NEXT_DOWNLOAD_RANGE:
	/* get the download urls for current reset range */
	%dsc_get_download_urls;
	%if &retcode = 1 %then %goto ERROREXIT;
	
	%put INFO: Finished getting urls for reset range &reset_start. &reset_end;

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
		%dsc_processrange(range_id=&T,reset=true,mart_nm=&mart_nm.,reset_completed=&reset_completed.);
		%if &retcode = 1 %then %goto ERROREXIT;
		%let NoOfRangesProcessed=%eval(&NoOfRangesProcessed. + 1);	
	%end;

	%put INFO: Finished Downloading Current Page;

	%if &Total_NoOfRanges = %eval(&NoOfRangesProcessed) %then
	%do;
		%put INFO: Finished reset for range &CurrentResetRange. &reset_start. &reset_end;

		%let NoOfResetRangesProcessed=%eval(&NoOfResetRangesProcessed. + 1);

		/* check if all reset pages are done */
		%if &Total_NoOfResetRanges = %eval(&NoOfResetRangesProcessed) %then
		%do;
			%put INFO: Finished Processing all reset ranges;
		%end;		
		/* reset download_url_orig on complettion of all reset ranges on current reset (CurrentResetRange) page instead of NoOfResetRangesProcessed */
		%else %if &CurrentResetRange. = &NoOfResetRanges. %then
		%do;
			%put INFO: Getting Next Reset Url from RESET_LINKS;
			/*this means the reset ranges on the current page are done but as the first condition was false there are more pages to reset */			
			/*set the next RESET download URL */
			data _null_;
				set Reset_links  (where=(rel='next'));
				download_url_orig=symget('DSC_DOWNLOAD_URL');
				url_domain = kcompress(kscan(download_url_orig,1,':')||'://'|| kscan(download_url_orig,2,'/'));
				DSC_RESET_URL=strip(url_domain) || strip(uri);
				call symputx('DSC_RESET_URL',DSC_RESET_URL);
			run;

			/* drop work reset tables */
			proc sql ;
				drop table Reset_root ;
				drop table Reset_links ;
				drop table Reset_items ;
				drop table Reset_details ;
			quit;

			%goto NEXT_RESET_PAGE;
		%end;
		%else
		%do;
			/*increment the resetRange counter*/
			%let CurrentResetRange=%eval(&CurrentResetRange. + 1);
			%goto NEXT_RESET_RANGE;
		%end;		
	%end;
	%else
	%do;
		%put INFO: Start Processing Next Page;
		%* get the next page url from Links table ;
		data _null_;
			set links  (where=(rel='next'));
			download_url=symget('DSC_DOWNLOAD_URL');
			auth_token=symget('DSC_AUTH_TOKEN');
			url_domain = kcompress(kscan(download_url,1,':')||'://'|| kscan(download_url,2,'/'));
			/*dsc_download_url=strip(url_domain) || strip(href)|| '&token=' || strip(auth_token);*/
			dsc_download_url=strip(url_domain) || strip(href);
			call symputx('dsc_download_url',dsc_download_url);
		run;
		%goto NEXT_DOWNLOAD_RANGE;
	%end;


data _null_;
	download_url=symget('download_url_orig');
	call symputx('DSC_DOWNLOAD_URL',download_url);
run;

%ERROREXIT:
%mend;
