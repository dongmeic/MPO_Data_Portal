# This script was created by Dongmei Chen (dchen@lcog.org) to reorganize and calculate data
#  for the bikes on buses dashboard 
# (https://www.lcog.org/906/Bikes-on-Buses) on May 18th, 2020

library(rgdal)
library(readxl)
library(dplyr)
library(tools)
library(lubridate)

source("T:/GitHub/MPO_Data_Portal/TransitData/Bikes_on_Buses_Functions.r")

# reorganize historic data since 2011
bodarding.path <- "T:/Data/LTD Data/BoardingSince2011/"
stop.path <- "T:/Data/LTD Data/StopsSince2011"
outfolder <- "T:/Tableau/tableauBikesOnBuses/Datasources"

# get all historical data
months <- c("April", "October")
years <- 2011:2020
MonthYear <- unique(file_path_sans_ext(list.files(bodarding.path)))

ptm <- proc.time()
for(yr in years){
  if(yr %in% c(2017, 2019, 2020)){
    BikeCounts <- get.bikecounts(yr=yr)
    BikeCounts.all <- rbind(BikeCounts.all, BikeCounts)
    print(paste("Got bike counts from", yr))
  }else{
    for(m in months){
      myr <- paste(m, yr)
      if(myr %in% MonthYear){
        if(myr == "October 2011"){
          BikeCounts.all <- get.bikecounts(m, yr)
        }else{
          BikeCounts <- get.bikecounts(m, yr)
          BikeCounts.all <- rbind(BikeCounts.all, BikeCounts)
        }
        print(paste("Got bike counts from", yr, m))
      }
    }
  }
}
proc.time() - ptm

# correct seasons due to extra data in some seasons
BikeCounts.all$Season <- sapply(BikeCounts.all$MonthYear, function(x) correct.season(x))

# remove duplicate data
df = distinct(BikeCounts.all)

ptm <- proc.time()
write.csv(df, paste0(outfolder, "/AllBikeCounts.csv"), row.names = FALSE)
proc.time() - ptm