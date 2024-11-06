/***************************************************************************************************
 Governance with Snowflake Horizon
  Protect Your Data
    1 - System Defined Roles and Privileges
    2 - Role Based Access Control
    3 - Tag-Based Masking
    4 - Row-Access Policies

  Know Your Data
    5 – Sensitive Data Classification
    6 – Access History (Read and Writes)

 Discovery with Snowflake Horizon
    7 - Universal Search
/*----------------------------------------------------------------------------------
Before we begin, the Snowflake Access Control Framework is based on:
  • Role-based Access Control (RBAC): Access privileges are assigned to roles, which 
    are in turn assigned to users.
  • Discretionary Access Control (DAC): Each object has an owner, who can in turn 
    grant access to that object.

The key concepts to understanding access control in Snowflake are:
  • Securable Object: An entity to which access can be granted. Unless allowed by a 
    grant, access is denied. Securable Objects are owned by a Role (as opposed to a User)
      • Examples: Database, Schema, Table, View, Warehouse, Function, etc
  • Role: An entity to which privileges can be granted. Roles are in turn assigned 
    to users. Note that roles can also be assigned to other roles, creating a role 
    hierarchy.
  • Privilege: A defined level of access to an object. Multiple distinct privileges 
    may be used to control the granularity of access granted.
  • User: A user identity recognized by Snowflake, whether associated with a person 
    or program.

In Summary:
  • In Snowflake, a Role is a container for Privileges to a Securable Object.
  • Privileges can be granted Roles
  • Roles can be granted to Users
  • Roles can be granted to other Roles (which inherit that Roles Privileges)
  • When Users choose a Role, they inherit all the Privileges of the Roles in the 
    hierarchy.
----------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------------
Step 1 - System Defined Roles and Privileges

 Before beginning to deploy Role Based Access Control (RBAC)
 let's first take a look at the Snowflake System Defined Roles and their privileges.
----------------------------------------------------------------------------------*/

-- let's start by assuming the Accountadmin role and our Snowflake Development Warehouse (synonymous with compute)
USE ROLE accountadmin;
USE WAREHOUSE nlt_dev_wh;

-- to follow best practices we will begin to investigate and deploy RBAC (Role-Based Access Control)
-- first, let's take a look at the Roles currently in our account
SHOW ROLES;


-- this next query, will turn the output of our last SHOW command and allow us to filter on the Snowflake System Roles that
-- are provided as default in all Snowflake Accounts
  --> Note: Depending on your permissions you may not see a result for every Role in the Where clause below.
SELECT
    "name",
    "comment"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN ('ORGADMIN','ACCOUNTADMIN','SYSADMIN','USERADMIN','SECURITYADMIN','PUBLIC');

    /**
      Snowflake System Defined Role Definitions:
       1 - ORGADMIN: Role that manages operations at the organization level.
       2 - ACCOUNTADMIN: Role that encapsulates the SYSADMIN and SECURITYADMIN system-defined roles.
            It is the top-level role in the system and should be granted only to a limited/controlled number of users
            in your account.
       3 - SECURITYADMIN: Role that can manage any object grant globally, as well as create, monitor,
          and manage users and roles.
       4 - USERADMIN: Role that is dedicated to user and role management only.
       5 - SYSADMIN: Role that has privileges to create warehouses and databases in an account.
          If, as recommended, you create a role hierarchy that ultimately assigns all custom roles to the SYSADMIN role, this role also has
          the ability to grant privileges on warehouses, databases, and other objects to other roles.
       6 - PUBLIC: Pseudo-role that is automatically granted to every user and every role in your account. The PUBLIC role can own securable
          objects, just like any other role; however, the objects owned by the role are available to every other
          user and role in your account.

                                +---------------+
                                | ACCOUNTADMIN  |
                                +---------------+
                                  ^    ^     ^
                                  |    |     |
                    +-------------+-+  |    ++-------------+
                    | SECURITYADMIN |  |    |   SYSADMIN   |<------------+
                    +---------------+  |    +--------------+             |
                            ^          |     ^        ^                  |
                            |          |     |        |                  |
                    +-------+-------+  |     |  +-----+-------+  +-------+-----+
                    |   USERADMIN   |  |     |  | CUSTOM ROLE |  | CUSTOM ROLE |
                    +---------------+  |     |  +-------------+  +-------------+
                            ^          |     |      ^              ^      ^
                            |          |     |      |              |      |
                            |          |     |      |              |    +-+-----------+
                            |          |     |      |              |    | CUSTOM ROLE |
                            |          |     |      |              |    +-------------+
                            |          |     |      |              |           ^
                            |          |     |      |              |           |
                            +----------+-----+---+--+--------------+-----------+
                                                 |
                                            +----+-----+
                                            |  PUBLIC  |
                                            +----------+
    **/

/*----------------------------------------------------------------------------------
Step 2 - Role Creation, GRANTS and SQL Variables

 Now that we understand System Defined Roles, let's begin leveraging them to create
 a Test Role and provide it access to the our OPOR data we will deploy our
 initial Snowflake Horizon Governance features against.
----------------------------------------------------------------------------------*/

-- let's use the Useradmin Role to create a Test Role
USE ROLE useradmin;

CREATE OR REPLACE ROLE nlt_test_role
    COMMENT = 'Test role for NLT Lab';


-- now we will switch to Securityadmin to handle our privilege GRANTS
USE ROLE securityadmin;


-- first we will grant ALL privileges on the Development Warehouse to our Sysadmin
GRANT ALL ON WAREHOUSE nlt_dev_wh TO ROLE sysadmin;


-- next we will grant only OPERATE and USAGE privileges to our Test Role
GRANT OPERATE, USAGE ON WAREHOUSE nlt_dev_wh TO ROLE nlt_test_role;

    /**
     Snowflake Warehouse Privilege Grants
      1 - MODIFY: Enables altering any properties of a warehouse, including changing its size.
      2 - MONITOR: Enables viewing current and past queries executed on a warehouse as well as usage
           statistics on that warehouse.
      3 - OPERATE: Enables changing the state of a warehouse (stop, start, suspend, resume). In addition,
           enables viewing current and past queries executed on a warehouse and aborting any executing queries.
      4 - USAGE: Enables using a virtual warehouse and, as a result, executing queries on the warehouse.
           If the warehouse is configured to auto-resume when a SQL statement is submitted to it, the warehouse
           resumes automatically and executes the statement.
      5 - ALL: Grants all privileges, except OWNERSHIP, on the warehouse.
    **/

-- now we will grant USAGE on our Database and all Schemas within it
GRANT USAGE ON DATABASE nlt TO ROLE nlt_test_role;

GRANT USAGE ON ALL SCHEMAS IN DATABASE nlt TO ROLE nlt_test_role;

    /**
     Snowflake Database and Schema Grants
      1 - MODIFY: Enables altering any settings of a database.
      2 - MONITOR: Enables performing the DESCRIBE command on the database.
      3 - USAGE: Enables using a database, including returning the database details in the
           SHOW DATABASES command output. Additional privileges are required to view or take
           actions on objects in a database.
      4 - ALL: Grants all privileges, except OWNERSHIP, on a database.
    **/

-- we are going to test Data Governance features as our Test Role, so let's ensure it can run SELECT statements against our Data Model
GRANT SELECT ON ALL TABLES IN SCHEMA nlt.raw TO ROLE nlt_test_role;
GRANT SELECT ON ALL VIEWS IN SCHEMA nlt.harmonized TO ROLE nlt_test_role;
GRANT SELECT ON ALL VIEWS IN SCHEMA nlt.analytics TO ROLE nlt_test_role;
GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.harmonized TO ROLE nlt_test_role;
GRANT ALL ON FUTURE VIEWS IN SCHEMA nlt.analytics TO ROLE nlt_test_role;

    /**
     Snowflake View and Table Privilege Grants
      1 - SELECT: Enables executing a SELECT statement on a table/view.
      2 - INSERT: Enables executing an INSERT command on a table. 
      3 - UPDATE: Enables executing an UPDATE command on a table.
      4 - TRUNCATE: Enables executing a TRUNCATE TABLE command on a table.
      5 - DELETE: Enables executing a DELETE command on a table.
    **/

-- before we proceed, let's SET a SQL Variable to equal our CURRENT_USER()
SET my_user_var  = CURRENT_USER();


-- now we can GRANT our Role to the User we are currently logged in as
GRANT ROLE nlt_test_role TO USER identifier($my_user_var);


/*----------------------------------------------------------------------------------
Step 3 - Column-Level Security and Tagging = Tag-Based Masking

  The first Governance feature set we want to deploy and test will be Snowflake Tag
  Based Dynamic Data Masking. This will allow us to mask PII data in columns from
  our Test Role but not from more privileged Roles.
----------------------------------------------------------------------------------*/

-- we can now USE the Test Role,  Development Warehouse and Database
USE ROLE nlt_test_role;
USE WAREHOUSE nlt_dev_wh;
USE DATABASE nlt;


-- to begin let's look at some tables with PII data
SELECT * FROM NLT.RAW.OPOR LIMIT 10;


-- woah! there is a couple of PIIs we need to take care of before our users can touch this data.
-- luckily we can use Snowflakes native Tag-Based Masking to do just this

    /**
     A tag-based masking policy combines the object tagging and masking policy features
     to allow a masking policy to be set on a tag using an ALTER TAG command. When the data type in
     the masking policy signature and the data type of the column match, the tagged column is
     automatically protected by the conditions in the masking policy.
    **/

-- first let's create Tags and Governance Schemas to keep ourselves organized and follow best practices
USE ROLE accountadmin;


-- create a Tag Schema to contain our Object Tags
CREATE OR REPLACE SCHEMA tags
    COMMENT = 'Schema containing Object Tags';


-- we want everyone with access to this table to be able to view the tags 
GRANT USAGE ON SCHEMA tags TO ROLE public;


-- now we will create a Governance Schema to contain our Security Policies
CREATE OR REPLACE SCHEMA governance
    COMMENT = 'Schema containing Security Policies';

GRANT ALL ON SCHEMA governance TO ROLE sysadmin;


-- next we will create one Tag for PII that allows these values: NAME, PHONE_NUMBER, EMAIL, BIRTHDAY
-- not only will this prevent free text values, but will also add the selection menu to Snowsight
CREATE OR REPLACE TAG tags.nlt_pii
    ALLOWED_VALUES 'ADDRESS'
    COMMENT = 'Tag for PII, allowed values are: ADDRESS';


-- with the Tags created, let's assign them to the relevant columns in the OPOR table
ALTER TABLE nlt.raw.opor
    MODIFY COLUMN 
    address SET TAG tags.nlt_pii = 'ADDRESS',
    address2 SET TAG tags.nlt_pii = 'ADDRESS';

-- now we can use the TAG_REFERENCE_ALL_COLUMNS function to return the Tags associated with OPOR table
SELECT
    tag_database,
    tag_schema,
    tag_name,
    column_name,
    tag_value
FROM TABLE(information_schema.tag_references_all_columns
    ('nlt.raw.opor','table'));

    /**
     With our Tags in place we can now create our Masking Policies that will mask data for all but privileged Roles.

     We need to create 1 policy for every data type where the return data type can be implicitly cast
     into the column datatype. We can only assign 1 policy per datatype to an individual Tag.
    **/

-- create our String Datatype Masking Policy
  --> Note: a Masking Policy is made of standard conditional logic, such as a CASE statement
CREATE OR REPLACE MASKING POLICY governance.nlt_pii_string_mask AS (val STRING) RETURNS STRING ->
    CASE
        -- these active roles have access to unmasked values 
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN','SYSADMIN')
            THEN val 
        -- if a column is tagged with NLT_PII : PHONE_NUMBER 
        -- then mask everything but the first 3 digits   
        WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN('TAGS.NLT_PII') = 'PHONE_NUMBER'
            THEN CONCAT(LEFT(val,3), '-***-****')
        -- if a column is tagged with NLT_PII : EMAIL  
        -- then mask everything before the @ sign  
        WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN('TAGS.NLT_PII') = 'EMAIL'
            THEN CONCAT('**~MASKED~**','@', SPLIT_PART(val, '@', -1))
        -- all other conditions should be fully masked   
    ELSE '**~MASKED~**' 
END;

-- now we are able to use an ALTER TAG statement to set the Masking Policies on the PII tagged columns
ALTER TAG tags.nlt_pii SET
    MASKING POLICY governance.nlt_pii_string_mask;


-- with Tag Based Masking in-place, let's give our work a test using our Test Role and Development Warehouse
USE ROLE nlt_test_role;
USE WAREHOUSE nlt_dev_wh;

SELECT * FROM NLT.RAW.OPOR LIMIT 10;


-- the masking is working! let's also check the downstream Harmonized layer View that leverages this table
USE ROLE SYSADMIN;
CREATE OR REPLACE VIEW NLT.HARMONIZED.OPOR_ADDRESS_V
AS SELECT ADDRESS,ADDRESS2 FROM NLT.RAW.OPOR;

USE ROLE nlt_test_role;
SELECT * FROM NLT.HARMONIZED.OPOR_ADDRESS_V LIMIT 10;

/*----------------------------------------------------------------------------------
Step 4 - Row-Access Policies

 Happy with our Tag Based Dynamic Masking controlling masking at the column level,
 we will now look to restrict access at the row level for our test role.

 Within our OPOR table, our role should only see Customers who have a specific cardcode

 Thankfully, Snowflake Horizon has another powerful native Governance feature that can
 handle this at scale called Row Access Policies. For our use case, we will leverage
 the mapping table approach.
----------------------------------------------------------------------------------*/

 -- to start, our Accountadmin will create our mapping table including Role and Cardcode Permissions columns
 -- we will create this in the Governance Sschema, as we don't want this table to be visible to others.
USE ROLE accountadmin;

CREATE OR REPLACE TABLE governance.row_policy_map
    (role STRING, cardcode_permissions STRING);


-- with the table in place, we will now INSERT the relevant Role to Cardcode Permissions mapping to ensure
-- our Test role only can see cardcode V1010 
INSERT INTO governance.row_policy_map
    VALUES ('NLT_TEST_ROLE','V1010'); 


-- now that we have our mapping table in place, let's create our Row Access Policy

    /**
     Snowflake supports row-level security through the use of Row Access Policies to
     determine which rows to return in the query result. The row access policy can be relatively
     simple to allow one particular role to view rows, or be more complex to include a mapping
     table in the policy definition to determine access to rows in the query result.
    **/

CREATE OR REPLACE ROW ACCESS POLICY governance.customer_cardcode_row_policy
    AS (CARDCODE STRING) RETURNS BOOLEAN ->
       CURRENT_ROLE() IN ('ACCOUNTADMIN','SYSADMIN') -- list of roles that will not be subject to the policy
        OR EXISTS -- this clause references our mapping table from above to handle the row level filtering
            (
            SELECT rp.role
                FROM governance.row_policy_map rp
            WHERE 1=1
                AND rp.role = CURRENT_ROLE()
                AND rp.cardcode_permissions = CARDCODE
            )
COMMENT = 'Policy to limit rows returned based on mapping table of ROLE and CARDCODE: governance.row_policy_map';


 -- let's now apply the Row Access Policy to our CARDCODE column in the OPOR table
ALTER TABLE NLT.RAW.OPOR
    ADD ROW ACCESS POLICY governance.customer_cardcode_row_policy ON (cardcode);

    
-- with the policy successfully applied, let's test it using the Test Role
USE ROLE nlt_test_role;
SELECT * FROM NLT.RAW.OPOR;
