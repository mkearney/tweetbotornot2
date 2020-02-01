prep_xgb_model <- function() {
  tweetbotornot_xgb_model <- xgboost::xgb.load(tweetbotornot_xgb_model_raw)
  tweetbotornot_xgb_model$best_ntreelimit <- tweetbotornot_xgb_model_best_ntreelimit
  xgboost::xgb.Booster.complete(tweetbotornot_xgb_model)
}

get_secret <- function(x) {
  if ((key <- Sys.getenv(x)) != "") {
    return(key)
  }
  if (grepl("(TOKEN|KEY)$", x)) {
    x <- paste0(sub("_(KEY|PAT|TOKEN|SECRET)$", "", x), c("", "_KEY", "_PAT", "_TOKEN"))
  } else {
    x <- paste0(sub("_(KEY|PAT|TOKEN|SECRET)$", "", x), c("", "_KEY", "_PAT", "_SECRET"))
  }
  x <- Sys.getenv(x)
  if (any(x != "")) {
    return(x[x != ""][1])
  }
  ""
}

create_token_from_secrets <- function() {
  if (file.exists("rtweet_token.rds") &&
      !isFALSE(x <- tryCatch(readRDS("rtweet_token.rds"), error = function(e) FALSE))) {
    return(x)
  }
  if (file.exists("rtweet_token.rds") &&
      !isFALSE(x <- tryCatch(readRDS("rtweet_token.rds"), error = function(e) FALSE))) {
    return(x)
  }
  rtweet_token()
}

in_years <- function(a, b) {
  as.numeric(difftime(a, b, units = "days")) / 365
}

ffactor <- function(x, ...) {
  factor(x, levels = unique(x), ...)
}

count_words <- function(x) lengths(gregexpr("\\S+", x))

max_freq <- function(x) {
  levs <- x[!duplicated(x)]
  max(tabulate(factor(x, levels = levs)))
}
min_freq <- function(x) {
  levs <- x[!duplicated(x)]
  min(tabulate(factor(x, levels = levs)))
}

factor_ <- function(x, levels) {
  x[!x %in% levels] <- "NA"
  factor(x, levels)
}

as_source_type <- function(x) {
  x <- source_types$type[match(x, source_types$source)]
  x[is.na(x)] <- "NA"
  x
}

max_round_time_2sec <- function(x) {
  x <- as.character(rtweet::round_time(x, "2 secs"))
  uq <- unique(x)
  max(tabulate(as.integer(factor(x,
    levels = uq, ordered = FALSE, exclude = FALSE)),
    nbins = length(uq)))
}


round_daytime15 <- function(x) {
  as.integer(format(x, "%H")) + as.integer(format(x, "%M")) %/% 15 * 0.25
}
round_daytime30 <- function(x) {
  as.integer(format(x, "%H")) + as.integer(format(x, "%M")) %/% 30 * 0.50
}

var_ <- function(x) {
  if (is.na(x <- stats::var(x, na.rm = TRUE, use = "na.or.complete"))) {
    0
  } else {
    x
  }
}

sd_ <- function(x) sqrt(var_(x))

mean_ <- function(x) mean(x, na.rm = TRUE)

count_list_col <- function(x) {
  if (!is.recursive(x)) {
    return(x)
  }
  o <- lengths(x)
  o[o == 1][dapr::vap_lgl(x[o == 1], is.na)] <- 0L
  o
}

sampleit <- function(x, n) {
  if (!is.list(x)) {
    sort(sample(x, n))
  } else {
    sort(unlist(lapply(x, sample, round(n / length(x)), 0), use.names = FALSE))
  }
}

#' Split test train
#'
#' Splits data frame into train and test sets
#'
#' @param .data Input data set
#' @param .p Proportion of cases to appear in training data
#' @param ... Optional, specify response variable via non-standard evaluation
#' @return a list with "train" and "test" data frames
#' @keywords internal
#' @export
split_test_train <- function(.data, .p = 0.80, ...) {
  y <- substitute(...)
  n <- round(nrow(.data) * .p, 0)
  r <- seq_len(nrow(.data))
  if (!is.null(y)) {
    y <- eval(y, envir = .data)
    ty <- table(y)
    ny <- length(ty)
    lo <- min(as.integer(ty))
    if ((n / ny) > lo) {
      n <- lo * ny
    }
    r <- split(r, y)
  }
  r <- sampleit(r, n)
  list(
    train = .data[r, ],
    test = .data[-r, ]
  )
}

#' Log counts
#'
#' Safely (deals with zero and negative values) logs integers
#'
#' @param x Input data
#' @return Output should match input class
#' @keywords internal
#' @export
log_counts <- function(x) UseMethod("log_counts")

#' @export
log_counts.default <- function(x) {
  x
}

#' @export
log_counts.integer <- function(x) {
  if ((m <- min(x, na.rm = TRUE)) < 0L) {
    x <- x + 0L - m
  }
  log1p(x)
}

#' @export
log_counts.list <- function(x) {
  cols <- names(x)[dapr::vap_lgl(x, is.integer)]
  for (i in cols) {
    x[[i]] <- log_counts(x[[i]])
  }
  x
}

#' @export
log_counts.data.table <- function(x) {
  cols <- names(x)[dapr::vap_lgl(x, is.integer)]
  for (i in cols) {
    x[[i]] <- log_counts(x[[i]])
  }
  x
}

#' @export
log_counts.data.frame <- function(x) {
  cols <- names(x)[dapr::vap_lgl(x, is.integer)]
  x[, cols] <- dapr::lap(x[, cols, drop = FALSE], log_counts)
  x
}

is_user <- function(x) {
  is.character(x) && all(grepl("^[[:alnum:]_]+$", x))
}

is_ids <- function(x) {
  is.character(x) && all(grepl("^\\d+$", x))
}


pluck_users <- function(x) {
  if (!any(
    c("user_id", "screen_name") %in% names(x)
  ) &&
      "id_str" %in% names(x)) {
    return(x[["id_str"]])
  }
  var <- sort(grep("^(user_id|screen_name)$", names(x), value = TRUE), decreasing = TRUE)[1]
  x[[var]]
}

get_model_data <- function(x) attr(x, "model_data")

trim_string_outers <- function(x) {
  gsub("(^[ \t\r\n]{0,}(\"|')?)|((\"|')[ \t\r\n]{0,}$)", "", x)
}

cleanup_users_string <- function(x) {
  ## remove outer white space/quotes
  x <- trim_string_outers(x)

  ## remove URL information
  urls <- grepl("^https?://|twitter\\.com/", x)
  x[urls] <- tfse::regmatches_first(x[urls], "(?<=twitter\\.com/)[^/]+")

  ## remove [at] sign0
  x <- sub("@", "", x, fixed = TRUE)

  ## return user(s)
  x
}


rtweet_token <- function(access_token = NULL, access_secret = NULL) {
  if (is.null(access_token)) {
    access_token <- unname(get_secret("TWITTER_ACCESS_TOKEN"))
  }
  if (is.null(access_secret)) {
    access_secret <- unname(get_secret("TWITTER_ACCESS_SECRET"))
  }
  eval(parse(text = paste0('token <- list()
  token$app <- list(appname = "rstats2twitter",
    secret = tweetbotornot2:::consumer_secret,
    key = tweetbotornot2:::consumer_key,
    redirect_uri = httr::oauth_callback())
  token$credentials <- list(oauth_token = "', access_token, '", oauth_token_secret = "', access_secret, '")
  token$params <- list(as_header = TRUE)
  token$endpoint <- list(
    request = "https://api.twitter.com/oauth/request_token",
    authorize = "https://api.twitter.com/oauth/authenticate",
    access = "https://api.twitter.com/oauth/access_token"
  )
  token$sign <- function(method, url) {
    oauth <- httr::oauth_signature(url, method,
      list(appname = "rstats2twitter",
        secret = tweetbotornot2:::consumer_secret,
        key = tweetbotornot2:::consumer_key,
        redirect_uri = httr::oauth_callback()),
      "', access_token, '",
      "', access_secret, '")
    c(structure(list(url = url), class = "request"), httr::oauth_header(oauth))
  }
  token$clone <- function() structure(token, class = c("rtweet_token", "Token"))
  structure(token, class = c("rtweet_token", "Token"))
  ')))
}

#' @export
print.rtweet_token <- function(x, ...) {
  cat('[oauth_endpoint]\n')
  cat('  request:  ', x$endpoint$request, '\n')
  cat('  authorize:', x$endpoint$authorize, '\n')
  cat('  access:   ', x$endpoint$access, '\n')

  cat('[oauth_app]\n')
  cat('  appname:  ', x$app$appname, '\n')
  cat('  key:      ', x$app$key, '\n')
  cat('[credentials]\n')
  cat('  token:     <hidden>\n')
  cat('  secret:    <hidden>\n')
  cat("\n")
}

#' @export
str.rtweet_token <- function(object, ...) {
  x <- unclass(object)
  x$app$secret <- "<hidden>"
  x$credentials$oauth_token <- "<hidden>"
  x$credentials$oauth_token_secret <- "<hidden>"
  utils::str(x)
}

`$<-.rtweet_token` <- function(x, name, value = NULL) {
  x <- unclass(x)
  x[[name]] <- value
  structure(x, c("rtweet_token", "token"))
}

`[.rtweet_token` <- function(x, name) {
  get(name, envir = x)
}
