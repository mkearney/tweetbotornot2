`%||%` <- function(x, y) {
  if (is_null(x)) {
    y
  } else {
    x
  }
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

percentile <- function(x) {
  dapr::vap_dbl(x, ~ (sum(x < .x) + 0.5 * sum(x == .x)) / length(x))
}

factor_ <- function(x, levels) {
  x[!x %in% levels] <- "NA"
  factor(x, levels)
}

the_mode <- function(x) {
  uq <- unique(x)
  if (is.character(x)) {
    x <- as.integer(factor(x,
      levels = uq, ordered = FALSE, exclude = FALSE))
  }
  uq[which.max(tabulate(x, nbins = length(uq)))]
}

as_source_type <- function(x) {
  x <- source_types$type[match(x, source_types$source)]
  x[is.na(x)] <- "NA"
  x
}

## for profile_image_url:      "", "gif", "jpeg", "jpg", "png"
## for profile_background_url: "", "gif", "png"
imge_levs <- c("gif", "jpeg", "jpg", "png", "NA")
bkgr_levs <- c("gif", "png", "NA")

as_image_type <- function(x) tolower(tfse::regmatches_first(x, "(?<=\\.)[[:alpha:]]+$"))
#table(is.na(.d$profile_banner_url))

dom_levs <- c("bit","cafedefaune","cheapbotsdonequick","decontextualize",
  "facebook","github","imdb","instagram","muffinlabs","patreon","theathletic",
  "twitch","twitter","wikipedia","youtu","youtube","NA")
as_dom <- function(x) {
  ifelse(is.na(x) | !x %in% dom_levs, "NA", x)
}
as_imge <- function(x) {
  ifelse(is.na(x) | !x %in% imge_levs, "NA", x)
}
as_bkgr <- function(x) {
  ifelse(is.na(x) | !x %in% bkgr_levs, "NA", x)
}
urldom <- function(x) {
  x <- tfse::regmatches_first(tolower(x), "(?<=://)[^/]+")
  x <- sub(paste0("^(", paste(c("www", "m", lang_levs),
    collapse = "|"), ")\\."), "", x)
  x <- sub("\\..*", "", x)
  x
}

max_round_time_2sec <- function(x) {
  x <- as.character(rtweet::round_time(x, "2 secs"))
  uq <- unique(x)
  max(tabulate(as.integer(factor(x,
    levels = uq, ordered = FALSE, exclude = FALSE)),
    nbins = length(uq)))
}

# lang_levs <- c("en","it","cy","nl","is","und","vi","el","et","ja","ca","fr",
#   "de","in","es","pt","pl","tl","ht","lt","no","fi","tr","ro","da","hi","sv",
#   "eu","cs","hu","sl","ru","zh","uk","lv","ar","ko","fa","ne","th","ml","am",
#   "iw","ur","bg","bo","bn","sr","ka","ta","hy","ps","mr","gu","pa","si","or",
#   "dv","kn","te","ckb","NA")
lang_levs <- c("ar","ca","de","en","es","et","fi","fr","hi","ht","in","it","ja",
  "ko","nl","pt","ro","ru","sv","tl","tr","und","NA")
as_lang <- function(x) {
  ifelse(is.na(x) | !x %in% lang_levs, "NA", x)
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

strip_twimg_url <- function(x) {
  if (any(grepl("http://pbs.twimg.com/", x, fixed = TRUE))) {
    x <-    sub("http://pbs.twimg.com/", "", x, fixed = TRUE)
  }
  if (any(grepl("http://abs.twimg.com/", x, fixed = TRUE))) {
    x <-    sub("http://abs.twimg.com/", "", x, fixed = TRUE)
  }
  if (any(grepl("https://pbs.twimg.com/", x, fixed = TRUE))) {
    x <- sub(   "https://pbs.twimg.com/", "", x, fixed = TRUE)
  }
  if (any(grepl("https://abs.twimg.com/", x, fixed = TRUE))) {
    x <-    sub("https://abs.twimg.com/", "", x, fixed = TRUE)
  }
  x
}


is_list_id <- function(x, ...) {
  if (isTRUE(attr(x, "is_list_id"))) {
    return(TRUE)
  }
  if (isFALSE(attr(x, "is_list_id"))) {
    return(TRUE)
  }
  all(grepl("^\\d+$", x)) &&
    any(dapr::vap_lgl(
      utils::head(x, 3), ~ NROW(rtweet::lists_statuses(.x)) > 0L
    ))
}

sampleit <- function(x, n) {
  if (!is.list(x)) {
    sort(sample(x, n))
  } else {
    sort(unlist(lapply(x, sample, round(n / length(x)), 0), use.names = FALSE))
  }
}

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

log_counts <- function(x) UseMethod("log_counts")

log_counts.default <- function(x) {
  x
}

log_counts.integer <- function(x) {
  if ((m <- min(x, na.rm = TRUE)) < 0L) {
    x <- x + 0L - m
  }
  log1p(x)
}

log_counts.list <- function(x) {
  cols <- names(x)[dapr::vap_lgl(x, is.integer)]
  for (i in cols) {
    x[[i]] <- log_counts(x[[i]])
  }
  x
}

log_counts.data.table <- function(x) {
  cols <- names(x)[dapr::vap_lgl(x, is.integer)]
  for (i in cols) {
    x[[i]] <- log_counts(x[[i]])
  }
  x
}

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
