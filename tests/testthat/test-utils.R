test_that("split_test_train works", {
  d <- data.frame(
    x1 = rnorm(100),
    x2 = rnorm(100),
    y = sample(c(TRUE, FALSE), 100, replace = TRUE)
  )
  tt <- split_test_train(d, .p = 0.5, y)
  expect_true(is.list(tt))
  expect_equal(length(tt), 2)
  expect_named(tt, expected = c("train", "test"))
  expect_equal(nrow(tt$train), 50)
  expect_equal(sum(tt$train$y), sum(!tt$train$y))
})


test_that("log_counts works", {
  d <- data.frame(
    x1 = rpois(100, 05),
    x2 = rpois(100, 15) * rep(c(1L, -1L), 50L),
    y = sample(c(TRUE, FALSE), 100, replace = TRUE)
  )
  d <- log_counts(d)
  expect_true(is.data.frame(d))
  expect_equal(nrow(d), 100L)
  expect_equal(ncol(d), 3L)
  expect_true(all(d$x2 >= 0))
})
