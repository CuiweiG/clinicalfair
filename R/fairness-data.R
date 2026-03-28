#' Create a fairness evaluation data object
#'
#' Bundles predictions, labels, and protected attributes into a
#' standardized container for fairness analysis.
#'
#' @param predictions Numeric vector of predicted probabilities or
#'   risk scores (between 0 and 1).
#' @param labels Binary integer vector of true outcomes (0 or 1).
#' @param protected_attr Character or factor vector identifying the
#'   protected group membership (e.g., race, sex, age group).
#' @param threshold Decision threshold for converting probabilities
#'   to binary predictions. Default 0.5.
#' @param reference_group Name of the reference (privileged) group.
#'   If `NULL`, the group with the highest selection rate is used.
#'
#' @return A `fairness_data` object (list) with standardized components:
#'   `predictions`, `labels`, `protected`, `threshold`, `predicted_class`,
#'   `reference_group`, `groups`, `n`, `prevalence`.
#'
#' @examples
#' set.seed(42)
#' fd <- fairness_data(
#'   predictions = runif(200),
#'   labels = rbinom(200, 1, 0.3),
#'   protected_attr = sample(c("GroupA", "GroupB"), 200, replace = TRUE)
#' )
#' fd
#'
#' @export
fairness_data <- function(predictions, labels, protected_attr,
                          threshold = 0.5, reference_group = NULL) {

  if (!is.numeric(predictions))
    cli::cli_abort("{.arg predictions} must be numeric.")
  if (!all(labels %in% c(0L, 1L, 0, 1)))
    cli::cli_abort("{.arg labels} must be binary (0/1).")
  n <- length(predictions)
  if (length(labels) != n || length(protected_attr) != n)
    cli::cli_abort("All inputs must have the same length ({n}).")
  if (any(is.na(predictions) | is.na(labels) | is.na(protected_attr)))
    cli::cli_abort("NA values not allowed. Remove or impute first.")

  protected <- as.character(protected_attr)
  groups <- sort(unique(protected))
  if (length(groups) < 2)
    cli::cli_abort("Need at least 2 groups. Found {length(groups)}.")

  predicted_class <- as.integer(predictions >= threshold)

  # Auto-select reference: group with highest selection rate
  if (is.null(reference_group)) {
    sel_rates <- tapply(predicted_class, protected, mean)
    reference_group <- names(which.max(sel_rates))
  }
  if (!reference_group %in% groups)
    cli::cli_abort("Reference group {.val {reference_group}} not found.")

  structure(
    list(
      predictions     = predictions,
      labels          = as.integer(labels),
      protected       = protected,
      threshold       = threshold,
      predicted_class = predicted_class,
      reference_group = reference_group,
      groups          = groups,
      n               = n,
      prevalence      = mean(labels)
    ),
    class = "fairness_data"
  )
}

#' @export
print.fairness_data <- function(x, ...) {
  cli::cli_h3("Fairness evaluation data")
  cli::cli_text("n = {x$n} | prevalence = {round(x$prevalence, 3)}")
  cli::cli_text("Groups: {.val {paste(x$groups, collapse = ', ')}}")
  cli::cli_text("Reference: {.val {x$reference_group}} | Threshold: {x$threshold}")
  invisible(x)
}
