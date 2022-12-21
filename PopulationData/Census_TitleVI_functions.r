
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
