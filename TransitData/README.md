# Explanations

Two dashboards [Transit Ridership Data](https://www.lcog.org/thempo/page/transit-ridership-data) and [Bikes on Buses](https://www.lcog.org/thempo/page/bikes-buses) are included in this data category. They are updated twice a year in Spring and Fall, until there is a recent update request on the monthly ridership data since 2017 from LTD. The script [LTDTransitMonthly.r](https://github.com/dongmeic/MPO_Data_Portal/blob/master/TransitData/LTDTransitMonthly.r) is used to update the monthly ridership data. The routes are [updated](https://github.com/dongmeic/MPO_Data_Portal/blob/master/TransitData/update_LTD_routes.ipynb) based on data availability.

## Data Sources

Data on the counts of passengers and bikes on the buses are provided by LTD via email. The data is save in T:\Data\LTD Data\BoardingSince2011 and T:\Data\LTD Data\MonthlyBoardings.

## Steps
1. Update the functions according to data needs;
2. Update the stops folder and routes if new data available;
3. run data update;
4. refresh Tableau extract;
5. make a data copy;
6. update the MPO web content as needed.

## Functions

A list of functions are applied to organize counts data and merge them with the stops to have stable coordinates.

The format for data cleaning on passenger counts:

 | stop  | srv | date | block | trip_end | time | route | dir | stop_name | bus | odometer | ons | offs | load | longitude | latitude | Season | MonthYear |

 | 00001 | wkd | 2012-10-05 00:00:00 | 2 | 1899-12-31 10:56:00 | 1899-12-31 10:46:00 | 11 | O | E/S of 58th N of Main | 1114 | 84.26 | 0 | 3 | 5 | -122.9267 | 44.04634 | Fall 2012 | October 2012 |

 The format for data clearning on bike counts:

 | stop | srv | date | block | trip_end | time | route | dir | stop_name | bus | odometer | desc | qty | longitude | latitude | Season | MonthYear | DailyRtQty | DailyQty |

| 00001 | wkd | 2013-02-26 | 53 | 2021-06-16 16:15:00 | 2021-06-16 16:02:00 | 11 | O | E/S of 58th N of Main | 1121 | 122.04 | bike on rack | 1 | -122.9267 | 44.04634 | Spring 2013 | February 2013 | 76 | 624 |

The routes shapefile should be updated with the same time period, for example, "October 2021", even if the routes haven't changed since 2019.
