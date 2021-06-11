# Explanations

The regional traffic counts include data continuously collected in the Fall (October) and Spring (April). The April 2020 data is missing due to the pandemic. 

## Source data

Data are provided by Shashi Bajracharya (Sr. Engineering Associate, shashi.bajracharya@lanecountyor.gov).

## Dashboard update

The dashboard shows the map of traffic counts and hourly traffic counts by vehicle type, and time table by site. 

### Steps to update the dashboard

1. When data is downloaded, review the completness and format, and follow up with the data provider if there are issues. 

2. Run the script *Traffic_Counts.r* and update Tableau viz following the steps described in *RegionalCountsUpdate.txt* located at \\clsrv111.int.lcog.org\transpor\Tableau\tableauRegionalCounts\Workbooks. 

3. If the data format has changed, data clearning needs to be started over. Check the data source to understand the required table format and update the R scripts to get the target tables and *RegionalCountsUpdate.txt* for future reference.

Notes on data cleaning:

The output should include "Site","Direction","Date","Day","Time","Total","Longitude","Latitude","owner","YEAR","SEASON","Location_d","VehicleType","VehicleQty". The format looks like below:

1,"N",2019-10-22,"Tuesday","10:00 AM",434,-122.963280802637,44.0442970391097,"SPR",2019,"FALL","42nd South of Main","MotorBikes",2
