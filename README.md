#  SAS Customer Intelligence 360 Download Client - SAS

## Overview
This repository hosts a SAS program that can download cloud data from SAS Customer Intelligence 360 to your local 
system.

The SAS program can perform the following tasks:
 * Download data from the Unified Data Model (UDM) in SAS Customer Intelligence 360.
 * Specify a time range, schema, and category of data to download.
 * Automatically unzip the download packages and load into the on-premises installation of SAS.
 * Keep track of all initiated downloads. This lets you download a delta from the last complete download and append it 
   to one file per table.

This topic contains the following sections:
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Running the Script](#running-the-script) (includes examples)
* [Contributing](#contributing)
* [License](#license)
* [Additional Resources](#additional-resources)


<!-- ## What's New -->

## Prerequisites
Install these applications and supporting tools:

* BASE SAS 9.4 (M4 or later). Make sure the installation includes these features:
    * Unicode support
    * the XCMD system option is enabled. For more information, see [XCMD System Option: Windows](https://support.sas.com/documentation/cdl/en/hostwin/69955/HTML/default/viewer.htm#p0xtd57b40ehdfn1jyk8yxemfrtv.htm)

* [Python 3](https://www.python.org/). Python is used to generate the authentication token for the REST API. 
  Make sure these packages are installed: `getopt`, `http.client`, `urllib`, `re`, `base64`, `jwt`

* [gzip utility program](http://www.gzip.org/). This program is required for the SAS program to read .gz files without 
  un-compressing the file. Follow these steps:
	1. Download the gzip.exe program.
	2. Add the location of the file to the PATH environment variable.
	

Configure external access to the REST API in SAS Customer Intelligence 360:

1. In the user interface for SAS Customer Intelligence 360, navigate to **General Settings** > **External** > **Access**.

1. Create a general access point if one does not exist. For more information, see 
   [Create an Access Point](https://go.documentation.sas.com/?cdcId=cintcdc&cdcVersion=production.a&docsetId=cintag&docsetTarget=extapi-config-agentdef.htm&locale=en).

1. Open the access point definition, and get the information about the gateway. The information is similar to this example:
	 ```
	 External gateway address: https://extapigwservice-<server>/marketingGateway
	 Name: ci360_agent
	 Tenant ID: abc123-ci360-tenant-id-xyz
	 Client secret: ABC123ci360clientSecretXYZ
	```

## Installation

1. Download the SAS client program from the repository, and save it to your local machine.
1. Make sure Python3 in installed with required libraries and in the PATH environment variable.
1. Make sure the gzip.exe file exists on your machine and is in the PATH environment variable.


## Running the Script

### Using the Script

1. Open BASE SAS9.4(M4)(Unicode Support).
1. Open the dsc_download.sas macro from the macros folder.
1. Set the required macro variables in the dsc_download.sas file. In particular, set the `mart_nm` variable to specify 
   which data mart from the UDM to download.
1. Run the macro.

### Examples
To use these example, modify the variables in the dsc_download.sas file.

* Download data from the detail mart from a specific date range:
   ```
   %let mart_nm=detail;
   %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
   %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
   %let DSC_SCHEMA_VERSION=1;
   %let DSC_SUB_HOURLY_MINUTES=60;
   %let RESET_DAY_OFFSET = 60;
   ```

* Download data from the detail mart from a specific date range and schema:
   ```
   %let mart_nm=detail;
   %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
   %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
   %let RESET_DAY_OFFSET = 60;
   %let DSC_SUB_HOURLY_MINUTES=60;
   
   %let DSC_SCHEMA_VERSION=3;
   ```

* Download data from the detail mart using a specific category (license):
  ```
  %let mart_nm=detail;
  %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
  %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
  %let DSC_SCHEMA_VERSION=3;
  %let RESET_DAY_OFFSET = 60;
  %let DSC_SUB_HOURLY_MINUTES=60;
  
  %let CATEGORY=engagedirect;
  ```

* Download data from the detail mart with multiple categories:
  ```
  %let mart_nm=detail;
  %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
  %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
  %let DSC_SCHEMA_VERSION=3;
  %let RESET_DAY_OFFSET = 60;
  %let DSC_SUB_HOURLY_MINUTES=60;
  
  %let CATEGORY=discover,engagedirect;
  ```

* Download test data from the detail mart;
  ```
  %let mart_nm=detail;
  %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
  %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
  %let DSC_SCHEMA_VERSION=3;
  %let RESET_DAY_OFFSET = 60;
  %let DSC_SUB_HOURLY_MINUTES=60;
  %let CATEGORY=;
  
  %let CODE=PH4TESTMODE;
  ```

* Download subhourly data from the detail mart:
  ```
  %let mart_nm=detail;
  %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
  %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
  %let DSC_SCHEMA_VERSION=3;
  %let RESET_DAY_OFFSET = 60;
  %let CATEGORY=;
  %let CODE=;
  
  %let DSC_SUB_HOURLY_MINUTES=10;
  ```

* Download data from the dbtReport mart from a specific date range:
  ```
  %let mart_nm=dbtReport;
  %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
  %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);
  %let DSC_SCHEMA_VERSION=3;
  %let RESET_DAY_OFFSET = 60;
  %let DSC_SUB_HOURLY_MINUTES=60;
  %let CATEGORY=;
  %let CODE=;
  ```

* Download identity data and metadata tables:
  ```
  %let mart_nm=snapshot;
  %let DSC_LOAD_START_DTTM=;
  %let DSC_LOAD_END_DTTM=;
  %let DSC_SCHEMA_VERSION=4;
  %let RESET_DAY_OFFSET = 60;
  %let DSC_SUB_HOURLY_MINUTES=60;
  %let CATEGORY=all;
  %let CODE=;
  ```

* Download metadata for items in SAS 360 Plan: 
  ```
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

* Download hourly data from the CDM mart:
  ```
  %let mart_nm=cdm;
  %let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
  %let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);;
  %let DSC_SCHEMA_VERSION=6;
  %let RESET_DAY_OFFSET = 60;
  %let DSC_SUB_HOURLY_MINUTES=60;
  %let CATEGORY=cdm;
  %let CODE=;
  ```

<!-- ### Troubleshooting -->


## Contributing

We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources
For more information, see [Downloading Data from SAS Customer Intelligence 360](https://go.documentation.sas.com/?cdcId=cintcdc&cdcVersion=production.a&docsetId=cintag&docsetTarget=extapi-discover-service.htm&locale=en#p0kj5ymn5wuyqdn1209mw0xcfinc).
