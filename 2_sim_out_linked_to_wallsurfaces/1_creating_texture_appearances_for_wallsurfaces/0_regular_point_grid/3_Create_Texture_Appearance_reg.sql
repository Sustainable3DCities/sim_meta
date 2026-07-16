/*

*** CREATE TEXTURE APPEARANCE FOR WALLSURFACE FROM SIM OUT IN REGULAR 3D POINT GRIDS ***

This SQL-script creates CityGML texture appearances from rasters produced based on sim out
points organised in regular 3D point grids and stores them in citydb.

More in particular, this achieved by implementing the following steps:

1. Create a separate appearance theme for storing the outputs of this type of simulation.
2. Create PNG-file of raster with sim out (produced in 2_Create_raster_from_sim_out_pts_reg_grid.sql) 
   and store it in the TEX_IMAGE table.
3. Update the SURFACE_DATA table to linkt the TEX_IMAGE TEXTURE added in step 1 to it.
4. Update APPEAR_TO_SURFACE_DATA table to link the texture to an appearance theme 
   (e.g., AIrr After Densification)
5. Update the TEXTUREPARAM table to link the texture to a citydb geometry (here WallSurface)
   based on its GMLIDgeometric.


REQUIREMENTS:
i.  Table storing the sim out raster produced in 2_Create_raster_from_sim_out_pts_reg_grid.sql
ii. Surface geometry GMLID of wall surface the raster corresponds to.

*/



-- Step 1 --
--Create an appearance theme for storing sim output for this particular type of simulation
--(Here: Total Annual Irradiance: AIrr) and scenario (e.g., before densification BD or after
--densification AD)

--AIrr simulation output (LOD2 WallSurface) BD
INSERT INTO citydb.APPEARANCE
VALUES (2, NULL, NULL, NULL, NULL, NULL,
'AIrr_wallsurface_LOD2_BD', NULL, NULL);

-- Set UUID for AIrr-theme:
UPDATE citydb.APPEARANCE
SET gmlid = CONCAT('AIrr_LOD2_BD_theme_', uuid_generate_v4())
WHERE citydb.APPEARANCE.ID = 2;


--AIrr simulation output (LOD2 WallSurface) AD
INSERT INTO citydb.APPEARANCE
VALUES (3, NULL, NULL, NULL, NULL, NULL,
'AIrr_wallsurface_LOD2_AD', NULL, NULL);

-- Set UUID for AIrr-theme:
UPDATE citydb.APPEARANCE
SET gmlid = CONCAT('AIrr_LOD2_AD_theme_', uuid_generate_v4())
WHERE citydb.APPEARANCE.ID = 3;



-- Step 2 --
--Add PNG-file with simulation ouput to TEX_IMAGE table along with attribute values
--for the image's ID, URI, and mime type:
INSERT INTO citydb.TEX_IMAGE(
	id,
	tex_image_uri,
	tex_image_data,
	tex_mime_type
)

SELECT 
	(SELECT MAX(TEX_IMAGE.ID)+1 FROM TEX_IMAGE) AS id,
	'WS_LOD2_AIrr_AD_Fx'|| (SELECT MAX(TEX_IMAGE.ID)+1 FROM TEX_IMAGE)::TEXT ||'.png' AS tex_image_uri,
	ST_AsPNG(r.rgb_rast) AS tex_image_data,
	'image/png' AS tex_mime_type

FROM AIrr_raster r
WHERE r.rid = 1;


--Delete the temporary help tables:
DROP TABLE AIrr_raster;

-- ----------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------



--STEP 3--
--Update the SURFACE_DATA table
INSERT INTO citydb.SURFACE_DATA
VALUES((SELECT MAX(SURFACE_DATA.ID)+1 FROM SURFACE_DATA), 
CONCAT('surfacedata', uuid_generate_v4()), NULL, 
'WS_LOD2_AIrr_AD_f'|| (SELECT MAX(SURFACE_DATA.ID)+1 FROM SURFACE_DATA)::TEXT, 
NULL, 'Texture for LOD2 WallSurface with AIrr output for AD scenario',
1, 54, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
(SELECT MAX(TEX_IMAGE.ID) FROM TEX_IMAGE)::INT, NULL, 'none', NULL, NULL, NULL, NULL);

-- ----------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------



--STEP 4--
--Update APPEAR_TO_SURFACE_DATA table to link the texture to a theme:

--AIrr textures (APPEARANCE ID for AIrr sim output - 2=BD, 3=AD): 
--Where BD (Before Densification) & AD (After Densification)
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES ((SELECT MAX(SURFACE_DATA.ID) FROM SURFACE_DATA)::INT, 3); --SURFACE_DATA.ID (TEXTURE ID), APPEARANCE.ID (THEME ID for AIrr AD)

-- ----------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------



--STEP 5--
--Update TEXTUREPARAM table to link the texture to the citydb wallsurface geometry.
--This example assumes that the wallsurface consists of one rectangular geometry.
INSERT INTO citydb.TEXTUREPARAM(
	surface_geometry_id,
	is_texture_parametrization,
	world_to_texture,
	texture_coordinates,
	surface_data_id
)
VALUES(SELECT ID
FROM SURFACE_GEOMETRY 
WHERE root_id IN (SELECT root_id from SURFACE_GEOMETRY WHERE GMLID = 'ID_87594c9e-6321-4195-b3e1-8eacd172fdd6')
AND GEOMETRY IS NOT NULL,
1, NULL, 
ST_GeomFromText('POLYGON((0.0 0.0, 1.0 0.0, 1.0 1.0, 0.0 1.0, 0.0 0.0))'), 
(SELECT MAX(SURFACE_DATA.ID) FROM SURFACE_DATA)::INT);

-- ----------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------


--In case you need to adjust the orientation of the texture
--as it is attached on the citydb geometry:

--UPDATE TEXTUREPARAM
--SET TEXTURE_COORDINATES =
--ST_GeomFromText('POLYGON((0.0 0.0, 0.0 1.0, 1.0 1.0, 1.0 0.0, 0.0 0.0))')
--WHERE SURFACE_GEOMETRY_ID = 82482 AND
--SURFACE_DATA_ID = 15

