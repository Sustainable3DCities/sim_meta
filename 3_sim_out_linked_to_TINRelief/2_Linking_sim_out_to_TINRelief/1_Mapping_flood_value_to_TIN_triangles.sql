/*

	*** Link FLOOD simulation output to TIN triangles ***

The SQL-queries in this script are used to link simulation output that
is related to the ground surface (e.g., flood) to the corresponding
TINRelief semantic and geometric identifiers (GMLIDs) and update the
TINRelief's appearance to reflect the simulation output values.

This is achieved by implementing the following steps:
1. Create a temporary table storing all TIN triangles relevant for 
   the sim out, convert them to 2D, and get the centroid of each one.
2. Find the closest 2D sim out point to every TIN triangle 2D centroid
   and assign the Surface Data ID corresponding to that sim value to it.
3. Update the TEXTUREPARAM table so that every TIN triangle reflects the
   value of the sim out point it has been linked to.
4. Update the table storing the sim out (here Geom_Flood) to include the
   GMLID and coressponding code space of the TINRelief object.

Notes:
We choose to store the GMLID of the TIN_RELIEF because it is the specific
component containig the actual triangular network and is a semantic object
instead of a geometric primitive (as the individual TIN triangles are).
If the organization storing the 3D city model (e.g., municipality) should 
regenerate the TIN - even with the same DEM points - the triangulation
algorithm might produce different triangle IDs or different mesh topology
altogether. Consequently, linking the sim out points to individual TIN 
triangles would be useless. This is without considering the massive overhead
of trying to link millions of TIN triangles to millions of sim out points in
the first place. 
One more thing to consider is that it is not certain that the flood simulation
is conducted using the same DEM as the one used to produce the TINRelief.
Therefore, to be consistent, it is important that the flood sim out points are
linked with a TINRelief that corresponds to roughly the same time as the DEM
that was used to conduct the simulation. This way it is ensured that the sim
out points are linked to the GMLID of a TINRelief' representing the same 
topographical conditions as the one used to produce them. 

*/



-- STEP 1 --
-- Create temp table storing all TIN triangles to be
-- linked with a flood simulation value and force them
-- to 2D.

WITH target_triangles AS (
	
	SELECT 
		sg.ID as sg_id,
		ST_Centroid(ST_Force2D(sg.GEOMETRY)) AS centroid_2D,
		ST_Z(ST_Centroid(sg.GEOMETRY)) AS original_z
	
	FROM citydb.SURFACE_GEOMETRY sg
	
	WHERE sg.GMLID LIKE 'TIN_TRI_%' 
	AND	sg.PARENT_ID IS NOT NULL 
	AND sg.GEOMETRY IS NOT NULL
),



-- STEP 2 --
-- Find the closest 2D flood point to every TIN triangle 
-- and assign the Surface Data ID based on the intervals

triangle_flood_mapping AS (
	
	SELECT
		t.sg_id,
		CASE 
			WHEN f.flood_val IS NULL THEN 90
			WHEN f.flood_val <= 0.1 THEN 91
			WHEN f.flood_val >0.1 AND f.flood_val <= 0.3 THEN 92
			WHEN f.flood_val >0.3 AND f.flood_val <= 0.6 THEN 93
			WHEN f.flood_val >0.6 AND f.flood_val <= 1.2 THEN 94
			WHEN f.flood_val >1.2 THEN 95
		END AS target_surface_data_id

	FROM target_triangles t

	CROSS JOIN LATERAL (
		
		SELECT gf.value AS flood_val
		FROM sim_meta.geom_flood gf
		ORDER BY gf.geom <-> t.centroid_2D
		LIMIT 1
	) f
)



-- STEP 3 --
-- Update TEXTUREPARAM with values
INSERT INTO citydb.TEXTUREPARAM (
	surface_geometry_id,
	surface_data_id,
	is_texture_parametrization
)
SELECT
	sg_id,
	target_surface_data_id,
	0 -- No texture coordinates included (Boolean logic)

FROM triangle_flood_mapping

WHERE target_surface_data_id IS NOT NULL;



-- STEP 4 --
-- Store the GMLID & code space of the TINRelief
-- and its corresponding geometry in Geom_Flood

UPDATE sim_meta.Geom_Flood

SET 
	GMLIDsemantic = s.G1
	GMLIDsCODESPACE = s.G1_CS
	GMLIDgeometric = s.G2
	GMLIDgCODESPACE = s.G2_CS

FROM (
	SELECT co.GMLID AS G1, co.GMLID_CODESPACE AS G1_CS,
	sg.GMLID AS G2, sg.GMLID_CODESPACE AS G1_CS

	FROM TIN_RELIEF tr INNER JOIN CITYOBJECT co
	ON tr.ID = co.ID 
	INNER JOIN SURFACE_GEOMETRY sg 
	ON co.ID = sg.CITYOBJECT_ID

	--In case there are more than 1 TINs in the database,
	--use the TIN name or description to distinguish the
	--unique way to identify 1 TIN:
	WHERE co.DESCRIPTION = 'TIN-component of Bellevue DTM'
	AND sg.GEOMETRY IS NULL
) AS s

--Limit the update to include only the rows of a specific simulation:
WHERE sim_meta.Geom_Flood.simulationID = 'Flood_malmo_bellevue_DpXXXXX_20240630_v1_60min';