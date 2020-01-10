test_that("model_data_bot works", {
  skip_on_cran()
  x <- model_data_bot(c("twitter", "jack"))
  expect_true(is.data.frame(x))
  expect_true(inherits(x, "data.table"))
  expect_true(nrow(x) == 2)
  expect_gt(ncol(x), 15)
  expect_true(all(c("user_id", "screen_name") %in% names(x)))
  x <- data.frame(x = 1:5, y = letters[1:5])
  expect_error(model_data_bot(x))
})

