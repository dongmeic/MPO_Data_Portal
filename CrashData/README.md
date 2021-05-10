# Explanations
Updated on May 10th, 2021

Crash data is used in five mapping and five crash rates dashboards listed as below (scripts are linked to the **bold** ones) including internal dashboard paths:

Internal parent path - T:\Tableau\tableauCrash\Workbooks

1. Crash data mapping

      1.1 [Motor Vehicle Crashes](https://www.lcog.org/914/Motor-Vehicle-Crashes) - CrashMaps_Motorized_DC.twb, save as 'Motor Vehicle Crashes'

      1.2 [Bicycle-Involved Crashes](https://www.lcog.org/916/Bicycle-Involved-Crashes) - CrashMaps_Bicycle_DC.twb, save as 'Bicycle-Involved Crashes'

      1.3 [Pedestrian-Involved Crashes](https://www.lcog.org/917/Pedestrian-Involved-Crashes) - CrashMaps_Pedestrian_DC.twb, save as 'Pedestrian-Involved Crashes'

      1.4 [Advanced User Data](https://www.lcog.org/913/Advanced-User-Data) - CrashMaps_AdvancedUser_DC.twb, save as 'Advanced User Data'

      1.5 [Crash Conditions](https://www.lcog.org/938/Crash-Conditions) - CrashesByFireDistrict_DC.twb, save as 'Crash Conditions'

2. [Population Crash Rates](https://www.lcog.org/891/Population-Crash-Rates) - CrashRatesByPopAgeGroup_DC.twb, save as 'Population Crash Rates'

This dashboard requires updates in *LaneAgeGroupPop.xlsx*, sourced from the [Population Research Center at Portland State University](https://www.pdx.edu/population-research/population-estimate-reports). The source table is Table 9 in the Annual Population Report Tables ([2018](https://drive.google.com/file/d/1M3ZpX3HwBPESVX0u-Q4hpI0F2yOPzmrc/view), [2019](https://drive.google.com/file/d/1Ul_4qRNTXAsZCEZbAnr4bzxO3Im6ohFd/view)). The age groups 15-17 and 18-19 are combined as 15-19. 

3. [VMT Crash Rates](https://www.lcog.org/892/VMT-Crash-Rates) - CrashRatesByVMT - Parameter_DC.twb, save as 'VMT Crash Rates'

This dashboard requires updates in *VMT_by_FuncClass.xlsx*, sourced from Federal Highway Administration (FHWA) [Table VM-2](https://www.fhwa.dot.gov/policyinformation/statistics/2019/vm2.cfm).

4. [**Transportation Safety Emphasis Areas**](https://www.lcog.org/912/Transportation-Safety-Emphasis-Areas)

5. [**NHTSA Core Safety Measures**](https://www.lcog.org/899/NHTSA-Core-Safety-Measures)

This dashboard requires updates in *US_FARS_data.xlsx*, sourced from National Highway Traffic Safety Administration (NHTSA) [FARS table](https://www-fars.nhtsa.dot.gov/States/StatesCrashesAndAllVictims.aspx). 

Most of the dashboards above are connected with the LCOG data server and the computation is done in Tableau which is a continued effort from the former GIS staff Bill Clingman, except the last two dashboards. Due to the Lane Geographic Data Consortium migration in 2020, crash data structure has changed by removing the differentiation of vehicle and non-vehicle participant.The dashboard *Transportation Safety Emphasis Areas* requires input files from lane county crash geodatabase prepared by Jacob Blair, and the calculation approach has been updated slightly due to the data structure change. The dashbords 1.1, 1.4, 1.5, 2, and 3 include low-level severity crash data and the update of crash data mapping only requires to refresh all extracts and change the year information, unless there are new changes in the data structure.

## Data Sources

The primary data source is the ODOT Crash linked the tables *dbo.ODOT_Crash* and *dbo.ODOT_Participant* within the **GIS_CLMPO** Database on the "rliddb.int.lcog.org,5433" Server. Other data sources are also listed [here](https://github.com/dongmeic/MPO_Data_Portal#crash-data).

## Functions

The scripts are mainly to clean up data and do some simple calculation.
