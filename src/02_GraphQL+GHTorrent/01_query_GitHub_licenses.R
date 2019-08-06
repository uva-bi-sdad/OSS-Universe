###This script creates functions that query GitHub repos with specific licenses created during a specific period of time
###We use this script to get the slugs, licenses, and save each year's data in a separate table in the database.
###The tables are saved as oss -> universe -> reponames_201x

library(ghql)
library(jsonlite)
library(httr)
library(stringr)
library(data.table)
library(lubridate)
library(stringr)
library(RPostgreSQL)
library(purrr)

# Save a github token to your system environment or save it here.
token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")


# CHANGE UPDATE DBSaved and DATES
databaseSaved <- "reponames_2016_2" #This specifies the table name you want to save in the database
# change the start date when it breaks
all_start_t <- c("2016-01-01")
all_end_t <- c("2016-12-31")

# These are the licenses that you check for
licenses2 <- c("MIT","GPL-3.0","Apache-2.0","BSD-3-Clause","GPL-2.0", "ISC", "LGPL-2.1", "LGPL-3.0", "AGPL-3.0", "Artistic-2.0", "EPL-1.0", "EPL-2.0", "Zlib")
# These are the hour time frames for each of them, because of how the code works you can't
# do more than every 72 hours
time_frames2 <- time_frames <- c(6, 24, 8, 8, 24, 24, 24, 48, 48, 48, 48, 48, 48) 

# For each of those licenses and time frames it does do it.
for (i in 1:length(licenses2)) {
  print(paste(licenses2[i],time_frames2[i]))
  license <- licenses2[i]
  all_time_t <- c(time_frames2[i])
  doIt()
}



# This specifies the number of quiries to do a time. Don't change it.
numOfIntervals = 10

# If you want to do the licenses one by one you change these:
#all_time_t <- c(12)
#license <- "Apache-2.0"
# doIt()

# calls the doItAllFunction
# this function is technically redundant now because of improvements in the code.
doIt <- function() {
  badIntervals <- c()
  for (i in 1:length(all_start_t)){
    doItAllHours(all_start_t[i],all_end_t[i],all_time_t[i])
  }
}

# Performs a number of functions for the time intervals
doItAllHours <- function(s,e,i){
  print(paste("currently looking between,",s,e,"for time interval",i,"in hours."))
  # returns a series of dates that breaks down the time interval into chunks
  # based on the number of hours specified.
  allIntervals <- getDates2(s,e,i)
  for (j in 1:length(allIntervals[[1]])){
    # Gets chunks again, but for smaller sections within it.
    all_Intervals <- allDates2(allIntervals[[1]][j],allIntervals[[2]][j], i)
    # changes intervals to workable type
    intervals <- all_Intervals[[1]]
    print("---------------------")
    print(intervals)
    # tries to query github with each of those intervals
    tryCatch(expr = {
      badIntervals <- c()
      outList <- queryGithub(intervals)
      clean_Data <- cleanData(outList)
      print("----Example User----")
      print(clean_Data$login[3])
      print("---Uploading to Database---")
      updateDataBase(clean_Data)
    },
    error = function(e) {
      print("SOMETHING BROKE")
      badIntervals <- c(badIntervals,intervals)
      bI <- data.table(date = intervals)
      conn <- dbConnect(drv = PostgreSQL(),
                        dbname = "oss",
                        host = "postgis_1",
                        port = 5432L,
                        user = Sys.getenv("db_userid"),
                        password = Sys.getenv("db_pwd"))
      
      dbWriteTable(conn = conn,
                   name = c(schema = "universe", name = "errors"),
                   value = bI,
                   append = TRUE,
                   row.names = FALSE)
      on.exit(expr = dbDisconnect(conn = conn))
    }
    )
  }
}

# Helper function that returns time intervals
find_time_intervals <- function(starttime,endtime,hour){
  start_time <- as_datetime(x = starttime)
  end_time <- as_datetime(x = endtime)
  period_length <- hour
  num_interval <- as.integer(ceiling(difftime(end_time,start_time)*24/period_length))
  times <- seq.POSIXt(from = start_time,
                      to = end_time,
                      length.out = num_interval)
  len <- length(x = times) - 1L
  start_times <- times[1:len]
  end_times <- times[-1L] - seconds()
  end_times[len] <- end_time
  string <- str_c(start_times, "..", end_times)
  str_replace_all(string, " ", "T")
}

# Returns a series of start and end dates between two dates with intervals of 20*i
getDates2 <- function(startD, endD, j) {
  all <- find_time_intervals(startD,endD,j*numOfIntervals)
  startDays <- c()
  endDays <- c()
  for (m in all){
    startDays <- c(startDays,substring(m,0,10))
    endDays <- c(endDays,substring(m,22,31))
  }
  return(list(startDays,endDays))
}

# Create lists of the start and end dates that you care about and run them
# Same but w/ hours
allDates2 <- function(startDates,endDates,i) {
  for (d in 1:length(startDates)) {
    date <- find_time_intervals(startDates[d],paste(endDates[d],"23:59:59"),i)
    if (exists("all_dates")) {
      all_dates <- append(all_dates, list(date))
    } else {
      all_dates <- list(date)
    }
  }
  return(all_dates)
}

# Cleans the messy data received from Congs function
cleanData <- function(out_list) {
  out_df <- data.frame(t(sapply(out_list,c)))
  out_df <- data.table(time = unlist(out_df$V4),
                       reponame = unlist(out_df$name), login = unlist(out_df$owner),
                       license = unlist(out_df$licenseInfo))
  return(out_df)
}

# Connects to the database and updates it. You need to change what database 
# Your're saving to.
updateDataBase <- function(finalTable) {
  conn <- dbConnect(drv = PostgreSQL(),
                    dbname = "oss",
                    host = "postgis_1",
                    port = 5432L,
                    user = Sys.getenv("db_userid"),
                    password = Sys.getenv("db_pwd"))
  
  dbWriteTable(conn = conn,
               name = c(schema = "universe", name = databaseSaved),
               value = finalTable,
               append = TRUE,
               row.names = FALSE)
  on.exit(expr = dbDisconnect(conn = conn))
}

# Connects to the github GraphQL API
queryGithub<- function(interval) {
  # pass it as a character vector
  out_list <- vector("list",length(interval))
  cli <- GraphqlClient$new(
    url = "https://api.github.com/graphql",
    headers = add_headers(Authorization = paste0("Bearer ", token))
  )
  # Since not every GraphQL server has a schema at the base URL, have to manually load the schema in this case
  cli$load_schema()
  for (i in 1:length(interval)){
    qry_initial <- str_interp('{
                              rateLimit {
                              cost
                              remaining
                              resetAt
                              }
                              search(query: "license:${license} created:${interval[i]}", type: REPOSITORY, first: 100) {
                              repositoryCount
                              pageInfo {
                              endCursor
                              startCursor
                              hasNextPage
                              }
                              nodes {
                              ... on Repository {
                              name
                              owner{
                              login
                              }
                              licenseInfo{
                              spdxId
                              }
                              }
                              }
                              }
  }'
)
    # Conduct the query
    qry <- Query$new()
    qry$query('getmydata',qry_initial)
    # Read the results
    result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))
    # Total repo number
    count <- result$data$search$repositoryCount
    # The first page of results
    output <- as.list(result$data$search$nodes)
    # If it has the next page
    nextpage <- result$data$search$pageInfo$hasNextPage
    
    if (is.null(result$data)) {
      return(value = str_interp(string = str_interp("License mit at ${interval[i]} has 0 count.")))
    } 
    
    if (count <= 1000){
      #dt <- data.table(output$name,output$owner$login,output$createdAt,output$updatedAt,output$defaultBranchRef$target$history)
      while (nextpage) {
        #Sys.sleep(10)
        # Get the end cursor
        cursor <- result$data$search$pageInfo$endCursor
        qry_after <- str_interp('{
                                rateLimit {
                                cost
                                remaining
                                resetAt
                                }
                                search(query: "license:${license} created:${interval[i]}", type: REPOSITORY, first:100, after:"${cursor}") {
                                repositoryCount
                                pageInfo {
                                endCursor
                                startCursor
                                hasNextPage
                                }
                                nodes {
                                ... on Repository {
                                name
                                owner{
                                login
                                }
                                licenseInfo {
                                spdxId
                                }
                                }
                                }
                                }
      }'
)
        qry <- Query$new()
        qry$query('getmydata', qry_after)
        result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))
        if (is_empty(result$data$search$nodes)) {
          return()
        } else {
          output <- mapply(c, output, as.list(result$data$search$nodes), SIMPLIFY=FALSE)
        }
        nextpage <- result$data$search$pageInfo$hasNextPage
        }#END OF WHILE
      print(str_interp("License mit at ${interval[i]} has ${count} counts"))
      }
    
    if (count >  1000){
      x <- data.table(dates = interval[i])
      conn <- dbConnect(drv = PostgreSQL(),
                        dbname = "oss",
                        host = "postgis_1",
                        port = 5432L,
                        user = Sys.getenv("db_userid"),
                        password = Sys.getenv("db_pwd"))
      
      dbWriteTable(conn = conn,
                   name = c(schema = "universe", name = "tooMany"),
                   value = x,
                   append = TRUE,
                   row.names = FALSE)
      on.exit(expr = dbDisconnect(conn = conn))
      return(value = str_interp(string = str_interp("License mit at ${interval[i]} has more than 1000 count.")))
    }
    
    # Transform to dataframe
    output[[4]] <- as.list(rep(interval[i],length(output$name)))
    out_list[[i]] <- output
    # Add the remaining check
    if (result$data$rateLimit$remaining == 0){
      while(Sys.time() < result$data$rateLimit$resetAt){
        Sys.sleep(60)
      }
    }
    }
  return(out_list)
  }





