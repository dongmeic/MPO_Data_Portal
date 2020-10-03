# Objective: to update data for the tableau dashboard "EmphasisAreas_DC"
# By Dongmei Chen (dchen@lcog.org)
# On March 11th, 2020

library(rgdal)
library(sf)
library(dplyr)
library(reshape2)

ReadFromSQL <- FALSE

if(ReadFromSQL){
  library(RODBC)
  dbhandle <- odbcDriverConnect('driver={SQL Server};server=rliddb.int.lcog.org,5433;database=GIS_CLMPO;trusted_connection=true')
  dbhandle
  currTableSQL <- paste("SELECT * From ODOT_Crash", sep="")
  currTableDF <- sqlQuery(dbhandle, currTableSQL)
}

fgdb <- "T:/Data/Safety/Lane_County_Crashes/LaneCounty_Crashes_SpatializedDecode.gdb"
outpath <- "//clsrv111.int.lcog.org/transpor/Tableau/tableauSafetyEmphasisAreas/Datasources/"

# What output should look like
CheckOldData = TRUE
if(CheckOldData){
  trend <- read.csv(paste0(outpath, "OldData/Trend_Tableau.csv"), stringsAsFactors = FALSE)
  head(trend)
  severity <- read.csv(paste0(outpath, "OldData/Severity_Tableau.csv"), stringsAsFactors = FALSE)
  head(severity)
}

# This will take a while to complete
data <- readOGR(dsn = fgdb, layer = "Crash", stringsAsFactors = FALSE)
vhcl <- st_read(dsn = fgdb, layer = "Crash_Vehicle", stringsAsFactors = FALSE)
# Read the participant table for the young drivers and unlicensed drivers measures
partic <- st_read(dsn = fgdb, layer = "Crash_Participant", stringsAsFactors = FALSE)
partic <- partic[!is.na(partic$vhcl_id),]
  
# Organize young drivers for each crash ID
partic$age_val <- as.numeric(partic$age_val)
partic.drvr <- partic[partic$partic_typ_long_desc == "Driver", ]
partic.yngdr <- partic.drvr[partic.drvr$age_val >= 15 & partic.drvr$age_val <= 21,]
data$yng_drvr <- ifelse(data$crash_id %in% partic.yngdr$crash_id, 1, 0)

# Organize unlicensed drivers for each crash ID
valid = TRUE
if(valid){
  partic.unlic <- partic.drvr[!(partic.drvr$drvr_lic_stat_cd %in%
                                  c("1", "2", "9")),]
}else{
  partic.unlic <- partic.drvr[(partic.drvr$drvr_lic_stat_cd %in% 
                                 c("0", "3", "8")),]
}
# table(partic.drvr$drvr_lic_stat_cd)
# table(partic.drvr$drvr_lic_stat_long_desc)
# length(na.omit(partic.drvr$drvr_lic_stat_long_desc))/dim(partic.drvr)[1]
# length(na.omit(partic.drvr$drvr_lic_stat_cd))/dim(partic.drvr)[1]
# unique(partic.drvr$drvr_lic_stat_cd[is.na(partic.drvr$drvr_lic_stat_long_desc)])

data$unlic_drvr <- ifelse(data$crash_id %in% partic.unlic$crash_id, 1, 0)
length(data$unlic_drvr[data$unlic_drvr == 1])/dim(data)[1]

# Organize the inattention measure
data$inatt_flag <- ifelse(((data$crash_cause_1_long_desc == "Inattention") | 
                          (data$crash_cause_2_long_desc == "Inattention") |
                          (data$crash_cause_3_long_desc == "Inattention")), 1, 0)
data$inatt_flag[is.na(data$inatt_flag)] <- 0

# Organize the intersection measure
unique(data$isect_rel_flg)
inters <- data[data$rd_char_long_desc == "Intersection",]
data$inters_flg <- ifelse(data$crash_id %in% inters$crash_id, 1, 0)

# Organize the factor ("Minor Arterial", "Prcpl. Arterial Oth", "Major Collector")
data$mir_atl <- ifelse(data$fc_desc %in% c("URBAN MINOR ARTERIAL", "RURAL MINOR ARTERIAL"), 1, 0)
data$prcpl_atl <- ifelse(data$fc_desc %in% c("URBAN PRINCIPAL ARTERIAL - OTHER", 
                                             "RURAL PRINCIPAL ARTERIAL - OTHER"), 1, 0)
data$maj_coltr <- ifelse(data$fc_desc %in% c("RURAL MAJOR COLLECTOR", 
                                             "URBAN MAJOR COLLECTOR"), 1, 0)

# Organize the speed involved measure
unique(data$crash_speed_invlv_flg)

# Organize the roadway departure measure
unique(data$lane_rdwy_dprt_crash_flg)
data$rdwy_dprt_flg <- ifelse(data$lane_rdwy_dprt_crash_flg == "Y", 1, 0)

# Organize the bicycle measure
bike.crash <- data[(data$tot_pedcycl_cnt > 0 & data$tot_ped_cnt == 0 
                   & data$tot_mcyclst_inj_cnt == 0 & data$tot_mcyclst_fatal_cnt == 0),]
data$pedcycl_flag <- ifelse(data$crash_id %in% bike.crash$crash_id, 1, 0)

# Organize the pedestrian measure
ped.crash <- data[(data$tot_ped_cnt > 0 & data$tot_pedcycl_cnt == 0 
                    & data$tot_mcyclst_inj_cnt == 0 & data$tot_mcyclst_fatal_cnt == 0),]
data$ped_flag <- ifelse(data$crash_id %in% ped.crash$crash_id, 1, 0)
  
# Organize the motorcycle measure
motorcycle <- vhcl[vhcl$vhcl_typ_long_desc == "Motorcycle, dirt bike",]
data$motorcyclist <- ifelse(data$crash_id %in% motorcycle$crash_id, 1, 0)

# Organize the impaired driving measure
data$impaired_drvr <- ifelse(data$alchl_invlv_flg == 1 | data$drug_invlv_flg == 1, 1, 0)

# Organize the unrestrained occupants measure
SevCode <- c(1, 2)
partic.no.seat.belt <- partic[partic$inj_svrty_cd %in% SevCode & partic$sfty_equip_use_cd == 0,]
partic.child <- partic[partic$age_val < 13 & partic$sfty_equip_use_long_desc %in%
                            c("Child restraint used improperly"),] # "Seat belt or harness used improperly"
data$unres_occup_flag <- ifelse(data$crash_id %in% c(partic.no.seat.belt$crash_id, partic.child$crash_id), 1, 0)

data$mpo_flg <- ifelse(is.na(data$is_in_mpo), "Non-CLMPO", "CLMPO")

# Organize measures
measures <- unique(trend$Measure)
variables <- c("impaired_drvr", "crash_speed_invlv_flg", "unres_occup_flag", "inatt_flag",
               "ped_flag", "pedcycl_flag", "motorcyclist", "yng_drvr", "mir_atl",
               "maj_coltr", "prcpl_atl", "inters_flg", "rdwy_dprt_flg", 
               "unlic_drvr")
oldnames <- c("crash_yr_no", "mpo_flg", variables) # "is_in_mpo", "urb_area_long_nm", "ugb_name"
newnames <- c("Year", "Geography", measures)

# Get the total counts and toal fatal counts
total.df <- as.data.frame(data[, c(oldnames, "tot_fatal_cnt", "tot_inj_lvl_a_cnt", "tot_inj_cnt")]) %>% 
  select(-c(coords.x1, coords.x2)) %>%
  mutate(Count = tot_fatal_cnt + tot_inj_lvl_a_cnt, Crash = tot_fatal_cnt + tot_inj_cnt) %>%
  select(-c(tot_fatal_cnt, tot_inj_lvl_a_cnt, tot_inj_cnt)) %>%
  rename_at(vars(oldnames), ~ newnames) %>%
  mutate(Year = as.numeric(Year))

# total.df$UGB <- ifelse(is.na(total.df$UGB), "Others", total.df$UGB)
# total.df <- total.df[total.df$Year < 2014, ]

# Calculate total fatal counts by measure 
count.df <- total.df[, c(newnames, "Count")] %>% 
  mutate_at(measures, funs(.*Count)) %>%
  group_by(Year, Geography, add = TRUE) %>% 
  summarise_at(measures, sum, na.rm = TRUE) %>%
  melt(id.vars = c("Year", "Geography"), measure.vars = measures) %>%
  rename(Measure = variable, Count = value) %>%
  mutate(Category = ifelse(Measure %in% c("Impaired Driving", "Speed Involved", 
                                           "Inattention", "Unlicensed Drivers"), 
                            "Risky Behavior", 
         ifelse(Measure %in% c("Unrestrained Occupants",
                               "Pedestrian","Bicycle", "Motorcycle",
                               "Young Drivers (15-21)"), 
                            "Vulnerable Users", "Infrastructure")))
sum(count.df$Count[count.df$Measure == "Unlicensed Drivers"])

# Calculate total counts by measure 
crash.df <- total.df[, c(newnames, "Crash")] %>% 
  mutate_at(measures, funs(.*Crash)) %>%
  group_by(Year, Geography, add = TRUE) %>% 
  summarise_at(measures, sum, na.rm = TRUE) %>%
  melt(id.vars = c("Year", "Geography"), measure.vars = measures) %>%
  rename(Measure = variable, Crash = value) %>%
  mutate(Category = ifelse(Measure %in% c("Impaired Driving", "Speed Involved", 
                                          "Inattention", "Unlicensed Drivers"), 
                           "Risky Behavior", 
                           ifelse(Measure %in% c("Unrestrained Occupants",
                                                 "Pedestrian","Bicycle", "Motorcycle",
                                                 "Young Drivers (15-21)"), 
                                  "Vulnerable Users", "Infrastructure")))

count.df2 <- cbind(count.df, data.frame(Crash = crash.df$Crash))
count.df2$Rate <- count.df2$Count/count.df2$Crash * 100

# Calculate rate
rate.df <- cbind(count.df[, c("Measure", "Geography", "Category", "Count")], crash.df[, "Crash"]) %>%
  rename_at('crash.df[, "Crash"]', ~ 'Crash') %>%
  group_by(Measure, Geography, Category, add = TRUE) %>% 
  summarise_at(c("Count", "Crash"), sum, na.rm = TRUE) %>%
  mutate(Rate = Count/Crash * 100) %>%
  select(Count, Crash, Rate, Measure, Geography, Category)

#rate.df <- rate.df[!is.na(rate.df$Rate),]

write.csv(count.df2, paste0(outpath, "Trend_Tableau.csv"), row.names = FALSE)
write.csv(rate.df, paste0(outpath, "Severity_Tableau.csv"), row.names = FALSE)

sum(rate.df$Count[rate.df$Geography == 'CLMPO']) # 2425
sum(rate.df$Count[rate.df$Geography == 'Non-CLMPO']) # 3118

################################# UGB #######################################
# add UGB
oldnames <- c("crash_yr_no", "mpo_flg", "ugb_name", variables) # "is_in_mpo", "urb_area_long_nm", "ugb_name"
newnames <- c("Year", "Geography", "UGB", measures)

# Get the total counts and toal fatal counts
total.df <- as.data.frame(data[, c(oldnames, "tot_fatal_cnt", "tot_inj_lvl_a_cnt", "tot_inj_cnt")]) %>% 
  select(-c(coords.x1, coords.x2)) %>%
  mutate(Count = tot_fatal_cnt + tot_inj_lvl_a_cnt, Crash = tot_fatal_cnt + tot_inj_cnt) %>%
  select(-c(tot_fatal_cnt, tot_inj_lvl_a_cnt, tot_inj_cnt)) %>%
  rename_at(vars(oldnames), ~ newnames) %>%
  mutate(Year = as.numeric(Year))

total.df$UGB <- ifelse(is.na(total.df$UGB), "Others", total.df$UGB)
# total.df <- total.df[total.df$Year < 2014, ]

# Calculate total fatal counts by measure 
count.df <- total.df[, c(newnames, "Count")] %>% 
  mutate_at(measures, funs(.*Count)) %>%
  group_by(Year, Geography, UGB, add = TRUE) %>% 
  summarise_at(measures, sum, na.rm = TRUE) %>%
  melt(id.vars = c("Year", "Geography", "UGB"), measure.vars = measures) %>%
  rename(Measure = variable, Count = value) %>%
  mutate(Category = ifelse(Measure %in% c("Impaired Driving", "Speed Involved", 
                                          "Inattention", "Unlicensed Drivers"), 
                           "Risky Behavior", 
                           ifelse(Measure %in% c("Unrestrained Occupants",
                                                 "Pedestrian","Bicycle", "Motorcycle",
                                                 "Young Drivers (15-21)"), 
                                  "Vulnerable Users", "Infrastructure")))
sum(count.df$Count[count.df$Measure == "Unlicensed Drivers"])

# Calculate total counts by measure 
crash.df <- total.df[, c(newnames, "Crash")] %>% 
  mutate_at(measures, funs(.*Crash)) %>%
  group_by(Year, Geography, UGB, add = TRUE) %>% 
  summarise_at(measures, sum, na.rm = TRUE) %>%
  melt(id.vars = c("Year", "Geography", "UGB"), measure.vars = measures) %>%
  rename(Measure = variable, Crash = value) %>%
  mutate(Category = ifelse(Measure %in% c("Impaired Driving", "Speed Involved", 
                                          "Inattention", "Unlicensed Drivers"), 
                           "Risky Behavior", 
                           ifelse(Measure %in% c("Unrestrained Occupants",
                                                 "Pedestrian","Bicycle", "Motorcycle",
                                                 "Young Drivers (15-21)"), 
                                  "Vulnerable Users", "Infrastructure")))

count.df3 <- cbind(count.df, data.frame(Crash = crash.df$Crash))
count.df3$Rate <- count.df3$Count/count.df3$Crash * 100

count.df4 <- count.df3

for(year in unique(count.df4$Year)){
  for(geo in unique(count.df4$Geography)){
    for(measure in unique(count.df4$Measure)){
      selected <- count.df4$Year == year & count.df4$Geography == geo & count.df4$Measure == measure
      tot.cnt <- sum(count.df4$Crash[selected])
      count.df4$Rate[selected] <-  count.df4$Count[selected]/tot.cnt * 100
      print(paste(year, geo, measure))
    }
  }
}

# Calculate rate
rate.df2 <- cbind(count.df[, c("Measure", "Geography", "UGB", "Category", "Count")], crash.df[, "Crash"]) %>%
  rename_at('crash.df[, "Crash"]', ~ 'Crash') %>%
  group_by(Measure, Geography, Category, UGB, add = TRUE) %>% 
  summarise_at(c("Count", "Crash"), sum, na.rm = TRUE) %>%
  mutate(Rate = Count/Crash * 100) %>%
  select(Count, Crash, Rate, Measure, Geography, UGB, Category)

# rate.df2 <- rate.df2[!is.na(rate.df2$Rate),]
rate.df3 <- rate.df2

for(geo in unique(rate.df3$Geography)){
  for(measure in unique(rate.df3$Measure)){
    selected <- rate.df3$Geography == geo & rate.df3$Measure == measure
    tot.cnt <- sum(rate.df3$Crash[selected])
    rate.df3$Rate[selected] <-  rate.df3$Count[selected]/tot.cnt * 100
    print(paste(geo, measure))
  }
}

write.csv(count.df4, paste0(outpath, "Trend_Tableau_UGB.csv"), row.names = FALSE)
write.csv(rate.df3, paste0(outpath, "Severity_Tableau_UGB.csv"), row.names = FALSE)
