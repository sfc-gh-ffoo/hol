USE ROLE sysadmin;

/*--
 • database, schema and warehouse creation
--*/

-- create nlt database
CREATE OR REPLACE DATABASE nlt;

-- create raw schema
CREATE OR REPLACE SCHEMA nlt.raw;

-- create harmonized schema
CREATE OR REPLACE SCHEMA nlt.harmonized;

-- create analytics schema
CREATE OR REPLACE SCHEMA nlt.analytics;

-- create warehouses
CREATE OR REPLACE WAREHOUSE nlt_de_wh
    WAREHOUSE_SIZE = 'xsmall' 
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'data engineering warehouse for nlt hands-on workshop';

CREATE OR REPLACE WAREHOUSE nlt_dev_wh
    WAREHOUSE_SIZE = 'xsmall'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'development warehouse for nlt hands-on workshop';

-- create roles
USE ROLE securityadmin;

-- functional roles
CREATE ROLE IF NOT EXISTS nlt_admin
    COMMENT = 'admin for nlt';
    
CREATE ROLE IF NOT EXISTS nlt_data_engineer
    COMMENT = 'data engineer for nlt';
    
CREATE ROLE IF NOT EXISTS nlt_dev
    COMMENT = 'developer for nlt';
    
-- role hierarchy
GRANT ROLE nlt_admin TO ROLE sysadmin;
GRANT ROLE nlt_data_engineer TO ROLE nlt_admin;
GRANT ROLE nlt_dev TO ROLE nlt_data_engineer;

-- privilege grants
USE ROLE accountadmin;

GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE nlt_data_engineer;

GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE nlt_admin;

USE ROLE securityadmin;

GRANT USAGE ON DATABASE nlt TO ROLE nlt_admin;
GRANT USAGE ON DATABASE nlt TO ROLE nlt_data_engineer;
GRANT USAGE ON DATABASE nlt TO ROLE nlt_dev;

GRANT USAGE ON ALL SCHEMAS IN DATABASE nlt TO ROLE nlt_admin;
GRANT USAGE ON ALL SCHEMAS IN DATABASE nlt TO ROLE nlt_data_engineer;
GRANT USAGE ON ALL SCHEMAS IN DATABASE nlt TO ROLE nlt_dev;

GRANT ALL ON SCHEMA nlt.raw TO ROLE nlt_admin;
GRANT ALL ON SCHEMA nlt.raw TO ROLE nlt_data_engineer;
GRANT ALL ON SCHEMA nlt.raw TO ROLE nlt_dev;

GRANT ALL ON SCHEMA nlt.harmonized TO ROLE nlt_admin;
GRANT ALL ON SCHEMA nlt.harmonized TO ROLE nlt_data_engineer;
GRANT ALL ON SCHEMA nlt.harmonized TO ROLE nlt_dev;

GRANT ALL ON SCHEMA nlt.analytics TO ROLE nlt_admin;
GRANT ALL ON SCHEMA nlt.analytics TO ROLE nlt_data_engineer;
GRANT ALL ON SCHEMA nlt.analytics TO ROLE nlt_dev;

-- warehouse grants
GRANT OWNERSHIP ON WAREHOUSE nlt_de_wh TO ROLE nlt_admin COPY CURRENT GRANTS;
GRANT ALL ON WAREHOUSE nlt_de_wh TO ROLE nlt_admin;
GRANT ALL ON WAREHOUSE nlt_de_wh TO ROLE nlt_data_engineer;

GRANT ALL ON WAREHOUSE nlt_dev_wh TO ROLE nlt_admin;
GRANT ALL ON WAREHOUSE nlt_dev_wh TO ROLE nlt_data_engineer;
GRANT ALL ON WAREHOUSE nlt_dev_wh TO ROLE nlt_dev;

-- future grants
GRANT ALL ON FUTURE TABLES IN SCHEMA nlt.raw TO ROLE nlt_admin;
GRANT ALL ON FUTURE TABLES IN SCHEMA nlt.raw TO ROLE nlt_data_engineer;
GRANT ALL ON FUTURE TABLES IN SCHEMA nlt.raw TO ROLE nlt_dev;

GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.harmonized TO ROLE nlt_admin;
GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.harmonized TO ROLE nlt_data_engineer;
GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.harmonized TO ROLE nlt_dev;

GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.analytics TO ROLE nlt_admin;
GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.analytics TO ROLE nlt_data_engineer;
GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.analytics TO ROLE nlt_dev;

-- Apply Masking Policy Grants
USE ROLE accountadmin;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE nlt_admin;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE nlt_data_engineer;

-- Let's proceed to load data into tables via the UI
//Proceed with UI

//VIEW DATA THAT HAS BEEN LOADED
SELECT * FROM NLT.RAW.OPOR LIMIT 10;

-- setup completion note
SELECT 'nlt setup is now complete' AS note;