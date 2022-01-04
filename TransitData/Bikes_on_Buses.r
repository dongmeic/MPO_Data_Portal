# This script was created by Dongmei Chen (dchen@lcog.org) to reorganize and calculate data
#  for the bikes on buses dashboard 
# (https://www.lcog.org/906/Bikes-on-Buses) on May 18th, 2020

library(rgdal)
library(readxl)
library(dplyr)
library(tools)
library(lubridate)

source("T:/DCProjects/GitHub/MPO_Data_Portal/TransitData/Bikes_on_Buses_Functions.r")
inpath <- "T:/Data/LTD Data/BikeOnBuses/Monthly"
outfolder <- "T:/Tableau/tableauBikesOnBuses/Datasources"
data <- read.csv(paste0(outfolder, "/AllBikeCounts.csv"))
excel_sheets(paste0(inpath,"/LTD Bike Count_2021.xlsx"))

get_bikecounts <- function(fileName = "LTD Bike Count_2021",
                           sheetName = "bike count_Apr21",
                           m="April",
                           yr=2021){
  df <- read_excel(paste0(inpath,"/", fileName, ".xlsx"), 
                   sheet = sheetName, 
                   col_types = c("text", "date", "numeric", "date", 
                                 "date", "text", "text", "text", 
                                 "text", "numeric", "numeric", "numeric", 
                                 "numeric", "text", "numeric"))
  stops.to.remove <- unique(grep('anx|arr|ann|escenter|garage', df$stop, value = TRUE))
  # remove the stops with letters
  df <- subset(df, !(stop %in% stops.to.remove)) %>% select(-c(latitude, longitude))
  # convert EmX
  Emx <- c("101", "102", "103", "104", "105")
  df$route <- ifelse(df$route %in% Emx, "EmX", df$route)
  # make the stop numbers to 5 digits
  zeros <- c("0", "00", "000", "0000")
  df$stop <- ifelse(nchar(df$stop) == 5, df$stop,
                    paste0(zeros[(5 - nchar(df$stop))], df$stop))
  stops.df <- get.stop.coordinates("October", 2019)
  df <- merge(df, stops.df, by = 'stop')
  months <- c("April", "October")
  seasons <- c("Spring", "Fall")
  df$Season <- rep(paste(seasons[months==m], yr), dim(df)[1])
  df$MonthYear <- paste(as.character(month(df$date, label=TRUE, abbr=FALSE)),
                        year(df$date))
  dates <- sort(unique(df$date))
  routes <- unique(df$route)
  for(i in 1:length(dates)){
    d <- dates[i]
    #print(d)
    for(j in 1:length(routes)){
      r <- routes[j]
      df$DailyRtQty[df$date==d & df$route==r] <- sum(df$qty[df$date==d & df$route==r], na.rm = TRUE)
    }
    df$DailyQty[df$date==d] <- sum(df$qty[df$date==d], na.rm = TRUE)
  }
  return(df)
}

############################# Before 2021 ###########################
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