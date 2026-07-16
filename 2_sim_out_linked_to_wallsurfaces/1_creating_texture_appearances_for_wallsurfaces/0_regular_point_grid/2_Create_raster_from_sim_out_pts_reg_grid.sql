/*
		*** CREATE RASTER FROM REGULAR 3D POINT GRID SIM OUT ***

	The following SQL-script creates a raster using AIrr sim output 
	(consisting of 3D points in a regular point grid) for a given 
	LOD2 WallSurface. The raster represents the simulated values
	as colors by displaying a specific color for every sim out
	value interval. The raster is meant to be exported in PNG-format, 
	so that it can then be imported and stored in the citydb schema 
	of 3DCityDB	as a texture for the specific LOD2 WallSurface.

	
	The following information is required to execute this SQL-script:

	1. simulationID: The unique ID of the simulation as stored in Geom_Airr.
	2. SURFACE_GEOMETRY.GMLID/GMLIDgeometric: The ID of the LOD2 WallSurface.
	3. AFFINE TRANSFORMATION PARAMATERS: Made available by the Python-script.

*/


/*

						* CREATE RASTER *

	The following SQL-query creates a raster of the sim out values
	of a regular point grid that matches the extend of the 2D wall
	surfaces the sim out points correspond to.

*/

--Enable GDAL drivers to allow the export of a raster to a PNG 
SET postgis.gdal.enabled_drivers = 'ENABLE_ALL'; --alt. SET postgis.gdal.enabled_drivers = 'PNG'

--Set the ID-value (GMLIDgeometric) of the wall surface the 3D sim out points correspond to
--as well as the simulation ID value:
DROP TABLE IF EXISTS script_vars;
CREATE TABLE script_vars AS
(SELECT
	'ID_87594c9e-6321-4195-b3e1-8eacd172fdd6'::text AS wallsurf_gmlid,
	'AIrr_malmo_bellevue_DpXXXXX_20251024_v2'::text AS sim_id
);


--Drop table if it already exists:
DROP TABLE IF EXISTS projected_points;

--Reproject sim output points to 2D using Affine transformation:
CREATE TABLE projected_points AS
(
	SELECT 
		ST_Force2D(
			ST_Affine(
			geom,
			 -0.485300222841916595317712790347,	-- a Affine transformation parameter 
			-0.874347581748577962201807167730, 	-- b Affine transformation parameter 
			0.000000000000106716193737452767, 	-- c Affine transformation parameter 
			0.000000000000051789571491018349, 	-- d Affine transformation parameter 
			0.000000000000093306946636507760, 	-- e Affine transformation parameter 
			0.999999999999999888977697537484, 	-- f Affine transformation parameter 
			-0.874347581748577851179504705215, 	-- g Affine transformation parameter 
			0.485300222841916539806561559089, 	-- h Affine transformation parameter 
			0.000000000000000000204597570934, 	-- i Affine transformation parameter 
			5444663.2173915, 		-- x-offset Affine transformation parameter 
			-20.955562219046868, 	-- y-offset Affine transformation parameter 
			-2887868.900733131 		-- z-offset Affine transformation parameter 			
			)
		) AS geom_2d, 
		value AS AIrr_value
	
	FROM sim_meta.Geom_AIrr CROSS JOIN script_vars
	
	WHERE GMLIDgeometric = script_vars.wallsurf_gmlid
	AND	simulationID = script_vars.sim_id
);


----Add index to temp_table:
CREATE INDEX projected_points_gix ON projected_points USING gist (geom_2d);


--Drop table point_raster:
DROP TABLE IF EXISTS point_raster;


--Create raster with AIrr sim output for a given 
--LOD2 WallSurface:
CREATE TABLE point_raster AS


--Get the vertex points from the vertical WallSurface: 
WITH wallsurface_dumped_points AS(
	SELECT 
		(ST_DumpPoints(GEOMETRY)).geom AS p_geom,
		ST_SRID(GEOMETRY) AS srid
	
	FROM SURFACE_GEOMETRY CROSS JOIN script_vars
	
	WHERE root_id IN (SELECT root_id FROM SURFACE_GEOMETRY
					WHERE GMLID = script_vars.wallsurf_gmlid)
	AND geometry IS NOT NULL
),

--Transform the vertical WallSurface to 2D using the same Affine transformation
--parameters that were used to transformat the sim out points: 
wallsurface_2d AS(
	SELECT 
		ST_MakePolygon(
			ST_MakeLine(
				ST_Force2D(
					ST_Affine(
					p_geom,
					 -0.485300222841916595317712790347, -- a Affine transformation parameter 
					-0.874347581748577962201807167730, 	-- b Affine transformation parameter 
					0.000000000000106716193737452767, 	-- c Affine transformation parameter 
					0.000000000000051789571491018349, 	-- d Affine transformation parameter 
					0.000000000000093306946636507760, 	-- e Affine transformation parameter 
					0.999999999999999888977697537484, 	-- f Affine transformation parameter 
					-0.874347581748577851179504705215, 	-- g Affine transformation parameter 
					0.485300222841916539806561559089, 	-- h Affine transformation parameter 
					0.000000000000000000204597570934, 	-- i Affine transformation parameter 
					5444663.2173915, 		-- x-offset Affine transformation parameter 
					-20.955562219046868, 	-- y-offset Affine transformation parameter 
					-2887868.900733131 		-- z-offset Affine transformation parameter 			
					)
				)
			)
		) AS polygon_2d_yz_plane
	FROM wallsurface_dumped_points
),


--Get the extent of the transformed 2D wall surface:
extent AS(
	SELECT ST_Extent(polygon_2d_yz_plane) AS bbox
	
	FROM wallsurface_2d	
),


--Get the 2D bounding box coordinates for the 2D wall surface:
raster_params AS (
	
	SELECT e.bbox, ST_SRID(e.bbox) AS consistent_srid
	
	FROM extent e
),


--Use the bounding box coordinates from above to create an empty raster:
ref_raster AS (
	SELECT 
		ST_AddBand(
			ST_MakeEmptyRaster(
			round((ST_XMax(rp.bbox) - ST_XMin(rp.bbox)) / 0.2::float)::int, --raster-cols
			round((ST_YMax(rp.bbox) - ST_YMin(rp.bbox)) / 0.2::float)::int, --raster-rows
			ST_XMin(rp.bbox), --upper left x-coord
			ST_YMax(rp.bbox), --upper left y-coord
			0.2, -0.2, --pixel size x, pixel size y
			0, 0, --skew x and y
			rp.consistent_srid--ST_SRID(bbox) -- SRID
			),
			'32BF'::text, --Pixel type (e.g., 32-bit float)
			-9999 --NoData value
			) AS initial_rast 
	
	FROM raster_params rp 
),


--Match every simulation output point to a 2D coordinate and store
--them in an appropriate array format (geomval) using the same SRID.
point_values_agg AS(
	
	SELECT ARRAY_AGG((
		ST_SetSRID(pp.geom_2d, rp.consistent_srid), pp.AIrr_value)::geomval) AS gv_array
	
	FROM projected_points pp CROSS JOIN raster_params rp
	
	GROUP BY rp.consistent_srid
)


--Add the aggregated/packaged sim out values (from point_values_agg) 
--to the empty reference raster (ref_raster): 
SELECT ST_SetValues(
	r.initial_rast,
	1,
	g.gv_array
) AS facade_raster

FROM ref_raster r CROSS JOIN point_values_agg g;

------------------------------------------------------------------------
------------------------------------------------------------------------




/*

						*** ADD COLOR TO RASTER ***

	The following SQL-query adds a colormap to the created raster that stores
	the simulation output values. There is one color per a specific sim out
	color interval.

	It is meant that this colormap is standard for the particular sim out it represents.
	This is so, because the colors should be identifiable and it should be easy for users
	to recognize what value interval corresponds to every color shown in the screen.

*/


--Delete table storing AIrr output in RGB-color (if it exists)
DROP TABLE IF EXISTS AIrr_raster;

--Create table to store raster with AIrr output in RGB-color
CREATE TABLE AIrr_raster AS
	--Convert 1-band raster containing AIrr sim out values to a 3-band RGB raster
	WITH reclassed_raster AS(
		SELECT ST_Reclass(
			facade_raster,
			1, --input raster band
			--Reclassification expression [min-max] = new_value
			'[-9999-0): 0,
			 [0-400): 1,
			 [400-500): 2,
			 [500-600): 3,
			 [600-700): 4,
			 [700-infinity): 5,',
			'8BUI'	
		) AS rast1
		FROM point_raster 
	)


	--Add a RGB-color to every group representing a range of AIrr values
	SELECT ST_Colormap(
		rast1,
		1,
		'0 255 255 255 255
		 1 245 245 0 255
		 2 245 184 0 255
		 3 245 122 0 255
		 4 245 61 0 255
		 5 168 0 0 255',
		 'EXACT'	
	) AS rgb_rast
	FROM reclassed_raster;	


--Add column to raster table to store raster ID:
ALTER TABLE AIrr_raster ADD COLUMN rid numeric;
UPDATE AIrr_raster SET rid = 1;

------------------------------------------------------------------------


--Drop the assisting temp tables:
DROP TABLE IF EXISTS script_vars, projected_points, point_raster;
------------------------------------------------------------------------
------------------------------------------------------------------------



/*

						*** VIEW RASTER ***

	The following SQL-query allows the user to export the newly-produced
	raster as a URL and view it in a browser.

*/


--Export raster to view in browser using the URL:
SELECT 'data:image/png;base64,' || encode(ST_AsPNG(rgb_rast), 'base64')

FROM AIrr_raster

WHERE rid=1;
