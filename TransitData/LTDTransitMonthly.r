# This script was created by Dongmei Chen (dchen@lcog.org) to organize the monthly data
#  for the LTD transit dashboard based on LTDTransit.r
# (https://www.lcog.org/thempo/page/Transit-Ridership-Data) on July 21st, 2021

library(rgdal)
library(readxl)
library(dplyr)
library(tools)
library(lubridate)
library(stringr)

options(warn = -1)

# functions
get.stop.coordinates <- function(m="October", yr=2011){
  stops <- readOGR(dsn = stop.path, layer = paste(m, yr), verbose = FALSE, 
                   stringsAsFactors = FALSE)
  # convert to data frame
  colnames <- c("STOP_NUMBE", "LONGITUDE1" , "LATITUDE1",
                "LONGITUDE_", "LATITUDE_W",
                "stop_numbe", "longitude", "latitude")
  colnames <- colnames[colnames %in% names(stops)]
  if(length(colnames) > 3){
    colnames <- colnames[1:3]
  }
  stops.df <- stops@data[, colnames]
  if("LONGITUDE_" %in% colnames){
    stops.df[,2] <- as.numeric(stops.df[,2])/10000000
    stops.df[,3] <- as.numeric(stops.df[,3])/10000000
  }
  names(stops.df) <- c("stop", "longitude", "latitude")
  return(stops.df)
}

path <- "T:/Data/LTD Data/MonthlyBoardings/"
stop.path <- "T:/Data/LTD Data/StopsSince2011"

get.PassengerCounts <- function(year=2017, month='Jan', m='01'){
  Counts <- read_excel(paste0(path, year, ' Ridership/LTD Ridership_', year, '-', m, '-', month, '.xlsx'), 
                       sheet = "passenger counts", 
                       col_types = c("text", "date", "numeric", "date", 
                                     "date", "text", "text", "text", 
                                     "text", "numeric", "numeric", "numeric", 
                                     "numeric", "numeric", "numeric",
                                     "numeric"))
  
  stops.to.remove <- unique(grep('anx|arr|ann|escenter|garage', Counts$stop, value = TRUE))
  # remove the stops with letters
  Counts <- subset(Counts, !(stop %in% stops.to.remove)) %>% select(-c(latitude, longitude))
  # convert EmX
  Emx <- c("101", "102", "103", "104", "105")
  Counts$route <- ifelse(Counts$route %in% Emx, "EmX", Counts$route)
  # make the stop numbers to 5 digits
  zeros <- c("0", "00", "000", "0000")
  Counts$stop <- ifelse(nchar(Counts$stop) == 5, Counts$stop,
                        paste0(zeros[(5 - nchar(Counts$stop))], Counts$stop))
  MonthYear.stops <- unique(file_path_sans_ext(list.files(stop.path)))
  if(month %in% c('Jan', 'Feb', 'Mar')){
    if(paste("October", year-1) %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m="October", yr=year-1)
    }else{
      stops.df <- get.stop.coordinates(m="April", yr=year-1)
    }
  }else if(month %in% c('Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep')){
    if(paste("April", year) %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m="April", yr=year)
    }else{
      stops.df <- get.stop.coordinates(m="October", yr=year-1)
    }
  }else{
    if(paste("October", year) %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m="October", yr=year)
    }else{
      stops.df <- get.stop.coordinates(m="April", yr=year)
    }
  }
  
  Counts <- merge(Counts, stops.df, by = 'stop')
  Counts$month <- month(Counts$date, label=TRUE, abbr=FALSE)
  Counts$year <- year(Counts$date) 
  return(Counts)
}

counts <- get.PassengerCounts()

years = 2017:2021
ms = str_pad(1:12, 2, pad = "0")
months = c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')

for(yr in years){
  for(m in ms){
    if(yr==2021 & m=='06'){
      break
    }else if(yr == 2017 & m == '01'){
      ndf <- get.PassengerCounts()
    }else{
      counts <- get.PassengerCounts(year = yr, month = months[which(ms==m)], m = m)
      ndf <- rbind(ndf, counts)
    }
    print(paste(yr, m))
  }
}
