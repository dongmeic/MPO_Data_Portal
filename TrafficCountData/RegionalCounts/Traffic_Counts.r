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

############################## Fall 2021 ################################
set <- "November2021"
data.path <- paste0(inpath, "data/", set, "/SiteData")

datafiles <- list.files(path = data.path, pattern = ".xlsx")
n <- length(datafiles)




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