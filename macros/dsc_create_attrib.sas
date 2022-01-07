/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_create_attrib(schemaName=,schemaVersion=,schemaUrl=);

  	%* Check if the schema version exists else create it ;
	%let schemaName=%lowcase(&schemaName.);
	%let schemaFile=&UtilityLocation./macros/dsc_&schemaName._v&schemaVersion..sas;

	%if %sysfunc(fileexist("&schemaFile")) %then 
	%do; 
		%put &schemaName. schema version &schemaVersion. already exists;
		%goto EXIT;
	%end;

	%put Creating &schemaName. schema version &schemaVersion. ;

	%dsc_get_schema(schemaUrl=&schemaUrl);
	
	%if &retcode=1 %then 
	%do;
		%goto EXIT;
	%end;

	proc sort data=schema_details ; by table_name column_sequence; run;

    proc sql noprint ;
        create view schema_Table_names as
        select distinct table_name from schema_details;
    quit;

	/* write the list of tables to file - this file is used in reset mode */
	%let tblstfile=&UtilityLocation./data/dsccnfg/&schemaName._table_list.txt;
	filename tblist "&tblstfile";

	data _null_ ;
		file tblist;
		set schema_Table_names ;
		put table_name ;
	run;

    proc sql noprint ;
        select distinct table_name into :Table_List separated by ',' from schema_details;
    quit;    

	filename dmschema "&schemaFile";
	%let TableCount=&sqlobs. ;	
    %let TblNum=0;

    %do TN=1 %to %eval(&TableCount.) ;
        %let TblNum= %eval(&TblNum. + 1);
    	%let Tbl&TblNum= %qscan(%bquote(&Table_List.),&TblNum.,%str(,));
    	%put &&Tbl&TblNum;
        /* write the if table_nm = condition in the file */
        data _null_;
            file dmschema mod;
            ident0=4;
			martNm=symget('schemaName');
			verNo=symget('schemaVersion');
            set schema_Table_names (where=(table_name="&&Tbl&TblNum"));
            %if &TblNum.=1 %then 
            %do;
				put '%macro dsc_' martNm +(-1) '_v' verNo +(-1)'(tbl_nm=);';
                put @ident0 '%if &tbl_nm = ' table_name ' %then';
                put @ident0 '%do;';
            %end;
            %else
            %do;
                put @ident0 '%else %if &tbl_nm = ' table_name ' %then';
                put @ident0 '%do;';
            %end; 
        run;
        /* write the attrib statement for the table */
        data _null_;
            file dmschema mod;
            default_datatype='FORMAT=$4000.';
			map_datatype_default='FORMAT=$4000.';
            ident1=8;
            ident2=12;
            set schema_details (where=(table_name="&&Tbl&TblNum")) end=eof;
            if _n_ = 1 then  put @ident1 'attrib ';

            /* char varchar type */
            if( data_type= 'varchar' or data_type= 'char' )then 
                put @ident2 column_name 'FORMAT=$' data_length +(-1) '.';
            /* date time type */
            else if data_type='timestamp' then
                put @ident2 column_name 'LENGTH=8 FORMAT=DATETIME27.6 INFORMAT=ymddttm.';
			/* date type */
			else if data_type='date' then
    			put @ident2 column_name 'LENGTH=8 FORMAT=DATE10. INFORMAT=yymmdd.';
            /* numeric type */
            else if (data_type='smallint' or data_type='tinyint' or data_type='int' or data_type='bigint' or data_type='decimal') then
			do;
				/*extract the numeric precision from the column type e.g if column type is decimal(13,6) then return 13.6*/
				numFormat='NLNUM' || compress(tranwrd(column_type,',','.'),'.','kd');
				/* check if the numformat has . in the end else append . */
				/* as NUM formats max is 32.2 .. this step will fail for formats more than 32 ...not formatting the nos for now 
				if index(numFormat,'.')  > 0 then put @ident2 column_name 'LENGTH=8. FORMAT=' numFormat ;
				else put @ident2 column_name 'LENGTH=8. FORMAT=' numFormat +(-1) '.';*/
				if index(numFormat,'.')  > 0 then put @ident2 column_name 'LENGTH=8.' ;
				else put @ident2 column_name 'LENGTH=8.' ;
			end;
			/* with schema 4 there are columns with 'MAP' data type , as there is no equivalent data type in SAS Data set , create it as 4000 Char 
			if you expect more data in map column , increase the length accordingly */
            else if( data_type = 'map' ) then
                put @ident2 column_name map_datatype_default ;
            else
                put @ident2 column_name default_datatype ;

            if eof then put @ident2 ';';
        run;

        /* write the input statement for the table */
        data _null_;
            file dmschema mod;
            ident1=8;
            ident2=12;
            set schema_details (where=(table_name="&&Tbl&TblNum")) end=eof;
            if _n_ = 1 then  put @ident1 'input ';

            put @ident2 column_name ;

            if eof then put @ident2 ';';
        run;

        /* write the end of the if condition in the file */
        data _null_;
            file dmschema mod;
            ident0=4;
            set schema_Table_names (where=(table_name="&&Tbl&TblNum"));
            put @ident0 '%end;';
            %if &TblNum.= &TableCount. %then 
            %do;
                put '%mend ;';
            %end;
        run;
    %end;
    filename dmschema;

	/* check if there are any changes in the schema for previously created dscwh tables */
	%dsc_schema_sync;

%EXIT:
%mend;
