# This script was created to collect and explore NOAA data for AADBT estimation
# Based on https://github.com/dongmeic/MPO_Data_Portal/blob/master/TrafficCountData/AADBT/Get_NOAA_Data.r
# By Dongmei Chen (dchen@lcog.org)
# On September 19th, 2022

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

# inpath <- "T:/DCProjects/Modeling/AADBT/input"
# noaa <- read.csv(paste0(inpath, "/3084343.csv"))

#Set up R environment
#------------------
#Set scientific notation
options(scipen = 6)
#Set working directory
setwd("T:/DCProjects/Modeling/AADBT/reading/Test/Data")

#Set NOAA API Key 
######################
keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
options(noaakey = rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$noaa$token)

#Define custom scripts functions
#------------------------------
#Function that simplifies loading .RData objects
assignLoad <- function(filename){
  load(filename)
  get(ls()[ls() != "filename"])
}

Site_Location_Info.. <- assignLoad(file = "Site_Location_Info_116.RData")
Site_Location_Info_Sp <- assignLoad( file = "Site_Location_Info_Sp_116.RData")

#Determine which stations to use for each count location
#--------------------------------------------------------

#Download station data - get 10 nearest stations to count site
##############
#Create a data frame of lat/long to look up NOAA stations
Site_Coordinates..  <- as.data.frame(coordinates(Site_Location_Info_Sp))
#Add city 
Site_Coordinates..$City <- Site_Location_Info_Sp@data$City
#Add device name
Site_Coordinates..$Device_Name <- Site_Location_Info_Sp@data$Name
Site_Coordinates.. <- Site_Coordinates..[Site_Coordinates..$Latitude !=0,]
#FInd the average for each city
City_Coordinates.. <- Site_Coordinates.. %>% group_by(City) %>% summarise(Longitude = round(mean(Longitude),5),Latitude = mean(Latitude))
#Add an id - meteo_nearby_stations() below requires this
City_Coordinates..$id <- 1:nrow(City_Coordinates..)
#Remove records with no city designation
City_Coordinates.. <- City_Coordinates..[!(is.na(City_Coordinates..$City)),]

#Initialize a data frame
Load_Stations_Info.. <- data.frame()
for(i in which(City_Coordinates..$City %in% c("Eugene", "Springfield"))){
  Stations_ <- meteo_nearby_stations(City_Coordinates..[i,], lat_colname = "Latitude",
                                     lon_colname = "Longitude", station_data = ghcnd_stations(),
                                     var = "all", year_min = 2012, year_max = 2021, radius = NULL,  limit = 20)	
  #Transform into data frame
  Temp_Stations_Info.. <- do.call("rbind",Stations_)
  #Append city 
  Temp_Stations_Info..$City <- City_Coordinates..[i,]$City
  #Store
  Load_Stations_Info.. <- rbind(Load_Stations_Info..,Temp_Stations_Info..)
}
	                                           
#Create a data frame of station information
Station_Info.. <- Load_Stations_Info..
Station_Info.. <- Station_Info..[!(duplicated(Station_Info..$id)),]

#Determine days in the year for determining climate data completeness below
Calendar.. <- data.frame(Date = seq(as.Date("2012-01-01"),as.Date(paste( year(Sys.Date()),"-12-31",sep="")),1))
Calendar..$Year <- year(Calendar..$Date)
Calendar_Summary.. <- Calendar.. %>%group_by(Year) %>%summarize(Days_in_Year = length(Date))

Stored_Climate_Data.. <- data.frame()
#initialize counter to track progress below
count = 1

for(city in c("Eugene", "Springfield")){
  #Create vector of station names closest to count location
  Station_Ids. <- paste("GHCND:",Load_Stations_Info..$id[Load_Stations_Info..$City%in%city],sep="")
  #Add stations to certain cities since the assigned stations for these cities are still missing data types
  if(city%in%c("Springfield","Eugene")){Station_Ids. <- c(Station_Ids., "GHCND:USW00024221")}
  if(city%in%c("Portland","Stafford","Lake Oswego")){Station_Ids. <- c(Station_Ids., "GHCND:USW00024229")}
  if(city%in%c("Hillsboro")){Station_Ids. <- c(Station_Ids., "GHCND:USW00094261")}
  if(city%in%c("Bend")){Station_Ids. <- c(Station_Ids., "GHCND:USW00024230")}
  
  #Determine years to look up in climate data
  Years. <- as.character(2012:2021)
  #Initiate a data frame to store retreived data
  Load_Climate_Data.. <- data.frame()
  
  for(station_id in Station_Ids.){
    for(yr in Years.){
      for(dt in c("PRCP","TMAX","SNOW")){
        #Pull data for year and station
        Start_Date <- paste(yr,"-01-01",sep="")
        End_Date <- paste(yr,"-12-31",sep="")
        #Store in data frame
        Load_Climate_Data.. <- rbind(Load_Climate_Data.., ncdc(datasetid = 'GHCND', datatypeid = dt,stationid = station_id, startdate = Start_Date, enddate = End_Date,limit = 1000, add_units = T)$data)
      }
    }
  }
  print("Climate data downloaded, proceeding to formatting")
  #Make a copy
  Climate_Data.. <- Load_Climate_Data..
  #clean up station id name
  Climate_Data..$id <- gsub("GHCND:","",Climate_Data..$station)
  #Format names and date
  Climate_Data..$Date <- as.Date(Climate_Data..$date, format = "%Y-%m-%d")
  #Add year
  Climate_Data..$Year <- year(Climate_Data..$Date)
  #Add station name
  Climate_Data.. <- left_join(Climate_Data..,Station_Info.., by = "id")
  
  #Sumamrize counts and determine which stations to use based on com,leteness and nearness to site
  ################################################
  #Summarize climate data and determine number of records including those that are non-NA
  Climate_Data_Summary.. <- as.data.frame(Climate_Data.. %>% group_by(id,datatype, Year) %>% summarise(Count = length(value),Non_NA =  sum(!is.na(value))))
  #Add number of days in year
  Climate_Data_Summary.. <- left_join(Climate_Data_Summary.., Calendar_Summary.., by = "Year")
  #Add station names
  Climate_Data_Summary.. <- left_join(Climate_Data_Summary.., Station_Info.., by = "id")
  #Determine which stations have complete data (temperature and precipitation)
  Select_Climate_Summary.. <- filter(Climate_Data_Summary..[Climate_Data_Summary..$Count >= 300,], datatype !="SNOW")
  
  #Do snow separately since the data is spottier, i think due to no reporting on no snow days.
  Temp.. <- filter(Climate_Data_Summary.., datatype =="SNOW")
  #Determine maximum number of snow days by year to determine which station to select
  Max_Snow_Days.. <- Temp.. %>% group_by(Year) %>% summarize(Max_Snow_Days = max(Count))
  Temp.. <-left_join(Temp.., Max_Snow_Days.., by = "Year")
  Select_Snow_Climate_Summary.. <- Temp..[Temp..$Count == Temp..$Max_Snow_Days,]
  #$Append to other climate data
  Select_Climate_Summary..  <- rbind(Select_Climate_Summary.. , Select_Snow_Climate_Summary..[,colnames(Select_Climate_Summary..)] )
  
  
  #Prepare temperature and precipitation data
  ############################
  
  #Create a vector of cliamte data types to iterate through below
  Climate_Data_Types. <- c("TMAX","PRCP","SNOW")
  #Initialize a data frame
  #Format_Climate_Data.. <- data.frame(Date = NULL, CIty = NULL)
  #Create a counter to help df development below
  Df_Count <- 0
  #Select different stations for different climate elements based on available data
  for(datatype in   Climate_Data_Types.){
    #Select data type
    Select_Climate_Data.. <- Climate_Data..[Climate_Data..$datatype%in%datatype,]
    #Check to see if data type exists before proceeding
    if(nrow(Select_Climate_Data..) > 0){
      #Add to counter
      Df_Count <- Df_Count + 1
      #Select stations
      Station_Select.. <- Select_Climate_Summary..[Select_Climate_Summary..$datatype == datatype,]
      #Determine nearest station
      Min_Station_Distance.. <- Station_Select.. %>% group_by(Year) %>% summarise(  distance = min(distance))
      #Add a flag declaring if the data should be selected base don distance
      Min_Station_Distance..$Is_Nearest <- TRUE
      Station_Select.. <- left_join(Station_Select.., Min_Station_Distance.., by = c("Year","distance"))
      Station_Select.. <-  Station_Select..[ Station_Select..$Is_Nearest%in%TRUE,]
      Select_Climate_Data..  <- left_join(Select_Climate_Data.., Station_Select..[,c("id","Year","Is_Nearest")], by = c("id","Year"))
      #Selectr only climate data for select data type that is nearest
      Near_Climate_Data.. <-   Select_Climate_Data..[  Select_Climate_Data..$Is_Nearest%in%TRUE,]
      #Add count site id
      #Near_Climate_Data..$Sub_Location_Id <- sub_location_id
      #Add city
      Near_Climate_Data..$City <- city
      #Create new column name
      Near_Climate_Data..[,datatype] <- Near_Climate_Data..$value
      Near_Climate_Data.. <- Near_Climate_Data..[,c("Date","City",datatype)]
      #Store
      if(Df_Count== 1){
        Format_Climate_Data.. <- Near_Climate_Data..} else {
          Format_Climate_Data.. <- left_join(Format_Climate_Data.., Near_Climate_Data.., by = c("Date","City"))
          
        }
      
    }
  }
  
  
  #Pull Sunlight Data
  ####################################
  #Determein lat and long of count site
  #Long <- Site_Coordinates..$Longitude[ Site_Coordinates..$id%in%sub_location_id]
  #Lat <- Site_Coordinates..$Latitude[ Site_Coordinates..$id%in%sub_location_id]
  Long <-City_Coordinates..$Longitude[ City_Coordinates..$City%in%city]
  Lat <- City_Coordinates..$Latitude[ City_Coordinates..$City%in%city]
  #Get amount of sunlight sunride.set function() uses NOAA as reference so better than suncalc that has reported inaccuracies
  Sunlight_Data.. <- sunrise.set(lat = Lat, lon = Long, as.Date(min(Format_Climate_Data..$Date)), timezone = "UTC-8", nrow(Format_Climate_Data..))
  #Calcualte sun time (the sunrise and sunset times seem wrong but the total daylight is correct when checked against https://www.timeanddate.com/sun/usa/bend?month=1&year=2017
  Sunlight_Data..$Daylight_Mins <- as.numeric(Sunlight_Data..$sunset - Sunlight_Data..$sunrise) * 60
  Sunlight_Data..$Date <- as.Date(Sunlight_Data..$sunrise)
  #Select final columsn for joining
  Sunlight_Data.. <- Sunlight_Data..[,c("Date","Daylight_Mins")]
  #Store
  Format_Climate_Data.. <- left_join(Format_Climate_Data.., Sunlight_Data.., by = c("Date"))
  
  #Store
  Stored_Climate_Data.. <- rbind(Stored_Climate_Data.., Format_Climate_Data..)
  
  #Report progress
  print(paste(city,": ",count," of ",length(unique(Load_Stations_Info..$City))," Complete",sep=""))
  #Add to progress counter
  count <- count + 1
  
}

Load_Store_Climate_Data.. <- 	Stored_Climate_Data.. 
#Graph the weather data
##############################
pdf("Reports/SARM Analysis/EUG_SPR_Climate_Data_Review.pdf", height = 11, width = 11)

for(city in unique(Load_Store_Climate_Data..$City)){
  #Select data
  Select_Climate_Data.. <- Load_Store_Climate_Data..[Load_Store_Climate_Data..$City%in%city,]
  #Reformat
  Select_Climate_Data.. <- melt(Select_Climate_Data.., id.vars = c("City","Date"), variable.name = "Data_Type",value.name = "Value")
  #plot
  Plot <- 
    ggplot(Select_Climate_Data.., aes(x = Date, y = Value)) +
    geom_line(aes(x = Date, y = Value, color = Data_Type)) +
    facet_wrap(~Data_Type, scales = "free") +
    ggtitle(paste("Climate Data for: ", city, sep=""))
  
  print(Plot)
}
#Close pdf
dev.off()	
