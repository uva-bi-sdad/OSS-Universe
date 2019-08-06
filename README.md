# OSS-Universe
This project uses intellectual property information (copyright and patents) to identify the universe of software development.

## Why GitHub
To understand the OSS universe, traditional methods is not enough because open source developers are not filing copyright for their code. GitHub the best potential source as all OSS codes are attached with OSI-approved licenses.  
We aim to collect the following information from GitHub repositories:  
- Names of repositories that have OSI-approved licenses  
- owners of repositories  
- contributors of repositories, including their locations and organizations  
- contribution to each repository, including additions, deletions and commits  

# Methods of collecting GitHub information  
- Rest API   
Easy to access but provides no way to directly query for particular licenses.  
- GraphQL   
Offers direct query, but has page limitation and API calls timeout issues.  
- Web Scraping   
Can be combined with GraphQL to obtain information that is difficult to query.   
- BigQuery   
A public dataset provided through Google which is infrequently updated and thus not a reliable data source for our purpose.   
- GHTorrent   
An open source project updated multiple times a day that reflects the data on Github, but did not offer information on repository licenses or additions and deletions.  
