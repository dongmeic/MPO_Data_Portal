library(rjson)
library(tidycensus)

keypath <- "T:/DCProjects/GitHub/MPO_Data_Portal/TrafficCountData/AADBT/"
census_api_key(rjson::fromJSON(file=paste0(keypath, "config/keys.json"))$acs$key, install = TRUE)

# place to store results and combine them
# Block groups are not currently available for the 2008-2012 ACS and earlier.
years <- 2012:2020
res <- vector("list",length(years))
names(res) <- years

# variables that you want
#        Tot Pop     White non-Hisp  FemHeadHouse  FamPoverty
#vars <- c('B01001_001','B03002_003','B11003_016','B17010_002')
vars <- c('S1901_C01_001E', 'S1901_C01_012E', 'S1901_C01_013E')

# loop over years, save data
# could also apply county filter, see help(get_acs)
for (y in years){
  # download data
  ld <- as.data.frame(get_acs(year = y,
                              geography='tract',
                              survey='acs5',
                              variables = vars,
                              state="OR",
                              county = "Lane"))
  # reshape long to wide
  ld2 <- reshape(ld,
                 idvar="GEOID",
                 timevar="variable",
                 direction="wide",
                 drop=c("NAME","moe"))
  # insert into list and add in year
  res[[y]] <- ld2
  res[[y]]$year <- y
}

# Combining the data frames together for final analysis
combo <- do.call("rbind",res)
head(combo) 
summary(combo)