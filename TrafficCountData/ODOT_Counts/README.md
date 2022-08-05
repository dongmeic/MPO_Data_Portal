# Explanations

The ODOT traffic counts include data primarily from 14 stations and counts with length reports.

## Source data

Data are provided by Josh Lucas (Traffic Data Analyst, Josh.lucas@odot.state.or.us).

## Dashboard update

The [dashboard](https://thempo.org/902/Motorized-Traffic-Counts) shows the spatial and temporal patterns of the counts and it has been updated to April 2021. There is no length data for Oct 2020 due to a data migration issue when ODOT shift to a new database (Oregon Traffic Monitoring System).

### Steps to update the dashboard

1. When data is downloaded, review the completness and format, and follow up with ODOT if there are issues. The existing format can be found in \\clsrv111.int.lcog.org\transpor\Data\COUNTS\ODOT_Counts and Forecasts\ATR Downloads by Month\[YEAR]. ODOT has changed the data format in March and October 2020. 

2. Run the script *ODOT_Counts.r* and update Tableau viz following the steps described in *ODOTCountsUpdateSince2020.txt* located at \\clsrv111.int.lcog.org\transpor\Tableau\tableauODOTCounts\Datasources. 

3. If the data format has changed, data clearning needs to be started over. Check the data source to understand the required table format and update the R scripts to get the target tables and *ODOTCountsUpdateSince2020.txt* for future reference.

Notes on data cleaning:

The output should include "StationID", "Direction", "Date", "Day", "Hour", and "Count". The format looks like below:

"20004","WB","10/01/2011","Sat","1:00 AM","10"

The same format shows in the long vehicles data, which include length "35-61" and "61-150". Since the length report in October 2020 is missing due to a data migration issue occurred when ODOT shifted to a new database Oregon Traffic Monitoring System, the dashboards are not synchronized with the same time information.