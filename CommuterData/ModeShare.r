# This script was created by Dongmei Chen (dchen@lcog.org) to calculate data for the
# commuter mode share and length of commute data dashboards 
# (https://thempo.org/904/Commuter-Data) on May 12th, 2020

# load libraries
library(readxl)
library(dplyr)
library(reshape2)
library(stringr)

inpath <- "T:/Data/TranspData for Web/JTW_AllYears/JTW ACS 5-Yr All Years/"
outfolder <- "//clsrv111.int.lcog.org/transpor/Tableau/tableauJourneyToWork/Datasources/"
mode.share.file <- "ModeShare_ALL_Years.xlsx"
mode.by.vehicles.file <- "ModeByVehiclesAvailable_AllYears.xlsx"
mode.by.poverty.file <- "ModeByPovertyStatus_AllYears.xlsx"

# check the original tables for Tableau viz
mode.share <- read_excel(paste0(outfolder, mode.share.file), sheet = "ForViz")
mode.share <- mode.share[mode.share$Year != 2000, ]
head(mode.share)
write.csv(mode.share, paste0(outfolder, "ModeShare_ALL_Years.csv"), row.names = FALSE)
mode.by.vehicles <- read_excel(paste0(outfolder, mode.by.vehicles.file), sheet = "ForViz")
head(mode.by.vehicles)
write.csv(mode.by.vehicles, paste0(outfolder, "ModeByVehiclesAvailable_AllYears.csv"), row.names = FALSE)
mode.by.poverty <- read_excel(paste0(outfolder, mode.by.poverty.file), sheet = "ForViz")
head(mode.by.poverty)
write.csv(mode.by.poverty, paste0(outfolder, "ModeByPovertyStatus_AllYears.csv"), row.names = FALSE)

# get data from the raw data
# 1. Mode share - raw data include estimate and its margin of errors in each mode
# the final output should be: Year, Geography, Mode, Estimate, MOE_Est,
# Share, MOE_Share, SharePct, MOE_SharePct
unique(mode.share$Mode) # check metadata for details
# check raw data
readtable <- function(foldername="JTW_TravelMode_B08301", 
                      filenm.start= "ACSDT5Y2018.", 
                      tablenm="B08301", 
                      filenm.end = "_data_with_overlays_2020-05-13T143128.csv"){
  
  filenm <- paste0(filenm.start, tablenm, filenm.end)
  dat <- read.csv(paste0(inpath, foldername, "/", filenm), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-2:-1]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,2]), as.data.frame(dat2))
  colnames(dat)[1] <- "Name"
  return(dat)
}

# Mode share
# B08301 - Means of transportation to work
year = 2018
B08301 <- readtable() 
B08301T <- B08301 %>% # get target columns (T represents target)
  select(B08301_001E, B08301_001M,
         B08301_003E, B08301_003M, B08301_004E, B08301_004M,
         B08301_010E, B08301_010M, B08301_016E, B08301_016M, 
         B08301_017E, B08301_017M, B08301_018E, B08301_018M,
         B08301_019E, B08301_019M, B08301_020E, B08301_020M, 
         B08301_021E, B08301_021M, Name)  
B08301TE <- B08301T[,grep("E", names(B08301T), value = TRUE)][,-1]
B08301TE.t <-  as.data.frame(t(B08301TE))
row.names(B08301TE.t) 
row.names(B08301TE.t) <- c("Car, truck, or van - Drove alone",
                           "Car, truck, or van - Carpooled",
                           "Public transportation (excluding taxicab)",
                           "Taxicab", "Motorcycle", "Bicycle", "Walked",
                           "Other means", "Worked at home")
geography <- c("Coburg" , "Eugene", "Springfield",
               "Eugene Urbanized Area", "Salem Urbanized Area")
colnames(B08301TE.t) <- geography
B08301TE.df <- stack(B08301TE.t)
colnames(B08301TE.df) <- c("Estimate", "Geography")
B08301TE.df$Mode <- rep(row.names(B08301TE.t), 5)
B08301TM <- B08301T[,grep("M", names(B08301T), value = TRUE)][,-1]
B08301TM.t <-  as.data.frame(t(B08301TM))
B08301TE.df$MOE_Est <- stack(B08301TM.t)$values
B08301TE.df$Year <- rep(year, dim(B08301TE.df)[1])
B08301TE.df <- B08301TE.df[, c("Year", "Geography", "Mode", "Estimate", "MOE_Est" )]
# calculate Share, MOE_Share, SharePct, MOE_SharePct
for(geo in unique(B08301TE.df$Geography)){
  i <- B08301TE.df$Geography == geo
  j <- unique(B08301TE.df$Geography) == geo
  B08301TE.df$Share[i] <- B08301TE.df$Estimate[i]/B08301T$B08301_001E[j]
  B08301TE.df$MOE_Share[i] <- sqrt((B08301TE.df$MOE_Est[i])^2-(B08301TE.df$Share[i])^2*(B08301T$B08301_001M[j])^2)/B08301T$B08301_001E[j]
}
B08301TE.df$SharePct <- B08301TE.df$Share * 100
B08301TE.df$MOE_SharePct <- B08301TE.df$MOE_Share * 100

mode.share <- read.csv(paste0(outfolder, "ModeShare_ALL_Years.csv"))
mode.share <- rbind(mode.share, B08301TE.df)
write.csv(mode.share, paste0(outfolder, "ModeShare_ALL_Years.csv"), row.names = FALSE)


# Mode share by vehicle available
B08141 <- readtable(foldername = "JTW_ModeByVehiclesAvailable_B08141", tablenm = "B08141",
                    filenm.end = "_data_with_overlays_2020-05-13T211815.csv")

get.data.by.mode <- function(cols=c("B08141_007", "B08141_008", "B08141_009", "B08141_010"), 
                             mode="Car, truck, or van - drove alone",
                             modecolnm="Mode by Vehicle Availability",
                             type="Vehicles Available",
                             dat=B08141,
                             type.details=c("No vehicle available", "1 vehicle available",
                                            "2 vehicles available", "3 or more vehicles available"),
                             totcols=c("B08141_002", "B08141_003", "B08141_004", "B08141_005")){
  df <- dat %>% select(paste0(cols, "E"))
  df.t <-  as.data.frame(t(df))
  row.names(df.t) <- type.details
  colnames(df.t) <- geography
  df.stk <- stack(df.t)
  colnames(df.stk) <- c("Estimate", "Geography")
  df.stk[,type] <- rep(row.names(df.t), 5)
  df <- dat %>% select(paste0(cols, "M"))
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

col.list <- list(c("B08141_012", "B08141_013", "B08141_014", "B08141_015"),
                 c("B08141_017", "B08141_018", "B08141_019", "B08141_020"),
                 c("B08141_022", "B08141_023", "B08141_024", "B08141_025"),
                 c("B08141_027", "B08141_028", "B08141_029", "B08141_030"),
                 c("B08141_032", "B08141_033", "B08141_034", "B08141_035"))

modes <- c("Car, truck, or van - drove alone", "Car, truck, or van - carpooled",
           "Public transportation (excluding taxicab)", "Walked",
           "Taxicab, motorcycle, bicycle, or other means", "Worked at home")

for(l in 1:length(col.list)){
  if(l == 1){
    B08141.df <- get.data.by.mode()
  }else{
    df <- get.data.by.mode(cols=col.list[[l]], mode=modes[l])
    B08141.df <- rbind(B08141.df, df)
  }
}

mode.by.vehicles <- read.csv(paste0(outfolder, mode.by.vehicles.file))
head(mode.by.vehicles)
mode.by.vehicles <- rbind(mode.by.vehicles, B08141.df)
write.csv(mode.by.vehicles, paste0(outfolder, "ModeByVehiclesAvailable_AllYears.csv"), row.names = FALSE)


# Mode share by poverty status
B08122 <- readtable(foldername = "JTW_ModeByPovertyStatus_B08122", tablenm = "B08122",
                    filenm.end = "_data_with_overlays_2020-05-14T172556.csv")

modecolnm = "Travel.Mode"
type = "Poverty.Status"
type.details = c("Below 100 percent of the poverty level", "100 to 149 percent of the poverty level",
                 "At or above 150 percent of the poverty level")
dat = B08122
totcols = c("B08122_002", "B08122_003", "B08122_004")

col.list <- list(c("B08122_006", "B08122_007", "B08122_008"), 
                 c("B08122_010", "B08122_011", "B08122_012"),
                 c("B08122_014", "B08122_015", "B08122_016"),
                 c("B08122_018", "B08122_019", "B08122_020"),
                 c("B08122_022", "B08122_023", "B08122_024"),
                 c("B08122_026", "B08122_027", "B08122_028"))

modes <- c("Car, truck, or van - drove alone", "Car, truck, or van - carpooled",
           "Public transportation (excluding taxicab)", "Walked", 
           "Taxicab, motorcycle, bicycle, or other means", "Worked at home")

for(l in 1:length(col.list)){
  
  if(l==1){
    B08122.df <- get.data.by.mode(cols=col.list[[l]], 
                               mode=modes[l],
                               modecolnm=modecolnm,
                               type=type,
                               dat=B08122,
                               type.details=type.details,
                               totcols=totcols)
  }else{
    df <- get.data.by.mode(cols=col.list[[l]], 
                           mode=modes[l],
                           modecolnm=modecolnm,
                           type=type,
                           dat=B08122,
                           type.details=type.details,
                           totcols=totcols)
    B08122.df <- rbind(B08122.df, df)
  }
  
}

mode.by.poverty.file <- "ModeByPovertyStatus_AllYears.csv"
mode.by.poverty <- read.csv(paste0(outfolder, mode.by.poverty.file))
head(mode.by.poverty)
mode.by.poverty <- rbind(mode.by.poverty, B08122.df)
write.csv(mode.by.poverty, paste0(outfolder, "ModeByPovertyStatus_AllYears.csv"), row.names = FALSE)

# Length of commute
time.leaving.file <- "TimeLeavingForWork_AllYears.xlsx"
time.leaving <- read_excel(paste0(outfolder, time.leaving.file), sheet = "ForViz")
write.csv(time.leaving, paste0(outfolder, "TimeLeavingForWork_AllYears.csv"), row.names = FALSE)

travel.time.file <- "TravelTimeToWork_AllYears.xlsx"
travel.time <- read_excel(paste0(outfolder, travel.time.file), sheet = "ForViz")
write.csv(travel.time, paste0(outfolder, "TravelTimeToWork_AllYears.csv"), row.names = FALSE)


foldername = "JTW_TimeLeaving_B08302"
filenm.start = "ACSDT5Y2018."
tablenm = "B08302"
filenm.end = "_2020-05-15T131849.csv"

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

timesteps <- c("Midnight to 5 AM","5 to 5:30 AM","5:30 to 6 AM",           
               "6 to 6:30 AM","6:30 to 7 AM","7 to 7:30 AM",           
               "7:30 to 8 AM", "8 to 8:30 AM","8:30 to 9 AM",           
                "9 to 10 AM", "10 to 11 AM", "11 AM to Noon",          
                "Noon to 4 PM", "4 PM to Midnight")

year = 2018

get.time.data <- function(foldername = "JTW_TimeLeaving_B08302", 
                          filenm.start = "ACSDT5Y2018.",
                          tablenm = "B08302", 
                          filenm.end = "_2020-05-15T131849.csv",
                          colnm = 'Time.Leaving.for.Work..Census.',
                          time = TRUE){
  data.file <- paste0(filenm.start, tablenm, "_data_with_overlays", filenm.end)
  dat <- read.csv(paste0(inpath, foldername, "/", data.file), stringsAsFactors = FALSE)
  dat2 <- dat[-1,-2:-1]
  dat2 <- apply(dat2, 2, as.numeric)
  dat <- cbind(as.data.frame(dat[-1,2]), as.data.frame(dat2))
  colnames(dat)[1] <- "Name"
  metadata.file <- paste0(filenm.start, tablenm, "_metadata", filenm.end)
  metadat <- read.csv(paste0(inpath, foldername, "/", metadata.file), stringsAsFactors = FALSE)
  metadat <- metadat[,-3]
  dat.t <- as.data.frame(t(dat))
  dat.t <- dat.t[-3:-1,]
  rownames <- row.names(dat.t)
  dat.t <- as.data.frame(apply(dat.t, 2, as.numeric))
  row.names(dat.t) <- rownames
  dat.est <- dat.t[row.names(dat.t) %in% grep("E", row.names(dat.t), value = TRUE),]
  colnames(dat.est) <- geography
  df.stk <- stack(dat.est)
  colnames(df.stk) <- c("Estimate", "Geography")
  metadat <- metadat[metadat$GEO_ID %in% grep("E", metadat$GEO_ID, value = TRUE),]
  metadat <- metadat[-2:-1,]
  dat.moe <- dat.t[row.names(dat.t) %in% grep("M", row.names(dat.t), value = TRUE),]
  df.stk$MOE_Est <- stack(dat.moe)$values
  if(time){
    df.stk[,colnm] <- rep(add.colon(str_remove(metadat$id, "Estimate!!Total!!")), 5)
    df.stk$`Time.Leaving.for.Work` <- rep(timesteps, 5)
    df.stk$Year <- rep(year, dim(df.stk)[1])
    df.stk <- df.stk[, c("Year", "Geography", colnm,
                         "Time.Leaving.for.Work", "Estimate", "MOE_Est")]
  }else{
    df.stk[,colnm] <- rep(str_remove(metadat$id, "Estimate!!Total!!"), 5)
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


B08302.df <- get.time.data()

B08303.df <- get.time.data(foldername = "JTW_TravelTime_B08303", tablenm = "B08303",
                    filenm.end = "_2020-05-15T131935.csv",
                    colnm = "Length.of.Commute", time = FALSE)

time.leaving.file <- "TimeLeavingForWork_AllYears.csv"
time.leaving <- read.csv(paste0(outfolder, time.leaving.file))
head(time.leaving)
time.leaving <- rbind(time.leaving, B08302.df)
write.csv(time.leaving, paste0(outfolder, "TimeLeavingForWork_AllYears.csv"), row.names = FALSE)

travel.time.file <- "TravelTimeToWork_AllYears.csv"
travel.time <- read.csv(paste0(outfolder, travel.time.file))
head(travel.time)
travel.time <- rbind(travel.time, B08303.df)
write.csv(travel.time, paste0(outfolder, "TimeLeavingForWork_AllYears.csv"), row.names = FALSE)