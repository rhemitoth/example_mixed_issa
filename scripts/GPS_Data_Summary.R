## ---------------------------
##
## Script name: GPS Data Summary PRE WOLF
##
## Author: Rhemi Toth
##
## Date Created: 2025-04-09
##
## Email: rhemitoth@g.harvard.edu
##
## ---------------------------
##
## Notes: This script summarized the GPS data from the Eurodeer Database
##   
##
## ---------------------------


# Load Packages -----------------------------------------------------------

library(tidyverse)


# Load the GPS data -------------------------------------------------------

gps_pre_wolf <- read_csv("/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/GPS/gps_pre_wolf.csv")
gps_post_wolf <- read_csv("/Users/rhemitoth/Library/CloudStorage/GoogleDrive-rhemitoth@g.harvard.edu/My Drive/Cembra/Data/Movement_Data/GPS/gps_post_wolf.csv") %>%
  mutate(acquisition_time = mdy_hm(acquisition_time))

# Summarize the Data ------------------------------------------------------

gps_sum_pre_wolf <- gps_pre_wolf %>%
  group_by(animals_id) %>%
  summarize(min_date = min(acquisition_time), 
            max_date = max(acquisition_time),
            num_relocations = n())%>%
  mutate(total_time = max_date - min_date)


gps_sum_post_wolf <- gps_post_wolf %>%
  group_by(animals_id) %>%
  summarize(min_date = min(acquisition_time), 
            max_date = max(acquisition_time),
            num_relocations = n())%>%
  mutate(total_time = max_date - min_date)

# Pre-wolf individuals ----------------------------------------------------

# filter the summarized dataset to get indivudals for the pre-wolf analysis

pre_wolf_animals <- gps_pre_wolf %>%
  filter(date(acquisition_time) > "2017-03-28")%>%
  filter(date(acquisition_time) < "2020-03-01") %>%
  group_by(animals_id) %>%
  summarize(min_date = min(acquisition_time), 
            max_date = max(acquisition_time),
            num_relocations = n())%>%
  mutate(total_time = max_date - min_date)

# Post-wolf individuals ---------------------------------------------------

post_wolf_animals <- gps_post_wolf %>%
  filter(date(acquisition_time) > "2022-04-01")%>%
  group_by(animals_id) %>%
  summarize(min_date = min(acquisition_time), 
            max_date = max(acquisition_time),
            num_relocations = n())%>%
  mutate(total_time = max_date - min_date)


# Roe deer years ----------------------------------------------------------

deer_years_pre <- sum(pre_wolf_animals$total_time) %>% as.numeric()/365.25
num_individuals_pre <- pre_wolf_animals$animals_id %>% unique() %>% length()


deer_years_post <- sum(post_wolf_animals$total_time) %>% as.numeric()/365.25
num_individuals_post <- post_wolf_animals$animals_id %>% unique() %>% length()

total_years <- deer_years_pre + deer_years_post
total_individuals <- num_individuals_pre + num_individuals_post
