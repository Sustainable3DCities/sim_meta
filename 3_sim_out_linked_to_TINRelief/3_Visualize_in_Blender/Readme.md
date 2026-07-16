# IMPORT KML/COLLADA FILES EXPORTED FROM 3DCITYDB WITH APPEARANCES TO BLENDER

This Python-script is designed to run inside Blender (bpy module). The aim is to automate the reconstruction of a 3D city model, exported from 3DCityDB in KLM/COLLADA format, by importing multiple building files and placing them at their correct geographic locations relative to a terrain anchor (corresponding to a CityGML TINRelief).

The execution of this Python-script is necessary as KML use geographic coordinates (latitude/longitude), while Blender uses a local Cartesian coordinate system (metres). If we import one DAE-file at the time, Blender will place the corresponding objects on top of each other at the origin. 
    
To avoid that and import all the exported 3D city model objects at their correct location,
it is necessary to organize the exported KML/COLLADA files as described in the requirements below.
<br>
<br>

## Prerequisites
1. Store all building DAE-files under the same folder
2. Provide the path to: 
	i.  the main KML-file exported from 3DCityDB (top-level file)
	ii. the folder storing all the building DAE-files.
<br>
<br>

## INSTRUCTIONS
To run the code, do the following:  
1. Open Blender
2. Remove any default objects present in the main frame by selecting them and pressing DELETE.
3. Go to the top menu and click on the "SCRIPTING" tab. 
4. In the window that opens, click on "New".
5. Paste the Python code there and click RUN.
<br>
<br>

## Technical requirements 
Blender version: 3.0.1
Python version (inside Blender): 3.9.7
<br>
<br>

## License and Usage
This replication package is shared for peer-review purposes.
Upon formal publication of the associated manuscript, the code 
will be officially released under the BSD-3-Clause-License.
<br>
<br>
