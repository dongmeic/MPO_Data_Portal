# Explanations

Two dashboards were originally in this data category and the [Population Data](https://www.lcog.org/thempo/page/population-data) has been first updated in 2019 by Bill Clingman. The script *Census_TitleVI.r* organizes data for the [Socio-Economic Data dashboard](https://www.lcog.org/thempo/page/socio-economic-data) (Title VI). The sript *TitleVI_Lane_Douglas.r* creates a 'Communities of Concern' dashboard for 9 census tracts in Lane County outside MPO and 2 census tracts in Douglas County.  

The [Population Data](https://www.lcog.org/thempo/page/population-data) dashboard has been further updated on December 15, 2020, by Dongmei Chen. Another dashboard on vehicle miles traveled (VMT) and population was added to this data category at the same time, using the same population data. The data sources are explained [below](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData#data-sources-for-vmt-and-population). The script *VMT_Pop.r* cleans data for the time-series VMT and population plots.

## Data Sources for the Title VI dashboards

Data from ten tables (1 - 10) within block group, one table (11) within census tract (for 1 year and 5 year respectively), and nine tables (12 - 19) were collected for the Title VI dashboard (the links are updated with the most-recent data, as current as 2019):

1. [B01003 Total Population](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B01003&hidePreview=false&cid=B01003_001E&vintage=2019)

2. [B01001 Sex By Age 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B01001&hidePreview=false&cid=B01003_001E&vintage=2019)

3. [B03002 Hispanic Or Latino Origin By Race 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B03002&hidePreview=false&cid=B01003_001E&vintage=2019) 

4. [B16004 Age By Language Spoken At Home By Ability To Speak English For The Population 5 Years And Over](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B16004&hidePreview=false&cid=B01003_001E&vintage=2019) 

5. [B17017 Poverty Status In The Past 12 Months By Household Type By Age Of Householder 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B17017&hidePreview=false&cid=B01003_001E&vintage=2019)

6. [B23025 Employment Status For The Population 16 Years And Over 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B23025&hidePreview=false&cid=B01003_001E&vintage=2019)

7. [B25002 Occupancy Status 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B25002&hidePreview=false&cid=B01003_001E&vintage=2019)

8. [B25008 Total Population In Occupied Housing Units By Tenure 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B25008&hidePreview=false&cid=B01003_001E&vintage=2019)

9. [B25010 Average Household Size Of Occupied Housing Units By Tenure 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B25010&hidePreview=false&cid=B01003_001E&vintage=2019)

10. [B25044 Tenure By Vehicles Available 5Y](https://data.census.gov/cedsci/table?g=0500000US41039.150000&tid=ACSDT5Y2019.B25044&hidePreview=false&cid=B01003_001E&vintage=2019)

11. [B18101 Sex By Age By Disability Status 5Y](https://data.census.gov/cedsci/table?t=Disability&g=0500000US41039.140000&tid=ACSDT5Y2019.B18101)

The 1-year data is limited in the Eugene, OR Urbanized Area (2010) Geography. Uncheck the 5-year option before downloading data.

12. [B01001 Sex By Age 1Y](https://data.census.gov/cedsci/table?g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B01001&hidePreview=false)

13. [B03002 Hispanic Or Latino Origin By Race 1Y](https://data.census.gov/cedsci/table?q=B03002&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B03002&hidePreview=false)

14. [B17017 Poverty Status In The Past 12 Months By Household Type By Age Of Householder 1Y](https://data.census.gov/cedsci/table?q=B17017&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B17017&hidePreview=false)

15. [B23025 Employment Status For The Population 16 Years And Over 1Y](https://data.census.gov/cedsci/table?q=B23025&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B23025&hidePreview=false)

16. [B25002 Occupancy Status 1Y](https://data.census.gov/cedsci/table?q=B25002&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B25002&hidePreview=false)

17. [B25008 Total Population In Occupied Housing Units By Tenure 1Y](https://data.census.gov/cedsci/table?q=ACSDT1Y2019.B25008&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B25008&hidePreview=false)

18. [B25010 Average Household Size Of Occupied Housing Units By Tenure 1Y](https://data.census.gov/cedsci/table?q=B25010&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B25010&hidePreview=false)

19. [B25044 Tenure By Vehicles Available 1Y](https://data.census.gov/cedsci/table?q=ACSDT1Y2019.B25044&g=400C100US28117&d=ACS%201-Year%20Estimates%20Detailed%20Tables&tid=ACSDT1Y2019.B25044&hidePreview=false)

20. [B18101 Sex By Age By Disability Status 1Y](https://data.census.gov/cedsci/table?t=Disability&g=400C100US28117&tid=ACSDT1Y2019.B18101&hidePreview=false)


Data sets are downloaded and saved in T:\Data\CENSUS\ACS20152019 and output is expported as T:\Tableau\tableauTitleVI\Datasources\MPO_BG_TitleVI.shp. Data sources for the 'Communities of Concern' dashboard includes Tables 2 (B01001, 'elderly'), 3 (B03002, 'minority'), 5 (B17017, 'poverty'), and 11 (B18101, 'disabled'). 

## Functions 
Two main functions are applied to read and reorganize the tables to the input files: *readtable* to read the raw data, remove unused rows and columns, and convert the values from character to numeric for the 5-year data and *read1yrtable* does the same for the 1-year data.

## Explanations of the Title VI variables

### Variable calculation in the script *Census_TitleVI.r* using the tables

The metadata of each table can be found from downloading the table, or searching online.  

**1) B01001 - Sex by age**

ps_65plus (population size on 65 year old and above): sum of the fields 020E to 025E, 044E to 049E

pc_65plus (population percentage on 65 year old and above): ppcount_65plus divided by 001E

ps_5plus (population size on 5 year old and above): 001E minus 003E and 027E (total population minus the count of male and female that are younger than 5-year old)

pc_5plus: ps_5plus divided by 001E

**2) B03002 - Hispanic or latino origin by race**

hislati_nowhal (population size on hispanic or latino and/or not white alone): 001E minus 003E

pc_hislati_nowhal (population percent on hispanic or latino and/or not white alone): hislati_nowhal divided by 001E

pc_hislati (population percent on hispanic or latino): 001E minus 002E and the result is divided by 001E

**3) B16004 - Age by language spoken at home by ability to speak English for the population 5 years and over**

en_nvwell (people who do not speak very well English): sum of the fields 006E to 008E, 011E to 013E, 016E to 018E, 021E to 023E, 028E to 030E, 033E to 035E, 038E to 040E, 043E to 045E, 050E to 052E, 055E to 057E, 060E to 062E, 065E to 067E

pc_en_nvwell (percent of people who do not speak very well English): en_nvwell divided by 001E

sp_en_nvwell (Spanish speakers who do not speak very well English): sum of the fields 006E to 008E, 028E to 030E, 050E to 052E

ine_en_nvwell (Indo-European languages speakers who do not speak very well English): sum of the fields 011E to 013E, 033E to 035E, 055E to 057E

asp_en_nvwell (Asian and Pacific Island languages speakers who do not speak very well English): sum of the fields 016E to 018E, 038E to 040E, 060E to 062E

oth_en_nvwell (other languages speakers who do not speak very well English): sum of the fields 021E to 023E, 043E to 045E, 065E to 067E

ps_sp (population size of Spanish speakers): sum of the fields 004E, 026E, 048E

ps_ine (population size of Indo-European languages speakers): sum of the fields 009E, 031E, 053E

ps_asp (population size of Asian and Pacific Island languages speakers): sum of the fields 014E, 036E, 058E

ps_oth (population size of other languages speakers): sum of the fields 019E, 041E, 063E

pc_sp_en_nvwell (percent of Spanish speakers who do not speak very well English): sp_en_nvwell divided by ps_sp if not zero

pc_ine_en_nvwell (percent of Indo-European languages speakers who do not speak very well English): ine_en_nvwell divided by ps_ine if not zero

pc_asp_en_nvwell (percent of Asian and Pacific Island languages speakers who do not speak very well English): asp_en_nvwell divided by ps_asp if not zero

pc_oth_en_nvwell (percent of other languages speakers who do not speak very well English): oth_en_nvwell divided by ps_oth if not zero

**4) B17017 - Poverty status in the past 12 months by household type by age of householder**

**5) B23025 - Employment status for the population 16 years and over**

pc_unemp (percent of unemployed people): 005E divided by 002E

pc_16older_wf (percent of 16 and older in workforce): 002E divided by 001E

**6) B25002 - Occupancy status**

occu_rate (occupancy rate): 002E divided by 001E

**7) B25008 - Total population in occupied housing units by tenure**

**8) B25010 - Average household size of occupied housing units by tenure**

**9) B25044 - Tenure by vehicles available**

zero_car (total zero-car households): 003E plus 010E

pc_rtr_0car (percent of zero-car household which are renters): 010E divided by zero_car

pc_own_0car (percent of zero-car household which are owners): 003E divided by zero_car

pc_rtr (percent of renters in all households): 009E divided by 001E

pc_zero-car (percent of zero-car households): zero_car divided by 001E

**10) B18101 - Sex by age by disability status (tract only)**
ps_ni_5plus (total 5-year-and-older non-institutionalized population): (002E - 003E) + (021E - 022E)

ps_ni_5plus_dis (total 5-year-and-older non-institutionalized population with disability): sum of the fields 007E, 010E, 013E, 016E, 019E, 026E, 029E, 032E, 035E, 038E

pc_ni_5plus_dis (percent of 5-year-and-older non-institutionalized population with disability): ps_ni_5plus_dis divided by ps_ni_5plus

pc_ni_5plus (percent of 5-year-and-older non-institutionalized population): ps_ni_5plus divided by 001E

### Variable explanations in the block group data

The explanation after the comma is either the source column or the calculated variable explained [above](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData#variable-calculation-in-the-script-census_titlevir-using-the-tables). Find (crtl/cmd + F) the variable name on the page to look for the definition of the variable. The source column name explanation can be found from downloading the table, or searching online.  

[1] "or_blockgr" - block group ID

[2] "BlkGrp10" - block group ID 

[3] "TotalPOP" - total population, B01001_001E

[4] "HHPop" - household population, B25008_001E   

[5] "GQPop" - group quarters population, the difference between total population and household population, TotalPOP - HHPop  

[6] "TotalDU" - total dwelling units, B25002_001E

[7] "HH" - total household size in the poverty status table, B17017_001E  

[8] "PopWrkF16" - total population of 16-year-and-older in workforce, B23025_002E 

[9] "PopGE5" - total population of 5-year-and-older, B16004_001E  

[10] "PopNInst5" - non-institutionalized population of 5-year-and-older, using the rate from census tract calculation pc_ni_5plus 

[11] "HHsize" -  household size from B25010_001E   

[12] "Occupancy" - B25002_002E (occupied) divided by B25002_001E (total)

[13] "PctMinor" - percent of minority (B03002_001E - B03002_003E)/B03002_001E 

[14] "PctElderly" - percent of elderly, pc_65plus

[15] "PctLEP" - percent of limited English proficiency, pc_en_nvwell 

[16] "PctPoor" - percent of poor, B17017_002E / B17017_001E  

[17] "PctHH0car" - percent of zero-car households, pc_zero_car  

[18] "PctUnEmp" - percent of unemployment, B23025_005E / B23025_002E 

[19] "PctDisab" - percent of disable, pc_ni_5plus_dis from census tract data

[20] "PopMinor" - minority population, B03002_001E - B03002_003E

[21] "PopEld" - elderly population, ps_65plus 

[22] "Pop5yrLEP" - population of limited English proficiency, en_nvwell  

[23] "HHPoor" -  households below poverty level, B17017_002E 

[24] "HH0car" -  zero-car households, zero_car 

[25] "PopWFUnEmp" - unemployed population of 16-year-and-older workforce, B23025_005E

[26] "PopNI5Disa" - disable population, using the rate from census tract calculation pc_ni_5plus_dis 

[27] "Minority" - whether percent of minority is higher than the MPO-wide average 

[28] "Elderly" - whether percent of minority is higher than the MPO-wide average  

[29] "LEP" - whether percent of limited English proficiency is higher than the MPO-wide average 

[30] "Poor" - whether percent of poor is higher than the MPO-wide average   

[31] "HHzerocar" - whether percent of zero-car households is higher than the MPO-wide average  

[32] "Disabled" - whether percent of disable is higher than the MPO-wide average   

[33] "ComofConce" - sum of Minority, Elderly, Poor and Disabled

[34] "Shape_Leng" - shape length (from shapefile)

[35] "Shape_Area"- shape area (from shapefile)

[36] "PctRentHH" - percent of renter household, pc_rtr 

[37] "RenterHHs" - renter household, B25044_009E

[38] "Renter" - whether percent of renter household is higher than the MPO-wide average   

[39] "OwnHHNoCar" - zero-car households which are owners, B25044_003E

[40] "RntHHNoCar" - zero-car households which are renters, B25044_010E

[41] "UnEmp" - whether percent of unemployment is higher than the MPO-wide average

## Download links for the CLMPO Title VI data

ArcMap or ArcGIS Pro is required for reading the feature layer and web map locally. The links are updated automatically with the most-recent data, as current as 2019. 

[Service Definition](https://lcog.maps.arcgis.com/home/item.html?id=4e6c93c4183c46fd90bd1b95edee800d) 

[Feature Layer](https://lcog.maps.arcgis.com/home/item.html?id=bff06c500d9c4749b047fbd7d0ab7a21)

[Shapefile](https://lcog.maps.arcgis.com/home/item.html?id=f17c5c349aa9407ab1d48338850ced05)

[Web Map](https://lcog.maps.arcgis.com/home/item.html?id=000d1aaae6144808bf76a113577a939e)

## Download links for the CLMPO Title VI PDF maps
[2014 - 2018](https://lanecouncilofgovernments-my.sharepoint.com/:f:/g/personal/dchen_lcog_org/EnM3omAabelNpQDt35dX4ckBM1NmZuAhahaobDWw3e56Bg?e=OVqQE2)

[2015 - 2019](https://lanecouncilofgovernments-my.sharepoint.com/:f:/g/personal/dchen_lcog_org/Er0KHmKTvEFEjhmNqK51C48BORpezlfErRSnMB0VR81lzw?e=qaxBsW) 

## A data requrest related to Title VI from Springfield on July 2021

City of Springfield requested the block group data for the Springfield area that shows zero car households and poverty in a map that can be zoomed into. The spatial data for the Springfield area can be downloaded [here](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData/TitleVI_Download). The dashboard [Zero-car households and households below poverty level by city](https://public.tableau.com/views/Zero-carhouseholdsandhouseholdsbelowpovertylevelbycity/TitleVI?:language=en-US&:display_count=n&:origin=viz_share_link) is also created for the data request. To download the selected data from the dashboard, click Download on the bottom right, choose a file format (recommend Data or Crosstab), confirm the download and make notes on the data. The column "ShowVar" indicates the variable selected and the column values are the values for the selected variable. Other variables are explained [above](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData#variable-explanations-in-the-block-group-data), and you can search the variable name on the page. You can also download the complete MPO Title VI spatial data [here](https://github.com/dongmeic/MPO_Data_Portal/tree/master/PopulationData#download-links-for-the-clmpo-title-vi-data).

## Steps for the Lane-Douglas communities of concern dashboard

1. Identify variables required and check data sources and output formats

Variables required by checking Tableau dashboard: 'TotalPOP', 'PopEld', 'PctElderly', PctDisab', 'PopNInst5', 'PopNI5Disa', 'PctPoor', 'HH', 'HHPoor', 'PctPoor', 'PopMinor' and 'PctMinor'; the average percentage for the four factors at a certain geography; condition variables - whether the percentage factor is higher than the average (1-yes, 0-no); and finally, 'ComofConce' - the sum of the condition variables. 

* Check the *Census_TitleVI.r* for the detailed calculation of the listed variables above. Need to check whether there is NA in the percentage variables.   

2. Download and organize data

Go to [US Census Advanced](https://data.census.gov/cedsci/advanced), Geogrpahy --> Block Group --> Oregon --> Lane County --> Check the needed census tracts and review the filter before hitting SEARCH. The VIEW ALL TABLES. Select [B01001](https://data.census.gov/cedsci/table?g=1400000US41039001101.150000,41039001102.150000,41039001201.150000,41039001301.150000,41039001302.150000,41039001400.150000,41039001700.150000,41039000800.150000,41039001202.150000&tid=ACSDT5Y2019.B01001&layer=VT_2019_150_00_PY_D1&vintage=2019&hidePreview=false&cid=B00001_001E), [B03002](https://data.census.gov/cedsci/table?g=1400000US41039001101.150000,41039001102.150000,41039001201.150000,41039001301.150000,41039001302.150000,41039001400.150000,41039001700.150000,41039000800.150000,41039001202.150000&tid=ACSDT5Y2019.B03002&layer=VT_2019_150_00_PY_D1&vintage=2019&hidePreview=false&cid=B00001_001E), and [B17017](https://data.census.gov/cedsci/table?g=1400000US41039001101.150000,41039001102.150000,41039001201.150000,41039001301.150000,41039001302.150000,41039001400.150000,41039001700.150000,41039000800.150000,41039001202.150000&tid=ACSDT5Y2019.B17017&layer=VT_2019_150_00_PY_D1&vintage=2019&hidePreview=false&cid=B00001_001E). Need to scroll down and load more for the later tables. Hit Download and check the three tables. Scroll up to hit Download Selected (3) on the top left. Then hit DOWNLOAD on the bottom right. The default year is the most recent one. Finally, hit Download Now after file loading. 

Repeat the same process for the table [B18101](https://data.census.gov/cedsci/table?g=1400000US41039001101,41039001102,41039001201,41039001202,41039001301,41039001302,41039001400,41039001700,41039000800&layer=VT_2019_140_00_PY_D1&tid=ACSDT5Y2019.B18101&vintage=2019&hidePreview=false&cid=S0101_C01_001E), but select Tract instead of Block Group. You can also edit the webpage link on the table name to get the table. Uncheck the 1-Year option and hit DOWNLOAD.

Repeat the above two steps for Douglas County. Use the same links and edit the filters.
[B01001](https://data.census.gov/cedsci/table?q=B01001&g=1400000US41019030000.150000,41019040000.150000&tid=ACSDT5Y2019.B01001&hidePreview=false)
[B03002](https://data.census.gov/cedsci/table?q=B03002&g=1400000US41019030000.150000,41019040000.150000&tid=ACSDT5Y2019.B03002&hidePreview=false)
[B17017](https://data.census.gov/cedsci/table?q=B17017&g=1400000US41019030000.150000,41019040000.150000&tid=ACSDT5Y2019.B17017&hidePreview=false)
[B18101](https://data.census.gov/cedsci/table?q=B18101&g=1400000US41019030000,41019040000&tid=ACSDT5Y2019.B18101&hidePreview=false)

Extract and save files at T Drive (\\clsrv111.int.lcog.org\transpor\Data\CENSUS\ACS20152019\TitleVI\Others\). 

Download Oregon block group boundary from [TIGER/Line](https://www.census.gov/cgi-bin/geo/shapefiles/index.php?year=2019&layergroup=Block+Groups). Save separately block groups of Lane (COUNTYFP = '039') and Douglas (COUNTYFP = '019') counties (only to check whether the census tracts are connected)

3. Process data

The detailed data processing steps follow the script *TitleVI_Lane_Douglas.r*, adjusted from the script *Census_TitleVI.r*. Summary data based on both counties combined is joined with the state block group boundary (keep matched ID only). 

4. Visualize data

Read the shapefile in Tableau. Create the map and plots following the 'Communities of Concern' dashboard settings. The dashboard "Lane_Douglas.twb" is saved at T:\Data\CENSUS\ACS20152019\TitleVI\others\processed.

# Data sources for VMT and population

The VMT data can be downloaded from the [ODOT Data and Maps](https://www.oregon.gov/odot/Data/Pages/Traffic-Counting.aspx#VMT). The downloaded VMT data is saved at T:\Data\VMT\VMT_State_and_County. The current population data can be retrieved from both the [PSU population estimates](https://www.pdx.edu/population-research/population-estimate-reports) and [US Census](https://www.census.gov/programs-surveys/decennial-census/decade.2010.html). The [historical state and lane county population](https://lcog.org/DocumentCenter/View/1370/Historical-Population-of-Lane-County-and-Cities) is saved at L:\Research&Analysis\Data\Population\Historical Population\Historical Population.xls. The table *HistoricalPopulation.xlsx* from T:\Tableau\tableauPop\Datasources is updated and used in the viz workbook *VMT_Pop.twb*. The text file *ReadMe_VMT_Pop.txt* in the same folder explains the data and viz update process. The dashboard is combined with the population data dashboard [here](https://www.lcog.org/thempo/page/Population-Data) and the source dashboard is T:\Tableau\tableauPop\Workbooks\CombinedPopData.twb. 
