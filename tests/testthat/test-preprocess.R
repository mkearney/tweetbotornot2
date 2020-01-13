test_that("preprocess_bot works", {
  skip_on_cran()

  token <- readRDS("twitter_tokens")
  x <- rtweet::get_timelines(c("twitter", "jack"), n = 200, check = FALSE, token = token)
  fake_user <- function(x) {
    x[["user_id"]] <- paste(sample(0:9, 14, replace = TRUE), collapse = "")
    x[["screen_name"]] <- paste0(sample(letters, 8, replace = TRUE), collapse = "")
    x
  }
  xx <- replicate(500, lapply(split(x, x$user_id), fake_user), simplify = FALSE)
  xx <- do.call("rbind", dapr::lap(xx, ~ do.call("rbind", .x)))
  xx <- preprocess_bot(xx, batch_size = 50)
  expect_true(is.data.frame(xx))
  expect_true(nrow(xx) == 1000)
  x <- preprocess_bot(x, token = token)
  expect_true(is.data.frame(x))
  expect_true(inherits(x, "data.table"))
  expect_true(nrow(x) == 2)
  expect_equal(ncol(x), 58)
  expect_true(all(c("user_id", "screen_name", "bot", "tweets", "usr_prfimNA") %in% names(x)))
  x <- data.frame(x = 1:5, y = letters[1:5])
  expect_error(preprocess_bot(x))
})
