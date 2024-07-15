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
