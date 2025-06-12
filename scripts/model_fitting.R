## ---------------------------
##
## Script name: Model Fitting
##
## Author: Rhemi Toth
##
## Date Created: 2025-04-27
##
## Email: rhemitoth@g.harvard.edu
##
## ---------------------------
##
## Notes: This script contains example code for fitting a mixed iSSA. Depending on your computing power,each model may take
## a few minutes to fit.
##   
##
## ---------------------------

rm(list = ls())

# Load Packages -----------------------------------------------------------

library(tidyverse)
library(glmmTMB)


# Load the Data -----------------------------------------------------------

# Used and available steps with covariates extracted
load("/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/issa_data.RData")

# Remove rows where NDVI is null
# This isn't good practice since we are removing some of the used/available steps from the dataset
# However, the code won't run if any of the covariates have NULL values
# When I regenerate NDVI layers using Andre's method, hopefully there will be no NULL values in the dataset
all_issa_data <- all_issa_data %>%
 filter(is.na(ndvi_end)==FALSE)

# Separate data into seasons ----------------------------------------------

# These are just some examples. You can change the definitions and add more seasons

hunting_season <- all_issa_data %>%
  filter(month(t2_) == 11)

summer_season <- all_issa_data %>%
  filter(month(t2_) == 7 | month(t2_) == 8)


# Hunting Season Model ----------------------------------------------------

start <- Sys.time()

m_hunt <- glmmTMB(case_ ~  
  # Movement Parameters
  sl_ + log_sl_ + cos_ta_ +
    # Effects of ToD on Movement
    #tod_start_:(sl_ + log_sl_ + cos_ta_)+
    #Effects of slope on movement and habitat selection
    #slope_start_scaled:(sl_ + log_sl_ + cos_ta_)+
    slope_end_scaled +
  # Effects of anthropogenic disturbance on  habitat selection
  roads_end_scaled +
  hs_end_scaled +
  # Effects of resources on habitat selection
  ndvi_end_scaled +
  fs_end_scaled +
  # Random effects
  (1|step_id_) + # Muff "Poisson Trick"
  (0 + sl_ + log_sl_ + cos_ta_ | id)+ # Individual variation in movement behavior
  (0 + fs_end_scaled|id), # Individual variation in preference for feeding sites
  family = poisson(), data = hunting_season)

end <- Sys.time()
time_elapsed <- end - start
print(time_elapsed)

# Save the model
save(m_hunt,file = "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/models/m_hunt.RData")
end <- Sys.time()
time_elapsed <- end - start
print(time_elapsed)

# Model summary
summary(m_hunt)

# Summer Season Model -----------------------------------------------------

start <- Sys.time()

m_summer <- glmmTMB(case_ ~  
                    # Movement Parameters
                    sl_ + log_sl_ + cos_ta_ +
                    # Effects of ToD on Movement
                    #tod_start_:(sl_ + log_sl_ + cos_ta_)+
                    #Effects of slope on movement and habitat selection
                    #slope_start_scaled:(sl_ + log_sl_ + cos_ta_)+
                    slope_end_scaled +
                    # Effects of anthropogenic disturbance on  habitat selection
                    roads_end_scaled +
                    hs_end_scaled +
                    # Effects of resources on habitat selection
                    ndvi_end_scaled +
                    fs_end_scaled +
                    # Random effects
                    (1|step_id_) + # Muff "Poisson Trick"
                    (0 + sl_ + log_sl_ + cos_ta_ | id)+ # Individual variation in movement behavior
                  (0 + fs_end_scaled|id), # Individual variation in preference for feeding sites
                  family = poisson(), data = summer_season)

end <- Sys.time()
time_elapsed <- end - start
print(time_elapsed)

# Notice that m_summer gives a Model convergence warning. This is one of the issues with fitting the iSSA
# using glmmTMB that we will have to look into.

# Save the model
save(m_summer,file = "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/models/m_summer.RData")
end <- Sys.time()
time_elapsed <- end - start
print(time_elapsed)

# Model summary
summary(m_summer)


