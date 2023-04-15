
# Created by DC on April 14th, 2023
# to summarize daily bike counts

library(lubridate)
library(sf)

inpath <- 'T:/Data/COUNTS/Nonmotorized Counts/Summary Tables/Bicycle/'
data <- read.csv(paste0(inpath, 'Bicycle_HourlyForTableau.csv'))
locdata <- read.csv("T:/Data/COUNTS/Nonmotorized Counts/Supporting Data/Supporting Bicycle Data/CountLocationInformation.csv")


dat <- data[data$Direction == "Total" & data$ObsHours == 24,]
pmloc <- unique(locdata[locdata$CountType=="Permanent", "Location"])
dt <- dat[dat$Location %in% pmloc,]

locvars <- c('CountType', 'Direction', 'FacilityType', 'RoadWidth', 'City', 
             'Location', 'Latitude', 'Longitude', 'Site_Name', 
             'DoubleCountLocation', 'IsOneway', 'OnewayDirection', 
             'IsSidewalk', 'Location_Description')

dt$Date <- as.Date(dt$Date, "%Y-%m-%d")

aggdata <- aggregate(x=list(DailyCounts = dt$Hourly_Count), 
                     by=list(Date = dt$Date, Location = dt$Location), 
                     FUN=sum, na.rm=TRUE)

no_days <- aggregate(x=list(ObsDays = dt$Date), 
                     by=list(Location = dt$Location, Year=dt$Year), 
                     FUN=function(x) length(unique(x)))

datedata <- unique(dt[,c("Date", "Month", "MonthDesc", "Season", "Weekday", 
                         "IsHoliday", "UoInSession", "IsSpecialEvent")])

aggdata$Year <- year(aggdata$Date)
ave_daily_cnt <- aggregate(x=list(AveDailyCnt = aggdata$DailyCounts), 
                           by=list(Location = aggdata$Location, Year=aggdata$Year), 
                           FUN=mean)

AveDailyCnt <- merge(ave_daily_cnt, no_days, by=c("Location", "Year"))
AveDailyCnt <- merge(AveDailyCnt, locdata[,locvars], by = 'Location')

aggdata <- merge(aggdata, datedata, by="Date")
aggdata <- merge(aggdata, locdata[,locvars], by = 'Location')
aggdata$SeasonOrder <- ifelse(aggdata$Season == "Spring", 1, 
                              ifelse(aggdata$Season == "Summer", 2, 
                                     ifelse(aggdata$Season == "Fall", 3, 4)))
aggdata$WeekdayOrder <- ifelse(aggdata$Weekday == "Monday", 1, 
                               ifelse(aggdata$Weekday == "Tuesday", 2, 
                                      ifelse(aggdata$Weekday == "Wednesday", 3, 
                                             ifelse(aggdata$Weekday == "Thursday", 4, 
                                                    ifelse(aggdata$Weekday == "Friday", 5, 
                                                           ifelse(aggdata$Weekday == "Saturday", 6, 7))))))
aggdata$DOY <- yday(aggdata$Date)
  
outpath <- 'T:/Tableau/tableauBikeCounts/Datasources'
write.csv(aggdata, paste0(outpath, "/Daily_Bike_Counts_Permanent.csv"), row.names = FALSE)
write.csv(AveDailyCnt, paste0(outpath, "/Average_Daily_Bike_Counts_Permanent.csv"), row.names = FALSE)
