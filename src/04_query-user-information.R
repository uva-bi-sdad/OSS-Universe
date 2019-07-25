library(ghql)
library(jsonlite)
library(httr)
library(stringr)
library(stringr)
library(RPostgreSQL)


# Initializing client
token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")

cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)


# Since not every GraphQL server has a schema at the base URL, have to manually load the schema in this case
cli$load_schema()

qry <- Query$new()
qry$query('getmydata','{
  user(login: "ccong2") {
    email
    login
    organizations(first: 1) {
      nodes {
        name
        location
      }
    }
  }
}')

# Read the results
result <- jsonlite::fromJSON(cli$exec(qry$queries$getmydata))
  
  
  