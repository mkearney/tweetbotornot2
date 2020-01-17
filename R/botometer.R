botometer_key <- function(x = NULL, set_key = FALSE) {
  if (length(x) > 0) {
    if (set_key &&
        !any(grepl("botometer", names(Sys.getenv()), ignore.case = TRUE))) {
      tfse::set_renv(BOTOMETER_KEY = x)
    }
    return(x)
  }
  ev <- grep("botometer", names(Sys.getenv()), ignore.case = TRUE, value = TRUE)
  if (length(ev) > 0L) {
    return(Sys.getenv(ev[1]))
  }
  stop(paste0("Must supply a 'Botometer' API key, see: ",
    "https://rapidapi.com/OSoMe/api/botometer/details"),
    call. = FALSE)
}

botometer_score <- function(user, token = NULL, key = NULL, set_key = FALSE) {
  api <- "https://api.twitter.com/1.1/"
  if (is.null(token)) {
    token <- rtweet::get_token()
  }
  key <- botometer_key(key, set_key = set_key)
  if (grepl("^\\d+$", user)) {
    idtype <- "user_id"
  } else {
    idtype <- "screen_name"
  }
  ## (1) users/show
  userdata <- httr::GET(glue::glue("{api}users/show.json?{idtype}={user}"), token)
  user_id <- httr::content(userdata)[["id_str"]][1]
  screen_name <- httr::content(userdata)[["screen_name"]][1]
  if (length(screen_name) == 1 && nchar(screen_name) > 1) {
    user <- screen_name
    idtype <- "screen_name"
  }
  if (length(user_id) == 0 && grepl("^\\d+$", user)) {
    user_id <- user
  }
  if (length(screen_name) == 0 && !grepl("^\\d+$", user)) {
    screen_name <- user
  }
  if (length(user_id) == 0) {
    user_id <- NA_character_
  }
  if (length(screen_name) == 0) {
    screen_name <- NA_character_
  }
  ## (2) statuses/user_timeline
  timeline <- httr::GET(
    glue::glue("{api}statuses/user_timeline.json?{idtype}={user}&count=200"),
    token)
  ## (3) search/tweets
  mentions <- httr::GET(glue::glue("{api}search/tweets.json?q={user}&count=200"),
    token)
  body = list(
    timeline = httr::content(timeline, type="application/json"),
    mentions = httr::content(mentions, type="application/json"),
    user     = httr::content(userdata, type="application/json")
  )
  body_json = RJSONIO::toJSON(body, auto_unbox = TRUE, pretty = TRUE)
  score <- tryCatch({
    httr::content(
      httr::POST("https://osome-botometer.p.mashape.com/2/check_account",
        encode = "json",
        httr::add_headers(`X-Mashape-Key` = key),
        body = body_json))[["scores"]][["english"]]
  }, error = function(e) NA_real_)
  if (length(score) == 0) {
    score <- NA_real_
  }
  # Parse result
  data.table::data.table(
    user_id = user_id,
    screen_name = screen_name,
    botometer = score
  )
}


#' Botometer scores
#'
#' Get Botometer scores for given user(s)
#'
#' @param users Vector of user IDs or screen names
#' @param token rtweet token. If NULL (default), then rtweet looks for a token
#'   path in .Renviron
#' @param key Botometer API key, which you should be able to get from:
#'   https://rapidapi.com/OSoMe/api/botometer/details
#' @param set_key Logical indicating whether to set the botometer key as an
#'   R environment variable for current future sessions (on the same machine).
#' @return A data frame (data.table) of user ID, screen name, and botometer score
#' @export
predict_botometer <- function(users, token = NULL, key = NULL, set_key = FALSE) {
  bo <- vector("list", length(users))
  for (j in seq_along(bo)) {
    if (NROW(bo[[j]]) == 0) {
      bo[[j]] <- botometer_score(users[j], token = token,
        key = key, set_key = set_key)
    }
    cat("@", users[j], " (", j, "/", length(bo), ")\n", sep = "")
  }
  do.call("rbind", bo)
}
