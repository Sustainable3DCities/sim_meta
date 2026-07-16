# Linking simulation output from regular/irregular point grids to CityGML WallSurfaces

This folder contains subfolders with indicatory SQL-scripts for linking 3D point simulation output (stored as regular/irregular point grids in the sim_meta database schema within 
3DCityDB) to CityGML WallSurface geometries stored in the citydb database schema within 
the same database.
 
There are also Python-scripts that compute Affine transformation parameters based on
3D sim out point geometries (when sim output is stored in 3D regular point grids) or 
based on the vertex points of their corresponding wall surfaces (when sim output is 
stored in irregular 3D point grids). 

Additionally, there are SQL-scripts that create rasters based on simulation out
3D point geometries that have been converted to 2D by applying an Affine transformation.

Finally, there are SQL-scripts that create texture appearances from rasters and apply 
them to their corresponding WallSurface geometries in citydb. 
<br>
<br>


## Organisation
The "0_linking_sim_out_to_wallsurfaces" folder contains SQL-scripts for finding the 
wall surface closest to every 3D point simulation output geometry and storing
its corresponding unique identifier (CITYOBJECT.GMLID) to the corresponding field
in the simulation output table (Geom_XXXX).

The "1_creating_texture_appearances_for_wallsurfaces" folder contains indicatory SQL-scripts for creating texture appearances (from both regular and irregular sim out point grids) and associating every wall surface with a texture to its geometry.
<br>
<br>

## Technical requirements
These SQL-scripts were developed for 3DCityDB v.4.1 running on
pgAdmin 4 version 8.12 with PostgreSQL 17.0 and PostGIS 3.5.0.
Python 3.8.8 was used for the Python-scripts.
<br>
<br>


## License and Usage
This replication package is shared for peer-review purposes.
Upon formal publication of the associated manuscript, the code 
will be officially released under the BSD-3-Clause-License.
<br>
<br>
