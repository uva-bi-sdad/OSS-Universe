queryDat = "2010-01-01"

makePretty <- function(res,queryDate) {
  
  # Save initial thing from Github as a data.table
  result2 <- as.data.table(result)
  
  # Takes only the important values from the query, and turns it to datatable
  queryResults2 <- as.data.table(result2$data[2])
  
  # Creates a table with information about the query
  allQueries <- data.table(
    date = queryDate,
    numRepos = queryResults2[[1,1]]
  )
  
  
  # Gets the information necessary in order to get num commits for a repo
  repoInfo <- as.data.table(result2$data[2])[[3,1]][[3]]
  
  # Creates a data table with the repository-specific information
  allRepos <- data.table(
    name = as.data.table(result2$data[2])[[3,1]][[1]],
    owner = as.data.table(result2$data[2])[[3,1]][[2]],
    defBranch = repoInfo$name,
    numCommits = repoInfo$target$history$totalCount,
    date = queryDate
  )
  
  
  # Gets the section of the DT that has more info form the query
  moreInfo <- as.data.table(queryResults2[[3,1]])
  # Gets the commit history for each repo
  commitHistory <- moreInfo$defaultBranchRef
  
  # For every repository, gets all of the commits and binds them together into one data table
  # Also gets the authors of those commits and writes them into a table.
  for (i in 1:length(commitHistory[[2]]$history$nodes)) {
    
    # Creates a data.table of the current repository's commit history
    currentRepo <- data.table(
      authorId = commitHistory[[2]]$history$nodes[[i]]$author$user$id,
      additions = commitHistory[[2]]$history$nodes[[i]]$additions,
      deletions = commitHistory[[2]]$history$nodes[[i]]$deletions
      # We also want to get 1. Repo Name 2. Date
    )
    
    currentAuthor <- data.table(
      email = commitHistory[[2]]$history$nodes[[i]]$author$email,
      id = commitHistory[[2]]$history$nodes[[i]]$author$user$id
      # Also want 1. Organization 2. Login 3. Company
    )
    
    # Binds the current repo's commit history to the list of existing commit history
    if (exists("allCommits")) {
      allCommits <- rbindlist(list(currentRepo, allCommits))
      allAuthors <- rbindlist(list(currentAuthor,allAuthors))
    } else {
      allCommits <- currentRepo
      allAuthors <- currentAuthor
    }
  }
  allAuthors <- unique(allAuthors)
  
  return(list(allQueries,allRepos,allCommits, allAuthors))
}
