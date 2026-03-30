#' Plot calibration curves by group
#'
#' Assesses whether predicted probabilities match observed event
#' rates within each protected group.
#'
#' @param data A [fairness_data] object.
#' @param n_bins Number of calibration bins. Default 10.
#'
#' @return A ggplot object.
#'
#' @examples
#' \donttest{
#' data(compas_sim)
#' fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
#'                     compas_sim$race)
#' plot_calibration(fd)
#' }
#'
#' @export
plot_calibration <- function(data, n_bins = 10L) {
  if (!inherits(data, "fairness_data"))
    cli::cli_abort("{.arg data} must be a {.cls fairness_data} object.")

  rows <- list()
  for (grp in data$groups) {
    idx <- data$protected == grp
    pred <- data$predictions[idx]
    lab  <- data$labels[idx]
    breaks <- seq(0, 1, length.out = n_bins + 1L)
    bins <- cut(pred, breaks, include.lowest = TRUE)
    for (b in levels(bins)) {
      b_idx <- bins == b
      if (sum(b_idx) < 2) next
      rows <- c(rows, list(tibble::tibble(
        group         = grp,
        bin_mid       = mean(pred[b_idx]),
        observed_rate = mean(lab[b_idx]),
        n             = sum(b_idx)
      )))
    }
  }
  cal_df <- dplyr::bind_rows(rows)

  ggplot2::ggplot(cal_df, ggplot2::aes(
    x = .data$bin_mid, y = .data$observed_rate, colour = .data$group
  )) +
    ggplot2::geom_abline(linetype = "dashed", colour = "gray50") +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(ggplot2::aes(size = .data$n), alpha = 0.7) +
    ggplot2::scale_size_continuous(range = c(1, 5), guide = "none") +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(x = "Predicted probability", y = "Observed rate",
                  colour = "Group") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")
}


#' Compute intersectional fairness metrics
#'
#' Evaluates fairness across combinations of multiple protected
#' attributes (e.g., race x sex), revealing disparities hidden by
#' single-attribute analysis.
#'
#' @param predictions Numeric vector of predicted probabilities.
#' @param labels Binary integer vector of true outcomes.
#' @param ... Two or more named vectors of protected attributes.
#'   Names become the attribute labels.
#' @param threshold Decision threshold. Default 0.5.
#' @param min_group_size Minimum number of observations required per
#'   intersectional group. Groups below this threshold are dropped
#'   with a warning. Default 10.
#'
#' @return A `fairness_metrics` object with intersectional groups.
#'   Groups with fewer than `min_group_size` observations are excluded.
#'
#' @references
#' Buolamwini J, Gebru T (2018). Gender Shades: Intersectional
#' Accuracy Disparities in Commercial Gender Classification.
#' \emph{Conference on Fairness, Accountability and Transparency}.
#'
#' @examples
#' set.seed(42)
#' n <- 400
#' intersectional_fairness(
#'   predictions = runif(n),
#'   labels = rbinom(n, 1, 0.3),
#'   race = sample(c("White", "Black"), n, replace = TRUE),
#'   sex = sample(c("Male", "Female"), n, replace = TRUE)
#' )
#'
#' @export
intersectional_fairness <- function(predictions, labels, ...,
                                    threshold = 0.5,
                                    min_group_size = 10L) {
  attrs <- list(...)
  if (length(attrs) < 2)
    cli::cli_abort("Provide at least 2 protected attributes.")

  # Create intersectional group labels
  combined <- do.call(paste, c(attrs, sep = " x "))

  # Check group sizes and filter small groups
  group_counts <- table(combined)
  small_groups <- names(group_counts[group_counts < min_group_size])

  if (length(small_groups) > 0) {
    keep <- !combined %in% small_groups
    n_dropped <- sum(!keep)
    cli::cli_warn(c(
      "Dropping {length(small_groups)} group(s) with fewer than \\
       {min_group_size} observations ({n_dropped} obs removed):",
      "*" = "{.val {small_groups}}"
    ))
    predictions <- predictions[keep]
    labels <- labels[keep]
    combined <- combined[keep]
  }

  remaining_groups <- length(unique(combined))
  if (remaining_groups < 2)
    cli::cli_abort(paste0(
      "After filtering small groups, only {remaining_groups} group(s) remain. ",
      "Need at least 2. Lower {.arg min_group_size} or provide more data."))

  fd <- fairness_data(predictions, labels, combined,
                      threshold = threshold)
  fairness_metrics(fd)
}
