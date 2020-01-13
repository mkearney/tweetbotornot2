#' Explain Twitter bot predictions
#'
#' Explain estimated probability that one or more Twitter accounts is a "bot"
#'
#' @inheritParams predict_bot
#' @return A data frame with the user id, screen name, probability estimate,
#'   feature name, and feature contribution
#' @examples
#'
#' \dontrun{
#'
#' ## estimate prediction and return with feature contribution
#' kmw <- explain_bot("kearneymw")
#'
#' ## view data
#' kmw
#'
#' ## prob_bot should be roughly equal to sum of log-odds of 'value'
#' kmw[,
#'   .(prob_bot = stats::qlogis(prob_bot[1]),
#'   contr = sum(value)),
#'   by = screen_name
#'  ]
#' }
#' @export
explain_bot <- function(x, batch_size = 100, ...) {
  UseMethod("explain_bot")
}

#' @export
explain_bot.character <- function(x, batch_size = 100, ...) {
  x <- predict_bot(x, batch_size = batch_size, ...)
  explain_bot(x)
}

#' @export
explain_bot.factor <- function(x, batch_size = 100, ...) {
  x <- as.character(x)
  explain_bot(x, batch_size = batch_size, ...)
}

#' @export
explain_bot.data.frame <- function(x, batch_size = 100, ...) {
  x <- data.table::data.table(x)
  explain_bot(x, batch_size = batch_size, ...)
}


#' @export
explain_bot.data.table <- function(x, batch_size = 100, ...) {
  . <- NULL
  user_id <- NULL
  screen_name <- NULL
  bot <- NULL
  prob_bot <- NULL
  value <- NULL
  feature_description <- NULL
  feature <- NULL
  if (!"prob_bot" %in% names(x)) {
    x <- predict_bot(x, batch_size = batch_size, ...)
  }
  p <- x[, prob_bot]
  x <- get_model_data(x)
  x[, prob_bot := p]
  #x[, prob_bot := pb]
  #p <- stats::predict(
  #  tweetbotornot_xgb_model,
  #  as.matrix(x[, -c("user_id", "screen_name", "bot", "prob_bot")])
  #)
  #p <- x[, prob_bot]
  pc <- stats::predict(
    tweetbotornot_xgb_model,
    as.matrix(x[, -c("user_id", "screen_name", "bot", "prob_bot")]),
    predcontrib = TRUE
  )
  x <- cbind(
    x[, .(user_id, screen_name, bot)],
    data.table::as.data.table(pc),
    data.table::data.table(prob_bot = p)
  )
  xlong <- x[, -c("screen_name", "bot", "prob_bot")][,
    .(feature = names(.SD), value = unlist(.SD)),
    by = "user_id"]
  xwide <- x[, c("user_id", "screen_name", "bot", "prob_bot")]
  x <- merge(xlong, xwide, by = "user_id")
  x <- x[order(screen_name, -abs(value)), ]
  x[, bot := NULL]
  x$feature_description <- feature_info[match(x$feature, names(feature_info))]
  x[, .(user_id, screen_name, prob_bot, feature, value, feature_description)]
}



feature_info <- c(
  usr_prfbg = "Whether user profile has background img",
  usr_prfbn = "Whether user profile has banner image",
  usr_prfur = "Whether user profile has URL",
  usr_prfimgif = "Whether user has profile image.gif",
  usr_prfimjpeg = "Whether user has profile image.jpeg",
  usr_prfimjpg = "Whether user has profile image.jpg",
  usr_prfimpng = "Whether user has profile image.png",
  usr_prfimNA = "Whether user has profile image",
  usr_twtrt = "User tweet rate",
  usr_ffrat = "User follower-friend ratio",
  usr_faves = "User favourites",
  usr_frnds = "User friends",
  usr_fllws = "User followers",
  usr_verif = "User verified",
  usr_actyr = "User account age",
  usr_allrt = "Last 0-200 tweets are all retweets",
  twt_wrdmn = "Tweet word count mean",
  twt_wrdsd = "Tweet word count variation",
  twt_wdtmn = "Tweet display width mean",
  twt_wdtsd = "Tweet display widht variatiojn",
  twt_langs = "Tweet languages",
  twt_srces = "Tweet sources",
  twt_srcts = "Tweet source types",
  twt_src2b = "Tweet source of CB,DQ!|twittbot.net",
  twt_srcbe = "Tweet source of known bot-enablers",
  twt_srctw = "Tweet source of Twitter (official)",
  twt_srcbu = "Tweet source of many other bots",
  twt_srcpp = "Tweet source of popular platform",
  twt_srcas = "Tweet source of popular service",
  twt_srcpu = "Tweet source of many other users",
  twt_srcna = "Tweet source of unknown",
  twt_rtwts = "Tweet via retweets",
  twt_quots = "Tweet via quotes",
  twt_rplys = "Tweet via replies",
  twt_atsmn = "Tweet mentions",
  twt_atssd = "Tweet mentions variation",
  twt_hshmn = "Tweet hashtags",
  twt_hshsd = "Tweet hashtags variation",
  twt_medmn = "Tweet media",
  twt_medsd = "Tweet media variation",
  twt_mtpmn = "Tweet media type",
  twt_mtpsd = "Tweet media type variation",
  twt_emdmn = "Tweet extended media",
  twt_emdsd = "Tweet extended media variation",
  twt_urlmn = "Tweet URLs",
  twt_urlsd = "Tweet URLs variations",
  twt_int15 = "Tweet counts in 15-minute intervals",
  twt_int30 = "Tweet counts in 30-minute intervals",
  twt_bunch = "Tweet bunching",
  twt_max15 = "Tweet count max in 15-minute intervals",
  twt_min15 = "Tweet count min in 15-minute intervals",
  twt_max30 = "Tweet count max in 30-minute intervals",
  twt_min30 = "Tweet count min in 30-minute intervals",
  twt_place = "Tweet location",
  tweets    = "Analyzed tweets (max 200)",
  BIAS      = "Intercept (y when x=0)"
)
