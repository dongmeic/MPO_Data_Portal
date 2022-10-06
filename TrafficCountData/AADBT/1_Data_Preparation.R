# This script was created to prepare data for AADBT estimation
# By Dongmei Chen (dchen@lcog.org)
# On September 29th, 2022

library(rjson)
library(rnoaa)
library(lubridate)
library(stringr)
library(geosphere)
library(dplyr)

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

# distance
distsq <- function(lon1, lon2, lat1, lat2){
  #(lon1-lon2)^2+(lat1-lat2)^2
  (distm(c(lon1, lat1), c(lon2, lat2), fun = distVincentyEllipsoid))^2
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

aggdata <- aggregate(x=list(DailyCounts = data$Hourly_Count), 
                     by=list(Date = data$Date, 
                             Location = data$Location), 
                     FUN=sum, na.rm=TRUE)

datedata <- unique(data[,c("Date", "Month", "MonthDesc", "Season", "Weekday", 
                           "IsHoliday", "UoInSession", "IsSpecialEvent")])
aggdata <- merge(aggdata, datedata, by="Date")

locvars <- c('CountType', 'Direction', 'FacilityType', 'RoadWidth', 'City', 
             'Location', 'Latitude', 'Longitude', 'Site_Name', 
             'DoubleCountLocation', 'IsOneway', 'OnewayDirection', 
             'IsSidewalk', 'Location_Description')
locdata <- read.csv(paste0(locpath, 'CountLocationInformation.csv'))
aggdata <- merge(aggdata, locdata[,locvars], by = 'Location')
write.csv(aggdata, paste0(outpath, "Daily_Bike_Counts.csv"), row.names = FALSE)

site_coords <- locdata[,c("Longitude", "Latitude")]
site_coords$Location <- locdata$Location
site_coords$City <- locdata$City
site_coords$id <- 1:nrow(site_coords)

noaa_data <- data.frame()
loc_data <- data.frame()

locations <- unique(aggdata$Location)
# need to manually fix error - Error: Bad Gateway (HTTP 502)
loc <- "RosaParksPathSouthQ"
locations <- locations[which(locations==loc):length(locations)]
for(location in locations){
  ptm <- proc.time()
  locdata <- meteo_nearby_stations(site_coords[site_coords$Location == location,], 
                                lat_colname = "Latitude",
                                lon_colname = "Longitude", 
                                station_data = ghcnd_stations(),
                                var = "all", 
                                year_min = 2012, 
                                year_max = 2021, 
                                radius = NULL,  
                                limit = 10)
  
  names(locdata) <- "data"
  locdata <- locdata$data
  locdata$location <- location
  loc_data <- rbind(loc_data, locdata)
  
  locdate <- aggdata[aggdata$Location == location, c("Location", "Date")]
  ObsDates <- locdate$Date
  dates <- sort(as.Date(ObsDates, "%Y-%m-%d"))
  Start_Date <- dates[1]
  End_Date <- dates[length(dates)]
  years <- unique(year(dates))
  n <- length(years)

  print(paste("Check climate data for", location, "from", Start_Date, 
              "to", End_Date, paste0("(", n, " years)")))

  for(year in years){
    if(year == years[1]){
      StartDate <- paste0(year, "-",str_pad(month(Start_Date), 2, pad="0"),"-01")
      EndDate <- paste0(year, "-12-31")
    }else if(year == years[length(years)]){
      StartDate <- paste0(year, "-01-01")
      EndDate <- paste0(year, "-",str_pad(month(End_Date), 2, pad="0"),"-31")
    }else{
      StartDate <- paste0(year, "-01-01")
      EndDate <- paste0(year, "-12-31")
    }
    
    for(dt in c("PRCP","TMAX","SNOW")){
      station_ids <- paste0('GHCND:', locdata$id)y
      # in case missing data
      station_ids <- c(station_ids, "GHCND:USW00024221")
      for(station_id in station_ids){
        clim <- ncdc(datasetid = 'GHCND', 
                     datatypeid = dt,
                     stationid = station_id, 
                     startdate = StartDate, 
                     enddate = EndDate,
                     add_units = T)$data
        clim$location <- location
        test <- rbind(test, clim)
        #noaa_data <- rbind(noaa_data,clim) # the loop is too long to run
        print(paste(dt, station_id, "from", StartDate, "to", EndDate, "for", location))
      }
    }
  }
  print(paste("Got climate data for", location))
  print(proc.time() - ptm)
}

# remove the duplicated due to the 502 Bad Gateway Error
noaa_data <- unique(noaa_data)
loc_data <- unique(loc_data)
write.csv(loc_data, paste0(outpath, "noaa_stations.csv"), row.names = FALSE)
write.csv(noaa_data, paste0(outpath, "noaa_data.csv"), row.names = FALSE)

noaa_data$date <- unlist(lapply(noaa_data$date, function(x) strsplit(x, split = "T")[[1]][1]))
noaa_data$station <- unlist(lapply(noaa_data$station, function(x) strsplit(x, split = ":")[[1]][2]))

names(loc_data)[1] <- "station"

for(location in locations){
  dates <- as.character(sort(as.Date(aggdata[aggdata$Location == location, 'Date'], "%Y-%m-%d")))
  for(date in dates){
    for(dtype in c("PRCP","TMAX","SNOW")){
      clim <- noaa_data[noaa_data$location == location & noaa_data$date == date & noaa_data$datatype == dtype,]
      if(dim(clim)[1] > 1){
        locdt <- loc_data[loc_data$location == location & loc_data$station %in% clim$station,]
        if(dim(locdt)[1] == 1){
          # choose the data from the close station
          aggdata[aggdata$Location == location & aggdata$Date == date, dtype] <- clim[clim$station == locdt$station,]$value
        }else{
          
        }
          
      }else if(dim(clim)[1] == 1){
        # when there is only one value
        aggdata[aggdata$Location == location & aggdata$Date == date, dtype] <- clim$value
      }else{
        # look for data from other stations
      }
    }
      
      
  }
}

