/*
			*** LINK OA SIM OUT to OPENINGS/WINDOWS ***

This SQL-query links every OA simulation output to its corresponding
window geometry and stores the window's CITYOBJECT.GMLID (semantic)
as well as it's SURFACE_GEOMETRY.GMLID (geometric). 

Note that for full FAIR compliance, you should also include the code 
space of the corresponding GMLID issuing authorities. 

*/



--Update Geom_OA by adding the CITYOBJECT.GMLID to the GMLIDsemantic column
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

UPDATE sim_meta.geom_oa
SET GMLIDsemantic = link_sim2citygml.gmlid,
	GMLIDsCodespace = link_sim2citygml.gmlid_codespace
FROM link_sim2citygml
WHERE sim_meta.geom_oa.geom_id = link_sim2citygml.geom_id;

------------------------------------------------------------------------
------------------------------------------------------------------------



--Update Geom_OA table by adding the SURFACE_GEOMETRY.GMLID to the 
--GMLIDgeometric column
WITH get_sg_gmlid AS(

	SELECT citydb.CITYOBJECT.GMLID AS co_gmlid, 
		   citydb.SURFACE_GEOMETRY.GMLID AS sg_gmlid,
		   citydb.SURFACE_GEOMETRY.GMLID_CODESPACE AS sg_gmlid_cs
	
	FROM citydb.CITYOBJECT INNER JOIN citydb.SURFACE_GEOMETRY
	ON citydb.CITYOBJECT.ID = citydb.SURFACE_GEOMETRY.CITYOBJECT_ID
	
	WHERE citydb.CITYOBJECT.GMLID IN (SELECT GMLIDsemantic FROM sim_meta.Geom_OA WHERE SIMULATIONID = 'OA_malmo_bellevue_DpXXXXX_20230401_v1')
	AND citydb.SURFACE_GEOMETRY.GEOMETRY IS NULL
)

UPDATE sim_meta.geom_oa
SET GMLIDgeometric = get_sg_gmlid.sg_gmlid,
	GMLIDgCodespace = get_sg_gmlid.sg_gmlid_cs
FROM get_sg_gmlid
WHERE sim_meta.geom_oa.GMLIDsemantic = get_sg_gmlid.co_gmlid;
