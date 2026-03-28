#' Optimize thresholds for fairness
#'
#' Finds group-specific decision thresholds that maximize accuracy
#' subject to a fairness constraint, or minimize disparity subject
#' to a minimum accuracy constraint.
#'
#' @param data A [fairness_data] object.
#' @param objective `"equalized_odds"` (default): minimize TPR/FPR
#'   disparity. `"demographic_parity"`: equalize selection rates.
#' @param min_accuracy Minimum acceptable overall accuracy. Default 0.5.
#'
#' @return A `fairness_mitigation` object (list) with:
#'   `$thresholds` (named numeric, one per group),
#'   `$before` and `$after` (fairness_metrics objects),
#'   `$accuracy_before` and `$accuracy_after`.
#'
#' @details
#' This implements post-processing threshold adjustment, the simplest
#' and most transparent mitigation strategy. Each group receives its
#' own threshold to equalize the chosen fairness criterion.
#'
#' For clinical applications, group-specific thresholds are
#' interpretable and auditable, unlike in-processing methods that
#' modify the model itself.
#'
#' @references
#' Hardt M, Price E, Srebro N (2016). Equality of Opportunity in
#' Supervised Learning. \emph{NeurIPS}.
#'
#' @examples
#' data(compas_sim)
#' fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
#'                     compas_sim$race)
#' mit <- threshold_optimize(fd)
#' mit
#'
#' @export
threshold_optimize <- function(data,
                               objective = c("equalized_odds",
                                             "demographic_parity"),
                               min_accuracy = 0.5) {
  if (!inherits(data, "fairness_data"))
    cli::cli_abort("{.arg data} must be a {.cls fairness_data} object.")
  objective <- match.arg(objective)

  before <- fairness_metrics(data)
  acc_before <- mean(data$predicted_class == data$labels)

  # Grid search per group
  best_thresholds <- stats::setNames(
    rep(data$threshold, length(data$groups)), data$groups
  )

  grid <- seq(0.05, 0.95, by = 0.05)

  if (objective == "demographic_parity") {
    # Target: overall selection rate
    target_sr <- mean(data$predicted_class)
    for (grp in data$groups) {
      idx <- data$protected == grp
      pred_grp <- data$predictions[idx]
      best_diff <- Inf
      for (th in grid) {
        sr <- mean(pred_grp >= th)
        diff <- abs(sr - target_sr)
        if (diff < best_diff) {
          best_diff <- diff
          best_thresholds[grp] <- th
        }
      }
    }
  } else {
    # equalized_odds: minimize max |TPR_g - TPR_ref| + |FPR_g - FPR_ref|
    ref <- data$reference_group
    ref_idx <- data$protected == ref
    ref_pred <- data$predictions[ref_idx]
    ref_lab <- data$labels[ref_idx]

    # Find ref TPR/FPR at default threshold
    ref_cls <- as.integer(ref_pred >= data$threshold)
    ref_tp <- sum(ref_cls == 1 & ref_lab == 1)
    ref_fn <- sum(ref_cls == 0 & ref_lab == 1)
    ref_fp <- sum(ref_cls == 1 & ref_lab == 0)
    ref_tn <- sum(ref_cls == 0 & ref_lab == 0)
    target_tpr <- if (ref_tp + ref_fn > 0) ref_tp / (ref_tp + ref_fn) else 0.5
    target_fpr <- if (ref_fp + ref_tn > 0) ref_fp / (ref_fp + ref_tn) else 0.5

    for (grp in data$groups) {
      if (grp == ref) next
      idx <- data$protected == grp
      pred_grp <- data$predictions[idx]
      lab_grp <- data$labels[idx]
      best_cost <- Inf
      for (th in grid) {
        cls <- as.integer(pred_grp >= th)
        tp <- sum(cls == 1 & lab_grp == 1)
        fn <- sum(cls == 0 & lab_grp == 1)
        fp <- sum(cls == 1 & lab_grp == 0)
        tn <- sum(cls == 0 & lab_grp == 0)
        tpr <- if (tp + fn > 0) tp / (tp + fn) else 0
        fpr <- if (fp + tn > 0) fp / (fp + tn) else 0
        cost <- abs(tpr - target_tpr) + abs(fpr - target_fpr)
        if (cost < best_cost) {
          best_cost <- cost
          best_thresholds[grp] <- th
        }
      }
    }
  }

  # Apply optimized thresholds
  new_class <- integer(data$n)
  for (grp in data$groups) {
    idx <- data$protected == grp
    new_class[idx] <- as.integer(data$predictions[idx] >= best_thresholds[grp])
  }

  # Build "after" fairness_data with new thresholds
  data_after <- data
  data_after$predicted_class <- new_class
  after <- fairness_metrics(data_after)
  acc_after <- mean(new_class == data$labels)

  out <- list(
    thresholds      = best_thresholds,
    objective       = objective,
    before          = before,
    after           = after,
    accuracy_before = acc_before,
    accuracy_after  = acc_after
  )
  class(out) <- "fairness_mitigation"
  out
}

#' @export
print.fairness_mitigation <- function(x, ...) {
  cli::cli_h3("Threshold optimization ({x$objective})")
  for (g in names(x$thresholds)) {
    cli::cli_text("  {g}: threshold = {x$thresholds[g]}")
  }
  cli::cli_text("")
  cli::cli_text("Accuracy: {round(x$accuracy_before, 3)} -> {round(x$accuracy_after, 3)}")
  invisible(x)
}
