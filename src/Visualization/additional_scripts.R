###This script produces some results that are not included in the final products:
#Match contributors' locations to countries
#Number of average contributors per repo

library(maps)
library(RPostgreSQL)
library(data.table)
library(ggplot2)
library(tidyverse)

# Setting root directory
knitr::opts_knit$set(echo = TRUE,
                     root.dir = rprojroot::find_rstudio_root_file())

data <- fread("./data/oss/final/Github/all_repos_commits.csv")

###Match locations to countries
#We uses the country names in package "maps" to match with the locations. 
locations <- unique(data$location) %>% data.frame()
# Loading country data  
data(world.cities)
#Removing punctuation
raw <- gsub("[[:punct:]\n]","",locations[,1])
# Split data at word boundaries
raw2 <- strsplit(raw, " ")
# Match on country in world.countries. This takes a while.  
CountryList_raw <- (lapply(raw2, function(x)x[which(toupper(x) %in% toupper(world.cities$country.etc))]))

match <- do.call(rbind, lapply(CountryList_raw, as.data.frame))


#####Number of average contributors per repo
comm <- data %>% group_by(repo_slug, license) %>% summarize(commits=sum(commit_cnt))%>%na.omit()
comm <- comm %>% group_by(license) %>% summarize(mean_per_repo=mean(commits))
