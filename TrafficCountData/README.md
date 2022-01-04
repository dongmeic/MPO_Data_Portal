# Explanations

Three databoards are in this data category and the scripts *ODOT_Counts.r* and *ODOT_Counts_Functions.r* in the **ODOT_Counts** folder are used to update the [Motorized Traffic Counts](https://www.lcog.org/thempo/page/motorized-traffic-counts) dashboard, which is updated monthly or periodically according to data availability. The [Bicycle Counts](https://www.lcog.org/thempo/page/bicycle-counts) and [Pedestrian Counts](https://www.lcog.org/thempo/page/pedestrian-counts) dashboards are managed by Kyle Overstake. The **AADBT** folder includes scripts to model the Annual Average Daily Bicycle Traffic. The **RegionalCounts** folder includes scripts to clean up regional traffic counts data.

## Data Sources

Data on traffic counts with length reports are provided by ODOT via email. Data on [AADBT](https://github.com/dongmeic/MPO_Data_Portal/tree/master/TrafficCountData/AADBT#explanations) are from NOAA, [Eco-Visio](https://www.eco-visio.net/v5/login/#::) and LCOG. Regional traffic counts are provided by Lane County. The downloaded data is saved in T:\Data\COUNTS\Motorized Counts\Regional Traffic Counts Program\Central Lane Motorized Count Program\data.

## Functions

A list of functions in the functions scripts are applied to convert string formats, read Excel sheets and files from a folder, reorganize and combine tables. Functions applied on the computation of AADBT are explained in [the folder](https://github.com/dongmeic/MPO_Data_Portal/tree/master/TrafficCountData/AADBT#explanations).

The first step to organize regional counts data is to review and organize the list of locations and link them to the site data. This step creates an ID column ("Site") to reorder the sampling sites with the order of site data tables in ArcGIS Pro ("T:\Data\COUNTS\Motorized Counts\Regional Traffic Counts Program\Central Lane Motorized Count Program\traffic_count_locations"). Next, review the tables to get the information to fill in the [functions](https://github.com/dongmeic/MPO_Data_Portal/blob/master/TrafficCountData/RegionalCounts/Traffic_Counts_Functions.r) to read table. Then review the functions that were used to process the last data collection and adjust them accordingly. Make sure the location layers include the key fields.
