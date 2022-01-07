/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_cdm_version_update(version_num=);
/* while moving to new version if you need to update existing tables write version specific changes here */
/*  need to allow using schema 8 - commenting out hard reference.
    %if &version_num. ne 8 %then %do;
        %put ERROR: CDM Schema Version mismatch;
        %put ERROR: Download KSA expects Schema Version 6, this is Schema Version &version_num..;
        %let retcode=1 ;
				%goto EXIT;
    %end;
*/
    data cdm_version_hist;
		    attrib ver_num length= 8.
               ver_create_dttm length=8. format=datetime25.6;
        ver_num =&version_num.;
        ver_create_dttm =datetime();
    run;

		proc append base=dsccnfg.cdm_version_hist data=cdm_version_hist;
    run;

%EXIT:

%mend dsc_cdm_version_update;
