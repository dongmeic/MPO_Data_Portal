# This script was created to collect NOAA data for AADBT estimation
# Based on https://github.com/dongmeic/MPO_Data_Portal/blob/master/TrafficCountData/AADBT/Get_NOAA_Data.r
# By Dongmei Chen (dchen@lcog.org)
# On September 29th, 2022

library(lubridate)
library(rgdal)
library(classInt)
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
library(gridExtra)
library(grid)
library(StreamMetabolism)
library(reshape2)
library(dplyr)
library(timeDate)
library(Lahman)
library(rnoaa)
library(readxl)	
library(Metrics)
library(geosphere)
library(rjson)

options(warn = -1)
setwd("T:/DCProjects/Modeling/AADBT/reading/Test/Data")

#Set NOAA API Key 
######################
keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
options(noaakey = rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$noaa$token)

locdata <- read.csv("T:/Data/COUNTS/Nonmotorized Counts/Supporting Data/Supporting Bicycle Data/CountLocationInformation.csv")

#Create a city coordinate data frame
site_coords <- locdata[,c("Longitude", "Latitude")]
site_coords$Location <- locdata$Location
site_coords$City <- locdata$City
city_coords <- site_coords %>% group_by(City) %>% summarise(Longitude = mean(Longitude),Latitude = mean(Latitude))
city_coords$id <- 1:nrow(city_coords)

#Collect NOAA station info
noaa_data <- data.frame()
for(i in 1:3){
  noaa_stations <- meteo_nearby_stations(city_coords[i,], lat_colname = "Latitude",
                                         lon_colname = "Longitude", station_data = ghcnd_stations(),
                                         var = "all", year_min = 2012, year_max = 2021, radius = NULL,  limit = 20)	
  temp_stations_info <- do.call("rbind",noaa_stations)
  temp_stations_info$City <- city_coords[i,]$City
  noaa_data <- rbind(noaa_data,temp_stations_info)
}

#Create a data frame of station information
stations_info <- noaa_data
stations_info <- stations_info[!(duplicated(stations_info$id)),]

calendar <- data.frame(Date = seq(as.Date("2012-01-01"),as.Date("2021-12-31"),1))
calendar$Year <- year(calendar$Date)
calendar_summary <- calendar %>%group_by(Year) %>%summarize(Days_in_Year = length(Date))

#Download NOAA data
retrieve_climate_data <- function(city="Eugene", 
                                  years=as.character(2012:2021), 
                                  dtypes=c("PRCP","TMAX","SNOW")){
  
  station_ids <- paste("GHCND:",noaa_data$id[noaa_data$City%in%city],sep="")
  #Add stations since the assigned stations for these cities are still missing data types
  station_ids <- c(station_ids, "GHCND:USW00024221")
  
  load_climate_data <- data.frame()
  
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
        print(paste(city, station_id, yr, dt))
      }
    }
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

load_climate_data_eug <- retrieve_climate_data()
load_climate_data_spr <- retrieve_climate_data(city="Springfield")

#Clean climate data based on completeness of records and nearness to bike counting sites 
summarize_climate_data <- function(climate_data = load_climate_data_eug){
  
  #Summarize counts and determine which stations to use based on completeness and nearness to site
  ################################################
  #Summarize climate data and determine number of records including those that are non-NA
  climate_data_summary <- as.data.frame(climate_data %>% 
                                          group_by(id, datatype, Year) %>% 
                                          summarise(Count = length(value), 
                                                    Non_NA =  sum(!is.na(value))))
  #Add number of days in year
  climate_data_summary <- left_join(climate_data_summary, calendar_summary, by = "Year")
  #Add station names
  climate_data_summary <- left_join(climate_data_summary, stations_info, by = "id")
  #Determine which stations have complete data (temperature and precipitation)
  select_climate_summary <- filter(climate_data_summary[climate_data_summary$Count >= 300,], 
                                   datatype !="SNOW")
  
  #Do snow separately since the data is spottier
  temp <- filter(climate_data_summary, datatype =="SNOW")
  #Determine maximum number of snow days by year to determine which station to select
  max_snow_days <- temp %>% group_by(Year) %>% summarize(MaxSnowDays = max(Count))
  temp <-left_join(temp, max_snow_days, by = "Year")
  SelectSnowClimateSummary <- temp[temp$Count == temp$MaxSnowDays,]
  #$Append to other climate data
  select_climate_summary  <- rbind(select_climate_summary, SelectSnowClimateSummary[,colnames(select_climate_summary)] )
  
  return(select_climate_summary)
}

select_climate_summary_eug <- summarize_climate_data()
select_climate_summary_spr <- summarize_climate_data(climate_data = load_climate_data_spr)

climate_data_types <- c("TMAX","PRCP","SNOW")

#
format_climate_data <- function(city="Eugene",
                                climate_data=load_climate_data_eug,
                                select_climate_summary=select_climate_summary_eug){
  Df_Count <- 0
  #Select different stations for different climate elements based on available data
  for(datatype in climate_data_types){
    #Select data type
    select_climate_data <- climate_data[climate_data$datatype%in%datatype,]
    #Check to see if data type exists before proceeding
    if(nrow(select_climate_data) > 0){
      #Add to counter
      Df_Count <- Df_Count + 1
      #Select stations
      station_selected <- select_climate_summary[select_climate_summary$datatype == datatype,]
      #Determine nearest station
      MinStationDistance <- station_selected %>% group_by(Year) %>% summarise(distance = min(distance))
      #Add a flag declaring if the data should be selected base don distance
      MinStationDistance$Is_Nearest <- TRUE
      station_selected <- left_join(station_selected, MinStationDistance, by = c("Year","distance"))
      station_selected <-  station_selected[ station_selected$Is_Nearest%in%TRUE,]
      select_climate_data  <- left_join(select_climate_data, station_selected[,c("id","Year","Is_Nearest")], 
                                        by = c("id","Year"))
      #Select only climate data for select data type that is nearest
      near_climate_data <- select_climate_data[  select_climate_data$Is_Nearest%in%TRUE,]
      #Add city
      near_climate_data$City <- city
      #Create new column name
      near_climate_data[,datatype] <- near_climate_data$value
      near_climate_data <- near_climate_data[,c("Date","City", datatype)]
      #Store
      if(Df_Count== 1){
        format_climate_data <- near_climate_data} else {
          format_climate_data <- left_join(format_climate_data, near_climate_data, by = c("Date","City"))
        }
      
    }
  }
  return(format_climate_data)
}

format_climate_data_eug <- format_climate_data()
format_climate_data_spr <- format_climate_data(city="Springfield",
                                               climate_data=load_climate_data_spr,
                                               select_climate_summary=select_climate_summary_spr)

add_sunlight_data <- function(city="Eugene",
                              format_climate_data=format_climate_data_eug){
  stored_climate_data <- data.frame()
  Long <- city_coords$Longitude[ city_coords$City%in%city]
  Lat <- city_coords$Latitude[ city_coords$City%in%city]
  #Get amount of sunlight sunrise.set function() uses NOAA as reference so better than suncalc that has reported inaccuracies
  sunlight_data <- sunrise.set(lat = Lat, lon = Long, as.Date(min(format_climate_data$Date)), timezone = "UTC-8", nrow(format_climate_data))
  #Calculate sun time (the sunrise and sunset times seem wrong but the total daylight is correct when checked against https://www.timeanddate.com/sun/usa/bend?month=1&year=2017
  sunlight_data$Daylight_Mins <- as.numeric(sunlight_data$sunset - sunlight_data$sunrise) * 60
  sunlight_data$Date <- as.Date(sunlight_data$sunrise)
  #Select final columns for joining
  sunlight_data <- sunlight_data[,c("Date","Daylight_Mins")]
  #Store
  format_climate_data <- left_join(format_climate_data, sunlight_data, by = c("Date"))
  
  #Store
  stored_climate_data <- rbind(stored_climate_data, format_climate_data)
  
  return(stored_climate_data)
}


stored_climate_data_eug <- add_sunlight_data()
stored_climate_data_spr <- add_sunlight_data(city="Springfield",
                                             format_climate_data=format_climate_data_spr)

load_store_climate_data <- rbind(stored_climate_data_eug, stored_climate_data_spr)
save(load_store_climate_data, file = "noaa_data_by_city.RData")

#Graph the weather data
##############################
pdf("Reports/SARM Analysis/climate_data_review.pdf", height = 11, width = 11)

for(city in unique(load_store_climate_data$City)){
  #Select data
  select_climate_data <- load_store_climate_data[load_store_climate_data$City%in%city,]
  #Reformat
  select_climate_data <- melt(select_climate_data, id.vars = c("City","Date"), variable.name = "Data_Type",value.name = "Value")
  #plot
  Plot <- 
    ggplot(select_climate_data, aes(x = Date, y = Value)) +
    geom_line(aes(x = Date, y = Value, color = Data_Type)) +
    facet_wrap(~Data_Type, scales = "free") +
    ggtitle(paste("Climate Data for: ", city, sep=""))
  
  print(Plot)
}
dev.off()	

