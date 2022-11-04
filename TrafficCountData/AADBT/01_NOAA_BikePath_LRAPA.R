# This script was created to prepare data from NOAA, bikeways, and LRAPA for AADBT estimation
# By Dongmei Chen (dchen@lcog.org)
# On September 29th, 2022

library(rjson)
library(rnoaa)
library(lubridate)
library(stringr)
library(geosphere)
library(dplyr)
library(StreamMetabolism)
library(sf)
library(odbc)
library(readxl)
library(sp)
library(mapview)
library(tidyverse)


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
#write.csv(aggdata, paste0(outpath, "Daily_Bike_Counts.csv"), row.names = FALSE)

################################################ GET NOAA DATA ###################################################
site_coords <- locdata[,c("Longitude", "Latitude")]
site_coords$Location <- locdata$Location
site_coords$City <- locdata$City
city_coords <- site_coords %>% group_by(City) %>% summarise(Longitude = mean(Longitude),Latitude = mean(Latitude))
city_coords$id <- 1:nrow(city_coords)

# collect NOAA station info
noaa_station_data <- data.frame()
for(i in 1:3){
  noaa_stations <- meteo_nearby_stations(city_coords[i,], lat_colname = "Latitude",
                                         lon_colname = "Longitude", station_data = ghcnd_stations(),
                                         var = "all", year_min = 2012, year_max = 2021, radius = NULL,  limit = 30)	
  temp_stations_info <- do.call("rbind",noaa_stations)
  temp_stations_info$City <- city_coords[i,]$City
  noaa_station_data <- rbind(noaa_station_data,temp_stations_info)
}

# create a data frame of station information
stations_info <- noaa_station_data
stations_info <- stations_info[!(duplicated(stations_info$id)),]

calendar <- data.frame(Date = seq(as.Date("2012-01-01"),as.Date("2021-12-31"),1))
calendar$Year <- year(calendar$Date)
calendar_summary <- calendar %>% group_by(Year) %>% summarize(Days_in_Year = length(Date))

# download NOAA data
retrieve_climate_data <- function(years=as.character(2012:2021), 
                                  dtypes=c("PRCP","TMAX","SNOW")){
  
  station_ids <- paste("GHCND:", stations_info$id,sep="")
  # in case missing data in all other stations
  station_ids <- c(station_ids, "GHCND:USW00024221")
  
  load_climate_data <- data.frame()
  n <- length(station_ids)
  
  for(station_id in station_ids){
    for(yr in years){
      
      Start_Date <- paste(yr,"-01-01",sep="")
      End_Date <- paste(yr,"-12-31",sep="")
      
      for(dt in dtypes){
        #Store in data frame
        load_climate_data <- rbind(load_climate_data, 
                                   ncdc(datasetid = 'GHCND', 
                                        datatypeid = dt,
                                        stationid = station_id, 
                                        startdate = Start_Date, 
                                        enddate = End_Date,
                                        limit = 1000,
                                        add_units = T)$data)
        print(paste(station_id, yr, dt))
      }
    }
    print(paste(n - which(station_ids == station_id), "more stations to check ..."))
  }
  climate_data <- load_climate_data
  climate_data$id <- gsub("GHCND:","",climate_data$station)
  #Format names and date
  climate_data$Date <- as.Date(climate_data$date, format = "%Y-%m-%d")
  #Add year
  climate_data$Year <- year(climate_data$Date)
  #Add station name
  climate_data <- left_join(climate_data, stations_info, by = "id")
  return(climate_data)
}

load_climate_data <- retrieve_climate_data()
noaa_data <- load_climate_data

# adjust the units to match with latter review
noaa_datas1 <- noaa_data[noaa_data$datatype %in% c("PRCP","TMAX"),]
noaa_datas1$value <- noaa_datas1$value / 10
noaa_datas2 <- noaa_data[noaa_data$datatype == "SNOW",]
noaa_data <- rbind(noaa_datas1, noaa_datas2)

locations <- unique(aggdata$Location)
k <- length(locations)

noaa_data$date <- unlist(lapply(noaa_data$date, function(x) strsplit(x, split = "T")[[1]][1]))
noaa_data$station <- unlist(lapply(noaa_data$station, function(x) strsplit(x, split = ":")[[1]][2]))
noaa_data[noaa_data$station == "USW00024221", "name"] <- "EUGENE MAHLON SWEET FIELD"
noaa_data[noaa_data$station == "USW00024221", "latitude"] <- 44.13311
noaa_data[noaa_data$station == "USW00024221", "longitude"] <- -123.21563

# collect climate data for each bike counting sampling site from NOAA
ptm <- proc.time()
for(location in locations){
  dates <- aggdata[aggdata$Location == location,]$Date
  for(date in dates){
    climdata <- noaa_data[noaa_data$date == date,]
    climdata <- climdata[!(is.na(climdata$longitude) | 
                         is.na(climdata$latitude) |
                         is.na(climdata$value)),]
      
    for(dtype in c("PRCP", "SNOW", "TMAX")){
      climdat <- climdata[climdata$datatype == dtype,]
      
      if(dim(climdat)[1] == 0){
        aggdata[aggdata$Location == location 
                & aggdata$Date == date, dtype] <- NA
      }else if(dtype == "TMAX"){
        aggdata[aggdata$Location == location 
                & aggdata$Date == date, dtype] <- climdat$value
      }else{
        aggdata[aggdata$Location == location 
                & aggdata$Date == date, dtype] <- idw(aggdata[aggdata$Location == location,]$Longitude[1],
                                                      aggdata[aggdata$Location == location,]$Latitude[1],
                                                      climdat$longitude,
                                                      climdat$latitude,
                                                      climdat$value)
      }                      
      
      print(paste(location, date, dtype))
    }
  }
  print(paste("Got climate data for the site", location))
  print(paste(k - which(locations == location), "more locations to check ..."))
}
print(proc.time() - ptm)

# check the NA data in NOAA
# dates with missing climate data
naclimdates <- as.character(sort(as.Date(unique(aggdata$Date[is.na(aggdata$PRCP)]), "%Y-%m-%d")))
aggdata_na <- aggdata[is.na(aggdata$PRCP),]
locations <- unique(aggdata_na$Location)
k <- length(locations)

# check manually downloaded data
datanoaa <- read.csv(paste0(outpath, "3084343.csv"))
data_noaa <- datanoaa[!(is.na(datanoaa$PRCP) | is.na(datanoaa$SNOW) | is.na(datanoaa$TMAX)),]

# check the missing dates to see if they are in the downloaded NOAA data
missingdates <- vector()
checkeddates <- vector()
for(date in naclimdates){
  if(!(date %in% data_noaa$DATE)){
    missingdates <- c(missingdates, date)
  }else{
    checkeddates <- c(checkeddates, date)
  }
}

# fill in data that covers all the three variables
ptm <- proc.time()
for(location in locations){
  dates <- aggdata_na[aggdata_na$Location == location,]$Date
  for(date in dates){
    if(date %in% checkeddates){
      climdata <- data_noaa[data_noaa$DATE == date,]
      for(dtype in c("PRCP", "SNOW", "TMAX")){
        if(dim(climdata)[1] == 1){
          aggdata[aggdata$Location == location 
                  & aggdata$Date == date, dtype] <- climdata[,dtype]
        }else{
          aggdata[aggdata$Location == location 
                  & aggdata$Date == date, dtype] <- idw(aggdata[aggdata$Location == location,]$Longitude[1],
                                                        aggdata[aggdata$Location == location,]$Latitude[1],
                                                        climdata$LONGITUDE,
                                                        climdata$LATITUDE,
                                                        climdata[,dtype])
        }
      }
    }
  }
  print(paste("Got climate data for the site", location))
  print(paste(k - which(locations == location), "more locations to check ..."))
}
print(proc.time() - ptm)

# check again missing data
naclimdates2 <- as.character(sort(as.Date(unique(aggdata$Date[is.na(aggdata$PRCP)]), "%Y-%m-%d")))
aggdata_na2 <- aggdata[is.na(aggdata$PRCP),]
locations2 <- unique(aggdata_na2$Location)
k <- length(locations2)

data_noaa2 <- datanoaa[!(is.na(datanoaa$PRCP) | is.na(datanoaa$SNOW)),]
# check again the missing dates to see if they are in the downloaded NOAA data
missingdates <- vector()
checkeddates <- vector()
for(date in naclimdates2){
  if(!(date %in% data_noaa2$DATE)){
    missingdates <- c(missingdates, date)
  }else{
    checkeddates <- c(checkeddates, date)
  }
}

# fill in data that covers all the two variables
ptm <- proc.time()
for(location in locations2){
  dates <- aggdata_na2[aggdata_na2$Location == location,]$Date
  for(date in dates){
    if(date %in% checkeddates){
      climdata <- data_noaa2[data_noaa2$DATE == date,]
      for(dtype in c("PRCP", "SNOW")){
        if(dim(climdata)[1] == 1){
          aggdata[aggdata$Location == location 
                  & aggdata$Date == date, dtype] <- climdata[,dtype]
        }else{
          aggdata[aggdata$Location == location 
                  & aggdata$Date == date, dtype] <- idw(aggdata[aggdata$Location == location,]$Longitude[1],
                                                        aggdata[aggdata$Location == location,]$Latitude[1],
                                                        climdata$LONGITUDE,
                                                        climdata$LATITUDE,
                                                        climdata[,dtype])
        }
      }
    }
  }
  print(paste("Got climate data for the site", location))
  print(paste(k - which(locations2 == location), "more locations to check ..."))
}
print(proc.time() - ptm)

# last check on the NA climate data
aggdata_na3 <- aggdata[is.na(aggdata$TMAX),]
naclimdates3 <- as.character(sort(as.Date(unique(aggdata$Date[is.na(aggdata$TMAX)]), "%Y-%m-%d")))
locations3 <- unique(aggdata_na3$Location)
k <- length(locations3)


# check_climate_data <- ncdc(datasetid = 'GHCND',
#                            datatypeid = 'TMAX',
#                            stationid = 'GHCND:USW00024221',
#                            startdate = '2013-01-08', 
#                            enddate = '2013-02-27',
#                            limit = 1000,
#                            add_units = T)$data

# collect missed data
for(year in 2013:2017){
  if(year == 2013){
    dtnoaa <- read.csv(paste0(outpath, "missed/", year, ".csv"))
    dtnoaa <- dtnoaa[,c("DATE", "TMAX")]
  }else{
    ndtnoaa <- read.csv(paste0(outpath, "missed/", year, ".csv"))
    ndtnoaa <- ndtnoaa[,c("DATE", "TMAX")]
    dtnoaa <- rbind(dtnoaa, ndtnoaa)
  }
}

# fill in data that covers missing TMAX
ptm <- proc.time()
for(location in locations3){
  dates <- aggdata_na3[aggdata_na3$Location == location,]$Date
  for(date in dates){
    climdata <- dtnoaa[dtnoaa$DATE == date,]
    aggdata[aggdata$Location == location 
            & aggdata$Date == date, 'TMAX'] <- climdata[,'TMAX']
  }
  print(paste("Got climate data for the site", location))
  print(paste(k - which(locations2 == location), "more locations to check ..."))
}
print(proc.time() - ptm)

# add sunlight data
getDaylight <- function(lat, lon, date){
  sunlight_data <- sunrise.set(lat = lat, lon = lon, 
                               as.Date(date), timezone = "UTC-8")
  return(as.numeric(sunlight_data$sunset - sunlight_data$sunrise) * 60)
}

ptm <- proc.time()
aggdata$Daylight_Mins <- mapply(function(x, y, z) getDaylight(x, y, z), aggdata$Latitude, aggdata$Longitude, aggdata$Date)
print(proc.time() - ptm)


################################################ GET BIKEPATH DATA ###################################################

# this variable is the same as FacilityType but with more details
# create a location shapefile
df <- locdata[,c("Location", "Longitude", "Latitude")]
loc_sf <- st_as_sf(df, coords = c("Longitude", "Latitude"))
loc_sf <- st_set_crs(loc_sf, 4269)
st_write(loc_sf, dsn = paste0(outpath, "shp"), 
         layer = "BikeCountsLocations", 
         driver = "ESRI Shapefile",
         delete_layer = TRUE)

con <- dbConnect(odbc(),
                 Driver = "SQL Server",
                 Server = "rliddb.int.lcog.org,5433",
                 Database = "RLIDGeo",
                 Trusted_Connection = "True")
sql = "
SELECT 
OBJECTID AS id,
ftypedes,
Shape.STAsBinary() AS geom
FROM dbo.BikeFacility
WHERE status = 'built';
"
bikeways <- st_read(con, geometry_column = "geom", query = sql) %>% st_set_crs(2914)
points <- st_transform(loc_sf, crs = 2914)
line_idx <- st_nearest_feature(points, bikeways)
points$LineType <- bikeways[line_idx,]$ftypedes

aggdata <- left_join(aggdata, points, by="Location") %>% select(-geometry)

write.csv(aggdata, paste0(outpath, "Daily_Bike_Counts_With_VarData.csv"), row.names = FALSE)

################################################ GET LRAPA DATA ###################################################

setwd("T:/DCProjects/Modeling/AADBT/data/air_quality")
outpath <- 'T:/DCProjects/Modeling/AADBT/input/'
aggdata <- read.csv(paste0(outpath, "Daily_Bike_Counts_With_VarData.csv"))

# organize LRAPA data
files <- list.files()

read_PM25 <- function(file){
  df <- read_excel(file, skip = 2)
  df <- df[-1,]
  head(df)
  site <- str_split(str_split(names(read_excel(file, n_max=1)), pattern=": ")[[1]][2], 
                    pattern = "  ")[[1]][1]
  df$Site <- rep(site, dim(df)[1])
  df <- df %>% select(c("Date", "Neph_PM25", "Site"))
  return(df)
}

combine_PM25 <- function(files){
  for(file in files){
    if(file == files[1]){
      df <- read_PM25(file = file)
    }else{
      ndf <- read_PM25(file = file)
      df <- rbind(df, ndf)
    }
  }
  return(df)
}

df <- combine_PM25(files=files)

# create points for the sampling locations, see https://data.lrapa.org/ for the locations
sitedf <- data.frame(x = c(493288, 488680, 490310, 498577), 
               y = c(4874794, 4879349, 4884738, 4877060),
               Site= c("Amazon Park", "HWY99", "Wilkes Drive", "Springfield City Hall"))
xy <- sitedf[,c(1,2)]
# spdf <- SpatialPointsDataFrame(coords = xy, data = sitedf,
#                                proj4string = CRS("+proj=utm +zone=10 +datum=WGS84"))
sfpoints <- st_as_sf(x = sitedf, 
                     coords = c("x", "y"),
                     crs = "+proj=utm +zone=10 +datum=WGS84")
mapview(sfpoints)
sfpoints <- st_transform(sfpoints, crs = CRS("+init=epsg:4326"))
sdf <- sfpoints
separated_coord <- sdf %>%
  mutate(Long = unlist(map(sdf$geometry,1)),
         Lat = unlist(map(sdf$geometry,2)))
sdf <- separated_coord[,c('Site', 'Long', 'Lat')] %>% st_drop_geometry()

df <- merge(df, sdf, by = 'Site')
head(df)
