# Summary

`clinicalfair` is an R package for post-hoc fairness assessment of
clinical prediction models. Given predicted probabilities, true
outcomes, and protected group membership, the package computes
group-stratified performance metrics with bootstrap confidence
intervals, detects violations of the four-fifths rule, visualises
disparities through calibration curves and ROC plots stratified by
group, conducts intersectional analysis across combinations of protected
attributes, and performs threshold-based mitigation to equalise error
rates without modifying the underlying model. The package is
model-agnostic and designed for regulatory auditing workflows aligned
with FDA guidance on AI/ML-based medical devices.

# Statement of Need

As machine learning models are increasingly deployed in clinical
decision support — from sepsis prediction to readmission risk scoring —
the question of whether these models perform equitably across patient
subgroups has moved from academic concern to regulatory expectation. The
FDA’s 2021 Action Plan for AI/ML-Based Software as a Medical Device
explicitly identified algorithm bias and fairness as areas requiring
transparency and monitoring \[@fda2021action\]. The European AI Act
imposes analogous requirements for high-risk AI systems deployed in
healthcare.

Documented cases of algorithmic unfairness in healthcare underscore the
urgency. Obermeyer et al. demonstrated in *Science* that a widely
deployed healthcare resource allocation algorithm exhibited substantial
racial bias: at equivalent predicted risk scores, Black patients were
significantly sicker than White patients, resulting in differential
access to care programmes \[@obermeyer2019dissecting\]. The ProPublica
investigation of the COMPAS recidivism algorithm revealed analogous
disparities in criminal justice risk prediction \[@angwin2016machine\].

Existing R packages address aspects of algorithmic fairness.
`fairmodels` provides model-agnostic fairness diagnostics and
mitigation. `fairness` computes group-level metrics. `fairmetrics`
offers a set of standard fairness measures. However, none of these
packages are specifically designed for the clinical audit use case,
which requires: (1) bootstrap confidence intervals suitable for
regulatory reporting, (2) intersectional analysis across multiple
protected attributes, (3) four-fifths rule violation detection aligned
with established legal standards, and (4) threshold-based mitigation
that preserves model interpretability — a property that matters in
regulated environments where model modifications may trigger
re-validation requirements.

`clinicalfair` is built around this clinical audit workflow. It accepts
any set of predicted probabilities — the auditor need not have access to
model internals, training data, or model architecture — and produces
structured output suitable for regulatory submissions, hospital
committee presentations, and peer-reviewed publications.

# Key Features

## Fairness Metrics with Confidence Intervals

[`fairness_metrics()`](https://cuiweig.github.io/clinicalfair/reference/fairness_metrics.md)
computes seven group-stratified metrics: selection rate, true positive
rate, false positive rate, positive predictive value, accuracy, AUC (via
Wilcoxon–Mann–Whitney statistic), and Brier score. Each metric is
accompanied by its ratio and absolute difference relative to a reference
group. Optional percentile bootstrap confidence intervals (configurable
number of resamples and confidence level) provide the uncertainty
quantification needed for formal reporting.

## Four-Fifths Rule Detection

[`fairness_report()`](https://cuiweig.github.io/clinicalfair/reference/fairness_report.md)
automates identification of metrics violating the four-fifths rule — a
threshold originating in the EEOC Uniform Guidelines on Employee
Selection Procedures and increasingly adopted in algorithmic fairness
contexts. Metrics with group-to-reference ratios below 0.8 or above 1.25
are flagged, and a narrative recommendation is generated.

## Intersectional Analysis

[`intersectional_fairness()`](https://cuiweig.github.io/clinicalfair/reference/intersectional_fairness.md)
evaluates model performance across combinations of multiple protected
attributes (e.g., race, sex, and age group simultaneously).
Intersectional groups below a configurable minimum size are excluded to
prevent unstable estimates. This capability implements the
methodological recommendations of Buolamwini and Gebru, whose Gender
Shades study established that single-attribute fairness analysis can
mask disparities emerging at attribute intersections
\[@buolamwini2018gender\].

## Threshold Optimisation

[`threshold_optimize()`](https://cuiweig.github.io/clinicalfair/reference/threshold_optimize.md)
performs group-specific threshold adjustment to minimise disparity in
either equalised odds (TPR and FPR parity, following @hardt2016equality)
or demographic parity (selection rate equalisation). The optimisation
respects a user-specified minimum accuracy constraint, ensuring that
mitigation does not degrade overall model performance below a clinically
acceptable level. Critically, this approach leaves the model untouched —
only decision thresholds change — preserving regulatory traceability.

## Visualisation

Three visualisation functions target different dimensions of
differential performance:
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
for faceted disparity bar plots,
[`plot_roc()`](https://cuiweig.github.io/clinicalfair/reference/plot_roc.md)
for group-stratified ROC curves, and
[`plot_calibration()`](https://cuiweig.github.io/clinicalfair/reference/plot_calibration.md)
for decile calibration curves by group. Differential calibration — where
predicted probabilities carry different meanings across groups — is
arguably the most consequential form of clinical algorithmic unfairness,
and the calibration plot makes it immediately visible.

# Example Usage

``` r
library(clinicalfair)
data(compas_sim)

# Bundle predictions with labels and protected attributes
fd <- fairness_data(
  predictions    = compas_sim$risk_score,
  labels         = compas_sim$recidivism,
  protected_attr = compas_sim$race
)

# Compute group-wise metrics with bootstrap CIs
fm <- fairness_metrics(fd, ci = TRUE, n_boot = 2000)

# Generate audit report with violation flags
rpt <- fairness_report(fd)

# Visualise calibration disparities
plot_calibration(fd)

# Intersectional analysis
isf <- intersectional_fairness(
  predictions = compas_sim$risk_score,
  labels      = compas_sim$recidivism,
  race        = compas_sim$race,
  sex         = compas_sim$sex,
  min_group_size = 30
)

# Threshold-based mitigation
mit <- threshold_optimize(fd, objective = "equalized_odds",
                          min_accuracy = 0.60)
```

# Included Data

The package includes `compas_sim`, a simulated dataset modelled on the
COMPAS recidivism prediction system investigated by ProPublica. The
dataset contains 1,000 observations with predicted risk scores, binary
recidivism outcomes, and racial group membership, with systematic bias
in risk score assignment reflecting documented disparities. The
simulation seed references the ProPublica publication date.

# Design Rationale

`clinicalfair` is deliberately post-hoc and model-agnostic. It evaluates
trained models rather than modifying training procedures, reflecting the
operational reality that fairness audits are most frequently conducted
by teams who receive a trained model and must assess it, not by the
teams who built it. All metrics and reports are returned as structured
tibbles, enabling programmatic integration into automated reporting
pipelines. Console output uses the `cli` package for consistent,
informative formatting. S3 methods (`print`, `autoplot`) follow R
conventions and return results invisibly.

# Availability

`clinicalfair` is available on CRAN at
<https://CRAN.R-project.org/package=clinicalfair> and on GitHub at
<https://github.com/CuiweiG/clinicalfair>. A vignette demonstrates the
complete audit workflow using the included dataset.

# References
