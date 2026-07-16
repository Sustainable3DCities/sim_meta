/*

            *** CREATE APPEARANCE FOR TINRelief ***
    
The SQL-queries below create a separate appearance theme for the simulation
type (e.g., Flood - Water Depth) as well as set different surface data 
X3D colors per simulation output value interval. These colors will then be
assigned to every TINRelief geometry (triangles) based on the value of the 
sim out point it has been linked to. This way CityGML will implicitly represent 
simulation output that will be visible when ordinary exports of the db in
CityGML or KML/COLLADA will be rendered with colors in visualization software 
supporting CityGML or KML/COLLADA.

Below we list how the objectives detailed above are realised:

1. Create a separate APPEARANCE theme for the particular simulation type 
   (here Flood: Water Depth)
2. Create one entry per sim out value interval in the SURFACE_DATA table
3. Link the APPEARANCE theme to the value intervals in SURFACE_DATA 
   by adding them as entries in the APPEAR_TO_SURFACE_DATA table

Note that in order to be able to create UUIDs (globally unique identifiers),
you need to have activated the corresponding extension for your postgresql
database using the command: 

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

*/



-- STEP 1 --
--Create a new appearance theme for the different
--simulation type (e.g., flood) and scenario 
--(e.g., before densification - BD, after densification - AD)

--Flood simulation output (Terrain) BD
INSERT INTO citydb.APPEARANCE
VALUES (6, NULL, NULL, NULL, NULL, NULL,
'Flood_LOD2_BD', NULL, NULL);

--Set a unique ID (UUID) as the GMLID-value for every row
-- Set UUID for Flood-theme (BD scenario):
UPDATE citydb.APPEARANCE
SET gmlid = CONCAT('Flood_LOD2_BD_theme_', uuid_generate_v4())
WHERE citydb.APPEARANCE.ID = 6;


--Flood simulation output (Terrain) AD
INSERT INTO citydb.APPEARANCE
VALUES (7, NULL, NULL, NULL, NULL, NULL,
'Flood_LOD2_AD', NULL, NULL);

--Set a unique ID (UUID) as the GMLID-value for every row
-- Set UUID for Flood-theme (AD scenario):
UPDATE citydb.APPEARANCE
SET gmlid = CONCAT('Flood_LOD2_AD_theme_', uuid_generate_v4())
WHERE citydb.APPEARANCE.ID = 7;



-- STEP 2 --
--Add a separate new row in the SURFACE_DATA table for every 
--value interval included in the new simulation output type
--(The below example corresponds to water depth of floods)

--Colors for TIN triangles without flood sim output:
INSERT INTO citydb.SURFACE_DATA
VALUES (90, NULL, NULL, 'water_depth_null', NULL, 'RGB-color for TIN triangle with no water depth value (value=NULL)',
1, 53, NULL, NULL, NULL, NULL, '1.0 1.0 1.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--Colors for TIN triangles with flood sim output:
INSERT INTO citydb.SURFACE_DATA
VALUES (91, NULL, NULL, 'water_depth_interval_1', NULL, 'RGB-color for TIN triangles whose water depth value is: WD < 0.1 m',
1, 53, NULL, NULL, NULL, NULL, '0.0 0.2 0.5', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (92, NULL, NULL, 'water_depth_interval_2', NULL, 'RGB-color for TIN triangles whose water depth value is: 0.1 m >= WD < 0.3 m',
1, 53, NULL, NULL, NULL, NULL, '0.0 0.3 0.7', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (93, NULL, NULL, 'water_depth_interval_3', NULL, 'RGB-color for TIN triangles whose water depth value is: 0.3 m >= WD < 0.6 m',
1, 53, NULL, NULL, NULL, NULL, '0.0 0.4 1.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (94, NULL, NULL, 'water_depth_interval_4', NULL, 'RGB-color for TIN triangles whose water depth value is: 0.6 m >= WD < 1.2 m',
1, 53, NULL, NULL, NULL, NULL, '0.4 0.7 1.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (95, NULL, NULL, 'water_depth_interval_5', NULL, 'RGB-color for TIN triangles whose water depth value is: WD >= 1.2 m',
1, 53, NULL, NULL, NULL, NULL, '0.8 0.9 1.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--Add a UUID as GMLID for all newly created entries:
UPDATE citydb.SURFACE_DATA
SET gmlid = CONCAT('surfacedata', uuid_generate_v4())
WHERE ID > 89 AND ID < 96;



-- STEP 3 --
--Link the newly created entries in the SURFACE_DATA table to 
--their corresponding simulation type theme created in step 1,
--by adding new rows in the APPEAR_TO_SURFACE_DATA table.
--The following example assigns the SURFACE_DATA interval values
--to the flood-water-depth sim out implementing the BD scenario.

--Entry for flood-water-depth NULL values:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (90, 6);

--Entry for flood-water-depth 1st value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (91, 6);

--Entry for flood-water-depth 2nd value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (92, 6);

--Entry for flood-water-depth 3rd value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (93, 6);

--Entry for flood-water-depth 4th value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (94, 6);

--Entry for flood-water-depth 5th value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (95, 6);

-- -------------------------------------------------
--                      OPTIONAL 
-- Add the building surfaces from before in the same
-- theme.
-- -------------------------------------------------
--Building surfaces
--WallSurface of existing buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (6, 6);

--RoofSurface of existing buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (7, 6);

--GroundSurface of existing buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (8, 6);