# clinicalfair 0.1.1

* Initial release.
* `fairness_data()`: Bundle predictions, labels, protected attributes.
* `fairness_metrics()`: Group-wise fairness metrics (selection rate,
  TPR, FPR, PPV, accuracy, AUC, Brier) with optional bootstrap CIs.
* `fairness_report()`: Audit report with four-fifths rule screening.
* `threshold_optimize()`: Group-specific threshold mitigation
  (equalized odds / demographic parity) with configurable grid
  resolution.
* `intersectional_fairness()`: Cross-tabulated multi-attribute
  analysis with small-group filtering.
* `autoplot()`, `plot_roc()`, `plot_calibration()`: Visualization.
* Built-in simulated COMPAS dataset for demonstrations.
