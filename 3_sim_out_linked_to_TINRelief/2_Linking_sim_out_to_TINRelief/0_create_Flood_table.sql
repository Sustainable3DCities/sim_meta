/*

			*** SQL-code FOR CREATING SIM OUT TABLE ***
	
	This SQL-query shows how to create a table for storing the 
	raw geometric data for a simulation (e.g., Flood - Water depth) 
	resulting in the production of 3D points.

	Note that the Coordinate Reference System (CRS) and 
	Vertical Coordinate Reference System (VCRS) of the 
	3D points must match the corresponding CRS & VCRS
	of the database in 3DCityDB.

	The fields/columns Identifier & IdentifierCodespace are only
	applicable for CityGML 3.0 models and should remain empty for
	CityGML 2.0 models.

	The process is completed in 4 steps:
	1. Create the table that will store the raw flood water depth data
	2. Import the raw sim output to the table created in step 1. Note
	   that every sim out point must include its corresponding x/y/z
	   coords in separate columns expressed in the same CRS/VCRS as 
	   the one used in the 3DCityDB database.
	3. Add a unique simulation ID to the table.
	4. Compute PostGIS point geometry (POINTZ) from the imported x-, y-, 
	   and z-coordinates.

*/


-- STEP 1 --
--Create Flood (water depth) table:

CREATE TABLE sim_meta.Geom_Flood
(
	Geom_ID character varying(255),
	coord_x double precision,
	coord_y double precision,
	coord_z double precision,
	Value numeric,
	cityObjectIdentifier character varying(255),
	cityObjectGMLID character varying(255),
	surfaceGeometryID bigint,
	simulationID character varying(255),
	geom geometry(PointZ, 3008)
);



-- STEP 2 --
--Import csv-file with Flood sim output to newly created table



-- STEP 3 --
-- Add simulation ID to table

UPDATE sim_meta.Geom_Flood
SET simulationID = 'Flood_malmo_bellevue_DpXXXXX_20240630_v1_60min'
WHERE simulationID IS NULL AND
geom_id LIKE 'flood_malmo_bellevue_DpXXXXX_20240201_v1c_p_%';



-- STEP 4 --
-- Compute point geometry from the imported x-, y-, and z-coordinates:

UPDATE sim_meta.Geom_Flood
SET geom = ST_SetSRID(ST_MakePoint(coord_x, coord_y, coord_z), 3008)
WHERE simulationID = 'Flood_malmo_bellevue_DpXXXXX_20240630_v1_60min';



/*
-- STEP 5 --
-- Store details of the closest TIN triangle to every sim output point:
WITH TIN_triangle_geom AS (
	SELECT	SURFACE_GEOMETRY.ID AS sg_id, 
			SURFACE_GEOMETRY.GMLID AS sg_gmlid, 
			SURFACE_GEOMETRY.GEOMETRY AS sg_geom,
			CITYOBJECT.ID AS co_id, 
			CITYOBJECT.GMLID AS co_gmlid
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	WHERE SURFACE_GEOMETRY.GMLID LIKE 'TIN_TRI_%'
)


SELECT	t.sg_gmlid, t.co_gmlid,
		ST_3DDistance(t.sg_geom, ST_Force3DZ('POINT(10 20 0)'::geometry)) AS dist_3D 
FROM	TIN_triangle_geom t
CROSS JOIN LATERAL (SELECT 'POINT(10 20)'::geometry AS p2d) p
ORDER BY 
	ST_Intersects(ST_Force2D(t.geom), p.p2d) DESC,
	ST_3DDistance(t.geom, ST_Force3DZ(p.p2d)) ASC
LIMIT 1;

*/

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'citydb.SURFACE_GEOMETRY'




