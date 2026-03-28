test_that("fairness_report detects violations", {
  data(compas_sim, package = "clinicalfair")
  fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                      compas_sim$race)
  rpt <- fairness_report(fd)
  expect_s3_class(rpt, "fairness_report")
  expect_true(nrow(rpt$flags) > 0)  # COMPAS has known bias
  expect_no_error(print(rpt))
})

test_that("fairness_report with no violations", {
  set.seed(1)
  pred <- runif(200)
  lab <- rbinom(200, 1, 0.3)
  grp <- rep(c("A", "B"), 100)
  fd <- fairness_data(pred, lab, grp)
  rpt <- fairness_report(fd)
  expect_s3_class(rpt, "fairness_report")
})

