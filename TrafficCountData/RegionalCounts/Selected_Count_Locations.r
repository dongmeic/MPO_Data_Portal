# This script was created to select some regional count locations for lane county

# Notes from Syd on the locations
# City of Eugene
# 
# On Chambers Street south of West 12th Ave
# 
# On Jefferson Street south of West 12th Ave
# 
# On Washington Street south of West 12th Ave
# 
# On 18th Street east of Oak Patch Road Drive
# 
# On Patterson Street south of East 19th Ave
# 
# On Hilyard Street south of East 19th Ave
# 
# On Barger Drive west of Laurelhurst Drive
# 
# On River Road north of Banton Ave
# 
# 
# City of Springfield 
# 
# On 42nd Street near the intersection with E Street
# 
# On 21st Street near the intersection with A Street
# 
# On 21st Street near the intersection with H Street
# 
# On Olympic Street near the intersection with 18th Street
# 
# On Marcola Road near the intersection with 19th Street
# 
# On Marcola Road northeast of 42nd Street
# 
# On 42nd Street north of Mount Vernon Road
# 
# On Hayden Bridge Road west of 19th Street

library(rgdal)

# data_path <- "T:/Tableau/tableauRegionalCounts/Datasources/"
# data <- read.csv(paste0(data_path, "Traffic_Counts_Vehicles.csv"))
# 
# head(data)
# unique(data$Location_d)

inpath <- "T:/Data/COUNTS/Motorized Counts/Regional Traffic Counts Program/Central Lane Motorized Count Program/"
site.path <- paste0(inpath, "traffic_count_locations")
loc <- readOGR(dsn=paste0(site.path, "/traffic_count_locations.gdb"), 
               layer="Nov2021", stringsAsFactors = FALSE)
loc.lonlat <- spTransform(loc, CRS("+init=epsg:4326"))
lonlat.df <- as.data.frame(loc.lonlat@coords)
names(lonlat.df) <- c("Longitude", "Latitude")

loc@data <- cbind(loc@data, lonlat.df)
writeOGR(loc, dsn = site.path, layer = "locations_Nov2021", driver="ESRI Shapefile", overwrite_layer=TRUE)
