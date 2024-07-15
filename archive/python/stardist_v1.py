#Select input directory
#FILE PATH MUST END WITH "/"
indir = ""

#Import modules for converting tif to numpy array
from PIL import Image
import numpy as np

#Import modules for processing folders
import os
import threading
import re, glob, os 
from os import walk
from os import listdir
from os.path import isfile, join

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

#Get all files in directory
infiles = os.listdir(indir)

#Get pretrained stardist model
model = StarDist2D.from_pretrained('2D_versatile_fluo')

#Define function for executing a python script
def execute_script(name):
        os.system('python ' + name)

#Create function for segmenting nuclei with stardist
def execute_segment_nuclei():
    print("Starting nuclei segmentation")
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
        print('\nSegmented %s' % infile)
    print("Finished nuclei segmentation")
    
#Execute function
execute_segment_nuclei()
