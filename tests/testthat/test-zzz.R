test_that("destroy token", {
  skip_on_cran()

  if (file.exists("twitter_tokens"))
    unlink("twitter_tokens")

  expect_false(file.exists("twitter_tokens"))
})
