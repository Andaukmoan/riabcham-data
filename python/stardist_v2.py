INDIR="C:/Users/Desktop/test/v7_test/test_nuclei/"

from PIL import Image
import numpy as np
import os 
from os import listdir
from stardist.models import StarDist2D
from csbdeep.utils import normalize
from csbdeep.io import save_tiff_imagej_compatible

INFILES=os.listdir(INDIR)

model = StarDist2D.from_pretrained('2D_versatile_fluo')

for INFILE in INFILES:
    if INFILE[-6:] != 'd0.TIF':
        continue
    INPUTS = INDIR + INFILE
    IMG=Image.open(INPUTS)
    IMG_ARRAY = np.asarray(IMG)
    labels,polygons=model.predict_instances(normalize(IMG_ARRAY))
    OUTFILE=INPUTS[:-4]
    save_tiff_imagej_compatible('%s_labels.tif' % OUTFILE, labels, axes='YX')