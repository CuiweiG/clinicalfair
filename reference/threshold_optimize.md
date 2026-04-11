# Optimize thresholds for fairness

Finds group-specific decision thresholds that maximize accuracy subject
to a fairness constraint, or minimize disparity subject to a minimum
accuracy constraint.

## Usage

``` r
threshold_optimize(
  data,
  objective = c("equalized_odds", "demographic_parity"),
  min_accuracy = 0.5,
  grid_resolution = 0.01
)
```

## Arguments

- data:

  A
  [fairness_data](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md)
  object.

- objective:

  `"equalized_odds"` (default): minimize TPR/FPR disparity across all
  groups. `"demographic_parity"`: equalize selection rates.

- min_accuracy:

  Minimum acceptable overall accuracy. Default 0.5.

- grid_resolution:

  Step size for the threshold grid search. Default 0.01 (99 candidate
  thresholds). Smaller values give finer-grained optimization at modest
  computational cost.

## Value

A `fairness_mitigation` object (list) with: `$thresholds` (named
numeric, one per group), `$before` and `$after` (fairness_metrics
objects), `$accuracy_before` and `$accuracy_after`.

## Details

This implements post-processing threshold adjustment, the simplest and
most transparent mitigation strategy. Each group receives its own
threshold to equalize the chosen fairness criterion.

For `"equalized_odds"`, the algorithm computes a pooled target TPR and
FPR across all groups at the original threshold, then optimizes every
group (including the reference) to match the pooled target. This avoids
the asymmetry of fixing the reference group threshold while only
adjusting others.

For clinical applications, group-specific thresholds are interpretable
and auditable, unlike in-processing methods that modify the model
itself.

## References

Hardt M, Price E, Srebro N (2016). Equality of Opportunity in Supervised
Learning. *NeurIPS*.

## Examples

``` r
data(compas_sim)
fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                    compas_sim$race)
mit <- threshold_optimize(fd)
mit
#> 
#> ── Threshold optimization (equalized_odds) 
#> Black: threshold = 0.58
#> White: threshold = 0.42
#> 
#> Accuracy: 0.794 -> 0.808
```
