#!/usr/bin/env python
# coding: utf-8


#Import Python modules:
import bpy
import os
import math
import xml.etree.ElementTree as ET


#Set the path to the main KML-file:
kml_path = r'C:\Users\...\Collada\tcim_malmo_xl_TIN\Flood_BD\Tiles\0\0\tcim_malmo_xl_Flood_BD_Tile_0_0_collada.kml'

#Set the path to the folder containing all the building DAE-files:
dae_folder = r'C:\Users\...\Collada\tcim_malmo_xl_TIN\Flood_BD_all_in_one\buildings' 


#Calculate how many meters there are per degree of 
#latitude & longitude.
def get_meters_per_degree(lat):
    
    lat_rad = math.radians(lat)
    
    # Metric approximation for Sweden's latitude
    # where 111132.92 = length in m of one degree of latitude at the equator
    # where 559.82 = correction factor that accounts for the Earth's flattening at the poles. 
    # where 111412.84 the base length while moving north/south from the equator
    m_per_lat = 111132.92 - 559.82 * math.cos(2 * lat_rad)
    m_per_lon = 111412.84 * math.cos(lat_rad)
    
    #Return values:
    return m_per_lat, m_per_lon


# Parse KML
tree = ET.parse(kml_path)
root = tree.getroot()

# Find all Placemarks
placemarks = root.findall('.//{*}Placemark')

#If "placemarks" is empty:
if not placemarks:
    print("Error: No Placemarks found.")
    
else:
    # Get Terrain Anchor (Last Placemark)
    terrain_pm = placemarks[-1]
    t_lon = float(terrain_pm.find('.//{*}longitude').text)
    t_lat = float(terrain_pm.find('.//{*}latitude').text)
    t_alt = float(terrain_pm.find('.//{*}altitude').text)
    
    #Call function to return meters per latitude and meters per longitude
    m_per_lat, m_per_lon = get_meters_per_degree(t_lat)
    
    print(f"Origin set at Terrain: {t_lat}, {t_lon}")

    
    # Process Buildings (all except the last placemark)
    for pm in placemarks[:-1]:
        
        #Search for the link to the 3D model file inside the KML data:
        href_tag = pm.find('.//{*}href')
        
        #If the tag is found:
        if href_tag is not None:
            
            # os.path.basename handles cases like '27030/filename.dae'
            filename = os.path.basename(href_tag.text)
            dae_path = os.path.join(dae_folder, filename)
            
            #Check that the DAE-file exists:
            if os.path.exists(dae_path):
                
                # Extracting nested tags
                lon = float(pm.find('.//{*}longitude').text)
                lat = float(pm.find('.//{*}latitude').text)
                alt = float(pm.find('.//{*}altitude').text)
                head = float(pm.find('.//{*}heading').text)
                
                # Calculate relative distance from terrain anchor
                x = (lon - t_lon) * m_per_lon
                y = (lat - t_lat) * m_per_lat
                
                # Import the DAE
                bpy.ops.wm.collada_import(filepath=dae_path)
                
                # Position and rotate the imported building
                for obj in bpy.context.selected_objects:
                    
                    #Move the building to the calculated x/y coords
                    #and set the altitude.
                    obj.location = (x, y, alt)
                    
                    # KML heading is degrees clockwise; Blender Z is radians counter-clockwise
                    obj.rotation_euler = (0, 0, math.radians(-head))
            else:
                print(f"File not found: {filename}")

    print("All buildings aligned.")
