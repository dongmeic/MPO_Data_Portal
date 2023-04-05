# This script was created to collect functions for LTD transit data
# By Dongmei Chen (dchen@lcog.org)
# On June 15th, 2021

library(rgdal)
library(readxl)
library(dplyr)
library(tools)
library(lubridate)
library(stringr)

options(warn = -1)
path <- "T:/Data/LTD Data/MonthlyBoardings/"
stop.path <- "T:/Data/LTD Data/StopsSince2011"

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

get.PassengerCounts <- function(year=2017, month='Jan', m='01'){
  if(year >= 2022){
    filepath = paste0(path, year, ' Ridership/LTD Ridership ', month,' ', year, '.xlsx')
  }else{
    filepath = paste0(path, year, ' Ridership/LTD Ridership_', year, '-', m, '-', month, '.xlsx')
  }
  Counts <- read_excel(filepath, 
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
  if(year == 2022){
    if(month %in% c('January', 'February', 'March')){
      stops.df <- get.stop.coordinates(m="October", yr=2019)
      stops.df$MonthYear <- "October 2019"
    }else if(month %in% c('October', 'November', 'December')){
      stops.df <- get.stop.coordinates(m="October", yr=2022)
      stops.df$MonthYear <- "October 2022"
    }else{
      stops.df <- get.stop.coordinates(m="April", yr=2020)
      stops.df$MonthYear <- "April 2020"
    }
  }else if(year > 2019){
    stops.df <- get.stop.coordinates(m="October", yr=2019)
    stops.df$MonthYear <- "October 2019"
  }else if(month %in% c('Jan', 'Feb', 'Mar')){
    if(paste("October", year-1) %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m="October", yr=year-1)
      stops.df$MonthYear <- paste("October", year-1)
    }else{
      stops.df <- get.stop.coordinates(m="April", yr=year-1)
      stops.df$MonthYear <- paste("April", year-1)
    }
  }else if(month %in% c('Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep')){
    if(paste("April", year) %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m="April", yr=year)
      stops.df$MonthYear <- paste("April", year)
    }else{
      stops.df <- get.stop.coordinates(m="October", yr=year-1)
      stops.df$MonthYear <- paste("October", year-1)
    }
  }else{
    if(paste("October", year) %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m="October", yr=year)
      stops.df$MonthYear <- paste("October", year)
    }else{
      stops.df <- get.stop.coordinates(m="April", yr=year)
      stops.df$MonthYear <- paste("April", year)
    }
  }
  if(nchar(stops.df$stop[1]) == 1){
    stops.df$stop <- ifelse(nchar(stops.df$stop) == 5, stops.df$stop,
                            paste0(zeros[(5 - nchar(stops.df$stop))], stops.df$stop))
  }
  Counts <- merge(Counts, stops.df, by = 'stop')
  Counts$month <- month(Counts$date, label=TRUE, abbr=FALSE)
  Counts$year <- year(Counts$date) 
  return(Counts)
}

get.YearlyCounts <- function(year=2022){
  months = c('January', 'February', 'March', 'April', 'May', 'June', 
             'July', 'August', 'September', 'October', 'November', 'December')
  ptm <- proc.time()
  for(month in months){
    if(month == 'January'){
      ndf <- get.PassengerCounts(year=year, month = month, m = NULL)
    }else{
      counts <- get.PassengerCounts(year=year, month = month, m = NULL)
      ndf <- rbind(ndf, counts)
    }
    print(paste(year, month))
  }
  print(proc.time() - ptm)
  ndf$date <- as.character(ndf$date)
  ndf$trip_end <- as.character(ndf$trip_end)
  ndf$time <- as.character(ndf$time)
  return(ndf)
}

get.MultiYearCounts <- function(years = 2017:2021,
                                startmonth = 1,
                                endmonth = 6,
                                complete = TRUE){
  # if it is a complete loop
  if(complete){
    ms = str_pad(startmonth:endmonth, 2, pad = "0")
  }else{
    ms = str_pad(startmonth:12, 2, pad = "0")
  }
  
  if(startmonth == 1){
    k = 0
  }else{
    k = startmonth - 1
  }

  startmonth = str_pad(startmonth, 2, pad = "0")
  endmonth = str_pad(endmonth, 2, pad = "0")
  months = c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
  
  # this will take a while
  ptm <- proc.time()
  for(yr in years){
    for(m in ms){
      if(!complete & yr == years[length(years)] & m == endmonth){
        break
      }else if(yr == years[1] & m == startmonth){
        ndf <- get.PassengerCounts(year=years[1], month = months[which(ms==m)+k], m = m)
      }else{
        counts <- get.PassengerCounts(year = yr, month = months[which(ms==m)+k], m = m)
        ndf <- rbind(ndf, counts)
      }
      print(paste(yr, m))
    }
  }
  proc.time() - ptm
  ndf$date <- as.character(ndf$date)
  ndf$trip_end <- as.character(ndf$trip_end)
  ndf$time <- as.character(ndf$time)
  return(ndf)
}

###### previous version ######
if(FALSE){
  correct.season <- function(myr){
    m = unlist(strsplit(myr, ' '))[1]
    yr = unlist(strsplit(myr, ' '))[2]
    if(m %in% c('September', 'October', 'November')){
      season = paste('Fall', yr)
    }else if(m %in% c('December', 'January', 'February')){
      season = paste('Winter', yr)
    }else if(m %in% c('March', 'April', 'May')){
      season = paste('Spring', yr)
    }else{
      season = paste('Summer', yr)
    }
    return(season)
  }
  
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
  
  get.PassengerCounts <- function(m="October", yr=2011){
    if(yr %in% c(2017, 2019, 2020)){
      myr <- yr
    }else{
      myr <- paste(m, yr)
    }
    if(myr %in% c("October 2011", "April 2013")){
      PassengerCounts <- read_excel(paste0(bodarding.path, myr,".xlsx"), 
                                    sheet = "passenger counts", 
                                    col_types = c("text", "text", "numeric", "text", 
                                                  "text", "text", "text", "text", 
                                                  "text", "numeric", "numeric", "numeric", 
                                                  "numeric", "numeric", "numeric",
                                                  "numeric"))
      
      PassengerCounts$date <- strptime(PassengerCounts$date, "%m/%d/%Y")
      PassengerCounts$trip_end <- strptime(PassengerCounts$trip_end, "%H:%M")
      PassengerCounts$time <- strptime(PassengerCounts$time, "%H:%M")
      if(myr == "April 2013"){
        PassengerCounts$route <- ifelse(PassengerCounts$route == '01', '1', PassengerCounts$route)
      }
    }else{
      PassengerCounts <- read_excel(paste0(bodarding.path, myr,".xlsx"), 
                                    sheet = "passenger counts", 
                                    col_types = c("text", "date", "numeric", "date", 
                                                  "date", "text", "text", "text", 
                                                  "text", "numeric", "numeric", "numeric", 
                                                  "numeric", "numeric", "numeric",
                                                  "numeric"))
    }
    
    stops.to.remove <- unique(grep('anx|arr|ann|escenter|garage', PassengerCounts$stop, value = TRUE))
    # remove the stops with letters
    PassengerCounts <- subset(PassengerCounts, !(stop %in% stops.to.remove)) %>% select(-c(latitude, longitude))
    # convert EmX
    Emx <- c("101", "102", "103", "104", "105")
    PassengerCounts$route <- ifelse(PassengerCounts$route %in% Emx, "EmX", PassengerCounts$route)
    # make the stop numbers to 5 digits
    zeros <- c("0", "00", "000", "0000")
    PassengerCounts$stop <- ifelse(nchar(PassengerCounts$stop) == 5, PassengerCounts$stop,
                                   paste0(zeros[(5 - nchar(PassengerCounts$stop))], PassengerCounts$stop))
    MonthYear.stops <- unique(file_path_sans_ext(list.files(stop.path)))
    if(myr %in% MonthYear.stops){
      stops.df <- get.stop.coordinates(m, yr)
    }else{
      # match with the same month and year unless data is missing, in which case match with the most recent data
      if(m == "October" & paste("April", yr) %in% MonthYear.stops){
        stops.df <- get.stop.coordinates(m="April", yr)
      }else{
        if(paste("October", yr-1) %in% MonthYear.stops){
          stops.df <- get.stop.coordinates(m="October", yr-1)
        }else{
          stops.df <- get.stop.coordinates(m="April", yr-1)
        }
      }
    }
    PassengerCounts <- merge(PassengerCounts, stops.df, by = 'stop')
    months <- c("April", "October")
    seasons <- c("Spring", "Fall")
    if(yr %in% c(2017, 2019, 2020)){
      PassengerCounts$Season <- ifelse(as.character(month(PassengerCounts$date, label=TRUE, abbr=FALSE)) == "April",
                                       paste("Spring", yr), paste("Fall", yr))
    }else{
      PassengerCounts$Season <- rep(paste(seasons[months==m], yr), dim(PassengerCounts)[1])
    }
    PassengerCounts$MonthYear <- paste(as.character(month(PassengerCounts$date, label=TRUE, abbr=FALSE)),
                                       year(PassengerCounts$date))
    # dates <- sort(unique(PassengerCounts$date))
    # routes <- unique(PassengerCounts$route)
    # for(i in 1:length(dates)){
    #   d <- dates[i]
    #   for(j in 1:length(routes)){
    #     r <- routes[j]
    #     PassengerCounts$DailyRtQty[PassengerCounts$date==d & PassengerCounts$route==r] <- sum(PassengerCounts$ons[PassengerCounts$date==d & PassengerCounts$route==r], na.rm = TRUE)
    #   }
    #   PassengerCounts$DailyQty[PassengerCounts$date==d] <- sum(PassengerCounts$ons[PassengerCounts$date==d], na.rm = TRUE)
    # }
    return(PassengerCounts)
  }
}
