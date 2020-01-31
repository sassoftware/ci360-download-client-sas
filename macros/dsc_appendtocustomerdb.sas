/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_appendtocustomerdb(range_id=);
	
	/* Combine all the parts downloaded in one range and append it to the target table */
	%let Entities=;
	proc sql noprint;
		select distinct entityName ,entity_cd  into :Entities separated by ',' , :Entitiy_cds separated by ','
		from Download_details 
		where range_id= &range_id.;
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
			%let current_entity=&current_entity._PR;

			/* set current entity cd*/
			%let entity_cd&entityNum= %qscan(%bquote(&Entitiy_cds.),&entityNum.,%str(,));
			%put &&entity_cd&entityNum.;
			%let current_entity_cd=&&entity_cd&entityNum.;
			%let current_entity_cd=&current_entity_cd._PR;

			/* */ 
			proc sql noprint;
				select 'DSCEXTR.' ||  memname into :TableParts separated by ' ' 
		         from dictionary.tables 
		         where upcase(libname) = "DSCEXTR" 
		               /*and MEMNAME like "&&entity&entityNum.%" */
					   /* and MEMNAME like "&current_entity%" */
				 		and MEMNAME like "&current_entity_cd%" 
			;quit;

			data &&entity&entityNum./view=&&entity&entityNum.;
				set &TableParts.;
			run;

			proc append base=DSCWH.&&entity&entityNum. data=&&entity&entityNum. force;
			run;

		%end;	
	%end;

	/* append the data to download_history table */
	proc append base=&mart_download_history. data=work.download_history force;
	run;

	/* append the data to reset_history table */
	proc append base=&mart_reset_history. data=work.download_history (where= (reset='1')) force;
	run;


	/* clean up DSCEXTR library.
	if the two marts run in parallel then this needs to be modified / removed as it can delete data for other mart */
	proc datasets lib=DSCEXTR kill noprint;
    quit;
	
%mend;
