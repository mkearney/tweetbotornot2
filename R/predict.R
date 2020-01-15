#' Predict Twitter bots
#'
#' Estimate probability that one or more Twitter accounts is a "bot"
#'
#' @param x Input data either character vector of Twitter identifiers (user IDs
#'   or screen names) or a data frame of Twitter data
#' @param batch_size Number of users to process per batch. Relevant if x contains user
#'   names or timeline data for more than 100 Twitter users. Because the data
#'   processing involves user-level aggregation (grouping by user), it can create
#'   computational bottlenecks that are easily avoided by breaking the data into
#'   batches of users. Manipulating this number may speed up or slow down data
#'   processing, but for most jobs the speed difference is likely negligible,
#'   meaning this argument may only be useful if you are working on either a very
#'   slow/low-memory machine or very fast/high-memory machine. Default is 100.
#' @param ... Other arguments are passed on to rtweet functions. This is mostly
#'   just to allow users to specify the Twitter API token, e.g.,
#'   \code{predict_bot("kearneymw", token = token)} or
#'   \code{predict_bot("kearneymw", token = rtweet::bearer_token())}.
#' @return predict_bot: A data frame (data.table) with the user id, screen name,
#'   and estimated probability of being a bot
#' @examples
#'
#' \dontrun{
#' ## vector of screen names
#' x <- c("netflix_bot", "aasfdiouyasdoifu", "madeupusernamethatiswrong",
#'   "a_quilt_bot", "jack", "SHAQ", "aasfdiouyasdoifu5", NA_character_,
#'   "madeupusernamethatiswrong", "a_quilt_bot")
#'
#' ## predict_bot - returns data.table (with user_id, screen_name, prob_bot)
#' (p1 <- predict_bot(x))
#'
#' ## predict_bot_score - returns scores (prob_bot as a numeric vector)
#' (p2 <- predict_bot_score(x))
#'
#' }
#' @export
predict_bot <- function(x, batch_size = 100, ...) {
  UseMethod("predict_bot")
}

#' @export
predict_bot.character <- function(x, batch_size = 100, ...) {
  x <- preprocess_bot(x, batch_size = batch_size, ...)
  predict_bot(x, batch_size = batch_size, ...)
}

#' @export
predict_bot.factor <- function(x, batch_size = 100, ...) {
  x <- as.character(x)
  predict_bot(x, batch_size = batch_size, ...)
}

#' @export
predict_bot.data.frame <- function(x, batch_size = 100, ...) {
  if (".ogusrs" %in% names(attributes(x))) {
    ogusrs <- attr(x, ".ogusrs")
    x <- data.table::data.table(x)
    attr(x, ".ogusrs") <- ogusrs
  } else {
    x <- data.table::data.table(x)
  }
  predict_bot(x, batch_size = batch_size, ...)
}

#' @export
predict_bot.data.table <- function(x, batch_size = 100, ...) {
  if (!all(tweetbotornot_xgb_model$feature_names %in% names(x))) {
    x <- preprocess_bot(x, batch_size = batch_size, ...)
  }
  og <- attr(x, ".ogusrs")
  if (sum(og %in% x$user_id, na.rm = TRUE) >
      sum(tolower(og) %in% tolower(x$screen_name), na.rm = TRUE)) {
    ogusrs <- data.table::data.table(
      user_id = og,
      screen_name = x$screen_name[match(og, x$user_id)],
      prob_bot = NA_real_
    )
  } else {
    ogusrs <- data.table::data.table(
      user_id = x$user_id[match(tolower(og), tolower(x$screen_name))],
      screen_name = og,
      prob_bot = NA_real_
    )
  }

  ##--------------------------------------------------------------------------##
  ##                           (FOR CRAN CHECKS)                              ##
  . <- NULL
  user_id <- NULL
  screen_name <- NULL
  prob_bot <- NULL
  ##--------------------------------------------------------------------------##

  dots <- list(...)
  if ("xgb_model" %in% names(dots)) {
    predmodel <- dots[["xgb_model"]]
  } else {
    predmodel <- tweetbotornot_xgb_model
  }

  p <- stats::predict(predmodel,
    newdata = wactor::xgb_mat(x[, -(1:3)]))
  ogusrs$prob_bot <- p[match(ogusrs$user_id, x$user_id)]
  x <- x[match(ogusrs$user_id, x$user_id), ][!is.na(user_id), ]
  attr(ogusrs, "model_data") <- x
  ogusrs
}

#' Predict bot score
#'
#' Returns numeric vector of bot probabilities matched to the input vector (or
#' data frame with user_id or screen_name) of users. This differs from
#' \code{predict_bot()} because it only returns the bot probabilities and not
#' user ID/screen name information.
#'
#' @rdname predict_bot
#' @export
#' @return predict_bot_score: returns a numeric vector of bot probabilities
predict_bot_score <- function(x, batch_size = 100, ...) {
  UseMethod("predict_bot_score")
}

#' @export
predict_bot_score.default <- function(x, batch_size = 100, ...) {
  if (any(c("user_id", "screen_name", "id_str") %in% names(x)) &&
      all(!c("text", "friends_count") %in% names(x))) {
    x <- pluck_users(x)
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }
  stopifnot(
    is.character(x)
  )
  og <- x
  x <- predict_bot(x, batch_size = batch_size, ...)
  if (sum(og %in% x$user_id, na.rm = TRUE) >
      sum(tolower(og) %in% tolower(x$screen_name), na.rm = TRUE)) {
    x$prob_bot[match(og, x$user_id)]
  } else {
    x$prob_bot[match(tolower(og), tolower(x$screen_name))]
  }
}

