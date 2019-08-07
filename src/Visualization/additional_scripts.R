###This script produces some results that are not included in the final products:
#Match contributors' locations to countries
#Number of average contributors per repo

library(maps)
library(RPostgreSQL)
library(data.table)
library(ggplot2)
library(tidyverse)
library(treemap)

# Setting root directory
knitr::opts_knit$set(echo = TRUE,
                     root.dir = rprojroot::find_rstudio_root_file())

data <- fread("./data/oss/final/Github/all_repos_commits.csv")

###Match locations to countries
locations <- unique(data$location) %>% data.frame()
# Loading country data from package maps
data(world.cities)
#Removing punctuation
raw <- gsub("[[:punct:]\n]","",locations[,1])
# Split data at word boundaries
raw2 <- strsplit(raw, " ")
# Match on country in world.countries
CountryList_raw <- (lapply(raw2, function(x)x[which(toupper(x) %in% toupper(world.cities$country.etc))]))

match <- do.call(rbind, lapply(CountryList_raw, as.data.frame))


#####Number of average contributors per repo
comm <- data %>%group_by(license)%>%summarize(commits=mean(Total_commit))%>%
  arrange(desc(commits))%>% na.omit()
colnames(comm) <-c("license","commits")
comm <- data.frame(comm)
comm$license <- as.factor(comm$license)
comm$commits <- as.numeric(comm$commits)