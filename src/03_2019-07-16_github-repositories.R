#devtools::install_github("ropensci/ghql")
library(ghql)
library(jsonlite)
library(httr)
library(stringr)
library(data.table)
library(lubridate)
library(stringr)
library(RPostgreSQL)

# Make time intervals
period_length <- 30L
start_date <- seq.Date(from = as_date(x = "2008-01-01"),
                       to = as_date(x = "2010-02-28"),
                       by = period_length)
intervals <- str_c(start_date, "..", start_date + days(x = period_length-1))



##THIS IS FOR DATE&TIME##
#start_hour <- seq.POSIXt(from=as_datetime("2016-07-15 00:00:00"), 
                        # to=as_datetime("2016-07-18 23:59:00"),by=3600*6)
#intervals <- str_c(start_hour, "..", start_hour + hours(6))
#intervals <- str_replace_all(intervals ," ","T")
##=====================##


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
  
  qry <- Query$new()
  qry$query('getmydata',qry_initial)
  
  result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))
  count <- result$data$search$repositoryCount
  output <- as.list(result$data$search$nodes)
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
    return(value = str_interp(string = str_interp("##### ${intervals[i]} has more than 1000 count #####")))
  }
  
  output[[4]] <- as.list(rep(intervals[i],length(output$name)))
  out_list[[i]] <- output
  }

# Make the final dateframe
out_df <- data.frame(t(sapply(out_list,c)))
out_df <- data.table(time = unlist(out_df$V4),
                  reponame = unlist(out_df$name), login = unlist(out_df$owner),
                  license = unlist(out_df$licenseInfo))

# Write into the database
reponames_to_bd <- function() {
  conn <- dbConnect(drv = PostgreSQL(),
                    dbname = "oss",
                    host = "postgis",
                    port = 5432L,
                    user = Sys.getenv("db_userid"),
                    password = Sys.getenv("db_pwd"))

  dbWriteTable(conn = conn,
               name = c(schema = "universe", name = "reponames"),
               value = out_df,
               append = TRUE,
               row.names = FALSE)
  on.exit(expr = dbDisconnect(conn = conn))
}

