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


############################## Test data in 2015 to match with the city table ######################
or_od_15 <- read.csv(paste0(inpath, "/or_od_main_JT01_2015.csv"))
or_od_15$w_geocode <- as.character(or_od_15$w_geocode)
or_od_15$h_geocode <- as.character(or_od_15$h_geocode)

test <- st_read(dsn = "T:/DCProjects/DataPortal/Data/LODES/LODES.gdb",
        layer = "center_test")
test_h <- st_read(dsn = "T:/DCProjects/DataPortal/Data/LODES/LODES.gdb",
                  layer = "center_test_h")

head(or_od_15[(or_od_15$w_geocode %in% test$BLOCKID10) & (or_od_15$h_geocode %in% test_h$BLOCKID10),])

citytable <- read_excel(paste0(inpath, "/CityTable.xlsx"))
citydf1 <- citytable[,c("WorkCity", "WkPlace", "WkCityLat", "WkCityLon")]
colnames(citydf1) <- c("City", "Place", "Latitude", "Longitude")
citydf2 <- citytable[,c("HomeCity", "HmPlace", "HmCityLat", "HmCityLon")]
colnames(citydf2) <- c("City", "Place", "Latitude", "Longitude")
citydf <- unique(rbind(citydf1, citydf2))
write.csv(citydf, paste0(outpath,"/or_city_coordinates.csv"), row.names = FALSE)

city <- st_read('T:/DCProjects/DataPortal/Data/city/city.shp')

cities <- read.csv(paste0(outpath,"/or_city_blockIDs.csv"))
head(or_od_15)

clean_text <- function(x){
  text1 <- str_replace_all(x, "\\[", "")
  text2 <- str_replace_all(text1, "\\]", "")
  text3 <- str_replace_all(text2, "'", "")
  return(text3)
}

cities$BlockIDs <- unlist(lapply(cities$BlockIDs, function(x) clean_text(x)))

allblockIDs <- paste(cities$BlockIDs, collapse = ", ")

getCity <- function(blockID){
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

ptm <- proc.time()
or_od_15$w_city <- unlist(lapply(or_od_15$w_geocode, function(x) getCity(x)))
proc.time() - ptm

ptm <- proc.time()
or_od_15$h_city <- unlist(lapply(or_od_15$h_geocode, function(x) getCity(x)))
proc.time() - ptm

