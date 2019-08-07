# Code to connect the github repos that we scraped to the repositories on Aaron's data.
# Results are saved as oss -> universe -> all_repos_commits_201x
# Calvin Isch

library(data.table)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)

# Connect DB
library(RPostgreSQL)
conn <- dbConnect(drv = PostgreSQL(),
                  dbname = "oss",
                  host = "postgis_1",
                  port = 5432L,
                  user = Sys.getenv("db_userid"),
                  password = Sys.getenv("db_pwd"))

# All of the data-bases we have sived on PostgreSQL
all_dbs <- c("reponames_2012_2","reponames_2013_2","reponames_2014","reponames_2015","reponames_2016_2","reponames_2017","reponames_2018")
years <- c("2012","2013","2014","2015","2016","2017","2018")
new_db <- c("all_repos_commits_2012","all_repos_commits_2013","all_repos_commits_2014","all_repos_commits_2015","all_repos_commits_2016","all_repos_commits_2017","all_repos_commits_2018")

for (i in 1:length(all_dbs)){
  
  # Get's the repos with licenses that we care about and makes it cleaner
  all_year <- dbReadTable(conn = conn, name = c(schema = "universe", name = all_dbs[i]))
  all_year$repo_slug <- paste(all_year$login,"/",all_year$reponame,sep="")
  all_year <- all_year %>%
    select(repo_slug,license)
  all_year$year_repo <- years[i]
  unique_year <- unique(all_year)
  
  # Reads aarons giant file in chunks and gets the repos that match
  check1 <- fread("../OSS-Universe/data/oss/oss2/github_big_queries/pushers/xx00", sep=",")
  a <- colnames(check1)
  # Join the two
  all_year_1 <- inner_join(check1, unique_year, by ="repo_slug")
  remove(check1)
  
  check2 <- fread("../OSS-Universe/data/oss/oss2/github_big_queries/pushers/xx01", sep=",")
  colnames(check2) <- a
  all_year_2 <- inner_join(check2, unique_year, by ="repo_slug")
  remove(check2)
  
  check3 <- fread("../OSS-Universe/data/oss/oss2/github_big_queries/pushers/xx02", sep=",")
  colnames(check3) <- a
  all_year_3 <- inner_join(check3, unique_year, by ="repo_slug")
  remove(check3)
  
  check4 <- fread("../OSS-Universe/data/oss/oss2/github_big_queries/pushers/xx03", sep=",")
  colnames(check4) <- a
  all_year_4 <- inner_join(check4, unique_year, by ="repo_slug")
  remove(check4)
  
  # combine all 3
  all_year_done <- rbindlist(list(all_year_1, all_year_2, all_year_3, all_year_4))
  remove(all_year_1)
  remove(all_year_2)
  remove(all_year_3)
  remove(all_year_4)
  
  # write it to the database.
  dbWriteTable(conn = conn,
               name = c(schema = "universe", name = new_db[i]),
               value = all_year_done,
               append = TRUE,
               row.names = FALSE)
  
  remove(all_year_done)
  remove(all_year)
  remove(unique_year)
}






