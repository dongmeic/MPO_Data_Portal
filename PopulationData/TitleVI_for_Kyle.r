# Objective: organize and map data for Kyle's requests - 
# to create data and visualization for places outside of MPO following the reference below
# Dongmei CHEN (dchen@lcog.org)
# August 7th, 2020
# Reference: https://www.lcog.org/958/Socio-Economic-Data 
# Geography is shown below 
# LANE COUNTY 
# 
# 41039000800 - Census Tract 8
# 41039001101 - Census Tract 11.01
# 41039001102 - Census Tract 11.02
# 41039001201 - Census Tract 12.01 --- and all block groups
# 41039001202 - Census Tract 12.02 --- and all block groups
# 41039001301 - Census Tract 13.01 --- and all block groups
# 41039001302 - Census Tract 13.02 --- and all block groups
# 41039001400 - Census Tract 14
# 41039001700 - Census Tract 17
# 
# DOUGLAS COUNTY
# 
# 41019030000 - Census Tract 300
# 41019040000 - Census Tract 400


# load libraries
library(readxl)
library(rgdal)
library(dplyr)

year <- 2019
rangeyr <- "20152019"

mainDir <- "T:/Data/CENSUS"
subDir <- sprintf("ACS%s", yrrange)
#county <- "Lane"
county <- "Douglas"
newDir <- paste0("TitleVI/Others/", county)
path <- file.path(mainDir, subDir, newDir)
dir.create(path)

zipfiles <- list.files(path = path, 
                       pattern = "zip", all.files = TRUE)
for(zipfile in zipfiles){
  unzip(zipfile = file.path(path, zipfile), 
        exdir = path)
}

# functions
# the functions have been updated for the 2019 data
readtable <- function(filenm.start= sprintf("ACSDT5Y%d.", year),
                      tablenm="B01001", stren = 21, yrrange = rangeyr,
                      county="Lane"){
  
  inpath <- paste0("T:/Data/CENSUS/ACS", rangeyr,"/TitleVI/others/")
  inpath <- paste0(inpath, county)
  filenm <- list.files(path = inpath, 
                       pattern = paste0(filenm.start,
                                        tablenm,
                                        "_data_with_overlays_"))
  dat <- read.csv(paste0(inpath, "/", filenm), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-2:-1]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,1]), as.data.frame(dat2))
  colnames(dat)[1] <- "GEO_ID"
  dat$GEO_ID <- substr(dat$GEO_ID, 10, stren)
  return(dat)
}

path <- paste0("T:/Data/CENSUS/ACS", yrrange, "/TitleVI/others/")
outpath <- paste0(path, "processed/")
dir.create(outpath)

#cnt.name <- "Lane"
cnt.name <- "Douglas"
sex.by.age <- readtable(county=cnt.name)
race <- readtable(tablenm = 'B03002', county=cnt.name)
poverty <- readtable(tablenm = 'B17017', county=cnt.name)
disability <- readtable(tablenm = 'B18101', stren = 20, 
                        county=cnt.name)

# get disability data for block group using census tract data
get.disab.dt <- function(df.tract =  disability, df.bg = sex.by.age){
  disability.dt <- df.tract[, c('GEO_ID', 'B18101_001E', 'B18101_002E', 'B18101_003E',
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
  pop.bg <- df.bg[, c('GEO_ID', 'B01001_001E', 'B01001_003E', 'B01001_020E',
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
  return(pop.bg)
}

pop.bg <- get.disab.dt()
#head(pop.bg)

# collect block group data
collect.bg.dt <- function(){
  bgdata <- pop.bg[, c('CT_ID', 'GEO_ID', 'B01001_001E', 'ps_65plus', 'pc_65plus', 
                       'pc_ni_5plus_dis', 'PopNInst5', 'PopNI5Disa')]
  colnames(bgdata)[3:6] <- c('TotalPOP', 'PopEld', 'PctElderly', 'PctDisab')
  bgdata <- merge(bgdata, poverty[,c('GEO_ID', 'B17017_001E', 'B17017_002E')], by='GEO_ID')
  bgdata <- bgdata %>%
    mutate(PctPoor=B17017_002E/B17017_001E) %>%
    rename(HH=B17017_001E, HHPoor=B17017_002E)
  
  bgdata <- merge(bgdata, race[,c('GEO_ID', 'B03002_001E', 'B03002_003E')], by='GEO_ID')
  bgdata <- bgdata %>% 
    mutate(PctMinor=(B03002_001E - B03002_003E)/B03002_001E,
           PopMinor=B03002_001E - B03002_003E) %>% 
    select(-c(B03002_001E, B03002_003E))
  return(bgdata)
}

bgdata <- collect.bg.dt()

# get average data
get.avg.dt <- function(){
  selected <- names(bgdata)[names(bgdata) %in% 
                              grep('Pct', names(bgdata), 
                                   value = TRUE)][1:4]
  cnt.avg <- c(sum(bgdata$PopEld)/sum(bgdata$TotalPOP), 
               sum(bgdata$PopNI5Disa)/sum(bgdata$PopNInst5),
               sum(bgdata$HHPoor)/sum(bgdata$HH),
               sum(bgdata$PopMinor)/sum(bgdata$TotalPOP))
  names(cnt.avg) <- selected
  print("The average values:")
  print(cnt.avg)
  variables <- c("Elderly", "Disabled", "Poor", "Minority")
  for(var in selected){
    bgdata[,variables[which(selected == var)]] <- ifelse(bgdata[,var] > cnt.avg[var], 1, 0)
  }
  bgdata$ComofConce <- rowSums(bgdata[, c("Minority", "Elderly", "Poor", "Disabled")])
  return(bgdata)
}
                                                                
bgdata <- get.avg.dt()

write.csv(bgdata, paste0(outpath, cnt.name, "_summary.csv"), 
          row.names = FALSE)

# combine both counties to calculate average
lane <- read.csv(paste0(outpath, "Lane_summary.csv"), stringsAsFactors = FALSE)
douglas <- read.csv(paste0(outpath, "Douglas_summary.csv"), stringsAsFactors = FALSE)

bgdata <- rbind(lane, douglas)
write.csv(bgdata, paste0(outpath, "separated_summary.csv"), row.names = FALSE)
bgdata <- get.avg.dt()
write.csv(bgdata, paste0(outpath, "combined_summary.csv"), row.names = FALSE)
