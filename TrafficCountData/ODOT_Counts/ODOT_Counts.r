# This script was created to clean ODOT counts data
# By Dongmei Chen (dchen@lcog.org)
# On April 9th, 2020

# load functions
source("T:/Data/COUNTS/ODOT_Counts and Forecasts/Scripts/ODOT_Counts_Functions.r")
inpath <- "T:/Data/COUNTS/ODOT_Counts and Forecasts/ATR Downloads by Month/"

############################## Run before Oct 2020 ################################
# update data after October 2020


############################## Data cleaning 2nd ################################








############################## Run before Oct 2020 ################################
# update data before October 2020
# range of the station table started from the 'Date' column and ended with the '24' column 
range <- "A16:Z46"
# the year folder name
year <- 2020
# the month folder name
month <- "Sep"
# last update month was May, 2020
Update.ODOD.Counts.By.Month(inpath, range, year, month)
Update.ODOD.Counts.By.Month(inpath, range, year, month, LR=TRUE)

############################## Data cleaning ################################
# test functions
range <- "A16:Z47"
year <- 2020
month <- "Jan"
length <- "35-61"
stationID <- "20027"

path <- getpath(inpath, year, month)
df <- read.odot.sheet(path, "20004", "WB", range)
df <- read.odot.sheet(path, "20027", "WB", range, LR = TRUE)
df <- read.odot.sheets(path, length, stationID, range)
df <- read.odot.sheets(path, length, stationID, range, LR = FALSE)
df <- read.odot.station(path, "20020", range)
df <- read.odot.station(path, "20027", range, LR = TRUE)
df <- read.odot.counts(path, range)
df <- read.odot.counts(path, range, LR = TRUE)

# need to reorganize the counts data before 2020
months <- c("Jan", "Feb", "March", "April", "May", "June", "July", "August", "Sept", "Oct", "Nov", "Dec")
years <- 2011:2019

for(year in years){
  if(year == 2011){
    for(m in c("Oct", "Nov")){
      path <- paste0(inpath, paste(m, year), "/")
      if(m == "Oct"){
        df <- read.odot.table(path, m, year)
      }else{
        ndf <- read.odot.table(path, m, year)
        df <- rbind(df, ndf)
      }
      print(paste("added", year, m))
    }
    }else{
      for(m in months){
        path <- paste0(inpath, paste(m, year), "/")
        if(m == "August"){
          m = "Aug"
        }
        if(year == 2012 && m == "March"){
          # something is wrong with the March 2012 data
          df.201203 <- read.odot.counts(paste0(inpath, "/March 2012/"), range="A17:Z46")
          write_xlsx(df.201203, paste0(inpath, "/March 2012/", "HourlyForTableau_March2012.xlsx"))
          df <- rbind(df, df.201203)
        }else{
          ndf <- read.odot.table(path, m, year)
          df <- rbind(df, ndf)
          print(paste("added", year, m))        
        }
      }
    }
}
df$Hour <- ifelse(df$Hour == "0", "12:00 AM", df$Hour)
write.csv(df, "T:/Tableau/tableauODOTCounts/Datasources/ODOT_ALL_HourlyForTableau.csv", row.names = FALSE)

# update data
# check the excel range, an example shown below
range <- "A16:Z46"
year <- 2020
month <- "Jan"
Update.ODOD.Counts.By.Month(inpath, "A16:Z47", year, "Jan")
Update.ODOD.Counts.By.Month(inpath, "A17:Z46", year, "Feb")
Update.ODOD.Counts.By.Month(inpath, "A16:Z47", year, "Jan", LR=TRUE)
Update.ODOD.Counts.By.Month(inpath, "A17:Z46", year, "Feb", LR=TRUE)

# 'correction' on the 2012 March data
datapath <- "T:/Data/COUNTS/ODOT_Counts and Forecasts/ATR Downloads by Month/MergeStaging/ODOT_ALL_HourlyForTableau.csv"
data <- read.csv(datapath, stringsAsFactors = FALSE)
data.201203 <- subset(data, year(parse_date_time(data$Date, orders = "mdy")) == 2012 & month(parse_date_time(data$Date, orders = "mdy")) == 3)
head(data.201203)
df.subset <- df[!(year(parse_date_time(df$Date, orders = "mdy")) == 2012 & month(parse_date_time(df$Date, orders = "mdy")) == 3),]
head(df.subset)
ndf <- subset(df.subset, year(parse_date_time(df.subset$Date, orders = "mdy")) == 2012)
unique(month(parse_date_time(ndf$Date, orders = "mdy")))
df <- rbind(df.subset, data.201203)

# redo length reports 
# 1. from 2011 to 2013 the yearly length report are saved in 
# "T:\Data\COUNTS\ODOT_Counts and Forecasts\ATR Downloads by Month\HistLength"
# 2. the rest length reports are saved in a "Length Reports" folder

# test the functions
stationID = 20017
length = '35-61'
year = 2014
m = "August"

path = "T:/Data/COUNTS/ODOT_Counts and Forecasts/ATR Downloads by Month/HistLength/2011 Length Reports/"
range = 'A65:Z430'

path = "T:/Data/COUNTS/ODOT_Counts and Forecasts/ATR Downloads by Month/April 2014/Length Reports/"
range = 'A16:Z46'

df <- read.hist.LR.sheets(path, length, stationID, range)
df <- read.hist.LR(path, stationID, range)
df <- read.hist.counts(path, range)

years1 <- 2011:2013
ranges1 <- c('A65:Z430', 'A65:Z431', 'A65:Z430')
# 2014
ranges2 <- c('A16:Z47', 'A16:Z44', 'A17:Z48', 'A16:Z46', 'A17:Z48', 'A16:Z46', 'A16:Z47',
             'A17:Z48', 'A16:Z46', 'A16:Z47', 'A17:Z47', 'A16:Z47')
# 2015
ranges3 <- c('A17:Z48', 'A16:Z44', 'A16:Z47', 'A16:Z46', 'A17:Z48', 'A16:Z46', 'A16:Z47',
             'A17:Z48', 'A16:Z46', 'A17:Z48', 'A16:Z46', 'A16:Z47')
# 2016
ranges4 <- c('A17:Z48', 'A16:Z45', 'A16:Z47', 'A17:Z47', 'A16:Z47', 'A16:Z46', 'A17:Z48',
             'A16:Z47', 'A16:Z46', 'A17:Z48', 'A16:Z46', 'A17:Z48')
# 2017
ranges5 <- c('A16:Z47', 'A16:Z44', 'A16:Z47', 'A17:Z47', 'A16:Z47', 'A16:Z46', 'A17:Z48',
             'A16:Z47', 'A17:Z47', 'A16:Z47', 'A16:Z46', 'A17:Z48')

# 2018
ranges6 <- c('A16:Z47', 'A16:Z44', 'A17:Z48', 'A16:Z46', 'A16:Z47', 'A17:Z47', 'A16:Z47',
             'A16:Z47', 'A17:Z47', 'A16:Z47', 'A16:Z46', 'A17:Z48')

# 2019
ranges7 <- c('A16:Z47', 'A16:Z44', 'A17:Z48', 'A16:Z46', 'A16:Z47', 'A17:Z47', 'A16:Z47',
             'A17:Z48', 'A16:Z46', 'A16:Z47', 'A17:Z47', 'A16:Z47')

years2 <- 2014:2019
ranges <- list(ranges2, ranges3, ranges4, ranges5, ranges6, ranges7)

for(year in years){
  if(year %in% years1){
    path <- paste0(inpath, "HistLength/", year, " Length Reports/")
    if(year == 2011){
      df <- read.hist.counts(path, range=ranges1[years1==year])
    }else{
      ndf <- read.hist.counts(path, range=ranges1[years1==year])
      df <- rbind(df, ndf)
    }
  }else{
    rangelist <- unlist(ranges[years2==year])
    for(m in months){
      path <- paste0(inpath,  paste(m, year), "/Length Reports/")
      ndf <- read.hist.counts(path, range=rangelist[months==m])
      df <- rbind(df, ndf)
      print(paste("!! got", year, m, "data !!"))
    }
  }
  print(paste("!! got", year, "data !!"))
}

df$Hour <- ifelse(df$Hour == "0", "12:00 AM", df$Hour)
# this will take a while
write.csv(df, "T:/Tableau/tableauODOTCounts/Datasources/ODOT_HourlyForTableau_LongVehicles.csv", row.names = FALSE)
