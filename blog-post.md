# Auditing Clinical Prediction Models for Fairness: An R Toolkit Aligned with FDA Expectations

The FDA’s 2021 Action Plan for AI/ML-Based Software as a Medical Device
made one thing clear: developers of clinical prediction models will be
expected to demonstrate that their algorithms perform equitably across
patient subgroups. The agency did not prescribe specific fairness
metrics or thresholds, but the direction of travel is unmistakable —
transparency about differential performance across demographic groups is
becoming a regulatory expectation, not merely an academic aspiration.

For the biostatistician or clinical informaticist tasked with conducting
such an audit, the practical question is immediate: given a trained
prediction model and a labelled evaluation cohort, how do you
systematically assess whether the model’s error rates, calibration, and
selection behaviour differ across protected groups? And if disparities
exist, what are the available post-hoc remediation options that preserve
model interpretability?

`clinicalfair` is an R package, now on CRAN, designed to answer these
questions. It provides a model-agnostic fairness auditing workflow that
takes predicted probabilities, true labels, and protected attributes as
inputs and returns group-stratified metrics, regulatory flag detection,
visualisations, and threshold-based mitigation — all without modifying
the underlying model.

## The Audit Workflow

The entry point is
[`fairness_data()`](https://cuiweig.github.io/clinicalfair/reference/fairness_data.md),
which bundles predictions, outcomes, and group membership into a
validated container:

``` r
library(clinicalfair)
data(compas_sim)

fd <- fairness_data(
  predictions = compas_sim$risk_score,
  labels      = compas_sim$recidivism,
  protected_attr = compas_sim$race
)
```

The reference group — against which all disparity ratios are computed —
is selected automatically as the group with the highest selection rate,
following the convention that disparities are measured relative to the
most-selected group. This default can be overridden.

[`fairness_metrics()`](https://cuiweig.github.io/clinicalfair/reference/fairness_metrics.md)
computes group-wise performance across seven metrics:

``` r
fm <- fairness_metrics(fd, ci = TRUE, n_boot = 2000)
```

The metrics span the major fairness criteria in the literature:
selection rate (demographic parity), true positive rate and false
positive rate (equalised odds, per Hardt, Price, and Srebro 2016),
positive predictive value (predictive parity), AUC, accuracy, and Brier
score. Bootstrap confidence intervals, when requested, use percentile
resampling within each group independently.

Each metric is reported alongside its ratio and absolute difference
relative to the reference group — the two quantities that matter for
regulatory assessment.

## Flagging Violations

[`fairness_report()`](https://cuiweig.github.io/clinicalfair/reference/fairness_report.md)
automates detection of disparities that exceed the four-fifths rule
threshold (ratio below 0.8 or above 1.25), a standard borrowed from
employment discrimination law (EEOC Uniform Guidelines) and increasingly
referenced in algorithmic fairness contexts:

``` r
rpt <- fairness_report(fd)
rpt
```

The report object contains flagged metrics, a narrative recommendation,
and the full metrics table. For teams preparing regulatory submissions
or hospital committee presentations, this structured output reduces the
gap between statistical computation and actionable reporting.

## Visualising Disparities

Three visualisation functions expose different dimensions of
differential performance:

``` r
autoplot(fm)           # Disparity bar plots, faceted by metric
plot_roc(fd)           # ROC curves stratified by group
plot_calibration(fd)   # Decile calibration curves by group
```

The calibration plot deserves particular attention. Obermeyer et
al. (2019) demonstrated in *Science* that a widely deployed healthcare
algorithm exhibited severe calibration disparities across racial groups
— at the same predicted risk score, Black patients were substantially
sicker than White patients. Differential calibration is arguably the
most clinically consequential form of algorithmic unfairness, and the
decile calibration plot makes it immediately visible.

## Intersectional Analysis

Single-attribute fairness analysis can mask disparities that emerge only
at the intersection of multiple protected characteristics. A model may
appear fair with respect to race and fair with respect to sex, yet
exhibit significant disparities for Black women specifically.
[`intersectional_fairness()`](https://cuiweig.github.io/clinicalfair/reference/intersectional_fairness.md)
addresses this directly:

``` r
isf <- intersectional_fairness(
  predictions = compas_sim$risk_score,
  labels      = compas_sim$recidivism,
  race        = compas_sim$race,
  sex         = sample(c("Male", "Female"), nrow(compas_sim), replace = TRUE),
  min_group_size = 30
)
```

Groups below the minimum size threshold are dropped with a warning,
preventing unstable estimates from small cells. This follows the
methodological guidance of Buolamwini and Gebru (2018), whose Gender
Shades study established intersectional evaluation as a standard in
algorithmic fairness.

## Post-Hoc Mitigation

When disparities are identified,
[`threshold_optimize()`](https://cuiweig.github.io/clinicalfair/reference/threshold_optimize.md)
searches for group-specific decision thresholds that minimise disparity
while maintaining an accuracy floor:

``` r
mit <- threshold_optimize(fd, objective = "equalized_odds", min_accuracy = 0.60)
mit
```

The function supports two objectives: equalised odds (minimising TPR and
FPR disparity) and demographic parity (equalising selection rates). The
optimisation uses a grid search over candidate thresholds, with the
accuracy constraint ensuring that mitigation does not degrade overall
model performance below a clinically acceptable level.

Group-specific thresholds are transparent and auditable. Unlike
in-processing fairness methods that modify model training, threshold
adjustment leaves the model itself untouched — a property that matters
in regulated environments where model modifications may trigger
re-validation requirements.

## Design Decisions

Several deliberate choices shape the package. First, `clinicalfair` is
strictly post-hoc: it evaluates models, not training procedures. This
reflects the reality that fairness audits are most often conducted by
teams who receive a trained model and must assess it, not by the teams
who built it. Second, the package is model-agnostic — it operates on
predicted probabilities, not on model internals. A risk score from a
logistic regression, a random forest, or a neural network is handled
identically. Third, all metrics and thresholds are returned as
structured data (tibbles), not buried in console output, enabling
programmatic integration into reporting pipelines.

## Limitations and Scope

Threshold-based mitigation is a blunt instrument. It addresses
disparities in classification decisions but cannot correct a model whose
learned representations are fundamentally biased. Pre-processing
(rebalancing training data) and in-processing (constrained optimisation
during training) approaches may be necessary for models with deep
structural unfairness. `clinicalfair` does not implement these — its
scope is the audit, not the redesign.

The four-fifths rule, while widely used, is not universally accepted as
the appropriate threshold for clinical applications. Some fairness
scholars argue for stricter standards in healthcare contexts where the
stakes are higher than employment decisions. The threshold is
configurable in the report internals, but users should consider whether
80% is the right bar for their specific clinical domain.

## Getting Started

``` r
install.packages("clinicalfair")
```

The included `compas_sim` dataset provides a ready-made example for
exploring the full workflow. Documentation and source code are available
on [GitHub](https://github.com/CuiweiG/clinicalfair).

As clinical AI systems move from research prototypes to deployed medical
devices, fairness auditing will transition from a best practice to a
regulatory requirement. Having a standardised, reproducible toolkit for
conducting these audits — one that produces output suitable for
regulatory review — is a prerequisite, not an optional enhancement.

------------------------------------------------------------------------

*Cuiwei Gao is a health data analyst and R developer. `clinicalfair` is
available on [CRAN](https://CRAN.R-project.org/package=clinicalfair).*
