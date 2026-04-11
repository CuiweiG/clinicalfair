# Plot calibration curves by group

Assesses whether predicted probabilities match observed event rates
within each protected group.

## Usage

``` r
plot_calibration(data, n_bins = 10L)
```

## Arguments

- data:

  A
  [fairness_data](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md)
  object.

- n_bins:

  Number of calibration bins. Default 10.

## Value

A ggplot object.

## Examples

``` r
# \donttest{
data(compas_sim)
fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                    compas_sim$race)
plot_calibration(fd)

# }
```
