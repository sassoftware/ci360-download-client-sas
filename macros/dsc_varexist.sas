/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_varexist(ds, var);
    %local rc dsid result;
    %let dsid = %sysfunc(open(&ds));
 
    %if %sysfunc(varnum(&dsid, &var)) > 0 %then %do;
        %let result = 1;
        %put NOTE: Var &var exists in &ds;
    %end;
    %else %do;
        %let result = 0;
        %put NOTE: Var &var not exists in &ds;
    %end;
 
    %let rc = %sysfunc(close(&dsid));
    &result
%mend dsc_varexist;
