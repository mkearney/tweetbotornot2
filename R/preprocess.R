
#' Preprocess data
#'
#' Prepares data for Twitter bot model
#'
#' @inheritParams predict_bot
#' @return Returns a data frame used to generate predictions
#' @examples
#'
#' \dontrun{
#'
#' #' ## vector of screen names
#' x <- c("netflix_bot", "aasfdiouyasdoifu", "madeupusernamethatiswrong",
#'   "a_quilt_bot", "jack", "SHAQ", "aasfdiouyasdoifu5", NA_character_,
#'   "madeupusernamethatiswrong", "a_quilt_bot")
#'
#' ## preprocess_bot - returns features data.table
#' ftrs <- preprocess_bot(x)
#'
#' ## use features to generate predictions
#' predict_bot(ftrs)
#'
#' }
#'
#' @export
preprocess_bot <- function(x, batch_size = 100, ...) UseMethod("preprocess_bot")

#' @export
preprocess_bot.character <- function(x, batch_size = 100, ...) {
  x <- unique(x[!is.na(x)])
  ogusrs <- x
  x <- suppressWarnings(
    rtweet::get_timelines(x, n = 200, check = FALSE, ...)
  )
  x <- data.table::as.data.table(x)
  attr(x, ".ogusrs") <- ogusrs
  preprocess_bot(x, batch_size = batch_size)
}

#' @export
preprocess_bot.factor <- function(x, batch_size = 100, ...) {
  x <- as.character(x)
  preprocess_bot(x, batch_size = batch_size, ...)
}

#' @export
preprocess_bot.data.frame <- function(x, batch_size = 100, ...) {
  if (".ogusrs" %in% names(attributes(x))) {
    ogusrs <- attr(x, ".ogusrs")
    x <- data.table::data.table(x)
    attr(x, ".ogusrs") <- ogusrs
  } else {
    x <- data.table::data.table(x)
  }
  preprocess_bot(x, batch_size = batch_size, ...)
}


#' @export
preprocess_bot.data.table <- function(x, batch_size = 100, ...) {
  user_id <- NULL
  if (all(
    tweetbotornot_xgb_model$feature_names %in% names(x)
  )) {
    return(x)
  }
  if (any(c("user_id", "screen_name", "id_str") %in% names(x)) &&
      all(!c("text", "friends_count") %in% names(x))) {
    x <- pluck_users(x)
    return(preprocess_bot(x, ...))
  }
  if (".ogusrs" %in% names(attributes(x))) {
    ogusrs <- attr(x, ".ogusrs")
  } else {
    ogusrs <- unique(x$user_id[!is.na(x$user_id)])
  }
  ## if no batches, process and return
  x <- preprocess_bot_init(x)
  uid <- unique(x[, user_id])
  if (is.null(batch_size) || isFALSE(batch_size) || length(uid) <= batch_size) {
    x <- preprocess_bot_group(x)
    attr(x, ".ogusrs") <- ogusrs
    return(x)
  }

  ## split data by user
  uid <- factor(x[, user_id], levels = uid)
  i <- cut(
    as.integer(uid),
    breaks = ceiling(length(levels(uid)) / batch_size),
    right = TRUE,
    labels = FALSE
  )
  x <- split(x, i)

  ## setup progress bar
  pb <- progress::progress_bar$new(
    format = " processing [:bar] :percent",
    total = length(x), clear = FALSE,
    width = if ((w <- getOption("width", 70)) > 70) 70 else w)

  ## iterate through split data
  x <- lapply(x, function(.x) {
    tryCatch(pb$tick(1), error = function(e) return(NULL))
    return(preprocess_bot_group(.x))
  })

  ## bind into data frame
  x <- do.call("rbind", x)

  ## put original users info back
  attr(x, ".ogusrs") <- ogusrs

  ## return
  x
}

preprocess_bot_init <- function(x) {
  ## store order
  ogusrs <- attr(x, ".ogusrs")

  ##--------------------------------------------------------------------------##
  ##                           (FOR CRAN CHECKS)                              ##
  ##--------------------------------------------------------------------------##
  text <- NULL
  display_text_width <- NULL
  reply_to_status_id <- NULL
  mentions_user_id <- NULL
  hashtags <- NULL
  media_expanded_url <- NULL
  ext_media_expanded_url <- NULL
  urls_expanded_url <- NULL
  mentions_user_id <- NULL
  media_type <- NULL
  user_id <- NULL
  account_created_at <- NULL
  created_at <- NULL
  profile_expanded_url <- NULL
  profile_banner_url <- NULL
  profile_image_url <- NULL
  profile_background_url <- NULL
  place_full_name <- NULL
  . <- NULL
  usr_allrt <- NULL
  is_retweet <- NULL
  twt_min15 <- NULL
  twt_min30 <- NULL
  bot <- NULL
  usr_actyr <- NULL

  if (!all(req_cols %in% names(x))) {
    .req_cols <- req_cols[!req_cols %in% names(x)]
    stop("Missing the following variables: ",
      paste(.req_cols, collapse = ", "), call. = FALSE)
  }
  ## copy and reorder rows by user and then date
  data <- data.table::copy(x[order(ffactor(user_id), -created_at), ])
  data.table::setkey(data, user_id)

  ## only include up to 200 most recent tweets
  data[, .i := seq_len(.n), by = user_id]
  data <- data[.i <= 200L, ]
  data[, .i := NULL]

  data[, usr_allrt := all(is_retweet), by = user_id]
  data[, text := ifelse(usr_allrt, text, ifelse(is_retweet, NA_character_, text))]
  data[, display_text_width := ifelse(usr_allrt, display_text_width,
    ifelse(is_retweet, NA_integer_, display_text_width))]

  ##--------------------------------------------------------------------------##
  ##                         MODIFY BY REFERENCE                              ##
  ##--------------------------------------------------------------------------##
  data[,
    `:=`(
      text = count_words(text),
      twt_min15 = round_daytime15(created_at),
      twt_min30 = round_daytime30(created_at),
      place_full_name = is.na(place_full_name),
      reply_to_status_id = is.na(reply_to_status_id),
      media_type = dapr::vap_lgl(media_type, ~ is.na(.x[1])),
      hashtags = count_list_col(hashtags),
      urls_expanded_url = count_list_col(urls_expanded_url),
      media_expanded_url = count_list_col(media_expanded_url),
      ext_media_expanded_url = count_list_col(ext_media_expanded_url),
      mentions_user_id = count_list_col(mentions_user_id),
      source_type = factor_(as_source_type(source),
        levels = c("bot_enablers", "bot_notsures", "bot_thebig2s", "NA",
          "pop_assister", "pop_notsures", "pop_platform", "twt_official"))
    )]
  data[,
    usr_actyr := in_years(Sys.time(), account_created_at),
    by = user_id]
  if (!"bot" %in% names(data)) {
    data[, bot := NA]
  }
  ## add original users back
  attr(data, ".ogusrs") <- ogusrs
  data
}


preprocess_bot_group <- function(data) {
  ##--------------------------------------------------------------------------##
  ##                           (FOR CRAN CHECKS)                              ##
  ##--------------------------------------------------------------------------##
  . <- NULL
  display_text_width <- NULL
  lang <- NULL
  source <- NULL
  is_retweet <- NULL
  is_quote <- NULL
  verified <- NULL
  screen_name <- NULL
  statuses_count <- NULL
  friends_count <- NULL
  followers_count <- NULL
  favourites_count <- NULL
  source_type <- NULL
  usr_prfim <- NULL
  prob_bot <- NULL

  text <- NULL
  reply_to_status_id <- NULL
  mentions_user_id <- NULL
  hashtags <- NULL
  media_expanded_url <- NULL
  ext_media_expanded_url <- NULL
  urls_expanded_url <- NULL
  mentions_user_id <- NULL
  media_type <- NULL
  user_id <- NULL
  account_created_at <- NULL
  created_at <- NULL
  profile_expanded_url <- NULL
  profile_banner_url <- NULL
  profile_image_url <- NULL
  profile_background_url <- NULL
  place_full_name <- NULL
  usr_allrt <- NULL
  twt_min15 <- NULL
  twt_min30 <- NULL
  bot <- NULL
  usr_actyr <- NULL
  tweets <- NULL

  ##--------------------------------------------------------------------------##
  ##                            GROUP BY USER_ID                              ##
  ##--------------------------------------------------------------------------##
  data <- data[,
    .(
      ## top-level vars
      screen_name = screen_name[1],
      bot       = bot[1],
      tweets    = .N,

      ## user-level features
      usr_prfim = factor_(tolower(sub(".*normal\\.?", "", profile_image_url[1])),
        levels = c("bmp", "gif", "jpeg", "jpg", "png", "NA")),
      usr_prfbg = is.na(profile_background_url[1]),
      usr_prfbn = is.na(profile_banner_url[1]),
      usr_prfur = is.na(profile_expanded_url[1]),
      usr_twtrt = statuses_count[1],
      usr_ffrat = log1p(followers_count[1] + 1) / log1p(friends_count[1] + 1),
      usr_faves = favourites_count[1],
      usr_frnds = friends_count[1],
      usr_fllws = followers_count[1],
      usr_verif = verified[1],
      usr_actyr = usr_actyr[1],
      usr_allrt = usr_allrt[1],

      ## status-level features I – COUNTS
      twt_langs = data.table::uniqueN(lang),
      twt_srces = data.table::uniqueN(source),
      twt_srcts = data.table::uniqueN(source_type),
      twt_src2b = sum(source_type == "bot_thebig2s") / .N,
      twt_srcbe = sum(source_type == "bot_enablers") / .N,
      twt_srctw = sum(source_type == "twt_official") / .N,
      twt_srcbu = sum(source_type == "bot_notsures") / .N,
      twt_srcpp = sum(source_type == "pop_platform") / .N,
      twt_srcas = sum(source_type == "pop_assister") / .N,
      twt_srcpu = sum(source_type == "pop_notsures") / .N,
      twt_srcna = sum(source_type == "NA") / .N,
      twt_rtwts = sum(is_retweet) / .N,
      twt_quots = sum(is_quote) / .N,
      twt_rplys = sum(reply_to_status_id) / .N,
      twt_place = sum(place_full_name) / .N,
      twt_int15 = uniqueN(twt_min15) / .N,
      twt_int30 = uniqueN(twt_min30) / .N,
      twt_bunch = max_round_time_2sec(created_at) / .N,
      twt_max15 = max_freq(twt_min15) / .N,
      twt_min15 = min_freq(twt_min15) / .N,
      twt_max30 = max_freq(twt_min30) / .N,
      twt_min30 = min_freq(twt_min30) / .N,

      ## status-level features II – STATS
      twt_wrdmn = mean_(text),
      twt_wrdsd = sd_(text),
      twt_wdtmn = mean_(display_text_width),
      twt_wdtsd = sd_(display_text_width),
      twt_atsmn = mean_(mentions_user_id),
      twt_atssd = sd_(mentions_user_id),
      twt_hshmn = mean_(hashtags),
      twt_hshsd = sd_(hashtags),
      twt_medmn = mean_(media_expanded_url),
      twt_medsd = sd_(media_expanded_url),
      twt_mtpmn = mean_(media_type),
      twt_mtpsd = sd_(media_type),
      twt_emdmn = mean_(ext_media_expanded_url),
      twt_emdsd = sd_(ext_media_expanded_url),
      twt_urlmn = mean_(urls_expanded_url),
      twt_urlsd = sd_(urls_expanded_url)
    ),
    by = user_id
    ]
  cbind(data[, -"usr_prfim"], model.matrix_(data[, .(usr_prfim)]))
}

model.matrix_ <- function(x) {
  f <- paste("~", paste(names(x), collapse = " + "))
  f <- stats::as.formula(f, environment())
  x <- data.table::as.data.table(stats::model.matrix.default(f, data = x))
  x[, -1]
}


req_cols <- c("user_id",
  "screen_name",
  "account_created_at",
  "text",
  "display_text_width",
  "profile_background_url",
  "profile_banner_url",
  "profile_expanded_url",
  "place_full_name",
  "reply_to_status_id",
  "media_type",
  "hashtags",
  "urls_expanded_url",
  "media_expanded_url",
  "ext_media_expanded_url",
  "mentions_user_id",
  "source",
  "profile_image_url",
  "account_created_at",
  "lang",
  "is_retweet",
  "is_quote",
  "statuses_count",
  "followers_count",
  "friends_count",
  "favourites_count",
  "verified"
)

