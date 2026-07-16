# Creating texture appearances from sim out points in regular/irregular grids

This folder contains subfolders with indicatory SQL-scripts for creating rasters
based on regular/irregular sim out point grids and assigning them as textures to
the wall surface they correspond to.
<br>
<br>


## Organisation
The "0_regular_point_grid" folder contains:

1. SQL-script for creating a DB user and assigning permissions
2. Python-script that computes Affine transformation parameters based on all 3D
   sim out points that are part of a regular grid and correspond to the same 
   wall surface.
3. SQL-script that creates rasters by applying the Affine transformation parameters
   from step 2 to the sim out 3D points as well as on their corresponding wall surface.
   Every raster is processed to include RGB-colors, where every color represents a 
   specific sim out value interval.
4. SQL-script for taking a raster (created in step 3), saving it as a texture in citydb
   and relating this texture to the corresponding wall surface.

<br>
<br>

The "1_irregular_point_grid" folder contains:

1. SQL-script for creating a DB user and assigning permissions
2. Python-script that computes Affine transformation parameters based on the vertex points 
   of a wall surface that is associated with sim out points.
3. SQL-script that creates rasters by applying the Affine transformation parameters
   from step 2 to the wall surface itself as well as to the sim out 3D points corresponding     
   to it. As the grid is irregular, we implement an Inverse distance weighting (IDW)
   interpolation with a high k-factor to fill the gaps. 
   Every raster is processed to include RGB-colors, where every color represents a 
   specific sim out value interval.
4. SQL-script for taking a raster (created in step 3), saving it as a texture in citydb
   and relating this texture to the corresponding wall surface.
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
