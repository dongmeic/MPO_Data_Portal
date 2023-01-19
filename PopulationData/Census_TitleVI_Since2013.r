
library(readxl)
library(dplyr)
library(sf)

source('T:/DCProjects/GitHub/MPO_Data_Portal/PopulationData/Census_TitleVI_functions.r')

# download <- "C:/Users/clid1852/Downloads/"
# destfolder <- "T:/Data/CENSUS"
# 
# files <- list.files(path = download, pattern = ".txt", all.files = TRUE)
# for(file in files){
#   if(grepl("1Y", file)){
#     file_to_move <- paste0(download, file)
#     move_to_folder <- paste0(destfolder, "/ACS", substr(file, 8, 11))
#     file.copy(file_to_move, move_to_folder)
#     file.remove(file_to_move)
#   }else{
#     file_to_move <- paste0(download, file)
#     end_year <- as.numeric(substr(file, 8, 11))
#     first_year <- end_year - 4
#     move_to_folder <- paste0(destfolder, "/ACS", first_year, end_year, "/TitleVI")
#     file.copy(file_to_move, move_to_folder)
#     file.remove(file_to_move)
#   }
# }

yearlist <- 2013:2021

for(year in yearlist){
  if(year==yearlist[1]){
    df <- get_MPOavg_data(year=year)
  }else{
    ndf <- get_MPOavg_data(year=year)
    df <- rbind(df, ndf)
  }
  print(year)
}

write.csv(df, paste0(outpath, "/TitleVIchangeovertime_review.csv"), 
          row.names = FALSE)

for(year in yearlist){
  if(year==yearlist[1]){
    gdf <- adjust_TitleVI_data(year=year)[[3]]
  }else{
    ngdf <- adjust_TitleVI_data(year=year)[[3]]
    gdf <- rbind(gdf, ngdf)
  }
  print(year)
}

st_write(gdf, dsn = outpath, 
         layer = "MPO_BG_TitleVI_Since2013", 
         driver = "ESRI Shapefile", 
         delete_layer=TRUE, 
         row.names = FALSE)

dat <- adjust_TitleVI_data(year=year)[[1]]
