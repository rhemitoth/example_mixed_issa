## ---------------------------
##
## Script name: Load Human Settlement
##
## Author: Rhemi Toth
##
## Date Created: 2025-04-15
##
## Email: rhemitoth@g.harvard.edu
##
## ---------------------------
##
## Notes: This script loads the human settlement data into R
##   
##
## ---------------------------

# libraries ---------------------------------------------------------------

library(terra)
library(tidyverse)


# Load the data -----------------------------------------------------------

hs_folder <- "/Users/rhemitoth/Library/CloudStorage/OneDrive-HarvardUniversity/Documents/Rhemi/Cembra/GIS/Images/dist_to_settlements"

all_files <- list.files(hs_folder, pattern = "\\.tif$", full.names = FALSE)
hs_files <- all_files[!grepl("\\.xml", all_files)]

hs <- tibble(filepath = character(),
             year = double())

for(i in 1:length(hs_files)){
  
  # Get the filepath
  file <- hs_files[i]
  filepath <- paste(hs_folder,file,sep = "/")
  
  # Get the year
  yr <- sub("dst_settlements_","",file)
  print(yr)
  yr <- sub(".tif","",yr)
  print(yr)
  yr <- as.numeric(yr)
  print(yr)
  

  row <- tibble(filepath = filepath,
                year = yr)
  
  hs <- rbind(hs, row)
  
}

