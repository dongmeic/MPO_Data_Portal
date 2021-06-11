# This script was created to collect functions for traffic counts
# By Dongmei Chen (dchen@lcog.org)
# On February 18th, 2020

# combine regional traffic counts spreadsheets
# requires a dataframe for the settings





combine.traffic.counts <- function(file.df, type=FALSE){
  # create a file.df to collect table information
  for(filenm in file.df$filename){
    # make sure this is the first row
    print(filenm)
    if(filenm == '42nd-Commercial'){
      if(!type){
        ndf <- read.traffic.counts()
      }
      if(type){
        ndf <- read.traffic.counts(filenm, file.df$vcrange[1], type=TRUE)
      }
    }else{
      i <- which(file.df$filename == filenm)
      if(!type){
        df <- read.traffic.counts(filenm, file.df$range[i], file.df$sitename[i], file.df$ishour[i])
      }
      if(type){
        df <- read.traffic.counts(filenm, file.df$vcrange[i], type=TRUE)
      }
      df <- df[,names(ndf)]
      ndf <- rbind(ndf, df)
    }
  }
  return(ndf)
}

# read raw data spreadsheets for the regional traffic counts
read.traffic.counts <- function(filename="42nd-Commercial", range="A1:F95", sitename="Counter \r\nSite", ishour=TRUE, type=FALSE){
  library(readxl)
  inpath <- "T:/Data/COUNTS/Motorized Counts/Regional Traffic Counts Program/Central Lane Motorized Count Program/"
  data.path <- paste0(inpath, "data/October2019/")
  if(!type){
    if(ishour){
      df <- read_xlsx(paste0(data.path, filename, ".xlsx"), sheet=1, range = range) %>%  # TC: traffic counts
        mutate(Date = as.Date(Date, "%m/%d/%Y", tz = "America/Los_Angeles"), 
               Hour = format(Hour, "%I:%M %p")) %>%
        filter(!is.na(Total)) %>%
        rename(Site = sitename, Time = Hour)      
    }
    if(!ishour){
      df <- read_xlsx(paste0(data.path, filename, ".xlsx"), sheet=1, range = range) %>%
        mutate(Date = as.Date(Date, "%m/%d/%Y", tz = "America/Los_Angeles"), 
               Time = format(Time, "%I:%M %p")) %>%
        rename(Site = sitename)
    }
  }
  if(type){
    df <- read_xlsx(paste0(data.path, filename, ".xlsx"), sheet=1, range = range) %>%
      select_all(~gsub("\\s+|\\.", "", .))
  }
  return(df)
}