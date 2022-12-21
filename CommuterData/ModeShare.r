# This script was created by Dongmei Chen (dchen@lcog.org) to calculate data for the
# commuter mode share and length of commute data dashboards 
# (https://www.lcog.org/thempo/page/commuter-mode-shares) on May 12th, 2020

inpath <- "T:/Data/TranspData for Web/JTW_AllYears/JTW ACS 5-Yr All Years/"
outfolder <- "T:/Tableau/tableauJourneyToWork/Datasources/"
source("T:/DCProjects/GitHub/MPO_Data_Portal/CommuterData/ModeShare_functions.r")

# set up parameters
year = 2021
test = TRUE
output = FALSE
new_data_only = TRUE

# ################################## One-time data cleaning ##################################
# mode.share.file <- "ModeShare_ALL_Years.xlsx"
# mode.by.vehicles.file <- "ModeByVehiclesAvailable_AllYears.xlsx"
# mode.by.poverty.file <- "ModeByPovertyStatus_AllYears.xlsx"
# 
# # check the original tables for Tableau viz
# mode.share <- read_excel(paste0(outfolder, mode.share.file), sheet = "ForViz")
# mode.share <- mode.share[mode.share$Year != 2000, ]
# head(mode.share)
# write.csv(mode.share, paste0(outfolder, "ModeShare_ALL_Years.csv"), row.names = FALSE)
# mode.by.vehicles <- read_excel(paste0(outfolder, mode.by.vehicles.file), sheet = "ForViz")
# head(mode.by.vehicles)
# write.csv(mode.by.vehicles, paste0(outfolder, "ModeByVehiclesAvailable_AllYears.csv"), row.names = FALSE)
# mode.by.poverty <- read_excel(paste0(outfolder, mode.by.poverty.file), sheet = "ForViz")
# head(mode.by.poverty)
# write.csv(mode.by.poverty, paste0(outfolder, "ModeByPovertyStatus_AllYears.csv"), row.names = FALSE)
# 
# # get data from the raw data
# # 1. Mode share - raw data include estimate and its margin of errors in each mode
# # the final output should be: Year, Geography, Mode, Estimate, MOE_Est,
# # Share, MOE_Share, SharePct, MOE_SharePct
# unique(mode.share$Mode) # check metadata for details

################################## Read new yearly data and append to the input tables ##################################
# Mode share
# B08301 - Means of transportation to work

B08301 <- readtable(year = year) 
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
if(test){
  mode.share <- mode.share[mode.share$Year != year,]
}
if(!new_data_only){
  mode.share <- rbind(mode.share, B08301TE.df)
}
if(output){
  write.csv(mode.share, paste0(outfolder, "ModeShare_ALL_Years.csv"), row.names = FALSE)
}

# Mode share by vehicle available
B08141 <- readtable(foldername = "JTW_ModeByVehiclesAvailable_B08141", 
                    year= 2021, 
                    tablenm = "B08141")

col.list <- list(c("012", "013", "014", "015"),
                 c("017", "018", "019", "020"),
                 c("022", "023", "024", "025"),
                 c("027", "028", "029", "030"),
                 c("032", "033", "034", "035"))

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

mode.by.vehicles.file <- "ModeByVehiclesAvailable_AllYears.csv"
mode.by.vehicles <- read.csv(paste0(outfolder, mode.by.vehicles.file))
colnames(B08141.df) <- colnames(mode.by.vehicles)
head(mode.by.vehicles)
if(test){
  mode.by.vehicles <- mode.by.vehicles[mode.by.vehicles$Year != year,]
}
if(!new_data_only){
  mode.by.vehicles <- rbind(mode.by.vehicles, B08141.df)
}
if(output){
  write.csv(mode.by.vehicles, paste0(outfolder, "ModeByVehiclesAvailable_AllYears.csv"), row.names = FALSE)
}

# Mode share by poverty status
B08122 <- readtable(foldername = "JTW_ModeByPovertyStatus_B08122", 
                    year = 2021, 
                    tablenm = "B08122")

modecolnm = "Travel.Mode"
type = "Poverty.Status"
type.details = c("Below 100 percent of the poverty level", "100 to 149 percent of the poverty level",
                 "At or above 150 percent of the poverty level")
dat = B08122
tablenm = "B08122"
totcols = c("002", "003", "004")

col.list <- list(c("006", "007", "008"), 
                 c("010", "011", "012"),
                 c("014", "015", "016"),
                 c("018", "019", "020"),
                 c("022", "023", "024"),
                 c("026", "027", "028"))

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
                               tablenm=tablenm,
                               totcols=totcols)
  }else{
    df <- get.data.by.mode(cols=col.list[[l]], 
                           mode=modes[l],
                           modecolnm=modecolnm,
                           type=type,
                           dat=B08122,
                           type.details=type.details,
                           tablenm=tablenm,
                           totcols=totcols)
    B08122.df <- rbind(B08122.df, df)
  }
}

mode.by.poverty.file <- "ModeByPovertyStatus_AllYears.csv"
mode.by.poverty <- read.csv(paste0(outfolder, mode.by.poverty.file))
head(mode.by.poverty)
if(test){
  mode.by.poverty <- mode.by.poverty[mode.by.poverty$Year != year,]
}
if(!new_data_only){
  mode.by.poverty <- rbind(mode.by.poverty, B08122.df)
}
if(output){
  write.csv(mode.by.poverty, paste0(outfolder, "ModeByPovertyStatus_AllYears.csv"), row.names = FALSE)
}

# ################################## One-time data cleaning ##################################
# # Length of commute
# time.leaving.file <- "TimeLeavingForWork_AllYears.xlsx"
# time.leaving <- read_excel(paste0(outfolder, time.leaving.file), sheet = "ForViz")
# write.csv(time.leaving, paste0(outfolder, "TimeLeavingForWork_AllYears.csv"), row.names = FALSE)
# 
# travel.time.file <- "TravelTimeToWork_AllYears.xlsx"
# travel.time <- read_excel(paste0(outfolder, travel.time.file), sheet = "ForViz")
# write.csv(travel.time, paste0(outfolder, "TravelTimeToWork_AllYears.csv"), row.names = FALSE)

################################## Read new yearly data and append to the input tables ##################################

timesteps <- c("Midnight to 5 AM","5 to 5:30 AM","5:30 to 6 AM",           
               "6 to 6:30 AM","6:30 to 7 AM","7 to 7:30 AM",           
               "7:30 to 8 AM", "8 to 8:30 AM","8:30 to 9 AM",           
                "9 to 10 AM", "10 to 11 AM", "11 AM to Noon",          
                "Noon to 4 PM", "4 PM to Midnight")

B08302.df <- get.time.data(year = 2021)

B08303.df <- get.time.data(foldername = "JTW_TravelTime_B08303", 
                           year = 2021,
                           tablenm = "B08303",
                           colnm = "Length.of.Commute",
                           time = FALSE)

time.leaving.file <- "TimeLeavingForWork_AllYears.csv"
time.leaving <- read.csv(paste0(outfolder, time.leaving.file))
#time.leaving <- time.leaving %>% filter(Year != year)
tail(time.leaving)
if(test){
  time.leaving <- time.leaving[time.leaving$Year != year,]
}
if(!new_data_only){
  time.leaving <- rbind(time.leaving, B08302.df)
}
if(output){
  write.csv(time.leaving, paste0(outfolder, "TimeLeavingForWork_AllYears.csv"),
            row.names = FALSE)
}

travel.time.file <- "TravelTimeToWork_AllYears.csv"
travel.time <- read.csv(paste0(outfolder, travel.time.file))
#travel.time <- travel.time %>% filter(Year != year) 
tail(travel.time)
if(test){
  travel.time <- travel.time[travel.time$Year != year,]
}
if(!new_data_only){
  travel.time <- rbind(travel.time, B08303.df)
}
if(output){
  write.csv(travel.time, paste0(outfolder, "TravelTimeToWork_AllYears.csv"),
            row.names = FALSE)
}

if(new_data_only){
  save(mode.share, mode.by.vehicles, mode.by.poverty, time.leaving, travel.time, 
     file = paste0(outfolder, "mode_share_data.RData"))
}