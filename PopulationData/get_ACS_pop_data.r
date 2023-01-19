
############################## update US population ###############################
update_pop <- function(years = c(2011:2019, 2021), geo="us"){
  res <- vector("list",length(years))
  names(res) <- years
  
  for (y in years){
    # download data
    if(geo=="us"){
      ld <- as.data.frame(get_acs(year = y,
                                  geography=geo,
                                  survey='acs1',
                                  variables = 'B01003_001E'))
    }else{
      ld <- as.data.frame(get_acs(year = y,
                                  geography=geo,
                                  survey='acs1',
                                  variables = 'B01003_001E',
                                  state="OR"))
    }
    
    # reshape long to wide
    ld2 <- reshape(ld,
                   idvar="GEOID",
                   timevar="variable",
                   direction="wide",
                   drop=c("NAME","moe"))
    # insert into list and add in year
    res[[y]] <- ld2
    res[[y]]$year <- y
  }
  
  # Combining the data frames together for final analysis
  combo <- do.call("rbind",res)
  return(combo[,-which(names(combo)=="GEOID")])
}

uspop <- update_pop()

pop20 <- get_decennial(geography = "us",
                       year = 2020,
                       variables = 'P1_001N')

pop10 <- get_decennial(geography = "us",
                       year = 2010,
                       variables = 'P001001')

GEO <- "United States"
for(year in 2010:2021){
  if(year == 2010){
    pop[pop$YEAR==year & pop$GEOGRAPHY==GEO, "POPULATION"] <- pop10$value
  }else if(year == 2020){
    pop[pop$YEAR==year & pop$GEOGRAPHY==GEO, "POPULATION"] <- pop20$value
  }else{
    pop[pop$YEAR==year & pop$GEOGRAPHY==GEO, "POPULATION"] <- uspop[uspop$year==year, "estimate.B01003_001"]
  }
}

############################## update OR population ###############################
orpop <- update_pop(geo = "state")

pop20or <- get_decennial(geography = "state",
                         year = 2020,
                         variables = 'P1_001N',
                         state="OR")

pop10or <- get_decennial(geography = "state",
                         year = 2010,
                         variables = 'P001001',
                         state="OR")

GEO <- "Oregon"
for(year in 2010:2021){
  if(year == 2010){
    pop[pop$YEAR==year & pop$GEOGRAPHY==GEO, "POPULATION"] <- pop10or$value
  }else if(year == 2020){
    pop[pop$YEAR==year & pop$GEOGRAPHY==GEO, "POPULATION"] <- pop20or$value
  }else{
    pop[pop$YEAR==year & pop$GEOGRAPHY==GEO, "POPULATION"] <- orpop[orpop$year==year, "estimate.B01003_001"]
  }
}