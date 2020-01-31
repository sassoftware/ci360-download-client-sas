/*-----------------------------------------------------------------------------
 Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
 SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_httprequest(	infile=,
						outfile=,
						headerin=,
						headerout=,
						requestCT=,
						requestURL=,
						requestMethod=,
						service_auth=,
						proxy_host=,
						proxy_port=,
						proxy_auth=
						);
	/* disable quote warnings */
	options NOQUOTELENMAX;
    proc http 
		%if &infile ne %then
		%do;
        	in=&infile
		%end;
		%if &outfile ne %then
		%do;
        	out=&outfile
		%end;
		%if &headerin ne %then
		%do;
			headerin=&headerin
		%end;
		%if &headerout ne %then
		%do;
        	headerout=&headerout
			HEADEROUT_OVERWRITE
		%end;
		%if &requestCT ne %then
		%do;
			ct="&requestCT ; charset=utf-8"		
		%end;
		/* need proxy ? */
		%if (%length(&proxy_host) > 0 and %length(&proxy_port) > 0) %then
		%do;
			proxyhost="&proxy_host"
			proxyport=&proxy_port
			/* proxy with auth ?*/
			%if &proxy_auth ne %then
			%do;
				&proxy_auth
			%end;
		%end;
		method="&requestMethod" 
		url="%superq(requestURL)"
		;
		%if &service_auth ne %then
		%do;
			&service_auth ;
		%end;
    run;

    %* Check proc http execution status ;
    %if &SYSERR. > 4 %then 
    %do;
       	%put &SYSERRORTEXT. ;
		%let retcode=1; 
		%put ERROR: Error in executing proc http call;
   	%end;

%mend;
