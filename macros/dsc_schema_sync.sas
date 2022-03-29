/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_schema_sync;

	/* 	dynamic schema sync 
	 	if the table already exists in the target library , 
		then check if there are any new columns in the new schema 
		and if so generate the alter table statements and execute them
	*/

	/* add datekey to all detail & dbt-report tables except identity (non-partitioned table) */
	proc sql;
		create table schema_details_datekey as
			select 	table_name
					,column_name
					,column_label
					,column_sequence 
					,data_type
					,data_length
					,column_type
			from 	schema_details
			/* addition of datekey was required while updating client macros from version 1 to version 3
			assuming by now it's already version 3 -datekey addition is not required. 
			commenting the following */
			/*
			union all
			select 	table_name
					,'datekey' as column_name
					,'datekey' as column_label
					,999 as column_sequence 
					,'int' as data_type
					,'' as data_length
					,'int(12)' as column_type
			from 	schema_table_names
			where	table_name not like 'identity%'
			*/
			order by table_name, column_sequence
	;quit;

	%let libnm=DSCWH;
	
	/* create a list of new columns */
	proc sql;
		create table schema_changes as
		select s1.* 
		from schema_details_datekey s1
		/* select only those tables which are already created in DSCWH */
		inner join 
		(
			select distinct lowcase(memname) as table_name
			from dictionary.columns 
			where libname ="&libnm."
		)s3
		on lowcase(s1.table_name)=s3.table_name
		/* select columns which are new in schema */
		left join 
			(
			select distinct lowcase(memname) as table_name, lowcase(name) as column_name
			from dictionary.columns 
			where libname ="&libnm." 
			)s2
		on 	lowcase(s1.table_name)=s2.table_name
		and lowcase(s1.column_name)=s2.column_name
		
		where s2.column_name is null 
		order by s1.table_name ,s1.column_sequence
	;quit;
	
	proc sql noprint;
		select count(*) into :schema_change_cnt	from schema_changes;
	quit;

	%if &schema_change_cnt. = 0 %then 
	%do;
		%put INFO: No new columns found in the schema;
	%end;
	%else
	%do;
		%put INFO: New columns found in the schema;
		%put INFO: Start updating schema chages;
		/* create alter table statements for the new columns and execute them */
		data _null_ ;
			default_datatype='char(4000)';
			map_datatype_default='char(4000)';
		    set schema_changes end=eof;
			libnm=symget('libnm');
		    if _n_ = 1 then  call execute( 'proc sql ; ');

		    /* char varchar type */
		    if( data_type= 'varchar' or data_type= 'char' )then 
		        call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) || ' add ' || strip(column_name) || ' char(' || strip(data_length) || ') FORMAT=$' || strip(data_length) || '. ;' );
		    /* date time type */
		    else if data_type='timestamp' then
		        call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) || ' add ' || strip(column_name) || ' num FORMAT=DATETIME27.6 INFORMAT=ymddttm. ;');
			/* date type */
			else if data_type='date' then
				call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) || ' add ' || strip(column_name) || ' num FORMAT=DATE10. INFORMAT=yymmdd. ;');
		    /* numeric type */
		    else if (data_type='smallint' or data_type='int' or data_type='bigint' or data_type='decimal') then
			do;
				/* extract the numeric precision from the column type e.g if column type is decimal(13,6) then return 13.6 */
				numFormat='NLNUM' || compress(tranwrd(column_type,',','.'),'.','kd');
				/* check if the numformat has . in the end else append . */
				/* as NUM formats max is 32.2 .. this step will fail for formats more than 32 ...not formatting the nos for now 
				if index(numFormat,'.')  > 0 then put @ident2 column_name 'LENGTH=8. FORMAT=' numFormat ;
				else put @ident2 column_name 'LENGTH=8. FORMAT=' numFormat +(-1) '.';*/
				if index(numFormat,'.')  > 0 then call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) ||' add ' || strip(column_name) || ' num ;' );
				else call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) || ' add ' || strip(column_name) || ' num ;') ;
			end;
			/* map type - defaults*/
			else if( data_type = 'map' )then
				call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) || ' add ' || strip(column_name) || ' ' || strip(map_datatype_default) || ';' );
		    else
		        call execute( 'alter table ' || strip(libnm) || '.' || strip(table_name) || ' add ' || strip(column_name) || ' ' || strip(default_datatype) || ';' );

			if eof then call execute('quit ;');
		run;
	%end;

    %if &SYSERR. > 4 %then 
    %do;
       	%put &SYSERRORTEXT. ;
		%let retcode=1; 
		%put ERROR: Error in updating schema changes;
   	%end;

	%put INFO: Finish updating schema chages;

%ERROREXIT:
%mend;
