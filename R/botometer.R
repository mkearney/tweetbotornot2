

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
#' @param parse Logical indicating whether to parse return information. If TRUE
#'   (the default) then a data.table is returned.
#' @param verbose Logical indicating whether to print updates between each call.
#'   Default is TRUE.
#' @return A data frame (data.table) of user ID, screen name, and botometer score
#' @examples
#'
#' \dontrun{
#' ## get botometer scores
#' b <- predict_botometer(c("kearneymw", "netflix_bot"))
#'
#' ## get full information returned by botometer (as response objects)
#' r <- predict_botometer(c("kearneymw", "netflix_bot"), parse = FALSE)
#' }
#' @export
predict_botometer <- function(users,
                              token = NULL,
                              key = NULL,
                              set_key = FALSE,
                              parse = TRUE,
                              verbose = TRUE) {
  ## check rtweet token
  if (is.null(token)) {
    token <- rtweet::get_token()
  }

  ## fetch and/or set botometer api key
  key <- botometer_key(key, set_key = set_key)

  ## clean/format users input
  users <- cleanup_users_string(users)

  ## preserve order
  users_og <- users

  ## only lookup non-missing users one time each
  users <- unique(users[!is.na(users)])

  ## determine user type–(if clearly a mix set to NULL to guess for each one)
  if (all(grepl("^\\d+$", users))) {
    user_type <- "user_id"
  } else if (length(users) > 2L && sum(grepl("^\\d+$", users)) > 1L) {
    user_type <- NULL
  } else {
    user_type <- "screen_name"
  }

  ## initialize output vector
  output <- vector("list", length(users))

  for (i in seq_along(output)) {
    if (NROW(output[[i]]) == 0) {
      output[[i]] <- botometer_score(
        user      = users[i],
        token     = token,
        key       = key,
        parse     = parse,
        user_type = user_type
      )
    }
    ## print status
    if (verbose) {
      cat("@", users[i], " (", i, "/", length(output), ")\n", sep = "")
    }
  }

  ## if parse then combine into single data frame/table
  if (parse) {
    output <- do.call("rbind", output)
    ## match with input order
    output <- output[match(users_og, users), ]
  }

  ## return output
  output
}

botometer_score <- function(user, token, key, parse = TRUE, user_type = NULL) {
  ## base URL for API calls
  base_url <- "https://api.twitter.com/1.1/"

  ## determine whether screen name or user ID
  if (is.null(user_type)) {
    ## determine
    if (grepl("^\\d+$", user)) {
      user_type <- "user_id"
    } else {
      user_type <- "screen_name"
    }
  }

  ## (1) users/show endpoint
  userdata <- httr::GET(
    paste0(base_url, "users/show.json?", user_type, "=", user),
    token
  )
  ## store returned user ID/screen name information
  .u <- httr::content(userdata)[c("id_str", "screen_name")]
  user_id <- .u[[1]]
  screen_name <- .u[[2]]
  ## if user info isn't valid, then return (skip the other API calls)
  if (length(screen_name) == 0) {
    ## preserve 'user' (input) information
    if (grepl("^\\d+$", user)) {
      user_id <- user
      screen_name <- NA_character_
    } else {
      user_id <- NA_character_
      screen_name <- user
    }
    if (parse) {
      return(data.table::data.table(
        user_id = user_id,
        screen_name = screen_name,
        botometer = NA_real_
      ))
    }
    return(list())
  }
  ## update 'user' with returned screen name and set 'user_type'
  user <- screen_name
  user_type <- "screen_name"

  ## (2) statuses/user_timeline endpoint
  timeline <- httr::GET(
    paste0(base_url, "statuses/user_timeline.json?", user_type, "=", user, "&count=200"),
    token
  )

  ## (3) search/tweets endpoint
  mentions <- httr::GET(
    paste0(base_url, "search/tweets.json?q=", user, "&count=200"),
    token
  )

  ## (4) check_account endpoint
  body <- RJSONIO::toJSON(list(
    timeline = httr::content(timeline, type = "application/json"),
    mentions = httr::content(mentions, type = "application/json"),
    user     = httr::content(userdata, type = "application/json")
  ), auto_unbox = TRUE, pretty = TRUE)
  ## send request to botometer API
  r <- httr::POST(
    "https://osome-botometer.p.mashape.com/2/check_account",
    encode = "json",
    httr::add_headers(`X-Mashape-Key` = key),
    body = body
  )

  ## if parse is false, return as is
  if (!parse) {
    return(r)
  }
  ## otherwise extract score and return as data table
  english <- httr::content(r)[["scores"]][["english"]]
  universal <- httr::content(r)[["scores"]][["universal"]]
  if (length(english) == 0L) {
    english <- NA_real_
  }
  if (length(universal) == 0L) {
    universal <- NA_real_
  }
  data.table::data.table(
    user_id = user_id,
    screen_name = screen_name,
    botometer_english = english,
    botometer_universal = universal
  )
}

# get_timelines_for_botometer <- function(x, token = NULL) {
#   x <- rtweet::get_timelines(x, n = 200, check = FALSE,
#     token = token, parse = FALSE)
#   for (i in seq_along(x)) {
#     x[[i]] <- x[[i]][[1]]
#     names(x[[i]])[names(x[[i]]) == "full_text"] <- "text"
#   }
#   sp <- getOption("scipen")
#   dg <- getOption("digits")
#   on.exit(options(scipen = sp, digits = dg), add = TRUE)
#   options(scipen = 20, digits = 20)
#   dapr::lap(x, ~ jsonlite::fromJSON(jsonlite::toJSON(.x), simplifyVector = TRUE, simplifyDataFrame = FALSE, simplifyMatrix = FALSE))
# }
#
# lookup_users_for_botometer <- function(x, token = NULL) {
#   x <- rtweet::lookup_users(x, token = token, parse = FALSE)
#   if (NROW(x) == 0) {
#     return(NULL)
#   }
#   nms <- x[['screen_name']]
#   sp <- getOption("scipen")
#   dg <- getOption("digits")
#   on.exit(options(scipen = sp, digits = dg), add = TRUE)
#   options(scipen = 20, digits = 20)
#   x <- jsonlite::fromJSON(jsonlite::toJSON(x), simplifyVector = TRUE, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
#   names(x) <- nms
#   x
# }
#
# search_tweets_for_botometer <- function(x, token = NULL) {
#   x <- dapr::lap(x, rtweet::search_tweets, token = token, parse = FALSE)
#   if (NROW(x) == 0) {
#     return(NULL)
#   }
#   dapr::lap(x, ~ {
#     .x <- .x[[1]]
#     names(.x[["statuses"]])[names(.x[["statuses"]]) == "full_text"] <- "text"
#     jsonlite::fromJSON(jsonlite::toJSON(.x), simplifyVector = TRUE, simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
#   })
# }

botometer_key <- function(x = NULL, set_key = FALSE) {
  ## look for key if not supplied directly
  x <- x %||% find_botometer_key()

  ## if no key is found, stop with hyperlinked message
  if (is.null(x)) {
    stop(paste0("This requires a valid 'Botometer' API key, see: ",
      "https://rapidapi.com/OSoMe/api/botometer/details for more information"),
      call. = FALSE)
  }

  ## validate string basics
  stopifnot(
    is.character(x),
    length(x) == 1L,
    nchar(x) > 0,
    grepl("[[:alnum:]]{5,}", x)
  )
  ## trim any outer white space or quotations
  x <- trim_string_outers(x)

  ## if TRUE set key as R environment variable
  if (set_key) {
    tfse::set_renv(BOTOMETER_KEY = x)
  }

  ## return key
  x
}

find_botometer_key <- function() {
  ## (1) look for 'BOTOMETER_KEY' R environment variable
  is_env <- function(x) x != ""
  if (is_env(key <- Sys.getenv("BOTOMETER_KEY"))) {
    return(key)
  }

  ## (2) look for similarly named (e.g., BOTOMETER or BOTOMETER_PAT)
  envs <- Sys.getenv()
  if (any(grepl("^botometer", names(envs), ignore.case = TRUE))) {
    key <- envs[[grep("^botometer", names(envs), ignore.case = TRUE)[1]]]
    return(key)
  }

  ## (3) look for botomer key stored at system level
  key <- c(
    system("echo $BOTOMETER_KEY", intern = TRUE),
    system("echo $BOTOMETER_PAT", intern = TRUE),
    system("echo $BOTOMETER", intern = TRUE)
  )
  if (any(key != "")) {
    key <- key[key != ""][1]
    return(key)
  }

  ## otherwise return NULL
  NULL
}
