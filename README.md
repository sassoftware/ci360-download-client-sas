#  SAS Customer Intelligence 360 Download Client - SAS

## Overview
 Download client program to download SAS Customer Intelligence 360 data from cloud.


### What's New

### Prerequisites
* BASE SAS9.4(M4)(Unicode Support)
* Enable SAS to Allow XCMD System Option
* Python3
	Python is used to generate token for API authentication. 
	make sure following python libraries are installed 
	`getopt`, `http.client`, `urllib`, `re`, `base64`, `jwt`
* gzip utility program 
	Download gzip.exe. Add gzip utility program location to PATH environment variable. This is required for SAS program to read .gz files without un-compressing the file.
* from CI360 Console - General Settings -> External -> Access 
 get the following ( create new access point if it's not already created)
	 ```
	 External gateway address: e.g. https://extapigwservice-dev.cidev.sas.us/marketingGateway
	 Name: ci360_agent
	 Tenant ID: abc123-ci360-tenant-id-xyz
	 Client secret: ABC123ci360clientSecretXYZ
	```
### Installation
* download client program and save it to client machine.
* set up python3 with required libraries
* set up gzip.exe

## Getting Started

### Running

* Open BASE SAS9.4(M4)(Unicode Support)
* Open dsc_download.sas macro from the macros folder
* Set all the required macro variables in dsc_download.sas
* Set the mart_nm to download and run the sas program.

### Examples
```
%* Set the variables in dsc_download.sas

%* detail mart with specific range ;
%let mart_nm=detail;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let DSC_SCHEMA_VERSION=1;
%let DSC_SUB_HOURLY_MINUTES=60;
%let RESET_DAY_OFFSET = 60;

%* detail mart with specific range & schema version 3 ;
%let mart_nm=detail;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;

%let DSC_SCHEMA_VERSION=3;


%* detail mart with specific category ;
%let mart_nm=detail;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let DSC_SCHEMA_VERSION=3;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;

%let CATEGORY=engagedirect;

%*  detail mart with multiple categories ;
%let mart_nm=detail;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let DSC_SCHEMA_VERSION=3;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;

%let CATEGORY=discover,engagedirect;


%* detail mart - Test Mode data ;
%let mart_nm=detail;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let DSC_SCHEMA_VERSION=3;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;
%let CATEGORY=;

%let CODE=PH4TESTMODE;


%* detail mart - subhourly data ;
%let mart_nm=detail;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let DSC_SCHEMA_VERSION=3;
%let RESET_DAY_OFFSET = 60;
%let CATEGORY=;
%let CODE=;

%let DSC_SUB_HOURLY_MINUTES=10;


%* dbtReport mart with specific range ;
%let mart_nm=dbtReport;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
%let DSC_SCHEMA_VERSION=3;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;
%let CATEGORY=;
%let CODE=;


%* identity and all categories metadata tables ;
%let mart_nm=snapshot;
%let DSC_LOAD_START_DTTM=;
%let DSC_LOAD_END_DTTM=;
%let DSC_SCHEMA_VERSION=4;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;
%let CATEGORY=all;
%let CODE=;

%* plan data ;
%let mart_nm=snapshot;
%let DSC_LOAD_START_DTTM=;
%let DSC_LOAD_END_DTTM=;
%let DSC_SCHEMA_VERSION=5;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;
%let CATEGORY=PLAN;
%let CODE=;

```

### Troubleshooting


## Contributing

We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources
For more information, see [Downloading Data from SAS Customer Intelligence 360](https://go.documentation.sas.com/?cdcId=cintcdc&cdcVersion=production.a&docsetId=cintag&docsetTarget=extapi-discover-service.htm&locale=en#p0kj5ymn5wuyqdn1209mw0xcfinc).