# This script was created to prepare data for AADBT estimation
# By Dongmei Chen (dchen@lcog.org)
# On September 29th, 2022

library(rjson)
library(rnoaa)
library(lubridate)

# functions
# weight by distance
idw <- function(lon, lat, lonv, latv, varv){
  n <- length(lonv)
  distv <- vector()
  nvarv <- vector()
  for(i in 1:n){
    distv[i] <- distsq(lon, lonv[i], lat, latv[i])
    nvarv[i] <- 1/distv[i] * varv[i]
  }
  return(sum(nvarv)/sumidw(distv))
}

# summary for weights
sumidw <- function(distv){
  sum(sapply(distv, function(x) 1/x))
}


options(warn = -1)
setwd("T:/DCProjects/Modeling/AADBT/reading/Test/Data")

keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
options(noaakey = rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$noaa$token)
inpath <- 'T:/Data/COUNTS/Nonmotorized Counts/Summary Tables/Bicycle/'
outpath <- 'T:/DCProjects/Modeling/AADBT/input/'
locpath <- 'T:/Data/COUNTS/Nonmotorized Counts/Supporting Data/Supporting Bicycle Data/'

rawdata <- read.csv(paste0(inpath, 'Bicycle_HourlyForTableau.csv'))
rawdata$Season <- ifelse(rawdata$MonthDesc == "September", "Fall", rawdata$Season)

year <- 2021
data <- rawdata[rawdata$Year <= year & 
                  rawdata$Direction == "Total" & 
                  rawdata$ObsHours == 24,]
#data$Date <- as.Date(data$Date, "%Y-%m-%d")

aggdata <- aggregate(x=list(DailyCounts = data$Hourly_Count), 
                     by=list(Date = data$Date, 
                             Location = data$Location), 
                     FUN=sum, na.rm=TRUE)

no_days <- aggregate(x=list(ObsDays = data$Date), 
                     by=list(Location = data$Location), 
                     FUN=function(x) length(unique(x)))

datedata <- unique(data[,c("Date", "Month", "MonthDesc", "Season", "Weekday", 
                           "IsHoliday", "UoInSession", "IsSpecialEvent")])
aggdata <- merge(aggdata, datedata, by="Date")

locvars <- c('CountType', 'Direction', 'FacilityType', 'RoadWidth', 'City', 
             'Location', 'Latitude', 'Longitude', 'Site_Name', 
             'DoubleCountLocation', 'IsOneway', 'OnewayDirection', 
             'IsSidewalk', 'Location_Description')
locdata <- read.csv(paste0(locpath, 'CountLocationInformation.csv'))
aggdata <- merge(aggdata, locdata[,locvars], by = 'Location')
write.csv(aggdata, paste0(outpath, "/Daily_Bike_Counts.csv"), row.names = FALSE)

site_coords <- locdata[,c("Longitude", "Latitude")]
site_coords$Location <- locdata$Location
site_coords$City <- locdata$City
site_coords$id <- 1:nrow(site_coords)

noaa_data <- data.frame()
locations <- unique(aggdata$Location)
locclim <- data.frame()
for(location in locations){
  locdata <- meteo_nearby_stations(site_coords[site_coords$Location == location,], 
                                lat_colname = "Latitude",
                                lon_colname = "Longitude", 
                                station_data = ghcnd_stations(),
                                var = "all", 
                                year_min = 2012, 
                                year_max = 2021, 
                                radius = 5)
  
  names(locdata) <- "data"
  locdata <- locdata$data
  locdata$location <- location
  
  locdate <- aggdata[aggdata$Location == location, c("Location", "Date")]
  ObsDates <- locdate$Date
  for(ObsDate in ObsDates){
    print(paste("Check climate data for", location, "on", ObsDate))
    for(dt in c("PRCP","TMAX","SNOW")){
      station_ids <- paste0('GHCND:', locdata$id)
      station_ids <- c(station_ids, "GHCND:USW00024221")
      for(station_id in station_ids){
        clim <- ncdc(datasetid = 'GHCND', 
                     datatypeid = dt,
                     stationid = station_id, 
                     startdate = ObsDate, 
                     enddate = ObsDate,
                     add_units = T)$data
        if(dim(clim)[1] == 1){
          locdate[locdate$Location == location & locdate$Date == ObsDate, dt] <- clim$value
          clim$location <- location
          noaa_data <- rbind(noaa_data, clim)
          print(paste(location, ObsDate, dt, station_id))
          break
        }else{
          print(paste("Didn't find", dt, "data in", station_id, "on", ObsDate))
        }
      }
    }
  }
  locclim <- rbind(locclim, locdate)
  print(paste(location, "is completed!"))
}




