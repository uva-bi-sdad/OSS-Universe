# Save initial thing from Github as a data.table
result2 <- as.data.table(result)

# Takes only the important values from the query, and turns it to datatable
queryResults2 <- as.data.table(result2$data[2])

# The number of repos found in this query
amountRepos <- queryResults2[[1,1]]

# Gets the section of the DT that has more info form the query
moreInfo <- as.data.table(queryResults2[[3,1]])

# Gets the commit history for each repo
commitHistory <- moreInfo$defaultBranchRef

# Looks at the commits for the first repo
firstRepoCommit <- (commitHistory[[2]][1,1])

# Looks at the authors for that first repo
View(firstRepoCommit$nodes[[1]]$author)

# For every repository, gets all of the commits and binds them together into one 
for (i in 1:length(commitHistory[[2]]$history$nodes)) {
  # Creates a data.table of the current repository's commit history
  currentRepo <- data.table(
    authorId = commitHistory[[2]]$history$nodes[[i]]$author$user$id,
    additions = commitHistory[[2]]$history$nodes[[i]]$additions,
    deletions = commitHistory[[2]]$history$nodes[[i]]$deletions
    # We also want to get 
  )
  # Binds the current repo's commit history to the list of existing commit history
  if (exists("allRepos")) {
    allRepos <- rbindlist(list(currentRepo, allRepos))
  } else {
    allRepos <- currentRepo
  }
}

# Creates a data.table of the authors
author<- data.table(
  email = firstRepoCommit$nodes[[1]]$author$email,
  id = firstRepoCommit$nodes[[1]]$author$user$id
)
