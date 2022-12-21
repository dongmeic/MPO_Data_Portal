
library(readxl)
library(dplyr)
library(sf)

source('T:/DCProjects/GitHub/MPO_Data_Portal/PopulationData/Census_TitleVI_functions.r')

yr_ranges <- c("20092013", "20102014", "20112015", 
               "20122016", "20132017", "20142018", 
               "20152019", "20162020", "20172021")
yearlist <- 2013:2021
yrs = 13:21


df <- get_MPOavg_data(yr=13, year=2013)

