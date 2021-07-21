# Explanations

Three dashboards are in this data category but the [Local and Regional Commute Patterns](https://www.lcog.org/thempo/page/Local-and-Regional-Commute-Patterns) dashboard uses raw data without further processing with scripts. This dashboad maintenance requires five data tables downloaded from the [US Census Bureau](https://data.census.gov/cedsci/). The work is a continued effort from the former LCOG GIS staff Bill Clingman. The two dashboards including [Commute Mode Share](https://www.lcog.org/thempo/page/commuter-mode-shares) and [Commute Length](https://www.lcog.org/thempo/page/length-commute) are updated annually. To update these two dashboards, the script requires three input files: ModeShare_ALL_Years.csv (from B08301), ModeByVehiclesAvailable_AllYears.csv (from B08141), and ModeByPovertyStatus_AllYears.csv (from B08122).   

## Data Sources

The tables below are downloaded and saved in `T:\Data\TranspData for Web\JTW_AllYears\JTW ACS 5-Yr All Years` in the folders matched with the table names.

1. [B08301 Means Of Transportation To Work](https://data.census.gov/cedsci/table?q=B08301&tid=ACSDT5Y2019.B08301&g=1600000US4114400,4123850,4169600_400C100US28117,78229)

2. [B08302 Time Leaving Home To Go To Work](https://data.census.gov/cedsci/table?q=B08302&tid=ACSDT5Y2019.B08302&g=1600000US4114400,4123850,4169600_400C100US28117,78229)

3. [B08303 Travel Time To Work](https://data.census.gov/cedsci/table?tid=ACSDT5Y2019.B08303&g=1600000US4114400,4123850,4169600_400C100US28117,78229)

4. [B08122 Means Of Transportation To Work by Poverty Status](https://data.census.gov/cedsci/table?tid=ACSDT5Y2019.B08122&g=1600000US4114400,4123850,4169600_400C100US28117,78229)

5. [B08141 Means Of Transportation To Work by Vehicles Available](https://data.census.gov/cedsci/table?tid=ACSDT5Y2019.B08141&g=1600000US4114400,4123850,4169600_400C100US28117,78229)

The links above are different only on the table ID. Below descibes how to get the link: 
1. Vist [the website](https://data.census.gov/cedsci/advanced);

2. Geography --> Select "Principal City" --> Type in Eugene, Coburg and Springfield;

3. Check "Show Summary Levels" --> Select "400 - Urban Area" --> Type in Eugene, Salem;

4. Hit "Search" after the geographies are all selected;

5. View all table, scroll down and choose the table ID.

## Steps to update the dashboard

1. Download tables from the above [links](https://github.com/dongmeic/MPO_Data_Portal/tree/master/CommuterData#data-sources), extract and save the tables in the specific folders;

2. Review and update the input files based on the [R script](https://github.com/dongmeic/MPO_Data_Portal/blob/master/CommuterData/ModeShare.r);

3. Refresh all extracts in `ModeShare_DC.twb` and `CommuteLength_DC.twb` in the T:\Tableau\tableauJourneyToWork\Workbooks folder. 

## Functions
Four functions are applied to read and reorganize the tables to get the input files: *readtable* to read the raw data, remove unused rows and columns, and convert the values from character to numeric; *get.data.by.mode* to reorganize the table B08141 and calculate mode share percent; *add.colon* to add colon to the time format from the tables B08302 and B08303; *get.time.data* to reorganize the tables B08302 and B08303 and calculate share percent.   

