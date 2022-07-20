# This script was created to update population data since 2020
# By Dongmei Chen (dchen@lcog.org)
# On July 19th, 2022

library(readxl)
library(writexl)

filename <- "T:/Tableau/tableauPop/Datasources/HistoricalPopulation.xlsx"
pop <- read_excel(filename)
head(pop)
colnames(pop)
unique(pop$GEOGRAPHY)

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

dt[dt$YEAR==2020,"PERCENTAGE OF LANE COUNTY"] <- ifelse(!(dt[dt$YEAR==2020,]$GEOGRAPHY %in% c("United States",
                                                                              "Oregon", 
                                                                              "Lane County (Total)")),
                                                          dt[dt$YEAR==2020,]$POPULATION/dt[dt$YEAR == 2020 & 
                                                                             dt$GEOGRAPHY=="Lane County (Total)",
                                                                           "POPULATION"]*100, NA)


dt[dt$YEAR==2021,"PERCENTAGE OF LANE COUNTY"] <- ifelse(!(dt[dt$YEAR==2021,]$GEOGRAPHY %in% c("United States",
                                                                                              "Oregon", 
                                                                                              "Lane County (Total)")),
                                                        dt[dt$YEAR==2021,]$POPULATION/dt[dt$YEAR == 2021 & 
                                                                                           dt$GEOGRAPHY=="Lane County (Total)",
                                                                                         "POPULATION"]*100, NA)

dt[dt$YEAR==2020,"5-YEAR AVG. ANNUAL GROWTH RATE"] <- ((dt[dt$YEAR == 2020, 
                                                           "POPULATION"]/pop[pop$YEAR == 2020-5, 
                                                                             "POPULATION"])^(1/(dt[dt$YEAR == 2020, 
                                                                                                   "POPULATION"] - pop[pop$YEAR == 2020-5, 
                                                                                                                       "POPULATION"])))-1


dt[dt$YEAR==2021,"5-YEAR AVG. ANNUAL GROWTH RATE"] <- ((dt[dt$YEAR == 2021, 
                                                           "POPULATION"]/pop[pop$YEAR == 2021-5, 
                                                                             "POPULATION"])^(1/(dt[dt$YEAR == 2021, 
                                                                                                   "POPULATION"] - pop[pop$YEAR == 2021-5, 
                                                                                                                       "POPULATION"])))-1

dt$GeoNum <- rep(1:16, 2)

newpop <- rbind(pop, dt)
newpop$DATE <- as.Date(newpop$DATE)
write_xlsx(list(PopulationRaw=newpop), path = filename,
           col_names = TRUE)
