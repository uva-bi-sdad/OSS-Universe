# OSS-Universe
This project uses intellectual property information (copyright and patents) to identify the universe of software development.

## Copyright

### What are copyrights and what do these protect?

Copyright is a form of protection provided by U.S. law to authors of "original works of authorship" from the time the works are created in a fixed form.

- [Copyright Basics (Circ. 1)](https://www.copyright.gov/circs/circ01.pdf)

### Relevant dataset:

U.S. Copyright Office. n.d. “Copyright Public Records Catalog Online. 1978 to Present.” US Library of Congress. Public Catalog. https://cocatalog.loc.gov/.

- Relevant Records
  - Type: Computer Files
  - Date: Last 20 years

- Access
  - Public Domain
  - Access through government portal
  - Available for harvest
  - No bulk download function
  - Relevant [documents](https://public.resource.org/copyright.gov/index.html)

- Data harvest will be performed using a script in the server during least disruptive hours and the data will be saved to the database.

## Why GitHub
To understand the OSS universe, traditional methods is not enough because open source developers are not filing copyright for their code. GitHub the best potential source as all OSS codes are attached with OSI-approved licenses.  
We aim to collect the following information from GitHub repositories:  
- Names of repositories that have OSI-approved licenses  
- owners of repositories  
- contributors of repositories, including their locations and organizations  
- contribution to each repository, including additions, deletions and commits  

### Methods of collecting GitHub information  
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
