# This script was created by Dongmei Chen (dchen@lcog.org) 
# to calculate data for the TitleVI dashboard 
# (https://thempo.org/958/Socio-Economic-Data) 
# on May 5th, 2020

# load libraries
library(readxl)
library(dplyr)
library(rjson)
library(tidycensus)
library(sf)

source('T:/DCProjects/GitHub/MPO_Data_Portal/PopulationData/Census_TitleVI_functions.r')

############################## Download data ##############################

# update year information here
year <- 2021

unzip_data(year=year)

# In 2020, move the 1-year table B18101 from the 5-year folder to 
# the 1-year folder, since only 1Y data available

# # alternatively, use API to access Census.Gov
# keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
# census_api_key(rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$acs$key, 
#                install = TRUE, overwrite=TRUE)

# titlevi <- read.csv("T:/Tableau/tableauTitleVI/Datasources/MPO_summary.csv")
# vars <- c("BlkGrp10", "PopNI5Disa", "PopEld", "HHPoor",  
#           "Pop5yrLEP", "PopMinor", "PopWFUnEmp", "HH0car")
# data <- titlevi[, vars]
# 
# write.csv(data, 
#           paste0("T:/Tableau/tableauTitleVI/Datasources/map_data.csv"), 
#           row.names = F)

############################## Read data ##############################
# get data for change over time
# factor
outdata <- get_MPOavg_data(year = year)

############################## Update change over time ##############################
# output should look like this, use data from ACS2013-2017
# change <- read_excel(paste0(outpath, "/TitleVIchangeovertime.xlsx"))
# # change2017 <- subset(change, Year==2017)
# # change2017
# change <- rbind(change, outdata)
# write.csv(change, paste0(outpath, "/TitleVIchangeovertime.csv"), row.names = FALSE)

change <- read.csv(paste0(outpath, "/TitleVIchangeovertime.csv"), 
                   stringsAsFactors = FALSE)

# # if you run into errors after the table update for the most recent year
# change <- subset(change, Year < year)

if(max(change$Year) == (year - 1)){
  change <- rbind(change, outdata)
  write.csv(change, paste0(outpath, "/TitleVIchangeovertime.csv"), row.names = FALSE)
  cat("Added the new data!")
}else if(max(change$Year) == year){
  cat("You are good to go!")
}else{
  cat("Have you updated the data last year?")
}

############################## Read block group shapefile ##############################

bgdata <- get_TitleVI_data()

bgdata <- adjust_TitleVI_data()[[1]]

# Update these numbers on the dashboard
mpoavg <- adjust_TitleVI_data()[[2]]
mpoavg[1:4]
# 2017-2021
# PctElderly   PctDisab    PctPoor   PctMinor 
# 0.1685620  0.1683580  0.1669944  0.2159047 
# mpoavg
# PctElderly   PctDisab    PctPoor   PctMinor   PctUnEmp     PctLEP  PctHH0car  PctRentHH 
# 0.16856201 0.16835799 0.16699439 0.21590469 0.07127118 0.02702321 0.08916891 0.47276171 

mpotot <- c(sum(bgdata$PopEld), 
            sum(bgdata$PopNI5Disa),
            sum(bgdata$HHPoor),
            sum(bgdata$PopMinor),
            sum(bgdata$PopWrkF16*bgdata$PctUnEmp),
            sum(bgdata$Pop5yrLEP),
            sum(bgdata$HH0car),
            sum(bgdata$RenterHHs))
names(mpotot) <- c("PopEld", "PopDisa", "HHPoor", "PopMinor", "PopUnEmp", 
                   "PopLEP", "HH0car", "RenterHHs")

# mpotot
# PopEld    PopDisa    HHPoor    PopMinor  PopUnEmp    PopLEP    HH0car   RenterHHs 
# 45403.870 43200.473  18651.340 58156.098 10202.056   6934.604  9959.135 52802.011 

############################## Get shapefile data ##############################

bg.shp <- adjust_TitleVI_data()[[3]]


# ############################## Others #################################
# # further notes for mapping: determine the classification of the percentage of 
# # concerns based on the quantile of population
# outpath <- "T:/Tableau/tableauTitleVI/Datasources"
# 
# bgdata <- read.csv(paste0(outpath, "/MPO_summary.csv"),  stringsAsFactors = FALSE)
# tot.vars <- c("TotalPOP", "PopWrkF16", "PopGE5", "HH", "PopNInst5", "TotalPOP", "HH")
# pop.vars <- c("PopMinor", "PopWFUnEmp", "Pop5yrLEP", "HH0car", "PopNI5Disa", "PopEld", "HHPoor")
# pct.vars <- c("PctMinor", "PctUnEmp", "PctLEP", "PctHH0car", "PctDisab", "PctElderly", "PctPoor")
# 
# # test some functions
# # library(Hmisc)
# # cuts <- split(bgdata[,pct.vars[5]], cut2(bgdata[,pop.vars[5]], g=6))
# # library(gtools)
# # levels(quantcut(bgdata[,pop.vars[5]], 6))
# # range(bgdata[bgdata[,pop.vars[5]]>=0.326 & bgdata[,pop.vars[5]]<= 97.9,
# #        pct.vars[5]])
# 
# notes <- c("1st", "2nd", "3rd", "4th", "5th", "6th")
# 
# MapDir <- "T:/MPO/Title VI & EJ/2023_TitleVI_update/Maps"
# sink(paste0(MapDir, "/symbology_manual_cuts.txt"))
# for(var in pct.vars){
#   tot.var <- tot.vars[which(pct.vars==var)]
#   df <- bgdata[,c(tot.var, var)]
#   df <- df[order(df[,var]),]
#   df$cumsum <-  cumsum(df[, tot.var])
#   avg <- sum(df[, tot.var])/6
#   cuts <- avg * c(1:6)
#   v <- vector()
#   for(cut in cuts){
#     df$diff <- df$cumsum - cut
#     cat(paste0('The ', notes[which(cuts==cut)], ' cut for ', var, ' is ', 
#                df[abs(df$diff) == min(abs(df$diff)),var], '\n'))
#     if(which(cuts==cut)==1){
#       pop <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
#       cat(paste0('The total population for this cut is ', pop,'\n'))
#       last.cum <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
#       v <- c(v, pop)
#     }else{
#       pop <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))] - last.cum
#       cat(paste0('The total population for this cut is ', pop,'\n'))
#       last.cum <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
#       v <- c(v, pop)
#     }
#   }
#   cat(paste("The average population size is", mean(v), "\n"))
#   cat("\n")
# }
# sink()