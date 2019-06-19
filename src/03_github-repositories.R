
##============================

library(httr)

auth_header <- paste('bearer', 'fc735803fd147b3562271439a1863957b5611496')

test<-httr::POST(url="https://api.github.com/graphql", 
                 add_headers(Authorization = auth_header),
                 encode="json",
                 body='{
                   rateLimit {
                     cost
                     remaining
                     resetAt
                   }
                   search(query: "license:mit", type: REPOSITORY, first: 100) {
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
                 }')


res <- content(test, as = "parsed", encoding = "UTF-8")













