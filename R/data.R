#' Simulated COMPAS-like recidivism prediction data
#'
#' A simulated dataset reflecting the documented racial disparities
#' in recidivism prediction algorithms, based on published statistics
#' from the ProPublica investigation (Angwin et al. 2016).
#'
#' @format A data frame with 1000 rows and 3 columns:
#' \describe{
#'   \item{risk_score}{Predicted recidivism risk (numeric, 0--1).}
#'   \item{recidivism}{Actual recidivism outcome (binary, 0/1).}
#'   \item{race}{Racial group: White or Black (character).}
#' }
#'
#' @source Simulated. Based on patterns from Angwin et al. (2016)
#'   "Machine Bias" and Obermeyer et al. (2019)
#'   \doi{10.1126/science.aax2342}.
#'
#' @examples
#' data(compas_sim)
#' fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
#'                     compas_sim$race)
#' fairness_metrics(fd)
"compas_sim"

