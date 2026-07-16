# Simulation output - Irregular point grid

The files contained in this folder are used to implement a workflow for mapping 3D simulation data onto building surfaces within a 3DCityDB database. The simulation data are stored in an irregular point grid format.
<br>
<br>

## Workflow overview

- **Database setup:** An SQL-script creates a database user and configures access rights.
- **Parameter calculation:** A Python script calculates the 3D Affine transformation parameters based on the vertex points of the target building wall surface.
- **Interpolation & rasterization:** An SQL script uses these parameters to convert the wall and 3D points into rasters. Because the grid is irregular, it uses Inverse Distance Weighting (IDW) interpolation to fill gaps and applies RGB colour-coding intervals to represent different simulation value ranges.
- **Texture mapping:** A final SQL script saves the coloured raster as a texture in the 3DCityDB database and links it to its corresponding building wall surface.

