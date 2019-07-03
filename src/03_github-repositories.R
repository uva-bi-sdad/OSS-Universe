#devtools::install_github("ropensci/ghql")
library("ghql")
library("jsonlite")
library("httr")

# Initializing client
token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")

cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)

# Since not every GraphQL server has a schema at the base URL, have to manually load the schema in this case
cli$load_schema()

# Make a Query class object
qry <- Query$new()

# Make the initial query of the first 100 records
qry$query('getmydata',
          '{
            rateLimit {
              cost
              remaining
              resetAt
            }
            search(query: "license:mit", type: REPOSITORY, first : 100) {
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


# Parse the result
result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))


# If 400 bad request
# If zero result

# If 200 OK
# Get the first 100 repository names
output <- data.frame(result$data$search$edges$node$name)


while (result$data$search$pageInfo$hasNextPage) {
  # Get the end cursor
  nextpage <- result$data$search$pageInfo$endCursor

  qry$query('getmydata',
            '{
              rateLimit {
                cost
                remaining
                resetAt
              }
              search(query: "license:mit", type: REPOSITORY, first: 100, after: nextpage) {
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
  
  output <- rbind.data.frame(output, data.frame(result$data$search$edges$node$name))
    
 
}










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













