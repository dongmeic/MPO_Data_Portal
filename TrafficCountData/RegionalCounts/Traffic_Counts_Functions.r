# This script was created to collect functions for traffic counts
# By Dongmei Chen (dchen@lcog.org)
# On February 18th, 2020


######################################## functions for the Summer 2021 data ################################
# need to set data.path, col_order

add_loc_info <- function(layer="locations2021", n=24,
                         colOrder = col_order){
  loc <- readOGR(dsn=paste0(site.path, "/traffic_count_locations.gdb"), 
                 layer=layer, stringsAsFactors = FALSE)
  loc$Site <- loc$Site+n
  loc.lonlat <- spTransform(loc, CRS("+init=epsg:4326"))
  lonlat.df <- as.data.frame(loc.lonlat@coords)
  names(lonlat.df) <- c("Longitude", "Latitude")
  loc.df <- as.data.frame(loc)[,c("Site", "owner")]
  # colnames(loc.df)[2] <- "Owner"
  loc.df <- cbind(lonlat.df, loc.df)
  loc.df$YEAR <- "2021"
  loc.df$SEASON <- "Summer"
  df <- readAllTables()
  ndf <- merge(df, loc.df, by="Site")
  ndf <- ndf[,colOrder]
  return(ndf)
}

readAllTables <- function(){
  
  datafiles <- list.files(path = data.path, pattern = "LCOG_2021")
  for(file in datafiles){
    if(file == datafiles[1]){
      df <- readOneTable(filename = file)
    }else{
      ndf <- readOneTable(filename = file)
      df <- rbind(df, ndf)
    }
    print(file)
  }
  
  return(df)
}

readOneTable <- function(filename="1.0 LCOG_2021RoyalAve.xlsx"){
  
  if(filename == "11.0 LCOG_2021ASt.xlsx"){
    
    df <- readOneBound(boundCell="B11:B11", range="A12:P60",
                       filename=filename)
  }else{
    
    df1 <- readOneBound(boundCell="B11:B11", range="A12:P60",
                        filename=filename)
    df2 <- readOneBound(boundCell="T11:T11", range="S12:AH60",
                        filename=filename)
    df <- rbind(df1, df2)
    
  }
  
  df$Location_d <- rep(get_loc_info(filename), dim(df)[1])
  
  return(df)
  
}

get_loc_info <- function(filename="1.0 LCOG_2021RoyalAve.xlsx"){
  
  loc <- names(read_excel(paste0(data.path, "/", filename), sheet=1, range = "B7:B7"))
  locnm <- substr(loc,2,nchar(loc)-9)
  
  loc2 <- names(read_excel(paste0(data.path, "/", filename), sheet=1, range = "B8:B8"))
  cross_st <- substr(loc2,2,nchar(loc2)-1)
  
  if(locnm %in% c("S Bertelsen Rd", "Bailey Hill Rd", "Hayden Br Rd")){
    locnm <- paste(locnm, "at", cross_st)
  }
  
  return(locnm)
}

readOneBound <- function(boundCell="B11:B11", range="A12:P60",
                         filename="1.0 LCOG_2021RoyalAve.xlsx"){
  
  s <- as.numeric(str_split(filename, ".0 ")[[1]][1]) + 24
  b <- substring(names(read_excel(paste0(data.path, "/", filename), sheet=1, range = boundCell)), 1, 1)
  df <- read_xlsx(paste0(data.path, "/", filename), sheet=1, range = range) %>%  # TC: traffic counts
    mutate(Date = as.Date(Date, "%m/%d/%Y", tz = "America/Los_Angeles"), 
           Time = format(Time, "%I:%M %p")) %>%
    filter(!is.na(Total)) %>% 
    mutate(Day = weekdays(Date), Direction=rep(b, length(.$Date)), Site=rep(s, length(.$Date))) %>%
    melt(id.vars=c("Site","Direction","Date","Day","Time","Total")) %>% 
    rename(VehicleType = variable, VehicleQty = value) %>%
    mutate(VehicleType = gsub(" ", "", VehicleType))
  
  return(df)
}


######################################## functions for the Fall 2020 data ################################
# organize location data with site IDs
# make sure site.path is in the global setting
get_loc_df <- function(layer = "locations2020"){
  loc <- readOGR(dsn = site.path, layer = layer, 
                 stringsAsFactors = FALSE)
  # get longitude and latitude information
  loc.lonlat <- spTransform(loc, CRS("+init=epsg:4326"))
  lonlat.df <- as.data.frame(loc.lonlat@coords)
  names(lonlat.df) <- c("Longitude", "Latitude")
  loc.df <- loc@data
  loc.df <- cbind(lonlat.df, loc.df)
  return(loc.df)
}

# make sure siten, sheet_names, rowlist are available globally
read_table <- function(){
  
  for(sheetnm in sheet_names){
    print(sheetnm)
    
    if(sheetnm %in% c("Marcola19th", "Marcola42nd", "Olympic St",
                      "HarlowRd-W", "Harlow Rd-E")){
      b1 = "E"
      b2 = "W"
    }else{
      b1 = "N"
      b2 = "S"
    }
    
    if(sheetnm==sheet_names[1]){
      df = read_site()
    }else{
      ndf = read_site(sheetnm = sheetnm, 
                      rows=unlist(rowlist[which(sheet_names==sheetnm)]),
                      b1=b1, b2=b2)
      df = rbind(df, ndf)
    }
  }
  
  return(df)
}

read_site <- function(sheetnm="Coburg@FerryStBrdg", cols=c("A", "D", "E", "Q"), 
                      rows=c(3, 48, 50, 95), b1="N", b2="S"){
  tc <- read_tc(sheetnm = sheetnm, 
                tcrange1=paste0(cols[1],rows[1],":",cols[2],rows[2]),
                b1=b1,
                tcrange2=paste0(cols[1],rows[3],":",cols[2],rows[4]),
                b2=b2)
  
  vc <- read_vc(sheetnm = sheetnm, 
                tcrange1=paste0(cols[3],rows[1],":",cols[4],rows[2]),
                b1=b1,
                tcrange2=paste0(cols[3],rows[3],":",cols[4],rows[4]),
                b2=b2)
  
  df <- cbind(tc, vc) %>% 
    melt(id.vars=c("Site","Direction","Date","Day","Time","Total")) %>% 
    rename(VehicleType = variable, VehicleQty = value) %>%
    mutate(VehicleType = gsub(" ", "", VehicleType))
    
  return(df)
}

# vc - vehicle classification; b - bound/direction
read_vc <- function(sheetnm="Coburg@FerryStBrdg",
                    tcrange1="E3:Q48",
                    b1="N",
                    tcrange2="E50:Q95",
                    b2="S"){
  df1 <- read_vc_b(sheetnm = sheetnm, tcrange = tcrange1, b=b1)
  df2 <- read_vc_b(sheetnm = sheetnm, tcrange = tcrange2, tcrange2 = tcrange1, b=b2)
  df <- rbind(df1, df2)
  
  return(df)
}

read_vc_b <- function(sheetnm="Coburg@FerryStBrdg",
                      tcrange="E3:Q48",
                      tcrange2="E3:Q48",
                      b="N"){
  df <- as.data.frame(read_excel(file, sheet=sheetnm, range=tcrange, trim_ws = TRUE))
  if(b == "S" | b == "W"){
    df2 <- as.data.frame(read_excel(file, sheet=sheetnm, range=tcrange2, trim_ws = TRUE))
    colnames(df) <- colnames(df2)
  }
  return(df)
}

read_tc <- function(sheetnm="Coburg@FerryStBrdg",
                    tcrange1="A3:D48",
                    b1="N",
                    tcrange2="A50:D95",
                    b2="S"){
  df1 <- read_tc_b(sheetnm = sheetnm, tcrange = tcrange1, b=b1)
  df2 <- read_tc_b(sheetnm = sheetnm, tcrange = tcrange2, b=b2)
  df <- rbind(df1, df2)
  
  return(df)
}


# tc - traffic counts; b - bound/direction
# make sure siten and sheet_names are available globally
read_tc_b <- function(sheetnm="Coburg@FerryStBrdg",
                      tcrange="A3:D48",
                      b="N"){
  df <- as.data.frame(read_excel(file, sheet=sheetnm, range=tcrange, trim_ws = TRUE))
  if(b == "S" | b == "W"){
    colnames(df) <- c("Date","Day","Time","Total")
  }
  df <- df %>% 
    mutate(Site=rep(siten[which(sheet_names==sheetnm)], length(.$Date)),
           Direction=rep(b, length(.$Date)), Day=weekdays(Date),
           Time = as.character(strftime(df$Time, format='%I:%M %p', tz='utc'))) %>%
    select(Site,Direction,Date,Day,Time,Total) %>%
    mutate(Date=as.character(Date))
  return(df)
}
 
######################################## functions for the Fall 2019 data ################################
# combine regional traffic counts spreadsheets
# requires a dataframe for the settings
combine.traffic.counts <- function(file.df, type=FALSE){
  # create a file.df to collect table information
  for(filenm in file.df$filename){
    # make sure this is the first row
    print(filenm)
    if(filenm == '42nd-Commercial'){
      if(!type){
        ndf <- read.traffic.counts()
      }
      if(type){
        ndf <- read.traffic.counts(filenm, file.df$vcrange[1], type=TRUE)
      }
    }else{
      i <- which(file.df$filename == filenm)
      if(!type){
        df <- read.traffic.counts(filenm, file.df$range[i], file.df$sitename[i], file.df$ishour[i])
      }
      if(type){
        df <- read.traffic.counts(filenm, file.df$vcrange[i], type=TRUE)
      }
      df <- df[,names(ndf)]
      ndf <- rbind(ndf, df)
    }
  }
  return(ndf)
}

# read raw data spreadsheets for the regional traffic counts
read.traffic.counts <- function(filename="42nd-Commercial", range="A1:F95", sitename="Counter \r\nSite", ishour=TRUE, type=FALSE){
  library(readxl)
  inpath <- "T:/Data/COUNTS/Motorized Counts/Regional Traffic Counts Program/Central Lane Motorized Count Program/"
  data.path <- paste0(inpath, "data/October2019/")
  if(!type){
    if(ishour){
      df <- read_xlsx(paste0(data.path, filename, ".xlsx"), sheet=1, range = range) %>%  # TC: traffic counts
        mutate(Date = as.Date(Date, "%m/%d/%Y", tz = "America/Los_Angeles"), 
               Hour = format(Hour, "%I:%M %p")) %>%
        filter(!is.na(Total)) %>%
        rename(Site = sitename, Time = Hour)      
    }
    if(!ishour){
      df <- read_xlsx(paste0(data.path, filename, ".xlsx"), sheet=1, range = range) %>%
        mutate(Date = as.Date(Date, "%m/%d/%Y", tz = "America/Los_Angeles"), 
               Time = format(Time, "%I:%M %p")) %>%
        rename(Site = sitename)
    }
  }
  if(type){
    df <- read_xlsx(paste0(data.path, filename, ".xlsx"), sheet=1, range = range) %>%
      select_all(~gsub("\\s+|\\.", "", .))
  }
  return(df)
}