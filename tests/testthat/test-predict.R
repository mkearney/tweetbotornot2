test_that("predict_bot works", {
  skip_on_cran()
  token <- readRDS("twitter_tokens")
  x <- predict_bot(c("twitter", "jack"), token = token)
  expect_true(is.data.frame(x))
  expect_true(inherits(x, "data.table"))
  expect_true(nrow(x) == 2)
  expect_equal(ncol(x), 3)
  expect_true(all(c("user_id", "screen_name", "prob_bot") %in% names(x)))
  x <- data.frame(x = 1:5, y = letters[1:5])
  expect_error(predict_bot(x))

  x <- c("netflix_bot", "aasfdiouyasdoifu", "madeupusernamethatiswrong",
    "a_quilt_bot", "jack", "SHAQ", "aasfdiouyasdoifu5", NA_character_,
    "madeupusernamethatiswrong", "a_quilt_bot")
  p1 <- predict_bot(x)
  expect_equal(nrow(p1), 7)

  p2 <- predict_bot_score(x)
  expect_true(
    is.numeric(p2)
  )
  expect_equal(
    length(x), length(p2)
  )
  p2d <- data.table::data.table(
    screen_name = x,
    prob_bot = p2
  )
  expect_true(identical(
    p1[order(screen_name), .(screen_name, prob_bot)],
    unique(p2d)[order(screen_name), ][!is.na(screen_name), ],
    ignore.environment = TRUE,
    ignore.srcref = TRUE
  ))


  x <- predict_bot(data.frame(user_id = c("1203840834", "2973406683")))
  expect_true(is.data.frame(x))
  expect_true(inherits(x, "data.table"))
  expect_true(nrow(x) == 2)
  expect_equal(ncol(x), 3)
  expect_true(all(c("user_id", "screen_name", "prob_bot") %in% names(x)))

  x <- predict_bot_score(data.frame(user_id = c("1203840834", "2973406683")))
  expect_true(is.numeric(x))
  expect_equal(length(x), 2L)
})
