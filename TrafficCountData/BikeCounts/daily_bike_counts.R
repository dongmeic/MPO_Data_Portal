
# Created by DC on April 14th, 2023
# to summarize daily bike counts

library(lubridate)
library(sf)
library(dplyr)

inpath <- 'T:/Data/COUNTS/Nonmotorized Counts/Summary Tables/Bicycle/'
data <- read.csv(paste0(inpath, 'Bicycle_HourlyForTableau.csv'))
locdata <- read.csv("T:/Data/COUNTS/Nonmotorized Counts/Supporting Data/Supporting Bicycle Data/CountLocationInformation.csv")


#dat <- data[data$Direction == "Total" & data$ObsHours == 24,]
# aggregate data on permanent counter sites
dat <- data[data$ObsHours == 24,]
pmloc <- unique(locdata[locdata$CountType=="Permanent", "Location"])
dt <- dat[dat$Location %in% pmloc,]

locvars <- c('CountType', 'FacilityType', 'RoadWidth', 'City', 
             'Location', 'Latitude', 'Longitude', 'Site_Name', 
             'DoubleCountLocation', 'IsOneway', 'OnewayDirection', 
             'IsSidewalk', 'Location_Description')

dt$Date <- as.Date(dt$Date, "%Y-%m-%d")

aggdata <- aggregate(x=list(DailyCounts = dt$Hourly_Count), 
                     by=list(Date = dt$Date, Location = dt$Location, Direction=dt$Direction), 
                     FUN=sum, na.rm=TRUE)

no_days <- aggregate(x=list(ObsDays = dt$Date), 
                     by=list(Location = dt$Location, Year=dt$Year, Direction=dt$Direction), 
                     FUN=function(x) length(unique(x)))

datedata <- unique(dt[,c("Date", "Month", "MonthDesc", "Season", "Weekday", 
                         "IsHoliday", "UoInSession", "IsSpecialEvent")])

aggdata$Year <- year(aggdata$Date)
ave_daily_cnt <- aggregate(x=list(AveDailyCnt = aggdata$DailyCounts), 
                           by=list(Location = aggdata$Location, 
                                   Year=aggdata$Year, 
                                   Direction=aggdata$Direction), 
                           FUN=mean)

AveDailyCnt <- merge(ave_daily_cnt, no_days, by=c("Location", "Year", "Direction"))
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

aggdata <- merge(aggdata, no_days, by=c("Location", "Year", "Direction"))
  
outpath <- 'T:/Tableau/tableauBikeCounts/Datasources'
write.csv(aggdata, paste0(outpath, "/Daily_Bike_Counts_Permanent.csv"), row.names = FALSE)
write.csv(AveDailyCnt, paste0(outpath, "/Average_Daily_Bike_Counts_Permanent.csv"), row.names = FALSE)

# grep("SB|NB|EB|WB| Side", unique(locdata$Location), value=TRUE)
# grep("13th", unique(locdata$Location), value=TRUE)
 
# data[data$Location %in% c("13thEastKincaidNorth", "13thEastKincaidSouth"),]
# locdata[locdata$Location %in% c("13thEastKincaidNorth", "13thEastKincaidSouth"),]

# reorganize data on the "13thEastKincaid" site
df <- data[data$Location %in% c("13thEastKincaidNorth", "13thEastKincaidSouth"),]
cols <- list()
cols2 <- list()
for(col in colnames(df)){
  if(length(unique(df[,col]))==1){
    cols <- append(cols, col)
  }else if(length(unique(df[,col]))==2){
    cols2 <- append(cols2, col)
  }
}

cols <- unlist(cols)
cols2 <- unlist(cols2)
# colnames(df)[!(colnames(df) %in% c(cols, cols2))]
# df[df$Date == "2019-10-24",]
# df$ID <- paste0(df$UniqueId, '-', df$Hour)
# df <- df %>% 
#   subset(select=-ID)

sdf <- df %>% 
  group_by(Direction, Date, Hour) %>%
  summarise(Hourly_Count=sum(Hourly_Count, na.rm = TRUE))

sdf2 <- sdf %>% group_by(Direction, Date) %>%
  summarise(DailyCounts=sum(Hourly_Count, na.rm = TRUE))

sdf3 <- df %>% filter(!is.na(Hourly_Count)) %>%
  group_by(Direction, Date) %>%
  summarise(ObsHours=n_distinct(Hour, na.rm = TRUE))

sdf$Location <- "13thEastKincaid"
sdf$LocationId <- 219
date_df <- unique(df[,colnames(df)[5:13]])
sdf <- merge(sdf, date_df, by="Date")
for(col in cols){
  sdf[,col] <- df[1, col]
}
#colnames(df)[!(colnames(df) %in% colnames(sdf))]
sdf <- merge(sdf, sdf2, by=c("Direction", "Date"))
sdf <- merge(sdf, sdf3, by=c("Direction", "Date"))
sdf$UniqueId <- paste0(sdf$Direction, "-", sdf$Location, "-", format(as.Date(sdf$Date), format="%m-%d-%Y"))

df <- rbind(df, sdf[,colnames(df)])
#df[df$Location=="13thEastKincaid",]
out <- rbind(data[!(data$Location %in% c("13thEastKincaidNorth", "13thEastKincaidSouth")),], df)
write.csv(out, paste0(outpath, 'Bicycle_HourlyForTableau.csv'), row.names = FALSE)

# reorganize the counter info
nlocdt <- data.frame(LocationId=integer(),
                     CountType=character(),
                     Direction=character(),
                     FacilityType=character(),
                     ArrowAngle=integer(),
                     RoadWidth=integer(),
                     IsAutomatic=logical(),
                     Location=character(),
                     HasData=logical(),
                     City=character(),
                     DoubleCountLocation=logical(),
                     IsOneway=logical(),
                     OnewayDirection=character(),
                     IsSidewalk=logical(),
                     Latitude=numeric(),
                     Longitude=numeric(),
                     ImageFilePath=character(),
                     Site_Name=character(),
                     Location_Description=character(),
                     TAZ=integer(),
                     Visual=logical())

nlocdt[1,] = list(219, "Manual", "EW", "Path", 0, 34, FALSE, "13thEastKincaid", 
                  TRUE, "Eugene", FALSE, FALSE, "<Null>", FALSE, 44.04551, 
                  -123.0785, "13thEastKincaidNorth.jpg, 13thEastKincaidNorth.jpg", 
                  "13th Ave East of Kincaid St", 
                  "13th Ave, 60ft east of Kincaid St, Eugene", 398, TRUE)

locdata <- rbind(locdata, nlocdt)
write.csv(locdata, paste0(outpath, 'CountLocationInformation.csv'), row.names = FALSE)


# for(col in colnames(locdata)){
#   if(col %in% colnames(out)){
#     print(col)
#   }
# }
# 
# out <- merge(out, locdata[,-which(colnames(locdata) %in% c("Direction", 
#                                                            "Location", 
#                                                            "IsOneway", 
#                                                            "OnewayDirection",
#                                                            "IsSidewalk"))], on="LocationId")
# write.csv(out, paste0(outpath, '/Bicycle_Hourly_wLocInfo.csv'), row.names = FALSE)
# out[out$Location=="13thEastKincaid",]
