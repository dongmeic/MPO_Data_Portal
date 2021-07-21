# MPO Data Portal Explanations
By Dongmei Chen (dchen@lcog.org)

June 2020

This is a repository to track the data wrangling process for the [Central Lane Metropolitan Planning Organization Data Portal](https://www.thempo.org/887/Data). The process is coded in R. The repo folders are organized by data categories: crash, transit, traffic count, population, and commuter. Each folder includes a README.md to explain the data sources and data processing in the R scripts.

## Crash Data

The [**CrashData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/CrashData) folder includes scripts *SafetyEmphasisAreas.r* to define and calculate variables in the [Transportation Safety Emphasis Areas](https://www.thempo.org/912/Transportation-Safety-Emphasis-Areas) viz, and *US_FARS.r* to organize [VMT](https://www.fhwa.dot.gov/policyinformation/statistics/2018/vm2.cfm) (Note: edit the year information on the website link to get the most recent year data) and [FARS](https://www-fars.nhtsa.dot.gov/States/StatesCrashesAndAllVictims.aspx) data for the [FARS Data](https://www.lcog.org/920/FARS-Data) viz.

## Transit Data

The [**TransitData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/TransitData) folder includes scripts *LTDTransit.r* to organize LTD passenger counts and merge with stop coordinates for the [Transit Ridership Data](https://www.thempo.org/903/Transit-Ridership-Data) viz, and *Bikes_on_Buses.r* to organize LTD bike counts and merge with stop coordinates for the [Bikes on Buses](https://www.thempo.org/906/Bikes-on-Buses) viz.  

## Traffic Count Data

The [**TrafficCountData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/TrafficCountData) folder includes scripts *ODOT_Counts.r* and *ODOT_Counts_Functions.r* to organize ODOT counts for the [Motorized Traffic Counts](https://www.thempo.org/902/Motorized-Traffic-Counts) viz.

## Population Data

The [**PopulationData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData) folder includes the script *Census_TitleVI.r* to define the variables and organize data for the [Socio-economic Data](https://www.thempo.org/958/Socio-Economic-Data) viz.


## Commuter Data

The [**CommuterData**](https://github.com/dongmeic/MPO_Data_Portal/tree/master/CommuterData) folder includes the script *ModeShare.r* to organize data tables for the viz [Commute Mode Shares](https://www.lcog.org/thempo/page/commuter-mode-shares) and [Length of Commute](https://www.lcog.org/thempo/page/length-commute). The viz [Local & Regional Commute Patterns](https://www.lcog.org/thempo/page/local-regional-commute-patterns) requires two csv files [`or_od_main_JT01_{YEAR}.csv`](https://lehd.ces.census.gov/data/#lodes) and [`or_xwalk.csv`](https://lehd.ces.census.gov/data/lodes/LODES7/or/). Update the data sources in Tableau on the join.

