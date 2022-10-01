#---------#---------#---------#---------#---------#---------#---------#---------
# Original Author: Josh Roll 
# Date: 11/11/2019
# Description:   
#   Use hold out analysis and test holding out each combination of 
#   months to determine the error for each month and total annual estimation.  
#   Comparing the pre-selected negative binomial statistical model against 
#   machine learning algorithms
# Version: 5.0.0
#   Refactor
# Refactor Author: Damian Satterthwaite-Phillips
# Refactor Date 2022-09-22 
# Developed under R 4.1.0
library(dplyr)
library(ggplot2)
library(lubridate)
library(readxl)	
library(StreamMetabolism)
library(timeDate)

	
options(scipen=999)
setwd('~/Learning/dongmei/MPO_Data_Portal/TrafficCountData/AADBT')
#setwd('T:/DCProjects/Modeling/AADBT/reading/Test/Data')
source('src/utils.R')
	

load.custom.vector <- function(sheet, vec.field, name.field) {
  data.dict <- as.data.frame(read_excel('data/Data Dictionary.xlsx', sheet=sheet))
  vec <- data.dict[, vec.field]
  names(vec) <- data.dict[, name.field]
  vec[!(is.na(names(vec)))]
}


load.custom.vectors <- function() {
  # in this file, at least, only <error.codes> is used.  Maybe drop others?
  sheets <- c(
    rep('User_Type_Code', 2), 'Direction', 'Collection_Type_Code', 
    'Facility_Type_Code', 'Device_Type', 'Error_Codes')
  vec.fields <- c(
    rep('User_Type', 2), 'Direction_Code', 'Collection_Type', 'Facility_Type', 
    'Device_Type', 'Error_Code')
  name.fields <- c(
    'Eco_User_Type_Desc', 'User_Type_Desc', 'Direction_Desc', 
    'Collection_Type_Desc', 'Facility_Type_Desc', 'Device_Type_Desc', 
    'Error_Name')
  vecs <- list()
  n.vecs <- length(sheets)
  for (i in 1:n.vecs) {
  	vecs[[i]] <- load.custom.vector(sheets[i], vec.fields[i], name.fields[i])
  }
  names(vecs) <- c(
    'eco.user.type', 'user.type', 'direction.descr', 'collection.type', 
    'facility.type', 'device.type', 'error.code')
  vecs
}

prep.climate.data <- function(climate) {
  climate.data <- climate
  climate.data$Index <- paste(climate.data$Date, climate.data$City, sep='-')
  climate.data <- climate.data[!(duplicated(climate.data$Index)), ]
  climate.data$SNOW[is.na(climate.data$SNOW)] <- 0
  # BUG IN ORIGINAL: original is missing <as.Date()> and doesn't match anything
  climate.data$Daylight_Mins[
    climate.data$Date %in% as.Date(c('2019-12-31', '2018-12-31', '2012-12-31'))
  ] <- 529
  climate.data
}


prep.daily <- function(
    daily.sub.location, site.location, error.code, climate.data) {
  daily <- daily.sub.location[
    daily.sub.location$Collection_Type_Desc %in% 'Permanent'
    & daily.sub.location$Direction %in% 'Total', ]
  daily$Error_Code_Desc <- names(error.code)[
    match(daily$Error_Code, error.code)]
  daily <- daily [!(daily$Error_Code %in% 1), ]   
  daily <- left_join(
    daily,
    as.data.frame(site.location)[, c('Vendor_Site_Id', 'City')],
    by=c('Vendor_Site_Id'))
  daily$City <- as.character(daily$City)    
  daily <- left_join(daily, climate.data, by=c('Date', 'City'))
  daily <- daily[!(is.na(daily$TMAX)), ]
  daily$Daylight_Mins <- climate.data$Daylight_Mins[
    match(daily$Date, climate.data$Date)]
  daily
}


# Summarize the number of records by device and by year
get.daily.counts <- function(daily) {
  daily %>% 
    group_by(Device_Name, User_Type_Desc, Year) %>%
    summarise(Count=length(Counts))
}


# Create a summary of daily observations to device what data to use
get.daily.summary <- function(daily) {
  daily %>% 
    group_by(Device_Name, User_Type_Desc,Year) %>% 
    summarise(Obs_N=length(Counts[!(is.na(Counts))]))
}


join.daily.summary.and.daily <- function(daily.summary, daily) {
  left_join(
    daily.summary, 
    daily %>% 
      group_by(Device_Name, User_Type_Desc, Year) %>% 
      summarise(Obs_N_Clean=length(Counts[!(is.na(Counts))])),
    by=c('Device_Name', 'User_Type_Desc', 'Year'))
}


finalize.daily <- function(daily, daily.summary, include.years) {
  # Summarize number of observations again with cleaned data
  daily <- left_join(
    daily, daily.summary, by=c('Device_Name', 'User_Type_Desc', 'Year'))
  daily <- daily[daily$Obs_N_Clean >= 350, ]
  daily$Week <- week(daily$Date)
  daily <- daily[!(is.na(daily$Device_Name)), ]
  daily <- daily[daily$Year %in% include.years, ]
  # Remove locations that are duplicates or have known issues
  # Remove combination of user type and location
  bad.pedestrian.names <- c(
    'Portland Ave. Southside', 'PB Nature trail/formerly base tr.', 
    'Minto Brown South', 'Rosa Parks Path south of Q St',
     'Millrace Path @ Booth Kelly')
  bad.bike.names <- c(
    'HAWTHORNE BR north side', 'HAWTHORNE BR south side', 'Hawthorne totem', 
    'Tilikum Crossing 2 (Westbound)', 'Tilikum Crossing 1 (Eastbound)', 
    'Tilikum Crossing 1 (Westbound)', 'Tilikum Crossing Total',
     'Alder north of 18th Ave', 'Newport Ave. Northside', 
     'Newport Ave. Southside') 
  daily <- daily[
    !(daily$Device_Name %in% bad.pedestrian.names 
      & daily$User_Type_Desc %in%'Pedestrian'), ]
  daily <- daily[
    !(daily$Device_Name %in% bad.bike.names 
      & daily$User_Type_Desc %in% 'Bicycle'), ]
  daily <- daily[daily$User_Type_Desc %in% c('Bicycle', 'Pedestrian'), ]
  daily
}


# Summarize final number of devices by user type and year used in the factoring 
# testing below
get.daily.summary.year <- function(daily) {
  daily %>% 
    group_by(Year,User_Type_Desc) %>% 
    summarise(
      Device_Count=length(unique(Device_Name)), 
      Mean_AADT=mean(Counts), 
      Median_AADT=median(Counts), 
	  Obs_N = length(Counts) / length(unique(Device_Name)))
}


# Summarize the number of records by device and by year
summarize.daily.counts.records <- function(daily) {
  daily.counts <- daily %>% 
    group_by(Device_Name, User_Type_Desc,Year) %>% 
    summarise(
      Obs_N=length(Counts[!(is.na(Counts))]), ADT=round(mean(Counts, na.rm=T)))
  # Remove locations with issues after review (below)
  locations.to.remove <- c(
    'Willamette St west Sidewalk north of Broadway', 'BendMULTI551', 
    'BendMULTI552')	
  daily.counts <- daily.counts[
    !(daily.counts$Device_Name %in% locations.to.remove), ] 
  # Remove locations/years with known issues for specific years
  daily.counts <- daily.counts[
    !(daily.counts$Device_Name %in% c(
        'Fern Ridge Path west of Chambers', 'Minto North') &
      daily.counts$Year %in% c('2013', '2014')),]
  daily.counts
}


# Plot daily counts for each year to review data; Save as PDF.
plot.daily.counts.all.to.pdf <- function(outpath, daily, error.code) {
  pdf(outpath, height=11, width=11)
  for (location in unique(daily$Device_Name)) {
    # Select count location
    dat <- daily[daily$Device_Name %in% location, ]
    shapes <- c(3, 15, 17, 16, 12, 6)
    names(shapes) <- names(error.code)
    plt <- ggplot(dat, aes(x=Date, y=Counts)) +
      geom_line(aes(x=Date, y=Counts), color='black', group=1) +
	  geom_point(
	    aes(x=Date, y=Counts, pch=Error_Code_Desc, color=Is_Holiday), 
	    group=1, 
	    size=2) +
      scale_colour_manual(c('No','Holiday'), values=c('black','skyblue')) +
      facet_wrap(~User_Type_Desc, scales='free') +
      scale_shape_manual(values=shapes) +
      ggtitle(location)		
    print(plt)
  }
  dev.off()
}


handle.climate.data.dates <- function(climate.data) {
  climate.data$Year <- year(climate.data$Date)
  climate.data$Month <- months(climate.data$Date)  
  #climate.data <- climate.data[ 
  #  ,c('Date','Month','Year','Max_Temp','Precip','Snow','Daylight_Mins')]
  climate.data$Weekday <- weekdays(climate.data$Date)
  climate.data$Is_Weekday <- 'Weekday'
  climate.data$Is_Weekday[
    climate.data$Weekday %in% c('Saturday', 'Sunday')] <- 'Weekend' 
  holidays <- c(
    'USNewYearsDay', 'USInaugurationDay', 'USMLKingsBirthday', 'USMemorialDay', 
    'USIndependenceDay', 'USLaborDay', 'USVeteransDay', 'USThanksgivingDay', 
    'USChristmasDay')
  holiday.dates <- as.Date(
    dates(
      as.character(holiday(unique(climate.data$Year), holidays)),
      format='Y-M-D'),
    format='%m/%d/%Y')
  climate.data$Is_Holiday <- F
  climate.data$Is_Holiday[climate.data$Date %in% holiday.dates] <- T
  climate.data
}

	  
# Summarize climate data for select locations
get.select.climate.data <- function(climate.data, daily) {
  select.climate.data <- climate.data[climate.data$City %in% unique(daily$City), ]
  select.climate.data %>% 
    group_by(City) %>% 
    # Use of "magic numbers" is bad coding practice. WHat do 10 and 0.0393701 
    # represent?? Readers of the code should not be epxected to know, so replace
    # with named variables like:
    # N_YEARS <- 10
    # ...or whatever
    summarise(
      Mean_Max_Temp=mean(TMAX), Total_Precip=sum((PRCP / 10), na.rm=T) /
        length(unique(Year)) * 0.0393701, 
      Total_Snow=sum((SNOW / 10)) / length(unique(Year)) * 0.0393701)
}


save.data <- function(climate.data, daily, daily.counts) {
  write.csv(climate.data, 'data/climateData.csv')
  write.csv(daily, 'data/daily.csv')
  write.csv(daily.counts, 'data/dailyCounts.csv')
}


main <- function() {
  custom.vectors <- load.custom.vectors()
  error.code <- custom.vectors$error.code
  daily.sub.location <- assign.load('data/Daily_Sub_Location_Id_406683.RData')
  site.location <- assign.load('data/Site_Location_Info_116.RData')
  #site.location.sp <- assign.load('data/Site_Location_Info_Sp_116.RData')
  climate <- assign.load('data/NOAA_Data.RData')
  climate.data <- prep.climate.data(climate)
  daily <- prep.daily(
    daily.sub.location, site.location, error.code, climate.data)
  daily.counts <- get.daily.counts(daily)
  daily.summary <- get.daily.summary(daily)
  # Remove holidays
  #daily <- daily[daily$Is_Holiday != FALSE, ]
  # Remove consecutive zeros
  daily <- daily[!(daily$Error_Code %in% c(1, 3)), ]
  daily.summary <- join.daily.summary.and.daily(daily.summary, daily)
  daily <- finalize.daily(
    daily, daily.summary, include.years=c('2017','2018','2019'))
  daily.summary.year <- get.daily.summary.year(daily)	
  daily.counts <- summarize.daily.counts.records(daily) 
  # outpath was: 'Reports/Imputation/Daily_Counts_All.pdf'
  daily.counts.all.path <- 'data/DailyCountsAll.pdf'
  climate.data <- handle.climate.data.dates(climate.data)
  select.climate.data <- get.select.climate.data(climate.data, daily)
  cat('No. distincts devices: ', length(unique(daily.counts$Device_Name)), '\n')
  plot.daily.counts.all.to.pdf(daily.counts.all.path, daily, error.code)
  save.data(climate.data, daily, daily.counts)
}


main()