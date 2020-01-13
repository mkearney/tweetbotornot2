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
#' @return A data frame with the user id, screen name, and estimated probability
#'   of being a bot
#' @export
predict_bot <- function(x, batch_size = 100, ...) {
  UseMethod("predict_bot")
}

#' @export
predict_bot.character <- function(x, batch_size = 100, ...) {
  x <- rtweet::get_timelines(x, n = 200, check = FALSE, ...)
  predict_bot(x, batch_size = batch_size, ...)
}

#' @export
predict_bot.factor <- function(x, batch_size = 100, ...) {
  x <- as.character(x)
  predict_bot(x, batch_size = batch_size, ...)
}


#' @export
predict_bot.data.frame <- function(x, batch_size = 100, ...) {
  x <- data.table::data.table(x)
  predict_bot(x, batch_size = batch_size, ...)
}

#' @export
predict_bot.data.table <- function(x, batch_size = 100, ...) {
  if (!all(tweetbotornot_xgb_model$feature_names %in% names(x))) {
    x <- preprocess_bot(x, batch_size = batch_size, ...)
  }

  ##--------------------------------------------------------------------------##
  ##                           (FOR CRAN CHECKS)                              ##
  . <- NULL
  user_id <- NULL
  screen_name <- NULL
  prob_bot <- NULL
  ##--------------------------------------------------------------------------##

  o <- x[, .(user_id, screen_name, prob_bot)]
  o$prob_bot <- stats::predict(tweetbotornot_xgb_model,
    newdata = wactor::xgb_mat(x[, -(1:3)]))
  attr(o, "model_data") <- x
  o
}

