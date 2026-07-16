/*

			*** CREATE TIN RELIEF FROM DEM POINTS ***

The following SQL-queries are used to create a TIN Relief CityGML object
using 3D point geometries derived from a Digital Elevation Model (DEM) 
with 1m spatial resolution.

The process is excuted in several steps:

1. Create a temporary table to store the DEM points
2. Import to table created in step 1 the 3D points derived from 
   the DEM (x-, y-, and z-coords are stored in separate columns
   in the same CRS as the one used in the database)
3. Create PointZ PostGIS geometries from the x-, y-, and z-coords
   of every point.
4. Create TIN from DEM points using Delaunay triangulation and
   store it in 3DCityDB as a TINRelief.

*/



-- STEP 1 --
--Create DEM point table:

CREATE TABLE sim_meta.DEM_point
(
	pointid character varying(255),
	coord_x double precision,
	coord_y double precision,
	coord_z double precision,
	geom geometry(PointZ, 3008)
);



-- STEP 2 --
--Import csv-file with DEM points to newly created table



-- STEP 3 --
-- Compute point geometry from the imported x-, y-, and z-coordinates:

UPDATE sim_meta.DEM_point
SET geom = ST_SetSRID(ST_MakePoint(coord_x, coord_y, coord_z), 3008);



-- STEP 4 --
--Create TIN from DEM points and store it in 3DCityDB

--Filter the DEM points to study area
WITH FilteredPoints AS (
	SELECT ST_Collect(ST_Force3D(geom)) AS collected_points
	FROM DEM_point
	WHERE ST_Within(geom, ST_MakeEnvelope(116874.00, 117165.00, 6162053.00, 6162360.00, 3008))-- Xmin, Xmax, Ymin, Ymax 
),


--Generate TIN triangles from the DEM points
tin_data AS (
	SELECT ST_DelaunayTriangles(collected_points, 0, 0) AS geom
	FROM FilteredPoints
),


--Dump the collection of Delaunay triangles to individual polygons
--ST_Dump() correctly handles both Collections and PolyhedralSurfaces
--by extracting their faces.
--Filter out the Delaunay triangles that are not polygons
--This makes it possible to calculate the aggregate envelope
geometry_dump AS (
	SELECT ST_SetSRID(ST_Force3D(dumped.geom), 3008)::geometry AS tri_geom
	FROM tin_data,
	LATERAL ST_Dump(ST_CollectionExtract(tin_data.geom, 3)) AS dumped
	WHERE ST_GeometryType(dumped.geom) = 'ST_Polygon'
),

--Calculate the 3D Envelope before inserting into CITYOBJECT
envelope_calc AS (
	SELECT ST_SetSRID(citydb.box2envelope(ST_3DExtent(tri_geom)), 3008) as box
	FROM geometry_dump
),

--Create an entry in CITYOBJECT for the ReliefFeature
relief_cityobj AS (
	INSERT INTO citydb.CITYOBJECT (ID, OBJECTCLASS_ID, GMLID, NAME, DESCRIPTION, ENVELOPE, CREATION_DATE, LAST_MODIFICATION_DATE, UPDATING_PERSON)
	SELECT
		nextval('citydb.cityobject_seq'),
		14,
		'RELIEF_FEAT_' || gen_random_uuid(),
		'DTM_of_Bellevue',
		'TIN-based DTM of Bellevue district Malmo',
		box,
		NOW(),
		NOW(),
		'postgres'
	FROM envelope_calc
	RETURNING ID
),

-- Add an entry to the ReliefFeature table:
relief_feat AS (
	INSERT INTO citydb.relief_feature (ID, OBJECTCLASS_ID, LOD)
	SELECT ID, 14, 2 FROM relief_cityobj
	RETURNING ID
),

--Add an entry in the CITYOBJECT table for the TINRelief component (one for every TIN-triangle):
--Create one TINRelief Component (the container for all triangles)
comp_cityobj AS (
	INSERT INTO citydb.CITYOBJECT (ID, OBJECTCLASS_ID, GMLID, NAME, DESCRIPTION, ENVELOPE, CREATION_DATE, LAST_MODIFICATION_DATE, UPDATING_PERSON)
	SELECT
		nextval('citydb.cityobject_seq'), --ID
		16, --OBJECTCLASS_ID
		'TIN_RELIEF_' || gen_random_uuid(), --GMLID
		'DTM_Component', --NAME
		'TIN-component of Bellevue DTM', --DESCRIPTION
		box, --ENVELOPE
		NOW(), --CREATION_DATE
		NOW(), --LAST_MODIFICATION_DATE
		'postgres' --UPDATING_PERSON
	FROM envelope_calc
	RETURNING ID
),

--Create an entry for every entry in ReliefComponent 
--The ID is a FK to the CITYOBJECT.ID of the corresponding TIN-triangle. 
relief_comp AS (
	INSERT INTO citydb.relief_component (ID, OBJECTCLASS_ID, LOD)
	SELECT ID, 16, 2 FROM comp_cityobj
	RETURNING ID
),

--Link the ReliefComponents to the ReliefFeature in the
--RELIEF_FEAT_TO_REL_COMP table
feat_to_comp AS (
	INSERT INTO citydb.RELIEF_FEAT_TO_REL_COMP (RELIEF_FEATURE_ID, RELIEF_COMPONENT_ID)
	SELECT rf.ID, rc.ID 
	FROM relief_feat rf CROSS JOIN relief_comp rc
	--RETURNING RELIEF_FEATURE_ID
),

--Create one root Surface Geometry for the entire DTM "tile".
--This acts as the "parent" in the SURFACE_GEOMETRY tree.
root_sg AS (
	INSERT INTO citydb.SURFACE_GEOMETRY(
		ID, GMLID, PARENT_ID, ROOT_ID,
		IS_COMPOSITE, IS_SOLID, 
		IS_TRIANGULATED, IS_REVERSE, IS_XLINK,
		GEOMETRY, CITYOBJECT_ID)
	
	SELECT 
		sub.val, --ID
		'TIN_ROOT_' || gen_random_uuid(), --Generate unique GMLID for parent
		NULL, --PARENT_ID
		sub.val, --ROOT_ID same as ID 
		0, 0, 1, 0, 0, -- IS_TRIANGULATED = 1, other flags = 0
		NULL, --Geometry
		sub.ID --CITYOBJECT_ID (FK to CITYOBJECT)
	FROM (SELECT nextval('citydb.surface_geometry_seq') AS val, ID FROM comp_cityobj) AS sub
	RETURNING ID
),

--Insert all triangles as children of the ONE root
--Every TIN-triangle gets a unique ID
child_geoms AS (
	INSERT INTO citydb.SURFACE_GEOMETRY(
		ID, GMLID, PARENT_ID, ROOT_ID,
		IS_COMPOSITE, IS_SOLID, 
		IS_TRIANGULATED, IS_REVERSE, IS_XLINK,
		GEOMETRY, CITYOBJECT_ID)

	SELECT 
		nextval('citydb.surface_geometry_seq'), --ID
		'TIN_TRI_' || gen_random_uuid(), --Generate unique GMLID for child
		rs.ID, --PARENT_ID - points to the single root created in root_sg
		rs.ID, --ROOT_ID
		0, 0, 0, 0, 0, --All flags = 0
		gd.tri_geom, --Geometry
		cc.ID --Points to the single component created in comp_cityobj

	FROM geometry_dump gd, root_sg rs, comp_cityobj cc
	RETURNING ID, GEOMETRY
)

--Connect the TINRelief table to the geometry root
INSERT INTO citydb.TIN_RELIEF (ID, OBJECTCLASS_ID, SURFACE_GEOMETRY_ID)
SELECT 
	cc.ID, 
	16, 
	rs.ID
FROM comp_cityobj cc, root_sg rs;
