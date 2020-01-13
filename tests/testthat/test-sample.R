

test_that("sample_via_twitter_lists works", {
  skip_on_cran()
  x <- sample_via_twitter_lists(c("VancityReynolds", "AnnaKendrick47"), n = 500)
  expect_true(is.data.frame(x))
  expect_true(inherits(x, "data.table"))
  expect_true(nrow(x) == 500)
  expect_gt(ncol(x), 4)
  expect_true(all(c("user_id", "screen_name", "n") %in% names(x)))
  x <- data.frame(x = 1:5, y = letters[1:5])
  expect_error(sample_via_twitter_lists(x))
})
