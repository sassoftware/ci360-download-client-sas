/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_download_non_partitioned(mart_nm=);

	%global retcode;
	%let retcode=0;

 %if %sysfunc(upcase("&category.")) eq "CDM" %then %do;
    %let non_part_download_history=dsccnfg.cdm_nonpar_download_hist;
    %put Start Processing cdm non partitioned ;
  %end;
  %else %do;
	  %let non_part_download_history=&mart_download_history.;
	  %put Start Processing detail non partitioned ;
	%end;

	/* set the download url as per the mart_nm
	  detail mart has two types of data partitioned & non partitioned
	*/
	%if( &mart_nm.= detail or &mart_nm.= dbtReport) %then %do;
	  %let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%str(&mart_nm./nonPartitionedData)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&category.%nrstr(&code=)&CODE.;
  %end;
  %else %if %sysfunc(upcase("&mart_nm.")) eq "CDM" %then %do;
	  %let DSC_DOWNLOAD_URL=&DSC_DOWNLOAD_URL%str(&mart_nm./nonPartitionedData)%nrstr(?agentName=)%str(&DSC_AGENT_NAME.)%nrstr(&schemaVersion=)&DSC_SCHEMA_VERSION.%nrstr(&category=)&category.%nrstr(&code=)&CODE.;
  %end;

	/* Create non part download history tables if not exits */
	%if %sysfunc(exist(&non_part_download_history.)) = 0 %then
	%do;
		data &non_part_download_history.;
    		attrib  entityName format=$200.
					lastModifiedTimestamp download_dttm length=8 format=datetime25.;
			stop;
		run;
	%end;

	%put Getting urls..;
	%* Call download api to get the list of urls ;
	%dsc_get_download_urls(part=0);
	%if &retcode = 1 %then %goto ERROREXIT;

	%put Finished getting urls..;

	%* Check the number of url pages to process & lastModifiedTimestamp timestamp of current data;
	%global lastModifiedTimestamp;
	proc sql noprint;
		select count(*) as Cnt_NonPart_tables ,max(lastModifiedTimestamp) as lastModifiedTimestamp format=datetime25. 	into :Cnt_NonPart_tables ,:lastModifiedTimestamp from Nonpart_details
	;quit;

	proc sql noprint;
		select count(*)as count_identity  into :count_identity
		from  &non_part_download_history.;
	;quit;
	%if &count_identity. > 0 %then
	%do;
		%let prev_lastModifiedTimestamp=;
		proc sql noprint;
			select max(lastModifiedTimestamp)as lastModifiedTimestamp format=datetime25. into :prev_lastModifiedTimestamp
			from  &non_part_download_history.;
		;quit;

		%*file is already downloaded before ?;
		%if &prev_lastModifiedTimestamp. = &lastModifiedTimestamp. %then
		%do;
			/*%put NOTE: IDENTITY TABLES ARE NOT UPDATED YET. SKIPPING DOWNLOAD.;*/
			%put NOTE: SNAPSHOT TABLES ARE NOT UPDATED YET. SKIPPING DOWNLOAD.;
			%goto ERROREXIT;
		%end;
	%end;

	%put Total NonPartition tables to download : &Cnt_NonPart_tables.;

	%* Process each non partitioned table ;
	%do T = 1 %to %eval(&Cnt_NonPart_tables.) ;
		%dsc_processnonpart(url_id=&T);
		%if &retcode = 1 %then %goto ERROREXIT;
	%end;

	%dsc_combine_identity_parts;

%put Download Complete;

%ERROREXIT:
%mend;

%macro dsc_processnonpart(url_id=);

	data _null_;
		set items ;
		call symputx('schemaUrl' ,schemaUrl);
		call symputx('schemaVersion' ,schemaVersion);
		schemaVer=tranwrd(schemaVersion, ".", "_");
		call symputx('schemaVersion' ,schemaVer);
	run;

  /* Make sure detail and cdm schema macros are distinct */
  %if %sysfunc(upcase("&category.")) eq "CDM" %then %do;
    %let schemaName=cdm;
  %end;
  %else %do;
    %let schemaName=&mart_nm;
  %end;

	%* Check if the schema version exists else create it ;
	%dsc_create_attrib(schemaName=&schemaName,schemaVersion=&schemaVersion,schemaUrl=&schemaUrl.);

	%global dsc_schema_macro_nm;
	%let dsc_schema_macro_nm=dsc_&schemaName._v&schemaVersion;

	%dsc_download_file( url_id=&&url_id, file_part_no=&url_id,url_table=nonPart_details);
	%if &retcode. eq 1 %then
	%do;
		%goto ERROREXIT;
	%end;


%ERROREXIT:
%mend;

%macro dsc_combine_identity_parts;

	%let download_dttm=%sysfunc(datetime());
	%put &download_dttm;

	/* Combine all the identity parts downloaded and replace the target identity table */

	%let Entities=;
	proc sql noprint;
		select distinct upcase(entityName) ,entity_cd  into :Entities separated by ',' , :Entitiy_cds separated by ','
		from Nonpart_details ;
	quit;

	%put &sqlobs.;
	%put &Entities.;

    %let entityNum=0;
	%if &Entities  ne %then
	%do;
		%do N = 1 %to %eval(&sqlobs.) ;
			%let entityNum= %eval(&entityNum. + 1);
			%let entity&entityNum= %qscan(%bquote(&Entities.),&entityNum.,%str(,));
			%put &&entity&entityNum.;
			%let current_entity=&&entity&entityNum.;
			%let current_entityNm=&current_entity.;
			%let current_entity=&current_entity._PR;

			/* set current entity cd*/
			%let entity_cd&entityNum= %qscan(%bquote(&Entitiy_cds.),&entityNum.,%str(,));
			%put &&entity_cd&entityNum.;
			%let current_entity_cd=&&entity_cd&entityNum.;
			%let current_entity_cd=&current_entity_cd._PR;

			%*find all part names of the entity ;
			proc sql noprint;
				create table ExtPartList as
				select 'DSCEXTR.' ||  memname as partName
			     from dictionary.tables
			     where upcase(libname) = "DSCEXTR"
				 /*and MEMNAME like "&current_entity%" */
				 and MEMNAME like "&current_entity_cd%"
			;quit;

			data _null_;
				set ExtPartList end=last;
				if _n_ = 1 then
				do;
					call execute( 'data &&entity&entityNum./view=&&entity&entityNum.;');
					call execute( "set ");
				end;
				call execute(partName);
				if last then
				do;
					call execute( ";");
					call execute( "run;	");
				end;
			run;


			%* replace the old entity ;
            %let tbl_nm = &&entity&entityNum.;
			%put &tbl_nm.;

     %if "&tbl_nm." = "IDENTITY_MAP" %then %do;

	    %if %sysfunc(exist(DSCWH.&&entity&entityNum.)) %then %do;
             proc sql noprint;
                 create table update_records as
					  select * from &&entity&entityNum. as a inner join
					                 DSCWH.&&entity&entityNum. as b
					  on a.source_identity_id = b.source_identity_id
                      and a.processed_dttm ne b.processed_dttm;
             quit;

		     /*data insert_records;
                   merge DSCWH.&&entity&entityNum. (in=a) &&entity&entityNum.(in=b);
                   by source_identity_id;
                   if b and not a;
             run;*/

			 proc sql noprint;
                create table insert_records as
                select * from &&entity&entityNum. where source_identity_id not in  ( select source_identity_id from DSCWH.&&entity&entityNum. );
             quit;


		     data recrds_tbl;
             set insert_records update_records;
             run;


			 proc sql noprint;
		             select count(*) into :rcd_cnt
		             from  recrds_tbl;
	         quit;

			 %put &rcd_cnt.;
			 %if %sysevalf(&rcd_cnt. > 0) %then %do;
                  data DSCWH.&&entity&entityNum.;
    			          modify DSCWH.&&entity&entityNum. recrds_tbl ;
    			          by source_identity_id;
    			          select(_IORC_);
        			      when (%SYSRC(_SOK))
        			      do;
            			    replace;
        			      end;
        			      when (%SYSRC(_DSENMR))
        			      do;
            			   _error_= 0;
            			    output;
        			      end;
			              otherwise
        			      do;
            			    stop;
        			     end;
    			         end;
			        run;

			     proc sql noprint;
			       drop table insert_records ;
                 quit;
                 proc sql noprint;
                    drop table update_records;
			      quit;
                 proc sql noprint;
			       drop table recrds_tbl;
		         quit;
			 %end;
			 %else %do;
                  %put "No new records to be inserted and updated";
			 %end;

		%end;
		%else %do;
            data DSCWH.&&entity&entityNum.;
			set &&entity&entityNum. ;
			run;

		%end;

	 %end;
	 %else %do;
        data DSCWH.&&entity&entityNum.;
				set &&entity&entityNum. ;
		run;

     %end;


			data identity_hist;
				attrib  entityName format=$200. lastModifiedTimestamp download_dttm length=8 format=datetime25.;
				entityName="&&entity&entityNum.";
				download_dttm=&download_dttm.;
				lastModifiedTimestamp="&lastModifiedTimestamp."dt;
			run;

			%* update history table ;
			data &non_part_download_history.;
    			modify &non_part_download_history. identity_hist ;
    			by entityName;
    			select(_IORC_);
        			when (%SYSRC(_SOK))
        			do;
            			replace;
        			end;
        			when (%SYSRC(_DSENMR))
        			do;
            			_error_= 0;
            			output;
        			end;
			        otherwise
        			do;
            			stop;
        			end;
    			end;
			run;

		 %* convert space separated table names into comma separated table names ;
			data _null_;
				set ExtPartList end=last;
				if _n_ = 1 then
				do;
					call execute( "proc sql noprint;");
				end;
				call execute("drop table " || partName || ";");
				if last then
				do;
					call execute( ";quit;	");
				end;
			run;

			proc sql noprint;
				drop table ExtPartList;
			quit;

		%end;
	%end;

%mend;
