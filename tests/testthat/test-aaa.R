test_that("create token", {
  skip_on_cran()

  if (!"TWITTER_PAT" %in% names(Sys.getenv())) {
    token <- rtweet::create_token(
      "rstats2twitter",
      consumer_key = rtweet:::decript_key(),
      consumer_secret = rtweet:::decript_secret(),
      access_secret = rtweet:::rtweet_find_access_secret(),
      access_token = rtweet:::rtweet_find_access_key(),
      set_renv = FALSE
    )
  } else {
    token <- readRDS(Sys.getenv("TWITTER_PAT"))
  }
  e <- tryCatch(rtweet:::api_access_level(token),
    error = function(e) NULL)
  expect_true(!is.null(e))

  x <- predict_bot(c("twitter", "jack"), token = token)
  expect_true(is.data.frame(x))
  expect_gt(nrow(x), 0)
  saveRDS(token$clone(), "twitter_tokens")
  expect_true(file.exists("twitter_tokens"))
  requireNamespace("rtweet", quietly = TRUE)

  assign("twitter_tokens", token, envir = rtweet:::.state)
  x <- predict_bot(c("twitter", "jack"))
  expect_true(is.data.frame(x))
  expect_gt(nrow(x), 0)
})
