# Create a fairness evaluation data object

Bundles predictions, labels, and protected attributes into a
standardized container for fairness analysis.

## Usage

``` r
fairness_data(
  predictions,
  labels,
  protected_attr,
  threshold = 0.5,
  reference_group = NULL
)
```

## Arguments

- predictions:

  Numeric vector of predicted probabilities or risk scores (between 0
  and 1).

- labels:

  Binary integer vector of true outcomes (0 or 1).

- protected_attr:

  Character or factor vector identifying the protected group membership
  (e.g., race, sex, age group).

- threshold:

  Decision threshold for converting probabilities to binary predictions.
  Default 0.5.

- reference_group:

  Name of the reference (privileged) group. If `NULL`, the group with
  the highest selection rate is used.

## Value

A `fairness_data` object (list) with standardized components:
`predictions`, `labels`, `protected`, `threshold`, `predicted_class`,
`reference_group`, `groups`, `n`, `prevalence`.

## Examples

``` r
set.seed(42)
fd <- fairness_data(
  predictions = runif(200),
  labels = rbinom(200, 1, 0.3),
  protected_attr = sample(c("GroupA", "GroupB"), 200, replace = TRUE)
)
fd
#> 
#> ── Fairness evaluation data 
#> n = 200 | prevalence = 0.265
#> Groups: "GroupA, GroupB"
#> Reference: "GroupB" | Threshold: 0.5
```
