## ---------------------------
##
## Script name: Extract Covariates
##
## Author: Rhemi Toth
##
## Date Created: 2025-04-23
##
## Email: rhemitoth@g.harvard.edu
##
## ---------------------------
##
## Notes:
##   
##
## ---------------------------

rm(list = ls())

# Load Packages -----------------------------------------------------------

library(tidyverse)
library(amt)
library(terra)
library(parallel)
library(lubridate)


# Load the used and avail points ------------------------------------------

load("/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/used_avail.RData")

# Specify the number of batches for the extraction
num_batches <- 50

# Split the data into n batches
obs_avail_full <- obs_avail %>%
  mutate(batch = cut_number(row_number(), n = num_batches, labels = FALSE))

# Load Static Covariates --------------------------------------------------

slope <- rast("/Users/rhemitoth/Library/CloudStorage/OneDrive-HarvardUniversity/Documents/Rhemi/Cembra/GIS/Images/TINITALY/slope.tif")
aspect <- rast("/Users/rhemitoth/Library/CloudStorage/OneDrive-HarvardUniversity/Documents/Rhemi/Cembra/GIS/Images/TINITALY/aspect.tif")
elev <- rast("/Users/rhemitoth/Library/CloudStorage/OneDrive-HarvardUniversity/Documents/Rhemi/Cembra/GIS/Images/TINITALY/w51065_s10.tif")
fs <- rast("/Users/rhemitoth/Library/CloudStorage/OneDrive-HarvardUniversity/Documents/Rhemi/Cembra/GIS/Images/Distance_To_FS/dist_to_fs/dist_to_fs")
roads <- rast("/Users/rhemitoth/Library/CloudStorage/OneDrive-HarvardUniversity/Documents/Rhemi/Cembra/GIS/Images/distance_to_roads/dst_roads_big/dst_roads_big.tif")

# Reclassify Aspect -------------------------------------------------------

# Reclassify the adjusted aspect raster to N, E, S, W
reclass_matrix <- matrix(c(
  0, 45,   1,   # North (315° to 45°)
  45, 135,   2,   # East (45° to 135°)
  135, 225,  3,   # South (135° to 225°)
  225, 315,  4,    # West (225° to 315°)
  315,360,5
), byrow = TRUE, ncol = 3)

# Reclassify the adjusted aspect raster
aspect <- classify(aspect, reclass_matrix)

# Load NDVI ---------------------------------------------------------------

source("/Users/rhemitoth/Documents/PhD/Cembra/observed_movement/scripts/Pre-Wolf/Load_NDVI.R")

# Load Distance to Human Settlement ---------------------------------------

source("/Users/rhemitoth/Documents/PhD/Cembra/observed_movement/scripts/Pre-Wolf/Load_Human_Settlement.R")

# Process the data in batches
for(i in 1:num_batches){
  
  print(paste("Processing batch ",i, "/",num_batches,sep = ""))
  
  start <- Sys.time()
  
  obs_avail <- obs_avail_full %>%
    filter(batch == i)
  
  
# Extract the static covariates -------------------------------------------

# Extract the static covaraites
print("Extracting static covariates")
obs_avail$elev_end <- terra::extract(elev,vect(obs_avail,geom=c('x2_','y2_')),ID=FALSE)[,1]
obs_avail$aspect_unmapped <- terra::extract(aspect,vect(obs_avail,geom=c('x2_','y2_')),ID=FALSE)[,1]
obs_avail$slope_end <- terra::extract(slope,vect(obs_avail,geom=c('x2_','y2_')),ID=FALSE)[,1]
obs_avail$slope_start <- terra::extract(slope,vect(obs_avail,geom=c('x1_','y1_')),ID=FALSE)[,1]
obs_avail$fs_end <- terra::extract(fs,vect(obs_avail,geom=c('x2_','y2_')),ID=FALSE)[,1]
obs_avail$roads_end <- terra::extract(roads,vect(obs_avail,geom=c('x2_','y2_')),ID=FALSE)[,1]

# Map aspect to class values
obs_avail <- obs_avail %>%
  mutate(aspect_end = ifelse(aspect_unmapped == 1, "N",
                             ifelse(aspect_unmapped == 2, "E",
                                    ifelse(aspect_unmapped ==3, "S",
                                           ifelse(aspect_unmapped == 4, "W", "N")))))%>%
  select(-c(aspect_unmapped))

# Make a date column
obs_avail$date <- date(obs_avail$t2_)

# Make a year column
obs_avail$year <- year(obs_avail$t2_)

# Match to closest NDVI date
obs_avail$ndvi_date <- ndvi_dates[apply(abs(outer(obs_avail$date, ndvi_dates, "-")), 1, which.min)]


#  Extract the dynamic covariates -----------------------------------------

# Function for extraction of dynamic covaraites ---------------------------

#' Extract NDVI and Habitat Suitability Values at a Given Point
#'
#' This function extracts NDVI and habitat suitability (HS) values from raster files
#' at a specified spatial point. The closest temporal match is selected based on the 
#' date associated with the point and the available NDVI and HS datasets.
#'
#' @param point A data frame containing coordinates and date information for a single point. 
#'   Must include columns `x2_`, `y2_`, `ndvi_date` (in "YYYY-MM-DD" format), and `year`.
#' @param ndvi A data frame containing NDVI data. Must include `date` (as string or Date), and `filepath` to raster files.
#' @param hs A data frame containing habitat suitability data. Must include `year` (numeric or integer), and `filepath` to raster files.
#'
#' @return A data frame with two columns:
#'   \describe{
#'     \item{ndvi_end}{NDVI value extracted at the point location and closest date}
#'     \item{hs_end}{Habitat suitability value extracted at the point location and closest year}
#'   }
#'
#' @details 
#' The function uses the `terra` package to convert the point to a spatial object, 
#' selects the raster file with the closest date/year from the NDVI and HS datasets, 
#' and extracts the raster values at the point's location.
#'
#' @import lubridate
#' @import tidyverse
#' @import terra

my_extraction_function <- function(point, ndvi, hs) {
  
  library(lubridate)
  library(tidyverse)
  
  # Convert point to a spatial object
  coords <- terra::vect(point, geom = c("x2_", "y2_"), crs = "EPSG:32632")
  
  # Find closest date in NDVI and HS dataframes
  ndvi_closest <- ndvi %>%
    mutate(date_diff = abs(as.Date(point$ndvi_date) - as.Date(date))) %>%
    slice_min(date_diff)  # Select the row with the closest date
  
  hs_closest <- hs %>%
    mutate(date_diff = abs(point$year - year)) %>%
    slice_min(date_diff)
  
  # Load the rasters from the filepath columns
  ndvi_raster <- terra::rast(ndvi_closest$filepath)
  hs_raster <- terra::rast(hs_closest$filepath)
  
  # Extract values from the rasters at the point's coordinates
  ndvi_val <- terra::extract(ndvi_raster, coords, ID = FALSE)[, 1]
  hs_val <- terra::extract(hs_raster, coords, ID = FALSE)[, 1]
  
  # Return the extracted values as a data frame
  data.frame(ndvi_end = ndvi_val,
             hs_end = hs_val)
}


# Extract the dynamic covariates ------------------------------------------

# Set up a cluster with 4 workers
print("Extracting dynamic covariates")
cl <- parallel::makeCluster(7)

# Export variables to workers
parallel::clusterExport(cl, c("obs_avail",
                              "ndvi",
                              "hs", 
                              "my_extraction_function"))

# Parallelize the loop using parLapply
niter <- nrow(obs_avail)
extracted <- parLapply(cl, 1:niter, function(i) {
  point <- as.data.frame(obs_avail[i, ])
  my_extraction_function(point,ndvi,hs)
})

# Combine the results into a data frame
extracted <- do.call(rbind, extracted)

# Stop the cluster after processing
stopCluster(cl)

# Join back to original steps
obs_avail$ndvi_end   <- extracted$ndvi_end
obs_avail$hs_end <- extracted$hs_end

# Attatch time of day
obs_avail <- time_of_day(obs_avail, where = "both")

# Scale covariates
print("Scaling covariates")
obs_avail$ndvi_end_scaled   <- scale(obs_avail$ndvi_end) %>% as.numeric()
obs_avail$hs_end_scaled <- scale(obs_avail$hs_end)%>% as.numeric()
obs_avail$roads_end_scaled <- scale(obs_avail$roads_end)%>% as.numeric()
obs_avail$fs_end_scaled <- scale(obs_avail$fs_end)%>% as.numeric()
obs_avail$slope_start_scaled <- scale(obs_avail$slope_start)%>% as.numeric()
obs_avail$slope_end_scaled <- scale(obs_avail$slope_end)%>% as.numeric()

#Save the results
print("Saving the results")
outfolder <- "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/issa_data_batches"
outfile <- paste(outfolder,"/","issa_data_",i,".RData",sep = "")
issa_data <- obs_avail
save(issa_data,file = outfile)

end <- Sys.time()
time_elapsed <- end-start
print(paste("Time elapsed ", time_elapsed,sep = ""))
rm(issa_data)
rm(obs_avail)
}

# Path to your folder
folder_path <- "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/issa_data_batches"

# List all .RData files in the folder
rdata_files <- list.files(folder_path, pattern = "\\.RData$", full.names = TRUE)

# Function to load a single file and return `issa_data`
load_issa_data <- function(file) {
  e <- new.env()
  load(file, envir = e)
  e$issa_data  # assumes issa_data exists in each .RData file
}

# Load and combine all issa_data tables
all_issa_data <- lapply(rdata_files, load_issa_data) %>%
  bind_rows()

# Save the combined file
outfolder <- "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf"
outfile <- paste(outfolder,"/","issa_data.RData",sep = "")
save(all_issa_data,file = outfile)


