# Compute fairness metrics across groups

Calculates a comprehensive set of group-wise and comparative fairness
metrics from a `fairness_data` object, with optional bootstrap
confidence intervals.

## Usage

``` r
fairness_metrics(
  data,
  metrics = c("selection_rate", "tpr", "fpr", "ppv", "accuracy", "auc", "brier"),
  ci = FALSE,
  n_boot = 2000L,
  ci_level = 0.95
)
```

## Arguments

- data:

  A
  [fairness_data](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md)
  object.

- metrics:

  Character vector of metrics to compute. Default computes all available
  metrics. Options: `"selection_rate"`, `"tpr"`, `"fpr"`, `"ppv"`,
  `"accuracy"`, `"auc"`, `"brier"`.

- ci:

  Logical; if `TRUE`, compute bootstrap confidence intervals for each
  metric. Default `FALSE`.

- n_boot:

  Number of bootstrap replicates when `ci = TRUE`. Default 2000.

- ci_level:

  Confidence level for the interval. Default 0.95.

## Value

A `fairness_metrics` object (tibble) with columns: `group`, `metric`,
`value`, `ratio` (vs reference group), `difference` (vs reference
group). When `ci = TRUE`, additional columns `ci_lower` and `ci_upper`
are included.

## Details

Fairness is assessed by comparing metric values across groups. A ratio
of 1.0 or difference of 0.0 indicates perfect parity. Common thresholds:
ratio in \\\[0.8, 1.25\]\\ (four-fifths rule, EEOC guidelines) or
difference \< 0.05.

When `ci = TRUE`, percentile bootstrap confidence intervals are computed
by resampling within each group. This accounts for sampling variability
and is recommended when reporting fairness metrics for regulatory or
publication purposes.

## References

Obermeyer Z, et al. (2019). Dissecting racial bias in an algorithm used
to manage the health of populations. *Science*, 366(6464):447–453.
[doi:10.1126/science.aax2342](https://doi.org/10.1126/science.aax2342)

## Examples

``` r
set.seed(42)
fd <- fairness_data(
  predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
  labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
  protected_attr = rep(c("A", "B"), each = 100)
)
fairness_metrics(fd)
#> 
#> ── Fairness metrics (reference: B) 
#> # A tibble: 14 × 5
#>    group metric         value ratio difference
#>  * <chr> <chr>          <dbl> <dbl>      <dbl>
#>  1 A     selection_rate 0.55  0.797  -0.140   
#>  2 A     tpr            0.609 0.903  -0.0652  
#>  3 A     fpr            0.532 0.757  -0.171   
#>  4 A     ppv            0.255 0.567  -0.195   
#>  5 A     accuracy       0.5   1.06    0.0300  
#>  6 A     brier          0.294 1.00    0.000532
#>  7 A     auc            0.479 0.904  -0.0508  
#>  8 B     selection_rate 0.69  1       0       
#>  9 B     tpr            0.674 1       0       
#> 10 B     fpr            0.704 1       0       
#> 11 B     ppv            0.449 1       0       
#> 12 B     accuracy       0.47  1       0       
#> 13 B     brier          0.294 1       0       
#> 14 B     auc            0.530 1       0       

# With bootstrap CIs
fairness_metrics(fd, ci = TRUE, n_boot = 500)
#> 
#> ── Fairness metrics (reference: B) 
#> # A tibble: 14 × 7
#>    group metric         value ci_lower ci_upper ratio difference
#>  * <chr> <chr>          <dbl>    <dbl>    <dbl> <dbl>      <dbl>
#>  1 A     selection_rate 0.55     0.45     0.64  0.797  -0.140   
#>  2 A     tpr            0.609    0.366    0.8   0.903  -0.0652  
#>  3 A     fpr            0.532    0.424    0.638 0.757  -0.171   
#>  4 A     ppv            0.255    0.130    0.371 0.567  -0.195   
#>  5 A     accuracy       0.5      0.4      0.6   1.06    0.0300  
#>  6 A     brier          0.294    0.259    0.331 1.00    0.000532
#>  7 A     auc            0.479    0.332    0.604 0.904  -0.0508  
#>  8 B     selection_rate 0.69     0.59     0.78  1       0       
#>  9 B     tpr            0.674    0.542    0.809 1       0       
#> 10 B     fpr            0.704    0.577    0.816 1       0       
#> 11 B     ppv            0.449    0.343    0.567 1       0       
#> 12 B     accuracy       0.47     0.375    0.57  1       0       
#> 13 B     brier          0.294    0.254    0.331 1       0       
#> 14 B     auc            0.530    0.412    0.642 1       0       
```
