# This script was created to collect functions for traffic counts
# By Dongmei Chen (dchen@lcog.org)
# On February 18th, 2020


######################################## functions for the Spring 2022 data ################################
read_OneTable <- function(filename="1.0 LCOG_2021RoyalAve.xlsx",
                         boundCell1="B11:B11", boundCell2="T11:T11",
                         range1="A12:P60", range2="S12:AH60",
                         n=24,pattern=".0",
                         loc1range="B7:B7", loc2range="B8:B8",
                         OneBound=FALSE){
  
  if(OneBound){
    
    df <- readOneBound(boundCell=boundCell1, range=range1, 
                       n=n, pattern = pattern,
                       filename=filename)
  }else{
    
    df1 <- readOneBound(boundCell=boundCell1, range=range1,
                        n=n, pattern = pattern,
                        filename=filename)
    df2 <- readOneBound(boundCell=boundCell2, range=range2,
                        n=n, pattern = pattern,
                        filename=filename)
    df <- rbind(df1, df2)
    
  }
  
  df$Location_d <- rep(get_loc_info(loc1range=loc1range, loc2range=loc2range, 
                                    filename=filename), dim(df)[1])
  
  return(df)
  
}

read_AllTables <- function(n=24, pattern=" ",
                          boundCell1_list=boundCell1_list, 
                          boundCell2_list=boundCell2_list,
                          range1_list=range1_list, 
                          range2_list=range2_list,
                          loc1range_list=loc1range_list, 
                          loc2range_list=loc2range_list,
                          datafiles=datafiles, 
                          OneBoundSites=c(13, 14)){
  
  for(file in datafiles){
    k = which(datafiles==file)
    if(file == datafiles[1] & !(1 %in% OneBoundSites)){
      
      df <- read_OneTable(filename=file, n=n, pattern=pattern,
                         boundCell1=boundCell1_list[1], boundCell2=boundCell2_list[1],
                         range1=range1_list[1], range2=range2_list[1],
                         loc1range=loc1range_list[1], loc2range=loc2range_list[1])
      
    }else if(file == datafiles[1] & (1 %in% OneBoundSites)){
      
      df <- read_OneTable(filename=file, n=n, pattern=pattern,
                          boundCell1=boundCell1_list[1],
                          range1=range1_list[1], 
                          loc1range=loc1range_list[1], 
                          OneBound=TRUE)
      
    }else{
      if(k %in% OneBoundSites){
        ndf <- read_OneTable(filename=file, n=n, pattern=pattern,
                            boundCell1=boundCell1_list[k], 
                            range1=range1_list[k], 
                            loc1range=loc1range_list[k],
                            OneBound=TRUE)
      }else{
        ndf <- read_OneTable(filename=file, n=n, pattern=pattern,
                            boundCell1=boundCell1_list[k], boundCell2=boundCell2_list[k],
                            range1=range1_list[k], range2=range2_list[k],
                            loc1range=loc1range_list[k], loc2range=loc2range_list[k])
      }
      
      df <- rbind(df, ndf)
    }
    print(file)
  }
  return(df)
}


######################################## functions for the Summer 2021 data ################################
# the functions are updated for the November 2021 data
# need to set data.path, col_order, and the lists to set the parameters

reorganize.locations <- function(data, locdf){
  df <- find.closest.points(locdf, tolerance=0.0002)
  cols <- names(locdf)
  for(s in df$site2){
    k <- which(df$site2==s)
    data[data$Site==s,cols] <- locdf[locdf$Site==df$site1[k],cols]
  }
  return(data)
}

find.closest.points <- function(locdf, tolerance=0.00001, returnSites=TRUE)
{
  lon <- locdf$Longitude
  lat <- locdf$Latitude
  site <- locdf$Site
  n <- dim(locdf)[1]
  v1 <- vector()
  v2 <- vector()
  v3 <- vector()
  v4 <- vector()
  
  for(i in 1:n){
    for(j in 1:n){
      if(abs(lat[i]-lat[j])<=tolerance & abs(lon[i]-lon[j])<=tolerance){
        if(site[i]!=site[j]){
          v1 <- c(v1, site[i])
          v2 <- c(v2, site[j])
          if(!(site[i] %in% v2)){
            v3 <- c(v3, site[i])
            v4 <- c(v4, site[j])
          }
        }
      }
    }
  }
  if(returnSites){
    df <- data.frame(site1=v3, site2=v4)
  }else{
    df <- locdf[locdf$Site %in% c(v3, v4),]
  }
  return(df)
}

add_loc_info <- function(layer="locations2021", n=24,
                         colOrder = col_order, pattern=".0",
                         boundCell1_list=boundCell1_list, 
                         boundCell2_list=boundCell2_list,
                         range1_list=range1_list, 
                         range2_list=range2_list,
                         loc1range_list=loc1range_list, 
                         loc2range_list=loc2range_list,
                         datafiles=datafiles,
                         year=2021,
                         season="Summer"){
  
  loc <- readOGR(dsn=paste0(site.path, "/traffic_count_locations.gdb"), 
                 layer=layer, stringsAsFactors = FALSE)
  # n is the total number of existing sampling sites
  loc$Site <- loc$Site+n
  loc.lonlat <- spTransform(loc, CRS("+init=epsg:4326"))
  lonlat.df <- as.data.frame(loc.lonlat@coords)
  names(lonlat.df) <- c("Longitude", "Latitude")
  loc.df <- as.data.frame(loc)[,c("Site", "owner")]
  # colnames(loc.df)[2] <- "Owner"
  loc.df <- cbind(lonlat.df, loc.df)
  loc.df$YEAR <- year
  loc.df$SEASON <- season
  df <- readAllTables(boundCell1_list, boundCell2_list,
                      range1_list, range2_list,
                      n=n, pattern=pattern,
                      loc1range_list, loc2range_list,
                      datafiles)
  ndf <- merge(df, loc.df, by="Site")
  ndf <- ndf[,colOrder]
  return(ndf)
}

readAllTables <- function(n=24, pattern=".0",
                          boundCell1_list=boundCell1_list, 
                          boundCell2_list=boundCell2_list,
                          range1_list=range1_list, 
                          range2_list=range2_list,
                          loc1range_list=loc1range_list, 
                          loc2range_list=loc2range_list,
                          datafiles=datafiles){
  
  for(file in datafiles){
    k = which(datafiles==file)
    if(file == datafiles[1]){
      df <- readOneTable(filename=file, n=n, pattern=pattern,
                         boundCell1=boundCell1_list[k], boundCell2=boundCell2_list[k],
                         range1=range1_list[k], range2=range2_list[k],
                         loc1range=loc1range_list[k], loc2range=loc2range_list[k])
    }else{
      ndf <- readOneTable(filename=file, n=n, pattern=pattern,
                          boundCell1=boundCell1_list[k], boundCell2=boundCell2_list[k],
                          range1=range1_list[k], range2=range2_list[k],
                          loc1range=loc1range_list[k], loc2range=loc2range_list[k])
      df <- rbind(df, ndf)
    }
    print(file)
  }
  
  return(df)
}

readOneTable <- function(filename="1.0 LCOG_2021RoyalAve.xlsx",
                         boundCell1="B11:B11", boundCell2="T11:T11",
                         range1="A12:P60", range2="S12:AH60",
                         n=24,pattern=".0",
                         loc1range="B7:B7", loc2range="B8:B8"){
  
  if(filename == "11.0 LCOG_2021ASt.xlsx"){
    
    df <- readOneBound(boundCell=boundCell1, range=range1, 
                       n=n, pattern = pattern,
                       filename=filename)
  }else{
    
    df1 <- readOneBound(boundCell=boundCell1, range=range1,
                        n=n, pattern = pattern,
                        filename=filename)
    df2 <- readOneBound(boundCell=boundCell2, range=range2,
                        n=n, pattern = pattern,
                        filename=filename)
    df <- rbind(df1, df2)
    
  }
  
  df$Location_d <- rep(get_loc_info(loc1range=loc1range, loc2range=loc2range, 
                                    filename=filename), dim(df)[1])
  
  return(df)
  
}

get_loc_info <- function(loc1range="B7:B7", loc2range="B8:B8", 
                         filename="1.0 LCOG_2021RoyalAve.xlsx"){
  
  loc <- names(read_excel(paste0(data.path, "/", filename), sheet=1, range=loc1range))
  if(grepl('mph', loc)){
    locnm <- substr(loc,2,nchar(loc)-9)
  }else{
    locnm <- substr(loc,2,nchar(loc)-1)
  }
  
  loc2 <- names(read_excel(paste0(data.path, "/", filename), sheet=1, range=loc2range))
  cross_st <- substr(loc2,2,nchar(loc2)-1)
  
  if(locnm %in% c("S Bertelsen Rd", "Bailey Hill Rd", "Hayden Br Rd", "21st St", "Marcola Rd")){
    locnm <- paste(locnm, "at", cross_st)
  }
  
  return(locnm)
}

# n is the last total number of sites
readOneBound <- function(boundCell="B11:B11", range="A12:P60", n=24,
                         pattern=".0", filename="1.0 LCOG_2021RoyalAve.xlsx"){
  
  s <- as.numeric(str_split(filename, pattern)[[1]][1]) + n
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