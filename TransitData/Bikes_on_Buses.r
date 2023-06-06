# This script was created by Dongmei Chen (dchen@lcog.org) to reorganize and calculate data
#  for the bikes on buses dashboard 
# (https://www.lcog.org/906/Bikes-on-Buses) on May 18th, 2020

library(rgdal)
library(readxl)
library(dplyr)
library(tools)
library(lubridate)

source("C:/Users/clid1852/.0GitHub/MPO_Data_Portal/TransitData/Bikes_on_Buses_Functions.r")

############################# 2023 ##################################
year <- 2023
inpath <- paste0("T:/Data/LTD Data/MonthlyBoardings/", year, " Ridership")
ndata <- get_bikecounts_yr(year=year, myrs=c("October 2022"), MY="April 2023")

############################# 2022 ##################################
year <- 2022
inpath <- paste0("T:/Data/LTD Data/MonthlyBoardings/", year, " Ridership")

outfolder <- "T:/Tableau/tableauBikesOnBuses/Datasources"
data <- read.csv(paste0(outfolder, "/DataCopy/AllBikeCounts.csv"))
ndata <- get_bikecounts_yr(year=2022, myrs=c("April 2020", "October 2022"))
# run the update

############################# 2021 ##################################
inpath <- "T:/Data/LTD Data/BikeOnBuses/Monthly"
data <- read.csv(paste0(outfolder, "/DataCopy/AllBikeCounts.csv"))
#excel_sheets(paste0(inpath,"/LTD Bike Count_2021.xlsx"))
ndata <- get_bikecounts_yr(2021)
data <- rbind(data, ndata)
# make sure data is copied
write.csv(data, paste0(outfolder, "/AllBikeCounts.csv"), row.names = FALSE)

############################# Before 2021 ###########################
# reorganize historic data since 2011
bodarding.path <- "T:/Data/LTD Data/BoardingSince2011/"
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