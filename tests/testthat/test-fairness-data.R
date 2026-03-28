test_that("fairness_data constructs correctly", {
  fd <- fairness_data(runif(100), rbinom(100, 1, 0.3),
                      rep(c("A", "B"), 50))
  expect_s3_class(fd, "fairness_data")
  expect_equal(fd$n, 100L)
  expect_equal(length(fd$groups), 2L)
})

test_that("fairness_data rejects bad inputs", {
  expect_error(fairness_data("a", 1, "G"))
  expect_error(fairness_data(0.5, 2, "G"))
  expect_error(fairness_data(c(0.5, 0.3), 1, "G"))
})

test_that("fairness_data auto-selects reference", {
  set.seed(1)
  fd <- fairness_data(c(runif(50, 0.6, 1), runif(50, 0, 0.4)),
                      rbinom(100, 1, 0.5),
                      rep(c("High", "Low"), each = 50))
  expect_equal(fd$reference_group, "High")
})

test_that("print works", {
  fd <- fairness_data(runif(50), rbinom(50, 1, 0.3),
                      rep(c("X", "Y"), 25))
  expect_no_error(print(fd))
})

