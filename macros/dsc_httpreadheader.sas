/*-----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
%macro dsc_httpreadheader(action=,hdrout=,outfile=);
	/*
		Action = GET_URLLIST 
		Action = FILE_DOWNLOAD
	*/

    %if %sysfunc(fileexist(&hdrout.)) %then 
    %do;
		%let retcode=1;
		%put ERROR:Header file not found. ;
		%goto ERROREXIT;
    %end;

    %* read the header output file
	1. read the first line which contains the return status code 
	2. read the line which contains the string location: (only post request will set this)
	3. extract the jobId from the location value string
	;
    data work.HeaderInfo;
        length HeaderLine $4000; 
        infile &hdrout. length=reclen ; 
        input HeaderLine $varying999. reclen ;
        /*check the status code and status message from the first line
        First line sample Http status             
		HTTP/1.1 200 OK - GET_URLLIST status - with EXT API now its set to HTTP/1.1 200 .. so only read status cd not status msg
        HTTP/1.1 405 Method Not Allowed
        HTTP/1.1 500 Internal Server Error
        */
        if _n_ eq 1 then
        do;
            if kindex(upcase(HeaderLine), 'HTTP/1.1' ) then
            do;
                %* read the 4th word which is the status code;
                status_code = kscan(HeaderLine, 4);  
                %* read the  string from 5th word onwards which is the status message;
                status_msg = ksubstr(HeaderLine, kindex(HeaderLine,scan(HeaderLine, 5)));
                call symput('http_status_cd' ,trim(status_code));
                call symput('http_status_msg' ,trim(status_msg));
            end;        
        end;
    run;

	%* set expected return codes & messages for the input action ;
	%if ( &Action = GET_URLLIST or &Action = FILE_DOWNLOAD or &Action = GET_SCHEMA ) %then
	%do;
		%let expected_success_cd=200;
		/*%let expected_success_msg=OK;*/
	%end;

	%* check if the returned codes in header out file are matching with the expected return codes ;
	/* %if (&http_status_cd. eq &expected_success_cd and %nrquote(&http_status_msg.) eq &expected_success_msg ) %then */
	%if (&http_status_cd. eq &expected_success_cd ) %then
	%do;
		%put INFO: PROC HTTP call successful. ;
	%end;
	%else
	%do;
		%let retcode=1;
		%put ERROR: The PROC HTTP call failed;
		%goto ERROREXIT;
	%end;	

%ERROREXIT:
%mend ;
