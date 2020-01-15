#' Sample Twitter Accounts
#'
#' Uses a snowball sampling method to identify (and gather) Twitter accounts
#'
#' @param x Vector or data frame containing screen names/user IDs. Or a vector
#'   or data frame containing list IDs/uri's.
#' @param n Maximum number of sample users to return.
#' @param regex Regular expression string used to filter lists–this pattern
#'   will be used to select which lists are relevant, e.g., "bot" will only use
#'   lists that contain the consecutive letters "bot"
#' @param ... Other args passed to rtweet function calls
#' @return Returns a data table with user_id, screen_name, description, and n
#'   (list appearance count)
#' #' @details
#' The search-based sampling method finds accounts by querying Twitter's
#' 'users/search' endpoint, which provides a simple interface for searching
#' public user profile information.
#'
#' Build a dataset by first selecting accounts using
#' \enumerate{
#'   \item user via lists_users & lists_members
#'   \item list via lists_members
#' }
#'
#' @export
sample_via_twitter_lists <- function(x, n = 1000, regex, ...) {
  UseMethod("sample_via_twitter_lists")
}


tweetbotornot_search_users <- function(keywords = c("bot", "automated", "twitterbot"),
                                  n = 1000, ...) {
  x <- dapr::lap(keywords, rtweet::search_users, n = n, ...)
  x <- data.table::data.table(do.call("rbind", x))
  x <- merge(x, x[, .(n = .N), by = user_id], by = "user_id")
  x <- x[order(-n), ][!duplicated(user_id), ]
  x[[".rtweet"]] <- "search_users"
  x
}

tweetbotornot_get_timelines <- function(x, ...) {
  data.table::data.table(
    suppressWarnings(
      rtweet::get_timelines(x, n = 200, check = FALSE, ...)
    )
  )
}

#' @export
sample_via_twitter_lists.data.frame <- function(x, n = 100, regex, ...) {
  x <- data.table::as.data.table(x)
  sample_via_twitter_lists(x, n = n, regex = regex, ...)
}

sample_via_twitter_lists.twist <- function(x, n = 1000, regex = NULL, ...) {
  if (is_ids(x)) {
    x <- data.table::data.table(list_id = as.character(x))
    return(sample_via_twitter_lists(x, n = n, regex = regex, ...))
  }
  ## if list path
  if (all(grepl("/lists/", x))) {
    x <- gsub("^/|.*twitter\\.com/|/(members|subscribers)/?|^/|/?$|@", "", x)
    x <- strsplit(x, "/lists/")
  } else if (all(grepl("/", x))) {
    x <- gsub("^/|/?$|@", "", x)
    x <- strsplit(x, "/")
  } else {
    stop("sample_via_twitter_lists input should be Twitter users or Twitter lists")
  }
  x <- data.table::data.table(
    owner_user = dapr::vap_chr(x, `[[`, 1L),
    slug = dapr::vap_chr(x, `[[`, 2L)
  )
  sample_via_twitter_lists(x, n = n, regex = regex, ...)
}

add_class <- function(x, cl) {
  `class<-`(x, unique(c(cl, class(x))))
}

#' @export
sample_via_twitter_lists.character <- function(x, n = 100, regex = NULL, ...) {
  if (all(grepl("/", x))) {
    x <- add_class(x, "twist")
    return(sample_via_twitter_lists(x = x, n = n, regex = regex, ...))
  }
  ## if `user_id` or `screen_name`
  if (!is_user(x)) {
    stop("sample_via_twitter_lists expected a vector of user IDs or screen names")
  }
  x <- dapr::lap(x, user_lists, n = ceiling(n / 200) * 200, ...)
  x <- do.call("rbind", x)
  if (NROW(x) == 0) {
    return(x)
  }
  . <- NULL
  member_count <- NULL
  slug <- NULL
  name <- NULL
  list_id <- NULL

  x <- x[, .(name = name[1], slug = slug[1], member_count = member_count[1], n = .N),
    by = list_id][order(-n), ]
  if (!is.null(regex)) {
    x <- x[grepl(regex, slug, ignore.case = TRUE) |
        grepl(regex, name, ignore.case = TRUE), ]
  }
  if (NROW(x) == 0) {
    return(x)
  }
  count <- ceiling(n / 500L) * 500L + 100
  x <- x[member_count >= 10, ]
  if (sum(cumsum(x[["member_count"]]) < count) < 5) {
    x <- utils::head(x, 6)
  } else {
    x <- x[c(TRUE, cumsum(member_count)[-length(member_count)]) < (count), ]
  }
  sample_via_twitter_lists(x = x, n = n, regex = regex, ...)
}

#' @export
sample_via_twitter_lists.data.table <- function(x, n = 100, regex, ...) {
  if (!"list_id" %in% names(x) &&
      !all(c("owner_user", "slug") %in% names(x))) {
    if ("user_id" %in% names(x)) {
      x <- x[, user_id]
    } else if ("screen_name" %in% names(x)) {
      x <- x[, screen_name]
    } else {
      stop("data frame input must include (1) user_id, (2) list_id, or (3) owner_user and slug")
    }
    return(sample_via_twitter_lists(x, n = n, regex = regex, ...))
  }
  l <- vector("list", nrow(x))
  if ("list_id" %in% names(x)) {
    list_id <- NULL
    x <- x[, list_id]
    for (i in seq_along(l)) {
      l[[i]] <- data.table::data.table(
        suppressWarnings(rtweet::lists_members(list_id = x[i]))
      )
      if (NROW(l[[i]]) > 0) {
        # lst <- user_lists(l[[i]]$user_id[i])
        # w <- which(lst[["list_id"]] == x[i])
        # if (length(w) > 0) {
        #   l[[i]][["list_id"]] <- lst[["list_id"]][w]
        #   l[[i]][["owner_user"]] <- gsub("^/|/lists.*", "", lst[["uri"]][w])
        #   l[[i]][["slug"]] <- lst[["slug"]][w]
        # } else {
        #   l[[i]][["list_id"]] <- x[i]
        #   l[[i]][["owner_user"]] <- NA_character_
        #   l[[i]][["slug"]] <- NA_character_
        # }
      }
    }
  } else {
    owner_user <- x[, owner_user]
    slug <- x[, slug]
    for (i in seq_len(nrow(x))) {
      for (i in seq_along(l)) {
        l[[i]] <- data.table::data.table(
          suppressWarnings(rtweet::lists_members(owner_user = owner_user[i],
            slug = slug[i], ...))
        )
      }
    }
  }
  l <- do.call("rbind", l)
  if ("created_at" %in% names(l) && !"account_created_at" %in% names(l)) {
    names(l)[names(l) == "created_at"] <- "account_created_at"
  }
  screen_name <- NULL
  description <- NULL
  account_created_at <- NULL
  statuses_count <- NULL
  friends_count <- NULL
  favourites_count <- NULL
  followers_count <- NULL
  listed_count <- NULL
  verified <- NULL
  . <- NULL
  user_id <- NULL
  l <- l[, .(screen_name = screen_name[1],
    description = description[1],
    account_created_at = account_created_at[1],
    statuses_count = statuses_count[1],
    favourites_count = favourites_count[1],
    friends_count = friends_count[1],
    followers_count = followers_count[1],
    listed_count = listed_count[1],
    verified = verified[1],
    n = .N),
    by = user_id][order(-n), ]
  utils::head(l, n)
}

sample_via_twitter_lists_nots <- function(x) {
  "person|people|man|real|friend"
}





tweetbotornot_search_users <- function(x, n = 1000, ...) {
  x <- dapr::lap(x, rtweet::search_users, n = n, ...)
  x <- do.call("rbind", x)
  x[[".rtweet"]] <- "search_users"
  x[[".sample"]] <- "search"
  data.table::data.table(x)
}

tweetbotornot_lookup_users <- function(x, ...) {
  if (is.null(x)) {
    x <- data.table::data.table(bot = logical())
    return(x)
  }
  if (!is.data.frame(x)) {
    x <- rtweet::lookup_users(x, ...)
  }
  x[["bot"]] <- TRUE
  x[[".rtweet"]] <- "lookup_users"
  x[[".sample"]] <- "lookup"
  data.table::data.table(x)
}

# bot <- function(x) UseMethod("bot")
#
# bot.character <- function(x) {
#   x <- tweetbotornot_lookup_users(x)
#   bot(x)
# }
#
# bot.data.frame <- function(x) {
#   x <- data.table::as.data.table(x)
#   bot(x)
# }
#
# as_dt <- function(x) {
#   `class<-`(x, c("data.table", "data.frame"))
# }
#
# bot.bot <- function(x) x
#
# bot.data.table <- function(x) {
#   if (!"bot" %in% names(x)) {
#     x[, bot := rep(NA, nrow(x))]
#   }
#   structure(
#     .Data = x,
#     .model = list(),
#     .N = nrow(x),
#     .features = ncol(x),
#     .bots = x[, sum(bot, na.rm = TRUE)],
#     .nots = x[, sum(!bot, na.rm = TRUE)],
#     class = "bot"
#   )
# }
# count_users <- function(x) attr(x, ".N")
# count_features <- function(x) attr(x, ".features")

# bot.default <- function(x) {
#   if (missing(x) || length(x) == 0) {
#     x <- data.table::data.table()
#     return(bot(x))
#   }
#   stop("bot expects a data table or character vector")
# }
#
# count_bots <- function(x) {
#   attr(x, ".bots")
# }
# count_nots <- function(x) {
#   attr(x, ".nots")
# }
# print.bot <- function(x) {
#   cat(format(x), fill = TRUE)
#   d <- as_dt(x)
#   if (all(c("user_id", "screen_name", "bot") %in% names(d))) {
#     cols <- c("user_id", "screen_name", "bot", "prob_bot",
#       "statuses_count", "friends_count", "followers_count",
#       "usr_twtrt", "usr_frnds", "usr_fflws")
#     cols <- cols[cols %in% names(d)]
#     d <- d[, ..cols]
#     d[, `. . .` := '. . .']
#   }
#   print(d)
# }
# format.bot <- function(x) {
#   gray <- crayon::make_style("#888888")
#   cat(gray(paste0("# A tweetbotornot2: ", count_users(x), " (users) x ",
#     count_features(x), " (features)")))
# }



# sample_via_twitter_lists_lists <- function(users, regex, ...) {
#   slug <- NULL
#   name <- NULL
#   list_id <- NULL
#   lu <- user_lists(users, ...)
#   lu <- lu[(grepl(regex, slug, ignore.case = TRUE) |
#       grepl(regex, name, ignore.case = TRUE)) &
#       !duplicated(list_id), ]
#   ul <- tweetbotornot_collect(lu, ...)
#   ul[["list_path"]] <- sub("^/", "", lu[["uri"]])[match(ul$list_id, lu$list_id)]
#   ul[["list_owner_user"]] <- sub("/.*", "", ul[["list_path"]])
#   ul[["list_slug"]] <- sub(".*/", "", ul[["list_path"]])
#   ul
# }

user_lists <- function(user, n = 1000, ...) {
  its <- ceiling(n / 200)
  rl <- rtweet::rate_limit("lists_memberships", ...)
  if (rl[["remaining"]] < its) {
    its <- rl[["remaining"]]
  }
  l <- vector('list', its)
  nc <- NULL
  for (i in seq_along(l)) {
    l[[i]] <- rtweet::lists_memberships(user = user, n = 200, cursor = nc, ...)
    if (NROW(l[[i]]) > 0) {
      l[[i]][["membership_user"]] <- user
    }
    nc <- rtweet::next_cursor(l[[i]])
    if (length(nc) == 0 || as.numeric(nc) <= 0) {
      break
    }
  }
  data.table::data.table(do.call("rbind", l))
}
