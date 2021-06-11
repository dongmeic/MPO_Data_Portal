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

# load functions
source("T:/GitHub/MPO_Data_Portal/TrafficCountData/RegionalCounts/Traffic_Counts_Functions.r")
inpath <- "T:/Data/COUNTS/Motorized Counts/Regional Traffic Counts Program/Central Lane Motorized Count Program/"
site.path <- paste0(inpath, "traffic_count_locations")
outpath <- "T:/Tableau/tableauRegionalCounts/Datasources"


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


loc <- readOGR(dsn = site.path, layer = "draft_locations", stringsAsFactors = FALSE)
head(loc) 


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