# This script was created to organize LODES data
# LEHD - Longitudinal Employer-Household Dynamics
# LODES - LEHD Origin-Destination Employment Statistics
# By Dongmei Chen (dchen@lcog.org)
# On August 12th, 2022

library(sf)
library(readxl)
library(stringr)
inpath <- "T:/Tableau/tableauLODES/Datasources"
outpath <- "T:/DCProjects/DataPortal/Data/Output"

############################## functions ###########################################################

clean_text <- function(x){
  text1 <- str_replace_all(x, "\\[", "")
  text2 <- str_replace_all(text1, "\\]", "")
  text3 <- str_replace_all(text2, "'", "")
  return(text3)
}

getCity <- function(blockID){
  cities <- read.csv(paste0(outpath,"/or_city_blockIDs.csv"))
  cities$BlockIDs <- unlist(lapply(cities$BlockIDs, function(x) clean_text(x)))
  allblockIDs <- paste(cities$BlockIDs, collapse = ", ")
  # require cities and allblockIDs
  if(grepl(blockID, allblockIDs)){
    city <- cities[grepl(blockID, cities$BlockIDs), "City"]
    print(paste(blockID, city))
    return(city)
  }else{
    print(paste(blockID,"is not in cities"))
    return(NA)
  }
}

get_OD_data <- function(year=2019, export=TRUE){
  or_od <- read.csv(paste0(inpath, "/or_od_main_JT01_", year, ".csv"))
  or_od$w_geocode <- as.character(or_od$w_geocode)
  or_od$h_geocode <- as.character(or_od$h_geocode)
  
  # this will take a while (about 8 hours)
  ptm <- proc.time()
  or_od$w_city <- unlist(lapply(or_od$w_geocode, function(x) getCity(x)))
  proc.time() - ptm
  
  ptm <- proc.time()
  or_od$h_city <- unlist(lapply(or_od$h_geocode, function(x) getCity(x)))
  proc.time() - ptm
  
  or_od_s <- na.omit(or_od)
  aggdt <- aggregate(or_od_s$S000, by=list(or_od_s$h_city, or_od_s$w_city), 
                     FUN=sum)
  colnames(aggdt) <- c("HomeCity", "WorkCity", "TotalJobs")
  colnames(aggdt)[1] <- "City"
  
  # m - merge
  vars <- c("City", "Place", "Latitude", "Longitude")
  aggdt_m1 <- merge(aggdt, cities[, vars], by="City")
  colnames(aggdt_m1) <- c("HomeCity", "City", "TotalJobs", "HmPlace", "HmCityLat", "HmCityLon")
  aggdt_m2 <- merge(aggdt_m1, cities[, vars], by="City")
  colnames(aggdt_m2)[which(colnames(aggdt_m2) %in% vars)] <- c("WorkCity", "WkPlace", "WkCityLat", "WkCityLon")
  
  # f - final
  targetvars <- c("WorkCity", "WkPlace", "WkCityLat", "WkCityLon", "HomeCity" , 
                  "HmPlace", "HmCityLat", "HmCityLon", "TotalJobs")
  aggdt_f <- aggdt_m2[,targetvars]
  
  if(export){
    write.csv(aggdt_f, paste0(inpath, "/CityTable.csv"), row.names = FALSE)
  }
}


############################## Update with new data ################################################

# this will run for 8 hours or so
data <- get_OD_data()


############################## Test data in 2015 to match with the city table ######################
or_od_15 <- read.csv(paste0(inpath, "/or_od_main_JT01_2015.csv"))
or_od_15$w_geocode <- as.character(or_od_15$w_geocode)
or_od_15$h_geocode <- as.character(or_od_15$h_geocode)

test <- st_read(dsn = "T:/DCProjects/DataPortal/Data/LODES/LODES.gdb",
        layer = "center_test")
test_h <- st_read(dsn = "T:/DCProjects/DataPortal/Data/LODES/LODES.gdb",
                  layer = "center_test_h")

head(or_od_15[(or_od_15$w_geocode %in% test$BLOCKID10) & (or_od_15$h_geocode %in% test$BLOCKID10),])

citytable <- read_excel(paste0(inpath, "/CityTable.xlsx"))
citydf1 <- citytable[,c("WorkCity", "WkPlace", "WkCityLat", "WkCityLon")]
colnames(citydf1) <- c("City", "Place", "Latitude", "Longitude")
citydf2 <- citytable[,c("HomeCity", "HmPlace", "HmCityLat", "HmCityLon")]
colnames(citydf2) <- c("City", "Place", "Latitude", "Longitude")
citydf <- unique(rbind(citydf1, citydf2))
write.csv(citydf, paste0(outpath,"/or_city_coordinates.csv"), row.names = FALSE)

city <- st_read('T:/DCProjects/DataPortal/Data/city/city.shp')

head(or_od_15)

# this will take a while (about 4 hours)
ptm <- proc.time()
or_od_15$w_city <- unlist(lapply(or_od_15$w_geocode, function(x) getCity(x)))
proc.time() - ptm

ptm <- proc.time()
or_od_15$h_city <- unlist(lapply(or_od_15$h_geocode, function(x) getCity(x)))
proc.time() - ptm

or_od_15_s <- na.omit(or_od_15)
aggdt <- aggregate(or_od_15_s$S000, by=list(or_od_15_s$h_city, or_od_15_s$w_city), 
                FUN=sum)
colnames(aggdt) <- c("HomeCity", "WorkCity", "TotalJobs")
colnames(aggdt)[1] <- "City"
# m - merge
vars <- c("City", "Place", "Latitude", "Longitude")
aggdt_m1 <- merge(aggdt, cities[, vars], by="City")
colnames(aggdt_m1) <- c("HomeCity", "City", "TotalJobs", "HmPlace", "HmCityLat", "HmCityLon")
aggdt_m2 <- merge(aggdt_m1, cities[, vars ], by="City")
colnames(aggdt_m2)[which(colnames(aggdt_m2) %in% vars)] <- c("WorkCity", "WkPlace", "WkCityLat", "WkCityLon")
# f - final
aggdt_f <- aggdt_m2[,names(citytable)]
write.csv(aggdt_f, paste0(inpath, "/CityTable.csv"), row.names = FALSE)
