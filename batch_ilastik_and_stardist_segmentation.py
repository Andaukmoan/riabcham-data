#Script to process a folder of images with a nuclei channel (d0) and a cytoplasm channel (d2). 
#Returns an image of ROIs for nuclei that can be imported into cellprofiler as objects.
#Returns a binary image of pixels associated with cytoplasm that can be used to identify secondary objects in cellprofiler.

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

#Import modules for stardist
from stardist.models import StarDist2D
from stardist.data import test_image_nuclei_2d
from stardist.plot import render_label
from csbdeep.utils import Path, normalize
from csbdeep.io import save_tiff_imagej_compatible
import matplotlib
matplotlib.rcParams["image.interpolation"] = 'none'
import matplotlib.pyplot as plt
from stardist import export_imagej_rois
from tqdm import tqdm

## 1. Convert Images from TIF to h5

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


#Start conversion from TIF to h5
if __name__ == "__main__":    
    #Let me know conversion has started
    print("Starting conversion")
    # Execute function on a thread (concurrently)
    a = threading.Thread(target=execute_conversion)
    a.start()
    #Block main execution until function is terminated
    a.join()
    #Let me know conversion has finished
    print("Finished conversion")

## 2. Segment h5 images with ilastik

#Get start directory
start_dir = os.getcwd()
#Set location of ilastik exe file
ilastik_location = 'C:/Program Files/ilastik-1.4.0/'
#Set location of ilastik project
ilastik_project = 'C:/Users/user_name/Desktop/pipeline_v6.1/segmentation_v2_3.ilp'
#Get all files in selected folder 
inputfiles = os.listdir(indir)
#Set directory to location of ilastik exe file
os.chdir(ilastik_location)

#Define function for segmenting DDX4 files with ilastik
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
    #Let me know segmentation has started
    print("Start segmentation")
    # Execute execute_DDX4 on a thread (concurrently)
    a = threading.Thread(target=execute_segmentation)
    a.start()
    #Block main execution until execute_DDX4 is terminated
    a.join()
    os.chdir(start_dir)
    print("Finished segmentation")

## 3. Segment Nuclei with stardist

#Get pretrained model
model = StarDist2D.from_pretrained('2D_versatile_fluo')


#Creat function for segmenting nuclei with stardist
def execute_segment_nuclei():
    for infile in infiles:
    #Exclude files that are not TIF format from processing
        if infile[-6:] != 'd0.TIF':
            print("skipping %s" % infile)
            continue
        #Combine path and file name
        inputs = indir + infile
        #load image
        img = Image.open(inputs)
        #Convert image to numpy array
        img_array = np.asarray(img)
        #Get prediction
        labels, polygons = model.predict_instances(normalize(img_array))
        #Remove file suffix from name
        outfile = inputs[:-4]
        #Save prediction as ROIs
        save_tiff_imagej_compatible('%s_labels.tif' % outfile, labels, axes='YX')
        

#Start nuclei segmentation
if __name__ == "__main__":    
    #Let me know segmentation has started
    print("Starting nuclei segmentation")
    # Execute function on a thread (concurrently)
    a = threading.Thread(target=execute_segment_nuclei)
    a.start()
    #Block main execution until function is terminated
    a.join()
    #Let me know conversion has finished
    print("Finished nuclei segmentation")
