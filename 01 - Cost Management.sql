/****************************************************************************************************
Cost Management
    a) Cost Optimization
        1 - Virtual Warehouses and Settings
    b) Cost Control
        2 - Resuming, Suspending and Scaling a Warehouse
        3 - Setting up Session Timeout Parameters 
        4 - Setting up Account Timeout Parameters
        5 - Setting up a Resource Monitors 
    c) Cost Visibility
        6 - Tagging Objects to Attribute Spend
        7 - Exploring Cost with Snowsight
****************************************************************************************************/
-- before we begin, let's set our Role, Warehouse and Database context
USE ROLE nlt_admin;
USE WAREHOUSE nlt_de_wh;
USE DATABASE nlt;

-- let's create our own Test Warehouse and reference the section below to understand each parameter is handling
CREATE OR REPLACE WAREHOUSE nlt_test_wh WITH
COMMENT = 'test warehouse for nlt'
    WAREHOUSE_TYPE = 'standard'
    WAREHOUSE_SIZE = 'xsmall'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = true -- turn on 
    INITIALLY_SUSPENDED = true;

    /**
     1) Warehouse Type: Warehouses are required for queries, as well as all DML operations, including
         loading data into tables. Snowflake supports Standard (most-common) or Snowpark-optimized
          Warehouse Types. Snowpark-optimized warehouses should be considered for memory-intensive
          workloads.

     2) Warehouse Size: Size specifies the amount of compute resources available per cluster in a warehouse.
         Snowflake supports X-Small through 6X-Large sizes.

     3) Max Cluster Count: With multi-cluster warehouses, Snowflake supports allocating, either statically
         or dynamically, additional clusters to make a larger pool of compute resources available.
         A multi-cluster warehouse is defined by specifying the following properties:
            - Min Cluster Count: Minimum number of clusters, equal to or less than the maximum (up to 10).
            - Max Cluster Count: Maximum number of clusters, greater than 1 (up to 10).

     4) Scaling Policy: Specifies the policy for automatically starting and shutting down clusters in a
         multi-cluster warehouse running in Auto-scale mode.

     5) Auto Suspend: By default, Auto-Suspend is enabled. Snowflake automatically suspends the warehouse
         if it is inactive for the specified period of time, in our case 60 seconds.

     6) Auto Resume: By default, auto-resume is enabled. Snowflake automatically resumes the warehouse
         when any statement that requires a warehouse is submitted and the warehouse is the
         current warehouse for the session.

     7) Initially Suspended: Specifies whether the warehouse is created initially in the ‘Suspended’ state.
    **/


/*----------------------------------------------------------------------------------
Step 2 - Resuming, Suspending and Scaling a Warehouse

 With a Warehouse created, let's now use it to answer a few questions from the 
 business. While doing so we will learn how to resume, suspend and elastically
 scale the Warehouse.
----------------------------------------------------------------------------------*/

-- let's first set our Admin Role and Test Warehouse context
USE ROLE nlt_admin;
USE WAREHOUSE nlt_test_wh;


-- Run a simple query on the nlt dataset
    --> NOTE: Snowflake automatically resumes the warehouse when any statement that requires a warehouse is submitted
SELECT
DOCENTRY, DOCNUM, DOCTYPE, CANCELED, HANDWRTTEN, PRINTED, DOCSTATUS, INVNTSTTUS, TRANSFERED, OBJTYPE, DOCDATE, DOCDUEDATE
FROM NLT.RAW.OPOR o
WHERE DOCNUM = '230074420';


-- to showcase Snowflakes elastic scalability let's scale our Warehouse up and run a few larger, aggregation queries
ALTER WAREHOUSE nlt_test_wh SET warehouse_size = 'large';


-- Try writing a more complex query that has filters and aggregates to test the performance of the larger warehouse
//TODO


-- let's now scale our Test Warehouse back down
ALTER WAREHOUSE nlt_test_wh SET warehouse_size = 'xsmall';


-- and now manually Suspend it
    --> NOTE: if you receive "Invalid state. Warehouse cannot be suspended." the auto_suspend we configured earlier has already occured
ALTER WAREHOUSE nlt_test_wh SUSPEND;


/*----------------------------------------------------------------------------------
Step 3 - Controlling Cost with Session Timeout Parameters 

 Within this step, let's now make sure we are protecting ourselves from bad,
 long running queries.
 
 To do this we will adjust two Statement Timeout Parameters on our Test Warehouse.
----------------------------------------------------------------------------------*/

-- to begin, let's look at the Statement Parameters for our Test Warehouse
SHOW PARAMETERS LIKE 'STATEMENT%' IN WAREHOUSE nlt_test_wh;


-- let's start by adjusting the 2 Statement Parameters related to Query Timeouts
--> 1) adjust Statement Timeout on the Test Warehouse to 30 minutes
ALTER WAREHOUSE nlt_test_wh
    SET statement_timeout_in_seconds = 1800; -- 1800 seconds = 30 minutes


--> 2) adjust Statement Queued Timeout on the Test Warehouse to 10 minutes
ALTER WAREHOUSE nlt_test_wh
    SET statement_queued_timeout_in_seconds = 600; -- 600 seconds = 10 minutes

    /**
     Statement Timeout in Seconds: Timeout in seconds for statements: statements are automatically canceled if they
      run for longer; if set to zero, max value (604800) is  enforced.

     Statement Queued in Second: Timeout in seconds for queued statements: statements will automatically be
      canceled if they are queued on a warehouse for longer than this  amount of time; disabled if set to zero.
    **/

/*----------------------------------------------------------------------------------
Step 4 - Controlling Cost with Account Timeout Parameters 

 The Timeout Parameters we set on our Test Warehouse are also available at the
 Account, User and Session level. Within this step, we will adjust these at the
 Account level.

 Moving forward we will plan to monitor these as our Snowflake Workloads and Usage
 grow to ensure they are continuing to protect our account from unnecessary consumption
 but allowing for expected longer jobs to complete.
----------------------------------------------------------------------------------*/

-- to begin we will assume the role of Accountadmin
USE ROLE accountadmin;


--> 1) adjust Statement Timeout on the the Account to 5 hours
ALTER ACCOUNT 
    SET statement_timeout_in_seconds = 18000; -- 18000 seconds = 5 hours


--> 2) adjust Statement Queued Timeout on the Account to 1 hour
ALTER ACCOUNT
    SET statement_queued_timeout_in_seconds = 3600; -- 3600 seconds = 1 hour;


/*----------------------------------------------------------------------------------
Step 5 - Monitoring Cost with Resource Monitors

 With a Test Warehouse in place, let's now leverage Snowflake's Resource Monitors
 to ensure the Warehouse has a monthly quota. This will also allow Admins to monitor
 credit consumption and trigger Warehouse suspension if the quota is surpassed.

 Within this step we will create our Resource Monitor using SQL but these can also
 be deployed and monitored in Snowsight by navigating to Admin -> Cost Management.
----------------------------------------------------------------------------------*/

   /**
     Resource Monitor: A resource monitor can be used to monitor credit usage by virtual warehouses
      and the cloud services needed to support those warehouses. If desired, the warehouse can be
      suspended when it reaches a credit limit.
    **/

-- create our Resource Monitor
CREATE OR REPLACE RESOURCE MONITOR nlt_test_rm
WITH
    CREDIT_QUOTA = 100 -- set the quota to 100 credits
    FREQUENCY = monthly -- reset the monitor monthly
    START_TIMESTAMP = immediately -- begin tracking immediately
    TRIGGERS
        ON 75 PERCENT DO NOTIFY -- notify accountadmins at 75%
        ON 100 PERCENT DO SUSPEND -- suspend warehouse at 100 percent, let queries finish
        ON 110 PERCENT DO SUSPEND_IMMEDIATE; -- suspend warehouse and cancel all queries at 110 percent


-- with the Resource Monitor created, apply it to our Test Warehouse
ALTER WAREHOUSE nlt_test_wh 
    SET RESOURCE_MONITOR = nlt_test_rm;

/*----------------------------------------------------------------------------------
Step 6 - Tag Objects to Attribute Spend

 Within this step, we will help our Finance department attribute consumption costs
 for the Test Warehouse to our Development Team. 
 
 We will create a Tag object for associating Cost Centers to Database
 Objects and Warehouses and leverage it to assign the Development Team Cost Center
 to our Test Warehouse.
----------------------------------------------------------------------------------*/

    /**
     Tag: A tag is a schema-level object that can be assigned to another Snowflake object.
      A tag can be assigned an arbitrary string value upon assigning the tag to a Snowflake object.
      Snowflake stores the tag and its string value as a key-value pair.
    **/
    
-- first, we will create our Cost Center Tag
CREATE OR REPLACE TAG cost_center;


-- now we use the Tag to attach the Development Team Cost Center to the Test Warehouse
ALTER WAREHOUSE nlt_test_wh SET TAG cost_center = 'DEVELOPMENT_TEAM';


/*----------------------------------------------------------------------------------
Step 7 - Exploring Cost with Snowsight

Snowflake also provides many ways to visually inspect Cost data within Snowsight.
In this step, we will walk through the click path to access a few of these pages.

To access an overview of incurred costs within Snowsight:
    1. Select Admin » Cost Management.
    2. Select a warehouse to use to view the usage data.
        • Snowflake recommends using an X-Small warehouse for this purpose.
    3. Select Account Overview.

To access and drill down into overall cost within Snowsight: 
    1. Select Admin » Cost Management.
    2. Select a warehouse to use to view the usage data.
        • Snowflake recommends using an X-Small warehouse for this purpose.
    3. Select Consumption.
    4. Select All Usage Types from the drop-down list.
----------------------------------------------------------------------------------*/


