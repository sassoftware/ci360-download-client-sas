#  SAS Customer Intelligence 360 Download Client - SAS

## Overview
 This program uses SAS code to download cloud data from SAS Customer Intelligence 360 to your local machine.

This topic contains the following sections:
* [Configuration](#configuration)
* [Using the Download Script](#using-the-download-script)
	* [Running the script](#running-the-script)
	* [Examples](#examples)
* [Contributing](#contributing)
* [License](#license)
* [Additional Resources](#additional-resources)


### Configuration
1. Install Base SAS 9.4M4 (with Unicode Support).
2. Enable SAS to use the XCMD System Option. For more information, see the
     [Help Center for SAS 9.4](https://go.documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=9.4_3.4) and search for the
     XCMD option.
3. Install Python (version 3 or later) from https://www.python.org/. Python is used to generate token for API authentication.

   **Tip:** Select the option to add Python to your PATH variable. If you choose the advanced installation option, make sure to install the pip utility.
     
    Make sure the following modules are installed for Python: `getopt`, `http.client`, `urllib`, `re`, `base64`, `PyJWT`.
4. Install the gzip program from https://www.gzip.org/.

   After the program is installed, add the location of the gzip program to the PATH environment variable. This is required for SAS program to read .gz files without un-compressing the file.
5. Create an access point in SAS Customer Intelligence 360.
    1. From the user interface, navigate to **General Settings** > **External Access** > **Access Points**.
    2. Create a new access point if one does not exist.
    3. Get the following information from the access point:
       ```
        External gateway address: e.g. https://extapigwservice-<server>/marketingGateway  
        Name: ci360_agent  
        Tenant ID: abc123-ci360-tenant-id-xyz  
        Client secret: ABC123ci360clientSecretXYZ
       ```

### Using the Download Script

#### Running the Script

1. Open Base SAS 9.4M4 (Unicode Support).
2. In Base SAS, open the dsc_download.sas macro from the `macros` folder.
3. Edit the variables in the dsc_download.sas macro.
   
   <a name="script-parameters"> </a>
   These are the variables and the values that they can be set to:

   | Parameter              | Description                                                                                                                                                                                 |
   |------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
   | mart_nm                | The table set to download. Use one of these values:<br><ul><li>cdm (This value downloads both partitioned tables and unpartitioned tables. The category value should also be set to "cdm".)</li><li>detail</li><li>dbtReport</li><li>snapshot (for identity tables and metadata tables)</li></ul>                                       |
   | DSC_LOAD_START_DTTM    | (Optional) The start value in this format: `%nrquote(ddMMMYYYY HH:mm:ss)`. For example: `%nrquote(12Jan2020 13:00:00)`                                                                                 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   | DSC_LOAD_END_DTTM      | (Optional) The end value in this format: `%nrquote(ddMMMYYYY HH:mm:ss)`. For example: `%nrquote(12Jan2020 13:00:00)`                                                                                   |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
   | DSC_SCHEMA_VERSION     | (Optional) The specific schema of tables to download. If you do not set this value, the data is downloaded from schema 1.                                                                              |
   | RESET_DAY_OFFSET       | (Optional) The number of days of reset data to download. For more information about how data is reset, see [Downloading Reprocessed Data with the Resets API](https://go.documentation.sas.com/doc/en/cintcdc/production.a/cintag/dat-export-api-resets.htm). <br/><br/>**Note:** The CDM tables do not use reset data, so this variable does not affect that data set.  | 
   | DSC_SUB_HOURLY_MINUTES | (Optional) For partitioned tables, this variable specifies how many minutes are in each partition. For example, setting the variable to 40 would download table data in partitions of 40 minutes each.<br/><br/>By default, partitions are in one-hour increments. |
   | CATEGORY |  (Optional) The category of tables to download. When the parameter is not specified, you download tables for all the categories that you have a license to access.<br><br>To download tables from a specific category, you can use one of these values:<ul><li>cdm</li><li>discover</li><li>engagedigital</li><li>engagedirect</li><li>engagemetadata</li><li>engagemobile</li><li>engageweb</li><li>engageemail</li><li>optoutdata</li><li>plan</li></ul><br>For more information, see [Schemas and Categories](https://go.documentation.sas.com/?cdcId=cintcdc&cdcVersion=production.a&docsetId=cintag&docsetTarget=dat-export-api-sch.htm).
   | CODE                   | (Optional) A code that enables you to download tables that are in test mode (for early adopters).                                                                                                      |
   
   **Note:** The start and end ranges are only used for the script's first run. After the first run, the download history is stored in the data/dsccnfg directory. To force the script to use the variables for start date and end date, delete or move the history information.
   
   See the [Examples](#examples) section for different combinations of values.

#### Examples
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

%* cdm mart hourly days ;
%let mart_nm=cdm;
%let DSC_LOAD_START_DTTM=%nrquote(12Jan2020 13:00:00);
%let DSC_LOAD_END_DTTM=%nrquote(12Jan2020 13:59:59);;
%let DSC_SCHEMA_VERSION=6;
%let RESET_DAY_OFFSET = 60;
%let DSC_SUB_HOURLY_MINUTES=60;
%let CATEGORY=cdm;
%let CODE=;

```


## Contributing

We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources
For more information, see [Downloading Data Tables with the REST API](https://go.documentation.sas.com/?softwareId=ONEMKTMID&softwareVersion=production.a&softwareContextId=DownloadDataTables) in the Help Center for SAS Customer Intelligence 360.
