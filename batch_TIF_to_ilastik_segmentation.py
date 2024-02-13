#Import modules for converting tif to h5
from PIL import Image
import numpy as np
import h5py

#Import modules for processing folders
import os
import threading
import re, glob, os 
from os import walk
from os import listdir
from os.path import isfile, join
import subprocess


#Set location of folder with images
indir = 'C:/Users/user_name/Desktop/test/raw_images/'
#Get all files in selected folder 
infiles = os.listdir(indir)

#Define function for executing a python script
def execute_script(name):
        os.system('python ' + name)

#Define function for converting files from TIF to h5
def execute_conversion():
    for infile in infiles:
    #Exclude files that are not TIF format from processing
        if infile[-6:] != 'd2.TIF':
            print("skipping %s" % infile)
            continue
        #Combine path and file name
        inputs = indir + infile
        #load image
        img = Image.open(inputs)
        #Convert image to numpy array
        img_array = np.asarray(img)
        #Add tzc dimensions
        img_array = np.expand_dims(img_array, axis=0)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = np.expand_dims(img_array, axis=-1)
        #Remove file suffix from name
        outfile = inputs[:-4]
        #Create empty h5 file
        h5f = h5py.File('%s.h5' % outfile, 'w')
        #Add numpy array to empty h5 file
        h5f.create_dataset('data', data=img_array)
        #Close h5 file
        h5f.close()

#Let me know conversion has started
print("Starting conversion")
#Start conversion from TIF to h5
if __name__ == "__main__":    
    # Execute function on a thread (concurrently)
    a = threading.Thread(target=execute_conversion)
    a.start()
# Block main execution until function is terminated
    a.join()
#Let me know conversion has finished
print("Finished conversion")

#Get start directory
start_dir = os.getcwd()
#Let me know segmentation has started
print("Start segmentation")
#Set location of ilastik exe file
ilastik_location = 'C:/Program Files/ilastik-1.4.0/'
#Set location of ilastik project
ilastik_project = 'C:/Users/user_name/Desktop/pipeline_v6.1/segmentation_v2_3.ilp'
#Get all files in selected folder 
inputfiles = os.listdir(indir)
#Set directory to location of ilastik exe file
os.chdir(ilastik_location)

#Define function for segmenting DDX4 files
def execute_segmentation():
    for infile in inputfiles:
    #Exclude files that are not h5 format from processing
        if infile[-5:] != 'd2.h5':
            print("skipping %s" % infile)
            continue
    #Set variables for ilastik subprocess
        command = '.\ilastik.exe --headless --project="%s" --export_source="Simple Segmentation" --output_filename_format="%s/{nickname}_Simple_Segmentation.tiff"  --raw_data="%s%s"' % (
            ilastik_project,
            indir,
            indir,
            infile)
        print("\n\n%s" % command)
    #Run ilastik subprocess
        subprocess.call(command, shell=True)


if __name__ == "__main__":    
    # Execute execute_segmentation on a thread (concurrently)
    a = threading.Thread(target=execute_segmentation)
    a.start()

    # Block main execution until execute_segmentation is terminated
    a.join()
    
os.chdir(start_dir)
print("Finished segmentation")
