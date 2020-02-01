test_that("create token", {
  skip_on_cran()

  token <- tweetbotornot2:::create_token_from_secrets()
  e <- tryCatch(rtweet:::api_access_level(token),
    error = function(e) NULL)
  expect_true(!is.null(e))

  x <- predict_bot(c("twitter", "jack"), token = token)
  expect_true(is.data.frame(x))
  expect_gt(nrow(x), 0)
  requireNamespace("rtweet", quietly = TRUE)

  assign("twitter_tokens", token, envir = rtweet:::.state)
  x <- predict_bot(c("twitter", "jack"))
  expect_true(is.data.frame(x))
  expect_gt(nrow(x), 0)
})
