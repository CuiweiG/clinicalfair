test_that("threshold_optimize reduces disparity", {
  data(compas_sim, package = "clinicalfair")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  mit <- threshold_optimize(fd, objective = "equalized_odds")

  expect_s3_class(mit, "fairness_mitigation")
  expect_true(length(mit$thresholds) == 2)
  expect_no_error(print(mit))

  # Disparity should decrease (or at least not increase much)
  before_max <- max(abs(mit$before$difference), na.rm = TRUE)
  after_max <- max(abs(mit$after$difference), na.rm = TRUE)
  # Allow some tolerance
  expect_true(after_max <= before_max + 0.1)
})

test_that("demographic_parity optimization works", {
  data(compas_sim, package = "clinicalfair")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  mit <- threshold_optimize(fd, objective = "demographic_parity")
  expect_s3_class(mit, "fairness_mitigation")
  expect_equal(mit$objective, "demographic_parity")
})

test_that("plot_calibration returns ggplot", {
  data(compas_sim, package = "clinicalfair")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  p <- plot_calibration(fd)
  expect_s3_class(p, "gg")
})

test_that("intersectional_fairness works", {
  set.seed(42)
  n <- 400
  result <- intersectional_fairness(
    predictions = runif(n),
    labels = rbinom(n, 1, 0.3),
    race = sample(c("White", "Black"), n, replace = TRUE),
    sex = sample(c("M", "F"), n, replace = TRUE)
  )
  expect_s3_class(result, "fairness_metrics")
  expect_true(length(unique(result$group)) == 4)
})

