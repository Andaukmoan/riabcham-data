/*
 * Macro to batch convert ets files to tif.
 */
 
  //Set global variables
  setBatchMode(true);
  dir = "/uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/images/Folder_20240710/";
  //dir = getArgument();
  
  //Process folder with subfolders containing ets files
  processFolder(dir); 
  print("Finished processing folder");
    
  //Function to process folder with processFile function
  function processFolder(dir) {
     list = getFileList(dir);
     for (i=0; i<list.length; i++) {
        print("starting " + list[i]);
        if (endsWith(list[i], "/"))
           processFolder(""+dir+list[i]);
        else if (endsWith(list[i], ".ets"))
           processFile(dir, list[i]);
        else
       	   print("skipping " + list[i]); }}
  
  //Function to convert ets files to tif files. This function assumes the files have the file path "*/<plate and well name>/stack1/<file>".
  function processFile(input, file) {
	   inputFilePath = input + file;
	   print("Processing: " + inputFilePath);
	   openArgs = "open=[" + inputFilePath + "] autoscale color_mode=Default rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT series_1";
	   run("Bio-Formats Importer", openArgs);
	   selectImage(1);
	   parent = File.getParent(input);
	   outputPath = parent + "d0.TIF";
	   saveAs("Tiff", outputPath);
	   selectImage(2);
	   outputPath = parent + "d1.TIF";
	   saveAs("Tiff", outputPath);
	   selectImage(3);
	   outputPath = parent + "d2.TIF";
	   saveAs("Tiff", outputPath);
	   close("*");
	   print("Finished: " + inputFilePath); }
 
