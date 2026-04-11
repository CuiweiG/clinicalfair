# Generate a fairness summary report

Generate a fairness summary report

## Usage

``` r
fairness_report(data, metrics = NULL)
```

## Arguments

- data:

  A
  [fairness_data](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md)
  object.

- metrics:

  A
  [fairness_metrics](https://cuiweig.github.io/clinicalfair/reference/fairness_metrics.md)
  object. If `NULL`, computed automatically.

## Value

A `fairness_report` (list) with `$summary`, `$flags`, `$recommendation`.

## Examples

``` r
set.seed(42)
fd <- fairness_data(
  predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
  labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
  protected_attr = rep(c("A", "B"), each = 100)
)
fairness_report(fd)
#> 
#> ── Fairness Report 
#> Reference group: "B"
#> 
#> ! 3 disparity flag(s):
#> A / selection_rate: ratio = 0.797
#> A / fpr: ratio = 0.757
#> A / ppv: ratio = 0.567
#> 
#> 3 metric(s) violate the four-fifths rule (ratio outside [0.8, 1.25]). Consider
#> threshold adjustment or model recalibration.
```
