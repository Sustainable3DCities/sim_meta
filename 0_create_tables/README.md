# Creating and initialising sim_meta tables

This folder contains indicatory SQL-scripts for creating and initialising the
tables storing output from various types of simulations in the sim_meta database
schema within 3DCityDB.
<br>
<br>

## Organisation
The "0_sql_create_table" folder contains SQL-scripts for creating the table 
corresponding to every simulation type. 

The "1_sql_table_unique_ids" folder contains an indicatory SQL-script used to 
create the unique IDs that are required in the table storing the simulation output
geometries and values.

The "2_sql_table_geom" folder contains an indicatory SQL-script used to 
create the geometry for the 3D points storing simulation output in the table 
storing the simulation output geometries and values.
<br>
<br>

## Technical requirements
These SQL-scripts were developed for 3DCityDB v.4.1 running on
pgAdmin 4 version 8.12 with PostgreSQL 17.0 and PostGIS 3.5.0.
<br>
<br>

## License and Usage
This replication package is shared for peer-review purposes.
Upon formal publication of the associated manuscript, the code 
will be officially released under the BSD-3-Clause-License.
<br>
<br>
