# This script was created by Dongmei Chen (dchen@lcog.org) 
# to calculate TitleVI data for Lane
# on May 30th, 2023

# load libraries
library(readxl)
library(dplyr)
library(rjson)
library(tidycensus)
library(sf)

source('C:/Users/clid1852/.0GitHub/MPO_Data_Portal/PopulationData/Census_TitleVI_functions.r')
year <- 2021

#the one-year data is for the average calculation
#unzip_data(subfolder='Lane', year=year, mode='1yr')
geo="Lane"
bgdata <- adjust_TitleVI_data(geo=geo)[[1]]
outpath <- "T:/Data/TitleVI"
st_write(bgdata, dsn = outpath, layer = paste0(geo, "_BG_TitleVI"), driver = "ESRI Shapefile", delete_layer=TRUE)
