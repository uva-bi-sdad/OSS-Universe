#devtools::install_github("ropensci/ghql")
library("ghql")
library("jsonlite")
library("httr")

token <- '963108f94c445eb2e50587013c0356bfce308ff1'
cli <- GraphqlClient$new(
  url = "https://api.github.com/graphql",
  headers = add_headers(Authorization = paste0("Bearer ", token))
)

cli$load_schema()
qry <- Query$new()

qry$query('getmydata','{
          rateLimit {
          cost
          remaining
          resetAt
          }
          search(query: "license:mit", type: REPOSITORY,first:100,after:"Y3Vyc29yOjEwMA==") {
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


resp <- cli$exec(qry$queries$getmydata)

fj <- jsonlite::fromJSON(resp)

fj$data$search$edges$node$name


fj$data$search$pageInfo$endCursor

while (fj$data$repository$issues$pageInfo$hasNextPage) {

  qry$queries$getissues$query <- sprintf(getIssues, cursor)
  q <- cli$exec(qry$queries$getissues)
  cursor <- q$data$repository$issues$pageInfo$endCursor
  issues <- c(issues, q$data$repository$issues$edges$node$number)
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













