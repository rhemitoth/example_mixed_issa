## ---------------------------
##
## Script name: Used and available points from the pre wolf period
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

# Load the GPS dataset and Summary ----------------------------------------

source("/Users/rhemitoth/Documents/PhD/Cembra/observed_movement/scripts/GPS_Data_Summary.R")


# Prep the GPS Data -------------------------------------------------------

animals <- pre_wolf_animals %>%
  select(animals_id) %>%
  unique()

num_animals <- nrow(animals)

gps <- gps_pre_wolf %>%
  # filter for pre-wolf data
  filter(animals_id %in% animals$animals_id) %>%
  filter(date(acquisition_time) < "2020-03-01") %>%
  # fix utm_x and utm_y columns
  filter(utm_x != "NULL") %>%
  mutate(utm_x = as.numeric(utm_x),
         utm_y = as.numeric(utm_y))

# Filter out erroneous fixes

xmin <- 664430
xmax <- 672100
ymin <- 5106080
ymax <- 5114580

gps <- gps %>%
  filter(utm_x >= xmin, utm_x <= xmax, utm_y >= ymin, utm_y <= ymax)


# Generate steps for each animal ------------------------------------------

# Make the tracks
trk <- make_track(gps,utm_x,utm_y,acquisition_time,crs=32632, id = animals_id)

# Group the track by animals_id and nest the track
trk1 <- trk %>% nest(data = -"id")

# Resample the track to one hour and create steps
steps_nested <- trk1 %>% 
  mutate(steps = map(data, function(x) 
    x %>% track_resample(rate = hours(1), tolerance = minutes(5)) %>% steps_by_burst()))


# Un-nest the data and remove zero length steps
steps <- steps_nested |> select(id, steps) |> unnest(cols = steps) %>%
  filter(sl_ > 0)

print("Saving combined dataset . . .")
outfolder <- "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/"
fname <- paste(outfolder,"all_steps.RData",sep = "")
save(steps,file = fname)

# Fit the step length distribution ----------------------------------------

sl_dist <- amt::fit_distr(steps$sl_,"gamma")
ggplot(data = steps,aes(sl_, fill = factor(id))) + geom_density(alpha = 0.4)

# Fit the turning angle distribution --------------------------------------

ta_dist <- amt::fit_distr(steps$ta_,"vonmises")
ggplot(data = steps,aes(ta_, fill = factor(id))) + geom_density(alpha = 0.4)

# Generate random steps ---------------------------------------------------

obs_avail <- amt::random_steps(x = steps,n_control = 5)

# Calculate log_sl and cos_ta ---------------------------------------------

obs_avail <- obs_avail %>% 
  mutate(log_sl_ = log(sl_),
         cos_ta_ = cos(ta_))


# Save the random steps ---------------------------------------------------

outfolder <- "/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/iSSA/pre_wolf/"
fname <- paste(outfolder,"used_avail.RData",sep = "")
save(obs_avail,file = fname)

