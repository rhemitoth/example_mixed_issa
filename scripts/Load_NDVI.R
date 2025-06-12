## ---------------------------
##
## Script name: Load NDVI (Pre-Wolf)
##
## Author: Rhemi Toth
##
## Date Created: 2025-04-09
##
## Email: rhemitoth@g.harvard.edu
##
## ---------------------------
##
## Notes:
##   
##
## ---------------------------


# Load Packages -----------------------------------------------------------

library(tidyverse)
library(terra)

# Load NDVI -------------------------------------------------------------

ndvi_folder <- "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Sentinel2_NDVI"
ndvi_files <- list.files(ndvi_folder, pattern = "\\.tif$")
ndvi_files <- ndvi_files[!grepl("\\.xml$", ndvi_files)]


# Get the dates of the images
ndvi_dates <- sub("NDVI_","",ndvi_files)
ndvi_dates <- sub(".tif","",ndvi_dates)
ndvi_dates <- ymd(ndvi_dates)

# Filter for dates in the post-wolf period
ndvi <- tibble(filename = ndvi_files,
               date = ndvi_dates) %>%
  mutate(filepath = paste0(ndvi_folder, "/", ndvi_files)) %>%  
  filter(date < as.Date("2020-03-09"))  


num_ndvi_files <- nrow(ndvi)
