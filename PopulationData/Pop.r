# This script was created to update population data since 2020
# By Dongmei Chen (dchen@lcog.org)
# On July 19th, 2022

library(readxl)
library(writexl)
library(rjson)
library(tidycensus)

keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
#census_api_key(rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$acs$key, install = TRUE)
census_api_key(rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$acs$key, overwrite=TRUE)

filename <- "T:/Tableau/tableauPop/Datasources/HistoricalPopulation.xlsx"
pop <- read_excel(filename)
head(pop)
colnames(pop)
unique(pop$GEOGRAPHY)

############################## update US population ###############################
update_US_pop <- function(years = c(2011:2019, 2021)){
  res <- vector("list",length(years))
  names(res) <- years
  
  for (y in years){
    # download data
    ld <- as.data.frame(get_acs(year = y,
                                geography='us',
                                survey='acs1',
                                variables = 'B01003_001E'))
    # reshape long to wide
    ld2 <- reshape(ld,
                   idvar="GEOID",
                   timevar="variable",
                   direction="wide",
                   drop=c("NAME","moe"))
    # insert into list and add in year
    res[[y]] <- ld2
    res[[y]]$year <- y
  }
  
  # Combining the data frames together for final analysis
  combo <- do.call("rbind",res)
  return(combo[,-which(names(combo)=="GEOID")])
}

uspop <- update_US_pop()

pop20 <- get_decennial(geography = "us",
                       year = 2020,
                       variables = 'P1_001N')

pop10 <- get_decennial(geography = "us",
                       year = 2010,
                       variables = 'P001001')

for(year in 2010:2021){
  if(year == 2010){
    pop[pop$YEAR==year & pop$GEOGRAPHY=="United States", "POPULATION"] <- pop10$value
  }else if(year == 2020){
    pop[pop$YEAR==year & pop$GEOGRAPHY=="United States", "POPULATION"] <- pop20$value
  }else{
    pop[pop$YEAR==year & pop$GEOGRAPHY=="United States", "POPULATION"] <- uspop[uspop$year==year, "estimate.B01003_001"]
  }
}

############################## adding new data ###############################
# need to review this data first
raw1 <- read_excel("L:/Research&Analysis/Data/Population/Historical Population/Historical Population.xls",
                   skip=1)
colnames(raw1)[c(1, 4, 5)] <- c("YEAR", "LANE Total", "LANE UNINCOR")
raw <- read_excel("L:/Research&Analysis/Data/Population/Historical Population/Historical Population.xls",
                  skip=2, n_max=71)
colnames(raw) <- colnames(raw1)
raw <- raw[!is.na(raw$YEAR), ]
newdata <- raw[raw$YEAR %in% c(2020, 2021),]
dt <- data.frame(YEAR=c(rep(2020, 16), rep(2021, 16)),
           DATE=c(rep(as.POSIXct("2020-04-01", 
                                 format = "%Y-%m-%d",
                                 tz="UTC"), 16),
                  rep(as.POSIXct("2021-04-01", 
                                 format = "%Y-%m-%d",
                                 tz="UTC"), 16)),
           GEOGRAPHY=rep(unique(pop$GEOGRAPHY), 2),
           POPULATION=c(t(newdata[,-1])[,1],t(newdata[,-1])[,2]))


year <- 2021
dt[dt$YEAR==year,"PERCENTAGE OF LANE COUNTY"] <- ifelse(!(dt[dt$YEAR==year,]$GEOGRAPHY %in% c("United States",
                                                                                              "Oregon", 
                                                                                              "Lane County (Total)")),
                                                        dt[dt$YEAR==year,]$POPULATION/dt[dt$YEAR == year & 
                                                                                           dt$GEOGRAPHY=="Lane County (Total)",
                                                                                         "POPULATION"]*100, NA)

dt[dt$YEAR==year,"5-YEAR AVG. ANNUAL GROWTH RATE"] <- ((dt[dt$YEAR == year, 
                                                           "POPULATION"]/pop[pop$YEAR == year-5, 
                                                                             "POPULATION"])^(1/(dt[dt$YEAR == year, 
                                                                                                   "POPULATION"] - pop[pop$YEAR == year-5, 
                                                                                                                       "POPULATION"])))-1

dt$GeoNum <- rep(1:16, 2)

newpop <- rbind(pop, dt)
newpop$DATE <- as.Date(newpop$DATE)
write_xlsx(list(PopulationRaw=newpop), path = filename,
           col_names = TRUE)