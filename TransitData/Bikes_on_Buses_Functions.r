# This script was created to collect functions for LTD bikes on buses data
# By Dongmei Chen (dchen@lcog.org)
# On June 16th, 2021


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

get.bikecounts <- function(m="October", yr=2011){
  if(yr %in% c(2017, 2019, 2020)){
    myr <- yr
  }else{
    myr <- paste(m, yr)
  }
  if(myr == "April 2013"){
    BikeCounts <- read_excel(paste0(bodarding.path, myr,".xlsx"), 
                             sheet = "bike counts", 
                             col_types = c("text", "text", "numeric", "text", 
                                           "text", "text", "text", "text", 
                                           "text", "numeric", "numeric", "numeric", 
                                           "numeric", "text", "numeric"))
    
    BikeCounts$date <- strptime(BikeCounts$date, "%m/%d/%Y")
    BikeCounts$trip_end <- strptime(BikeCounts$trip_end, "%H:%M")
    BikeCounts$time <- strptime(BikeCounts$time, "%H:%M")
    BikeCounts$route <- ifelse(BikeCounts$route == '01', '1', BikeCounts$route)
  }else{
    BikeCounts <- read_excel(paste0(bodarding.path, myr,".xlsx"), 
                             sheet = "bike counts", 
                             col_types = c("text", "date", "numeric", "date", 
                                           "date", "text", "text", "text", 
                                           "text", "numeric", "numeric", "numeric", 
                                           "numeric", "text", "numeric"))
  }
  
  stops.to.remove <- unique(grep('anx|arr|ann|escenter|garage', BikeCounts$stop, value = TRUE))
  # remove the stops with letters
  BikeCounts <- subset(BikeCounts, !(stop %in% stops.to.remove)) %>% select(-c(latitude, longitude))
  # convert EmX
  Emx <- c("101", "102", "103", "104", "105")
  BikeCounts$route <- ifelse(BikeCounts$route %in% Emx, "EmX", BikeCounts$route)
  # make the stop numbers to 5 digits
  zeros <- c("0", "00", "000", "0000")
  BikeCounts$stop <- ifelse(nchar(BikeCounts$stop) == 5, BikeCounts$stop,
                            paste0(zeros[(5 - nchar(BikeCounts$stop))], BikeCounts$stop))
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
  BikeCounts <- merge(BikeCounts, stops.df, by = 'stop')
  months <- c("April", "October")
  seasons <- c("Spring", "Fall")
  if(yr %in% c(2017, 2019, 2020)){
    BikeCounts$Season <- ifelse(as.character(month(BikeCounts$date, label=TRUE, abbr=FALSE)) == "April",
                                paste("Spring", yr), paste("Fall", yr))
  }else{
    BikeCounts$Season <- rep(paste(seasons[months==m], yr), dim(BikeCounts)[1])
  }
  BikeCounts$MonthYear <- paste(as.character(month(BikeCounts$date, label=TRUE, abbr=FALSE)),
                                year(BikeCounts$date))
  dates <- sort(unique(BikeCounts$date))
  routes <- unique(BikeCounts$route)
  for(i in 1:length(dates)){
    d <- dates[i]
    print(d)
    for(j in 1:length(routes)){
      r <- routes[j]
      BikeCounts$DailyRtQty[BikeCounts$date==d & BikeCounts$route==r] <- sum(BikeCounts$qty[BikeCounts$date==d & BikeCounts$route==r], na.rm = TRUE)
    }
    BikeCounts$DailyQty[BikeCounts$date==d] <- sum(BikeCounts$qty[BikeCounts$date==d], na.rm = TRUE)
  }
  return(BikeCounts)
}