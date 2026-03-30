#' Compute fairness metrics across groups
#'
#' Calculates a comprehensive set of group-wise and comparative
#' fairness metrics from a `fairness_data` object, with optional
#' bootstrap confidence intervals.
#'
#' @param data A [fairness_data] object.
#' @param metrics Character vector of metrics to compute. Default
#'   computes all available metrics. Options: `"selection_rate"`,
#'   `"tpr"`, `"fpr"`, `"ppv"`, `"accuracy"`,
#'   `"auc"`, `"brier"`.
#' @param ci Logical; if `TRUE`, compute bootstrap confidence
#'   intervals for each metric. Default `FALSE`.
#' @param n_boot Number of bootstrap replicates when `ci = TRUE`.
#'   Default 2000.
#' @param ci_level Confidence level for the interval. Default 0.95.
#'
#' @return A `fairness_metrics` object (tibble) with columns:
#'   `group`, `metric`, `value`, `ratio` (vs reference group),
#'   `difference` (vs reference group). When `ci = TRUE`, additional
#'   columns `ci_lower` and `ci_upper` are included.
#'
#' @details
#' Fairness is assessed by comparing metric values across groups.
#' A ratio of 1.0 or difference of 0.0 indicates perfect parity.
#' Common thresholds: ratio in \eqn{[0.8, 1.25]} (four-fifths rule,
#' EEOC guidelines) or difference < 0.05.
#'
#' When `ci = TRUE`, percentile bootstrap confidence intervals are
#' computed by resampling within each group. This accounts for
#' sampling variability and is recommended when reporting fairness
#' metrics for regulatory or publication purposes.
#'
#' @references
#' Obermeyer Z, et al. (2019). Dissecting racial bias in an
#' algorithm used to manage the health of populations. \emph{Science},
#' 366(6464):447--453. \doi{10.1126/science.aax2342}
#'
#' @examples
#' set.seed(42)
#' fd <- fairness_data(
#'   predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
#'   labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
#'   protected_attr = rep(c("A", "B"), each = 100)
#' )
#' fairness_metrics(fd)
#'
#' # With bootstrap CIs
#' fairness_metrics(fd, ci = TRUE, n_boot = 500)
#'
#' @export
fairness_metrics <- function(data,
                             metrics = c("selection_rate", "tpr", "fpr",
                                         "ppv", "accuracy", "auc", "brier"),
                             ci = FALSE,
                             n_boot = 2000L,
                             ci_level = 0.95) {
  if (!inherits(data, "fairness_data"))
    cli::cli_abort("{.arg data} must be a {.cls fairness_data} object.")

  ref <- data$reference_group
  results <- list()

  for (grp in data$groups) {
    idx <- data$protected == grp
    pred <- data$predictions[idx]
    lab  <- data$labels[idx]
    cls  <- data$predicted_class[idx]
    n_grp <- sum(idx)

    vals <- .compute_group_metrics(pred, lab, cls, n_grp, metrics)

    # Bootstrap CIs
    ci_lo <- ci_hi <- NULL
    if (ci) {
      boot_mat <- .bootstrap_metrics(pred, lab, cls, n_grp, metrics,
                                     n_boot = n_boot, ci_level = ci_level)
      ci_lo <- boot_mat$lower
      ci_hi <- boot_mat$upper
    }

    for (i in seq_along(vals)) {
      m <- names(vals)[i]
      row <- tibble::tibble(group = grp, metric = m, value = vals[[i]])
      if (ci) {
        row$ci_lower <- ci_lo[m]
        row$ci_upper <- ci_hi[m]
      }
      results <- c(results, list(row))
    }
  }

  out <- dplyr::bind_rows(results)

  # Compute ratio and difference vs reference
  ref_vals <- out[out$group == ref, c("metric", "value")]
  names(ref_vals)[2] <- "ref_value"
  out <- dplyr::left_join(out, ref_vals, by = "metric")
  out$ratio <- ifelse(out$ref_value != 0, out$value / out$ref_value, NA_real_)
  out$difference <- out$value - out$ref_value
  out$ref_value <- NULL

  structure(out, class = c("fairness_metrics", class(tibble::tibble())),
            reference_group = ref)
}

#' Compute metrics for a single group
#' @noRd
.compute_group_metrics <- function(pred, lab, cls, n_grp, metrics) {
  tp <- sum(cls == 1 & lab == 1)
  fp <- sum(cls == 1 & lab == 0)
  tn <- sum(cls == 0 & lab == 0)
  fn <- sum(cls == 0 & lab == 1)

  vals <- list()
  if ("selection_rate" %in% metrics) vals$selection_rate <- mean(cls)
  if ("tpr" %in% metrics) vals$tpr <- if (tp + fn > 0) tp / (tp + fn) else NA_real_
  if ("fpr" %in% metrics) vals$fpr <- if (fp + tn > 0) fp / (fp + tn) else NA_real_
  if ("ppv" %in% metrics) vals$ppv <- if (tp + fp > 0) tp / (tp + fp) else NA_real_
  if ("accuracy" %in% metrics) vals$accuracy <- (tp + tn) / n_grp
  if ("brier" %in% metrics) vals$brier <- mean((pred - lab)^2)
  if ("auc" %in% metrics) vals$auc <- .compute_auc(pred, lab)
  vals
}

#' Bootstrap confidence intervals for group metrics
#' @noRd
.bootstrap_metrics <- function(pred, lab, cls, n_grp, metrics,
                               n_boot, ci_level) {
  alpha <- 1 - ci_level
  boot_results <- list()

  for (b in seq_len(n_boot)) {
    idx_b <- sample.int(n_grp, replace = TRUE)
    vals_b <- .compute_group_metrics(pred[idx_b], lab[idx_b], cls[idx_b],
                                     n_grp, metrics)
    boot_results[[b]] <- vapply(vals_b, function(x) x, numeric(1))
  }

  boot_mat <- do.call(rbind, boot_results)
  lower <- apply(boot_mat, 2, stats::quantile,
                 probs = alpha / 2, na.rm = TRUE)
  upper <- apply(boot_mat, 2, stats::quantile,
                 probs = 1 - alpha / 2, na.rm = TRUE)
  list(lower = lower, upper = upper)
}

#' @export
print.fairness_metrics <- function(x, ...) {
  ref <- attr(x, "reference_group")
  cli::cli_h3("Fairness metrics (reference: {ref})")
  NextMethod()
}

#' Simple AUC computation (trapezoidal)
#' @noRd
.compute_auc <- function(pred, lab) {
  if (length(unique(lab)) < 2) return(NA_real_)
  n1 <- sum(lab == 1)
  n0 <- sum(lab == 0)
  if (n1 == 0 || n0 == 0) return(NA_real_)
  r <- rank(pred)
  (sum(r[lab == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
