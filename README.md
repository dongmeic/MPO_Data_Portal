# MPO Data Portal Explanations
By Dongmei Chen (dchen@lcog.org)

June 2020

This is a repository to track the data wrangling process for the [Central Lane Metropolitan Planning Organization Data Portal](https://www.lcog.org/thempo/page/data). The process is coded in R. The repo folders are organized by data categories: crash, transit, traffic count, population, and commuter. Each folder includes a README.md to explain the data sources and data processing in the R scripts.

## Commuter Data

The [**CommuterData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/CommuterData) folder includes the script *ModeShare.r* to organize data tables for the viz [Commute Mode Shares](https://www.lcog.org/thempo/page/commuter-mode-shares) and [Length of Commute](https://www.lcog.org/thempo/page/length-commute). The viz [Local & Regional Commute Patterns](https://www.lcog.org/thempo/page/local-regional-commute-patterns) requires two csv files [`or_od_main_JT01_{YEAR}.csv`](https://lehd.ces.census.gov/data/#lodes) and [`or_xwalk.csv`](https://lehd.ces.census.gov/data/lodes/LODES7/or/). Update the data sources in Tableau on the join.

## Crash Data

The [**CrashData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/CrashData) folder includes scripts *SafetyEmphasisAreas.r* to define and calculate variables in the [Transportation Safety Emphasis Areas](https://www.lcog.org/thempo/page/transportation-safety-emphasis-areas) viz, and *US_FARS.r* to organize [VMT](https://www.fhwa.dot.gov/policyinformation/statistics/2020/vm2.cfm) (Note: edit the year information on the website link to get the most recent year data) and [FARS](https://www-fars.nhtsa.dot.gov/States/StatesCrashesAndAllVictims.aspx) data for the [FARS Data](https://www.lcog.org/thempo/page/fars-data) viz.

## Population Data

The [**PopulationData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData) folder includes the script *Census_TitleVI.r* to define the variables and organize data for the [Socio-economic Data](https://www.lcog.org/thempo/page/socio-economic-data) viz.

## Traffic Count Data

The [**TrafficCountData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/TrafficCountData) folder includes scripts *ODOT_Counts.r* and *ODOT_Counts_Functions.r* to organize ODOT counts for the [Motorized Traffic Counts](https://www.lcog.org/thempo/page/motorized-traffic-counts) viz.

## Transit Data

The [**TransitData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/TransitData) folder includes scripts *LTDTransit.r* to organize LTD passenger counts and merge with stop coordinates for the [Transit Ridership Data](https://www.lcog.org/thempo/page/transit-ridership-data) viz, and *Bikes_on_Buses.r* to organize LTD bike counts and merge with stop coordinates for the [Bikes on Buses](https://www.lcog.org/thempo/page/bikes-buses) viz.

## When to Update

1. When ACS 5Y data is published, update the Title VI dashboard and maps first and the commuter data and population data when all data sources available;

2. When crash data is published, update the crash maps first and the rest in the crash data category when other data sources are updated;

3. Traffic count data and transit data are updated when requesting data from agencies, and the frequency can be flexible.

## SQL database

To organize data sources in one place, all the regularly-updated data sets are uploaded to the GIS_CLMPO database in RLID. The data update process is recreated using python. 

### steps to organize the database

1. Review the data tables in the "Datasources";

2. Organize the tables in the SQL database;

3. Test the data links and edit data connection on Tableau
