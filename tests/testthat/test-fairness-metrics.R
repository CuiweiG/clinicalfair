test_that("fairness_metrics returns correct structure", {
  set.seed(1)
  fd <- fairness_data(runif(100), rbinom(100, 1, 0.3),
                      rep(c("A", "B"), 50))
  fm <- fairness_metrics(fd)
  expect_s3_class(fm, "fairness_metrics")
  expect_true(all(c("group", "metric", "value", "ratio", "difference") %in% names(fm)))
})

test_that("perfect parity gives ratio = 1", {
  pred <- rep(0.6, 100)
  lab <- rep(1L, 100)
  grp <- rep(c("A", "B"), 50)
  fd <- fairness_data(pred, lab, grp)
  fm <- fairness_metrics(fd, metrics = "selection_rate")
  expect_true(all(fm$ratio == 1))
})

test_that("AUC computed correctly", {
  # Perfect separation within each group
  pred <- c(rep(0.9, 25), rep(0.1, 25), rep(0.9, 25), rep(0.1, 25))
  lab  <- c(rep(1L, 25),  rep(0L, 25),  rep(1L, 25),  rep(0L, 25))
  grp  <- c(rep("A", 50), rep("B", 50))
  fd <- fairness_data(pred, lab, grp)
  fm <- fairness_metrics(fd, metrics = "auc")
  expect_equal(fm$value[fm$group == "A"], 1.0)
  expect_equal(fm$value[fm$group == "B"], 1.0)
})

test_that("COMPAS dataset shows disparity", {
  data(compas_sim, package = "fairml")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  fm <- fairness_metrics(fd, metrics = "selection_rate")
  # Black group should have higher selection rate (known bias)
  sr_black <- fm$value[fm$group == "Black"]
  sr_white <- fm$value[fm$group == "White"]
  expect_gt(sr_black, sr_white)
})
