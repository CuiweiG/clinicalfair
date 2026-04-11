# Simulated COMPAS-like recidivism prediction data

A simulated dataset reflecting the documented racial disparities in
recidivism prediction algorithms, based on published statistics from the
ProPublica investigation (Angwin et al. 2016).

## Usage

``` r
compas_sim
```

## Format

A data frame with 1000 rows and 3 columns:

- risk_score:

  Predicted recidivism risk (numeric, 0–1).

- recidivism:

  Actual recidivism outcome (binary, 0/1).

- race:

  Racial group: White or Black (character).

## Source

Simulated. Based on patterns from Angwin et al. (2016) "Machine Bias"
and Obermeyer et al. (2019)
[doi:10.1126/science.aax2342](https://doi.org/10.1126/science.aax2342) .

## Examples

``` r
data(compas_sim)
fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                    compas_sim$race)
fairness_metrics(fd)
#> 
#> ── Fairness metrics (reference: Black) 
#> # A tibble: 14 × 5
#>    group metric          value ratio difference
#>  * <chr> <chr>           <dbl> <dbl>      <dbl>
#>  1 Black selection_rate 0.571  1        0      
#>  2 Black tpr            0.902  1        0      
#>  3 Black fpr            0.276  1        0      
#>  4 Black ppv            0.744  1        0      
#>  5 Black accuracy       0.808  1        0      
#>  6 Black brier          0.152  1        0      
#>  7 Black auc            0.901  1        0      
#>  8 White selection_rate 0.291  0.510   -0.280  
#>  9 White tpr            0.573  0.635   -0.329  
#> 10 White fpr            0.0724 0.262   -0.204  
#> 11 White ppv            0.860  1.16     0.116  
#> 12 White accuracy       0.773  0.957   -0.0346 
#> 13 White brier          0.156  1.03     0.00381
#> 14 White auc            0.887  0.984   -0.0148 
```
