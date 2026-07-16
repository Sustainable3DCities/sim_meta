/*

        *** CREATE USER AND ADD PERMISSIONS ***

    This SQL-script is used to create a new user and assign
    this user with permissions to allow the execution of a 
    Python-script connecting to the database.

    Note that it is up to the db admin to restrict or increase
    the permissions associated with every user.

*/

--Create user (for Python code)
CREATE USER ENTER_USERNAME WITH PASSWORD 'ENTER_PASSWORD';

--Grant access:
GRANT CONNECT ON DATABASE "ENTER_DB_NAME" TO ENTER_USERNAME;


--Grant table permissions:
--GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sim_meta, citydb TO ENTER_USERNAME;
GRANT ALL ON ALL TABLES IN SCHEMA citydb TO ENTER_USERNAME;
GRANT ALL ON ALL TABLES IN SCHEMA sim_meta TO ENTER_USERNAME;

GRANT ALL ON SCHEMA citydb TO ENTER_USERNAME;
GRANT ALL ON SCHEMA sim_meta TO ENTER_USERNAME;