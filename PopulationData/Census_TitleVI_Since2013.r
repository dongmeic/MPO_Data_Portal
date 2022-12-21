
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
