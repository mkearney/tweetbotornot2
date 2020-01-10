#' Predict Twitter bots
#'
#' Estimate probability that one or more Twitter accounts is a "bot"
#'
#' @param x Input data either character vector of Twitter identifiers (user IDs
#'   or screen names) or a data frame of Twitter data
#' @return A data frame with the user id, screen name, and estimated probability
#'   of being a bot
#' @export
predict_bot <- function(x) {
  UseMethod("predict_bot")
}

#' @export
predict_bot.character <- function(x) {
  x <- rtweet::get_timelines(x, n = 200, check = FALSE)
  predict_bot(x)
}

#' @export
predict_bot.data.frame <- function(x) {
  x <- data.table::data.table(x)
  predict_bot(x)
}

#' @export
predict_bot.data.table <- function(x) {
  ##--------------------------------------------------------------------------##
  ##                           (FOR CRAN CHECKS)                              ##
  ##--------------------------------------------------------------------------##
  . <- NULL
  user_id <- NULL
  screen_name <- NULL
  prob_bot <- NULL

  if (!all(tweetbotornot_xgb_model$feature_names %in% names(x))) {
    x <- preprocess_bot(x)
  }
  o <- x[, .(user_id, screen_name, prob_bot)]
  o$prob_bot <- stats::predict(tweetbotornot_xgb_model,
    newdata = wactor::xgb_mat(x[, -(1:3)]))
  attr(o, "model_data") <- x
  o
}


get_model_data <- function(x) attr(x, "model_data")
