# Housekeeping ----

library(RSelenium)
library(DBI)

# Set-up database ----

conn <- dbConnect(drv = RPostgreSQL::PostgreSQL(),
                  dbname = "oss",
                  host = "127.0.0.1",
                  port = "5433",
                  user = Sys.getenv("db_userid"),
                  password = Sys.getenv("db_pwd"))
dbWriteTable(conn = conn,
             name = c(schema = "universe", name = "test"),
             value = iris,
             row.names = FALSE,
             overwrite = TRUE)
mydata <- dbReadTable(conn = conn,
                      name = c(schema = "universe", name = "test"))
dbRemoveTable(conn = conn,
              name = c(schema = "universe", name = "test"))
dbDisconnect(conn = conn)

# Selenium since website uses Javascript ----

remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L,
  browserName = "firefox"
)
remDr$open()
remDr$getStatus()
remDr$navigate("https://cocatalog.loc.gov/")
remDr$getCurrentUrl()
ssl <- remDr$findElement(using = "xpath",
                         "/html/body/form/table[1]/tbody/tr[2]/td/div/div/table/tbody/tr/td[3]/div/a")
ssl$clickElement()
remDr$getCurrentUrl()
item_type <- remDr$findElement(using = "xpath",
                               "/html/body/form/table/tbody/tr/td/div/table/tbody/tr[7]/td[2]/div/select/option[10]")
item_type$clickElement()
date_input <- remDr$findElement(using = "xpath",
                                "/html/body/form/table/tbody/tr/td/div/table/tbody/tr[5]/td[2]/div/input[1]")
date_input$sendKeysToElement(list("2008"))
ssl_submit <- remDr$findElement(using = "xpath",
                                "/html/body/form/table/tbody/tr/td/div/table/tbody/tr[10]/td/div/font/input[4]")
ssl_submit$clickElement()
rpp <- remDr$findElement(using = "xpath",
                         "/html/body/form/table[1]/tbody/tr[2]/td/div/div/table/tbody/tr/td[1]/select/option[4]")
rpp$clickElement()
sf_blank <- remDr$findElement(using = "xpath",
                              "/html/body/form/table[1]/tbody/tr[1]/td/table[2]/tbody/tr[2]/td/table/tbody/tr[1]/td/font/b/input")
sf_blank$sendKeysToElement(list("R"))
bss <- remDr$findElement(using = "xpath",
                         "/html/body/form/table[1]/tbody/tr[2]/td/div/div/table/tbody/tr/td[2]/div/input[2]")
bss$clickElement()
remDr$getCurrentUrl()

allpage <- remDr$findElement(using = "xpath",
                             "/html/body/form/center/center[1]/table/tbody/tr[3]/td[1]/input[1]")
allpage$clickElement()
export <- remDr$findElement(using = "xpath",
                            "/html/body/form/center/center[1]/table/tbody/tr[2]/td[2]/input")
export$clickElement()
result <- remDr$getPageSource()[[1]]
remDr$goBack()

currentpage <- remDr$getCurrentUrl()[[1]]

nextpage <- remDr$findElement(using = "css",
                              "img[alt='Next']")
nextpage$clickElement()

currentpage == remDr$getCurrentUrl()

allpage <- remDr$findElement(using = "xpath",
                             "/html/body/form/center/center[1]/table/tbody/tr[3]/td[1]/input[1]")
allpage$clickElement()
export <- remDr$findElement(using = "xpath",
                            "/html/body/form/center/center[1]/table/tbody/tr[2]/td[2]/input")
export$clickElement()
result2 <- remDr$getPageSource()[[1]]

remDr$goBack()
nextpage <- remDr$findElement(using = "css",
                              "img[alt='Next']")
nextpage$clickElement()

allpage <- remDr$findElement(using = "xpath",
                             "/html/body/form/center/center[1]/table/tbody/tr[3]/td[1]/input[1]")
allpage$clickElement()
export <- remDr$findElement(using = "xpath",
                            "/html/body/form/center/center[1]/table/tbody/tr[2]/td[2]/input")
export$clickElement()
result3 <- remDr$getPageSource()[[1]]
remDr$goBack()

nextpage <- remDr$findElement(using = "css",
                              "img[alt='Next']")
currentpage <- remDr$getCurrentUrl()[[1L]]
nextpage$clickElement()
remDr$getCurrentUrl()[[1L]] == currentpage

remDr$close()
