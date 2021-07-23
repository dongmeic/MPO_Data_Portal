# Explanations
Updated on May 10th, 2021

Crash data is used in five mapping and five crash rates dashboards listed as below (scripts are linked to the **bold** ones) including internal dashboard paths:

Internal parent path - T:\Tableau\tableauCrash\Workbooks, except for the safety emphasis areas dashboard - T:\Tableau\tableauSafetyEmphasisAreas\Workbooks

1. Crash data mapping

      1.1 [**Motor Vehicle Crashes**](https://www.lcog.org/thempo/page/Motor-Vehicle-Crashes) - CrashMaps_Motorized_DC.twb

      1.2 [**Bicycle-Involved Crashes**](https://www.lcog.org/thempo/page/Bicycle-Involved-Crashes) - CrashMaps_Bicycle_DC.twb

      1.3 [**Pedestrian-Involved Crashes**](https://www.lcog.org/thempo/page/Pedestrian-Involved-Crashes) - CrashMaps_Pedestrian_DC.twb

      1.4 [**Advanced User Data**](https://www.lcog.org/thempo/page/Advanced-User-Data) - CrashMaps_AdvancedUser_DC.twb

      1.5 [**Crash Conditions**](https://www.lcog.org/thempo/page/Crash-Conditions) - CrashesByFireDistrict_DC.twb

2. [**Population Crash Rates**](https://www.lcog.org/thempo/page/Population-Crash-Rates) - CrashRatesByPopAgeGroup_DC.twb

This dashboard requires updates in *LaneAgeGroupPop.xlsx*, sourced from the [Population Research Center at Portland State University](https://www.pdx.edu/population-research/population-estimate-reports). The source table is Table 9 in the Annual Population Report Tables ([2018](https://drive.google.com/file/d/1M3ZpX3HwBPESVX0u-Q4hpI0F2yOPzmrc/view), [2019](https://drive.google.com/file/d/1Ul_4qRNTXAsZCEZbAnr4bzxO3Im6ohFd/view)). The age groups 15-17 and 18-19 are combined as 15-19. 

3. [**VMT Crash Rates**](https://www.lcog.org/thempo/page/VMT-Crash-Rates) - CrashRatesByVMT - Parameter_DC.twb

This dashboard requires updates in *VMT_by_FuncClass.xlsx*, sourced from ODOT VMT report. The detailed steps are addressed in T:\Data\VMT\VMT HPMS\update_notes.txt. The results are calculated in spreadsheet using daily vehicle miles, the number of days in a year, and unit conversion.

4. [**Transportation Safety Emphasis Areas**](https://www.lcog.org/thempo/page/Transportation-Safety-Emphasis-Areas) - EmphasisAreas_UGB.twb

This dashboard requires updates in *Severity_Tableau_UGB.csv* and *Trend_Tableau_UGB.csv*, by running the the script *SafetyEmphasisAreas.r*.

5. [**NHTSA Core Safety Measures**](https://www.lcog.org/thempo/page/NHTSA-Core-Safety-Measures) - CoreSafetyMeasures_Parameter_DC.twb

This dashboard requires updates in *US_FARS_data.xlsx*, sourced from Federal Highway Administration (FHWA) [Table VM-2](https://www.fhwa.dot.gov/policyinformation/statistics/2019/vm2.cfm) and National Highway Traffic Safety Administration (NHTSA) [FARS table](https://www-fars.nhtsa.dot.gov/States/StatesCrashesAndAllVictims.aspx). 

Most of the dashboards above are connected with the LCOG data server and the computation is done in Tableau which is a continued effort from the former GIS staff Bill Clingman, except the last two dashboards. Due to the Lane Geographic Data Consortium migration in 2020, crash data structure has changed by removing the differentiation of vehicle and non-vehicle participant.The dashboard *Transportation Safety Emphasis Areas* requires input files from lane county crash geodatabase prepared by Jacob Blair, and the calculation approach has been updated slightly due to the data structure change. The dashbords 1.1, 1.4, 1.5, 2, and 3 include low-level severity crash data and the update of crash data mapping and NHTSA core safety measures only requires to refresh all extracts and change the year information, unless there are new changes in the data structure.

6. [**FARS Data**](https://www.lcog.org/thempo/page/fars-data) - US_FARS_VMT Fatality Rate OneMap_DC.twb

Download [VM2](https://www.fhwa.dot.gov/policyinformation/statistics/2019/vm2.cfm), copy the TOTAL column and save it as the CSV format. Download [NHTSA](https://www-fars.nhtsa.dot.gov/States/StatesCrashesAndAllVictims.aspx) and save it as the XLSX format. Run the [script](https://github.com/dongmeic/MPO_Data_Portal/blob/master/CrashData/US_FARS.r) to update the input files. Refresh the extract and update the dashboard.

## Data Sources

The primary data source is the ODOT Crash linked the tables *dbo.ODOT_Crash* and *dbo.ODOT_Participant* within the **GIS_CLMPO** Database on the "rliddb.int.lcog.org,5433" Server. Other data sources are also listed [here](https://github.com/dongmeic/MPO_Data_Portal#crash-data).

## Functions

The scripts are mainly to clean up data and do some simple calculation.