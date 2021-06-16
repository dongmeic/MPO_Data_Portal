# This script was created to collect functions for LTD transit data
# By Dongmei Chen (dchen@lcog.org)
# On June 15th, 2021

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
