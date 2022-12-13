# This script was created to collect functions for the cleaning of commuter data
# By Dongmei Chen (dchen@lcog.org)
# On August 11th, 2022

# load libraries
library(readxl)
library(dplyr)
library(reshape2)
library(stringr)

# read tables since 2021
readtable <- function(foldername="JTW_TravelMode_B08301", 
                      year=2021, 
                      tablenm="B08301", 
                      filenm.end = "-Data"){
  filenm.start <- paste0("ACSDT5Y", year, ".")
  filenm.end <- paste0(filenm.end, ".csv")
  filenm <- paste0(filenm.start, tablenm, filenm.end)
  dat <- read.csv(paste0(inpath, foldername, "/", filenm), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-which(names(dat) %in% c("GEO_ID", "NAME", "X",
                                          grep("EA|MA", colnames(dat), value = TRUE)))]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,which(names(dat) %in% c("GEO_ID", "NAME"))]), as.data.frame(dat2))
  colnames(dat)[2] <- "Name"
  return(dat)
}

# readtable <- function(foldername="JTW_TravelMode_B08301", 
#                       year=2018, 
#                       tablenm="B08301", 
#                       filenm.end = "2020-05-13T143128"){
#   filenm.start <- paste0("ACSDT5Y", year, ".")
#   filenm.end <- paste0("_data_with_overlays_", filenm.end, ".csv")
#   filenm <- paste0(filenm.start, tablenm, filenm.end)
#   dat <- read.csv(paste0(inpath, foldername, "/", filenm), stringsAsFactors = FALSE)
#   dat2 <- dat[-1,-which(names(dat) %in% c("GEO_ID", "NAME"))]
#   dat2 <- apply(dat2, 2, as.numeric)
#   dat <- cbind(as.data.frame(dat[-1,2]), as.data.frame(dat2))
#   colnames(dat)[1] <- "Name"
#   return(dat)
# }

get.data.by.mode <- function(cols=c("007", "008", "009", "010"), 
                             mode="Car, truck, or van - drove alone",
                             modecolnm="Mode by Vehicle Availability",
                             type="Vehicles Available",
                             dat=B08141,
                             type.details=c("No vehicle available", "1 vehicle available",
                                            "2 vehicles available", "3 or more vehicles available"),
                             tablenm="B08141",
                             totcols=c("002", "003", "004", "005")){
  totcols <- paste0(tablenm, "_", totcols)
  df <- dat %>% select(paste0(tablenm, "_", cols, "E"))
  df.t <-  as.data.frame(t(df))
  row.names(df.t) <- type.details
  geography <- c("Coburg" , "Eugene", "Springfield",
                 "Eugene Urbanized Area", "Salem Urbanized Area")
  colnames(df.t) <- geography
  df.stk <- stack(df.t)
  colnames(df.stk) <- c("Estimate", "Geography")
  df.stk[,type] <- rep(row.names(df.t), 5)
  df <- dat %>% select(paste0(tablenm, "_", cols, "M"))
  df.t <-  as.data.frame(t(df))
  df.stk$MOE_Est <- stack(df.t)$values
  df.stk$Year <- rep(year, dim(df.stk)[1])
  df.stk[,modecolnm] <- rep(mode, dim(df.stk)[1])
  df.stk <- df.stk[, c("Year", "Geography", modecolnm,
                       type, "Estimate", "MOE_Est")]
  # calculate Share, MOE_Share, SharePct, MOE_SharePct
  for(geo in unique(df.stk$Geography)){
    for(t in unique(df.stk[,type])){
      i <- df.stk$Geography == geo & df.stk[,type] == t
      j <- unique(df.stk$Geography) == geo
      k <- unique(df.stk[,type]) == t
      df.stk$Share[i] <- df.stk$Estimate[i]/dat[,paste0(totcols[k], "E")][j]
      df.stk$MOE_Share[i] <- sqrt((df.stk$MOE_Est[i])^2-(df.stk$Share[i])^2*(dat[,paste0(totcols[k], "M")][j])^2)/dat[,paste0(totcols[k], "E")][j]
    }
  }
  df.stk$SharePCT <- df.stk$Share * 100
  df.stk$MOE_SharePct <- df.stk$MOE_Share * 100
  return(df.stk)
}

add.colon <- function(v){
  for(i in 1:length(v)){
    num <- gsub("\\D", "", v[i])
    if(i==1){
      v[i] <- paste(paste0(substr(num, 1, 2), ":", substr(num, 3, 4)), "a.m. to",
                    paste0(substr(num, 5, 5), ":", substr(num, 6, 7)), "a.m.")
    }else if(i == 13){
      v[i] <- paste(paste0(substr(num, 1, 2), ":", substr(num, 3, 4)), "p.m. to",
                    paste0(substr(num, 5, 5), ":", substr(num, 6, 7)), "p.m.")
    }else if(i == 14){
      v[i] <- paste(paste0(substr(num, 1, 1), ":", substr(num, 2, 3)), "p.m. to",
                    paste0(substr(num, 4, 5), ":", substr(num, 6, 7)), "p.m.")
    }else if(i == 11 | i == 12){
      v[i] <- paste(paste0(substr(num, 1, 2), ":", substr(num, 3, 4)), "a.m. to",
                    paste0(substr(num, 5, 6), ":", substr(num, 7, 8)), "a.m.")
    }else{
      v[i] <- paste(paste0(substr(num, 1, 1), ":", substr(num, 2, 3)), "a.m. to",
                    paste0(substr(num, 4, 4), ":", substr(num, 5, 6)), "a.m.")
    }
  }
  return(v)
}

get.time.data <- function(foldername = "JTW_TimeLeaving_B08302", 
                          year = 2021,
                          tablenm = "B08302", 
                          filenm.end = "-Data",
                          colnm = 'Time.Leaving.for.Work..Census.',
                          toRemove = "Annotation of Estimate!!Total:!!",
                          time = TRUE){
  filenm.start <- paste0("ACSDT5Y", year, ".")
  #data.file <- paste0(filenm.start, tablenm, "_data_with_overlays_", filenm.end, ".csv")
  data.file <- paste0(filenm.start, tablenm, filenm.end, ".csv")
  dat <- read.csv(paste0(inpath, foldername, "/", data.file), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-which(names(dat) %in% c("GEO_ID", "NAME", "X",
                                          grep("EA|MA", colnames(dat), value = TRUE)))]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,"NAME"]), as.data.frame(dat2))
  colnames(dat)[1] <- "Name"
  #metadata.file <- paste0(filenm.start, tablenm, "_metadata_", filenm.end, ".csv")
  metadata.file <- paste0(filenm.start, tablenm, "-Column-Metadata.csv")
  metadat <- read.csv(paste0(inpath, foldername, "/", metadata.file), 
                      stringsAsFactors = FALSE, 
                      skip = 1)
  #metadat <- metadat[,-3]
  dat.t <- as.data.frame(t(dat))
  dat.t <- dat.t[-3:-1,]
  rownames <- row.names(dat.t)
  dat.t <- as.data.frame(apply(dat.t, 2, as.numeric))
  row.names(dat.t) <- rownames
  dat.est <- dat.t[row.names(dat.t) %in% grep("E", row.names(dat.t), value = TRUE),]
  colnames(dat.est) <- geography
  df.stk <- stack(dat.est)
  colnames(df.stk) <- c("Estimate", "Geography")
  metadat <- metadat[metadat$GEO_ID %in% grep("EA", metadat$GEO_ID, value = TRUE),]
  metadat <- metadat[-1,]
  dat.moe <- dat.t[row.names(dat.t) %in% grep("M", row.names(dat.t), value = TRUE),]
  df.stk$MOE_Est <- stack(dat.moe)$values
  if(time){
    df.stk[,colnm] <- rep(add.colon(str_remove(metadat$Geography, toRemove)), 5)
    # need to define timesteps
    df.stk$`Time.Leaving.for.Work` <- rep(timesteps, 5)
    df.stk$Year <- rep(year, dim(df.stk)[1])
    df.stk <- df.stk[, c("Year", "Geography", colnm,
                         "Time.Leaving.for.Work", "Estimate", "MOE_Est")]
  }else{
    df.stk[,colnm] <- rep(str_remove(metadat$Geography, toRemove), 5)
    df.stk$Year <- rep(year, dim(df.stk)[1])
    df.stk <- df.stk[, c("Year", "Geography", colnm,
                         "Estimate", "MOE_Est")]
  }
  for(geo in unique(df.stk$Geography)){
    i <- df.stk$Geography == geo
    j <- unique(df.stk$Geography) == geo
    df.stk$Share[i] <- df.stk$Estimate[i]/dat[j,2]
    df.stk$MOE_Share[i] <- sqrt((df.stk$MOE_Est[i])^2-(df.stk$Share[i])^2*(dat[j,3])^2)/dat[j,2]
  }
  df.stk$SharePCT <- df.stk$Share * 100
  df.stk$MOE_SharePct <- df.stk$MOE_Share * 100
  return(df.stk)
}