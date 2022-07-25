# This script was created to clean traffic counts data
# By Dongmei Chen (dchen@lcog.org)
# On February 13th, 2020
# The original spread sheets were created on February 12th, 2020

# load libraries
library(dplyr)
library(readxl)
library(writexl)
library(rgdal)
library(reshape2)
library(stringr)

# load functions and get some global settings
source("T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/RegionalCounts/Traffic_Counts_Functions.r")
inpath <- "T:/Data/COUNTS/Motorized Counts/Regional Traffic Counts Program/Central Lane Motorized Count Program/"
site.path <- paste0(inpath, "traffic_count_locations")
outpath <- "T:/Tableau/tableauRegionalCounts/Datasources/"

# read the last-updated data
data <- read.csv(paste0(outpath, "Traffic_Counts_Vehicles.csv"))
data$Date <- as.Date(data$Date, format = "%Y-%m-%d")
#colnames(data)[which(colnames(data) %in% c("owner", "YEAR", "SEASON","Location_d"))] <- c("Owner", "Year", "Season","Location")
#data$Owner <- ifelse(data$Owner=='Eug', 'EUG', ifelse(data$Owner=='Spr', 'SPR', data$Owner))
col_order <- colnames(data)

############################## Spring 2022 ################################
set <- "May2022"
data.path <- paste0(inpath, "data/", set, "/SiteData")
datafiles <- list.files(path = data.path, pattern = ".xlsx")

boundCell1_list <- c(rep("B11:B11", 24))
boundCell2_list <- c(rep("S11:S11", 3), rep("T11:T11", 2), rep("S11:S11", 1), rep("T11:T11", 18))

range1_list <- c(rep("A12:P60", 2),rep("A12:P59", 1),
                 rep("A12:P60", 3),rep("A12:P59", 1),
                 rep("A12:P60", 3),rep("A12:P58", 1),
                 rep("A12:P59", 7),rep("A12:P61", 1),
                 rep("A12:P62", 1),rep("A12:P60", 2), 
                 rep("A12:P59", 2))

range2_list <- c(rep("R12:AG60", 2),rep("R12:AG59", 1), 
                 rep("S12:AH60", 2),rep("R12:AG60", 1),
                 rep("S12:AH59", 1),rep("S12:AH60", 3),
                 rep("S12:AH58", 1),rep("S12:AH59", 1),
                 rep("NA", 2), rep("S12:AH59", 4),
                 rep("S12:AH61", 1),rep("S12:AH62", 1),
                 rep("S12:AH60", 2),rep("S12:AH59", 2))

loc1range_list <- c(rep("B7:B7", 24)) 
loc2range_list <- c(rep("B8:B8", 24))

df <- read_AllTables(boundCell1_list, boundCell2_list,
                    range1_list, range2_list,
                    n=54, pattern=" ",
                    loc1range_list, loc2range_list,
                    datafiles, 
                    OneBoundSites=c(13, 14))

new_data <- add_loc_info(layer="May2022",
                         n=54,
                         year=2022,
                         season="Spring",
                         data=df,
                         colOrder=col_order)

ndata <- rbind(data, new_data)
ndata$SEASON <- ifelse(ndata$SEASON == "FALL", "Fall", ndata$SEASON)

write.csv(ndata, paste0(outpath, "Traffic_Counts_Vehicles.csv"), row.names = FALSE)

aggdata <- aggregate(x=list(Counts = ndata$VehicleQty), 
          by=list(Season = paste(ndata$YEAR, ndata$SEASON), Location = ndata$Location_d, 
                  Site = ndata$Site, Longitude=ndata$Longitude, Latitude=ndata$Latitude), 
          FUN=sum, na.rm=TRUE)

aggdate <- aggregate(x=list(NDays = ndata$Date), 
                     by=list(Season = paste(ndata$YEAR, ndata$SEASON), Location = ndata$Location_d, 
                             Site = ndata$Site, Longitude=ndata$Longitude, Latitude=ndata$Latitude), 
                     FUN=function(x) length(unique(x)))

aggdata$NDays <- aggdate$NDays
aggdata$DailyCNT <- aggdata$Counts/aggdata$NDays
write.csv(aggdata, paste0(outpath, "Traffic_Counts_Site.csv"), 
          row.names = FALSE)

# add coordinates
path <- paste0(inpath, "data/", set)
locdf <- read_excel(paste0(path, "/LCOG  Counts May 2022 Report.xlsx"), 
           range = "A4:E28",
           col_names = FALSE)
colnames(locdf) <- c("Site ID", "Roadway", "Cross Street Ref", "Lat", "Long")
write.csv(locdf, paste0(path, "/coordinates.csv"), row.names = FALSE)

############################## Fall 2021 #################################
set <- "November2021"
data.path <- paste0(inpath, "data/", set, "/SiteData")

datafiles <- list.files(path = data.path, pattern = ".xlsx")

boundCell1_list <- c(rep("B6:B6", 1),rep("B9:B9", 1),rep("B10:B10", 1),
                     rep("B9:B9", 1),rep("B10:B10", 1),rep("B12:B12", 2),
                     rep("B11:B11", 3),rep("B12:B12", 1),rep("B11:B11", 5))
boundCell2_list <- c(rep("T6:T6", 1),rep("T9:T9", 1),rep("T10:T10", 1),
                     rep("T9:T9", 1),rep("T10:T10", 1),rep("T12:T12", 2),
                     rep("T11:T11", 3),rep("T12:T12", 1),rep("T11:T11", 1),
                     rep("S11:S11", 1),rep("T11:T11", 3))
range1_list <- c(rep("A7:P56", 1),rep("A10:P59", 1),rep("A11:P60", 1),
                 rep("A10:P81", 1),rep("A11:P58", 1),rep("A13:P84", 1),
                 rep("A13:P64", 1),rep("A12:P64", 1),rep("A12:P59", 2),
                 rep("A13:P60", 1),rep("A12:P59", 3),rep("A12:P60", 1),
                 rep("A12:P59", 1))
range2_list <- c(rep("S7:AH56", 1),rep("S10:AH59", 1),rep("S11:AH60", 1),
                 rep("S10:AH81", 1),rep("S11:AH58", 1),rep("S13:AH84", 1),
                 rep("S13:AH64", 1),rep("S12:AH64", 1),rep("S12:AH59", 2),
                 rep("S13:AH60", 1),rep("S12:AH59", 1),rep("R12:AG59", 1),
                 rep("S12:AH59", 1),rep("S12:AH60", 1),rep("S12:AH59", 1))
loc1range_list <- c(rep("B3:B3", 1),rep("B5:B5", 4),rep("B7:B7", 11)) 
loc2range_list <- c(rep("B4:B4", 1),rep("B6:B6", 4),rep("B8:B8", 11))

datafiles <- list.files(path = data.path, pattern = ".xlsx")
datafiles <- c(datafiles[1], datafiles[9:16], datafiles[2:8])

df <- readAllTables(boundCell1_list, boundCell2_list,
                    range1_list, range2_list,
                    n=n, pattern=pattern,
                    loc1range_list, loc2range_list,
                    datafiles)

new_data <- add_loc_info(layer="Nov2021")

ndata <- rbind(data, new_data)
dataDF <- unique(ndata[,c('Site','Latitude', 'Longitude','Location_d')])
res <- reorganize.locations(data=ndata,locdf=dataDF)

write.csv(res, paste0(outpath, "Traffic_Counts_Vehicles.csv"), row.names = FALSE)

############################## Summer 2021 ################################
# # review the locations
# tubelocs <- readOGR(dsn=paste0(site.path, "/traffic_count_locations.gdb"), layer="tube_locations_SpatialJoin")
# 
# # # read the summary table to get the locations
# sum.table <- read_xlsx(paste0(inpath, "data/June2021/LCOG_2021Data SummaryB.xlsx"), sheet=1)
# unique(sum.table$Roadway)
# rlidnms <- vector()
# missed <- vector()
# for(loc in unique(sum.table$Roadway)[2:15]){
#   if(loc %in% unique(tubelocs$rlidname)){
#     print(loc)
#     rlidnms <- append(rlidnms, loc)
#   }else{
#     missed <- append(missed, loc)
#   }
# }  
# # select the traffic locations from the tube locations
# # review the locations using the table information and tube locations
# # change "Danebo" to "N Danebo Ave", "S Bertensen" to "S Bertelsen Rd", "N 42nd Avenue" to "S 42nd St",
# # "S 42nd St" to "42nd St", "Virvinia Ave" to "Virginia Ave", "W11th" to "W 11th Ave"
# # select these locations from the tube locations: Laurelhurst Dr, 32nd St, and rlidnms
# sel_tubelocs <- tubelocs[tubelocs$rlidname %in% c("Laurelhurst Dr", "32nd St", rlidnms),]

set <- "June2021"
data.path <- paste0(inpath, "data/", set, "/SiteData")

datafiles <- list.files(path = data.path, pattern = ".xlsx")
n <- length(datafiles)
boundCell1_list <- rep("B11:B11", n)
boundCell2_list <- rep("T11:T11", n)
range1_list <- rep("A12:P60", n)
range2_list <- rep("S12:AH60", n) 
loc1range_list <- rep("B7:B7", n)
loc2range_list <- rep("B8:B8", n)

new_data <- add_loc_info(layer="locations2021", n=24,
                         colOrder = col_order, pattern=".0",
                         boundCell1_list=boundCell1_list, 
                         boundCell2_list=boundCell2_list,
                         range1_list=range1_list, 
                         range2_list=range2_list,
                         loc1range_list=loc1range_list, 
                         loc2range_list=loc2range_list)

ndata <- rbind(data, new_data)
write.csv(ndata, paste0(outpath, "Traffic_Counts_Vehicles.csv"), row.names = FALSE)

############################## Fall 2020 ################################
file <- paste0(inpath, "data/LCOG_2020Data Summary.xlsx")
sheet_names <- excel_sheets(path=file)
sheet_names <- grep(sheet_names, pattern = "Summary|Seasonal Factors", invert=TRUE, value = TRUE)
n <- length(sheet_names)
k=9 # start of numbering
siten <- k:(k+n-1)
rowlist <- list(c(3, 48, 50, 95),
             c(3, 50, 52, 99),
             c(3, 50, 52, 99),
             c(3, 51, 53, 101),
             c(3, 52, 54, 103),
             c(3, 52, 54, 103),
             c(3, 50, 52, 99),
             c(3, 50, 52, 99),
             c(3, 50, 52, 99),
             c(3, 50, 52, 98),
             c(3, 49, 52, 98),
             c(3, 50, 52, 99),
             c(3, 49, 51, 97),
             c(3, 49, 51, 97),
             c(3, 51, 53, 101),
             c(3, 50, 52, 99))

df <- read_table()
head(df)
sitedf <- data.frame(Site=siten, Name=sheet_names)


loc_df <- get_loc_df()
head(loc_df)
outdata <- merge(df, loc_df, by='Site')
outdata$YEAR <- rep(2020, dim(outdata)[1])

olddata <- read.csv(paste0(outpath, "Traffic_Counts_Oct2019_Vehicles.csv"),
                    stringsAsFactors = FALSE)
olddata <- olddata[colnames(outdata)]
newdata <- rbind(olddata, outdata)

# Modify the street names
newdata$Location_d <- ifelse(newdata$Location_d=="Coburg@FerryStBrdg", "Coburg Rd at Ferry Street Bridge",
                             ifelse(newdata$Location_d=="Coburg@oakway", "Coburg Rd at Oakway Rd",
                             ifelse(newdata$Location_d=="Coburg Rd@JeppensAcre", "Coburg Rd at Jeppesen Acres Rd",
                             ifelse(newdata$Location_d=="Marcola19th", "Marcola Rd at 19th",
                             ifelse(newdata$Location_d=="Marcola42nd", "Marcola Rd at 42nd",newdata$Location_d)))))

head(newdata)
tail(newdata)

write.csv(newdata, file = paste0(outpath, "Traffic_Counts_Vehicles.csv"), row.names = FALSE)

############################## Fall 2019 ################################
# initial data cleaning on the October 2019 data
# set data path
data.path <- paste0(inpath, "data/October2019/")

filenames <- c("42nd-Commercial", "Centennial-18th", "Mohawk-G St", "PioneerPrk-S", "PioneerPrk-N", 
               "QSt-105", "Centennial-Anderson", "Franklin-I5")
ranges <- c("A1:F95", "A3:F93", "A3:F95", "A2:F46", "A2:F46", "A3:F235", "A3:F91", "A3:F93")
sitenames <- c("Counter \r\nSite", "Count Site", "CounterSite", rep("Counter Site", 5))
ishour <- c(TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE)
# vc: vehicle classification
vcranges <- c("H3:T95", "H3:T93", "H3:T95", "H2:T46", "H2:T46", "H3:T235", "H3:T91", "H3:T93")

file.df <- data.frame(filename=filenames, range=ranges, sitename=sitenames, ishour=ishour, vcrange=vcranges, stringsAsFactors = FALSE)

# get all total counts
sitetc <- combine.traffic.counts(file.df)
# get all specific counts with vehicle classification  
sitevc <- combine.traffic.counts(file.df, type=TRUE)
# combine both
sites <- cbind(sitetc, sitevc)

head(sites)
# read site locations
loc <- readOGR(dsn = site.path, layer = "regional_count_locations", stringsAsFactors = FALSE)
head(loc)
# get longitude and latitude information
proj4string(loc)
loc.lonlat <- spTransform(loc, CRS("+init=epsg:4326"))
lonlat.df <- as.data.frame(loc.lonlat@coords)
names(lonlat.df) <- c("Longitude", "Latitude")
loc.df <- loc@data
loc.df <- cbind(lonlat.df, loc.df)
# merge site data with location data
sites <- merge(sites, loc.df, by = "Site")
# correct weekdays
sites$Day <- weekdays(sites$Date)
# create a column for velhicle types
write.csv(sites, file = paste0(outpath, "Traffic_Counts_Oct2019.csv"), row.names = FALSE)
write_xlsx(vehicles, paste0(outpath, "Traffic_Counts_Oct2019.xlsx"))

# reorganize vehicle types
vehicles <- melt(data = sites, id.vars = names(sites)[c(1:6, 20:25)], 
                 measure.vars = names(sites)[7:19])
names(vehicles)[which(names(vehicles) %in% c("variable", "value"))] <- c("VehicleType", "VehicleQty")
write.csv(vehicles, file = paste0(outpath, "Traffic_Counts_Oct2019_Vehicles.csv"), row.names = FALSE)
write_xlsx(vehicles, paste0(outpath, "Traffic_Counts_Oct2019_Vehicles.xlsx"))

dim(vehicles)