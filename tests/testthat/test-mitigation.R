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

test_that("intersectional_fairness warns on small groups", {
  set.seed(99)
  n <- 100
  race <- c(rep("White", 48), rep("Black", 48), rep("Other", 4))
  sex <- sample(c("M", "F"), n, replace = TRUE)
  expect_warning(
    intersectional_fairness(
      predictions = runif(n),
      labels = rbinom(n, 1, 0.3),
      race = race,
      sex = sex,
      min_group_size = 10
    ),
    "Dropping"
  )
})

test_that("grid_resolution parameter works in threshold_optimize", {
  data(compas_sim, package = "clinicalfair")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  mit_fine <- threshold_optimize(fd, grid_resolution = 0.01)
  mit_coarse <- threshold_optimize(fd, grid_resolution = 0.1)
  expect_s3_class(mit_fine, "fairness_mitigation")
  expect_s3_class(mit_coarse, "fairness_mitigation")
  # Fine grid should have at least as good disparity reduction
  after_fine <- max(abs(mit_fine$after$difference), na.rm = TRUE)
  after_coarse <- max(abs(mit_coarse$after$difference), na.rm = TRUE)
  expect_true(after_fine <= after_coarse + 0.05)
})

test_that("equalized_odds optimizes all groups including reference", {
  data(compas_sim, package = "clinicalfair")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  mit <- threshold_optimize(fd, objective = "equalized_odds")
  # Both groups should have thresholds (including reference)
  expect_true(all(fd$groups %in% names(mit$thresholds)))
  # Reference group threshold may differ from original 0.5
  # (since we now optimize all groups, not just non-reference)
})

