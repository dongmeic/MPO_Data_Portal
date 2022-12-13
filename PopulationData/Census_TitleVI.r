# This script was created by Dongmei Chen (dchen@lcog.org) 
# to calculate data for the TitleVI dashboard 
# (https://thempo.org/958/Socio-Economic-Data) 
# on May 5th, 2020

# load libraries
library(readxl)
library(rgdal)
library(dplyr)
library(rjson)
library(tidycensus)
library(sf)

############################## Download data ##############################

# update year information here
yrrange <- "20172021"
year <- 2021
yr = 21

# create a new folder if not exist
mainDir <- "T:/Data/CENSUS"
subDir <- sprintf("ACS%s.", yrrange)
# prints an warning if exists
dir.create(file.path(mainDir, subDir))
newDir <- "TitleVI"
dir.create(file.path(mainDir, subDir, newDir))
# set the work directory for downloads
setwd(file.path(mainDir, subDir))
#### manual download 5-yr data ####
# extract the downloaded files
zipfiles <- list.files(path = ".", pattern = "zip", all.files = TRUE)
for(zipfile in zipfiles){
  unzip(zipfile = zipfile, exdir = paste0(getwd(), "/", newDir))
}

# repeat the process for the 1-year data
subDir1yr <- sprintf("ACS%d.", year)
path1yr <- file.path(mainDir, subDir1yr)
dir.create(path1yr)
#### manual download 1-yr data #### 
# the geography is urbanized area instead 
# then extract the files
zipfiles <- list.files(path = path1yr, pattern = "zip", all.files = TRUE)
for(zipfile in zipfiles){
  unzip(zipfile = paste0(path1yr, "/", zipfile), exdir = path1yr)
}

# In 2020, move the 1-year table B18101 from the 5-year folder to 
# the 1-year folder, since only 1Y data available

# # alternatively, use API to access Census.Gov
# keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
# census_api_key(rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$acs$key, 
#                install = TRUE, overwrite=TRUE)

# titlevi <- read.csv("T:/Tableau/tableauTitleVI/Datasources/MPO_summary.csv")
# vars <- c("BlkGrp10", "PopNI5Disa", "PopEld", "HHPoor",  
#           "Pop5yrLEP", "PopMinor", "PopWFUnEmp", "HH0car")
# data <- titlevi[, vars]
# 
# write.csv(data, 
#           paste0("T:/Tableau/tableauTitleVI/Datasources/map_data.csv"), 
#           row.names = F)

############################## Read data ##############################
# set-ups
outpath <- "T:/Tableau/tableauTitleVI/Datasources"
tablenm <- "B01001"

# functions
# stren - string end number in the GeoID
readtable <- function(filenm.start=sprintf("ACSDT5Y%d.", year), 
                      tablenm="B01001", 
                      ext="-Data",
                      stren=21){
  mainDir <- "T:/Data/CENSUS"
  subDir <- sprintf("ACS%s.", yrrange)
  newDir <- "TitleVI"
  inpath <- file.path(mainDir, subDir, newDir)
  
  filenm <- list.files(path = inpath, 
                       pattern = paste0(filenm.start,
                                        tablenm,
                                        ext))
  
  dat <- read.csv(paste0(inpath, "/", filenm), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-which(names(dat) %in% c("GEO_ID", "NAME", "X",
                                            grep("EA|MA", colnames(dat), value = TRUE)))]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,which(names(dat)=="GEO_ID")]), as.data.frame(dat2))
  colnames(dat)[1] <- "GEO_ID"
  dat$GEO_ID <- substr(dat$GEO_ID, 10, stren)
  return(dat)
}

read1yrtable <- function(yr = 18, tablenm = "B01001", 
                         ext="-Data"){ #ext="_data_with_overlays_"
  inpath <- paste0("T:/Data/CENSUS/ACS20", yr)
  filenm <- list.files(path = inpath, 
                       pattern = paste0(yr,".",tablenm,
                                        ext))
  dat <- read.csv(paste0(inpath, "/", filenm), stringsAsFactors = FALSE)
  if(sum(grepl("MA", colnames(dat))) > 0){
    dat2 <- dat[-1,-which(names(dat) %in% c("GEO_ID", "NAME", "X",
                                            grep("EA|MA", colnames(dat), value = TRUE)))]
  }else{
    dat2 <- dat[-1,-which(names(dat) %in% c("GEO_ID", "NAME"))]
  }
  
  dat2 <- apply(dat2, 2, as.numeric)
  return(dat2)
}

# get data for change over time
# factor
disabled = sum(read1yrtable(yr, "B18101")[c("B18101_004E","B18101_007E", 
                                            "B18101_010E", "B18101_013E",
                                            "B18101_016E", "B18101_019E",
                                            "B18101_023E", "B18101_026E",
                                            "B18101_029E", "B18101_032E",
                                            "B18101_035E", "B18101_038E")])

elderly = sum(read1yrtable(yr, "B01001")[c("B01001_020E","B01001_021E", "B01001_022E", 
                                          "B01001_023E","B01001_024E","B01001_025E",
                                          "B01001_044E","B01001_045E","B01001_046E", 
                                          "B01001_047E","B01001_048E","B01001_049E")])

minority = read1yrtable(yr, "B03002")
minority = minority["B03002_001E"] - minority["B03002_003E"]
poverty = read1yrtable(yr, "B17017")["B17017_002E"]
renters = read1yrtable(yr, "B25044")["B25044_009E"]
unemployed = read1yrtable(yr, "B23025")["B23025_005E"]
zero_cars = sum(read1yrtable(yr, "B25044")[c("B25044_003E", "B25044_010E")])

disabled.mpo = read1yrtable(yr, "B18101")["B18101_001E"]
elderly.mpo = read1yrtable(yr, "B01001")["B01001_001E"]
minority.mpo = read1yrtable(yr, "B03002")["B03002_001E"]
poverty.mpo = read1yrtable(yr, "B17017")["B17017_001E"]
renters.mpo = read1yrtable(yr, "B25044")["B25044_001E"]
unemployed.mpo = read1yrtable(yr, "B23025")["B23025_002E"]
zero_cars.mpo = read1yrtable(yr, "B25044")["B25044_001E"]

years = rep(year, 7)
factor = c("Disabled",
           "Elderly",
           "Minority",
           "Poverty",
           "Renters",
           "Unemployed",
           "Zero Cars")
universe = c("Non-Institutionalized Pop",
             "Population",
             "Population",
             "Households",
             "Households",
             "Workforce (Pop 16+)",
             "Households")

factortotal = c(disabled,
                elderly,
                minority,
                poverty,
                renters,
                unemployed,
                zero_cars)

mpototal = c(disabled.mpo,
             elderly.mpo,
             minority.mpo,
             poverty.mpo,
             renters.mpo,
             unemployed.mpo,
             zero_cars.mpo)

outdata <- data.frame(Year=years, Factor=factor, Universe=universe, 
                      FactorTotal=factortotal, MPOTotal=mpototal)
outdata$MPOavg = outdata$FactorTotal / outdata$MPOTotal
############################## Update change over time ##############################
# output should look like this, use data from ACS2013-2017
# change <- read_excel(paste0(outpath, "/TitleVIchangeovertime.xlsx"))
# # change2017 <- subset(change, Year==2017)
# # change2017
# change <- rbind(change, outdata)
# write.csv(change, paste0(outpath, "/TitleVIchangeovertime.csv"), row.names = FALSE)

change <- read.csv(paste0(outpath, "/TitleVIchangeovertime.csv"), 
                   stringsAsFactors = FALSE)

# # if you run into errors after the table update for the most recent year
# change <- subset(change, Year < year)

if(max(change$Year) == (year - 1)){
  change <- rbind(change, outdata)
  cat("Added the new data!")
}else if(max(change$Year) == year){
  cat("You are good to go!")
}else{
  cat("Have you updated the data last year?")
}
write.csv(change, paste0(outpath, "/TitleVIchangeovertime.csv"), row.names = FALSE)

############################## Read block group shapefile ##############################

bgpath <- "T:/Data/CENSUS/TIGER"
bg.shp <- st_read(dsn = bgpath, layer = "MPO_BG")
bginmpo <- read.csv(paste0(bgpath, "/blockgroup_in_mpo.csv"))

############################## Get 5-year data ##############################
# get data from all the tables
sex.by.age <- readtable()
race <- readtable(tablenm = 'B03002')
english <- readtable(tablenm = 'B16004')
poverty <- readtable(tablenm = 'B17017')
employment <- readtable(tablenm = 'B23025')
occupancy <- readtable(tablenm = 'B25002')
poptenure <- readtable(tablenm = 'B25008')
hhtenure <- readtable(tablenm = 'B25010')
vehicles <- readtable(tablenm = 'B25044')
disability <- readtable(tablenm = 'B18101', stren = 20) 
head(names(disability))
#head(disability)

############################## Calculate variables ##############################
# get disability data for block group using census tract data
disability.dt <- disability[, c('GEO_ID', 'B18101_001E', 'B18101_002E', 'B18101_003E',
                                  'B18101_007E', 'B18101_010E',
                                  'B18101_013E', 'B18101_016E',
                                  'B18101_019E', 'B18101_021E',
                                  'B18101_022E', 'B18101_026E',
                                  'B18101_029E', 'B18101_032E',
                                  'B18101_035E', 'B18101_038E')]
# ps_ni_5plus: total 5-year-and-older non-institutionalized population
disability.dt$ps_ni_5plus <- (disability.dt$B18101_002E - disability.dt$B18101_003E) + 
  (disability.dt$B18101_021E - disability.dt$B18101_022E)
# ps_ni_5plus_dis: total 5-year-and-older non-institutionalized population with disability
disability.dt$ps_ni_5plus_dis <- disability.dt$B18101_007E + disability.dt$B18101_010E + 
  disability.dt$B18101_013E + disability.dt$B18101_016E + disability.dt$B18101_019E + 
  disability.dt$B18101_026E + disability.dt$B18101_029E + disability.dt$B18101_032E + 
  disability.dt$B18101_035E + disability.dt$B18101_038E
# pc_ni_5plus_dis: percent of 5-year-and-older non-institutionalized population with disability
disability.dt$pc_ni_5plus_dis <- disability.dt$ps_ni_5plus_dis/disability.dt$ps_ni_5plus
# pc_ni_5plus: percent of 5-year-and-older non-institutionalized population
disability.dt$pc_ni_5plus <- disability.dt$ps_ni_5plus/disability.dt$B18101_001E

# get block group disability data
pop.bg <- sex.by.age[, c('GEO_ID', 'B01001_001E', 'B01001_003E', 'B01001_020E',
                           'B01001_021E','B01001_022E', 'B01001_023E','B01001_024E', 
                           'B01001_025E','B01001_027E','B01001_044E', 'B01001_045E',
                           'B01001_046E', 'B01001_047E', 'B01001_048E', 'B01001_049E')]
pop.bg$ps_65plus <- rowSums(pop.bg[,-which(names(pop.bg) %in% c('GEO_ID', 'B01001_001E', 'B01001_003E', 'B01001_027E'))])
pop.bg$pc_65plus <- pop.bg$ps_65plus/pop.bg$B01001_001E
pop.bg$CT_ID <- substr(pop.bg$GEO_ID, 1, 11)
names(disability.dt)[1] <- 'CT_ID' 
pop.bg <- merge(pop.bg, disability.dt[, c('CT_ID', 'pc_ni_5plus_dis', 'pc_ni_5plus')], by='CT_ID')
pop.bg$PopNInst5 <- pop.bg$B01001_001E * pop.bg$pc_ni_5plus
pop.bg$PopNI5Disa <- pop.bg$PopNInst5 * pop.bg$pc_ni_5plus_dis
#head(pop.bg)

# English proficiency literacy
ennvwell.bg <- english[, c('GEO_ID', 'B16004_001E', 'B16004_006E', 'B16004_007E',
                         'B16004_008E','B16004_011E', 'B16004_012E','B16004_013E', 
                         'B16004_016E','B16004_017E', 'B16004_018E', 'B16004_021E',
                         'B16004_022E', 'B16004_023E', 'B16004_028E', 'B16004_029E',
                         'B16004_030E', 'B16004_033E', 'B16004_034E', 'B16004_035E',
                         'B16004_038E', 'B16004_039E', 'B16004_040E', 'B16004_043E',
                         'B16004_044E', 'B16004_045E', 'B16004_050E', 'B16004_051E',
                         'B16004_052E', 'B16004_055E', 'B16004_056E', 'B16004_057E',
                         'B16004_060E', 'B16004_061E', 'B16004_062E', 'B16004_065E',
                         'B16004_066E', 'B16004_067E')]

ennvwell.bg$en_nvwell <- rowSums(ennvwell.bg[,-2:-1])
ennvwell.bg$pc_en_nvwell <- ennvwell.bg$en_nvwell/ennvwell.bg$B16004_001E

# zero-cars
zerocars.bg <- vehicles[, c('GEO_ID', 'B25044_001E', 'B25044_003E', 'B25044_009E', 'B25044_010E')]
zerocars.bg$zero_car <- zerocars.bg$B25044_003E + zerocars.bg$B25044_010E
zerocars.bg$pc_rtr_0car <- zerocars.bg$B25044_010E/zerocars.bg$zero_car
zerocars.bg$pc_own_0car <- zerocars.bg$B25044_003E/zerocars.bg$zero_car
zerocars.bg$pc_rtr <- zerocars.bg$B25044_009E/zerocars.bg$B25044_001E
zerocars.bg$pc_zero_car <- zerocars.bg$zero_car/zerocars.bg$B25044_001E

############################## Combine all variables ##############################
# collect block group data
bgdata <- pop.bg[, c('CT_ID', 'GEO_ID', 'B01001_001E', 'ps_65plus', 'pc_65plus', 'pc_ni_5plus_dis', 'PopNInst5', 'PopNI5Disa')]
colnames(bgdata)[3:6] <- c('TotalPOP', 'PopEld', 'PctElderly', 'PctDisab')
bgdata <- merge(bgdata, poptenure[,c('GEO_ID', 'B25008_001E')], by='GEO_ID') 
bgdata <- bgdata %>% rename(HHPop=B25008_001E)
bgdata$GQPop <- bgdata$TotalPOP - bgdata$HHPop
bgdata <- merge(bgdata, occupancy[,c('GEO_ID', 'B25002_001E', 'B25002_002E')], by='GEO_ID')
bgdata <- bgdata %>%
  mutate(Occupancy=B25002_002E/B25002_001E) %>%
  rename(TotalDU=B25002_001E) %>% 
  select(-c(B25002_002E))

bgdata <- merge(bgdata, poverty[,c('GEO_ID', 'B17017_001E', 'B17017_002E')], by='GEO_ID')
bgdata <- bgdata %>%
  mutate(PctPoor=B17017_002E/B17017_001E) %>%
  rename(HH=B17017_001E, HHPoor=B17017_002E)

bgdata <- merge(bgdata, race[,c('GEO_ID', 'B03002_001E', 'B03002_003E')], by='GEO_ID')
bgdata <- bgdata %>% 
  mutate(PctMinor=(B03002_001E - B03002_003E)/B03002_001E,
         PopMinor=B03002_001E - B03002_003E) %>% 
  select(-c(B03002_001E, B03002_003E))

bgdata <- merge(bgdata, employment[,c('GEO_ID', 'B23025_002E', 'B23025_005E')], by='GEO_ID')
bgdata <- bgdata %>%
  mutate(PctUnEmp=B23025_005E/B23025_002E) %>% 
  rename(PopWrkF16=B23025_002E, PopWFUnEmp=B23025_005E)

bgdata <- merge(bgdata, hhtenure[,c('GEO_ID', 'B25010_001E')], by='GEO_ID')
bgdata <- bgdata %>% rename(HHsize=B25010_001E)

bgdata <- merge(bgdata, ennvwell.bg[,c('GEO_ID', 'B16004_001E', 'en_nvwell', 'pc_en_nvwell')], by='GEO_ID')
bgdata <- bgdata %>% rename(PopGE5=B16004_001E, Pop5yrLEP=en_nvwell, PctLEP=pc_en_nvwell)

bgdata <- merge(bgdata, zerocars.bg[,c('GEO_ID', 'B25044_009E', 'B25044_003E','B25044_010E',
                                       'pc_zero_car', 'zero_car', 'pc_rtr')], by='GEO_ID')
bgdata <- bgdata %>% rename(PctHH0car=pc_zero_car, HH0car=zero_car, PctRentHH=pc_rtr, 
                            RenterHHs=B25044_009E, OwnHHNoCar=B25044_003E, 
                            RntHHNoCar=B25044_010E)

# double check the data
colnames(bgdata)[colnames(bgdata)=='GEO_ID'] <- 'BlkGrp20'
colnames(bginmpo)[colnames(bginmpo)=='GEOID'] <- 'BlkGrp20'

vars <- names(bgdata)[!(grepl('Pct', names(bgdata)) | (names(bgdata) %in% c("GEO_ID", "CT_ID", "HHsize", 'Occupancy')))]
bgdata <- merge(bgdata, bginmpo, by = 'BlkGrp20')

# correct data with percentage in MPO
for(var in vars[-1]){
  # if(var == "GQPop"){
  #   bgdata[,var] <- bgdata[,var] * bgdata$PctGQinside
  # }else{
    bgdata[,var] <- bgdata[,var] * bgdata$PctInside
  # }
}

# get MPO data only
#bgdata <- bgdata[bgdata$InsideArea != 0,]
bgdata <- bgdata[bgdata$PctInside != 0,]
selected <- names(bgdata)[names(bgdata) %in% grep('Pct', names(bgdata), value = TRUE) &
                              !(names(bgdata) %in% names(bginmpo))]
#mpoavg <- apply(bgdata[,selected], 2, mean, na.rm=TRUE)
mpoavg <- c(sum(bgdata$PopEld)/sum(bgdata$TotalPOP), 
            sum(bgdata$PopNI5Disa)/sum(bgdata$PopNInst5),
            sum(bgdata$HHPoor)/sum(bgdata$HH),
            sum(bgdata$PopMinor)/sum(bgdata$TotalPOP),
            sum(bgdata$PopWrkF16*bgdata$PctUnEmp)/sum(bgdata$PopWrkF16),
            sum(bgdata$Pop5yrLEP)/sum(bgdata$PopGE5),
            sum(bgdata$HH0car)/sum(bgdata$HH),
            sum(bgdata$RenterHHs)/sum(bgdata$HH))
names(mpoavg) <- selected
variables <- c("Elderly", "Disabled", "Poor", "Minority", 
               "UnEmp", "LEP", "HHzerocar", "Renter")
  
for(var in selected){
  bgdata[,variables[which(selected == var)]] <- ifelse(bgdata[,var] > mpoavg[var], 1, 0)
}
bgdata$ComofConce <- rowSums(bgdata[, c("Minority", "Elderly", "Poor", "Disabled")])
bgdata <- bgdata[, -which(names(bgdata) %in% c('CT_ID', 'InsideArea', 'PctInside', 'PctGQinside'))]

head(bgdata)
write.csv(bgdata, paste0(outpath, "/MPO_summary.csv"), row.names = FALSE)

# Update these numbers on the dashboard
mpoavg[1:4]
# 2017-2021
# PctElderly   PctDisab    PctPoor   PctMinor 
# 0.1685620  0.1683580  0.1669944  0.2159047 
# mpoavg
# PctElderly   PctDisab    PctPoor   PctMinor   PctUnEmp     PctLEP  PctHH0car  PctRentHH 
# 0.16856201 0.16835799 0.16699439 0.21590469 0.07127118 0.02702321 0.08916891 0.47276171 

mpotot <- c(sum(bgdata$PopEld), 
            sum(bgdata$PopNI5Disa),
            sum(bgdata$HHPoor),
            sum(bgdata$PopMinor),
            sum(bgdata$PopWrkF16*bgdata$PctUnEmp),
            sum(bgdata$Pop5yrLEP),
            sum(bgdata$HH0car),
            sum(bgdata$RenterHHs))
names(mpotot) <- c("PopEld", "PopDisa", "HHPoor", "PopMinor", "PopUnEmp", 
                   "PopLEP", "HH0car", "RenterHHs")

# mpotot
# PopEld    PopDisa    HHPoor    PopMinor  PopUnEmp    PopLEP    HH0car   RenterHHs 
# 45403.870 43200.473  18651.340 58156.098 10202.056   6934.604  9959.135 52802.011 

############################## Get shapefile data ##############################
names(bg.shp)[1] <- names(bgdata)[1]
bg.shp <- merge(bg.shp, bgdata, by="BlkGrp20")
bg.shp$ComofConce <- ifelse(is.na(bg.shp$ComofConce), 0, bg.shp$ComofConce)
bg.shp$PctPoor <- ifelse(is.na(bg.shp$PctPoor), 0, bg.shp$PctPoor)
# warnings on "Shape_Area" can be ignored
st_write(bg.shp, dsn = outpath, layer = "MPO_BG_TitleVI", driver = "ESRI Shapefile",
         delete_layer=TRUE)

############################## Others #################################
# further notes for mapping: determine the classification of the percentage of 
# concerns based on the quantile of population
outpath <- "T:/Tableau/tableauTitleVI/Datasources"

bgdata <- read.csv(paste0(outpath, "/MPO_summary.csv"),  stringsAsFactors = FALSE)
tot.vars <- c("TotalPOP", "PopWrkF16", "PopGE5", "HH", "PopNInst5", "TotalPOP", "HH")
pop.vars <- c("PopMinor", "PopWFUnEmp", "Pop5yrLEP", "HH0car", "PopNI5Disa", "PopEld", "HHPoor")
pct.vars <- c("PctMinor", "PctUnEmp", "PctLEP", "PctHH0car", "PctDisab", "PctElderly", "PctPoor")

# test some functions
# library(Hmisc)
# cuts <- split(bgdata[,pct.vars[5]], cut2(bgdata[,pop.vars[5]], g=6))
# library(gtools)
# levels(quantcut(bgdata[,pop.vars[5]], 6))
# range(bgdata[bgdata[,pop.vars[5]]>=0.326 & bgdata[,pop.vars[5]]<= 97.9,
#        pct.vars[5]])

notes <- c("1st", "2nd", "3rd", "4th", "5th", "6th")

MapDir <- "T:/MPO/Title VI & EJ/2023_TitleVI_update/Maps"
sink(paste0(MapDir, "/symbology_manual_cuts.txt"))
for(var in pct.vars){
  tot.var <- tot.vars[which(pct.vars==var)]
  df <- bgdata[,c(tot.var, var)]
  df <- df[order(df[,var]),]
  df$cumsum <-  cumsum(df[, tot.var])
  avg <- sum(df[, tot.var])/6
  cuts <- avg * c(1:6)
  v <- vector()
  for(cut in cuts){
    df$diff <- df$cumsum - cut
    cat(paste0('The ', notes[which(cuts==cut)], ' cut for ', var, ' is ', 
               df[abs(df$diff) == min(abs(df$diff)),var], '\n'))
    if(which(cuts==cut)==1){
      pop <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
      cat(paste0('The total population for this cut is ', pop,'\n'))
      last.cum <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
      v <- c(v, pop)
    }else{
      pop <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))] - last.cum
      cat(paste0('The total population for this cut is ', pop,'\n'))
      last.cum <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
      v <- c(v, pop)
    }
  }
  cat(paste("The average population size is", mean(v), "\n"))
  cat("\n")
}
sink()