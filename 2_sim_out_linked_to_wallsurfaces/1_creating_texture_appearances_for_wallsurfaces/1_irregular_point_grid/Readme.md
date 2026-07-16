# Simulation output - Irregular point grid

The files contained in this folder are used to implement a workflow for mapping 3D simulation data onto building surfaces within a 3DCityDB database. The simulation data are stored in an irregular point grid format.
<br>
<br>

## Workflow overview

- **Database setup:** A SQL-script creates a database user and configures the necessary access permissions.
- **Parameter calculation:** A Python script calculates the 3D Affine transformation parameters from simulation points on a regular grid corresponding to a building wall surface.
- **Rasterization & appearance settings (colouring):** A SQL script uses these parameters to convert the 3D points and wall geometry into rasters, applying RGB colour intervals to represent different simulation value ranges.
- **Texture mapping:** A final SQL scriot saves the coloured rasters as textures in the 3DCityDB database and links them to their corresponding building wall surfaces.

