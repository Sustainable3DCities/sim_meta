# Linking simulation output to TINRelief



This repository contains SQL-scripts and Python code for creating
simulation output tables in the sim_meta database schema, linking
them to CityGML TINRelief geometries in citydb and creating appearances 
for them as described in the manuscript titled "Storing and visualizing
simulation output linked to semantic 3D city models in a FAIR framework".
More in particular, the repository contains code for:

1. creating a TINRelief from DEM points.
2. creating appearances for TINRelief that are associated with a specific
   simulation type and scenario (e.g., before densification - BD, after
   densification - AD) in the tables of the 3DCityDB citydb database schema. 
3. linking simulation output to CityGML TINRelief & associating its
   geometries with the correct appearance reflecting the sim out value.
4. importing the exported 3D city model from 3DCityDB (KML/COLLADA) in Blender.
<br>
<br>

## Organisation
The "0_Create_TIN_relief" folder contains SQL-scripts for creating a TINRelief
from 3D points derived from a DEM (Digital Elevation Model). 

The "1_Creating_appearances_for_TINRelief" folder contains indicatory SQL-scripts 
for creating appearances to store simulation output corresponding to ground surfaces 
(e.g., flood, wind comfort) that can be linked to a CityGML TINRelief utilising X3D 
colour appearances.

The "2_Linking_sim_out_to_TINRelief" folder contains indicatory SQL-scripts
used for linking simulation output (e.g., flood) to CityGML TINRelief surfaces
and storing the corresponding identifiers in the simulation output table for 
FAIR purposes.

The "3_Visualize_in_Blender" folder contains Python code for importing the exported
3D city model (including the TINRelief and its appearance) in Blender.
<br>
<br>

## Technical requirements
These SQL-scripts were developed for 3DCityDB v.4.x running on
pgAdmin 4 version 8.12 with PostgreSQL 17.0 and PostGIS 3.5.0.
The Python code for Blender version: 3.0.1 was developed using Python version 3.9.7
(inside Blender).
<br>
<br>

## License and Usage
This replication package is shared for peer-review purposes.
Upon formal publication of the associated manuscript, the code 
will be officially released under the BSD-3-Clause-License.
<br>
<br>
