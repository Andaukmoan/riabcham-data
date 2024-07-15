# DDX4_EdU
Analyze DDX4 and EdU images.

# Setup
**Cellprofiler**

Download and install cellprofiler (v4.2.6) from their website. [link](https://cellprofiler.org/)

Set location of classifier model in "ClassifyObjects" module to location on your machine.
Set location of rules in "FilterObjects" module to location on your machine.

**Python**
1. Pillow

``` 
pip install pillow
```
2. Tensorflow

``` 
pip install tensorflow
```
3. Stardist

``` 
pip install stardist
```

See [stardist repository](https://github.com/stardist/stardist) for more details on setting up stardist.

If stardist has trouble installing, see "riabcham-data->archive->Imagej_macro->batch_stardist.ijm"

*If using Windows, download python from the [website](https://www.python.org/downloads/).

**RStudio**

Instructions on setting up RStudio can be found [link](https://rstudio-education.github.io/hopr/starting.html).

Install Rtools [link](https://cran.r-project.org/bin/windows/Rtools/)

Set the "use_python" function to the location of python on your machine in stardist_v1.rmd.

Go [here](https://github.com/ttimbers/intro-to-reticulate/blob/main/setup-instructions/macos_install_python.md) for troubleshooting issues with the reticulate package.

**ImageJ**

We are currently having issues with the stardist python package on Mac M1 computers. We can also run stardist through Fiji. An imageJ macro for running stardist can be found in the Imagej_macro folder.

Download Fiji (Fiji is just imageJ) from [here](https://imagej.net/software/fiji/downloads).

Install stardist plugin from [here](https://imagej.net/plugins/stardist).

For Mac M1 computers after installing stardist plugin:

1. Select Tensorflow version 1.12 from Edit > Options > Tensorflow.

2. Restart FIJI. 

(see [forum](https://forum.image.sc/t/fiji-crashing-upon-running-stardist-in-mac/47507) for more details)

# Running

The files are numbered in order that they should be run (starting with 1).

Files 1 and 2 are only for images from the olympus microscope otherwise you can start at file 3. 

1. The first file is an imageJ macro that should be run with FIJI. You will need to change the path in the script to the path to the folder you want analyzed.

2. The second file is an R script that can be run in Rstudio. It will open an interactive window for you to select the folder with your images.

3. The third file is a python script. There are two variants (".py" and ".Rmd"). The ".py" is a python file that can be run from command line or your favorite python IDE. The second is an R script that can be used with Rstudio. You can use either depending on your preference. ".py" requires you to write in the path to the folder you want analyzed. ".Rmd" will open an interactive window for you to select the folder of interest.

4. The fourth file is the actual CellProfiler pipeline. You will need to set the paths for the classifier model and rules text (see 4_models folder) to your machine before running the pipeline. Go to the images module, remove any images there, and drag and drop the folder you want analyzed into CellProfiler. Set the output folder for the last two modules (SaveImages and ExportDatabase) to your desired folder. Finally, click run "Analyze Images". This will take around an hour for 100 images and monopolize your computer's resources.

5. The fifth file is an R script that can be run in Rstudio. It will open an interactive window for you to select your database file and another window to select location for the output. This script will output a folder for each plate in the data set. Each folder will have a file for counts per image, counts per well, individual colonies, and colonies per well.
