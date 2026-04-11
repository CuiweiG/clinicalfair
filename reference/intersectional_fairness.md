# Compute intersectional fairness metrics

Evaluates fairness across combinations of multiple protected attributes
(e.g., race x sex), revealing disparities hidden by single-attribute
analysis.

## Usage

``` r
intersectional_fairness(
  predictions,
  labels,
  ...,
  threshold = 0.5,
  min_group_size = 10L
)
```

## Arguments

- predictions:

  Numeric vector of predicted probabilities.

- labels:

  Binary integer vector of true outcomes.

- ...:

  Two or more named vectors of protected attributes. Names become the
  attribute labels.

- threshold:

  Decision threshold. Default 0.5.

- min_group_size:

  Minimum number of observations required per intersectional group.
  Groups below this threshold are dropped with a warning. Default 10.

## Value

A `fairness_metrics` object with intersectional groups. Groups with
fewer than `min_group_size` observations are excluded.

## References

Buolamwini J, Gebru T (2018). Gender Shades: Intersectional Accuracy
Disparities in Commercial Gender Classification. *Conference on
Fairness, Accountability and Transparency*.

## Examples

``` r
set.seed(42)
n <- 400
intersectional_fairness(
  predictions = runif(n),
  labels = rbinom(n, 1, 0.3),
  race = sample(c("White", "Black"), n, replace = TRUE),
  sex = sample(c("Male", "Female"), n, replace = TRUE)
)
#> 
#> ── Fairness metrics (reference: White x Male) 
#> # A tibble: 28 × 5
#>    group          metric         value ratio difference
#>  * <chr>          <chr>          <dbl> <dbl>      <dbl>
#>  1 Black x Female selection_rate 0.463 0.896   -0.0537 
#>  2 Black x Female tpr            0.391 1.04     0.0163 
#>  3 Black x Female fpr            0.486 0.854   -0.0831 
#>  4 Black x Female ppv            0.205 1.05     0.00889
#>  5 Black x Female accuracy       0.484 1.16     0.0685 
#>  6 Black x Female brier          0.350 1.03     0.0115 
#>  7 Black x Female auc            0.418 0.887   -0.0533 
#>  8 Black x Male   selection_rate 0.422 0.817   -0.0948 
#>  9 Black x Male   tpr            0.419 1.12     0.0444 
#> 10 Black x Male   fpr            0.423 0.743   -0.146  
#> # ℹ 18 more rows
```
