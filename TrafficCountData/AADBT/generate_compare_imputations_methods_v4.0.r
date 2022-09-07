#Author: Josh Roll 
#Date: 11/11/2019
#Description:   Use hold out analysis and test holding out each combination of months to determine the error for each month and total annual estimation.  Comparing the pre-selected negative binomial statistical model against 
#machine leanring algorithms
#Version
#1.0
#2.0
#3.0
#4.0
#---Added tests to include multiple years of data
#Notes:



#Load libraries
#----------------------
	library(rgdal)
	library(rgeos)
	library(MASS)
	library(AER)
	library(scales)
	library(htmltools)
	library(htmlwidgets)
	library(maptools)
	library(ggplot2)
	library(tigris)
	library(RColorBrewer)
	library(dplyr)
	library(gridExtra)
	library(grid)
	library(StreamMetabolism)
	library(reshape2)
	library(dplyr)
	library(timeDate)
	library(lubridate)
	library(Lahman)
	library(rnoaa)
	library(readxl)	
	library(Metrics)
	library(geosphere)
	library(caret)
	library(lm.beta)
	library(plotly)
	library(rpart)
  library(doParallel)
  library(rattle)
  library(rpart.plot)

	
#Set up R environment
#------------------
	#Set scientific notation
#	options(scipen = 6)
	options(scipen=999)
	#Set working directory
	setwd("T:/DCProjects/Modeling/AADBT/reading/Test/Data")
	
	
	#set parallel backend (Windows)
	###########################
	
	
	
	#Define custom scripts functions
#------------------------------
	#Function that simplifies loading .RData objects
	assignLoad <- function(filename){
       load(filename)
       get(ls()[ls() != "filename"])
    }
	#Function to create bin labels
	label_Bins <- function(Breaks.){
		Labels_ <- list()
		for(i in 1:(length(Breaks.)-1)){
			Labels_[[i]] <- paste(Breaks.[[i]], Breaks.[[i + 1]], sep="-")
		}
		#Return result
		unlist(Labels_)
	}
			
	#Function to calculate psuedo r squared
	pseudoR2 <- function(Model){
		df <- summary(Model)$df[2]
		x <- summary(Model)$deviance
		y <- summary(Model)[["null.deviance"]]
		R2 <- 1 - (x / y)
		R2
	}

	
#Define custom vectors
#--------------------------
	#Items from Data Dictionary
	######################################
	#Load User Type sheet---
	Data_Dictionary.. <- read_excel("Documentation/Data Dictionary.xlsx", sheet = "User_Type_Code")
	Eco_User_Type. <- Data_Dictionary..$User_Type
	names(Eco_User_Type.) <- Data_Dictionary..$Eco_User_Type_Desc
	Eco_User_Type. <- Eco_User_Type.[!(is.na(names(Eco_User_Type.)))] 
	#Define additional user types codes since Eco Counter does not correctly define users when bike/ped collected together---
	User_Type. <- Data_Dictionary..$User_Type
	names(User_Type.) <- Data_Dictionary..$User_Type_Desc
	User_Type. <- User_Type.[!(is.na(names(User_Type.)))] 
	#Load Direction Code sheet---
	Data_Dictionary.. <- read_excel("Documentation/Data Dictionary.xlsx", sheet = "Direction")
	#Create a direction description vector
	Direction_Desc. <- Data_Dictionary..$Direction_Code
	names(Direction_Desc.) <- Data_Dictionary..$Direction_Desc
	#Load Collection Type Code sheet---
	Data_Dictionary.. <- read_excel("Documentation/Data Dictionary.xlsx", sheet = "Collection_Type_Code")
	#Collection Type Codes---
	Collection_Type. <- Data_Dictionary..$Collection_Type
	names(Collection_Type.) <- Data_Dictionary..$Collection_Type_Desc
	#Load Facility Type Code sheet---
	Data_Dictionary.. <- read_excel("Documentation/Data Dictionary.xlsx", sheet = "Facility_Type_Code")
	#Create facility type desc vector
	Facility_Type. <- Data_Dictionary..$Facility_Type
	names(Facility_Type.) <-Data_Dictionary..$Facility_Type_Desc
	#Load Facility Type Code sheet---
	Data_Dictionary.. <- read_excel("Documentation/Data Dictionary.xlsx", sheet = "Device_Type")
	#Create device type desc vector
	Device_Type. <- Data_Dictionary..$Device_Type
	names(Device_Type.) <- Data_Dictionary..$Device_Type_Desc
	#Load Error Code sheet---
	Data_Dictionary.. <- read_excel("Documentation/Data Dictionary.xlsx", sheet = "Error_Codes")
	#Create device type desc vector
	Error_Code. <- Data_Dictionary..$Error_Code
	names(Error_Code.) <- Data_Dictionary..$Error_Name
	
#Load data
#-----------------------------
	#Counts data
	#####################
	#Create vector of file names
	# All_Files. <- file.info(dir(paste(getwd(),"/Counts Data/Step 3 - Counts with Errors",sep=""), full.names=TRUE))$ctime
	# names(All_Files.) <- dir(paste(getwd(),"/Counts Data/Step 3 - Counts with Errors",sep=""), full.names=TRUE)
	# #Daily counts by sub location 
	# File <- All_Files.[grep("Daily_Sub_Location_Id", names(All_Files.))]
	# File <- names(File[File%in%max(File)])
	File <- "Daily_Sub_Location_Id_406683.RData"
	Load_Daily_Sub_Location_Id.. <- assignLoad(File)
	
	#Supporting Data
	###################
	#Locate latest files
	# All_Files. <- file.info(dir(paste("Supporting Data/API Call Summary Information",sep=""), full.names=TRUE))$ctime
	# names(All_Files.) <- dir(paste("Supporting Data/API Call Summary Information",sep=""), full.names=TRUE)
	# All_Files. <- All_Files.[agrep(".RData",names(All_Files.))]
	# #Site information form API Call----
	# Select_Files. <- All_Files.[grep("Site_Location_Info", names(All_Files.))]
	# File <- names(Select_Files.[Select_Files.%in%max(Select_Files.)])
	# Site_Location_Info.. <- assignLoad(file = File)
	#Load spatial data
	#Site_Location_Info_Sp <- assignLoad( file ="Supporting Data/API Call Summary Information/Site_Location_Info_Sp_116.RData")
	Site_Location_Info_Sp <- assignLoad( file = "Site_Location_Info_Sp_116.RData")
	#Load store climate data
	#Load_Store_Climate_Data.. <- assignLoad( file ="//wpdotfill09/R_VMP3_USERS/tdb069/Data/Climate/Processed/NOAA_Data.RData")
	Load_Store_Climate_Data.. <- assignLoad( file = "NOAA_Data.RData")
	
	
#SARM Validation 
#-----------------------------	
	#SARM Validation 
	#-----------------------------	
	#Review and determine completness of daily counts 
	#########################
	#Select just the total 
	Daily.. <- Load_Daily_Sub_Location_Id..[Load_Daily_Sub_Location_Id..$Collection_Type_Desc%in%"Permanent" & Load_Daily_Sub_Location_Id..$Direction%in%"Total",]
	#Add descriptive error code
	Daily..$Error_Code_Desc <- names(Error_Code.)[match(Daily..$Error_Code, Error_Code.)]
	#Select only data with no known error
	Daily..  <- Daily.. [!(Daily..$Error_Code%in%1),]
	#Assign city to daily count data
	Daily..  <- left_join(Daily.., as.data.frame(Site_Location_Info..)[,c("Vendor_Site_Id","City")], by = c("Vendor_Site_Id"))
	#Convert city variable to character
	Daily..$City <- as.character(Daily..$City)  
	#Make a copy of the climate data
	Climate_Data.. <- 	Load_Store_Climate_Data..
	#Remove duplicated
	Climate_Data..$Index <- paste(Climate_Data..$Date, Climate_Data..$City, sep="-")
	Climate_Data.. <- Climate_Data..[!(duplicated(Climate_Data..$Index)),]
	#Snow that is na mark as 0 
	Climate_Data..$SNOW[is.na(Climate_Data..$SNOW)] <- 0
	#Fix last day of year
	Climate_Data..$Daylight_Mins[Climate_Data..$Date%in%"2019-12-31"] <- 529
	Climate_Data..$Daylight_Mins[Climate_Data..$Date%in%"2018-12-31"] <- 529
	Climate_Data..$Daylight_Mins[Climate_Data..$Date%in%"2012-12-31"] <- 529

	#Join climate data	
	Daily.. <- left_join(Daily.. , Climate_Data.., by = c("Date","City"))
	#Select only records with weather data
	Daily.. <- Daily..[!(is.na(Daily..$TMAX)),]
	#Fix daylight mins
	Daily..$Daylight_Mins <- Climate_Data..$Daylight_Mins[match(Daily..$Date, Climate_Data..$Date)]
	#Manually fix the last day of 2018 - try 
	Daily..$Daylight_Mins[Daily..$Date%in%as.Date("2018-12-31")]<- 529
	Daily..$Daylight_Mins[Daily..$Date%in%as.Date("2019-12-31")]<- 529
	#Sumamrize the number of records by device and by year
	##############
	Daily_Counts_Summary.. <- Daily.. %>% group_by(Device_Name,User_Type_Desc, Year) %>% summarise(Count = length(Counts))
	#Create a summary of daily observations to device what data to use
	Daily_Summary.. <- Daily.. %>% group_by(Device_Name, User_Type_Desc,Year) %>% summarise(Obs_N = length(Counts[!(is.na(Counts))]))
	#Remove holidays
	#Daily.. <- Daily..[Daily..$Is_Holiday%in%FALSE,]
	#Remove consecutive zeros
	Daily.. <- Daily..[!(Daily..$Error_Code%in%c(1,3)),]
	#Summarize number of observations agian with cleaned data
	Daily_Summary.. <- left_join(Daily_Summary.., Daily.. %>% group_by(Device_Name, User_Type_Desc,Year) %>% summarise(Obs_N_Clean = length(Counts[!(is.na(Counts))])), by = c("Device_Name", "User_Type_Desc", "Year"))
	Daily.. <- left_join(Daily..,Daily_Summary.., by = c("Device_Name", "User_Type_Desc", "Year"))
	#Select only sites with 360 days or more
	Daily.. <- Daily..[Daily..$Obs_N_Clean >=350,]
	#Add week colum
	Daily..$Week <- week(Daily..$Date)
	Daily.. <- Daily..[!(is.na(Daily..$Device_Name)),]
	#Do just 2018 for now
	Daily.. <- Daily..[Daily..$Year%in%c("2017","2018","2019"),]
	#Remove locations that are duplicates or have known issues
	##############
	#Remove combination of user type and location
	Daily.. <- Daily..[!(Daily..$Device_Name%in%c("Portland Ave. Southside","PB Nature trail/formerly base tr.","Minto Brown South","Rosa Parks Path south of Q St") & Daily..$User_Type_Desc%in%"Pedestrian"),]
	Daily.. <- Daily..[!(Daily..$Device_Name%in%c("HAWTHORNE BR north side","HAWTHORNE BR south side","Hawthorne totem","Tilikum Crossing 2 (Westbound)","Tilikum Crossing 1 (Eastbound)","Tilikum Crossing 1 (Westbound)","Tilikum Crossing Total") & Daily..$User_Type_Desc%in%"Bicycle"),]
	Daily.. <- Daily..[!(Daily..$Device_Name%in%c("Millrace Path @ Booth Kelly") & Daily..$User_Type_Desc%in%"Pedestrian"),]
	Daily.. <- Daily..[!(Daily..$Device_Name%in%c("Alder north of 18th Ave","Newport Ave. Northside","Newport Ave. Southside") & Daily..$User_Type_Desc%in%"Bicycle"),]
	#Select user types
	Daily.. <- Daily..[Daily..$User_Type_Desc%in%c("Bicycle","Pedestrian"),]
	#Summarise final number of device by user type and year used in the factoring testing below
	Daily_Summary_Year.. <- Daily.. %>% group_by(Year,User_Type_Desc) %>% summarise(Device_Count = length(unique(Device_Name)), Mean_AADT = mean(Counts), Median_AADT = median(Counts), 
		Obs_N = length(Counts) / length(unique(Device_Name)))
	#Sumamrize the number of records by device and by year
	##############
	Daily_Counts_Summary..  <- Daily.. %>% group_by(Device_Name, User_Type_Desc,Year) %>% summarise(Obs_N = length(Counts[!(is.na(Counts))]),ADT = round(mean(Counts, na.rm=T)))
	#Remove locations with issues after review (below)
	Locations_To_Remove. <- c("Willamette St west Sidewalk north of Broadway","BendMULTI551","BendMULTI552")	
	Daily_Counts_Summary.. <- Daily_Counts_Summary..[!(Daily_Counts_Summary..$Device_Name%in%Locations_To_Remove.),]
	
  #Store Daily Counts for use in related script
	#############################
	#save(Daily.., file = "Models/Imputation/Data/Daily_ML_Input_Data.RData")
	
	
	#Plot daily counts for each year to review data
	#####################
	pdf("Reports/Imputation/Daily_Counts_All.pdf", height = 11, width = 11)
	for(location in unique(Daily..$Device_Name)){
		#Select count locaiton
		dat <- Daily..[Daily..$Device_Name%in%location,]
		Shapes. <- c(3,15,17,16,12,6)
		names(Shapes.) <- names(Error_Code.)
      
		Plot <- ggplot(dat, aes(x = Date, y = Counts)) +
			geom_line(aes(x = Date, y = Counts),color = "black", group = 1) +
			geom_point(aes(x = Date, y = Counts, pch = Error_Code_Desc, color = Is_Holiday), group = 1, size = 2) +
			scale_colour_manual(c("No","Holiday"),values=c("black","skyblue")) +
			facet_wrap(~User_Type_Desc, scales = "free") +
			scale_shape_manual(values=Shapes.) +
			ggtitle(location)
			
		print(Plot)
	}
	dev.off()	
		
	#filter(Daily_Counts_Summary.., Device_Name == 
	#Prepare and join climate to daily count records
	##############################	
	#Create year column
	Climate_Data..$Year <- year(Climate_Data..$Date)
	#Month data
	Climate_Data..$Month <- months(Climate_Data..$Date)
	#Select final columns
	#Climate_Data.. <- Climate_Data..[,c("Date","Month","Year","Max_Temp","Precip","Snow","Daylight_Mins")]
	#Weekdays and dummy for weekend
	Climate_Data..$Weekday <- weekdays(Climate_Data..$Date)
	Climate_Data..$Is_Weekday <- "Weekday"
	Climate_Data..$Is_Weekday[Climate_Data..$Weekday%in%c("Saturday","Sunday")] <- "Weekend" 
	#Append is holiday flag
	Holidays. <-  c("USNewYearsDay","USInaugurationDay","USMLKingsBirthday","USMemorialDay","USIndependenceDay","USLaborDay","USVeteransDay","USThanksgivingDay","USChristmasDay")
	Holiday_Dates.  <-  as.Date(dates(as.character(holiday(unique(Climate_Data..$Year),Holidays.)),format ="Y-M-D"),format = "%m/%d/%Y")
	#Append to daily and hourly data sets
	Climate_Data..$Is_Holiday <- FALSE
	Climate_Data..$Is_Holiday[Climate_Data..$Date%in%Holiday_Dates.] <- TRUE

	#Remove locations/years with known issues
	##############################
	Daily_Counts_Summary.. <- Daily_Counts_Summary..[!((Daily_Counts_Summary..$Device_Name%in%"Fern Ridge Path west of Chambers" & Daily_Counts_Summary..$Year%in%c("2013","2014"))),]
	
	#Count number of unique locations
	length(unique(Daily_Counts_Summary..$Device_Name))
	  
	#Summarize climate data for select locations
	Select_Climate_Data.. <- Climate_Data..[Climate_Data..$City%in%unique(Daily..$City),]
	Select_Climate_Data.. %>% group_by(City) %>% summarise(Mean_Max_Temp = mean(TMAX_Trans), Total_Precip = sum((PRCP/10),na.rm=T) / length(unique(Year)) * 0.0393701, Total_Snow = sum((SNOW/10)) /length(unique(Year)) * 0.0393701)
	
	
	
	
#Compare imputation methods - Monthly scenario holdout - do one year at time----
#-------------------------------------------
	#Set up variable grid for the negative binomial process
	Variables. <- month.name
	#Just variable used in current version of paper 
	#Craft matrix logical  TRUE/FALSE vectors must equal the number of variables)
	Months_Mat <- expand.grid(Variables.,Variables.)
	reg_Mat <- expand.grid(c(TRUE,FALSE), c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE), c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE))
	
	#Use model found to be best in previous agaistive search method
	SARM_Models.. <- assignLoad(file = "Models/Imputation/SARM_Annualization_Models.RData")
		
	#Create a data.frame to store the results
	##############################
	#Estimated and observed results data
	Obs_Est.. <- data.frame()
	#Initialize a data frame for storing model coefficients
	All_Coefficients.. <- data.frame()
	#Initialize a list to store models
	##############
	#Negative Binomial
	NegBin_Models_ <- list()
	#RPART ML models
	Rpart_Models_ <- list()
	#Conditional Inference
	Cond_Inf_Models_ <- list()
	#Random Forest Models
	Rf_Models_ <- list()
	#Create a data frame to store standardized beta coefficients
	Std_Beta_Coeff_ <- list()
	#initialize a dataframe to store negative binomical regression 
	Coefficients.. <- data.frame()
	Std_Beta_Coeff.. <- data.frame()
	#Set up parallel processing
	cl <- makePSOCKcluster(7)
	registerDoParallel(cl)
	count <- 1
	for(device_name in unique( Daily_Counts_Summary..$Device_Name )){
	  Select_Data_1.. <-  Daily_Counts_Summary.. [ Daily_Counts_Summary.. $Device_Name%in%device_name,]
	  for(user_type in unique(Select_Data_1..$User_Type_Desc)){
		  	#Select counts data for location
			Select_Data_2.. <- Daily_Counts_Summary.. [Daily_Counts_Summary..$User_Type_Desc%in%user_type & Daily_Counts_Summary..$Device_Name%in%device_name,]
			#Estimated and observed results data
			Obs_Est.. <- data.frame()
			#Do each year 
			for(year in unique( Select_Data_2..$Year)){
				#Initialize a list to store models
				##############
				#Negative Binomial
				NegBin_Models_ <- list()
				#RPART ML models
				Rpart_Models_ <- list()
				#Conditional Inference
				Cond_Inf_Models_ <- list()
				#Random Forest Models
				Rf_Models_ <- list()
				#Create a data frame to store standardized beta coefficients
				Std_Beta_Coeff_ <- list()				
				
				#Select yearly data			
				Select_Data_3.. <- Daily..[Daily..$Device_Name%in%device_name & Daily..$User_Type_Desc%in%user_type & Daily..$Year%in%year,]
				if(nrow(Select_Data_3..) > 0){				
					#Make an application copy of the climate and daily condition data
					Apply_Data.. <- Climate_Data.. 
					#Make a copy of the data
					Model_Data.. <- Select_Data_3..					
					
					#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
					#Negative binomail regression
					#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
					#Define Imputation type object
					Imputation_Type <- "Negative_Binomial"					
					#Initialize lists for storage
					Daily_Mean_APE_ <- list()
					Daily_Median_APE_ <- list()
					Est_Sum_Month_ <- list()
					Obs_Sum_Month_ <- list()
					Est_Sum_Annual_ <- list()
					#initialize a dataframe to store negative binomical regression 
					#Coefficients.. <- data.frame()
					#Std_Beta_Coeff.. <- data.frame()
					#Initiate a start timer
					Master_Start_Time <- Sys.time()
					Start_Time <- Sys.time()
					
					for(i in 1:nrow(reg_Mat )){				
						#Determine months selected
						Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
						#Dont do if all true == all months of year 
						if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
							#Create input and hold out datasets
							Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
							Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
							#Determine best model specification
							x <- gsub(" ","",unlist(strsplit(SARM_Models..[SARM_Models..$Device_Name%in%device_name & SARM_Models..$User_Type_Desc%in%user_type,]$Model_Input,",")))
							x <- x[!(x%in%"")]
							model_spec <-  as.formula(paste("Counts~",paste(x, collapse ="+"),sep=""))
							Model <- suppressWarnings(glm.nb(model_spec  , data = Input_Data..,init.theta=1e-6))
							#Store model object item
							NegBin_Models_[[paste(device_name, user_type,year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
							#Store all model coefficient information
							Temp_Coefficients.. <- as.data.frame(coefficients(summary(Model))) 
							Temp_Coefficients..$Device_Name <-device_name
							Temp_Coefficients..$User_Type_Desc <- user_type
							Temp_Coefficients..$Months_Select <- paste(Months_Select.,collapse="-")
							Temp_Coefficients..$Year <- year
							Coefficients.. <- rbind(Coefficients..,Temp_Coefficients..)
							#Prepare and store standardized beta coefficients
							Temp_Std_Beta_Coeff.. <- as.data.frame(coefficients(lm.beta(Model)))
							colnames(Temp_Std_Beta_Coeff..) <- "Coefficient"
							Temp_Std_Beta_Coeff..$Variable <- rownames(Temp_Std_Beta_Coeff.. )
							Temp_Std_Beta_Coeff..$Device_Name <-device_name
							Temp_Std_Beta_Coeff..$User_Type_Desc <- user_type
							Temp_Std_Beta_Coeff..$Months_Select <- paste(Months_Select.,collapse="-")
							Temp_Std_Beta_Coeff..$Year <- year
							Std_Beta_Coeff.. <- rbind(	Std_Beta_Coeff.. ,Temp_Std_Beta_Coeff..)
							#Store in list
							Std_Beta_Coeff_[[paste(device_name, user_type,paste(Months_Select.,collapse="-"),sep="_")]]  <-  Temp_Std_Beta_Coeff..
							#Apply model and calculate APE
							Est.  <- predict(Model, newdata = Holdout_Data.. ) 
							Obs. <- Holdout_Data..$Counts		
							Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
							Temp_Daily..$Date <- Holdout_Data..$Date
							#Remove records with 0 observed daily counts
							Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
							#Calculate APE
							Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
							#Define imputation type
							Temp_Daily..$Imputation_Type <- Imputation_Type
							#Store summary information
							###################
							#Daily---
							Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
							Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
							#Monthly---
							Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
							Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
							#Annual---
							Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
							#Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )							
						}
						#Report progress
						if(length(i[i %% 1000 == 0] == 0) > 0){
							print(paste(i, " of ",nrow(reg_Mat)," Variables Done",sep=""))
							print(round(Sys.time() - Start_Time,2))
							#Reinitiate timer
							Start_Time <- Sys.time()
						}
					#End monthly scenario loop	
					}
					#Print total calculation time
					print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
					print(round(Sys.time() - Master_Start_Time,2))
					#Store model coefficients
					#Std_Beta_Coeff.. <- do.call("rbind",Std_Beta_Coeff_)
					#rownames(Std_Beta_Coeff..) <- 1:nrow(Std_Beta_Coeff..)
					#save( Std_Beta_Coeff..,file = "Models/Imputation/Std_Beta_Coeff_df.RData")
					#Create a data frame to store absolute percent error for day, month, and year
					##############################
					#Create dataframe
					Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
						User_Type_Desc = user_type, Year = year)
					#Month
					Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
					#Annual 
					Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
					#Mean Daily
					Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
					#Median Daily
					Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
					#Add Imputation type
					Temp_Obs_Est..$Imputation_Type <- Imputation_Type
					#Stire in master data frame
					Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
					#Store model coefficients
					#All_Coefficients.. <- rbind(All_Coefficients.., Coefficients..)
					#All_Coefficients.. <- rbind(All_Std_Beta_Coeff.. , Std_Beta_Coeff.. )
					#All_Std_Beta_Coefficients.. <- rbind(All_Std_Beta__Coefficients.., 		Temp_Std_Beta_Coeff..)
					
					#save( Std_Beta_Coeff..,file = "Models/Imputation/Std_Beta_Coeff_df.RData")
					
					#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
					#Recursive Partition (Rpart)
					#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
					#Define Imputation type object
					Imputation_Type <- "Rpart"
					#Set vector of candidate covariates
					Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Weekday","Is_Holiday")					
					#Reinitialize lists for storage
					Daily_Mean_APE_ <- list()
					Daily_Median_APE_ <- list()
					Est_Sum_Month_ <- list()
					Obs_Sum_Month_ <- list()
					Est_Sum_Annual_ <- list()
					#Initiate a start timer
					Master_Start_Time <- Sys.time()
					Start_Time <- Sys.time()
					for(i in 1:nrow(reg_Mat )){
						#Determine months selected
						Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
						#Dont do if all true == all months of year 
						if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
							#Create input and hold out datasets
							Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
							Input_Data..$Weekday <- as.factor(Input_Data..$Weekday)
							Input_Data..$Is_Weekday <- as.factor(Input_Data..$Is_Weekday)
							Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
							#Train model 
							#rpart2-----
							#Setup LM control parameters
							Control_ <- trainControl(method = "repeatedcv",
									number = 10, repeats = 2,
									 search = "grid", allowParallel = TRUE)
							#Setup grid
							Tune_Grid_ <- data.frame(maxdepth = seq(2,4,1))
							#Train Model 
							Model <- train(x=Input_Data..[,Col_Names.],
									y=Input_Data..$Counts,	method='rpart2',
									trControl = Control_, tuneGrid = Tune_Grid_)
							#Store model object item
							#Rpart_Models_[[paste(device_name, user_type, year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
						
							#Apply model
							###################
							Est.  <- predict(Model, newdata = Holdout_Data.. ) 
							Obs. <- Holdout_Data..$Counts		
							Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
							Temp_Daily..$Date <- Holdout_Data..$Date
							#Remove records with 0 observed daily counts
							Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
							#Calculate APE
							Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
							#Define imputation type
							Temp_Daily..$Imputation_Type <- Imputation_Type
							#Store summary information
							###################
							#Daily---
							Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
							Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
							#Monthly---
							Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
							Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
							#Annual---
							Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
							#Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )					
						}					
						#Report progress
						if(length(i[i %% 100 == 0] == 0) > 0){
							print(paste(i, " of ",nrow(reg_Mat)," Variables Done - ",Imputation_Type,sep=""))
							print(round(Sys.time() - Start_Time,2)); Start_Time <- Sys.time()
						}
					}
					#Print total calculation time
					print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
					print(round(Sys.time() - Master_Start_Time,2))
				
					#Create a data frame to store absolute percent error for day, month, and year
					##############################
					#Create dataframe
					Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
						User_Type_Desc = user_type, Year = year)
					#Month
					Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
					#Annual 
					Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
					#Mean Daily
					Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
					#Median Daily
					Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
					#Add Imputation type
					Temp_Obs_Est..$Imputation_Type <- Imputation_Type
					#Stire in master data frame
					Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
							
					#-------------------------------------------------------------------------------------------------------------------------------------
					#Conditional Inference
					#--------------------------------------------------------------------------------------------------------------------------------------
					#Define Imputation type object
					Imputation_Type <- "Conditional_Inference"				
					#Set vector of candidate covariates
					Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Weekday","Is_Holiday")					
					#Reinitialize lists for storage
					Daily_Mean_APE_ <- list()
					Daily_Median_APE_ <- list()
					Est_Sum_Month_ <- list()
					Obs_Sum_Month_ <- list()
					Est_Sum_Annual_ <- list()
					#Initiate a start timer
					Master_Start_Time <- Sys.time()
					Start_Time <- Sys.time()
					for(i in 1:nrow(reg_Mat )){
						#Determine months selected
						Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
						#Dont do if all true == all months of year 
						if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
							#Create input and hold out datasets
							Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
							Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
							#Train model 
							#Conditional Inference
							#Train model 
							Model <- train(
								Counts ~., data = Input_Data..[,c("Counts",Col_Names.)], method = "ctree2",
								trControl = trainControl("cv", number = 10, allowParallel = TRUE),
								tuneGrid = expand.grid(maxdepth = 3, mincriterion = 0.95 )
								)
							#Store model object item
							#Cond_Inf_Models_[[paste(device_name, user_type, year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
													
							#Apply model
							###################
							Est.  <- predict(Model, newdata = Holdout_Data.. ) 
							Obs. <- Holdout_Data..$Counts		
							Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
							Temp_Daily..$Date <- Holdout_Data..$Date
							#Remove records with 0 observed daily counts
							Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
							#Calculate APE
							Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
							#Define imputation type
							Temp_Daily..$Imputation_Type <- Imputation_Type
							#Store summary information
							###################
							#Daily---
							Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
							Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
							#Monthly---
							Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
							Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
							#Annual---
							Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
							#Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )					
						}					
						#Report progress
						if(length(i[i %% 100 == 0] == 0) > 0){
							print(paste(i, " of ",nrow(reg_Mat)," Variables Done - ",Imputation_Type,sep=""))
							print(round(Sys.time() - Start_Time,2)); Start_Time <- Sys.time()
						}
					}
					#Print total calculation time
					print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
					print(round(Sys.time() - Master_Start_Time,2))
				
					#Create a data frame to store absolute percent error for day, month, and year
					##############################
					#Create dataframe
					Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
						User_Type_Desc = user_type, Year = year)
					#Month
					Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
					#Annual 
					Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
					#Mean Daily
					Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
					#Median Daily
					Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
					#Add Imputation type
					Temp_Obs_Est..$Imputation_Type <- Imputation_Type
					#Stire in master data frame
					Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
						
					#-------------------------------------------------------------------------------------------------------------------------------------
					#Random forest
					#--------------------------------------------------------------------------------------------------------------------------------------
					#Define Imputation type object
					Imputation_Type <- "Random_Forest"				
					#Set vector of candidate covariates
					Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Weekday","Is_Holiday")					
					#Reinitialize lists for storage
					Daily_Mean_APE_ <- list()
					Daily_Median_APE_ <- list()
					Est_Sum_Month_ <- list()
					Obs_Sum_Month_ <- list()
					Est_Sum_Annual_ <- list()
					#Initiate a start timer
					Master_Start_Time <- Sys.time()
					Start_Time <- Sys.time()
					for(i in 1:nrow(reg_Mat )){
					  #Determine months selected
					  Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
					  #Dont do if all true == all months of year 
					  if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
					    #Create input and hold out datasets
					    Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
					    Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
					    #Train model 
					    #Random Forest
					    Control_ <- trainControl(method = "cv", number = 10,search = "grid", allowParallel = TRUE)
					    #Train model 
					    Model <- train(Counts~.,
					                data = Input_Data..[,c("Counts",Col_Names.)],
					                method = "rf", metric = "RMSE",  trControl = Control_)
					    #Store model object item
					   # Rf_Models_[[paste(device_name, user_type,year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
					    
					    #Apply model
					    ###################
					    Est.  <- predict(Model, newdata = Holdout_Data.. ) 
					    Obs. <- Holdout_Data..$Counts		
					    Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
					    Temp_Daily..$Date <- Holdout_Data..$Date
					    #Remove records with 0 observed daily counts
					    Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
					    #Calculate APE
					    Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
					    #Define imputation type
					    Temp_Daily..$Imputation_Type <- Imputation_Type
					    #Store summary information
					    ###################
					    #Daily---
					    Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
					    Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
					    #Monthly---
					    Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
					    Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
					    #Annual---
					    Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
					    #Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )					
					  }					
					  #Report progress
					  if(length(i[i %% 100 == 0] == 0) > 0){
					    print(paste(i, " of ",nrow(reg_Mat)," Variables Done - ",Imputation_Type,sep=""))
					    print(round(Sys.time() - Start_Time,2)); Start_Time <- Sys.time()
					  }
					}
					#Print total calculation time
					print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
					print(round(Sys.time() - Master_Start_Time,2))
					
					#Create a data frame to store absolute percent error for day, month, and year
					##############################
					#Create dataframe
					Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
					                             User_Type_Desc = user_type, Year = year)
					#Month
					Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
					#Annual 
					Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
					#Mean Daily
					Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
					#Median Daily
					Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
					#Add Imputation type
					Temp_Obs_Est..$Imputation_Type <- Imputation_Type
					#Stire in master data frame
					Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
					
				}
			#End Year loop
			print(year)
			}
			#Store yearly, monthly, and daily estiamtes and observed with APE
		#	save(Obs_Est.., file = paste("Models/Imputation/Separate Outputs/",device_name,"-",user_type,"_Obs_Est_.RData",sep=""))				
		#	save(NegBin_Models_, file = paste("Models/Imputation/Separate Outputs/",device_name,"-",user_type,"_NegBin_Models_.RData",sep=""))				
		#	save(Rpart_Models_, file = paste("Models/Imputation/Separate Outputs/",device_name,"-",user_type,"_Rpart_Models_.RData",sep=""))				
		#	save(Cond_Inf_Models_, file = paste("Models/Imputation/Separate Outputs/",device_name,"-",user_type,"_Cond_Inf_Models_.RData",sep=""))				
		#	save(Rf_Models_, file = paste("Models/Imputation/Separate Outputs/",device_name,"-",user_type,"_Rf_Models_.RData",sep=""))						
			
		print(paste(device_name, " ",user_type, " Done. ", sep=""))
		#End User loop
		}	
		#Print progress on location
		print(paste(device_name, " Done. ",count, " of ", length(unique( Daily_Counts_Summary..$Device_Name )), sep=""))
		count <- count + 1
	#End location loop
	}
	
	
	
	#Compare imputation methods - Monthly scenario holdout - do one year at time----
	#-------------------------------------------
	#Set up variable grid for the negative binomial process
	Variables. <- month.name
	#Just variable used in current version of paper 
	#Craft matrix logical  TRUE/FALSE vectors must equal the number of variables)
	Months_Mat <- expand.grid(Variables.,Variables.)
	reg_Mat <- expand.grid(c(TRUE,FALSE), c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE), c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE),c(TRUE,FALSE))
	
	#Create a data.frame to store the results
	##############################
	#Estimated and observed results data
	Obs_Est.. <- data.frame()
	#Initialize a data frame for storing model coefficients
	All_Coefficients.. <- data.frame()
	#Initialize a list to store models
	##############
	#Negative Binomial
	NegBin_Models_ <- list()
	#RPART ML models
	Rpart_Models_ <- list()
	#Conditional Inference
	Cond_Inf_Models_ <- list()
	#Random Forest Models
	Rf_Models_ <- list()
	#Create a data frame to store standardized beta coefficients
	Std_Beta_Coeff_ <- list()
	#Set up parallel processing
	cl <- makePSOCKcluster(7)
	registerDoParallel(cl)
	count <- 1
	
	Daily_Counts_Summary..[Daily_Counts_Summary..$Year%in%c("2018","2019"),]
	#Determine devices with multiple years
	x <- Daily.. %>% group_by(Device_Name, User_Type_Desc) %>% summarise(N_Year = length(unique(Year)))
	x <- x[x$N_Year>1,]
	filter(Daily.., Device_Name
	
	for(device_name in unique( Daily_Counts_Summary..$Device_Name )){
	  Select_Data_1.. <-  Daily_Counts_Summary.. [ Daily_Counts_Summary.. $Device_Name%in%device_name,]
	  for(user_type in unique(Select_Data_1..$User_Type_Desc)){
	    #Select counts data for location
	    Select_Data_2.. <- Daily_Counts_Summary.. [Daily_Counts_Summary..$User_Type_Desc%in%user_type & Daily_Counts_Summary..$Device_Name%in%device_name,]
	    #Estimated and observed results data
	    Obs_Est.. <- data.frame()
	    #Do each year 
	    for(year in unique( Select_Data_2..$Year)){
	      #Initialize a list to store models
	      ##############
	      #Negative Binomial
	      NegBin_Models_ <- list()
	      #RPART ML models
	      Rpart_Models_ <- list()
	      #Conditional Inference
	      Cond_Inf_Models_ <- list()
	      #Random Forest Models
	      Rf_Models_ <- list()
	      #Create a data frame to store standardized beta coefficients
	      Std_Beta_Coeff_ <- list()				
	      
	      #Select yearly data			
	      Select_Data_3.. <- Daily..[Daily..$Device_Name%in%device_name & Daily..$User_Type_Desc%in%user_type & Daily..$Year%in%year,]
	      if(nrow(Select_Data_3..) > 0){				
	        #Make an application copy of the climate and daily condition data
	        Apply_Data.. <- Climate_Data.. 
	        #Make a copy of the data
	        Model_Data.. <- Select_Data_3..					
	        
	        #-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	        #Negative binomail regression
	        #-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	        #Define Imputation type object
	        Imputation_Type <- "Negative_Binomial"					
	        #Initialize lists for storage
	        Daily_Mean_APE_ <- list()
	        Daily_Median_APE_ <- list()
	        Est_Sum_Month_ <- list()
	        Obs_Sum_Month_ <- list()
	        Est_Sum_Annual_ <- list()
	        #initialize a dataframe to store negative binomical regression 
	        Coefficients.. <- data.frame()
	        #Initiate a start timer
	        Master_Start_Time <- Sys.time()
	        Start_Time <- Sys.time()
	        
	        for(i in 1:nrow(reg_Mat )){				
	          #Determine months selected
	          Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
	          #Dont do if all true == all months of year 
	          if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
	            #Create input and hold out datasets
	            Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
	            Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
	            #Determine best model specification
	            x <- gsub(" ","",unlist(strsplit(SARM_Models..[SARM_Models..$Device_Name%in%device_name & SARM_Models..$User_Type_Desc%in%user_type,]$Model_Input,",")))
	            x <- x[!(x%in%"")]
	            model_spec <-  as.formula(paste("Counts~",paste(x, collapse ="+"),sep=""))
	            Model <- suppressWarnings(glm.nb(model_spec  , data = Input_Data..,init.theta=1e-6))
	            #Store model object item
	            NegBin_Models_[[paste(device_name, user_type,year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
	            #Store all model coefficient information
	            Temp_Coefficients.. <- as.data.frame(coefficients(summary(Model))) 
	            Temp_Coefficients..$Device_Name <-device_name
	            Temp_Coefficients..$User_Type_Desc <- user_type
	            Temp_Coefficients..$Months_Select <- paste(Months_Select.,collapse="-")
	            Temp_Coefficients..$Year <- year
	            Coefficients.. <- rbind(Coefficients..,Temp_Coefficients..)
	            #Prepare and store standardized beta coefficients
	            Temp_Std_Beta_Coeff.. <- as.data.frame(coefficients(lm.beta(Model)))
	            colnames(Temp_Std_Beta_Coeff..) <- "Coefficient"
	            Temp_Std_Beta_Coeff..$Variable <- rownames(Temp_Std_Beta_Coeff.. )
	            Temp_Std_Beta_Coeff..$Device_Name <-device_name
	            Temp_Std_Beta_Coeff..$User_Type_Desc <- user_type
	            Temp_Std_Beta_Coeff..$Months_Select <- paste(Months_Select.,collapse="-")
	            Temp_Std_Beta_Coeff..$Year <- year
	            #Store in list
	            Std_Beta_Coeff_[[paste(device_name, user_type,paste(Months_Select.,collapse="-"),sep="_")]]  <-  Temp_Std_Beta_Coeff..
	            #Apply model and calculate APE
	            Est.  <- predict(Model, newdata = Holdout_Data.. ) 
	            Obs. <- Holdout_Data..$Counts		
	            Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
	            Temp_Daily..$Date <- Holdout_Data..$Date
	            #Remove records with 0 observed daily counts
	            Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
	            #Calculate APE
	            Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
	            #Define imputation type
	            Temp_Daily..$Imputation_Type <- Imputation_Type
	            #Store summary information
	            ###################
	            #Daily---
	            Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
	            Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
	            #Monthly---
	            Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
	            Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
	            #Annual---
	            Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
	            #Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )							
	          }
	          #Report progress
	          if(length(i[i %% 1000 == 0] == 0) > 0){
	            print(paste(i, " of ",nrow(reg_Mat)," Variables Done",sep=""))
	            print(round(Sys.time() - Start_Time,2))
	            #Reinitiate timer
	            Start_Time <- Sys.time()
	          }
	          #End monthly scenario loop	
	        }
	        #Print total calculation time
	        print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
	        print(round(Sys.time() - Master_Start_Time,2))
	        
	        #Create a data frame to store absolute percent error for day, month, and year
	        ##############################
	        #Create dataframe
	        Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
	                                     User_Type_Desc = user_type, Year = year)
	        #Month
	        Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
	        #Annual 
	        Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
	        #Mean Daily
	        Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
	        #Median Daily
	        Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
	        #Add Imputation type
	        Temp_Obs_Est..$Imputation_Type <- Imputation_Type
	        #Stire in master data frame
	        Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
	        
	        
	        
	        #-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	        #Recursive Partition (Rpart)
	        #-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	        #Define Imputation type object
	        Imputation_Type <- "Rpart"
	        #Set vector of candidate covariates
	        Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Weekday","Is_Holiday")					
	        #Reinitialize lists for storage
	        Daily_Mean_APE_ <- list()
	        Daily_Median_APE_ <- list()
	        Est_Sum_Month_ <- list()
	        Obs_Sum_Month_ <- list()
	        Est_Sum_Annual_ <- list()
	        #Initiate a start timer
	        Master_Start_Time <- Sys.time()
	        Start_Time <- Sys.time()
	        for(i in 1:nrow(reg_Mat )){
	          #Determine months selected
	          Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
	          #Dont do if all true == all months of year 
	          if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
	            #Create input and hold out datasets
	            Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
	            Input_Data..$Weekday <- as.factor(Input_Data..$Weekday)
	            Input_Data..$Is_Weekday <- as.factor(Input_Data..$Is_Weekday)
	            Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
	            #Train model 
	            #rpart2-----
	            #Setup LM control parameters
	            Control_ <- trainControl(method = "repeatedcv",
	                                     number = 10, repeats = 2,
	                                     search = "grid", allowParallel = TRUE)
	            #Setup grid
	            Tune_Grid_ <- data.frame(maxdepth = seq(2,4,1))
	            #Train Model 
	            Model <- train(x=Input_Data..[,Col_Names.],
	                           y=Input_Data..$Counts,	method='rpart2',
	                           trControl = Control_, tuneGrid = Tune_Grid_)
	            #Store model object item
	            #Rpart_Models_[[paste(device_name, user_type, year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
	            
	            #Apply model
	            ###################
	            Est.  <- predict(Model, newdata = Holdout_Data.. ) 
	            Obs. <- Holdout_Data..$Counts		
	            Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
	            Temp_Daily..$Date <- Holdout_Data..$Date
	            #Remove records with 0 observed daily counts
	            Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
	            #Calculate APE
	            Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
	            #Define imputation type
	            Temp_Daily..$Imputation_Type <- Imputation_Type
	            #Store summary information
	            ###################
	            #Daily---
	            Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
	            Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
	            #Monthly---
	            Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
	            Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
	            #Annual---
	            Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
	            #Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )					
	          }					
	          #Report progress
	          if(length(i[i %% 100 == 0] == 0) > 0){
	            print(paste(i, " of ",nrow(reg_Mat)," Variables Done - ",Imputation_Type,sep=""))
	            print(round(Sys.time() - Start_Time,2)); Start_Time <- Sys.time()
	          }
	        }
	        #Print total calculation time
	        print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
	        print(round(Sys.time() - Master_Start_Time,2))
	        
	        #Create a data frame to store absolute percent error for day, month, and year
	        ##############################
	        #Create dataframe
	        Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
	                                     User_Type_Desc = user_type, Year = year)
	        #Month
	        Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
	        #Annual 
	        Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
	        #Mean Daily
	        Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
	        #Median Daily
	        Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
	        #Add Imputation type
	        Temp_Obs_Est..$Imputation_Type <- Imputation_Type
	        #Stire in master data frame
	        Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
	        
	        #-------------------------------------------------------------------------------------------------------------------------------------
	        #Conditional Inference
	        #--------------------------------------------------------------------------------------------------------------------------------------
	        #Define Imputation type object
	        Imputation_Type <- "Conditional_Inference"				
	        #Set vector of candidate covariates
	        Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Weekday","Is_Holiday")					
	        #Reinitialize lists for storage
	        Daily_Mean_APE_ <- list()
	        Daily_Median_APE_ <- list()
	        Est_Sum_Month_ <- list()
	        Obs_Sum_Month_ <- list()
	        Est_Sum_Annual_ <- list()
	        #Initiate a start timer
	        Master_Start_Time <- Sys.time()
	        Start_Time <- Sys.time()
	        for(i in 1:nrow(reg_Mat )){
	          #Determine months selected
	          Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
	          #Dont do if all true == all months of year 
	          if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
	            #Create input and hold out datasets
	            Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
	            Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
	            #Train model 
	            #Conditional Inference
	            #Train model 
	            Model <- train(
	              Counts ~., data = Input_Data..[,c("Counts",Col_Names.)], method = "ctree2",
	              trControl = trainControl("cv", number = 10, allowParallel = TRUE),
	              tuneGrid = expand.grid(maxdepth = 3, mincriterion = 0.95 )
	            )
	            #Store model object item
	            #Cond_Inf_Models_[[paste(device_name, user_type, year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
	            
	            #Apply model
	            ###################
	            Est.  <- predict(Model, newdata = Holdout_Data.. ) 
	            Obs. <- Holdout_Data..$Counts		
	            Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
	            Temp_Daily..$Date <- Holdout_Data..$Date
	            #Remove records with 0 observed daily counts
	            Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
	            #Calculate APE
	            Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
	            #Define imputation type
	            Temp_Daily..$Imputation_Type <- Imputation_Type
	            #Store summary information
	            ###################
	            #Daily---
	            Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
	            Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
	            #Monthly---
	            Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
	            Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
	            #Annual---
	            Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
	            #Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )					
	          }					
	          #Report progress
	          if(length(i[i %% 100 == 0] == 0) > 0){
	            print(paste(i, " of ",nrow(reg_Mat)," Variables Done - ",Imputation_Type,sep=""))
	            print(round(Sys.time() - Start_Time,2)); Start_Time <- Sys.time()
	          }
	        }
	        #Print total calculation time
	        print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
	        print(round(Sys.time() - Master_Start_Time,2))
	        
	        #Create a data frame to store absolute percent error for day, month, and year
	        ##############################
	        #Create dataframe
	        Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
	                                     User_Type_Desc = user_type, Year = year)
	        #Month
	        Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
	        #Annual 
	        Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
	        #Mean Daily
	        Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
	        #Median Daily
	        Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
	        #Add Imputation type
	        Temp_Obs_Est..$Imputation_Type <- Imputation_Type
	        #Stire in master data frame
	        Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
	        
	        #-------------------------------------------------------------------------------------------------------------------------------------
	        #Random forest
	        #--------------------------------------------------------------------------------------------------------------------------------------
	        #Define Imputation type object
	        Imputation_Type <- "Random_Forest"				
	        #Set vector of candidate covariates
	        Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Weekday","Is_Holiday")					
	        #Reinitialize lists for storage
	        Daily_Mean_APE_ <- list()
	        Daily_Median_APE_ <- list()
	        Est_Sum_Month_ <- list()
	        Obs_Sum_Month_ <- list()
	        Est_Sum_Annual_ <- list()
	        #Initiate a start timer
	        Master_Start_Time <- Sys.time()
	        Start_Time <- Sys.time()
	        for(i in 1:nrow(reg_Mat )){
	          #Determine months selected
	          Months_Select. <- month.name[as.logical(unlist(strsplit(paste(reg_Mat[i,] ,collapse = ","),",")))]
	          #Dont do if all true == all months of year 
	          if(length(Months_Select.) > 0 & length(Months_Select.) < 12 ){
	            #Create input and hold out datasets
	            Input_Data.. <- Model_Data..[(Model_Data..$Month%in%Months_Select.),]
	            Holdout_Data.. <- Model_Data..[!(Model_Data..$Month%in%Months_Select.),]
	            #Train model 
	            #Random Forest
	            Control_ <- trainControl(method = "cv", number = 10,search = "grid", allowParallel = TRUE)
	            #Train model 
	            Model <- train(Counts~.,
	                           data = Input_Data..[,c("Counts",Col_Names.)],
	                           method = "rf", metric = "RMSE",  trControl = Control_)
	            #Store model object item
	            # Rf_Models_[[paste(device_name, user_type,year,paste(Months_Select.,collapse="-"),sep="_")]] <- Model
	            
	            #Apply model
	            ###################
	            Est.  <- predict(Model, newdata = Holdout_Data.. ) 
	            Obs. <- Holdout_Data..$Counts		
	            Temp_Daily.. <- data.frame(Obs_Counts = Obs., Est_Counts = Est.)
	            Temp_Daily..$Date <- Holdout_Data..$Date
	            #Remove records with 0 observed daily counts
	            Temp_Daily.. <- Temp_Daily..[Temp_Daily..$Obs_Counts >0,]
	            #Calculate APE
	            Temp_Daily..$APE <-  abs((Temp_Daily..$Obs_Counts - Temp_Daily..$Est_Counts) / Temp_Daily..$Obs_Counts)
	            #Define imputation type
	            Temp_Daily..$Imputation_Type <- Imputation_Type
	            #Store summary information
	            ###################
	            #Daily---
	            Daily_Mean_APE_[[paste(Months_Select.,collapse="-")]] <- mean(	Temp_Daily..$APE)
	            Daily_Median_APE_[[paste(Months_Select.,collapse="-")]] <- median(Temp_Daily..$APE)
	            #Monthly---
	            Est_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Est_Counts)
	            Obs_Sum_Month_[[paste(Months_Select.,collapse="-")]] <- sum(Temp_Daily..$Obs_Counts)
	            #Annual---
	            Est_Sum_Annual_[[paste(Months_Select.,collapse="-")]] <- sum(Input_Data..$Counts) + sum(Est.)
	            #Temp_RMSE_[[paste(Months_Select.,collapse="-")]] <- rmse(Holdout_Data..$Counts	,Est. )					
	          }					
	          #Report progress
	          if(length(i[i %% 100 == 0] == 0) > 0){
	            print(paste(i, " of ",nrow(reg_Mat)," Variables Done - ",Imputation_Type,sep=""))
	            print(round(Sys.time() - Start_Time,2)); Start_Time <- Sys.time()
	          }
	        }
	        #Print total calculation time
	        print(paste("------------------------",Imputation_Type, "Imputation Total Process Time:"))
	        print(round(Sys.time() - Master_Start_Time,2))
	        
	        #Create a data frame to store absolute percent error for day, month, and year
	        ##############################
	        #Create dataframe
	        Temp_Obs_Est.. <- data.frame(Est_Month = unlist(Est_Sum_Month_), Obs_Month = unlist(Obs_Sum_Month_),Est_Annual = unlist(Est_Sum_Annual_), Obs_Annual = sum(Model_Data..$Counts),  Device_Name = device_name, 
	                                     User_Type_Desc = user_type, Year = year)
	        #Month
	        Temp_Obs_Est..$APE_Month <- round(abs((Temp_Obs_Est..$Obs_Month - Temp_Obs_Est..$Est_Month) / Temp_Obs_Est..$Obs_Month),4)
	        #Annual 
	        Temp_Obs_Est..$APE_Annual <- round(abs((Temp_Obs_Est..$Obs_Annual - Temp_Obs_Est..$Est_Annual) / Temp_Obs_Est..$Obs_Annual),4)
	        #Mean Daily
	        Temp_Obs_Est..$Mean_APE_Daily <- round(unlist(Daily_Mean_APE_),4)
	        #Median Daily
	        Temp_Obs_Est..$Median_APE_Daily <- round(unlist(Daily_Median_APE_),4)
	        #Add Imputation type
	        Temp_Obs_Est..$Imputation_Type <- Imputation_Type
	        #Stire in master data frame
	        Obs_Est.. <- rbind(Obs_Est.., Temp_Obs_Est..)
	        
	      }
	      #End Year loop
	      print(year)
	    }
	   
	    print(paste(device_name, " ",user_type, " Done. ", sep=""))
	    #End User loop
	  }	
	  #Print progress on location
	  print(paste(device_name, " Done. ",count, " of ", length(unique( Daily_Counts_Summary..$Device_Name )), sep=""))
	  count <- count + 1
	  #End location loop
	}
	
	
	
	
	
	
#Create tree graphic for illustrative purposes
#--------------------------------------------
  #Set up parallel processing
  cl <- makePSOCKcluster(3)
  registerDoParallel(cl)
  Col_Names. <-  c("TMAX","PRCP","SNOW","Daylight_Mins","Is_Weekday","Is_Holiday")					
  
  #Define input data
  Input_Data.. <- Daily..[Daily..$Device_Name%in%"Portland Ave. Northside" &  Daily..$User_Type_Desc%in%"Bicycle",]
  Input_Data..$TMAX <- (Input_Data..$TMAX /10) * (9/5) +32 
  Input_Data..[,c("Date","TMAX","TMAX_2")]
  #0?C ? 9/5) + 32 = 32?F
	
  #Setup LM control parameters
  Control_ <- trainControl(method = "repeatedcv",number = 10, repeats = 1,search = "grid", allowParallel = TRUE)
  #Setup grid
  Tune_Grid_ <- data.frame(maxdepth = seq(2,4,1))
  #Train Model 
  Model <- rpart(formula = Counts ~ .,data    = Input_Data..[,c("Counts",Col_Names.)],  method  = "anova",model=TRUE)
  
  #Show example tree
  fancyRpartPlot(Model, caption = NULL,main = "Decision Tree Example\nDaily Features and Bicycle Counts\nMethod: Recursive Partioning",tweak  = 1.5)
  
  #Pull out variable importance infomration
  Var_Imp.. <- varImp(Model)
  dat <- Var_Imp..
  dat$Feature <- rownames(dat)
  dat <- dat[order(dat$Overall),]
  dat$Feature <- factor(dat$Feature, levels = dat$Feature)
  #Chart
  ggplot(dat, aes(x = Feature, y = Overall)) +
    geom_bar(position="dodge", stat="identity", color = "black", fill = "grey") +
    #geom_text(aes(x = Feature, y = Overall, fill = Spec)) +
    ggtitle("Example of Variable Importance for Imputation Problem") + 
    theme(plot.title = element_text(hjust = 0.5)) +
    labs(x = "Feature", y = "Overall Importance") +
    # scale_y_continuous(labels = percent) +
    coord_flip() + 
    theme(legend.position = "none") +
    theme(text = element_text(size=20)) 
  
    
  
  
	