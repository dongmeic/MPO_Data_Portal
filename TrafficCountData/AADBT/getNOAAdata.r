# This script was created to collect and explore NOAA data for AADBT estimation
# Based on 
# By Dongmei Chen (dchen@lcog.org)
# On September 19th, 2022

inpath <- "T:/DCProjects/Modeling/AADBT/input"
noaa <- read.csv(paste0(inpath, "/3084343.csv"))

library(rgdal)
library(rgeos)
library(MASS)
library(AER)
library(scales)
library(htmltools)
library(htmlwidgets)
library(maptools)
library(ggplot2)
library(tigris)
library(RColorBrewer)
library(dplyr)
library(gridExtra)
library(grid)
library(StreamMetabolism)
library(reshape2)
library(dplyr)
library(timeDate)
library(lubridate)
library(Lahman)
library(rnoaa)
library(readxl)	
library(Metrics)
library(geosphere)
library(rjson)