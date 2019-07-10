# Function: MakePretty
# Calvin Isch
# 2019-07-10
#
# Function Description:
# Given queried info from github, and the date that the query was for, returns a list of four tables
# 1. QueryTable -- a table with query specific info
# 2. RepoTable -- a table with information about each repository returned by the query
# 3. CommitTable -- a table with information about all of the commits to all repositories
# 4. AuthorTable -- a table with info about the authors who created the commits
# 
# These tables are related as follows: 
# QueryTable has a 1 to many relationship with RepoTable via variable date,
# RepoTable has a 1 to many relationship with CommitTable via repoName,
# CommitTable has a 1 to 1 relationship with AuthorTable via authorID

makePretty <- function(res,queryDate) {
  
  # Creates a table with information about the query
  allQueries <- data.table(
    date = queryDate,
    numRepos = res$data$search$repositoryCount
  )
  
  # Creates a data table with the repository-specific information
  allRepos <- data.table(
    repoName = result$data$search$nodes$name,
    owner = res$data$search$nodes$owner$login,
    defBranch = res$data$search$nodes$defaultBranchRef$name,
    numCommits = res$data$search$nodes$defaultBranchRef$target$history$totalCount,
    date = queryDate
  )
  
  
  # For every repository, gets all of the commits and binds them together into one data table
  # Also gets the authors of those commits and writes them into a table.
  for (i in 1:length(res$data$search$nodes$defaultBranchRef$target$history$nodes)) {
    
    # Creates a data.table of the current repository's commit history
    currentRepo <- data.table(
      authorId = res$data$search$nodes$defaultBranchRef$target$history$nodes[[i]]$author$user$id,
      additions = res$data$search$nodes$defaultBranchRef$target$history$nodes[[i]]$additions,
      deletions = res$data$search$nodes$defaultBranchRef$target$history$nodes[[i]]$deletions,
      repoName = res$data$search$nodes$name[i]
      # We also want to get  2. Date
    )
    
    ### YOU ARE HERE!!! ###
    currentAuthor <- data.table(
      email = res$data$search$nodes$defaultBranchRef$target$history$nodes[[i]]$author$email,
      authorId = res$data$search$nodes$defaultBranchRef$target$history$nodes[[i]]$author$user$id
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
