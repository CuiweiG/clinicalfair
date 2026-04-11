# Changelog

## clinicalfair 0.1.1

- Initial release.
- [`fairness_data()`](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md):
  Bundle predictions, labels, protected attributes.
- [`fairness_metrics()`](https://cuiweig.github.io/clinicalfair/reference/fairness_metrics.md):
  Group-wise fairness metrics (selection rate, TPR, FPR, PPV, accuracy,
  AUC, Brier) with optional bootstrap CIs.
- [`fairness_report()`](https://cuiweig.github.io/clinicalfair/reference/fairness_report.md):
  Audit report with four-fifths rule screening.
- [`threshold_optimize()`](https://cuiweig.github.io/clinicalfair/reference/threshold_optimize.md):
  Group-specific threshold mitigation (equalized odds / demographic
  parity) with configurable grid resolution.
- [`intersectional_fairness()`](https://cuiweig.github.io/clinicalfair/reference/intersectional_fairness.md):
  Cross-tabulated multi-attribute analysis with small-group filtering.
- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html),
  [`plot_roc()`](https://cuiweig.github.io/clinicalfair/reference/plot_roc.md),
  [`plot_calibration()`](https://cuiweig.github.io/clinicalfair/reference/plot_calibration.md):
  Visualization.
- Built-in simulated COMPAS dataset for demonstrations.
