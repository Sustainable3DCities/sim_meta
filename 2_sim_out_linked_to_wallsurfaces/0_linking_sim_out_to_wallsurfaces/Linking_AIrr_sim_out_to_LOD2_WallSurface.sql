/*

*** Link 3D Regular Grid Sim Out to CityGML WS Feature ***

This SQL-script is dedicated to linking simulation output 
consisting of 3D point-geometries in a regular point grid to 
the corresponding WallSurface (WS) geometry in the CityGML 
model they belong to.

Since every CITYOBJECT may consist of more than one geometries
(i.e., every CITYOBJECT ID corresponding to a single WallSurface
may consist of more than one geometries in the SURFACE_GEOMETRY
table), each of which has a unique ID (SURFACE_GEOMETRY.GMLID 
& SURFACE_GEOMETRY.ID). 

In order to be able to uniquely identify every WallSurface geometry
for obtaining its dimensions (height, width) and create a raster
corresponding to its size, it is necessary to add its corresponding
SURFACE_GEOMETRY GMLID to the Geom_XXXX table. 
This is also needed from a FAIR perspective.

*/



--Link AIrr simulation output (solar irradiance on 3D regular point grid)
--to 3D CityGML geometries (WallSurface LOD2) - add the CITYOBJECT.GMLID 
--to the corresponding sim out table column (GMLIDsemantic):

WITH temp_update_AIrr_table AS(

SELECT t1.geom_id, t1.value, t1.geom, t2.co_gmlid, t2.co_gmlid_cs,
	   ST_3DDistance(t1.geom, t2.GEOMETRY) AS distance

FROM sim_meta.geom_AIrr AS t1

	CROSS JOIN LATERAL (
		
		SELECT CITYOBJECT.GMLID AS co_gmlid, 
			   CITYOBJECT.GMLID_CODESPACE AS co_gmlid_cs, 
			   SURFACE_GEOMETRY.GEOMETRY
		
		FROM THEMATIC_SURFACE INNER JOIN SURFACE_GEOMETRY ON
		THEMATIC_SURFACE.LOD2_MULTI_SURFACE_ID = SURFACE_GEOMETRY.ROOT_ID
		INNER JOIN CITYOBJECT ON
		SURFACE_GEOMETRY.CITYOBJECT_ID = CITYOBJECT.ID
		
		WHERE CITYOBJECT.OBJECTCLASS_ID = 34
		AND SURFACE_GEOMETRY.GEOMETRY IS NOT NULL
		AND ST_3DDwithin(geometry, t1.geom, 1)
		
		ORDER BY t1.geom <-> geometry
		LIMIT 1

	) AS t2

--Set condition to only apply this linking to the sim output of a
--specific simulation (using its unique identifier: simulationID)
WHERE t1.simulationID = 'AIrr_malmo_bellevue_DpXXXXX_20251024_v2'
)

--Update the GMLIDsemantic & GMLIDsCodespace columns in the sim
--out table storing the geometries and values of the AIrr sim out,
--using the contents of the "temp_update_AIrr_table" temporary table:
UPDATE sim_meta.Geom_AIrr

SET GMLIDsemantic = temp_update_AIrr_table.co_gmlid,
GMLIDsCodespace = temp_update_AIrr_table.co_gmlid_cs

FROM temp_update_AIrr_table

WHERE sim_meta.Geom_AIrr.simulationID = 'AIrr_malmo_bellevue_DpXXXXX_20251024_v2'
AND sim_meta.Geom_AIrr.geom_id = temp_update_AIrr_table.geom_id;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--Link AIrr simulation output (solar irradiance on 3D regular point grid)
--to 3D CityGML geometries (WallSurface LOD2) - add the SURFACE_GEOMETRY.GMLID 
--of every parent WallSurface SURFACE_GEOMETRY geometry to the corresponding 
--sim out table column (GMLIDgeometric):

WITH get_sg_gmlid_WS AS(

	SELECT t1.GMLIDsemantic AS ga_gmlid, t2.GMLID AS co_gmlid, 
		   t3.GMLID AS sg_gmlid, t3.GMLID_CODESPACE AS sg_gmlid_cs

	FROM sim_meta.geom_airr t1 INNER JOIN CITYOBJECT t2 ON 
	t1.GMLIDsemantic = t2.GMLID
	INNER JOIN SURFACE_GEOMETRY t3 ON
	t2.ID = t3.CITYOBJECT_ID

	--Set condition to only apply this linking to the sim output of a
	--specific simulation (using its unique identifier: simulationID)
	--and include only the GMLID of the parent wall surface geometry
	--of every wall - whose SURFACE_GEOMETRY.GEOMETRY IS NULL
	WHERE t1.simulationID = 'AIrr_malmo_bellevue_DpXXXXX_20251024_v2' 
	AND	t3.GEOMETRY IS NULL
)

--Update the GMLIDgeometric & GMLIDgCodespace columns in the sim
--out table storing the geometries and values of the AIrr sim out,
--using the contents of the "get_sg_gmlid_WS" temporary table:
UPDATE sim_meta.geom_airr

SET GMLIDgeometric = get_sg_gmlid_WS.sg_gmlid,
	GMLIDgCodespace = get_sg_gmlid_WS.sg_gmlid_cs

FROM get_sg_gmlid_WS

WHERE sim_meta.geom_airr.simulationID = 'AIrr_malmo_bellevue_DpXXXXX_20251024_v2'
AND sim_meta.geom_airr.GMLIDsemantic = get_sg_gmlid.ga_gmlid;
