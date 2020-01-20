test_that("predict_botometer works", {
  b <- predict_botometer(c("kearneymw", "jack"))
  expect_true(is.data.frame(b))
  expect_equal(nrow(b), 2L)
})
