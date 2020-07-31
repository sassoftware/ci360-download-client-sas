/*----------------------------------------------------------------------------
Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
-----------------------------------------------------------------------------*/
/******************************************************************************
	SAS OPTIONS
******************************************************************************/
data _null_;run;
options source2 source;
options mprint mlogic symbolgen notes;
options nofmterr novnferr nobyerr nodsnferr no$syntaxcheck;
options compress=yes ;

/******************************************************************************
	GLOBAL VARIABLES USED BY DOWNLOAD PROGRAM
******************************************************************************/
%global DSC_DOWNLOAD_URL DSC_AGENT_NAME  DSC_TENANT_ID DSC_SECRET_KEY DSC_AUTH_TOKEN
DSC_PROXY_HOST DSC_PROXY_PORT DSC_PROXY_AUTH DSC_LOAD_START_DTTM PYTHON_PATH
DSC_HTTP_MAX_RETRY_ATTEMPTS DSC_HTTP_RETRY_WAIT_SEC DSC_FILE_READ_OPTION
UTILITYLOCATION MART_NM CATEGORY CODE AUTORESET;

/*****************************************************************************
	SET THE LOCATION OF THE DOWNLOAD UTILTY e.g. %let UtilityLocation=C:\dev\Client;
******************************************************************************/
%let UtilityLocation=C:\dev\Client;

/*****************************************************************************
	SET THE NAME OF THE MART YOU WISH TO DOWNLOAD DATA E.G.
	%let mart_nm=detail; or %let mart_nm=dbtReport; or %let mart_nm=snapshot;
	or %let mart_nm=cdm;
******************************************************************************/
%let mart_nm=detail;

/*****************************************************************************
	SET LOG LOCATION
******************************************************************************/
proc printto log="&UtilityLocation./logs/&mart_nm._%left(%sysfunc(datetime(),B8601DT15.)).log"; run;

/*****************************************************************************
	SET MACROS LOCATION
*****************************************************************************/
filename dscautos "&UtilityLocation/macros";
options mautosource sasautos=(dscautos,SASAUTOS);

/******************************************************************************
	SET PYTHON34 INSTALL LOCATION e.g.%let PYTHON_PATH=%str(c:\Python36\python.exe);
******************************************************************************/
%let PYTHON_PATH=%str(C:\Python\Python37\python.exe);

/******************************************************************************
	SET DOWNLOAD API PARAMETERS  e.g.
	%let DSC_DOWNLOAD_URL=%nrstr(https://extapigwservice-prod.ci360.sas.com/marketingGateway/discoverService/dataDownload/eventData/);
	%let DSC_AGENT_NAME=ci360_agent;
	%let DSC_TENANT_ID=%str(abc123-ci360-tenant-id-xyz);
	%let DSC_SECRET_KEY=%str(ABC123ci360clientSecretXYZ);

	if the DOWNLOAD endpoint needs a proxy server then set the proxy options else set it to missing values e.g.
	%let DSC_PROXY_HOST=%nrstr(proxy.server.com);
	%let DSC_PROXY_PORT=3128;
	%let DSC_PROXY_AUTH=%nrstr(proxyusername = "proxyuser" proxypassword = "{SAS002}BA7B9D0652C64B185AE2159833C36B93");
******************************************************************************/

%let DSC_DOWNLOAD_URL=%nrstr(https://extapigwservice-prod.ci360.sas.com/marketingGateway/discoverService/dataDownload/eventData/);
%let DSC_AGENT_NAME=ci360_agent;
%let DSC_TENANT_ID=%str(abc123-ci360-tenant-id-xyz);
%let DSC_SECRET_KEY=%str(ABC123ci360clientSecretXYZ);

%let DSC_PROXY_HOST=;
%let DSC_PROXY_PORT=;
%let DSC_PROXY_AUTH=;

/******************************************************************************
	HTTP RETRY OPTIONS
	DSC_HTTP_MAX_RETRY_ATTEMPTS - no of times to retry proc http on failure
	DSC_HTTP_RETRY_WAIT_SEC - no of seconds to wait before retrying http
******************************************************************************/
%let DSC_HTTP_MAX_RETRY_ATTEMPTS=3;
%let DSC_HTTP_RETRY_WAIT_SEC=5;

/******************************************************************************
	FILE OPTIONS
	DSC_FILE_READ_OPTION - options to use in infile statement
	e.g. maximum length of the record in the input file
******************************************************************************/
%let DSC_FILE_READ_OPTION=%str(LRECL=60000 MISSOVER);

/******************************************************************************
	SAS DATA LIBRARIES
	DSCCNFG - Library to store configuration / history files
	DSCDONL - Library to store the downloaded files
	DSCEXTR - Library to hold extract tables created after the file is downloaded
	DSCWH  -  LIbrary to store the detail / dbt tables
******************************************************************************/
libname DSCCNFG "&UtilityLocation./data/dsccnfg";
libname DSCDONL "&UtilityLocation./data/dscdonl";
libname DSCEXTR "&UtilityLocation./data/dscextr";
libname DSCWH "&UtilityLocation./data/dscwh";

/******************************************************************************
 	specify the date time from where you wish to start downloading data or
	keep it blank to start from begining of the available date range e.g.
	%let DSC_LOAD_START_DTTM=%nrquote(05Nov2018 00:00:00);
	%let DSC_LOAD_END_DTTM=%nrquote(05Nov2018 23:59:59);
******************************************************************************/
%let DSC_LOAD_START_DTTM=;
%let DSC_LOAD_END_DTTM=;
%let DSC_LOAD_START_DTTM=%nrquote(12Nov2019 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Nov2019 13:59:59);

/******************************************************************************
	if the data that is already downloaded has been changed in cloud then
	This client program will remove the downloaded data & new data will be downloaded
	by default it will look for changes in previous 60 days data.
	The number of days to look back and reset can be set to other values using
	following option
	e.g.
	%let AUTORESET = yes
	%let RESET_DAY_OFFSET=10;
	RESET_DAY_OFFSET specifies how far back to look for any changes in cloud
    to disable auto reset set AUTORESET = no
******************************************************************************/
%let AUTORESET = yes;
%let RESET_DAY_OFFSET = 60;

/******************************************************************************
	detail mart can be downloaded for minutes instead of default as hours
	to fetch detail data every N ( between 1 to 60 , default is 60) minutes
	set "DSC_SUB_HOURLY_MINUTES" parameter value
	e.g for 10 minutes
	%let DSC_SUB_HOURLY_MINUTES=10;
******************************************************************************/
%let DSC_SUB_HOURLY_MINUTES=60;

/******************************************************************************
	specify schema version to use for download. e.g.
	%let DSC_SCHEMA_VERSION=1; or
	%let DSC_SCHEMA_VERSION=6;
******************************************************************************/
%let DSC_SCHEMA_VERSION=1;

/*****************************************************************************
	SET name of the category to download : e.g. discover,engagedirect ..default discover
	%let category=discover; or %let category=discover,engagedirect; or
	%let category=cdm;
******************************************************************************/
%let CATEGORY=;

/*****************************************************************************
	if you wish you download data in test mode , SET code value : e.g. PH4TESTMODE or PH5TESTMODE
	for regular download set it as %let CODE=;
	Its best to run the test mode by making a copy of the download program
	as the data will be downloaded in the same locations.
	please refer download API documentation for more details about TESTMODE
	e.g.
	%let code=PH4TESTMODE; or %let code=PH5TESTMODE; or %let code=CDMTESTMODE;
******************************************************************************/
%let CODE=;

/******************************************************************************
	RUN THE DOWNLOAD PROGRAM
******************************************************************************/
%dsc_download_data(mart_nm=&mart_nm., reset_day_offset=&reset_day_offset.);

/*****************************************************************************
	STOP PRINTING LOG
******************************************************************************/
proc printto; run;
