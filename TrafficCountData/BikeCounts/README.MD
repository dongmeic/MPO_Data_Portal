# Explanations

The bike counts are collected by Lane Council of Governments. Kyle Overstake is responsible for the bike counter maintenance and raw data collection and aggregation. To prepare for the Tableau source data, he used the R scripts developed by a former staff Josh Roll who is now working at ODOT. 

## Source data

The source data is T:\Data\COUNTS\Nonmotorized Counts\Summary Tables\Bicycle\Bicycle_HourlyForTableau.csv. Make a copy in T:\Tableau\tableauBikeCounts\Datasources. Another two tables are *Average_Daily_Bike_Counts_Permanent.csv* and *Daily_Bike_Counts_Permanent.csv*, updated from running the script [daily_bike_counts.R](https://github.com/dongmeic/MPO_Data_Portal/blob/master/TrafficCountData/BikeCounts/daily_bike_counts.R). 

## Dashboard update

The dashboard [bicycle counts](https://www.lcog.org/thempo/page/bicycle-counts) includes two viz "Bicycle Counts" and "AADBT". The first viz can be updated by refreshing the extracts. The second viz requires a script running to get the source data first. 

### Steps to update the dashboard

1. To update the second viz "AADBT", run the script [daily_bike_counts.R](https://github.com/dongmeic/MPO_Data_Portal/blob/master/TrafficCountData/BikeCounts/daily_bike_counts.R) to get the tables *Average_Daily_Bike_Counts_Permanent.csv* and *Daily_Bike_Counts_Permanent.csv*. Skip this step if only to update the first viz "Bicycle Counts". 

2. Refresh the extracts once the source data is ready. 