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
        if infile[-4:] != '.TIF':
            print("skipping %s" % infile)
            continue
        #Combine path and file name
        input = indir + infile
        #load image
        img = Image.open(input)
        #Convert image to numpy array
        img_array = np.asarray(img)
        #Remove file suffix from name
        outfile = input[:-4]
        #Create empty h5 file
        h5f = h5py.File('%s.h5' % outfile, 'w')
        #Add numpy array to empty h5 file
        h5f.create_dataset('data', data=img_array)
        #Close h5 file
        h5f.close()

print("Starting conversion")
execute_conversion()
print("Finished conversion")
