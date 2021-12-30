# This script was created by Dongmei Chen (dchen@lcog.org) to organize the monthly data
#  for the LTD transit dashboard based on LTDTransit.r
# (https://www.lcog.org/thempo/page/Transit-Ridership-Data) on July 21st, 2021

source('T:/DCProjects/GitHub/MPO_Data_Portal/TransitData/LTDTransit_Functions.r')

# after 2021 June
df <- read.csv("T:/Tableau/tableauTransit/Datasources/datacopy/MonthlyPassengerCounts.csv")
ndf <- get.MultiYearCounts(years = 2021:2021,
                           startmonth = 6,
                           endmonth = 10)

ndf <- rbind(df, ndf)
write.csv(ndf, "T:/Tableau/tableauTransit/Datasources/MonthlyPassengerCounts.csv", row.names = FALSE)

oldaggdata <- read.csv("T:/Tableau/tableauTransit/Datasources/datacopy/AggPassengerCounts.csv")
aggdata <-aggregate(x=ndf[c('ons', 'offs', 'load')], 
                    by=ndf[c("route", 'longitude', 'latitude', "month", "year")],
                    FUN=sum, na.rm=TRUE)

aggdata$MonthYear = ifelse(aggdata$month %in% c('January', 'February', 'March'), paste('October', aggdata$year - 1),
                           ifelse(aggdata$month %in% c('April', 'May', 'June', 'July', 'August', 'September'), paste('April', aggdata$year),
                                  paste('October', aggdata$year)))
aggdata <- rbind(oldaggdata, aggdata)
write.csv(aggdata, "T:/Tableau/tableauTransit/Datasources/AggPassengerCounts.csv", row.names = FALSE)

# before 2021 June
ptm <- proc.time()
ndf <- get.MultiYearCounts(complete = FALSE)
write.csv(ndf, "T:/Tableau/tableauTransit/Datasources/MonthlyPassengerCounts.csv", row.names = FALSE)
proc.time() - ptm

# aggregate monthly data
aggdata <-aggregate(x=ndf[c('ons', 'offs', 'load')], 
                    by=ndf[c("route", 'longitude', 'latitude', "month", "year")],
                    FUN=sum, na.rm=TRUE)

aggdata$MonthYear = ifelse(aggdata$month %in% c('January', 'February', 'March'), paste('October', aggdata$year - 1),
                           ifelse(aggdata$month %in% c('April', 'May', 'June', 'July', 'August', 'September'), paste('April', aggdata$year),
                                  paste('October', aggdata$year)))
aggdata$MonthYear = ifelse(aggdata$MonthYear %in% c('April 2021', 'October 2021'), 'October 2020', aggdata$MonthYear)

write.csv(aggdata, "T:/Tableau/tableauTransit/Datasources/AggPassengerCounts.csv", row.names = FALSE)
