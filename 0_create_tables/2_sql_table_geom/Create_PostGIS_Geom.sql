/*

					COMPUTE PostGIS POINTZ GEOMETRY
	
	This SQL-query reads the imported x-, y-, z-coordinates for every
	3D point simulation output and along with the CRS (here EPSG:3008)
	returns the corresponding PostGIS POINTZ geometry. 

	Note that the CRS of the imported points should match the CRS of the
	database.

	If we choose to store multiple outputs of the same simulation type in
	the same table, it is important to distinguish newly imported raw data
	from already existing. In order to only execute the geometry-calculation
	for the newly imported raw data, we add a condition for the simulation ID,
	which we added in a previous step just after importing the raw data to the
	table. 
	
*/



-- Compute PostGIS point geometry from the imported x-, y-, and z-coordinates:

UPDATE sim_meta.Geom_OA
SET geom = ST_SetSRID(ST_MakePoint(coord_x, coord_y, coord_z), 3008)
WHERE simulationID = 'OA_malmo_bellevue_DpXXXXX_20230401_v1';



