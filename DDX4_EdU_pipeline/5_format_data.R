#!/usr/bin/env Rscript

#Load packages
library(xlsx)
library(DBI)
library(RSQLite)

#Get folder with images
file_path <- rstudioapi::selectDirectory()

#Subset "args" based on known delimiters to get user set variables for the rest of the script
channels <- c("DNA","EdU","DDX4")
format_columns <- c("Count_Filterednuclei","Count_Filtered_somatics","Count_Combined_DDX4","Count_CombinedObjects","Count_cytoDDX4_EdU")
name_columns <- c("Hoechst+","Hoechst+_EdU+_cytoDDX4-","Hoechst+_DDX4+","Hoechst+_cytoDDX4+","Hoechst+_cytoDDX4+_EdU+")

#Get all csv files in folder
filenames <- list.files(path=file_path, pattern = "*.csv", full.names = TRUE, recursive = TRUE)
#Get unique csv file types
split_filenames <- strsplit(filenames, "_")
temp <- split_filenames[[1]]
file_types <- temp[length(temp)]
for (i in 2:length(split_filenames)){
  temp <- split_filenames[[i]]
  file_types[length(file_types)+1] <- temp[length(temp)]
}
u.patterns <- unique(file_types)

lf <- list()
#Group all files of the same type into one file
for (pattern in 1:length(u.patterns)){
  #gets the files matching pattern.
  filenames <- list.files(path=file_path, pattern = paste0('*',u.patterns[pattern]), full.names = TRUE, recursive = TRUE)
  file <- gsub(".csv", "", u.patterns[pattern])
  #Load all files as data frames in the list of data frames "ldf".
  ldf <- lapply(filenames, read.csv)
  #Create data frame to store all results in.
  df <- ldf[[1]]
  #Loop through each data frame in the list of data frames and add them to the end of the empty data frame.
  for (data_frame in 2:length(ldf)){
    df <- rbind(df, ldf[[data_frame]])
  }
  #Reorder df by image number
  logic <- unique(colnames(df) %in% "ImageNumber")
  if (length(logic) > 1){
    df <- df[order(df[,"ImageNumber"]),]  
  }
  lf[[pattern]] <- df
  names(lf)[pattern] <- file
  #Get time to use as unique file name
  time <- as.character(Sys.time())
  #Remove spaces and special characters from time
  time <- gsub(" ", "_", time)
  time <- gsub(":", "-", time)
  type <- vector()
  for (i in 1:length(channels)){type <- paste0(type, "_", channels[i])}
  #Save data frame with raw values from each file.
  write.csv(df, file=paste0(file_path,"/counts/",time,"_", file, type, ".csv"), row.names = FALSE)
}

#Create database with image and object information
#Get image data_frame and add to database
#Create path to database and connect to database.
db_path <- paste0(file_path, "/counts/",time,"_database.db")
con <- dbConnect(RSQLite::SQLite(), db_path)
tdf <- lf[[grep("Image",names(lf))]]
#Add "Image" to the beginning of all the column names for cellprofiler"
columns <- colnames(tdf)
for(column in 1:length(columns)){
  if (columns[column] != "ImageNumber" & columns[column] != "ImageSet_ImageSet") {
    columns[column] <- paste0("Image_", columns[column])
  }
}
colnames(tdf) <- columns
#Write data to database and disconnect
dbWriteTable(con, "MyExpt_Per_Image", tdf, overwrite = TRUE)
dbDisconnect(con)
#Get data frames with object data
names <- vector()
for (data_frame in 1:length(lf)){
  logic <- grep("ObjectNumber",colnames(lf[[data_frame]]))
  if (length(logic) > 0){
    names <- append(names, names(lf[data_frame]))
  }
}
#Combine data frames with object data
for (name in 1:length(names)){
  tdf <- lf[[names[name]]]
  columns <- colnames(tdf)
  for (column in 1:length(columns)){
    if (columns[column] != "ImageNumber" & columns[column] != "ObjectNumber"){
      columns[column] <- paste0(names[name], "_", columns[column])
    }
  }
  colnames(tdf) <- columns
  if (name == 1){
    df <- tdf
  } else {
    df <- cbind(df, tdf)
  }
}
df <- df[, !duplicated(colnames(df))]
#Write file with combined object data
write.csv(df, paste0(file_path, "/counts/",time,"_object_data.csv"))
#Write object data to database
con <- dbConnect(RSQLite::SQLite(), db_path)
dbWriteTable(con, "MyExpt_Per_Object", df, overwrite = TRUE)
dbDisconnect(con)
print("New database complete")

#Get image data to get counts per image
image.data <- lf[[grep("Image",names(lf))]]
columns <- colnames(image.data)
cplate <- grep("Metadata_Plate",columns,value=TRUE)
cwell <- grep("Metadata_Well",columns,value=TRUE)
grep(format_columns[1], columns, value=TRUE)
#Subset relevant columns
for (column in 1:length(format_columns)){
  tdf <- image.data[c(cplate, cwell, format_columns[column])]
  tdf <- tdf[order(tdf[,cwell]),]
  tdf <- tdf[order(tdf[,cplate]),]
  if (column == 1){
    df <- tdf
  } else {
    df <- cbind(df,tdf)    
  }
}
df <- df[, !duplicated(colnames(df))]
colnames(df) <- c("Plate", "Well", name_columns)
#Subset data by plate
u.Plate <- as.data.frame(unique(df["Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df["Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]
#Save data sets
for (i in 1:length(per_plate)){
  if (!file.exists(paste0(file_path, "/counts/", u.Plate[i,1]))){
    dir.create(paste0(file_path, "/counts/", u.Plate[i,1]))
  }
  file <- paste0(file_path,"/counts/", u.Plate[i,1],"/",u.Plate[i,1],"_per_image_", type,"_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx2(save,file)
}
#Create functions
#Function for summing image counts per well
sum_well <- function(a="df", b = "Well", c = "Count_TotalCells"){
  u.Well <- unique(a[b])
  per_well <- as.data.frame(c(1))
  if (length(u.Well[,1]) > 1){
    for (i in 1:length(u.Well[,1])){
      per_well[i,1] <- sum(a[a[b]==u.Well[i,1],c])  
    } } else {
      per_well[1,1] <- sum(a[a[b]==u.Well[1,1],c])
    }
  return(per_well)
}
#Apply function by plate in a data set
apply_plate <- function(a="df", b="Plate",d="Function", c="Well", e="Column Names", f="column"){
  u.Plate <- as.data.frame((unique(a[b])))
  temp <- as.data.frame(cbind(0,0,0))
  colnames(temp) <- e
  per_plate <- 0
  if (length(u.Plate[,1]>1)){
    for (i in 1:length(u.Plate[,1])){
      per_plate <- a[a[b]==u.Plate[i,1],]
      per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate, c=f))
      colnames(per_plate) <- e
      temp <- rbind(temp, per_plate)
    }
  } else{
    per_plate <- a[a[b]==u.Plate[1,1],]
    per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate,c=f))
    colnames(per_plate) <- e
    temp <- rbind(temp, per_plate)
  }
  temp <- temp[2:length(temp[,1]),]
  return(temp)
}

#Sum counts per well per plate
for (column in 1:length(name_columns)){
  tdf <- apply_plate(a=df, b="Plate", d=sum_well, c="Well", e=c("Plate", "Well", name_columns[column]), f = name_columns[column])
  if (column == 1){
    counts_per_well <- tdf
  } else {
    counts_per_well <- cbind(counts_per_well, tdf) 
  }
}
counts_per_well <- counts_per_well[, !duplicated(colnames(counts_per_well))]

#Subset out plates
u.Plate <- as.data.frame(unique(counts_per_well["Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- counts_per_well[counts_per_well["Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(counts_per_well)
  }
names(per_plate) <- u.Plate[,1]
#Save data sets
for (i in 1:length(per_plate)){
  if (!file.exists(paste0(file_path, "/counts/", u.Plate[i,1]))){
    dir.create(paste0(file_path, "/counts/", u.Plate[i,1]))
  }
  file <- paste0(file_path,"/counts/",u.Plate[i,1], "/",u.Plate[i,1],"_per_well_",type,"_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx2(save,file)
}

#Check if there is relationship data
logic <- grep("relationship", names(lf))
if (logic > 1){
#Get relationship data from list of data frames
Per_RelationshipsView <- lf[[grep("relationship", names(lf))]]
#Get Neighbor relationships
Neighbors <- Per_RelationshipsView[Per_RelationshipsView$Relationship == "Neighbors",]
#Create data frame to store output
output <- data.frame()
#Get list of unique images
u.image <- sort(unique(Neighbors$First.Image.Number))
#Loop through each unique image
for (image in 1:length(u.image)){
  #Subset values for the given image
  image_Neighbors <- Neighbors[Neighbors$First.Image.Number==u.image[image],]
  #Get unique object numbers for the image
  u.number <- unique(image_Neighbors$First.Object.Number)
  #Create a list of vectors with neighboring objects
  list <- list()
  for (number in 1:length(u.number)){
    temp <- image_Neighbors[u.number[number] == image_Neighbors$First.Object.Number, "Second.Object.Number"]
    temp <- append(temp, u.number[number])
    list[[number]] <- temp
  }
  #Combine vectors that have overlapping objects
  #The number of loops determine how far a part the connections can be and still be recognized as a single colony.
  #The current set up can recognize colonies with objects 244 connections apart.
  #(connections a part still recognized) = 1.000000099*e^(1.098612261*#loops)+0.999999253
  for (i in 1:5){
    if (i == 1){groups <- list()}
    for (vector in 1:length(list)){
      temp <- list[[vector]]
      for (second_vector in 1:length(list)){
        if (any(list[[vector]] %in% list[[second_vector]])){
          temp <- union(temp, list[[second_vector]])
        }
      }
      temp <- temp[order(temp)]
      groups[[vector]] <- temp
    }
    list <- groups
  }
  #Remove duplicate vectors
  list <- unique(list)
  #Get number of unique colonies
  colony <- c(1:length(list))
  #Get colony size
  colony_size <- unlist(lapply(list, length))
  #Create data frame with unique colonies, colony size, and image number
  colonies <- cbind(unique(image_Neighbors$First.Image.Number), colony, colony_size)
  colnames(colonies) <- c("ImageNumber","colony","colony_size")
  #Add data to output data frame
  output <- rbind(output,colonies)
}
#Add plate and well metadata columns
df <- cbind(0,0,output)
colnames(df) <- c(cplate,cwell, colnames(output))
#Add plate and well values based on image number
for (i in 1:length(df[[1]])){
  df[i,c(cplate,cwell)] <- image.data[df[i,"ImageNumber"]==image.data[,"ImageNumber"], c(cplate,cwell)]  
}
#Save data frame without missing images
sdf <- df
#Identify missing images.
missing <- image.data[!image.data[,"ImageNumber"] %in% df[,"ImageNumber"],"ImageNumber"]
if (length(missing) > 1){
  missing <- cbind(0,0,missing,0,0)
  missing <- as.data.frame(missing)
  colnames(missing) <- c(cplate,cwell, colnames(output))
  for (i in 1:length(missing[[1]])){
    missing[i,c(cplate,cwell)] <- image.data[missing[i,"ImageNumber"]==image.data[,"ImageNumber"], c(cplate,cwell)]  
  }
  #Add missing images to df.
  df <- rbind(df,missing)
} else {
  print("No missing images")
}
#Save raw data files per plate.
#Create list with a data frame for each plate.
u.Plate <- as.data.frame(unique(df[cplate]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df[cplate]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]
#Create data frame with file names based on plate names.
filename <- as.data.frame(sapply(u.Plate, paste0,"_individual_colony_data.xlsx"))
#Save each plate to a separate xlsx file.
lapply(1:length(per_plate), function(a) write.xlsx2(per_plate[[a]], file = paste0(file_path, "/counts/", u.Plate[a,1], "/",filename[a,1]), row.names = FALSE))
#Subset data frame by colony size.
#sdf <- sdf[sdf["colony_size"]>2,]
#Create functions
#Sum number of colonies per well
sum_well <- function(a, b = cwell, c = "colony"){
  u.Well <- unique(a[b])
  per_well <- as.data.frame(c(1))
  if (length(u.Well[,1]) > 1){
    for (i in 1:length(u.Well[,1])){
      per_well[i,1] <- sum(a[b]==u.Well[i,1])  
    } } else {
      per_well[1,1] <- sum(a[b]==u.Well[1,1])
    }
  return(per_well)
}
#Summary of colonies per well
summary_colony <- function(a, b = cwell, c = "colony_size"){
  u.Well <- unique(a[b])
  per_well <- cbind(u.Well,0,0,0,0,0)
  if (length(u.Well[,1]) > 1){
    for (i in 1:length(u.Well[,1])){
      per_well[i,] <- t(data.frame(unclass(summary(a[a[b]==u.Well[i,1],c]))))
      
    } } else {
      per_well[1,] <- t(data.frame(unclass(summary(a[a[b]==u.Well[1,1],c]))))
    }
  return(per_well)
}
#Apply two functions by plate in a data set
apply_plate2 <- function(a="df", b="Plate",d="Function", c="Well", e="Column Names", f="Function"){
  u.Plate <- as.data.frame((unique(a[b])))
  temp <- as.data.frame(cbind(0,0,0,0,0,0,0,0,0))
  colnames(temp) <- e
  per_plate <- 0
  if (length(u.Plate[,1]>1)){
    for (i in 1:length(u.Plate[,1])){
      per_plate <- a[a[b]==u.Plate[i,1],]
      per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate), f(per_plate))
      colnames(per_plate) <- e
      temp <- rbind(temp, per_plate)
    }
  } else{
    per_plate <- a[a[b]==u.Plate[1,1],]
    per_plate <- cbind(per_plate[1,1], unique(per_plate[c]), d(per_plate), f(per_plate))
    colnames(per_plate) <- e
    temp <- rbind(temp, per_plate)
  }
  temp <- temp[2:length(temp[,1]),]
  return(temp)
}
#Set column names
column_names <- c(cplate,cwell, "Colony_Count","Colony_Min","Colony_1st_Q","Colony_Median","Colony_Mean","Colony_3rd_Q","Colony_Max")
#Combine images per well per plate using functions created in previous chunk
per_well <- apply_plate2(a=sdf, b=cplate,c=cwell,d=sum_well, e=column_names, f=summary_colony)
#Add missing wells
if (length(missing) >1){
  #Get missing wells
  missing_well <- apply_plate2(a=missing, b=cplate,c=cwell,d=sum_well, e=column_names, f=summary_colony)
  #Set colony counts to zero
  missing_well$Colony_Count <- 0
  #Split data frame into list of data frames per plate
  u.Plate <- as.data.frame(unique(per_well[cplate]))
  per_plate <- list(c(1))
  if (length(u.Plate[,1])>1){
    for (i in 1:length(u.Plate[,1])){
      per_plate[[i]] <- per_well[per_well[cplate]==u.Plate[i,1],] 
    }} else {
      per_plate <- list(per_well)
    }
  names(per_plate) <- u.Plate[,1]
  #Split missing well data frame
  u.missing <- as.data.frame(unique(missing_well[cplate]))
  per_plate_missing <- list(c(1))
  if (length(u.missing[,1])>1){
    for (i in 1:length(u.missing[,1])){
      per_plate_missing[[i]] <- missing_well[missing_well[cplate]==u.missing[i,1],] 
    }} else {
      per_plate_missing <- list(missing_well)
    }
  names(per_plate_missing) <- u.missing[,1]
  #Loop through each plate
  for (i in 1:length(u.missing[,1])){
    #Get counts for each plate
    df <- per_plate[[u.missing[i,1]]]
    #Get potential missing wells for each plate
    mdf <- per_plate_missing[[u.missing[i,1]]]
    #Create temporary file of missing wells
    temp <- mdf[!mdf[cwell] %in% df[cwell],]
    #If there are missing wells, add them to the data frame
    if (length(temp[,1])>=1){
      df <- rbind(df,temp)  
    }
    per_plate[[u.missing[i,1]]] <- df
  }
}
#Create single data frame that contains all the information from each plate.
per_well <- data.frame()
if (length(per_plate) > 1){
  for (i in 1:length(per_plate)){
    per_well <- rbind(per_well, per_plate[[i]])
  } 
} else{
  per_well <- per_plate[[1]]
}
#Reorder data
#Order by well
per_well <- per_well[order(per_well[,cwell]),]
#Order by plate
per_well <- per_well[order(per_well[,cplate]),]
#Save raw data files per plate
#Create list with a data frame for each plate
u.Plate <- as.data.frame(unique(per_well[cplate]))
plate_summary <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    plate_summary[[i]] <- per_well[per_well[cplate]==u.Plate[i,1],] 
  }} else {
    plate_summary <- list(per_well)
  }
#Create data frame with file names based on plate names
filename <- as.data.frame(sapply(u.Plate, paste0,"_colony_counts_per_well.xlsx"))
#Save each plate to a separate csv file.
for (i in 1:length(plate_summary)){
  write.xlsx2(plate_summary[[i]], paste0(file_path,"/counts/", u.Plate[i,1],"/",filename[i,1]))
}
}