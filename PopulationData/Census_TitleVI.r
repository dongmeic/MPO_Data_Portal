# This script was created by Dongmei Chen (dchen@lcog.org) to calculate data for the
# TitleVI dashboard (https://thempo.org/958/Socio-Economic-Data) on May 5th, 2020

# load libraries
library(readxl)
library(rgdal)
library(dplyr)
inpath <- "T:/Data/CENSUS/ACS20142018/TitleVI/"
outpath <- "T:/Tableau/tableauTitleVI/Datasources"

tablenm <- "B01001"

# functions
readtable <- function(filenm.start= "ACSDT5Y2018.", 
                      tablenm="B01001", stren = 21, # string end number
                      filenm.end = "_data_with_overlays_2020-05-05T123638.csv"){
  filenm <- paste0(filenm.start, tablenm, filenm.end)
  dat <- read.csv(paste0(inpath, filenm), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-2:-1]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,1]), as.data.frame(dat2))
  colnames(dat)[1] <- "GEO_ID"
  dat$GEO_ID <- substr(dat$GEO_ID, 10, stren)
  return(dat)
}

read1yrtable <- function(yr, tablenm){
  dat <- read.csv(paste0("T:/Data/CENSUS/ACS20", yr, "/ACS_", yr, "_1YR_", tablenm, "_with_ann.csv"), 
                  stringsAsFactors = FALSE)
  dat2 <- dat[-1,-2:-1]
  dat2 <- apply(dat2, 2, as.numeric)
  return(dat2)
}

# get data for change over time
# factor
yr = 18
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

year = 2018
year = rep(year, 7)
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

outdata <- data.frame(Year=year, Factor=factor, Universe=universe, 
                      FactorTotal=factortotal, MPOTotal=mpototal)
outdata$MPOavg = outdata$FactorTotal / outdata$MPOTotal

# output should look like this, use data from ACS2013-2017
change <- read_excel(paste0(outpath, "/TitleVIchangeovertime.xlsx"))
# change2017 <- subset(change, Year==2017)
# change2017
change <- rbind(change, outdata)
write.csv(change, paste0(outpath, "/TitleVIchangeovertime.csv"), row.names = FALSE)

# bgdata.shp <- readOGR(dsn = outpath, layer = "MPO_BG_TitleVI", 
#                   stringsAsFactors = FALSE)
# names(bgdata.shp)

bg.shp <- readOGR(dsn = outpath, layer = "MPO_BG", stringsAsFactors = FALSE)

# create a table to match blockgroup with the MPO boundary 
# by copying data from previous blockgroupdata.xlsx
testpath <- "C:/Users/clid1852/OneDrive - lanecouncilofgovernments/DataPortal/census"
bginmpo <- read_excel(paste0(testpath, "/blockgroup_in_mpo.xlsx"))
bginmpo$PctGQinside <- ifelse(is.na(bginmpo$PctGQinside), 0, bginmpo$PctGQinside)
head(bginmpo)

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
disability <- readtable(tablenm = 'B18101', stren = 20,
                        filenm.end = '_data_with_overlays_2020-05-09T003818.csv') 
head(names(disability))
#head(disability)

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
colnames(bgdata)[colnames(bgdata)=='GEO_ID'] <- 'BlkGrp10'
# bgdata[bgdata$BlkGrp10 == '410390003001',-2]
# bgdata.shp@data[bgdata.shp@data$BlkGrp10 == '410390003001',names(bgdata[,-2])]
# what other variables are missing
# names(bgdata.shp@data)[!(names(bgdata.shp@data) %in% names(bgdata))]
# make corrections with percentages in MPO on these variables
vars <- names(bgdata)[!(grepl('Pct', names(bgdata)) | (names(bgdata) %in% c("GEO_ID", "CT_ID", "HHsize", 'Occupancy')))]
bgdata <- merge(bgdata, bginmpo, by = 'BlkGrp10')
# bgdata[bgdata$InsideArea == 2 & bgdata$GQPop != 0, c('BlkGrp10', 'PctGQinside', 'GQPop')]
# df <- merge(bgdata.shp@data, bginmpo, by = 'BlkGrp10')
# df[df$InsideArea == 2, c('BlkGrp10','PctGQinside', 'GQPop')]

# correct data with percentage in MPO
for(var in vars[-1]){
  if(var == "GQPop"){
    bgdata[,var] <- bgdata[,var] * bgdata$PctGQinside
  }else{
    bgdata[,var] <- bgdata[,var] * bgdata$PctInside
  }
}
# bgdata[bgdata$BlkGrp10 == '410390003001',vars[-1]]
# df[df$BlkGrp10 == '410390003001',vars[-1]]
# get MPO data only
bgdata <- bgdata[bgdata$InsideArea != 0,]
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
variables <- c("Elderly", "Disabled", "Poor", "Minority", "UnEmp", "LEP", "HHzerocar", "Renter")
  
for(var in selected){
  bgdata[,variables[which(selected == var)]] <- ifelse(bgdata[,var] > mpoavg[var], 1, 0)
}
bgdata$ComofConce <- rowSums(bgdata[, c("Minority", "Elderly", "Poor", "Disabled")])
bgdata <- bgdata[, -which(names(bgdata) %in% c('CT_ID', 'InsideArea', 'PctInside', 'PctGQinside'))]

# double check data
# bgdata[1,]
# bgdata.shp@data[1,names(bgdata)]

head(bgdata)
write.csv(bgdata, paste0(outpath, "/MPO_summary.csv"), row.names = FALSE)
names(bg.shp)[1] <- names(bgdata)[1]
bg.shp <- merge(bg.shp, bgdata, by="BlkGrp10")
bg.shp$ComofConce <- ifelse(is.na(bg.shp$ComofConce), 0, bg.shp$ComofConce)
bg.shp$PctPoor <- ifelse(is.na(bg.shp$PctPoor), 0, bg.shp$PctPoor)
writeOGR(bg.shp, dsn = outpath, layer = "MPO_BG_TitleVI", driver = "ESRI Shapefile",
         overwrite_layer=TRUE)

# further notes for mapping: determine the classification of the percentage of 
# concerns based on the quantile of population

bgdata <- read.csv(paste0(outpath, "/MPO_summary.csv"),  stringsAsFactors = FALSE)
tot.vars <- c("TotalPOP", "PopWrkF16", "PopGE5", "HH", "PopNInst5", "TotalPOP")
pop.vars <- c("PopMinor", "PopWFUnEmp", "Pop5yrLEP", "HH0car", "PopNI5Disa", "PopEld")
pct.vars <- c("PctMinor", "PctUnEmp", "PctLEP", "PctHH0car", "PctDisab", "PctElderly")

# test some functions
# library(Hmisc)
# cuts <- split(bgdata[,pct.vars[5]], cut2(bgdata[,pop.vars[5]], g=6))
# library(gtools)
# levels(quantcut(bgdata[,pop.vars[5]], 6))
# range(bgdata[bgdata[,pop.vars[5]]>=0.326 & bgdata[,pop.vars[5]]<= 97.9,
#        pct.vars[5]])

notes <- c("1st", "2nd", "3rd", "4th", "5th", "6th")
for(var in pct.vars){
  tot.var <- tot.vars[which(pct.vars==var)]
  df <- bgdata[,c(tot.var, var)]
  df <- df[order(df[,var]),]
  df$cumsum <-  cumsum(df[, tot.var])
  avg <- sum(df[, tot.var])/6
  cuts <- avg * c(1:6)
  for(cut in cuts){
    df$diff <- df$cumsum - cut
    cat(paste0('The ', notes[which(cuts==cut)], ' cut for ', var, ' is ', 
               df[abs(df$diff) == min(abs(df$diff)),var], '\n'))
    if(which(cuts==cut)==1){
      cat(paste0('The total population for this cut is ', df$cumsum[which(abs(df$diff) == min(abs(df$diff)))],'\n'))
      last.cum <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
    }else{
      cat(paste0('The total population for this cut is ', df$cumsum[which(abs(df$diff) == min(abs(df$diff)))] - last.cum,'\n'))
      last.cum <- df$cumsum[which(abs(df$diff) == min(abs(df$diff)))]
    }
  }
  cat("\n")
}

