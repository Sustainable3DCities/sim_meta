#!/usr/bin/env python
# coding: utf-8

# 
# # Get affine transformation parametes
# This notebook is dedicated to obtaining the parameter values for executing an Affine transformation (from 3D to 2D) in PostGIS using the 3D point geometry of the vertices of a certain building part (e.g., a wall) corresponding to a facade of a building. The same parameters are applied to transform the coordinates of all vertices of the corresponding facade polygon. These parameters are also used to transform the 3D points of the simulation output (e.g., noise simulation output) that corresponf to the given facade polygon.
# 
# Measures are taken to ensure the orthogonality of the transformed point grid to the origin (0,0).
# 
# 



#Import Python modules:
import pandas as pd
import numpy as np
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
import psycopg
import math
from decimal import Decimal




#Database connection credentials
uid = 'userID'
pwd = 'userPassword'

#SQL db details:
server = "[serverName]"
database = "[databaseName]"
schema = "sim_meta"




#Connect to database:
engine = create_engine(f'postgresql+psycopg://{uid}:{pwd}@{server}:5432/{database}')





#Set GMLID of WallSurface:
WS_GMLID = 'WSLod2df1b756b-57ba-442c-ae79-e856b4c0b4b7'


#Set simulation ID:
sim_ID = 'Lden_malmo_bellevue_DpXXXXX_20240630_v2'




#SQL-query that returns the Surface_Geometry_ID(s) 
#for a WallSurface object with a given GMLID:
sql2 ="""
SELECT SURFACE_GEOMETRY.ID
FROM CITYOBJECT INNER JOIN SURFACE_GEOMETRY
ON CITYOBJECT.ID = SURFACE_GEOMETRY.CITYOBJECT_ID
WHERE CITYOBJECT.GMLID = '"""+WS_GMLID+"""'
AND SURFACE_GEOMETRY.GEOMETRY IS NOT NULL;"""




#Call query and return SURFACE_GEOEMETRY_ID(s) in pandas df:
df2 = pd.read_sql_query(sql2, engine)




#Select surface geometry ID:
sg_id = df2.id.iloc[0]





#SQL-query that returns the x-, y-, and z-coords of a
#wallsurface polygon, given a specific surfacegeometryid
sql = """SELECT 
ST_X((ST_DumpPoints(GEOMETRY)).geom) AS poly_point_coordx,
ST_Y((ST_DumpPoints(GEOMETRY)).geom) AS poly_point_coordy,
ST_Z((ST_DumpPoints(GEOMETRY)).geom) AS poly_point_coordz
FROM SURFACE_GEOMETRY 
WHERE SURFACE_GEOMETRY.ID = """ + str(sg_id)




#Read query to pandas df
#This pandas dataframe includes the x-, y-, and z-coordinate
#for every point of a WallSurface polygon. 
#Every row repesent the x-, y-, and z-coord of a point
poly_points_df = pd.read_sql_query(sql, engine) 





#Convert pandas df to a list of tuples (coords for one point per tuple)
tups = [tuple(x) for x in poly_points_df.values.tolist()]





def calc_orthogonal_basis_from_points(point_ls):
    
    """
    Function that applies Principal Component Analysis (PCA) to determine
    the robust orthogonal basis vectors (U, V, N) for a set of points on
    a (potentially distorted) plane.
    
    The points come from a WallSurface polygon of a building where every
    points coordinates are expressed in 3D (x, y, z).
    
    """
    
    #Import the list of polygon point tuples to an np array:
    points_array = np.array(point_ls)
    
    #Center the points by subtracting the mean (centroid)
    centroid = np.mean(points_array, axis=0)
    centered_points = points_array - centroid
    
    #Calculate the covariance matrix:
    covariance_matrix = np.cov(centered_points, rowvar = False)
    
    #Perform eigenvalue decomposition (PCA) to find the primary axes:
    eigenvalues, eigenvectors = np.linalg.eigh(covariance_matrix)
    
    #Sort eigenvectors by magnitude of eigenvalues:
    sorted_indices = np.argsort(eigenvalues)[::-1]
    eigenvectors = eigenvectors[:, sorted_indices]
    
    #The first two eigenvectors (U & V) define the best-fit plane
    U = eigenvectors[:, 0] # New X basis vector (direction of most variance/length)
    V = eigenvectors[:, 1] # New Y basis vector (direction of second most variance/height)
    
    #The third eigenvector is the robust normal vector (N):
    N = eigenvectors[:, 2]
    
    #Return values:
    #U, V, and N are quaranteed to be orthogonal unit vectors.
    return U, V, N, centroid
    




def calculate_affine_parameters_robust(point_ls):
    
    """
        Function that calculates robust ST_Affine parameters 
        (for PostGIS) using PCA alignment and translation
        
    """
    
    #Call function to obtain the eigenvectors U, V, and N along
    #with the vertical (WallSurface) polygon centroid:
    U, V, N, centroid = calc_orthogonal_basis_from_points(point_ls)
    
    #We use the calculated U, V, and N as our rotation matrix R:
    R = np.vstack([U, V, N])
    
    #Translate the centroid to the origin
    #in the new coordinate system:
    T = -R @ centroid
    xoff, yoff, zoff = T
    
    #Extract the 12 parameters of the Affine transformation:
    a, b, c = R[0]
    d, e, f = R[1]
    g, h, i = R[2]
    
    #Return the Affine transformation parameters:
    return a, b, c, d, e, f, g, h, i, xoff, yoff, zoff
    




#Call function to get Affine transformation parameters
#for a given vertical (WallSurface) polygon: 
a, b, c, d, e, f, g, h, i, xoff, yoff, zoff = calculate_affine_parameters_robust(tups)




#Print the parameters of the Affine trnasformation:
print('\033[1m'+'Affine transformation parameters'+'\033[0m')
print('\033[1m'+'a: '+'\033[0m'+ '{0:.40f}'.format(a))
print('\033[1m'+'b: '+'\033[0m'+ '{0:.40f}'.format(b))
print('\033[1m'+'c: '+'\033[0m'+ '{0:.40f}'.format(c))
print('\033[1m'+'d: '+'\033[0m'+ '{0:.40f}'.format(d))
print('\033[1m'+'e: '+'\033[0m'+ '{0:.40f}'.format(e))
print('\033[1m'+'f: '+'\033[0m'+ '{0:.40f}'.format(f))
print('\033[1m'+'g: '+'\033[0m'+ '{0:.40f}'.format(g))
print('\033[1m'+'h: '+'\033[0m'+ '{0:.40f}'.format(h))
print('\033[1m'+'i: '+'\033[0m'+ '{0:.40f}'.format(i))
print('\033[1m'+'xoff: '+'\033[0m'+ '{0:.40f}'.format(xoff))
print('\033[1m'+'yoff: '+'\033[0m'+ '{0:.40f}'.format(yoff))
print('\033[1m'+'zoff: '+'\033[0m'+ '{0:.40f}'.format(zoff))


# 
# ### Notes
# 
# **Python version:** 3.8.8
# 
# **Python modules to install:**
# #!pip install "psycopg[binary,pool]"
# #!pip install SQLAlchemy==2.0.44
# #!pip3 install pandas==2.0.3 
# 
# 
# Developed by: XXXXXX XXXXXXX
# Last updated: 2025-11-23