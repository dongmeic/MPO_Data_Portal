
# functions

unzip_data <- function(yrrange="20172021", year=2021){
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
}

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

get_MPOavg_data <- function(yr=21){
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
  
  return(outdata)
}

get_TitleVI_data <- function(){
  ############################## Get 5-year data ##############################
  # get data from all the tables
  sex.by.age <- readtable(tablenm="B01001")
  race <- readtable(tablenm = 'B03002')
  english <- readtable(tablenm = 'B16004')
  poverty <- readtable(tablenm = 'B17017')
  employment <- readtable(tablenm = 'B23025')
  occupancy <- readtable(tablenm = 'B25002')
  poptenure <- readtable(tablenm = 'B25008')
  hhtenure <- readtable(tablenm = 'B25010')
  vehicles <- readtable(tablenm = 'B25044')
  disability <- readtable(tablenm = 'B18101', stren = 20) 
  #head(names(disability))
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
  
  return(bgdata)
}

adjust_TitleVI_data <- function(df=bgdata, export=TRUE){
  # double check the data
  if(!('GEOID' %in% colnames(df))){
    colnames(df)[colnames(df)=='GEO_ID'] <- 'GEOID'
  }
  
  vars <- names(df)[!(grepl('Pct', names(df)) | (names(df) %in% c("GEO_ID", "CT_ID", "HHsize", 'Occupancy')))]
  df <- merge(df, bginmpo, by = 'GEOID')
  
  # correct data with percentage in MPO
  for(var in vars[-1]){
    # if(var == "GQPop"){
    #   df[,var] <- df[,var] * df$PctGQinside
    # }else{
    df[,var] <- df[,var] * df$PctInside
    # }
  }
  
  # get MPO data only
  #df <- df[df$InsideArea != 0,]
  df <- df[df$PctInside != 0,]
  selected <- names(df)[names(df) %in% grep('Pct', names(df), value = TRUE) &
                              !(names(df) %in% names(bginmpo))]
  #mpoavg <- apply(df[,selected], 2, mean, na.rm=TRUE)
  mpoavg <- c(sum(df$PopEld)/sum(df$TotalPOP), 
              sum(df$PopNI5Disa)/sum(df$PopNInst5),
              sum(df$HHPoor)/sum(df$HH),
              sum(df$PopMinor)/sum(df$TotalPOP),
              sum(df$PopWrkF16*df$PctUnEmp)/sum(df$PopWrkF16),
              sum(df$Pop5yrLEP)/sum(df$PopGE5),
              sum(df$HH0car)/sum(df$HH),
              sum(df$RenterHHs)/sum(df$HH))
  names(mpoavg) <- selected
  variables <- c("Elderly", "Disabled", "Poor", "Minority", 
                 "UnEmp", "LEP", "HHzerocar", "Renter")
  
  for(var in selected){
    df[,variables[which(selected == var)]] <- ifelse(df[,var] > mpoavg[var], 1, 0)
  }
  df$ComofConce <- rowSums(df[, c("Minority", "Elderly", "Poor", "Disabled")])
  df <- df[, -which(names(df) %in% c('CT_ID', 'InsideArea', 'PctInside', 'PctGQinside'))]
  
  if(export){
    write.csv(df, paste0(outpath, "/MPO_summary.csv"), row.names = FALSE)
  }
  
  return(list(df, mpoavg))
}
