#devtools::install_github("ropensci/ghql")
library(ghql)
library(jsonlite)
library(httr)
library(stringr)
library(data.table)

# Initializing client
token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")

cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)

# Since not every GraphQL server has a schema at the base URL, have to manually load the schema in this case
cli$load_schema()

search_by_license <- function(license_name) {
  
  # Make a Query class object
  qry <- Query$new()

  # Make the initial query of the first 100 records
  qry$query('getmydata',str_interp(
         '{
            rateLimit {
              cost
              remaining
              resetAt
            }
            search(query: "license:${license_name}", type: REPOSITORY, first : 100) {
              repositoryCount
              pageInfo {
                endCursor
                startCursor
                hasNextPage
              }
              edges {
                node {
                  ... on Repository {

                    owner {
                      login
                    }
                    name
                  }
                }
              }
            }
          }'))


  # Parse the result
  result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))

  if (is.null(result$data)) {
    return(value = str_interp(string = "License ${license_name} has 0 count."))
  } 
  
  count <- result$data$search$repositoryCount
  output <- data.table(result$data$search$edges$node$name)
  nextpage <- result$data$search$pageInfo$hasNextPage
  
  while (nextpage) {
  # Get the end cursor
  cursor <- result$data$search$pageInfo$endCursor
  qry_string <- str_interp('{
              rateLimit {
                cost
                remaining
                resetAt
              }
              search(query: "license:${license_name}", type: REPOSITORY, first: 100, after: ${cursor}) {
                repositoryCount
                pageInfo {
                  endCursor
                  startCursor
                  hasNextPage
                }
                edges {
                  node {
                    ... on Repository {
                      owner {
                        login
                      }
                      name
                    }
                  }
                }
              }
            }')
  qry <- Query$new()
  qry$query('getmydata', qry_string)         
  
  result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))
  output <- rbind(output, data.table(result$data$search$edges$node$name))
  nextpage <- result$data$search$pageInfo$hasNextPage
  
  if (result$data$rateLimit$remaining == 1){
    while (Sys.time() < result$data$rateLimit$resetAt) {
      Sys.sleep(3600)
    }
  }
  }
  
  print(str_interp("License ${license_name} has ${count} counts"))
  output
}


search_by_license("ISC")









##============================

url="https://api.github.com/graphql"

auth_header <- paste("bearer", '963108f94c445eb2e50587013c0356bfce308ff1')
agent="ccong2"

pbody <-  'query{
  rateLimit {
    cost
    remaining
    resetAt
  }
  search(query: "license:mit", type: REPOSITORY, first: 20) {
    repositoryCount
    pageInfo {
      endCursor
      startCursor
    }
    edges {
      node {
        ... on Repository {
          owner {
            login
          }
          name
        }
      }
    }
  }
}'


res <- POST(url, body = rjson::toJSON(pbody),  
            add_headers(Authorization=auth_header,`User-Agent` = agent))

library(stringr)
body<-str_remove_all(body,"\n")
body<-rjson::toJSON(body)
body<-str_remove_all(body,"")

res <- content(res, as = "parsed", encoding = "UTF-8")













