test_that("predict_botometer works", {
  skip_on_cran()
  token <- tweetbotornot2:::create_token_from_secrets()
  b <- predict_botometer(c("kearneymw", "jack", NA_character_, "kearneymw", "a2431sdfas1234dfasdfa"),
    token = token)
  expect_true(is.data.frame(b))
  expect_equal(nrow(b), 5L)
  expect_equal(ncol(b), 4L)
  expect_named(b, expected = c("user_id", "screen_name", "botometer_english", "botometer_universal"))
})
