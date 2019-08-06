

get_github_contributors <- function(repo = "pandas-dev/pandas") {
  # get first page
  c1 <- httr::GET(paste0("https://api.github.com/repos/", repo,"/contributors"))
  # get next and last page numbers
  if (!is.null(c1$headers$link)) {
    links <- c1$headers$link
    next_page <- stringr::str_match_all(links, "page=([0-9]?[0-9]?)")[[1]][1, 2]
    last_page <- stringr::str_match_all(links, "page=([0-9]?[0-9]?)")[[1]][2, 2]
  } else {
    last_page <- 1
  }
  # get first page content
  c1_cont <- httr::content(c1)
  c1_cont_dt <- purrr::map(c1_cont, data.table::as.data.table)
  c1_cont_dt <- data.table::rbindlist(c1_cont_dt)
  # pre-allocate list
  out_list <- vector("list", last_page)
  # set first list entry
  out_list[1] <- list(c1_cont_dt)
  # get additional page content
  if (!is.null(c1$headers$link)) {
    for (i in next_page:last_page) {
      # get page
      c2 <- httr::GET(paste0("https://api.github.com/repos/", repo,"/contributors?page=", i))
      # get page content
      c2_cont <- httr::content(c2)
      c2_cont_dt <- purrr::map(c2_cont, data.table::as.data.table)
      c2_cont_dt <- data.table::rbindlist(c2_cont_dt)
      # add to out_list
      out_list[i] <- list(c2_cont_dt)
    }
  }
  # return out_list
  data.table::rbindlist(out_list)
}




####TESTING###
get_all_github_repo_names_ids <- function(limit = 5) {
  out_dt <- data.table::data.table(repo_id = 0, full_name = "")
  
  l <- 0
  while (l < limit) {
    repo_id <- max(out_dt$repo_id)
    url <- paste0("https://api.github.com/repositories?since=", repo_id)
    repos <- httr::GET(url)
    Sys.sleep(1)
    repos_content <- httr::content(repos)
    for (i in 1:length(repos_content)) {
      id_name_dt <- data.table::data.table(repo_id = repos_content[[i]]$id, full_name = repos_content[[i]]$full_name)
      out_list[i] <- list(id_name_dt)
    }
    out_list_dt <- data.table::rbindlist(out_list)
    out_dt <- data.table::rbindlist(list(out_dt, out_list_dt))
    l <- l + 1
  }
  out_dt
}


repo_id <- 0
url <- paste0("https://api.github.com/repositories?since=", repo_id)
repos <- httr::GET(url)
repos_content <- httr::content(repos)
out_list <- vector("list", length(repos_content))
for (i in 1:length(repos_content)) {
  id_name_dt <- data.table::data.table(repo_id = repos_content[[i]]$id, full_name = repos_content[[i]]$full_name)
  out_list[i] <- list(id_name_dt)
}
out_dt <- data.table::rbindlist(out_list)


