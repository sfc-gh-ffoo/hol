/***************************************************************************************************
Transformation
    1 - Zero Copy Cloning
    2 - Using Persisted Query Results
    3 - Adding and Updating a Column in a Table
    4 - Time-Travel for Table Restore
    5 - Table Swap, Drop and Undrop
***************************************************************************************************/

/*----------------------------------------------------------------------------------
Step 1 - Zero Copy Cloning

 Within this step, we will first walk through standing up a Development environment
 using Snowflake Zero Copy Cloning for this development to be completed and tested
 within before rolling into production.
----------------------------------------------------------------------------------*/

-- before we begin, let's set our Role and Warehouse context
USE ROLE nlt_dev;
USE DATABASE nlt;


-- to ensure our new Column development does not impact production,
-- let's first create a snapshot copy of the opor table using Clone 
CREATE OR REPLACE TABLE raw.opor_dev CLONE raw.opor;

      /**
        Zero Copy Cloning: Creates a copy of a database, schema or table. A snapshot of data present in
         the source object is taken when the clone is created and is made available to the cloned object.

         The cloned object is writable and is independent of the clone source. That is, changes made to
         either the source object or the clone object are not part of the other. Cloning a database will
         clone all the schemas and tables within that database. Cloning a schema will clone all the
         tables in that schema.
      **/

-- before we query our clone, let's now set our Warehouse context
    --> NOTE: a Warehouse isn't required in a Clone statement as it is handled via Snowwflake Cloud Services
USE WAREHOUSE nlt_dev_wh;

-- with our Zero Copy Clone created, let's query for what we would like to combin
//TO DO - Try this out with any query of choice!
SELECT DOCENTRY,
DOCNUM,
DOCTYPE,
CANCELED,
HANDWRTTEN,
PRINTED,
DOCSTATUS,
CARDNAME
FROM NLT.RAW.OPOR_DEV;


/*----------------------------------------------------------------------------------
Step 2 - Using Persisted Query Results

 If a user repeats a query that has already been run in the last 24 hours, and the 
 data in the table hasn’t changed since the last time that the query was run, 
 then the result of the query is the same. 
 
 Instead of running the query again, Snowflake simply returns the same result that
 it returned previously from the result set cache. Within this step, we will
 test this functionality.
----------------------------------------------------------------------------------*/

-- to test Snowflake's Result Cache, let's first suspend our Warehouse
    --> NOTE: if you recieve "..cannot be suspended" then the Warehouse Auto Suspend timer has already elapsed
ALTER WAREHOUSE nlt_dev_wh SUSPEND;


-- with our compute suspended, let's re-run our query from above
SELECT DOCENTRY,
DOCNUM,
DOCTYPE,
CANCELED,
HANDWRTTEN,
PRINTED,
DOCSTATUS,
CARDNAME, --> Snowflake supports Trailing Comma's in SELECT clauses
FROM NLT.RAW.OPOR_DEV;

-- a few things we should look at after executing the query:

    -- did the Warehouse turn on?
        --> In the Top Right Context window, explore the Warehouse status via Show Warehouse details

    -- what does the Query Profile show?
        --> In the Query Details pane next to Result, Click on the Query ID to open up the Query Profile

    -- we also need to fix the address2 column to reflect a change in address
        --> We will do this in the next Step

  
/*----------------------------------------------------------------------------------
Step 3 - Adding and Updating a Column in a Table

 Within this step, we will now will Add and Update a CARDNAME Type column
 to the Development Table we created previously while also addressing
 the typo in the Make field.
----------------------------------------------------------------------------------*/

-- to start, let's correct the typo we noticed in the Make column
UPDATE NLT.RAW.OPOR_DEV
    SET CARDNAME = 'TEST CARD' WHERE CARDNAME = 'TEST TEST TEST PTE LTD';


-- now, let's build a query to concatenate columns together
SELECT
    DOCENTRY,
    DOCNUM,
    DOCTYPE,
    CANCELED,
    HANDWRTTEN,
    PRINTED,
    DOCSTATUS,
    CONCAT(DOCTYPE,'-',DOCNUM) AS DOCNAME
FROM NLT.RAW.OPOR_DEV;


-- let's now Add the new column to the table
ALTER TABLE NLT.RAW.OPOR_DEV
    ADD COLUMN DOCNAME VARCHAR(50);


-- with our empty column in place, we can now run the Update statement to populate each row
UPDATE NLT.RAW.OPOR_DEV
    SET DOCNAME =  CONCAT(DOCTYPE,'-',DOCNUM);


--with the rows successfully updated, let's validate our work
SELECT
    DOCENTRY,
    DOCNUM,
    DOCTYPE,
    DOCNAME
FROM NLT.RAW.OPOR_DEV;

/*----------------------------------------------------------------------------------
Step 3 - Time-Travel for Table Restore

 Oh no! We made a mistake on the Update statement earlier. Thankfully, we can use Time Travel to revert our table back
 to the state it was after we tried to fix it so we can correct our work.

 Time-Travel enables accessing data that has been changed or deleted at any point
 up to 90 days. It serves as a powerful tool for performing the following tasks:
   - Restoring data objects that have been incorrectly changed or deleted.
   - Duplicating and backing up data from key points in the past.
   - Analyzing data usage/manipulation over specified periods of time.
----------------------------------------------------------------------------------*/

-- first, let's look at all Update statements to our Development Table using the Query History function
SELECT
    query_id,
    query_text,
    user_name,
    query_type,
    start_time
FROM TABLE(information_schema.query_history())
WHERE 1=1
    AND query_type = 'UPDATE'
    AND query_text LIKE '%NLT.RAW.OPOR_DEV%'
ORDER BY start_time DESC;


-- for future use, let's create a SQL variable and store the Update statement's Query ID in it
SET query_id =
    (
    SELECT TOP 1
        query_id
    FROM TABLE(information_schema.query_history())
    WHERE 1=1
        AND query_type = 'UPDATE'
        AND query_text LIKE '%SET DOCNAME =%'
    ORDER BY start_time DESC
    );

    /**
    Time-Travel provides many different statement options including:
        • At, Before, Timestamp, Offset and Statement

    For our demonstration we will use Statement since we have the Query ID from our bad
    Update statement that we want to revert our table back to the state it was before execution.
    **/

-- now we can leverage Time Travel and our Variable to look at the Development Table state we will be reverting to
SELECT 
    DOCENTRY,
    DOCNUM,
    DOCTYPE,
    DOCNAME
FROM NLT.RAW.OPOR_DEV
BEFORE(STATEMENT => $query_id);


-- using Time Travel and Create or Replace Table, let's restore our Development Table
CREATE OR REPLACE TABLE NLT.RAW.OPOR_DEV
    AS
SELECT * FROM NLT.RAW.OPOR_DEV
BEFORE(STATEMENT => $query_id); -- revert to before a specified Query ID ran


--to conclude, let's run the correct Update statement 
UPDATE NLT.RAW.OPOR_DEV
    SET DOCNAME =  CONCAT(DOCTYPE,'-',DOCNUM);


/*----------------------------------------------------------------------------------
Step 4 - Table Swap, Drop and Undrop

 Based on our previous efforts, we have addressed the requirements we were given and
 to complete our task need to push our Development into Production.

 Within this step, we will swap our Development table with what is currently
 available in Production.
----------------------------------------------------------------------------------*/

-- our Accountadmin role will now Swap our Development Table with the Production
USE ROLE accountadmin;

ALTER TABLE NLT.RAW.OPOR_DEV
    SWAP WITH NLT.RAW.OPOR;


-- let's confirm the production table has the new column in place
SELECT
    DOCENTRY,
    DOCNUM,
    DOCTYPE,
    DOCNAME
FROM NLT.RAW.OPOR;


-- looks great, let's now drop the Development Table
DROP TABLE NLT.RAW.OPOR;


-- we have made a mistake! that was the production version of the table!
-- let's quickly use another Time Travel reliant feature and Undrop it
UNDROP TABLE NLT.RAW.OPOR;


-- with the Production table restored we can now correctly drop the Development Table
DROP TABLE NLT.RAW.OPOR_DEV;

