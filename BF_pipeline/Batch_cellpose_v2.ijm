/*
 * Macro to measure cell area from bright field images
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".TIF") suffix

run("Set Measurements...", "area perimeter redirect=None decimal=3");

processFolder(input);

// function to scan folder to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

// function to run Cellpose, save segmentation, and measure area for a file
function processFile(input, output, file){
	inputFilePath = input + File.separator + file;
	//print("Porcessing: " + inputFilePath);
	outputFileName = replace(file, suffix, "_results.csv");
	outputFilePath = output + File.separator + outputFileName;
	outputimage = replace(file, suffix, "_segmentation.jpg");
	outputimagePath = output + File.separator + outputimage;
	// print("Saving to: " + outputFilePath);
	open(inputFilePath);	
	run("Cellpose Advanced", "diameter=0 cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=12.0 model=cyto2 nuclei_channel=0 cyto_channel=1 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags=");
	selectImage(2);
	run("glasbey_inverted");
	saveAs("Jpeg", outputimagePath);
	run("Set Scale...", "distance=1 known=1 unit=unit global");
	run("Label image to ROIs", "rm=[RoiManager[size=3043, visible=true]]");
	roiManager("Show All");
    roiManager("Measure");
    saveAs(outputFileName, outputFilePath);
    close("*");
    close("ROI Manager");
	close("Results");
}

