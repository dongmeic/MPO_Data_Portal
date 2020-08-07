# Explanations

Two dashboards are in this data category and the [Population Data](https://www.lcog.org/957/Population-Data) has been updated in 2019 by Bill Clingman. The script *Census_TitleVI.r* organizes data for the [Socio-Economic Data dashboard](https://lcog.org/958/Socio-Economic-Data) (Title VI). The sript *TitleVI_for_Kyle.r* creates a 'Communities of Concern' dashboard for 9 census tracts in Lane County outside MPO and 2 census tracts in Douglas County.  

## Data Sources

Data from ten tables (1 - 10) within block group and one table (11) within census tract (for 1 year and 5 year respectively) were collected for the Title VI dashboard:

1. [B01003 Total Population](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B01003&hidePreview=false&cid=B01003_001E&vintage=2018)

2. [B01001 Sex By Age](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B01001&hidePreview=false&cid=B01003_001E&vintage=2018)

3. [B03002 Hispanic Or Latino Origin By Race](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B03002&hidePreview=false&cid=B01003_001E&vintage=2018) 

4. [B16004 Age By Language Spoken At Home By Ability To Speak English For The Population 5 Years And Over](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B16004&hidePreview=false&cid=B01003_001E&vintage=2018) 

5. [B17017 Poverty Status In The Past 12 Months By Household Type By Age Of Householder](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B17017&hidePreview=false&cid=B01003_001E&vintage=2018)

6. [B23025 Employment Status For The Population 16 Years And Over](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B23025&hidePreview=false&cid=B01003_001E&vintage=2018)

7. [B25002 Occupancy Status](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B25002&hidePreview=false&cid=B01003_001E&vintage=2018)

8. [B25008 Total Population In Occupied Housing Units By Tenure](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B25008&hidePreview=false&cid=B01003_001E&vintage=2018)

9. [B25010 Average Household Size Of Occupied Housing Units By Tenure](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B25010&hidePreview=false&cid=B01003_001E&vintage=2018)

10. [B25044 Tenure By Vehicles Available](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2018.B25044&hidePreview=false&cid=B01003_001E&vintage=2018)

11. [B18101 Sex By Age By Disability Status](https://data.census.gov/cedsci/table?tid=ACSDT1Y2018.B18101&t=Disability&vintage=2018)

Data sources for the 'Communities of Concern' dashboard includes Tables 2 (B01001, 'elderly'), 3 (B03002, 'minority'), 5 (B17017, 'poverty'), and 11 (B18101, 'disabled'). 

## Functions 
Two main functions are applied to read and reorganize the tables to the input files: *readtable* to read the raw data, remove unused rows and columns, and convert the values from character to numeric for the 5-year data and *read1yrtable* does the same for the 1-year data.

## Steps for Kyle's data requests

1. Identify variables required and check data sources and output formats;

Variables required by checking Tableau dashboard: 'TotalPOP', 'PopEld', 'PctElderly', PctDisab', 'PopNInst5', 'PopNI5Disa', 'PctPoor', 'HH', 'HHPoor', 'PctPoor', 'PopMinor' and 'PctMinor'; the average percentage for the four factors at a certain geography; condition variables - whether the percentage factor is higher than the average (1-yes, 0-no); and finally, 'ComofConce' - the sum of the condition variables. * Need to check whether there is NA in the percentage variables.   

2. Download and organize data;



3. 
