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
explain_bot.default <- function(x, batch_size = 100, ...) {
  if (length(x) == 0) {
    data.table::data.table()
  }
  stopifnot(
    is.character(x) || is.data.frame(x)
  )
  data.table::data.table()
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

  pc <- stats::predict(
    prep_xgb_model(),
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
  BIAS      = "Intercept (y when x=0)",
  dtime001  = "Shortest (nth) time between tweets",
  dtime002  = "Shortest (nth) time between tweets",
  dtime003  = "Shortest (nth) time between tweets",
  dtime004  = "Shortest (nth) time between tweets",
  dtime005  = "Shortest (nth) time between tweets",
  dtime006  = "Shortest (nth) time between tweets",
  dtime007  = "Shortest (nth) time between tweets",
  dtime008  = "Shortest (nth) time between tweets",
  dtime009  = "Shortest (nth) time between tweets",
  dtime010  = "Shortest (nth) time between tweets",
  dtime011  = "Shortest (nth) time between tweets",
  dtime012  = "Shortest (nth) time between tweets",
  dtime013  = "Shortest (nth) time between tweets",
  dtime014  = "Shortest (nth) time between tweets",
  dtime015  = "Shortest (nth) time between tweets",
  dtime016  = "Shortest (nth) time between tweets",
  dtime017  = "Shortest (nth) time between tweets",
  dtime018  = "Shortest (nth) time between tweets",
  dtime019  = "Shortest (nth) time between tweets",
  dtime020  = "Shortest (nth) time between tweets",
  dtime021  = "Shortest (nth) time between tweets",
  dtime022  = "Shortest (nth) time between tweets",
  dtime023  = "Shortest (nth) time between tweets",
  dtime024  = "Shortest (nth) time between tweets",
  dtime025  = "Shortest (nth) time between tweets",
  dtime026  = "Shortest (nth) time between tweets",
  dtime027  = "Shortest (nth) time between tweets",
  dtime028  = "Shortest (nth) time between tweets",
  dtime029  = "Shortest (nth) time between tweets",
  dtime030  = "Shortest (nth) time between tweets",
  dtime031  = "Shortest (nth) time between tweets",
  dtime032  = "Shortest (nth) time between tweets",
  dtime033  = "Shortest (nth) time between tweets",
  dtime034  = "Shortest (nth) time between tweets",
  dtime035  = "Shortest (nth) time between tweets",
  dtime036  = "Shortest (nth) time between tweets",
  dtime037  = "Shortest (nth) time between tweets",
  dtime038  = "Shortest (nth) time between tweets",
  dtime039  = "Shortest (nth) time between tweets",
  dtime040  = "Shortest (nth) time between tweets",
  dtime041  = "Shortest (nth) time between tweets",
  dtime042  = "Shortest (nth) time between tweets",
  dtime043  = "Shortest (nth) time between tweets",
  dtime044  = "Shortest (nth) time between tweets",
  dtime045  = "Shortest (nth) time between tweets",
  dtime046  = "Shortest (nth) time between tweets",
  dtime047  = "Shortest (nth) time between tweets",
  dtime048  = "Shortest (nth) time between tweets",
  dtime049  = "Shortest (nth) time between tweets",
  dtime050  = "Shortest (nth) time between tweets",
  dtime051  = "Shortest (nth) time between tweets",
  dtime052  = "Shortest (nth) time between tweets",
  dtime053  = "Shortest (nth) time between tweets",
  dtime054  = "Shortest (nth) time between tweets",
  dtime055  = "Shortest (nth) time between tweets",
  dtime056  = "Shortest (nth) time between tweets",
  dtime057  = "Shortest (nth) time between tweets",
  dtime058  = "Shortest (nth) time between tweets",
  dtime059  = "Shortest (nth) time between tweets",
  dtime060  = "Shortest (nth) time between tweets",
  dtime061  = "Shortest (nth) time between tweets",
  dtime062  = "Shortest (nth) time between tweets",
  dtime063  = "Shortest (nth) time between tweets",
  dtime064  = "Shortest (nth) time between tweets",
  dtime065  = "Shortest (nth) time between tweets",
  dtime066  = "Shortest (nth) time between tweets",
  dtime067  = "Shortest (nth) time between tweets",
  dtime068  = "Shortest (nth) time between tweets",
  dtime069  = "Shortest (nth) time between tweets",
  dtime070  = "Shortest (nth) time between tweets",
  dtime071  = "Shortest (nth) time between tweets",
  dtime072  = "Shortest (nth) time between tweets",
  dtime073  = "Shortest (nth) time between tweets",
  dtime074  = "Shortest (nth) time between tweets",
  dtime075  = "Shortest (nth) time between tweets",
  dtime076  = "Shortest (nth) time between tweets",
  dtime077  = "Shortest (nth) time between tweets",
  dtime078  = "Shortest (nth) time between tweets",
  dtime079  = "Shortest (nth) time between tweets",
  dtime080  = "Shortest (nth) time between tweets",
  dtime081  = "Shortest (nth) time between tweets",
  dtime082  = "Shortest (nth) time between tweets",
  dtime083  = "Shortest (nth) time between tweets",
  dtime084  = "Shortest (nth) time between tweets",
  dtime085  = "Shortest (nth) time between tweets",
  dtime086  = "Shortest (nth) time between tweets",
  dtime087  = "Shortest (nth) time between tweets",
  dtime088  = "Shortest (nth) time between tweets",
  dtime089  = "Shortest (nth) time between tweets",
  dtime090  = "Shortest (nth) time between tweets",
  dtime091  = "Shortest (nth) time between tweets",
  dtime092  = "Shortest (nth) time between tweets",
  dtime093  = "Shortest (nth) time between tweets",
  dtime094  = "Shortest (nth) time between tweets",
  dtime095  = "Shortest (nth) time between tweets",
  dtime096  = "Shortest (nth) time between tweets",
  dtime097  = "Shortest (nth) time between tweets",
  dtime098  = "Shortest (nth) time between tweets",
  dtime099  = "Shortest (nth) time between tweets",
  dtime100  = "Shortest (nth) time between tweets",
  dtime101  = "Shortest (nth) time between tweets",
  dtime102  = "Shortest (nth) time between tweets",
  dtime103  = "Shortest (nth) time between tweets",
  dtime104  = "Shortest (nth) time between tweets",
  dtime105  = "Shortest (nth) time between tweets",
  dtime106  = "Shortest (nth) time between tweets",
  dtime107  = "Shortest (nth) time between tweets",
  dtime108  = "Shortest (nth) time between tweets",
  dtime109  = "Shortest (nth) time between tweets",
  dtime110  = "Shortest (nth) time between tweets",
  dtime111  = "Shortest (nth) time between tweets",
  dtime112  = "Shortest (nth) time between tweets",
  dtime113  = "Shortest (nth) time between tweets",
  dtime114  = "Shortest (nth) time between tweets",
  dtime115  = "Shortest (nth) time between tweets",
  dtime116  = "Shortest (nth) time between tweets",
  dtime117  = "Shortest (nth) time between tweets",
  dtime118  = "Shortest (nth) time between tweets",
  dtime119  = "Shortest (nth) time between tweets",
  dtime120  = "Shortest (nth) time between tweets",
  dtime121  = "Shortest (nth) time between tweets",
  dtime122  = "Shortest (nth) time between tweets",
  dtime123  = "Shortest (nth) time between tweets",
  dtime124  = "Shortest (nth) time between tweets",
  dtime125  = "Shortest (nth) time between tweets",
  dtime126  = "Shortest (nth) time between tweets",
  dtime127  = "Shortest (nth) time between tweets",
  dtime128  = "Shortest (nth) time between tweets",
  dtime129  = "Shortest (nth) time between tweets",
  dtime130  = "Shortest (nth) time between tweets",
  dtime131  = "Shortest (nth) time between tweets",
  dtime132  = "Shortest (nth) time between tweets",
  dtime133  = "Shortest (nth) time between tweets",
  dtime134  = "Shortest (nth) time between tweets",
  dtime135  = "Shortest (nth) time between tweets",
  dtime136  = "Shortest (nth) time between tweets",
  dtime137  = "Shortest (nth) time between tweets",
  dtime138  = "Shortest (nth) time between tweets",
  dtime139  = "Shortest (nth) time between tweets",
  dtime140  = "Shortest (nth) time between tweets",
  dtime141  = "Shortest (nth) time between tweets",
  dtime142  = "Shortest (nth) time between tweets",
  dtime143  = "Shortest (nth) time between tweets",
  dtime144  = "Shortest (nth) time between tweets",
  dtime145  = "Shortest (nth) time between tweets",
  dtime146  = "Shortest (nth) time between tweets",
  dtime147  = "Shortest (nth) time between tweets",
  dtime148  = "Shortest (nth) time between tweets",
  dtime149  = "Shortest (nth) time between tweets",
  dtime150  = "Shortest (nth) time between tweets",
  dtime151  = "Shortest (nth) time between tweets",
  dtime152  = "Shortest (nth) time between tweets",
  dtime153  = "Shortest (nth) time between tweets",
  dtime154  = "Shortest (nth) time between tweets",
  dtime155  = "Shortest (nth) time between tweets",
  dtime156  = "Shortest (nth) time between tweets",
  dtime157  = "Shortest (nth) time between tweets",
  dtime158  = "Shortest (nth) time between tweets",
  dtime159  = "Shortest (nth) time between tweets",
  dtime160  = "Shortest (nth) time between tweets",
  dtime161  = "Shortest (nth) time between tweets",
  dtime162  = "Shortest (nth) time between tweets",
  dtime163  = "Shortest (nth) time between tweets",
  dtime164  = "Shortest (nth) time between tweets",
  dtime165  = "Shortest (nth) time between tweets",
  dtime166  = "Shortest (nth) time between tweets",
  dtime167  = "Shortest (nth) time between tweets",
  dtime168  = "Shortest (nth) time between tweets",
  dtime169  = "Shortest (nth) time between tweets",
  dtime170  = "Shortest (nth) time between tweets",
  dtime171  = "Shortest (nth) time between tweets",
  dtime172  = "Shortest (nth) time between tweets",
  dtime173  = "Shortest (nth) time between tweets",
  dtime174  = "Shortest (nth) time between tweets",
  dtime175  = "Shortest (nth) time between tweets",
  dtime176  = "Shortest (nth) time between tweets",
  dtime177  = "Shortest (nth) time between tweets",
  dtime178  = "Shortest (nth) time between tweets",
  dtime179  = "Shortest (nth) time between tweets",
  dtime180  = "Shortest (nth) time between tweets",
  dtime181  = "Shortest (nth) time between tweets",
  dtime182  = "Shortest (nth) time between tweets",
  dtime183  = "Shortest (nth) time between tweets",
  dtime184  = "Shortest (nth) time between tweets",
  dtime185  = "Shortest (nth) time between tweets",
  dtime186  = "Shortest (nth) time between tweets",
  dtime187  = "Shortest (nth) time between tweets",
  dtime188  = "Shortest (nth) time between tweets",
  dtime189  = "Shortest (nth) time between tweets",
  dtime190  = "Shortest (nth) time between tweets",
  dtime191  = "Shortest (nth) time between tweets",
  dtime192  = "Shortest (nth) time between tweets",
  dtime193  = "Shortest (nth) time between tweets",
  dtime194  = "Shortest (nth) time between tweets",
  dtime195  = "Shortest (nth) time between tweets",
  dtime196  = "Shortest (nth) time between tweets",
  dtime197  = "Shortest (nth) time between tweets",
  dtime198  = "Shortest (nth) time between tweets",
  dtime199  = "Shortest (nth) time between tweets"
)
