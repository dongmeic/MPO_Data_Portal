# Objective: Clean the state and lane county VMT and population data
# to create the viz (VMT and Population: https://www.lcog.org/957/Population-Data)
# By Dongmei Chen (dchen@lcog.org)
# On December 15, 2020

# load libraries
library(xlsx)
library(readxl)


vmt_path <- "T:/Data/VMT/VMT_State_and_County"
pop_path <- "T:/Tableau/tableauPop/Datasources"

############################### Update 2020 #############################
dt <- read.csv(file.path(pop_path, "VMT_Pop.csv"))
vmt_state <- read_excel(file.path(vmt_path, "VMT_State.xls"),
                        range = "G17:H17",
                        col_names = FALSE)
vmt_county <- read_excel(file.path(vmt_path, "VMT_County.xlsx"),
                         range = "B25:B25",
                         col_names = FALSE)
filename <- "T:/Tableau/tableauPop/Datasources/HistoricalPopulation.xlsx"
pop <- read_excel(filename)



ndt <- data.frame(Year=2020, State_VMT=as.numeric(vmt_state[1,2]),
                  County_VMT=as.numeric(vmt_county),
                  State_Pop=as.numeric(pop[pop$YEAR==2020 & pop$GEOGRAPHY=="Oregon", 
                                           "POPULATION"]),
                  State_GrowthRate=as.numeric(pop[pop$YEAR==2020 & pop$GEOGRAPHY=="Oregon", 
                                                  "5-YEAR AVG. ANNUAL GROWTH RATE"]),
                  County_Pop=as.numeric(pop[pop$YEAR==2020 & pop$GEOGRAPHY=="Lane County (Total)", 
                                            "POPULATION"]),
                  County_GrowthRate=as.numeric(pop[pop$YEAR==2020 & pop$GEOGRAPHY=="Lane County (Total)", 
                                                   "5-YEAR AVG. ANNUAL GROWTH RATE"]))
geos <- c("State", "County")
vars <- c("PerCap", "AnnGR")
types <- c("VMT", "Pop")

for(geo in geos){
  for(var in vars){
    if(var == "PerCap"){
      ndt[,paste0(geo, "_", var)] <- ndt[,paste0(geo, "_VMT")]/ndt[,paste0(geo, "_Pop")]
    }else{
      for(type in types){
        x <- ndt[,paste0(geo, "_", type)]
        y <- dt[dt$Year==2019, paste0(geo, "_", type)]
        ndt[,paste0(geo, "_", type, "_", var)] <- x/y - 1
      }
    }
  }
}

dat <- rbind(dt, ndt)
write.csv(dat, file.path(pop_path, "VMT_Pop.csv"), row.names = FALSE)

############################### Before 2020 #############################
############################### Read VMT data ###########################
# open the table in Excel to check the reading range
vmt_state <- read.xlsx(file = file.path(vmt_path, "VMT_State.xls"),
                       sheetName = "VMT Web Publication", colIndex = 1:8,
                       startRow = 5, endRow = 24, header = FALSE)
head(vmt_state)
# rearrange the columns
for(i in 1:(dim(vmt_state)[2]/2)){
  if(i==1){
    cols <- vmt_state[,i:(2*i)]
    colnames(cols) <- c("Year", "VMT")
  }else{
    new_cols <- vmt_state[,((2*i)-1):(2*i)]
    colnames(new_cols) <- c("Year", "VMT")
    cols <- rbind(cols, new_cols)
  }
}
vmt_state_re <- cols
colnames(vmt_state_re)[2] <- "State_VMT"
vmt_state <- vmt_state_re[44:72,]

vmt_county <- read.xlsx(file = file.path(vmt_path, "VMT_County.xls"),
                       sheetName = "VMT by County", colIndex = 1:30,
                       startRow = 5, endRow = 41, header = FALSE)
vmt_county <- vmt_county[vmt_county$X1 %in% c("COUNTY", "LANE"),]
vmt_county <- data.frame(Year = as.numeric(vmt_county[1, 2:30]),
                         VMT = as.numeric(vmt_county[2, 2:30]))

vmt_county <- vmt_county[order(vmt_county$Year),]
colnames(vmt_county)[2] <- "County_VMT"

vmt <- cbind(vmt_state, vmt_county)[,-3]
vmt <- as.data.frame(apply(vmt, 2, as.numeric))

############################### Read Pop data ###########################
hist_pop <- read.xlsx(file = file.path(pop_path, "HistoricalPopulation.xlsx"),
                       sheetName = "PopulationRaw", colIndex = 1:7)
vars <- c("Year", "Pop", "GrowthRate")
colnames(hist_pop)[which(colnames(hist_pop) %in% 
                           c("YEAR", "POPULATION", "X5.YEAR.AVG..ANNUAL.GROWTH.RATE"))] <- vars
state_pop <- subset(hist_pop, as.numeric(Year) >= 1991 & GEOGRAPHY == "Oregon")[,vars]
county_pop <- subset(hist_pop, as.numeric(Year) >= 1991 & GEOGRAPHY == "Lane County (Total)")[,vars]
colnames(state_pop)[2:3] <- paste0("State_", colnames(state_pop)[2:3])
colnames(county_pop)[2:3] <- paste0("County_", colnames(county_pop)[2:3])

pop <- cbind(state_pop, county_pop[,2:3])

############################### Export the data ###########################

data <- cbind(vmt, pop[,-1])
geos <- c("State", "County")
vars <- c("PerCap", "AnnGR")
types <- c("VMT", "Pop")

for(geo in geos){
  for(var in vars){
    if(var == "PerCap"){
      data[,paste0(geo, "_", var)] <- data[,paste0(geo, "_VMT")]/data[,paste0(geo, "_Pop")]
    }else{
      for(type in types){
        x <- data[,paste0(geo, "_", type)]
        n <- length(x)
        data[,paste0(geo, "_", type, "_", var)] <- c(NA, x[2:n]/x[1:(n-1)]-1)
      }
    }
  }
}
write.csv(data, file.path(pop_path, "VMT_Pop.csv"), row.names = FALSE)

