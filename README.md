# riabcham-data
Prepare data for cellprofiler

This repository is for files to help prepare images for my cellprofiler pipeline.

The main file is "batch_ilastik_and_stardist_segmentation.py".
This script will process a folder of images with a nuclei channel (d0) and a cytoplasm channel (d2). 
Returns an image of ROIs for nuclei that can be imported into cellprofiler as objects.
Returns a binary image of pixels associated with cytoplasm that can be used to identify secondary objects in cellprofiler.

