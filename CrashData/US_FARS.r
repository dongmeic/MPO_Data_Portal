# This script was created to update US FARS (Fatality Analysis Reporting System) data 
# data downloaded from https://www.fhwa.dot.gov/policyinformation/statistics/2019/vm2.cfm (VMT) and 
# https://www-fars.nhtsa.dot.gov/States/StatesCrashesAndAllVictims.aspx (fatalities) for the 
# tableau dashboard "US_FARS_VMT Fatality Rate OneMap_DC"
# By Dongmei Chen (dchen@lcog.org)
# On March 11th, 2020

library(readxl)
library(dplyr)
library(writexl)

inpath <- "T:/Data/FARS/" 
outpath <- "T:/Tableau/tableauCrash/Datasources/"

# output format
US_FARS_data <- read_xlsx(paste0(outpath, "US_FARS_data.xlsx")) %>%
                select_all(~gsub("\\s+|\\.", "", .)) 

names(US_FARS_data)[which(names(US_FARS_data) == 'VMT(Millions)')] <- 'VMT'

# input data
# the original table was downloaded as a "xls" extension and the table can't be read correctly
# so I edit the table to get the total numbers only and save the data as a csv
#vmt <- read_xlsx(paste0(inpath, "vm2.xlsx"))
vmt <- read.csv(paste0(inpath, "vm2.csv"))
# I also save this data to "xlsx" and remove the second empty row
fars <- read_xlsx(paste0(inpath, "FileName.xlsx"))

length(vmt$STATE)
length(fars$State)
unique(US_FARS_data$State)


vmt <- vmt[vmt$STATE %in% unique(US_FARS_data$State), ]
fars <- fars[fars$State %in% unique(US_FARS_data$State), ]


ndf <- data.frame(State=unique(US_FARS_data$State), Year=rep(2019, 50), VMT=round(vmt$TOTAL, 0),
                  Fatalities=fars$`2019`, FatalityRate=round((fars$`2019`/round(vmt$TOTAL, 0))*100, 2))

US_FARS_data <- rbind(US_FARS_data, ndf)
US_FARS_data <- US_FARS_data[order(US_FARS_data$State),] 
names(US_FARS_data) <- c("State", "Year", "VMT (Millions)", "Fatalities", "Fatality Rate")

write_xlsx(US_FARS_data, paste0(outpath, "US_FARS_data.xlsx"))
