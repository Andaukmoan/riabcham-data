/*
 * Macro to segment nuclei using stardist for all d0 images in a folder
 */

#@ File (label = "Input directory", style = "directory") input

output = input;
suffix = "d0.TIF";

processFolder(input);

// function to scan folder to find files with correct suffix
function processFolder(input) {
	// print("Started segmenting")
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
	// print("Finished segmenting")
}

// function to segment nuclei using stardist and save output as ROI labels
function processFile(input, output, file) {
	inputFilePath = input + File.separator + file;
	outputFileName = replace(file, suffix, "d0_labels.tif");
	outputFilePath = output + File.separator + outputFileName;
	open(inputFilePath);
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input': "+file+", 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'35.0', 'percentileTop':'99.8', 'probThresh':'0.39999999999999997', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	selectImage("Label Image");
	// print("Finished segmenting " + outputFileName);
	saveAs("Tiff", outputFilePath);
    close("*");
    close("ROI Manager");
}