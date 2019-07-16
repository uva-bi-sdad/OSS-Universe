search_by_timeframe(starttime,endtime,step){
  start_date <- seq.Date(from = as_date(x = starttime),
                         to = as_date(x = endtime),
                         by = step)
  intervals <- str_c(start_date, "..", start_date + days(x = 29L))
  
  
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
      return(value = str_interp(string = str_interp("License mit at ${intervals[i]} has more than 1000 count.")))
    }
    
    output[[4]] <- as.list(rep(intervals[i],length(output$name)))
    
    out_list[[i]] <- output
    }
  
  
  df <- data.frame(t(sapply(out_list,c)))
  
  df2 <- data.table(time = unlist(df$V4),
                    reponame = unlist(df$name), owner = unlist(df$owner),
                    license = unlist(df$licenseInfo))
  
}