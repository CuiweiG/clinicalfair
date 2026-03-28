# clinicalfair

<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![R â‰?4.1.0](https://img.shields.io/badge/R-%E2%89%A5%204.1.0-brightgreen.svg)](https://cran.r-project.org/)
<!-- badges: end -->

Algorithmic fairness assessment for clinical prediction models.

## Installation

```r
devtools::install_github("CuiweiG/clinicalfair")
```

## Quick example

```r
library(clinicalfair)
data(compas_sim)

fd <- fairness_data(
  predictions    = compas_sim$risk_score,
  labels         = compas_sim$recidivism,
  protected_attr = compas_sim$race
)

fairness_metrics(fd)
fairness_report(fd)
threshold_optimize(fd, objective = "equalized_odds")
```

## Features

**Metrics**: demographic parity, equalized odds, predictive parity,
calibration, AUC, Brier score â€?with ratio and difference vs reference.

**Visualization**: `autoplot()` disparity plots, `plot_roc()` by group,
`plot_calibration()` by group.

**Mitigation**: `threshold_optimize()` for group-specific thresholds
(equalized odds or demographic parity).

**Intersectional**: `intersectional_fairness()` for race Ã— sex Ã— age
cross-tabulated analysis.

**Reporting**: `fairness_report()` with four-fifths rule violation
detection and actionable recommendations.

## References

- Obermeyer et al. (2019) *Science* doi:10.1126/science.aax2342
- Hardt et al. (2016) *NeurIPS* â€?Equality of Opportunity
- FDA AI/ML Action Plan (2024)

## License

MIT

