# Explanations

Two dashboards [Transit Ridership Data](https://lcog.org/903/Transit-Ridership-Data) and [Bikes on Buses Data Explanation](https://lcog.org/906/Bikes-on-Buses) are included in this data category. They are updated twice a year in Spring and Fall. 

## Data Sources

Data on the counts of passengers and bikes on the buses are provided by LTD via email. The data is save in T:\Data\LTD Data\BoardingSince2011. 

## Functions

A list of functions are applied to organize counts data and merge them with the stops to have stable coordinates.

The format for data cleaning:
 stop srv                date block            trip_end                time route dir             stop_name  bus
 00001 wkd 2012-10-05 00:00:00     2 1899-12-31 10:56:00 1899-12-31 10:46:00    11   O E/S of 58th N of Main 1114

odometer ons offs load longitude latitude    Season    MonthYear
    84.26   0    3    5 -122.9267 44.04634 Fall 2012 October 2012

