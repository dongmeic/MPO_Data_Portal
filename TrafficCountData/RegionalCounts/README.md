# Explanations

The regional traffic counts include data continuously collected in the Fall (October - December) and Spring (April - June) started from Fall 2019. The Spring 2020 data is missing due to the pandemic. The collection month is not consistent among years. 

## Source data

Data are provided by Shashi Bajracharya (Sr. Engineering Associate, shashi.bajracharya@lanecountyor.gov). The downloaded data is saved in T:\Data\COUNTS\Motorized Counts\Regional Traffic Counts Program\Central Lane Motorized Count Program\data. The data format is not consistent and so data cleaning is a must. The data table to update is T:\Tableau\tableauRegionalCounts\Datasources\Traffic_Counts_Oct2019_Vehicles.csv.

## Dashboard update

The dashboard shows the map of traffic counts and hourly traffic counts by vehicle type, and time table by site. 

### Steps to update the dashboard

1. When data is downloaded, review the completness and format, and follow up with the data provider if there are issues. 

2. Run the script *Traffic_Counts.r* and update Tableau viz following the steps described in *RegionalCountsUpdate.txt* located at \\clsrv111.int.lcog.org\transpor\Tableau\tableauRegionalCounts\Workbooks. 

3. Data cleaning is required for each data update. Check the data source to understand the required table format and update the R scripts to get the target tables and *RegionalCountsUpdate.txt* for future reference.

Notes on data cleaning:

The output should include "Site","Direction","Date","Day","Time","Total","Longitude","Latitude","owner","YEAR","SEASON","Location_d","VehicleType","VehicleQty". The format looks like below:

1,"N",2019-10-22,"Tuesday","10:00 AM",434,-122.963280802637,44.0442970391097,"SPR",2019,"FALL","42nd South of Main","MotorBikes",2

Since Fall 2020, the data format has been adjusted to:

"Site","Direction","Date","Day","Time","Total","VehicleType","VehicleQty","Longitude","Latitude","owner","YEAR","SEASON","Location_d"
1,"N","2019-10-22","Tuesday","10:00 AM",434,"MotorBikes",2,-122.963280802637,44.0442970391097,"SPR",2019,"FALL","42nd South of Main"

4. The regional traffic counts dashboards are combined with the ODOT counts [here](https://www.lcog.org/thempo/page/motorized-traffic-counts).