### 1. Sort the raw images into a separate folder (if necessary):

  a. Go to the folder with the images.

  b. Search for images that have “_R_” in the name. These are the “Raw” image files.

  c. Use control+“A” to select all images and move them to a new folder.

  d. You can process multiple plates at the same time as long as they have different file names by combining the images from multiple plates into a single folder.

### 2. Segment DNA with stardist:

  a. Open “stardist_v1.rmd” in v7_SYCP3_EdU folder on the desktop.
  
  b. Select “Run” and then “Run All”.
  
  c. A popup window will open. Select the folder with your images and then click “Open”.

  d. The pipeline will start running. It will print “Finished nuclei segmentation” when complete.
  
  e. This will take ~2.7 seconds per image.

### 3. Run CellProfiler:

  a. Open up CellProfiler.

  b. Go to file->open project and open “SYCP3_EdU_v7.cpproj” in the v7_SYCP3_EdU folder on the desktop.

  c. Drag and drop the folder(s) with your images into the images module. There should be four types of images.
    
      1. Hoechst (d0.TIF)

      2. EdU (d1.TIF)

      3. SYCP3 (d2.TIF)

      4. Nuclei segmentation (labels.tif)

  d. Go to the “NamesAndTypes” module and click “Update” to verify that your images are properly recognized by the program.

  e. Got the “ExportToDatabase” module. Name your experiment and database file. Set the save destination.

  f. Click “Analyze Images" to run the pipeline.

  g. This will take ~17 seconds per image set.

### 4. Format CellProfiler results with R:

  a. Open up “SYCP3_EdU_v7_quantification_v1.Rmd” in the v7_SYCP3_EdU folder on the desktop.

  b. Select “Run” and then “Run All”.

  c. A popup window will open. Select your database file (this will be saved in the location you chose in cellprofiler and have the name you gave it with a “.db” suffix) and then click “Open”.

  d. Another popup window will open asking if you have files from CPA that you would like to use. Type "Yes" if you do or "No" if you don't.

  e. The output will be saved in the v7_SYCP3_EdU folder on the desktop as an excel file. There will be a separate file for each unique plate name. Move the output to the location you would like to store it long term.

  f. There will be four files per plate:

    1. Raw cell counts
    
    2. Cell counts per well

### Put a copy of the output onto the lab google drive (lab resources->experiment tracking->quantification->your experiment name).
