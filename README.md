# example_mixed_issa
This repository contains example code for running an iSSA with mixed effects

## Required packages
Before running the code please make sure that the following R packages are installed:
- terra
- tidyverse
- lubridate
- amt
- parallel
- glmmTMB

```
required_packages <- c("terra", "lubridate", "tidyverse", "amt", "parallel", "glmmTMB")
install.packages(setdiff(required_packages, installed.packages()[, "Package"]))

```

## To perform the analysis:
1) **Run used_avail_prewolf.R to generate the used and available steps.**
- This script sources GPS_Data_Summary.R to get the IDs of individuals from the pre-wolf period. 
- As output, the script saves the used and available steps as an RData file
2) **Run extract_covariates.R to extract the covariates at the used and available steps.**
- As input, this script reads in the RData file generated in step 1. 
- This script sources Load_NDVI.R to load the NDVI data and  Load_Human_Settlement.R to load the human settlement data.
- As output, this script saves an RData file of used and available steps with the covariates extracted.
3) **

