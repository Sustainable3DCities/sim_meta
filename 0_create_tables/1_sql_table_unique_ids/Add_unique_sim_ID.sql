/*

						Add simulation ID

	This SQL-query adds a unique simulation ID to the imported raw data
	from a certain type of simulation. 

	The simulation ID could follow a naming convetion. An indicatory 
	example is presented below.

	SimulationType_Municipality_District_DDPcode_SimulationDate_ScenarioVersion

	DDP denotes a Detailed Development Plan. Note this could be replaced with 
	another title indicating the purpose of the simulation. 

*/


-- Add simulation ID to table

UPDATE sim_meta.Geom_OA
SET simulationID = 'OA_malmo_bellevue_DpXXXXX_20230401_v1';


