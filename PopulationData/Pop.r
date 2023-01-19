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

############################## check source data ###############################
# need to review this data first
raw1 <- read_excel("L:/Research&Analysis/Data/Population/Historical Population/Historical Population.xls",
                   skip=1)
colnames(raw1)[c(1, 4, 5)] <- c("YEAR", "LANE Total", "LANE UNINCOR")
raw <- read_excel("L:/Research&Analysis/Data/Population/Historical Population/Historical Population.xls",
                  skip=2, n_max=71)
colnames(raw) <- colnames(raw1)
raw <- raw[!is.na(raw$YEAR), ]

############################## adjust pop data ###############################
pop[pop$YEAR %in% 2010:2021 & pop$GEOGRAPHY=="United States", "POPULATION"] <- raw[raw$YEAR %in% 2010:2021, "UNITED STATES"]
pop[pop$YEAR %in% 2010:2021 & pop$GEOGRAPHY=="Oregon", "POPULATION"] <- raw[raw$YEAR %in% 2010:2021, "OREGON"]

############################## adding new data ###############################
newdata <- raw[raw$YEAR == 2022,]
dt <- data.frame(YEAR=rep(2022, 16),
           DATE= rep(as.POSIXct("2022-04-01", 
                                 format = "%Y-%m-%d",
                                 tz="UTC"), 16),
           GEOGRAPHY=rep(unique(pop$GEOGRAPHY), 1),
           POPULATION=t(newdata[,-1])[,1]) #c(t(newdata[,-1])[,1],t(newdata[,-1])[,2])

year <- 2022
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

dt$GeoNum <- rep(1:16, 1)

newpop <- rbind(pop, dt)
newpop$DATE <- as.Date(newpop$DATE)
write_xlsx(list(PopulationRaw=newpop), path = filename,
           col_names = TRUE)

# write_xlsx(list(PopulationRaw=pop), path = filename,
#            col_names = TRUE)