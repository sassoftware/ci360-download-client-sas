/*-----------------------------------------------------------------------------
 Copyright � 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_processrange(range_id=,reset=,mart_nm=,reset_completed=);

	data download_history;
		attrib	reset format=$1.
				resetCompletedTimeStamp length=8. format=datetime25.6
				download_dttm format=datetime25.6
				dataRangeProcessingStatus format=$30.
				;
		set items (where = (ordinal_items= &range_id.));
		download_dttm=datetime();
		keep dataRangeStartTimeStamp dataRangeEndTimeStamp download_dttm dataRangeProcessingStatus datekey reset resetCompletedTimeStamp;
		schemaUrl2='%nrstr('||strip(schemaUrl)||')';
		call symputx('schemaUrl' ,schemaUrl2);

		schemaVer=tranwrd(schemaVersion, ".", "_");
		call symputx('schemaVersion' ,schemaVer);

		call symputx('dataRangeProcessingStatus' ,dataRangeProcessingStatus);
		call symput('dataRangeStartTimeStamp' ,dataRangeStartTimeStamp);
		call symput('dataRangeEndTimeStamp' ,dataRangeEndTimeStamp);

		range_start=put(dataRangeStartTimeStamp,datetime25.6);
		range_end=put(dataRangeEndTimeStamp,datetime25.6);
		call symput('range_start',range_start);
		call symput('range_end',range_end);
		call symput('datekey',datekey);

		reset_flag=symget('reset');
		reset_completed=symget('reset_completed');
		if reset_flag = 'true' then
		do;
			reset='1';
			resetCompletedTimeStamp=input(reset_completed,datetime25.6);
		end;
		else
		do;
			reset='0';
		end;
	run;

	%put INFO: Downloading range_id :&range_id. from &range_start. to &range_end.;

	%if &reset. = true %then
	%do;
		%put INFO: Reset Mode: Checking if datekey=&datekey. is downloaded earlier ;
		proc sql noprint;
			select 	count(*) as prev_download into :prev_download
			from 	&mart_download_history.
			where 	datekey=input("&datekey.",12.)
			and 	reset='0'
		;quit;

		%if &prev_download. = 0 %then
		%do;
			%put INFO: Reset Mode: Data for datekey=&datekey. is not downloaded earlier, Skipping Reset;
			%goto SKIPRANGE ;
		%end;

		%put INFO: Reset Mode: Checking if datekey=&datekey. is reseted earlier ;
		%let prev_resetCompletedTimeStamp=;
		%let prev_reset=0;
		proc sql noprint;
			select 	max(resetCompletedTimeStamp) as resetCompletedTimeStamp format=datetime25.6
					,count(*) as prev_reset
				into :prev_resetCompletedTimeStamp
					,:prev_reset
			from 	&mart_download_history.
			where 	datekey=input("&datekey.",12.)
			and 	reset='1'
		;quit;

		%if &prev_reset. > 0 %then
		%do;
			%if &prev_resetCompletedTimeStamp. = &RESET_COMPLETED. %then
			%do;
				%put INFO: Reset Mode: Reset Data for datekey=&datekey. with resetCompletedTimeStamp=&RESET_COMPLETED. is already downloaded, Skipping Reset;
				%goto SKIPRANGE ;
			%end;
		%end;

		%put INFO: Reset Mode: Deleting records for datekey=&datekey.;
		%dsc_reset_records(datekey=&datekey.);
		%if &retcode = 1 %then %goto ERROREXIT;
	%end;

	/* when there is NO_DATA in the range just append range in download_history */
	%if (&dataRangeProcessingStatus. = NO_DATA or &dataRangeProcessingStatus. = ERROR or &dataRangeProcessingStatus. = RESET_INPROGRESS )%then
	%do;
		proc append base=&mart_download_history. data=work.download_history force;
		run;
		%put INFO: Date range &range_start. to &range_end. dataRangeProcessingStatus:&dataRangeProcessingStatus.;
		%put INFO:	Skipping this range ;
		%goto SKIPRANGE ;
	%end;

  /* Make sure detail and cdm schema macros are distinct */
  %if %sysfunc(upcase("&category.")) eq "CDM" %then %do;
    %let schemaName=cdm;
  %end;
  %else %do;
    %let schemaName=&mart_nm;
  %end;

	%* Check if the schema version exists else create it ;
	%dsc_create_attrib(schemaName=&schemaName,schemaVersion=&schemaVersion,schemaUrl=&schemaUrl.);

	%if &retcode=1 %then
	%do;
		%goto ERROREXIT;
	%end;


	%global dsc_schema_macro_nm;
	%let dsc_schema_macro_nm=dsc_&schemaName._v&schemaVersion;

	%*loop through all entities in the range , download each url file and create sas dataset ;
	filename filelst temp ;
	data _null_ ;
		file filelst ;
		length file_part_no 8.;
		retain file_part_no 0;;
		set Download_details (where = (range_id= &range_id.));
		by range_id entityName ;
		file_part_no=sum(file_part_no + 1);
		/* when only 1 part file */
		if first.entityName =1 and last.entityName = 1 then
		do;
			put '%dsc_download_file( url_id='  url_id ', file_part_no=' file_part_no ', datekey=' datekey ');' ;
			file_part_no=0;
		end;
		/* when not the firt or last part */
		else if last.entityName = 0 then
		do;
			put '%dsc_download_file( url_id='  url_id ', file_part_no=' file_part_no ', datekey=' datekey ');' ;
		end;
		/* when the last part */
		else if last.entityName = 1 then
		do;
			put '%dsc_download_file( url_id='  url_id ', file_part_no=' file_part_no ', datekey=' datekey ');' ;
			file_part_no=0;
		end;
	run;
	%include filelst;
	filename filelst clear;
	%put INFO: Finished Downloading files for range_id:&range_id.;

	%if &retcode = 1 %then %goto ERROREXIT;
	%dsc_appendtocustomerdb(range_id=&T);

%ERROREXIT:
%SKIPRANGE:
%mend;
