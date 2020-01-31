/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_version_update(version_num=);
/* while moving to new version if you need to update existing tables
write version specific changes here */
	%if &version_num. = 3 %then
	%do;
		/*if version hist does not exists, then version 3 updates are required */
		%if %sysfunc(exist(dsccnfg.dsc_version_hist)) = 0 %then
		%do;

			%* step#2 add new columns in dsccnfg.Detail_download_history ;
			%let detail_download_history=dsccnfg.Detail_download_history;
			%if %sysfunc(exist(&detail_download_history.)) %then
			%do;
				data &detail_download_history._bkp;
					set &detail_download_history;
				run;	
				proc sql;
					alter table &detail_download_history. add datekey num FORMAT=12.;
					alter table &detail_download_history. add dataRangeProcessingStatus char(30) FORMAT=$30.;
					alter table &detail_download_history. add reset char(1) FORMAT=$1.;
					alter table &detail_download_history. add resetCompletedTimeStamp num FORMAT=datetime25.6;
					update &detail_download_history. set dataRangeProcessingStatus='DATA_AVAILABLE' , reset='0';
				;quit;
				data dsccnfg.Detail_reset_history;
					set &detail_download_history(obs=0);
				run;
			%end;
			%if &SYSERR. > 4 %then 
    		%do;
				%put ERROR: Error in applying alters to &detail_download_history.;
				%put ERROR: Error in applying version 3 updates.;
				%let retcode=1 ;
				%goto EXIT;
			%end;

			%* add new columns in dsccnfg.Dbtreport_download_history ;
			%let Dbtreport_download_history=dsccnfg.Dbtreport_download_history;
			%if %sysfunc(exist(&Dbtreport_download_history.)) %then
			%do;
				data &Dbtreport_download_history._bkp;
					set &Dbtreport_download_history.;
				run;
				proc sql;
					alter table &Dbtreport_download_history. add datekey num FORMAT=12.;
					alter table &Dbtreport_download_history. add dataRangeProcessingStatus char(30) FORMAT=$30.;
					alter table &Dbtreport_download_history. add reset char(1) FORMAT=$1.;
					alter table &Dbtreport_download_history. add resetCompletedTimeStamp num FORMAT=datetime25.6;
					update &Dbtreport_download_history. set dataRangeProcessingStatus='DATA_AVAILABLE' , reset='0';
				;quit;
				data dsccnfg.Dbtreport_reset_history;
					set &Dbtreport_download_history(obs=0);
				run;
				%if &SYSERR. > 4 %then 
	    		%do;
					%put ERROR: Error in applying alters to &Dbtreport_download_history.;
					%put ERROR: Error in applying version 3 updates.;
					%let retcode=1 ;
					%goto EXIT;
				%end;
			%end;

			%* modify "dscwh.session_details" "session_dt" column from char to date data type if it is not already date type ;
			%let session_details=dscwh.session_details ;
			%if %sysfunc(exist(&session_details.)) %then
			%do;
				data &session_details._bkp;
					set &session_details.;
				run;
				data &session_details.;
					set &session_details. (rename=(session_dt=session_dt_str));
					attrib session_dt LENGTH=8 FORMAT=DATE10. INFORMAT=yymmdd. ;
					session_dt=input(session_dt_str,yymmdd10.);
					drop session_dt_str;
				run;
				%if &SYSERR. > 4 %then 
	    		%do;
					%put ERROR: Error in applying changes to &session_details.;
					%put ERROR: Error in applying version 3 updates.;
					%let retcode=1 ;
					%goto EXIT;
				%end;
			%end;
			%* modify "dscwh.page_details" "session_dt" column from char to date data type if it is not already date type ;
			%let page_details=dscwh.page_details ;
			%if %sysfunc(exist(&page_details.)) %then
			%do;
				data &page_details._bkp;
					set &page_details.;
				run;
				data &page_details.;
					set &page_details. (rename=(session_dt=session_dt_str));
					attrib 	session_dt LENGTH=8 FORMAT=DATE10. INFORMAT=yymmdd. ;
					session_dt=input(session_dt_str,yymmdd10.);
					drop session_dt_str;
				run;
				%if &SYSERR. > 4 %then 
	    		%do;
					%put ERROR: Error in applying changes to &page_details.;
					%put ERROR: Error in applying version 3 updates.;
					%let retcode=1 ;
					%goto EXIT;
				%end;
			%end;

			%* modify "dscwh.dbt_goals" "goals" column from char to numeric data type if it is not already numeric type ;
			%let dbt_goals=dscwh.dbt_goals ;
			%if %sysfunc(exist(&dbt_goals.)) %then
			%do;
				data &dbt_goals._bkp;
					set &dbt_goals.;
				run;
				data &dbt_goals.;
					set &dbt_goals.(rename=(goals=goals_str));
					attrib 	goals LENGTH=8. ;
					goals=input(goals_str,$20.);
					drop goals_str;
				run;
				%if &SYSERR. > 4 %then 
	    		%do;
					%put ERROR: Error in applying changes to &dbt_goals.;
					%put ERROR: Error in applying version 3 updates.;
					%let retcode=1 ;
					%goto EXIT;
				%end;
			%end;

			%* modify "dscwh.dbt_media_consumption" "media_section_view,views,views_completed,views_started" column from char to numeric data type if it is not already numeric type ;
			%let dbt_media_consumption=dscwh.dbt_media_consumption;
			%if %sysfunc(exist(&dbt_goals.)) %then
			%do;
				data &dbt_media_consumption._bkp;
					set &dbt_media_consumption;
				run;
				data &dbt_media_consumption. ;
					set &dbt_media_consumption.(rename=(media_section_view=media_section_view_str views=views_str views_completed=views_completed_str views_started=views_started_str));
					attrib 	media_section_view views views_completed views_started LENGTH=8. ;
					media_section_view=input(media_section_view_str,$20.);
					views=input(views_str,$20.);
					views_completed=input(views_completed_str,$20.);
					views_started=input(views_started_str,$20.);

					drop media_section_view_str views_str views_completed_str views_started_str;
				run;
				%if &SYSERR. > 4 %then 
	    		%do;
					%put ERROR: Error in applying changes to &dbt_media_consumption.;
					%put ERROR: Error in applying version 3 updates.;
					%let retcode=1 ;
					%goto EXIT;
				%end;
			%end;

			%let Business_process_details_ext=dscwh.business_process_details_ext;
			%if %sysfunc(exist(&Business_process_details_ext.)) %then
			%do;
				proc sql;
					drop table &Business_process_details_ext.;
				quit;
			%end;
			%let cart_activity_details_ext=dscwh.cart_activity_details_ext;
			%if %sysfunc(exist(&cart_activity_details_ext.)) %then
			%do;
				proc sql;
					drop table &cart_activity_details_ext.;
				quit;
			%end;
			%let goal_details_ext=dscwh.goal_details_ext;
			%if %sysfunc(exist(&goal_details_ext.)) %then
			%do;
				proc sql;
					drop table &goal_details_ext.;
				quit;
			%end;
			%let search_results_ext=dscwh.search_results_ext;
			%if %sysfunc(exist(&search_results_ext.)) %then
			%do;
				proc sql;
					drop table &search_results_ext.;
				quit;
			%end;
			%let media_activity_details=dscwh.media_activity_details;
			%if %sysfunc(exist(&media_activity_details.)) %then
			%do;
				proc sql;
					drop table &media_activity_details.;
				quit;
			%end;			

			data dsc_version_hist;
				attrib 	ver_num length= 8.
						ver_create_dttm length=8. format=datetime25.6;					
					ver_num =3;
					ver_create_dttm =datetime();
			run;			
			proc append base=dsccnfg.dsc_version_hist data=dsc_version_hist;
			run;
		%end;
		%else
		%do;
			%put Download client version = &version_num.;
		%end;
	%end;/* version_num. = 3 */

	%if &version_num. = 4 %then
	%do;
		%let ver_hist_ds=dsccnfg.dsc_version_hist;
		*check if version hist ds exists;
		%if %sysfunc(exist(&ver_hist_ds.)) %then
		%do;
			*what is the version num ;
			proc sql noprint;
				select max(ver_num) into :dsc_ver_num from &ver_hist_ds. ;
			quit;
			%if &dsc_ver_num. = 3 %then
			%do;
				*if dsc_ver_num is 3 then do one time delete of dsc_dbtreport_v3_0.sas file ;
				*as the schema is updated post release to add new table ;
				%let schemaFile=&UtilityLocation./macros/dsc_dbtreport_v3_0.sas;
				data test;
				    fname="tempfile";
				    rc=filename(fname,"&schemaFile.");
				    if rc = 0 and fexist(fname) then
				       rc=fdelete(fname);
				    rc=filename(fname);
				run;

				*create version hist ds with version 4;
				data dsc_version_hist;
					attrib 	ver_num length= 8.
						ver_create_dttm length=8. format=datetime25.6;					
						ver_num =4;
						ver_create_dttm =datetime();
				run;
				proc append base=dsccnfg.dsc_version_hist data=dsc_version_hist;
				run;
			%end;
		%end;
		%else
		%do;
			*create version hist ds with version 4;
			data dsc_version_hist;
				attrib 	ver_num length= 8.
					ver_create_dttm length=8. format=datetime25.6;					
					ver_num =4;
					ver_create_dttm =datetime();
			run;			
			proc append base=dsccnfg.dsc_version_hist data=dsc_version_hist;
			run;
		%end;
	%end;
%EXIT:	
%mend;
