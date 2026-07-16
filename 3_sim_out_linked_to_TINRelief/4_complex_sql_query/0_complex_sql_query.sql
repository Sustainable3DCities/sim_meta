/*
					*** COMPLEX SQL QUERY ***

	This is an example of the type of SQL queries the proposed sim_meta 
	db schema within a 3DCityDB database can support.
	
	The script below, presents a complex SQL query	combining CityGML 
	semantic information with outputs from more than one simulations 
	in urban planning.

	This particular example identifies buildings whose use is 
	residential	or related to health care and have simulation outputs 
	for obstruction angle exceeding the limit (>30 degrees) and Lden 
	noise values from road traffic exceeding 53 dB(A).

	Buildings with these characteristics are highlighted using a red X3D 
	color in Surface_Data linked to a specific Appearance theme for city
	objects that do not comply to existing laws/recommendations, etc.

*/



-- STEP 1 --
--Enter a new row in the APPEARANCE table to store a new appearance
--theme for residential buildings not conforming to solar access/noise 
--recommendations.

INSERT INTO citydb.APPEARANCE
VALUES (10, NULL, NULL, NULL, NULL, NULL,
'problematic_buildings', NULL, NULL);

-- Set UUID for "problematic buildings"-theme:
UPDATE citydb.APPEARANCE
SET gmlid = CONCAT('problematic_buildings_theme_', uuid_generate_v4())
WHERE citydb.APPEARANCE.ID = 10;

-------------------------------------------------------------------
-------------------------------------------------------------------



-- STEP 2 --
--Add entries to the SURFACE_DATA table corresponding to the 
--X3D colors for building parts (GroundSurface, WallSurface & RoofSurface)
--of residential buildings that fail to conform to recommended 
--solar access (OA metric) and noise level (Lden) threshold values.

--Problematic buildings: RoofSurface
INSERT INTO citydb.SURFACE_DATA
VALUES (103, NULL, NULL, 'RoofSUrface_highlighted_red', NULL, 'RGB-color for roof surface of highlighted buildings',
1, 53, NULL, NULL, NULL, NULL, '1.0 0.2 0.2', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--Problematic buildings: WallSurface
INSERT INTO citydb.SURFACE_DATA
VALUES (104, NULL, NULL, 'WallSurface_highlighted_red', NULL, 'RGB-color for wall surface of highlighted buildings',
1, 53, NULL, NULL, NULL, NULL, '1.0 0.2 0.2', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--Problematic buildings: GroundSurface
INSERT INTO citydb.SURFACE_DATA
VALUES (105, NULL, NULL, 'GroundSurface_highlighted_red', NULL, 'RGB-color for ground surface of highlighted buildings',
1, 53, NULL, NULL, NULL, NULL, '1.0 0.2 0.2', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--Add GMLID (UUID) for building wall- and roof-surfaces:
UPDATE citydb.SURFACE_DATA
SET gmlid = CONCAT('surfacedata', uuid_generate_v4())
WHERE (SURFACE_DATA.ID < 106) AND (SURFACE_DATA.ID > 102);

-------------------------------------------------------------------
-------------------------------------------------------------------



-- STEP 3 --
--Update the APPEAR_TO_SURFACE_DATA table to map the newly created
--SURFACE_DATA table entries (ID: 103, 104, 105) to the 
--"problematic_buildings" theme (ID: 10) in the APPEARANCE table. 

--WallSurface of problematic buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (103, 10);

--RoofSurface of problematic buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (104, 10);

--GroundSurface of problematic buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (105, 10);

--WallSurface of non-problematic buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (13, 10);

--RoofSurface of non-problematic buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (12, 10);


--GroundSurface of non-problematic buildings:
INSERT INTO citydb.APPEAR_TO_SURFACE_DATA
VALUES (8, 10);

-------------------------------------------------------------------
-------------------------------------------------------------------



-- STEP 4 --
--Set the color of all building parts whose buildings are
--ressidential and do not conform to the solar access and 
--noise level thresholds to red in the TEXTUREPARAM table.

--Get all GMLIDs of windows whose OA>=30
WITH oa_gmlids AS (

	SELECT sim_meta.geom_oa.GMLIDsemantic AS gmlid_oa
	FROM sim_meta.geom_oa
	WHERE sim_meta.geom_oa.simulationid = 'OA_malmo_bellevue_DpXXXXX_20230401_v1'
	AND value >= 30.0
),

--Get all GMLIDs of	walls whose Lden > 53 dB
noise_gmlids AS (
	SELECT sim_meta.geom_noise.GMLIDsemantic AS gmlid_noise
	FROM sim_meta.geom_noise
	WHERE sim_meta.geom_noise.simulationid = 'Noise_malmo_bellevue_DpXXXXX_20240707_v1'
	AND value >= 53.0
),

--Get the building IDs corresponding to the window and wall surface GMLIDs
--that do not comply to the solar access and noise recommended threshold
--values.
problematic_b_ids AS (
	
	--Get the IDs of all buildings that fail to meet the solar access
	--recommended values
	SELECT DISTINCT	b.ID AS building_id

	FROM CITYOBJECT CO 
	INNER JOIN OPENING_TO_THEM_SURFACE OTS ON CO.ID = OTS.OPENING_ID
	INNER JOIN THEMATIC_SURFACE TS	ON OTS.THEMATIC_SURFACE_ID = TS.ID
	INNER JOIN BUILDING b ON TS.BUILDING_ID = b.ID
	
	WHERE CO.GMLID IN (SELECT GMLID_oa FROM oa_gmlids)	

	--Merge the IDs of problematic buildings failing to meet threshold
	--values for both solar access and noise  
	UNION 

	--Get the IDs of all buildings that fail to meet the recommended 
	--noise level threshold
	SELECT DISTINCT b.ID AS building_id
	
	FROM CITYOBJECT CO
	INNER JOIN THEMATIC_SURFACE TS ON CO.ID = TS.ID
	INNER JOIN BUILDING b ON TS.BUILDING_ID = b.ID
	
	WHERE CO.GMLID IN (SELECT gmlid_noise FROM noise_gmlids)	
),

--Filter out buildings that are not 
--residential or related to health care
b_semantic_filter AS (
	
	SELECT B.ID AS b_ID
	
	FROM BUILDING B
	
	WHERE B.ID IN (SELECT building_id FROM problematic_b_ids)
	AND (class = 'habitation' OR class = 'healthcare')
)

--Update the TEXTUREPARAM table so that the geometries
--of the RoofSurface, WallSurface, and GroundSurface
--of the selected buildings are set to red
UPDATE TEXTUREPARAM
SET SURFACE_DATA_ID = CASE
	WHEN t.OBJECTCLASS_ID = 34 THEN 103 --RoofSurface
	WHEN t.OBJECTCLASS_ID = 33 THEN 104 --WallSurface
	WHEN t.OBJECTCLASS_ID = 35 THEN 105 --GroundSurface
END
FROM (
	SELECT SG.ID AS geom_id, TS.OBJECTCLASS_ID
	FROM SURFACE_GEOMETRY SG INNER JOIN THEMATIC_SURFACE TS
	ON SG.CITYOBJECT_ID = TS.ID
	WHERE TS.BUILDING_ID IN (
		SELECT b_ID
		FROM b_semantic_filter
	) AND TS.OBJECTCLASS_ID IN (33, 34, 35)
) AS t

WHERE TEXTUREPARAM.SURFACE_GEOMETRY_ID = t.geom_id;



