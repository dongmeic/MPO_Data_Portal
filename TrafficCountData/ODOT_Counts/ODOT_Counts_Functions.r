# This script was created to collect functions for the cleaning of ODOT counts
# By Dongmei Chen (dchen@lcog.org)
# On April 9th, 2020

# load libraries
library(readxl)
library(writexl)
library(stringr)
library(dplyr)
library(reshape2)
library(stringr)
library(lubridate)

read_LR_files <- function(year=2021, keyw="Class Data"){
  lrfiles <- list.files(paste0(inpath, year, "/LengthReport"), 
                        pattern = paste0("^", keyw),
                        full.names = TRUE)
  for(file in lrfiles){
    print(file)
    if(file==lrfiles[1]){
      df <- read_LR_file(filename = file)
    }else{
      ndf <- read_LR_file(filename = file)
      df <- rbind(df, ndf)
    }
  }
  return(df)
}

read_LR_file <- function(filename=NULL){
  sheets <- excel_sheets(filename)
  selected_sheets <- grep(sheets, pattern = "EB|WB|SB|NB", value = TRUE)
  selected_sheets <- grep(selected_sheets, pattern = "_1_|_2_|_3_", 
                          value = TRUE, invert = TRUE)
  for(sheet in selected_sheets){
    print(sheet)
    if(sheet==selected_sheets[1]){
      df <- read_LR_sheet(filename=filename, sheetname=sheet)
    }else{
      ndf <- read_LR_sheet(filename=filename, sheetname=sheet)
      df <- rbind(df, ndf)
    }
  }
  return(df)
}

read_LR_sheet <- function(filename=NULL, sheetname=NULL){
  dt <- read_excel(filename, sheet = sheetname, skip=24, n_max=25) %>%
    select(c("Date", "Hour", "0 - 19", "20 - 34", "35 - 60", "61 - 149")) %>%
    mutate(Count=`35 - 60`+`61 - 149`) %>%
    select(c("Date", "Hour", "Count")) %>%
    mutate(StationID=str_split(sheetname, "_")[[1]][1], 
           Direction=str_split(sheetname, "_")[[1]][2],
           Day=substr(weekdays(Date), 1, 3),
           Date=format(Date, "%m/%d/%Y"),
           Hour=unlist(sapply(Hour, Covert.Hour.Format))) %>%
    select(StationID, Direction, Date, Day, Hour, Count)
  dt <- dt[!(dt$Hour %in% c("Total #:00 NA", "Total %:00 NA")),]
  dt$Direction <- unlist(lapply(dt$Direction, function(x) str_split(x, " ")[[1]][1]))
  return(dt)
}

Update.ODOT.LengthData <- function(month=NULL, 
                               year=NULL, multi_month=FALSE, 
                               months=NULL){
  old.counts <- read.csv("T:/Tableau/tableauODOTCounts/Datasources/ODOT_HourlyForTableau_LongVehicles.csv", stringsAsFactors = FALSE)
  if(multi_month){
    for(month in months){
      if(month == months[1]){
        ndf <- Get.LengthReport(year=year, month=month)
        print(paste("Got data from", month, year))
      }else{
        df <- Get.LengthReport(year=year, month=month)
        ndf <- rbind(ndf, df)
        print(paste("Got data from", month, year))
      }
    }
    new.counts <- rbind(old.counts, ndf)
  }else{
    counts.df <- Get.LengthReport(year=year, month=month)
    new.counts <- rbind(old.counts, counts.df)
  }
  write.csv(new.counts, "T:/Tableau/tableauODOTCounts/Datasources/ODOT_HourlyForTableau_LongVehicles.csv", row.names = FALSE)
}

Get.LengthReport <- function(year=2020, month='Nov'){
  filenm <- paste0(month, year, ".xlsx")
  file <- paste0(inpath, year, "/LengthReport/", filenm)
  df <- as.data.frame(read_excel(file))
  # select columns:COUNTY12, COUNTY2, COUNTY9, TwentyFourHour_Date, 
  # Test1, 35 - 60, 61 - 149
  df <- df[, c("COUNTY12", "COUNTY2", "COUNTY9", "TwentyFourHour_Date", "Test1",
               "35 - 60", "61 - 149")]
  colnames(df)[1:5] <- c("StationID", "County", "Direction", "Date", "Hour")
  #head(df)
  df$StationID
  df <- df[!unlist(sapply(df$StationID, function(x) excludedID(x))),]
  df[,"Count"] <- df[,"35 - 60"] + df[,"61 - 149"]
  
  df <- df %>% 
    filter(County == "Lane" & Direction %in% c("EB", "NB", "SB", "WB")) %>%
    mutate(Day=substr(weekdays(Date), 1, 3)) %>%
    select(StationID, Direction, Date, Day, Hour, Count) %>%
    mutate(StationID=unlist(sapply(StationID, Get.StationID)),
           Date=format(Date, "%m/%d/%Y"),
           Hour=unlist(sapply(Hour, Covert.Hour.Format)))
  return(df)
}

excludedID <- function(x){
  length(unlist(strsplit(x, "_"))) == 3
}

Get.StationID <- function(x){
  unlist(strsplit(x, "_"))[1]
}

Covert.Hour.Format <- function(x){
  x <- unlist(strsplit(x, " - "))[1]
  x <- unlist(strsplit(x, "(?=[A-Za-z])(?<=[0-9])|(?=[0-9])(?<=[A-Za-z])", 
                       perl=TRUE))
  return(paste(paste0(x[1], ":00"), toupper(x[2])))
}

Update.ODOT.Counts <- function(month_range="Oct-Dec", 
                               year=2020){
  old.counts <- read.csv("T:/Tableau/tableauODOTCounts/Datasources/ODOT_ALL_HourlyForTableaU.csv", 
                         stringsAsFactors = FALSE)
  counts.df <- read_by_stations(month_range=month_range, year=year)
  new.counts <- rbind(old.counts, counts.df)
  write.csv(new.counts, "T:/Tableau/tableauODOTCounts/Datasources/ODOT_ALL_HourlyForTableau.csv", 
            row.names = FALSE)
}

read_by_stations <- function(month_range="Oct-Dec", 
                             year=2020){
  files <- list.files(paste0(inpath, year, "/", month_range), 
                      pattern = "^VOLUME|Volume",
                      full.names = FALSE)
  files <- grep(files, pattern = "EB|WB|SB|NB", value = TRUE)
  
  for(filenm in files){
    if(filenm == files[1]){
      df = read_by_month_range(year=year, month_range=month_range,
                               filenm=filenm)
    }else{
      ndf = read_by_month_range(year=year, month_range=month_range,
                                filenm=filenm)
      df = rbind(df, ndf)
    }
  }
  return(df)
}

read_by_month_range <- function(year=2020, month_range="Oct-Dec",
                                filenm="VOLUME_20004_EB_20201001.xlsx"){
  
  #year <- as.numeric(substr(unlist(strsplit(filenm, "_"))[4], 1, 4))
  file <- paste0(inpath, year, "/", month_range, "/", filenm)
  sheet_names <- excel_sheets(path=file)
  for(sheetnm in sheet_names){
    if(sheetnm==sheet_names[1]){
      df = read_by_month(month_range=month_range,
                         filenm=filenm,
                         sheetnm=sheetnm)
    }else{
      ndf = read_by_month(month_range=month_range,
                          filenm=filenm,
                          sheetnm=sheetnm)
      df = rbind(df, ndf)
    }
  }
  return(df)
}

read_by_month <- function(month_range="Oct-Dec",
                          filenm="VOLUME_20004_EB_20201001.xlsx",
                          sheetnm="10_2020"){

  file <- paste0(inpath, year, "/", month_range, "/", filenm)
  month <- as.numeric(unlist(strsplit(sheetnm, "_"))[1])
  year <- as.numeric(unlist(strsplit(sheetnm, "_"))[2])
  range=paste0("A10:AA", (10+days.in.month(month=month, year=year)))
  df <- as.data.frame(read_excel(file, 
                                 sheet=sheetnm, 
                                 range = range)) %>%
    filter(`QC Status` == "Accepted") %>%
    select(-c("QC Status", "TOTAL"))
  if(dim(df)[1] != 0){
    df[1] <- unlist(lapply(df[1], function(x) paste0(month, "/", x, "/", year)))
    colnames(df)[1:25] <- c("Date", seq(0, 23, by=1))
    
    df <- df %>% 
      mutate(Date = as.Date(Date, format = "%m/%d/%Y")) %>% 
      mutate(Day = substr(weekdays(Date), 1, 3)) %>%
      melt(id.vars = c("Date", "Day")) %>% 
      rename(Hour = variable, Count = value) %>%
      mutate(Direction = rep(unlist(strsplit(filenm, "_"))[3],length(.$Date)), 
             StationID = rep(unlist(strsplit(filenm, "_"))[2],length(.$Date))) %>%
      select(StationID, Direction, Date, Day, Hour, Count) %>%
      mutate(Hour = unlist(lapply(as.numeric(Hour), convert.hour))) %>%
      mutate(Date = format(Date, "%m/%d%/%Y"))
  }
  return(df)
}

days.in.month <- function(month, year){
  if(month %in% c(4, 6, 9, 11)){
    days = 30
  }else if(month == 2){
    if(is.leap.year(year)){
      days = 29
    }else{
      days = 28
    }
  }else{
    days = 31
  }
  return(days)
}

#If a year is divisible by 4, 100 and 400, it's a leap year.
#If a year is divisible by 4 and 100 but not divisible by 400, it's not a leap year.
#If a year is divisible by 4 but not divisible by 100, it's a leap year.

is.leap.year <- function(year){
  if((year %% 4) == 0 & (year %% 100) == 0){
    if((year %% 400) == 0){
      TRUE
    }else{
      FALSE
    }
  }else if((year %% 4) == 0 & (year %% 100) != 0){
    TRUE
  }else{
    FALSE
  }
}

convert.hour <- function(hour){
  if(hour %in% c(1:11)){
    hour = paste0(hour, ":00 AM")
  }else if(hour %in% c(13:23)){
    hour = paste0(hour - 12, ":00 PM")
  }else if(hour %in% c(12, 24, 0)){
    if(hour == 12){
      hour = paste0(hour, ":00 PM")
    }else{
      hour = paste0("12:00 AM")
    }
  }
  return(hour)
}

getpath <- function(path, year, month){
  paste0(path, year, "/", month, "/")
}

# read ODOT counts spreadsheets
# requires inputs path and range
# LR - length report
# HD - historical data
read.odot.sheet <- function(path, stationID, sheetnm, range, length="35-61", LR=FALSE, HD=FALSE){
  if(LR){
    # require information on year, month, length
    if(HD){
      file <- paste0(path, length, "_", stationID, ".xls")
    }else{
      file <- paste0(path, length, "_ft_", stationID, ".xls")
    }
  }else{
    file <- paste0(path, stationID, ".xls")
  }
  
  df <- read_excel(file, sheet=sheetnm, range = range)
  if(colnames(df)[1] == "No Data"){
    print("No data in this table!!")
    df <- data.frame(StationID=character(), Direction=character(), Date=character(),
                     Day=character(), Hour=character(), Count=character())
  }else{
    df <- df %>%
      melt(id.vars = c("Date", "Day")) %>% 
      rename(Hour = variable, Count = value) %>%
      mutate(Direction = rep(sheetnm,length(.$Date)), StationID = rep(stationID,length(.$Date))) %>%
      select(StationID, Direction, Date, Day, Hour, Count) %>%
      mutate(Hour = unlist(sapply(as.numeric(Hour), convert.hour))) %>%
      mutate(Date = format(Date, "%m/%d/%Y"))
  }
  return(df)
}

# read ODOT counts in the station
# LR is short for length report
# HD is short for historical data
read.odot.sheets <- function(path, length="35-61", stationID, range, LR=TRUE, HD=FALSE){
  if(LR){
    if(HD){
      file <- paste0(path, length, "_", stationID, ".xls")
    }else{
      file <- paste0(path, length, "_ft_", stationID, ".xls")
    }
  }else{
    file <- paste0(path, stationID, ".xls")
  }
  sheets <- excel_sheets(file)
  sheets <- sheets[sheets %in% c("WB", "EB", "SB", "NB")]
  df1 <- read.odot.sheet(path, stationID, sheets[1], range, length, LR=LR)
  df2 <- read.odot.sheet(path, stationID, sheets[2], range, length, LR=LR)
  df <- rbind(df1, df2)
  return(df)
}

read.odot.station <- function(path, stationID, range, LR=FALSE){
  if(LR){
    # require information on year, month, length
    for(length in c("35-61", "61-150")){
      if(length == "35-61"){
        df <- read.odot.sheets(path, length, stationID, range, LR = LR)
      }else{ 
        ndf <- read.odot.sheets(path, length, stationID, range, LR = LR)
        df <- rbind(df, ndf)
      }
    }
    
  }else{
    df <- read.odot.sheets(path, length, stationID, range, LR = LR)
  }
  return(df)
}

# read all ODOT counts
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

read.odot.counts <- function(path, range, LR=FALSE){
  files <- str_remove(list.files(path), ".xls")
  if(LR){
    stations <- files[sapply(files, str_length) > 5]
    stations <- stations[grepl("35-61|61-150", stations)]
    for(station in stations){
        if(station == stations[1]){
          ndf <- read.odot.station(path, substrRight(station, 5), range, LR=LR)
        }else{
          df <- read.odot.station(path, substrRight(station, 5), range, LR=LR)
          ndf <- rbind(ndf, df)
        }
      print(paste(station, "added!"))
    }
    
  }else{
    stations <- files[sapply(files, str_length)==5]
    for(station in stations){
      if(station == stations[1]){
        ndf <- read.odot.station(path, station, range)
      }else{
        df <- read.odot.station(path, station, range)
        ndf <- rbind(ndf, df)
      }
      print(paste(station, "added!"))
    }
  }
  return(ndf)
}

read.odot.table <- function(path, m, year){
  df <- read_xlsx(paste0(path, "HourlyForTableau_", m, year, ".xlsx")) %>%
    mutate(Date = format(date(Date), "%m/%d%/%Y"), 
           Hour = unlist(sapply(hour(Hour), convert.hour)))
  return(df)
}

read.hist.LR.sheets <- function(path, length, stationID, range, LR=TRUE, HD=TRUE){
  file <- paste0(path, length, "_", stationID, ".xls")
  sheets <- excel_sheets(file)
  sheets <- sheets[sheets %in% c("WB", "EB", "SB", "NB")]
  df1 <- read.odot.sheet(path, stationID, sheets[1], range, length, LR=LR, HD=HD)
  df2 <- read.odot.sheet(path, stationID, sheets[2], range, length, LR=LR, HD=HD)
  df <- rbind(df1, df2)
  return(df)
}

read.hist.LR <- function(path, stationID, range){
  for(length in c("35-61", "61-150")){
    if(length == "35-61"){
      df <- read.hist.LR.sheets(path, length, stationID, range)
    }else{ 
      ndf <- read.hist.LR.sheets(path, length, stationID, range)
      df <- rbind(df, ndf)
    }
  }
  return(df)
}

read.hist.counts <- function(path, range){
  files <- str_remove(list.files(path), ".xls")
  stations <- files[grepl("35-61|61-150", files)]
  for(station in stations){
    if(station == stations[1]){
      ndf <- read.hist.LR(path, substrRight(station, 5), range)
    }else{
      df <- read.hist.LR(path, substrRight(station, 5), range)
      ndf <- rbind(ndf, df)
    }
    print(paste(station, "added!"))
  }
  return(ndf)
}

# read length reports differently from March 2020
get.length.reports <- function(path){
  dat <- read_excel(paste0(path, "LengthReport.xls"))
  df <- cbind(dat[-1,1], dat[-1,2]) %>% 
    setNames(c("Direction", "DateTime"))  %>% 
    mutate(Date = sapply(DateTime, function(x) strsplit(x, " ")[[1]][1]),
           Hour = sapply(DateTime, function(x) paste(strsplit(x, " ")[[1]][2], strsplit(x, " ")[[1]][3]))) %>% 
    mutate(Date=as.Date(Date, format="%m/%d/%Y")) %>% 
    mutate(Day=weekdays(Date, abbreviate = TRUE)) %>% 
    mutate(Date = format(Date, "%m/%d%/%Y")) %>%
    select(-DateTime)
  
  stations <- names(dat)[grepl("200|220", names(dat))]
  for(i in 1:length(stations)){
    df$StationID <- rep(stations[i], dim(df)[1])
    ndf1 <- cbind(df, dat[-1,5+4*(i-1)])
    names(ndf1)[length(names(ndf1))] <- "Count"
    ndf2 <- cbind(df, dat[-1,6+4*(i-1)])
    names(ndf2)[length(names(ndf2))] <- "Count"
    if(i==1){
      ndf <- rbind(ndf1, ndf2)
    }else{
      ndf <- rbind(ndf, ndf1, ndf2)
    }
    print(paste("Get data from", stations[i]))
  }
  
  ndf <- ndf[,c("StationID", "Direction", "Date", "Day", "Hour", "Count")]
  return(ndf)
}


# add new data to the old table
Update.ODOT.Counts.By.Month <- function(path, range, year, month, LR=FALSE, HD=FALSE){
  path <- getpath(path, year, month)
  if(LR){
    old.LR <- read.csv("T:/Tableau/tableauODOTCounts/Datasources/ODOT_HourlyForTableaU_LongVehicles.csv", stringsAsFactors = FALSE)
    if(HD){
      LR.df <- read.odot.counts(path, range, LR = LR)
    }else{
      LR.df <- get.length.reports(path)
    }
    new.LR <- rbind(old.LR, LR.df)
    write.csv(new.LR, "T:/Tableau/tableauODOTCounts/Datasources/ODOT_HourlyForTableaU_LongVehicles.csv", row.names = FALSE)
  }else{
    old.counts <- read.csv("T:/Tableau/tableauODOTCounts/Datasources/ODOT_ALL_HourlyForTableaU.csv", stringsAsFactors = FALSE)
    counts.df <- read.odot.counts(path, range)
    new.counts <- rbind(old.counts, counts.df)
    write.csv(new.counts, "T:/Tableau/tableauODOTCounts/Datasources/ODOT_ALL_HourlyForTableau.csv", row.names = FALSE)
  }
}
