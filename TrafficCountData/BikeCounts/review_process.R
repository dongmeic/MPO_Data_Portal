
# Created by DC on April 14th, 2023
# to review process in organizing bike counts

path <- 'T:/Tableau/tableauBikeCounts/Datasources'
inpath <- 'T:/Data/COUNTS/Nonmotorized Counts/Summary Tables/Bicycle'
data <- read.csv(paste0(path, '/Bicycle_HourlyForTableau.csv'))
countloc <- read.csv(paste0(path, '/CountLocationInformation.csv'))

pmloc <- unique(countloc[countloc$CountType=="Permanent", "Location"])
length(unique(data[data$Location == "AlderNorth18th" & data$Year == 2022,'Date']))
 
dat <- read.csv(paste0(inpath, '/BicycleDaily.csv'))
pmdat <- dat[dat$Location %in% pmloc,]
pmdat$Date <- as.Date(pmdat$Date)

