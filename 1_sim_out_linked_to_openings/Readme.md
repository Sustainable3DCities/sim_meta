# Linking simulation output to CityGML openings (windows)

This folder contains indicatory SQL-scripts for linking 3D point simulation output
from the sim_meta database schema within 3DCityDB to CityGML geometries of openings
(windows) stored in citydb database schema within the same database. There are also
SQL-scripts that assign an X3D color appearance color to every opening/window geometry
depending on the value of the 3D point sim output geometry the window is linked to.
<br>
<br>

## Organisation
The "0_linking_sim_out_to_openings" folder contains SQL-scripts for finding the 
opening/window closest to every 3D point simulation output geometry and storing
its corresponding unique identifier (CITYOBJECT.GMLID) to the corresponding field
in the simulation output table (Geom_XXXX).

The "1_creating_appearances_for_openings" folder contains an indicatory SQL-scripts
for creating a separate appearance per simulation type and associating every opening/
window with a X3D color to its geometry depending on the value of the simulation
output point it is closest to.
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
