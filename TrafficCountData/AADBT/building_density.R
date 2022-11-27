
# source: https://towardsdatascience.com/calculating-building-density-in-r-with-osm-data-e9d85c701e19
#loading packages
library(osmdata)
library(dplyr)
library(ggplot2)
library(sf)
library(tmap)
library(tidycensus)
library(tigris)
library(odbc)
options(tigris_use_cache = TRUE)

con <- dbConnect(odbc(),
                 Driver = "SQL Server",
                 Server = "rliddb.int.lcog.org,5433",
                 Database = "RLIDGeo",
                 Trusted_Connection = "True")
sql = "
SELECT 
ugbcity AS city,
Shape.STAsBinary() AS geom
FROM dbo.ugb
WHERE ugbcity IN ('EUG', 'SPR', 'COB');
"
ugb <- st_read(con, geometry_column = "geom", query = sql) %>% 
  st_set_crs(2914) %>% 
  st_transform(4326)
#eug_ugb <- ugb %>% filter(city=='EUG')

#plot
ggplot(eug_ugb) +
  geom_sf()

lane_pop <- get_acs(
  geography = "tract", 
  variables = "B01001_003",
  county = "Lane",
  state = "OR", 
  year = 2020,
  geometry = TRUE
) %>% 
  st_transform(4326)

plot(lane_pop["estimate"])

# clip Eugene census tract
cl_ct = st_intersection(lane_pop, ugb)

#plot
ggplot(cl_ct) +
  geom_sf()

#retrieve bounding box for region of interest 
eug_bbox <- getbb("eugene", featuretype = "city")
spr_bbox <- getbb("springfield, OR", featuretype = "city")
cob_bbox <- getbb("coburg, OR", featuretype = "city")
#"springfield", "coburg"

#retrieve level 8 administrative boundaries 
cl_boundary <- opq(eug_bbox) %>% 
  add_osm_feature(key = "admin_level", value = "8") %>% 
  osmdata_sf() 

cl_boundary

#select only df multipolygons
cl_polys <- cl_boundary$osm_multipolygons 
#%>% filter(name=="Eugene")

#calculate polygon areas for later analysis and append to new column
cl_polys$poly_area <- st_area(cl_polys)

#plot
ggplot(cl_polys) +
  geom_sf()

eug_buildings <- opq(eug_bbox) %>%
  add_osm_feature(key = "building") %>%
  osmdata_sf()

spr_buildings <- opq(spr_bbox) %>%
  add_osm_feature(key = "building") %>%
  osmdata_sf()

cob_buildings <- opq(cob_bbox) %>%
  add_osm_feature(key = "building") %>%
  osmdata_sf()

#get rid of the excess data again. This time I will keep the polygon sf object.
eug_build_polys <- eug_buildings$osm_polygons %>%
  select(osm_id, geometry)
spr_build_polys <- spr_buildings$osm_polygons %>%
  select(osm_id, geometry)
cob_build_polys <- cob_buildings$osm_polygons %>%
  select(osm_id, geometry)

build_polys <- rbind(eug_build_polys, spr_build_polys, cob_build_polys, deparse.level = 1)

#plot the result
ggplot(cl_polys) + 
  geom_sf() + 
  geom_sf(data = build_polys)


#calculate surface area of buildings
build_polys$area <- sf::st_area(build_polys)

#calculate centroids
build_cents <- sf::st_centroid(build_polys)

joined <- st_join(cl_ct, build_polys)
ggplot(joined) +
  geom_sf()
joined$poly_area <- st_area(joined) 

#aggregating and summing total building area
density_calc <- aggregate(joined$area, list(joined$GEOID),
                          FUN = sum, na.rm=TRUE)
#rename columns
colnames(density_calc) <- c("GEOID", "totarea")

#create final df that contains district polygons and building area
bounds_blds_sf <- merge(joined, density_calc, by="GEOID") 

#calculate building density
bounds_blds_sf <- bounds_blds_sf %>%
  mutate(b_dens = totarea/poly_area * 100) %>% 
  filter(as.vector(b_dens) <= 100) %>%
  select(GEOID, geometry, b_dens) 

bounds_blds <- unique(bounds_blds_sf)

outpath <- "T:/DCProjects/Modeling/AADBT/input/shp"
bikeloc <- st_read(file.path(outpath, 'BikeCountsLocations.shp')) %>% 
  st_transform(4326)
#set interactive mode
#tmap_mode('view')
tmap_mode('plot')

#plot with basemap
#tm_basemap("Stamen.TonerLite") +
  tm_shape(bounds_blds) +
  tm_polygons(col="b_dens",
              id="GEOID",
              title= "Building Density as % of Land Area",
              alpha=.8) +
    tm_shape(bikeloc) +
    tm_dots( col='blue', alpha=0.4, size = 0.3)
  
st_write(obj=bounds_blds, 
         dsn=outpath, 
         layer='building_density_census_tract', 
         driver='ESRI Shapefile', 
         delete_layer = TRUE)

