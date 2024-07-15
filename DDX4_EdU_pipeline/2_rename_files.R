
#Get folder with images
file_path <- rstudioapi::selectDirectory()

#Get files that need to be renamed (have name ending in ".tif")
filenames <- list.files(path=file_path, pattern = "*.tif", full.names = TRUE, recursive = TRUE)

#Go through each file in the list and rename it. This assumes files are named "DAPI", "FITC", and "CY3" and should be renamed "d0", "d1", and "d2" respectively.
list <- list()
for (file in 1:length(filenames)){
  split <- strsplit(filenames[file], "/")
  split <- split[[1]]
  parts <- strsplit(split[length(split)], "_")
  parts <- parts [[1]]
  if (parts[length(parts)] == "DAPI.tif"){
    parts[length(parts)] <- "d0.TIF"
  } else if (parts[length(parts)] == "FITC.tif"){
    parts[length(parts)] <- "d1.TIF"
  } else if (parts[length(parts)] == "CY3.tif"){
    parts[length(parts)] <- "d2.TIF"
  }
  parts[length(parts)-1] <- paste0("f", parts[length(parts)-1])
  parts[length(parts)-2] <- paste0("_Plate_R_p00_0_", parts[length(parts)-2],parts[length(parts)-1],parts[length(parts)])
  name <- "olympus"
  for (i in 2:(length(parts)-2)){
    name <- paste0(name,"_",parts[i])
  }
  for (i in 1:(length(split)-1)){
    if (i == 1){
      file_repath <- split[i]
    } else {
      file_repath <- paste0(file_repath, "/",split[i])
    }
  }
  file_rename <- paste0(file_repath, "/", name)
  list[file] <- file_rename
}
file_renames <- unlist(list)

#Rename each file with the new file name
lapply(1:length(filenames), function (file) file.rename(filenames[file], file_renames[file]))



