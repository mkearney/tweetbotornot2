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

is_null <- is.null
