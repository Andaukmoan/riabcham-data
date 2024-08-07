#Load packages
packages <- c("readxl","DBI", "properties","RSQLite","xlsx")
install.packages(setdiff(packages, rownames(installed.packages()))) 
library(readxl)
library(DBI)
library(properties)
library(RSQLite)
library(xlsx)

#Choose path to database file
database.path<- rstudioapi::selectFile(caption = "Select database file")

#Do you have files from training in CPA that need to be used in place of the standard outputs?
cpa_file_answer <- rstudioapi::showPrompt("CellProfiler Analyst selection", "Do you have files from cellprofiler analyst to use for the classification counts? (Yes/No)")

if (cpa_file_answer == "Yes"){
  #Choose path to cytoplasmic DDX4+ counts files.
  cyto_path <- rstudioapi::selectFile(caption = "Select cytoDDX4 counts file")
  
  #Choose path to cytoplasmic DDX4+ / EdU+ counts files.
  double_path <- rstudioapi::selectFile(caption = "Select cytoDDX4/EdU counts file")
  
  #cyto_path
  #double_path  
}

#Open connection to data base
con <- dbConnect(RSQLite::SQLite(), database.path)
#Get table of data frames in data base
Tables <- as.data.frame(dbListTables(con))
#Get name of data frame with per image counts
Table <- as.data.frame(grep("Per_Image", Tables[,1], value = TRUE))
Table <- as.data.frame(grep("Per_Image_", Table[,1], value = TRUE, invert = TRUE))
#Create new object with data frame of per image counts
image.data <- dbReadTable(con, Table[[1]])
#Close connection to data base
dbDisconnect(con)

#Open CSV files from CPA.
if (cpa_file_answer == "Yes"){
  cyto <- read.csv(cyto_path)
  double <- read.csv(double_path)  
}

#Subset relevant columns
somatic <- image.data[c("Image_Metadata_Plate","Image_Metadata_Well","Image_Count_Filtered_nuclei")]
txrd <- image.data[c("Image_Metadata_Plate","Image_Metadata_Well","Image_Count_Combined_DDX4")]
somatic_edu <- image.data[c("Image_Metadata_Plate","Image_Metadata_Well","Image_Count_Filtered_somatics")]

if (cpa_file_answer == "Yes"){
  cyto <- cyto[c("Image_Metadata_Plate", "Image_Metadata_Well", "Positive..Cell.Count")]
  double <- double[c("Image_Metadata_Plate", "Image_Metadata_Well", "Positive..Cell.Count")]  
}else{
  cyto <- image.data[c("Image_Metadata_Plate","Image_Metadata_Well","Image_Count_CombinedObjects")]
  double <- image.data[c("Image_Metadata_Plate","Image_Metadata_Well","Image_Count_cytoDDX4_EdU")]  
}

#Reorder data (just in case)
#Order by well
somatic <- somatic[order(somatic[,"Image_Metadata_Well"]),]
txrd <- txrd[order(txrd[,"Image_Metadata_Well"]),]
somatic_edu <- somatic_edu[order(somatic_edu[,"Image_Metadata_Well"]),]
cyto <- cyto[order(cyto[,"Image_Metadata_Well"]),]
double <- double[order(double[,"Image_Metadata_Well"]),]
#Order by plate
somatic <- somatic[order(somatic[,"Image_Metadata_Plate"]),]
txrd <- txrd[order(txrd[,"Image_Metadata_Plate"]),]
somatic_edu <- somatic_edu[order(somatic_edu[,"Image_Metadata_Plate"]),]
cyto <- cyto[order(cyto[,"Image_Metadata_Plate"]),]
double <- double[order(double[,"Image_Metadata_Plate"]),]

#Calculate somatic cell number
somatic[,4] <- somatic[,3]-txrd[,3]
somatic[,4] <- somatic[,4]-somatic_edu[,3]
#Calculate dead DDX4 per well
txrd["Dead_DDX4"] <- txrd[,3] - cyto[,3]

#Check for inconsistencies between group and subgroup
check_somatic <- somatic[somatic[,4]<0,]
check_cyto <- cyto[cyto[,3]<double[,3],]
check_txrd <- txrd[txrd[,4] < 0,]

#Save per image data

df <- cbind(somatic[c(1,2,4)],somatic_edu[,3], (txrd[,3]-cyto[,3]),cyto[,3],double[,3],(double[,3]/cyto[,3]*100))
colnames(df) <- c("Plate", "Well","Somatic", "Somatic/EdU","Dead_DDX4","cytoDDX4","DDX4/EdU","Percent_Double")
df[is.na(df["Percent_Double"]),"Percent_Double"] <- 0

#Subset out plates
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
  file <- paste0(u.Plate[i,1],"_per_image_DDX4EdUv7_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx(save,file)
}

#Create functions


#Function for summing image counts per well
sum_well <- function(a="df", b = "Image_Metadata_Well", c = "Image_Count_TotalCells"){
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
apply_plate <- function(a="df", b="Image_Metadata_Plate",d="Function", c="Well", e="Column Names", f="column"){
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

#Sum somatic cells per well per plate
somatic <- apply_plate(a=somatic,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_TotalCells"), f = "Image_Count_Filtered_nuclei")
#Sum Txrd+ cells per well per plate
txrd <- apply_plate(a=txrd,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_txrd"), f = "Image_Count_Combined_DDX4")
#Sum Txrd-/EdU+ cells per well per plate
somatic_edu <- apply_plate(a=somatic_edu,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_edu"), f = "Image_Count_Filtered_somatics")

if (cpa_file_answer == "Yes"){
  #Sum cytoDD4+ cells per well per plate
  cyto <- apply_plate(a=cyto,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_cyto"), f = "Positive..Cell.Count")
  #Sum double positive cells per well per plate
  double <- apply_plate(a=double,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_double"), f = "Positive..Cell.Count")  
}else{
  #Sum cytoDD4+ cells per well per plate
  cyto <- apply_plate(a=cyto,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_cyto"), f = "Image_Count_CombinedObjects")
  #Sum double positive cells per well per plate
  double <- apply_plate(a=double,b="Image_Metadata_Plate",d=sum_well, c="Image_Metadata_Well", e=c("Metadata_Plate","Metadata_Well","Count_double"), f = "Image_Count_cytoDDX4_EdU")  
}

#Calculate somatic cells per well
somatic["Somatic_Count"] <- somatic$Count_TotalCells - txrd$Count_txrd
somatic["Somatic_Count"] <- somatic$Somatic_Count - somatic_edu$Count_edu
#Calculate dead DDX4 per well
txrd["Dead_DDX4"] <- txrd$Count_txrd - cyto$Count_cyto

#Combine data sets and resolve NaN
df <- cbind(somatic[c(1,2,4)], somatic_edu$Count_edu, (txrd[,3]-cyto[,3]),cyto[,3],double[,3],(double[,3]/cyto[,3]*100))
colnames(df) <- c("Plate", "Well","Somatic", "Somatic/EdU","Dead_DDX4","cytoDDX4","DDX4/EdU","Percent_Double")
df[is.na(df["Percent_Double"]),"Percent_Double"] <- 0

#Subset out plates
u.Plate <- as.data.frame(unique(df["Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df["Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]
names(per_plate)

counts_df <- df
counts_per_plate <- per_plate

#Save data sets
for (i in 1:length(per_plate)){
  file <- paste0(u.Plate[i,1],"_DDX4EdUv7_quantification.xlsx")
  save <- per_plate[[i]]
  write.xlsx(save,file)
}

#Open data base connection
con <- dbConnect(RSQLite::SQLite(), database.path)
#Get list of tables
Tables <- as.data.frame(dbListTables(con))
#Get name of relationshipsview data frame
Table <- as.data.frame(grep("RelationshipsView", Tables[,1], value = TRUE))
#Get relationshipsview data frame
Per_RelationshipsView <- dbReadTable(con, Table[1,1])
#Close data base connection
dbDisconnect(con)

#This code is really gross. I am so sorry I did not document it better. I could not find a good way to do this, so I took a very round about way that is long and clunky and gives a ton of warning messages because I coerce the living daylights out of the data.

#Get Neighbor relationships
Neighbors <- Per_RelationshipsView[Per_RelationshipsView$relationship == "Neighbors",]

#Create data frame to store output
output <- data.frame()

#Get list of unique images
u.image <- sort(unique(Neighbors$image_number1))

#Loop through each unique image
for (i in 1:length(u.image)){
  
  #Subset values for the given image
  image_Neighbors <- Neighbors[Neighbors$image_number1==u.image[i],]
  
  #object_number1 <- c(1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20)
  #object_number2 <- c(2,1,3,2,4,3,5,4,6,5,7,6,8,7,9,8,10,9,11,10,12,11,13,12,14,13,15,14,16,15,17,16,18,17,19,18,20,19)
  #image_Neighbors <- cbind(object_number1,object_number2)
  #image_Neighbors <- as.data.frame(image_Neighbors)
  
  #Remove duplicate relationships. Not strictly necessary yet but reduces number of objects
  u.number <- unique(image_Neighbors$object_number1)
  u.Neighbors <- data.frame()
  for (i in 1:length(u.number)){
    if (!u.number[i] %in% u.Neighbors$object_number1){
      temp <- image_Neighbors[u.number[i] == image_Neighbors$object_number2,]  
      u.Neighbors <- rbind(u.Neighbors,temp)} else {
        temp <- image_Neighbors[u.number[i] == image_Neighbors$object_number2,]
        number <- u.number[i]
        u.temp <- unique(temp$object_number1)
        for (i in 1:length(u.temp)){
          if (u.temp[i] %in% u.Neighbors$object_number1 & !u.temp[i] %in% u.Neighbors[u.Neighbors$object_number1 == number, "object_number2"]){
            temp_2 <- temp[u.temp[i] == temp$object_number1,]
            u.Neighbors <- rbind(u.Neighbors,temp_2)      
          }}}}
  
  #Create list of relationships
  u.Neighbors_list <- list()
  for (i in 1:length(u.Neighbors$object_number1)){
    temp <- c(u.Neighbors$object_number1[i], u.Neighbors$object_number2[i])
    u.Neighbors_list[[length(u.Neighbors_list)+1]] <- temp
  }
  
  #Find connections between objects
  u.Neighbors_group <- list()
  for (i in 1:length(u.Neighbors_list)){
    temp <- u.Neighbors_list[[i]]
    for (j in 1:length(u.Neighbors_list)){
      if (any(u.Neighbors_list[[i]] %in% u.Neighbors_list[[j]])){
        temp <- union(temp, u.Neighbors_list[[j]])
      }    
    }
    u.Neighbors_group[[length(u.Neighbors_group)+1]] <- temp
  }
  
  #Find connections between objects a second time
  u.Neighbors_list <- list()
  for (i in 1:length(u.Neighbors_group)){
    temp <- u.Neighbors_group[[i]]
    for (j in 1:length(u.Neighbors_group)){
      if (any(u.Neighbors_group[[i]] %in% u.Neighbors_group[[j]])){
        temp <- union(temp, u.Neighbors_group[[j]])
      }    
    }
    u.Neighbors_list[[length(u.Neighbors_list)+1]] <- temp
  }
  
  #Find connections between objects a third time
  #This allows us to group objects together that are within 14 connections of each other. I am assuming we won't have more than 14 connections between objects.
  #Check colony size. If any colonies are 15+, then we need to revisit this assumption.
  temp_2 <- list()
  for (i in 1:length(u.Neighbors_list)){
    temp <- u.Neighbors_list[[i]]
    for (j in 1:length(u.Neighbors_list)){
      if (any(u.Neighbors_list[[i]] %in% u.Neighbors_list[[j]])){
        temp <- union(temp, u.Neighbors_list[[j]])
      }    
    }
    temp_2[[length(temp_2)+1]] <- temp
  }
  u.Neighbors_list <- temp_2
  
  #Remove duplicates
  u.Neighbors_group <- list(u.Neighbors_list[[1]])
  for (i in 1:length(u.Neighbors_list)){
    temp <- list()
    for (j in 1:length(u.Neighbors_group)){
      temp <- c(temp, any(u.Neighbors_list[[i]] %in% u.Neighbors_group[[j]]))
    }
    if (!any(temp)){
      u.Neighbors_group[[length(u.Neighbors_group)+1]] <- u.Neighbors_list[[i]] 
    }
  }
  
  #Get number of unique colonies
  colony <- c(1:length(u.Neighbors_group))
  
  #Get colony size
  colony_size <- unlist(lapply(u.Neighbors_group, length))
  
  #Create data frame with unique colonies, colony size, and image number
  colonies <- cbind(unique(image_Neighbors$image_number1), colony, colony_size)
  colnames(colonies) <- c("ImageNumber","colony","colony_size")
  
  #Add data to output data frame
  output <- rbind(output,colonies)
}



#Add plate and well metadata columns
df <- cbind(0,0,output)
colnames(df) <- c("Metadata_Plate","Metadata_Well", colnames(output))

#Add plate and well values based on image number
for (i in 1:length(df[[1]])){
  df[i,c("Metadata_Plate","Metadata_Well")] <- image.data[df[i,"ImageNumber"]==image.data[,"ImageNumber"], c("Image_Metadata_Plate","Image_Metadata_Well")]  
}

#Save data frame missing images
sdf <- df

#Identify missing images.
missing <- image.data[!image.data[,"ImageNumber"] %in% df[,"ImageNumber"],1]


if (length(missing) > 1){
  missing <- cbind(0,0,missing,0,0)
  missing <- as.data.frame(missing)
  colnames(missing) <- c("Metadata_Plate","Metadata_Well", colnames(output))
  
  for (i in 1:length(missing[[1]])){
    missing[i,c("Metadata_Plate","Metadata_Well")] <- image.data[missing[i,"ImageNumber"]==image.data[,"ImageNumber"], c("Image_Metadata_Plate","Image_Metadata_Well")]  
  }
  
  df <- rbind(df,missing)
} else {
  print("No missing images")
}

#Save raw data files per plate.
#Create list with a data frame for each plate.
u.Plate <- as.data.frame(unique(df["Metadata_Plate"]))
per_plate <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    per_plate[[i]] <- df[df["Metadata_Plate"]==u.Plate[i,1],] 
  }} else {
    per_plate <- list(df)
  }
names(per_plate) <- u.Plate[,1]

#Create data frame with file names based on plate names.
filename <- as.data.frame(sapply(u.Plate, paste0,"_raw_colony_data.xlsx"))


#Save each plate to a separate xlsx file.
#I used lapply for fun, but a for loop would look cleaner.
lapply(1:length(per_plate), function(a) write.xlsx(per_plate[[a]], 
                                                   file = filename[a,1],
                                                   row.names = FALSE))

#Create functions

#Sum number of colonies per well
sum_well <- function(a, b = "Metadata_Well", c = "colony"){
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
summary_colony <- function(a, b = "Metadata_Well", c = "colony_size"){
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
column_names <- c("Metadata_Plate","Metadata_Well", "Colony_Count","Colony_Min","Colony_1st_Q","Colony_Median","Colony_Mean","Colony_3rd_Q","Colony_Max")
#Combine images per well per plate using functions created in previous chunk
per_well <- apply_plate2(a=sdf, b="Metadata_Plate",c="Metadata_Well",d=sum_well, e=column_names, f=summary_colony)


#Add missing wells
if (length(missing) >1){
  
  #Get missing wells
  missing_well <- apply_plate2(a=missing, b="Metadata_Plate",c="Metadata_Well",d=sum_well, e=column_names, f=summary_colony)
  #Set colony counts to zero
  missing_well$Colony_Count <- 0
  #Split data frame into list of data frames per plate
  u.Plate <- as.data.frame(unique(per_well["Metadata_Plate"]))
  per_plate <- list(c(1))
  if (length(u.Plate[,1])>1){
    for (i in 1:length(u.Plate[,1])){
      per_plate[[i]] <- per_well[per_well["Metadata_Plate"]==u.Plate[i,1],] 
    }} else {
      per_plate <- list(per_well)
    }
  names(per_plate) <- u.Plate[,1]
  
  #Split missing well data frame
  u.missing <- as.data.frame(unique(missing_well["Metadata_Plate"]))
  per_plate_missing <- list(c(1))
  if (length(u.missing[,1])>1){
    for (i in 1:length(u.missing[,1])){
      per_plate_missing[[i]] <- missing_well[missing_well["Metadata_Plate"]==u.missing[i,1],] 
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
    temp <- mdf[!mdf$Metadata_Well %in% df$Metadata_Well,]
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
per_well <- per_well[order(per_well[,"Metadata_Well"]),]

#Order by plate
per_well <- per_well[order(per_well[,"Metadata_Plate"]),]

#Save raw data files per plate
#Create list with a data frame for each plate
u.Plate <- as.data.frame(unique(per_well["Metadata_Plate"]))
plate_summary <- list(c(1))
if (length(u.Plate[,1])>1){
  for (i in 1:length(u.Plate[,1])){
    plate_summary[[i]] <- per_well[per_well["Metadata_Plate"]==u.Plate[i,1],] 
  }} else {
    plate_summary <- list(per_well)
  }

#Create data frame with file names based on plate names
filename <- as.data.frame(sapply(u.Plate, paste0,"_colony_counts_per_well.xlsx"))


#Save each plate to a separate csv file.
for (i in 1:length(plate_summary)){
  write.xlsx(plate_summary[[i]], filename[i,1])
}
