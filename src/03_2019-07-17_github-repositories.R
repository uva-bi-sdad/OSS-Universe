#devtools::install_github("ropensci/ghql")
library(ghql)
library(jsonlite)
library(httr)
library(stringr)
library(data.table)
library(lubridate)
library(stringr)
library(RPostgreSQL)

# Run the two functions that make intervals for dates and time
find_date_intervals <- function(startdate,enddate,length){ 
  start_date <- as_date(x = startdate)
  end_date <- as_date(x = enddate)
  period_length <- length
  num_interval <- as.integer(ceiling(difftime(end_date,start_date)/period_length))
  dates <- seq.Date(from = start_date,
                    to = end_date,
                    length.out = num_interval)
  len <- length(x = dates) - 1L
  start_dates <- dates[1:len]
  end_dates <- dates[-1L] - days()
  end_dates[len] <- end_date
  str_c(start_dates, "..", end_dates)
}

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

##Examples of creating intervals:
intervals <- find_date_intervals("2011-08-14", "2011-09-14",15) # Format: (startdate, enddate, days)
#intervals <- find_time_intervals("2016-5-1 00:00:00","2016-5-3 23:59:00",6) # Format: (starttime from 00:00:00, endtime to 23:59:00, hours)


# Initializing client
token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")

cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)


# Since not every GraphQL server has a schema at the base URL, have to manually load the schema in this case
cli$load_schema()
# pre-allocate list
out_list <- vector("list",length(intervals))

for (i in 1:length(intervals)){
  qry_initial <- str_interp('{
                            rateLimit {
                            cost
                            remaining
                            resetAt
                            }
                            search(query: "license:mit created:${intervals[i]}", type: REPOSITORY, first: 100) {
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
    return(value = str_interp(string = str_interp("License mit at ${intervals[i]} has 0 count.")))
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
                              search(query: "license:mit created:${intervals[i]}", type: REPOSITORY, first:100, after:"${cursor}") {
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
      output <- mapply(c, output, as.list(result$data$search$nodes), SIMPLIFY=FALSE)
      nextpage <- result$data$search$pageInfo$hasNextPage
      }#END OF WHILE
    print(str_interp("License mit at ${intervals[i]} has ${count} counts"))
    }
  
  if (count >  1000){
    start <- as.Date(strsplit(intervals[i], "[..]")[[1]][1])
    end <- as.Date(strsplit(intervals[i], "[..]")[[1]][3])
    itv_1 <- str_c(start, "..",start+(end -start)/2-1)
    itv_2 <- str_c(start+(end -start)/2, "..", end)
    
    # For itv_1
    sum_1 <- count
    while (nextpage) {
        cursor <- result$data$search$pageInfo$endCursor
        qry_after <- str_interp('{
                                rateLimit {
                                cost
                                remaining
                                resetAt
                                }
                                search(query: "license:mit created:${itv_1}", type: REPOSITORY, first:100, after:"${cursor}") {
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
      output <- mapply(c, output, as.list(result$data$search$nodes), SIMPLIFY=FALSE)
      nextpage <- result$data$search$pageInfo$hasNextPage
      }#END OF WHILE
    output_itv_1 <- output

    # For itv_2
    qry <- Query$new()
    qry$query('getmydata',str_interp('{
                            rateLimit {
                                     cost
                                     remaining
                                     resetAt
  }
                                     search(query: "license:mit created:${itv_2}", type: REPOSITORY, first: 100) {
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
))
    result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))
    sum_2 <- result$data$search$repositoryCount
    output <- as.list(result$data$search$nodes)
    nextpage <- result$data$search$pageInfo$hasNextPage
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
                              search(query: "license:mit created:${itv_2}", type: REPOSITORY, first:100, after:"${cursor}") {
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
      output <- mapply(c, output, as.list(result$data$search$nodes), SIMPLIFY=FALSE)
      nextpage <- result$data$search$pageInfo$hasNextPage
      }#END OF WHILE
    output_itv_2 <- output

    output <- mapply(c, output_itv_1,output_itv_2, SIMPLIFY=FALSE)
    count <- sum_1 
    print(str_interp("License mit at ${intervals[i]} has ${count} counts"))
  }
  
  # Transform to dataframe
  output[[4]] <- as.list(rep(intervals[i],length(output$name)))
  out_list[[i]] <- output
  # Add the remaining check
  if (result$data$rateLimit$remaining == 0){
    while(Sys.time() < result$data$rateLimit$resetAt){
      Sys.sleep(60)
    }
  }
  }

# Make the final dateframe
out_df <- data.frame(t(sapply(out_list,c)))
out_df <- data.table(time = unlist(out_df$V4),
                  reponame = unlist(out_df$name), login = unlist(out_df$owner),
                  license = unlist(out_df$licenseInfo))

# Write into the database
  conn <- dbConnect(drv = PostgreSQL(),
                    dbname = "oss",
                    host = "postgis_1",
                    port = 5432L,
                    user = Sys.getenv("db_userid"),
                    password = Sys.getenv("db_pwd"))

  dbWriteTable(conn = conn,
               name = c(schema = "universe", name = "reponames"),
               value = out_df,
               append = TRUE,
               row.names = FALSE)
  on.exit(expr = dbDisconnect(conn = conn))


