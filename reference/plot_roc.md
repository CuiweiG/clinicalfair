# Plot ROC curves by group

Plot ROC curves by group

## Usage

``` r
plot_roc(data)
```

## Arguments

- data:

  A
  [fairness_data](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md)
  object.

## Value

A ggplot object.

## Examples

``` r
# \donttest{
set.seed(42)
fd <- fairness_data(
  predictions = c(runif(100, 0.2, 0.8), runif(100, 0.3, 0.9)),
  labels = c(rbinom(100, 1, 0.3), rbinom(100, 1, 0.5)),
  protected_attr = rep(c("A", "B"), each = 100)
)
plot_roc(fd)

# }
```
