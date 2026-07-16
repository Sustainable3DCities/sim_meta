/*
		*** CREATE RASTER FROM REGULAR 3D POINT GRID SIM OUT ***

	The following SQL-script creates a raster using Noise sim output 
	(consisting of 3D points in a irregular point grid) for a given 
	LOD2 WallSurface. The raster represents the simulated values
	as colors by displaying a specific color for every sim out
	value interval. The raster is meant to be exported in PNG-format, 
	so that it can then be imported and stored in the citydb schema 
	of 3DCityDB	as a texture for the specific LOD2 WallSurface. 

	To avoid empty raster cells, an IDW interpolation is applied
	over the raster.

	The following information is required to execute this SQL-script:

	1. simulationID: The unique ID of the simulation as stored in Geom_Noise.
	2. SURFACE_GEOMETRY.GMLID/GMLIDgeometric: The ID of the LOD2 WallSurface.
	3. AFFINE TRANSFORMATION PARAMATERS: Made available by the Python-script.

*/
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------

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
	'Noise_malmo_bellevue_DpXXXXX_20240707_v1'::text AS sim_id
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
		value AS Noise_value
	
	FROM sim_meta.Geom_Noise CROSS JOIN script_vars
	
	WHERE GMLIDgeometric = script_vars.wallsurf_gmlid
	AND	simulationID = script_vars.sim_id
);


----Add index to temp_table:
CREATE INDEX projected_points_gix ON projected_points USING gist (geom_2d);


--Drop table point_raster:
DROP TABLE IF EXISTS point_raster;


--Create raster with Noise sim output for a given 
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
	SELECT 
		e.bbox, ST_SRID(e.bbox) AS consistent_srid,
		3.0 AS pixel_size_x,
		-3.0 AS pixel_size_y,
		-9999 AS no_data_val
		
	FROM extent e
),


--Use the bounding box coordinates from above to create an empty raster:
ref_raster AS (
	SELECT 
		ST_AddBand(
			ST_MakeEmptyRaster(
			CEIL((ST_XMax(rp.bbox) - ST_XMin(rp.bbox)) / ABS(rp.pixel_size_x))::int, --raster-cols
			CEIL((ST_YMax(rp.bbox) - ST_YMin(rp.bbox)) / ABS(rp.pixel_size_y))::int, --raster-rows
			ST_XMin(rp.bbox), --upper left x-coord
			ST_YMax(rp.bbox), --upper left y-coord
			
			rp.pixel_size_x, rp.pixel_size_y, --pixel size x, pixel size y
			0, 0, --skew x and y
			rp.consistent_srid--ST_SRID(bbox) -- SRID
			),
			'32BF'::text, --Pixel type (e.g., 32-bit float)
			rp.no_data_val--NoData value
			) AS initial_rast
	FROM raster_params rp 
),


--Match every simulation output point to a 2D coordinate and store
--them in an appropriate array format (geomval) using the same SRID.
point_values_agg AS(
	
	SELECT ARRAY_AGG((
		ST_SetSRID(pp.geom_2d, rp.consistent_srid), pp.Noise_value)::geomval) AS gv_array
	
	FROM projected_points pp CROSS JOIN raster_params rp
	
	GROUP BY rp.consistent_srid
),


--Create a raster with gaps, by applying the sim out values to the
--empty raster:
original_raster_with_gaps AS(
	SELECT
		ST_SetValues(
			r.initial_rast,
			1,
			g.gv_array
	) AS rast
	
	FROM ref_raster r CROSS JOIN point_values_agg g
),


--Interpolate a full raster surface
--using IDW with a radius 
interpolated_surface AS (
	SELECT 
		ST_InterpolateRaster( --https://postgis.net/docs/RT_ST_InterpolateRaster.html	
			(SELECT 
				ST_UNION(ST_MakePoint(ST_X(geom_2d), ST_Y(geom_2d), Noise_value)) 
			FROM projected_points),			
			'invdist:power=4.0:radius=10.0'::text,
			(SELECT initial_rast FROM ref_raster LIMIT 1)
		) AS full_idw_rast
	LIMIT 1
),


--Merge the two rasters:
merged_raster AS (
	SELECT 
		ST_MapAlgebra( --https://postgis.net/docs/RT_ST_MapAlgebra_expr.html
			og.rast, --rast1: original_raster_with_gaps
			idw.full_idw_rast, --rast2: interpolated_surface
			'[rast1.val]', --expression: default to rast1 values
			'32BF'::text,  --pixeltype: explicit output pixel type
			'FIRST', --extenttype: use extent of rast1
			'[rast2.val]', --nodata1expression: If rast1 pixel is NoData, use the value from pixel in rast2
			'[rast1.val]', --nodata2expression: If rast2 pixel is NoData, use the value from pixel in rast1
			--nodatanodataval: If both the pixel in rast1 & the pixel in rast2 are NoData, return -9999:
			(SELECT no_data_val FROM raster_params LIMIT 1)::double precision
		) AS final_rast
	
	FROM original_raster_with_gaps og
	
	CROSS JOIN interpolated_surface idw
)


--Select the final merged raster:
SELECT final_rast AS facade_raster
FROM merged_raster;

-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------




/*

						*** ADD COLOR TO RASTER ***

	The following SQL-query adds a colormap to the created raster that stores
	the simulation output values. There is one color per a specific sim out
	color interval.

	It is meant that this colormap is standard for the particular sim out it represents.
	This is so, because the colors should be identifiable and it should be easy for users
	to recognize what value interval corresponds to every color shown in the screen.

*/


--Delete table storing Noise output in RGB-color (if it exists)
DROP TABLE IF EXISTS Noise_raster;

--Create table to store raster with Noise output in RGB-color
CREATE TABLE Noise_raster AS
	--Convert 1-band raster containing Noise sim out values to a 3-band RGB raster
	WITH reclassed_raster AS(
		SELECT ST_Reclass(
			facade_raster,
			1, --input raster band
			--Reclassification expression [min-max] = new_value
			'[-9999-0): 0,
			 [0-30): 1,
			 [30-35): 2,
			 [35-40): 3,
			 [40-45): 4,
			 [45-50): 5,
			 [50-55): 6,
			 [55-60): 7,
			 [60-65): 8,
			 [65-70): 9,
			 [70-75): 10,
			 [75-80): 11,
			 [80-infinity): 12',
			'8BUI'	
		) AS rast1
		FROM point_raster 
	)

	--Add a RGB-color to every group representing a range of Noise values
	SELECT ST_Colormap(
		rast1,
		1,
		'0 255 255 255 255
		 1 255 255 255 255
		 2 130 166 173 255
		 3 160 186 191 255
		 4 184 214 209 255
		 5 206 228 204 255
		 6 226 242 191 255
		 7 243 198 131 255
		 8 232 126 77 255
		 9 205 70 62 255
		 10 161 26 77 255
		 11 117 8 92 255
		 12 67 10 74 255',
		 'EXACT'	
	) AS rgb_rast
	FROM reclassed_raster;	

--Add column to raster table to store raster ID:
ALTER TABLE Noise_raster ADD COLUMN rid numeric;
UPDATE Noise_raster SET rid = 1;

-- ----------------------------------------------------------------------


--Drop the assisting temp tables:
DROP TABLE IF EXISTS script_vars, projected_points, point_raster;
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------



/*

						*** VIEW RASTER ***

	The following SQL-query allows the user to export the newly-produced
	raster as a URL and view it in a browser.

*/


--Export raster to view in browser using the URL:
SELECT 'data:image/png;base64,' || encode(ST_AsPNG(rgb_rast), 'base64')

FROM Noise_raster

WHERE rid=1;

-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
