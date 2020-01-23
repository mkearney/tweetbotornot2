test_that("chunk_users works", {
  ## this generates a vector of user-ID like values
  users <- replicate(1000, paste(sample(0:9, 14, replace = TRUE), collapse = ""))

  ## break users into 100-user chunks
  chunky <- chunk_users(users, n = 100)
  expect_equal(length(chunky), 10L)

  ## break into 100-user data frames
  chunky <- chunk_users_data(data.frame(user_id = users), n = 100)
  expect_equal(length(chunky), 10L)
})
