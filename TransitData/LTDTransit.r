# This script was created by Dongmei Chen (dchen@lcog.org) to reorganize and calculate data
#  for the LTD transit dashboard 
# (https://www.lcog.org/thempo/page/Transit-Ridership-Data) on May 29th, 2020

library(rgdal)
library(readxl)
library(dplyr)
library(tools)
library(lubridate)

source("T:/GitHub/MPO_Data_Portal/TransitData/LTDTransit_Functions.r")

# reorganize historic data since 2011
bodarding.path <- "T:/Data/LTD Data/BoardingSince2011/"
stop.path <- "T:/Data/LTD Data/StopsSince2011"
outfolder <- "T:/Tableau/tableauTransit/Datasources"

############################## Data update in 2021 ################################
# review data
data <- read.csv(paste0(outfolder, "/AllPassengerCounts.csv"))
# correct seasons due to extra data in some seasons
data$Season <- sapply(data$MonthYear, function(x) correct.season(x))
# remove duplicate data
df = distinct(data)
unique(df$MonthYear)
unique(df$Season)

ptm <- proc.time()
write.csv(df, paste0(outfolder, "/AllPassengerCounts.csv"), row.names = FALSE)
proc.time() - ptm

############################## Data cleaning in 2020 ################################
# get all historical data
months <- c("April", "October")
years <- 2011:2020
MonthYear <- unique(file_path_sans_ext(list.files(bodarding.path)))

ptm <- proc.time()
for(yr in years){
  if(yr %in% c(2017, 2019, 2020)){
    PassengerCounts <- get.PassengerCounts(yr=yr)
    PassengerCounts.all <- rbind(PassengerCounts.all, PassengerCounts)
    print(paste("Got passenger counts from", yr))
  }else{
    for(m in months){
      myr <- paste(m, yr)
      if(myr %in% MonthYear){
        if(myr == "October 2011"){
          PassengerCounts.all <- get.PassengerCounts(m, yr)
        }else{
          PassengerCounts <- get.PassengerCounts(m, yr)
          if(myr == "October 2012"){
            PassengerCounts.all <- rbind(PassengerCounts, PassengerCounts.all)
          }else{
            PassengerCounts.all <- rbind(PassengerCounts.all, PassengerCounts)
          }
        }
        print(paste("Got passenger counts from", yr, m))
      }
    }
  }
}
proc.time() - ptm

ptm <- proc.time()
write.csv(PassengerCounts.all, paste0(outfolder, "/AllPassengerCounts.csv"), row.names = FALSE)
proc.time() - ptm
