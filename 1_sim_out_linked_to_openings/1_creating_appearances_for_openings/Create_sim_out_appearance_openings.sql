/*
	*** CREATING AN APPEARANCE FOR OPENING-RELATED SIM OUT ***

The SQL-queries below create a separate appearance theme for the simulation
type (e.g., Obstruction Angle - OA) as well as set different surface data 
X3D colors per simulation output value interval. These colors are then
assigned to every opening (window) geometry based on the value of the sim
out point it has been linked to. This way CityGML can implicitly represent 
simulation output that will be visible when ordinary exports of the db in
CityGML or KML/COLLADA will be rendered with colors in visualization software 
supporting CityGML or KML/COLLADA.

Below we list how the objectives detailed above are realised:

1. Create a separate APPEARANCE theme for the particular simulation type 
   (here OA)
2. Create one entry per sim out value interval in the SURFACE_DATA table
3. Link the APPEARANCE theme to the value intervals in SURFACE_DATA 
   by adding them as entries in the APPEAR_TO_SURFACE_DATA table
4. Get the GMLID of the CityGML feature (window) closest to your simulatin
   output point and store it in the corresponding sim out table 
   (here Geom_OA).
5. Populate the TEXTUREPARAM table with values to associate the geometry
   of every window with a X3D color depending on the value of the sim out
   point it has been linked to in the previous step, using its 
   CITYOBJECT.GMLID.


Note that in order to be able to create UUIDs (globally unique identifiers),
you need to have activated the corresponding extension for your postgresql
database using the command: 

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

*/



-- STEP 1 --

--Create an APPEARANCE for the OA simulation type
INSERT INTO citydb.APPEARANCE
VALUES (1, NULL, NULL, NULL, NULL, NULL,
'OA_windows_LOD3', NULL, NULL);

-- Set UUID for "OA"-theme:
UPDATE citydb.APPEARANCE
SET gmlid = CONCAT('OA_LOD3_theme_', uuid_generate_v4())
WHERE citydb.APPEARANCE.ID = 1;

-------------------------------------------------------------------
-------------------------------------------------------------------



-- STEP 2 --
--Add entries to the SURFACE_DATA table corresponding to different 
--X3D colors for every OA simulation output value interval.
--Note that the colors are expressed in RGB where every color-value 
--is divided by 255 to produce a new value between 0.0 and 1.0.

--Colors for windows with and without OA sim output:
INSERT INTO citydb.SURFACE_DATA
VALUES (0, NULL, NULL, 'w_OA_null', NULL, 'RGB-color for windows with no OA value (value=NULL)',
1, 53, NULL, NULL, NULL, NULL, '1.0 1.0 1.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (1, NULL, NULL, 'w_OA_interval_1', NULL, 'RGB-color for windows whose OA value is: OA < 5 degrees',
1, 53, NULL, NULL, NULL, NULL, '0.0 0.5 0.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (2, NULL, NULL, 'w_OA_interval_2', NULL, 'RGB-color for windows whose OA value is: 5<= OA <10 degrees',
1, 53, NULL, NULL, NULL, NULL, '0.5 0.7 0.1', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (3, NULL, NULL, 'w_OA_interval_3', NULL, 'RGB-color for windows whose OA value is: 10<= OA <20 degrees',
1, 53, NULL, NULL, NULL, NULL, '1.0 1.0 0.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (4, NULL, NULL, 'w_OA_interval_4', NULL, 'RGB-color for windows whose OA value is: 20<= OA <30 degrees',
1, 53, NULL, NULL, NULL, NULL, '1.0 0.7 0.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO citydb.SURFACE_DATA
VALUES (5, NULL, NULL, 'w_OA_interval_5', NULL, 'RGB-color for windows whose OA value is: OA >=30 degrees',
1, 53, NULL, NULL, NULL, NULL, '1.0 0.2 0.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--OPTIONAL 
--(If the sim out colorscale needs larger contrast with background color of buildings)
--Change color of building RoofSurface:
INSERT INTO citydb.SURFACE_DATA
VALUES (6, NULL, NULL, 'RoofSurface_darkgray', NULL, 'RGB-color for roof surfaces',
1, 53, NULL, NULL, NULL, NULL, '0.2 0.2 0.0', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--Change color of building WallSurface:
INSERT INTO citydb.SURFACE_DATA
VALUES (7, NULL, NULL, 'WallSurface_lightgray', NULL, 'RGB-color for wall surfaces',
1, 53, NULL, NULL, NULL, NULL, '0.7 0.7 0.7', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--Change color of building GroundSurface:
INSERT INTO citydb.SURFACE_DATA
VALUES (8, NULL, NULL, 'GroundSurface_beige', NULL, 'RGB-color for ground surfaces',
1, 53, NULL, NULL, NULL, NULL, '0.9 0.7 0.4', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--Add UUID as ID for every SURFACE_DATA table entry
--OA (sunlight simulation)
UPDATE citydb.SURFACE_DATA
SET gmlid = CONCAT('surfacedata', uuid_generate_v4())
WHERE SURFACE_DATA.ID >= 0 AND SURFACE_DATA.ID < 9;

-------------------------------------------------------------------
-------------------------------------------------------------------





-- STEP 3 --
--Update the APPEAR_TO_SURFACE_DATA table to map the newly created
--SURFACE_DATA table entries to the "OA" theme (ID: 1) in the 
--APPEARANCE table. 

--Entry for OA NULL values:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (0, 1);

--Entry for OA 1st value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (1, 1);

--Entry for OA 2nd value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (2, 1);

--Entry for OA 3rd value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (3, 1);

--Entry for OA 4th value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (4, 1);

--Entry for OA 5th value interval:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (5, 1);

--Building surfaces
--WallSurface of existing buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (6, 1);

--RoofSurface of existing buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (7, 1);

--GroundSurface of existing buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (8, 1);

-------------------------------------------------------------------
-------------------------------------------------------------------




-- STEP 4 --
--Link OA simulation output to 3D city model geometry (windows):

WITH link_sim2citygml AS(

	--Get the GMLID of the window geometry closest to the sim output point:
	SELECT	t1.geom_id, t1.geom, t2.gmlid, t2.gmlid_codespace,
			ST_3DDistance(t1.geom, t2.geometry) AS distance
	
	FROM sim_meta.Geom_OA AS t1
	
		CROSS JOIN LATERAL (
			SELECT citydb.CITYOBJECT.gmlid, citydb.CITYOBJECT.gmlid_codespace,
			citydb.SURFACE_GEOMETRY.GEOMETRY
		
			FROM citydb.CITYOBJECT INNER JOIN citydb.SURFACE_GEOMETRY
			ON citydb.CITYOBJECT.ID = citydb.SURFACE_GEOMETRY.CITYOBJECT_ID
			
			WHERE citydb.CITYOBJECT.OBJECTCLASS_ID = 38     --OBJECTCLASS_ID=38 denotes openings/windows
			AND	citydb.SURFACE_GEOMETRY.geometry IS NOT NULL
			AND ST_3DDwithin(geometry, t1.geom, 1)
			
			ORDER BY t1.geom <-> geometry
			LIMIT 1
			
		) AS t2
	
	--Limit the computation to include just the points of a 
	--particular simulation:
	WHERE	t1.SIMULATIONID = 'OA_malmo_bellevue_DpXXXXX_20230401_v1'
)

--Update Geom_OA by adding the CITYOBJECT.GMLID to the GMLIDsemantic column
UPDATE sim_meta.geom_oa
SET GMLIDsemantic = link_sim2citygml.gmlid,
	GMLIDsCodespace = link_sim2citygml.gmlid_codespace
FROM link_sim2citygml
WHERE sim_meta.geom_oa.geom_id = link_sim2citygml.geom_id;

-------------------------------------------------------------------
-------------------------------------------------------------------




-- STEP 5 --
--Populate TEXTUREPARAM table with values for OA.
--Match the SURFACE_DATA color to the SURFACE_GEOMETRY window
--based on the OA sim output value 

-----------------------------------------------------------------
--			        *** SIM OUTPUT ***
-----------------------------------------------------------------

--Windows whose OA is NULL:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 0
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	LEFT JOIN sim_meta.geom_oa
	ON CITYOBJECT.GMLID = sim_meta.geom_oa.GMLIDsemantic
	WHERE CITYOBJECT.OBJECTCLASS_ID = 38
	AND SURFACE_GEOMETRY.GEOMETRY IS NULL 
	AND sim_meta.geom_oa.Value IS NULL
);


--Windows whose OA is < 5 degrees:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 1
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	INNER JOIN sim_meta.geom_oa
	ON CITYOBJECT.GMLID = sim_meta.geom_oa.GMLIDsemantic
	WHERE CITYOBJECT.OBJECTCLASS_ID = 38
	AND SURFACE_GEOMETRY.GEOMETRY IS NULL 
	AND sim_meta.geom_oa.Value >= 0
	AND sim_meta.geom_oa.Value < 5
);

--Windows whose sim output is: 5>= OA <10:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 2
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	INNER JOIN sim_meta.geom_oa
	ON CITYOBJECT.GMLID = sim_meta.geom_oa.GMLIDsemantic
	WHERE CITYOBJECT.OBJECTCLASS_ID = 38
	AND SURFACE_GEOMETRY.GEOMETRY IS NULL 
	AND sim_meta.geom_oa.Value >= 5
	AND sim_meta.geom_oa.Value < 10
);


--Windows whose sim output is: 10>= OA <20:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 3
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	INNER JOIN sim_meta.geom_oa
	ON CITYOBJECT.GMLID = sim_meta.geom_oa.GMLIDsemantic
	WHERE CITYOBJECT.OBJECTCLASS_ID = 38
	AND SURFACE_GEOMETRY.GEOMETRY IS NULL 
	AND sim_meta.geom_oa.Value >= 10
	AND sim_meta.geom_oa.Value < 20
);


--Windows whose sim output is: 20>= OA <30:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 4
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	INNER JOIN sim_meta.geom_oa
	ON CITYOBJECT.GMLID = sim_meta.geom_oa.GMLIDsemantic
	WHERE CITYOBJECT.OBJECTCLASS_ID = 38
	AND SURFACE_GEOMETRY.GEOMETRY IS NULL 
	AND sim_meta.geom_oa.Value >= 20
	AND sim_meta.geom_oa.Value < 30
);


--Windows whose sim output is: OA >=30:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 5
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	INNER JOIN sim_meta.geom_oa
	ON CITYOBJECT.GMLID = sim_meta.geom_oa.GMLIDsemantic
	WHERE CITYOBJECT.OBJECTCLASS_ID = 38
	AND SURFACE_GEOMETRY.GEOMETRY IS NULL 
	AND sim_meta.geom_oa.Value >= 30
);



-----------------------------------------------------------------
--			        *** BUILDING SURFACES ***
-----------------------------------------------------------------

--Building roofs:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 6
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	WHERE CITYOBJECT.OBJECTCLASS_ID = 33
	
);


--Building wall surfaces:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 7
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	WHERE CITYOBJECT.OBJECTCLASS_ID = 34
);


--Building ground surfaces:
UPDATE citydb.TEXTUREPARAM
SET SURFACE_DATA_ID = 8
WHERE SURFACE_GEOMETRY_ID IN(

	SELECT SURFACE_GEOMETRY.ID
	FROM SURFACE_GEOMETRY INNER JOIN CITYOBJECT
	ON SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
	WHERE CITYOBJECT.OBJECTCLASS_ID = 35
);

