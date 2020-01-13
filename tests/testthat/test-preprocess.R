test_that("preprocess_bot works", {
  skip_on_cran()

  token <- readRDS("twitter_tokens")
  x <- preprocess_bot(c("twitter", "jack"), token = token)
  expect_true(is.data.frame(x))
  expect_true(inherits(x, "data.table"))
  expect_true(nrow(x) == 2)
  expect_equal(ncol(x), 58)
  expect_true(all(c("user_id", "screen_name", "bot", "tweets", "usr_prfimNA") %in% names(x)))
  x <- data.frame(x = 1:5, y = letters[1:5])
  expect_error(preprocess_bot(x))
})
