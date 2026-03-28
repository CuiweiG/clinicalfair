#' Plot fairness metrics disparity
#'
#' @param object A `fairness_metrics` object.
#' @param type Plot type: `"disparity"` (default), `"roc"`,
#'   or `"calibration"`.
#' @param ... Additional arguments (unused).
#'
#' @return A ggplot object.
#'
#' @examples
#' \donttest{
#' set.seed(42)
#' fd <- fairness_data(
#'   predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
#'   labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
#'   protected_attr = rep(c("A", "B"), each = 100)
#' )
#' fm <- fairness_metrics(fd)
#' autoplot(fm)
#' }
#'
#' @export
autoplot.fairness_metrics <- function(object,
                                      type = c("disparity", "roc", "calibration"),
                                      ...) {
  type <- match.arg(type)
  switch(type,
    disparity   = .plot_disparity(object),
    roc         = cli::cli_abort("Use {.fn plot_roc} with a {.cls fairness_data} object."),
    calibration = cli::cli_abort("Use {.fn plot_calibration} with a {.cls fairness_data} object.")
  )
}

#' @noRd
.plot_disparity <- function(fm) {
  ref <- attr(fm, "reference_group")

  ggplot2::ggplot(fm, ggplot2::aes(
    x = .data$value, y = .data$group, fill = .data$group
  )) +
    ggplot2::geom_col(alpha = 0.8, width = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.3f", .data$value)),
                       hjust = -0.1, size = 3) +
    ggplot2::facet_wrap(~ .data$metric, scales = "free_x") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.3))) +
    ggplot2::labs(x = "Value", y = NULL, fill = "Group",
                  caption = paste("Reference group:", ref)) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                   strip.text = ggplot2::element_text(face = "bold"))
}

#' Plot ROC curves by group
#'
#' @param data A [fairness_data] object.
#'
#' @return A ggplot object.
#'
#' @examples
#' \donttest{
#' set.seed(42)
#' fd <- fairness_data(
#'   predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
#'   labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
#'   protected_attr = rep(c("A", "B"), each = 100)
#' )
#' plot_roc(fd)
#' }
#'
#' @export
plot_roc <- function(data) {
  if (!inherits(data, "fairness_data"))
    cli::cli_abort("{.arg data} must be a {.cls fairness_data} object.")

  roc_rows <- list()
  for (grp in data$groups) {
    idx <- data$protected == grp
    pred <- data$predictions[idx]
    lab <- data$labels[idx]
    thresholds <- sort(unique(c(0, pred, 1)))
    for (th in thresholds) {
      cls <- as.integer(pred >= th)
      tp <- sum(cls == 1 & lab == 1)
      fp <- sum(cls == 1 & lab == 0)
      fn <- sum(cls == 0 & lab == 1)
      tn <- sum(cls == 0 & lab == 0)
      tpr <- if (tp + fn > 0) tp / (tp + fn) else 0
      fpr <- if (fp + tn > 0) fp / (fp + tn) else 0
      roc_rows <- c(roc_rows, list(tibble::tibble(
        group = grp, fpr = fpr, tpr = tpr
      )))
    }
  }
  roc_df <- dplyr::bind_rows(roc_rows)

  ggplot2::ggplot(roc_df, ggplot2::aes(
    x = .data$fpr, y = .data$tpr, colour = .data$group
  )) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_abline(linetype = "dashed", colour = "gray50") +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "False Positive Rate", y = "True Positive Rate",
                  colour = "Group") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")
}

#' Generate a fairness summary report
#'
#' @param data A [fairness_data] object.
#' @param metrics A [fairness_metrics] object. If `NULL`, computed
#'   automatically.
#'
#' @return A `fairness_report` (list) with `$summary`, `$flags`,
#'   `$recommendation`.
#'
#' @examples
#' set.seed(42)
#' fd <- fairness_data(
#'   predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
#'   labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
#'   protected_attr = rep(c("A", "B"), each = 100)
#' )
#' fairness_report(fd)
#'
#' @export
fairness_report <- function(data, metrics = NULL) {
  if (is.null(metrics)) metrics <- fairness_metrics(data)
  ref <- attr(metrics, "reference_group")

  # Flag metrics violating four-fifths rule
  non_ref <- metrics[metrics$group != ref, ]
  flags <- non_ref[!is.na(non_ref$ratio) &
                     (non_ref$ratio < 0.8 | non_ref$ratio > 1.25), ]

  n_flags <- nrow(flags)
  rec <- if (n_flags == 0) {
    "No fairness violations detected under the four-fifths rule."
  } else {
    paste0(n_flags, " metric(s) violate the four-fifths rule (ratio outside [0.8, 1.25]). ",
           "Consider threshold adjustment or model recalibration.")
  }

  out <- list(
    summary = metrics,
    flags   = flags,
    recommendation = rec,
    reference_group = ref
  )
  class(out) <- "fairness_report"
  out
}

#' @export
print.fairness_report <- function(x, ...) {
  cli::cli_h3("Fairness Report")
  cli::cli_text("Reference group: {.val {x$reference_group}}")
  cli::cli_text("")
  if (nrow(x$flags) > 0) {
    cli::cli_alert_warning("{nrow(x$flags)} disparity flag(s):")
    for (i in seq_len(nrow(x$flags))) {
      f <- x$flags[i, ]
      cli::cli_text("  {f$group} / {f$metric}: ratio = {round(f$ratio, 3)}")
    }
  } else {
    cli::cli_alert_success("No disparities flagged (four-fifths rule).")
  }
  cli::cli_text("")
  cli::cli_text(x$recommendation)
  invisible(x)
}
