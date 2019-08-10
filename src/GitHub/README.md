## Scripts in this folder
**01_GraphQL + Webscraping** 

This method uses webscraping to get contributions and user information of each repository to circumvent the issues of page limitation and data restriction of GraphQl. 
Theretically this method has three steps:
1) query repo names, owner login names and licenses in GraphQl,
2) webscrape detailed repo contributions, and
3) use the slugs of each contribution to query user information in GraphQL. The two scripts in this folder are the first two steps:
- 01_query_slugs.R
This script queries repo names, owner login names and licenses and saves the results in database oss->universe->reponames_2008. This script was a test version before the team upgrade it to a more robust one that automates the queries by year and fixed the API timeout issue. The new version of this script is in folder 02_GraphQL+GHTorrent.
- 02_webscraping
This script takes the repo names and owner login names obtained from the last step and webscrapes repo additions, deletions, commits, creation date, and last updated date. 
The results are saved in database oss->universe->contribution and oss->universe->slugcreatedon. As the team did not continue with this method, these two tables were abandoned and only contain incompleted results.

**02_GraphQL + GHTorrent**
- 01_query_GitHub_licenses
This is the upgraded version of GraphQL queries. We have used this script to collect repo names, owner login names and OSS licenses from 2012 to 2018. 
The tables in the database that store our final results are:  
reponames_2012  
reponames_2013  
reponames_2014  
reponames_2015  
reponames_2016  
reponames_2017  
reponames_2018  

- 02_combine_licenses_with_GHTorrent
This script merges our data in the last step with GHTorrent data by slugs (owner/reponame) to obtain all repositories with OSS licenses as well as their contributors' information including location, company, total commits and login names. The resulting tables in the database are:  
all_repos_commits_2012  
all_repos_commits_2013  
all_repos_commits_2014  
all_repos_commits_2015  
all_repos_commits_2016  
all_repos_commits_2017  
all_repos_commits_2018  

**03_RESTAPI.R**   
Aaron created this script trying to get all repo information including contributors. We did not proceed with this method. 
