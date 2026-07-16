/*
			*** SQL-code FOR CREATING SIM OUT TABLE ***
	
	This SQL-query shows how to create a table for storing the 
	raw geometric data for a simulation (e.g., Obstruction Angle - OA) 
	resulting in the production of 3D points.

	Note that the Coordinate Reference System (CRS) and 
	Vertical Coordinate Reference System (VCRS) of the 
	3D points must match the corresponding CRS & VCRS
	of the database in 3DCityDB.

	The fields/columns Identifier & IdentifierCodespace are only
	applicable for CityGML 3.0 models and should remain empty for
	CityGML 2.0 models.

*/



--Create Geometry_OA table:

CREATE TABLE sim_meta.Geom_OA
(
	Geom_ID character varying(255), 			--corresponds to GeommetryID (unique numeric ID for simulation output raw data)
	coord_x double precision,					--x-coord of sim out 3D point geometry
	coord_y double precision,					--y-coord of sim out 3D point geometry
	coord_z double precision,					--z-coord of sim out 3D point geometry
	Value numeric,								--simulation output value (here: OA in degrees)
	Identifier character varying(255),			--unique permanent identifier for CityGML feature
	IdentifierCodespace character varying(255), --code space identifying the authority producing the identifier
	GMLIDsemantic character varying(255),		--GMLID of the CityGML Feature the sim out point corresponds to
	GMLIDsCodespace character varying(255),		--code space identifying the authority issuing the semantic GMLID code
	GMLIDgeometric character varying(255),		--GMLID of the CityGML Feature's geometry the sim output point corresponds to
	GMLIDgCodespace character varying(255),		--code space identifying the authority issuing the geometric GMLID code 
	simulationID character varying(255),		--unique ID of the simulation scenario
	geom geometry(PointZ, 3008)					--PostGIS geometry for 3D point
);


