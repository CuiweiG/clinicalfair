# clinicalfair: positioning among R fairness packages

Last checked: 2026-11-26.

- Statements about clinicalfair refer to the GitHub version 0.1.1 and
  were checked against the code in `R/`. CRAN has version 0.1.0,
  published 2026-04-02 [cf-cran].
- Statements about other packages were checked on 2026-11-26 against
  their CRAN pages, CRAN reference manuals and papers. Each one carries a
  source key in square brackets; the URLs are listed at the end.
- Versions and dates go out of date. Recheck them before each release.

## 1. What clinicalfair does

### 1.1 Input

`fairness_data()` (R/fairness-data.R) takes three vectors of equal
length: predicted probabilities, observed binary outcomes (0/1) and group
membership. Optional arguments are the decision threshold (default 0.5)
and the reference group. Without a reference group, the group with the
highest selection rate at the threshold is used (R/fairness-data.R,
lines 50-54). Missing values are rejected (line 40).

The fitted model is not needed, so predictions from any modeling software
can be audited. Outcomes must be binary.

### 1.2 Functions

| Area | Function (file) | What the code does |
|---|---|---|
| Group metrics | `fairness_metrics()` (R/fairness-metrics.R) | For each group: selection rate, true positive rate (TPR), false positive rate (FPR), positive predictive value (PPV), accuracy, Brier score and AUC (rank-based). Each value also has a ratio and a difference relative to the reference group. With `ci = TRUE`, percentile bootstrap intervals (resampling within each group, default 2,000 replicates) are added for the per-group values. The ratio and difference columns have no intervals. |
| Intersectional analysis | `intersectional_fairness()` (R/calibration.R) | Pastes two or more attribute vectors into combined labels (for example `"Black x Female"`), drops combinations with fewer than `min_group_size` observations (default 10) with a warning, and returns `fairness_metrics()` output for the remaining combinations. There are no `ci` or `reference_group` arguments; the reference is the combination with the highest selection rate. Attributes are treated as categorical, so a continuous variable such as age must be grouped first. |
| Calibration by group | `plot_calibration()` (R/calibration.R) | One calibration curve per group: predictions are cut into `n_bins` equal-width bins on [0, 1] (default 10), and the mean prediction in each bin is plotted against the observed outcome rate. Bins with fewer than two observations are dropped. No calibration statistic (for example calibration-in-the-large or calibration slope) and no interval is computed. The only numeric calibration-related output is the per-group Brier score from `fairness_metrics()`, which also depends on discrimination. |
| Discrimination by group | `plot_roc()` (R/fairness-plot.R) | Empirical ROC curve per group. |
| Metric plot | `autoplot()` method for `fairness_metrics` objects (R/fairness-plot.R) | Bar chart of per-group metric values, one panel per metric, with the reference group named in the caption. Ratios, differences and intervals are not drawn. |
| Report | `fairness_report()` (R/fairness-plot.R) | Returns a list with the metric table, the rows whose ratio to the reference group is below 0.8 or above 1.25 (checked for every metric in the table, all seven by default, not only selection rate; rows with an undefined ratio are skipped) and a one-sentence recommendation. The print method writes a short summary to the console. No file or document is produced. |
| Mitigation | `threshold_optimize()` (R/mitigation.R) | Post-processing. For each group separately, a grid of thresholds (step `grid_resolution`, default 0.01, which gives 99 candidates) is searched for the threshold whose TPR and FPR are closest, by sum of absolute differences, to the pooled TPR and FPR at the original threshold (`objective = "equalized_odds"`), or whose selection rate is closest to the overall selection rate (`objective = "demographic_parity"`). Thresholds are deterministic. If overall accuracy after the change falls below `min_accuracy` (default 0.5), all thresholds are reset to the original value with a warning. The result holds the thresholds and the `fairness_metrics()` output before and after. |
| Example data | `compas_sim` (R/data.R; generator in data-raw/prepare_compas.R) | Simulated recidivism scores: 1,000 rows, two groups. |

Imports: cli, dplyr, ggplot2, rlang, stats and tibble (DESCRIPTION).

### 1.3 What clinicalfair does not do

No code in `R/` was found for any of the following:

- pre-processing or in-processing bias mitigation;
- randomized post-processing, or choosing thresholds by minimizing a loss
  under a fairness constraint. Hardt, Price, and Srebro (2016) define the
  derived predictor as the one that minimizes expected loss subject to the
  fairness condition. For equalized odds with a score, that predictor can
  be a random mixture of two thresholds per group; for equal opportunity,
  one deterministic threshold per group is optimal (Sections 4 and 4.2)
  [hardt]. `threshold_optimize()` uses one deterministic threshold per
  group chosen by distance to pooled rates, and checks `min_accuracy`
  only after the search;
- intervals or tests for between-group ratios or differences, and
  multiple-comparison adjustment;
- outcomes other than binary (multi-class, continuous, time-to-event),
  and case weights;
- model explanation;
- document-style reports (files).

All metrics are computed against the labels the user supplies. Obermeyer
et al. (2019) found racial bias in a care-management algorithm because it
used health costs as a proxy for health needs [obermeyer]. clinicalfair
cannot detect that kind of label-choice bias from the predictions and the
proxy label alone. Such a check needs a second outcome measure; the
clinicalfair functions can be rerun with it as `labels` if it is binary.

## 2. Comparable R packages

### 2.1 Overview

| Package | Latest CRAN version (published) | Required input | Mitigation stage | Sources |
|---|---|---|---|---|
| fairmodels | 1.2.2 (2025-11-30) | Fitted models wrapped as 'DALEX' explainers | Pre-processing, post-processing | [fm-cran], [fm-refman] |
| mlr3fairness | 0.4.0 (2025-06-24) | 'mlr3' tasks and learners; `compute_metrics()` also takes predictions made outside 'mlr3' | Pre-processing, in-processing (learners that wrap 'fairml'), post-processing | [m3f-cran], [m3f-refman] |
| fairml | 0.9.1 (2026-03-09) | Response, predictors and sensitive attributes, used to fit a new model | In-processing | [fml-cran], [fml-refman] |
| fairness | 1.2.3 (2025-12-14) | Data frame with outcome, group and predicted probabilities or classes | None found | [fair-cran], [fair-refman] |
| fairmetrics | 1.0.8 (2026-04-16) | Data frame with outcome, a two-group protected attribute and predicted probabilities | None found | [fmet-cran], [fmet-refman] |
| yardstick (fairness metrics) | 1.5.0 (2026-11-18) | Data frame with truth, estimate and a group column | None found | [ys-cran], [ys-refman] |
| clinicalfair | 0.1.0 (2026-04-02); 0.1.1 on GitHub | Three vectors | Post-processing (deterministic group thresholds) | [cf-cran], `R/` |

"None found" means that no mitigation function was found in the package's
reference manual.

### 2.2 fairmodels

- Maintenance: version 1.2.2 was published on 2025-11-30 [fm-cran]. The
  CRAN archive lists the previous release, 1.2.1, with the date
  2022-08-23, and the first archived version, 0.1.1, with 2020-08-20
  [fm-archive]. CRAN checks were OK on all 13 platforms on 2026-11-26
  [fm-checks]. Paper: Wiśniewski and Biecek (2022), The R Journal
  14(1):227-243 [fm-rj].
- Inputs and framework: imports 'DALEX' [fm-cran]. The main function,
  `fairness_check()`, takes explainers created with `DALEX::explain()`
  for binary classification, or existing fairness objects, together with
  a protected factor, a privileged level and optional per-group cutoffs
  [fm-refman]. 'DALEX' explainers are model agnostic [dalex-cran], so
  fairmodels is not tied to one modeling framework, but it needs a fitted
  model wrapped as an explainer rather than a vector of predictions.
- Metrics: TPR, TNR, PPV, NPV, FNR, FPR, FDR, FOR, threat score,
  statistical parity, accuracy and F1, compared with the privileged group
  as ratios and summarized as "parity loss". A metric fails the check when
  its ratio is outside (`epsilon`, 1/`epsilon`), with `epsilon = 0.8` by
  default [fm-refman]. `fairness_check_regression()` is an experimental
  check for regression models [fm-refman].
- Plots: fairness check plot, heatmap, radar, PCA biplot, stacked
  metrics, metric scores, density, performance versus fairness, and
  cutoff plots (`all_cutoffs()`, `ceteris_paribus_cutoff()`) [fm-refman].
- Mitigation: pre-processing with `disparate_impact_remover()`,
  `reweight()` and `resample()` (also through `pre_process_data()`);
  post-processing with `roc_pivot()` (reject option based classification)
  and with per-group cutoffs passed to `fairness_check()` [fm-refman].
- Not found in the reference manual (searched for "bootstrap",
  "confidence interval" and "intersect"): confidence intervals and a
  dedicated function for crossed subgroups [fm-refman].

### 2.3 mlr3fairness

- Maintenance: version 0.4.0 was published on 2025-06-24 [m3f-cran]. The
  CRAN archive lists 0.3.0 (2022-05-12), 0.3.1 (2022-08-16) and 0.3.2
  (2023-05-05) [m3f-archive]. CRAN checks were OK on all platforms on
  2026-11-26 [m3f-checks]. Paper: Pfisterer et al. (2023), The R Journal
  15(1):234-253 [m3f-rj].
- Inputs and framework: part of the 'mlr3' ecosystem; imports 'mlr3',
  'mlr3pipelines' and related packages [m3f-cran]. Protected attributes
  are set as a column role (`pta`) of an 'mlr3' task; several protected
  columns define intersecting groups [m3f-refman]. `compute_metrics()`
  computes the fairness measures for predictions that were not made with
  'mlr3' [m3f-refman].
- Metrics: predefined measures for absolute between-group differences in
  accuracy, MSE, FNR, FPR, TNR, TPR, NPV, PPV, false omission rate and
  confusion-matrix counts; the Calders-Wevers gap (demographic parity);
  equalized odds and predictive parity summaries; and accuracy under a
  fairness constraint. Custom measures can compare groups by difference
  or by ratio (`groupdiff_tau()`) [m3f-refman].
- Plots: `fairness_accuracy_tradeoff()`, `compare_metrics()` and
  `fairness_prediction_density()` [m3f-refman].
- Mitigation: pre-processing by reweighing (`PipeOpReweighingWeights`,
  `PipeOpReweighingOversampling`); post-processing by equalized odds
  debiasing (`po("EOd")`), which flips a subset of predictions at random
  with precomputed probabilities and cites Hardt et al. (2016) and Pleiss
  et al. (2017); in-processing through fair learners that wrap 'fairml'
  models [m3f-refman]. Learners and debiasing steps can be tuned jointly
  [m3f-cran].
- Reports: `report_fairness()`, `report_modelcard()` and
  `report_datasheet()` create R Markdown templates [m3f-refman].

### 2.4 fairml

- Maintenance: version 0.9.1 was published on 2026-03-09 [fml-cran]. The
  CRAN archive lists versions from 0.2 (2020-08-06) to 0.9 (2025-04-30)
  [fml-archive]. CRAN checks on 2026-11-26: OK on 7 platforms, a NOTE on
  5 r-devel platforms and a WARN on r-oldrel-macos-x86_64 [fml-checks].
  Method paper: Scutari, Panero and Proissl (2022), Statistics and
  Computing 32(5):77 [fml-paper].
- Inputs and framework: fits new models from a response, predictors and
  sensitive attributes (vectors, matrices or data frames); imports
  'glmnet' [fml-cran], [fml-refman].
- Models (in-processing): `frrm()` and `fgrrm()` (fair ridge and fair
  generalized ridge regression; `fgrrm()` supports the Gaussian, binomial,
  Poisson, Cox and multinomial families), `nclm()` (Komiyama et al. 2018),
  and `zlm()` and `zlrm()` (Zafar et al. 2019), each with an `unfairness`
  bound. `frrm()` and `fgrrm()` accept statistical parity, equality of
  opportunity, individual fairness or a user-supplied definition
  [fml-refman].
- Other tools: cross-validation (`fairml.cv()`), profile plots over the
  unfairness bound (`fairness.profile.plot()`), bootstrap confidence
  intervals for model parameters (`confint()`, added in 0.9) and
  diagnostic plots [fml-refman], [fml-changelog].
- fairml fits new models; it is not a tool for auditing the predictions
  of an existing model.

### 2.5 Other packages with overlapping features

- fairness: version 1.2.3 was published on 2025-12-14 [fair-cran]; the
  CRAN archive lists the previous version, 1.2.2, with the date
  2021-04-14 [fair-archive]. Functions such as `dem_parity()`,
  `equal_odds()`, `pred_rate_parity()` and `roc_parity()` take a data
  frame with outcome, group and predicted probabilities or classes, return
  each group's metric relative to a base group, and draw bar and density
  plots; `roc_parity()` also draws ROC curves for all groups, and a
  continuous group variable can be binned [fair-refman]. No mitigation or
  interval functions were found in the reference manual [fair-refman].
- fairmetrics: version 1.0.8 was published on 2026-04-16; the CRAN archive
  lists the first version, 1.0.0, with the date 2025-05-19 [fmet-cran],
  [fmet-archive]. The protected attribute must have exactly two groups.
  Twelve `eval_*()` functions (among them statistical parity, equal
  opportunity, predictive equality, Brier score parity and balance for the
  positive and negative class) and `get_fairness_metrics()` report each
  group's value, the difference and the ratio between the two groups, and
  bootstrap confidence intervals for the difference and the ratio. The
  package includes preprocessed MIMIC-II clinical data [fmet-refman], and
  its description cites Gao et al. (2025) [fmet-cran], [fmet-paper]. No
  plotting or mitigation functions were found in the reference manual
  [fmet-refman].
- yardstick: `demographic_parity()`, `equalized_odds()` and
  `equal_opportunity()` were added in version 1.3.0 and are built with
  `new_groupwise_metric()` [ys-news]. By default each returns the largest
  between-group difference of the underlying metric, and they are used in
  metric sets [ys-refman]. Version 1.5.0 was published on 2026-11-18
  [ys-cran]. A tidymodels article applies them to hospital readmission
  data [tm-readmission].
- probably: `cal_plot_breaks()` draws binned calibration curves with
  intervals for the event rate and accepts a grouping column (`.by`)
  [prob-refman]; version 1.2.0 was published on 2025-10-16 [prob-cran].
- DALEX: model-agnostic explainers, used by fairmodels; version 2.5.4 was
  published on 2026-07-15 [dalex-cran].
- The CRAN package aif360 was archived on 2023-06-20 [aif-cran] and is not
  considered here.

## 3. Boundaries

### 3.1 Covered by other packages, not by clinicalfair

| Capability | clinicalfair | Available in |
|---|---|---|
| Fairness-constrained model fitting (in-processing) | No | fairml [fml-refman]; mlr3fairness fair learners [m3f-refman] |
| Pre-processing (reweighing, resampling, feature repair) | No | fairmodels [fm-refman]; mlr3fairness [m3f-refman] |
| Randomized equalized odds post-processing | No; one deterministic threshold per group | mlr3fairness `po("EOd")` [m3f-refman] |
| Reject option based classification | No | fairmodels `roc_pivot()` [fm-refman] |
| Fairness measures inside resampling, benchmarking and tuning | No | mlr3fairness [m3f-cran]; yardstick metric sets [ys-refman] |
| Model explanation at the instance and dataset level | No | DALEX [dalex-cran], used by fairmodels [fm-cran] |
| Intervals for between-group differences or ratios | No; per-group intervals only | fairmetrics, two groups only [fmet-refman] |
| Report templates (fairness report, model card, datasheet) | No; console summary only | mlr3fairness [m3f-refman] |
| Regression outcomes | No | fairmodels, experimental [fm-refman]; mlr3fairness measures such as MSE differences [m3f-refman]; fairml [fml-refman] |
| Binned calibration curves with intervals | Curves without intervals | probably `cal_plot_breaks()` [prob-refman] |

### 3.2 What clinicalfair offers compared with these packages

Taken together, the following features distinguish clinicalfair from the
packages above. Each comparison rests on the sources in Section 2.

- The input is three vectors; no model object, task or explainer is
  needed. This differs from fairmodels and from mlr3fairness pipelines.
  Working from predictions alone is also possible in fairness,
  fairmetrics, yardstick and `mlr3fairness::compute_metrics()`, so it is
  not unique to clinicalfair.
- Two or more groups, and crossed subgroups with a minimum size
  (fairmetrics is limited to two groups).
- Per-group AUC and Brier score next to the threshold-based metrics, with
  optional per-group bootstrap intervals.
- ROC and calibration curves by group from the same object. Each kind of
  plot also exists elsewhere: ROC curves by group in
  `fairness::roc_parity()` [fair-refman] and grouped calibration curves,
  with intervals, in `probably::cal_plot_breaks()` [prob-refman].
- A deterministic group-specific threshold search with metrics before and
  after. It is easy to inspect, but it does not guarantee equalized odds,
  demographic parity or optimal accuracy.

One overlap: fairmodels applies the same 0.8 to 1.25 ratio band in
`fairness_check()` [fm-refman], so the four-fifths screen is not specific
to clinicalfair.

### 3.3 When to use which

- clinicalfair: you have predictions, outcomes and group labels from an
  existing model, possibly fitted elsewhere, and want per-group metrics
  with ratios and differences, crossed subgroups, ROC and calibration
  curves by group, and a simple threshold adjustment to inspect. The
  ratio flags carry no measure of uncertainty, and the threshold search
  is a heuristic.
- fairmetrics: the protected attribute has two groups and you need
  confidence intervals for between-group differences or ratios, or
  calibration-related criteria such as Brier score parity and class
  balance [fmet-refman].
- yardstick: you work in tidymodels and want fairness metrics inside
  metric sets during resampling or tuning [ys-refman], [tm-readmission].
- fairmodels: your models can be wrapped as 'DALEX' explainers, and you
  want to compare several models, use many plot types, try pre-processing
  or reject option post-processing, or combine fairness checks with
  'DALEX' explanations [fm-refman], [dalex-cran].
- mlr3fairness: you use 'mlr3' and want fairness measures in resampling
  and benchmarks, debiasing steps in pipelines (reweighing, randomized
  equalized odds post-processing), fair learners, or R Markdown report
  templates [m3f-refman].
- fairml: you can refit the model and want fairness constraints in the
  estimation of linear, generalized linear or Cox models, with a tunable
  bound on unfairness [fml-refman].
- fairness: you want metrics relative to a base group with bar and
  density plots, and do not need intervals or mitigation [fair-refman].

## Sources

All accessed 2026-11-26. CRAN archive dates are the dates shown in the
archive directory listing.

clinicalfair

- [cf-cran] https://CRAN.R-project.org/package=clinicalfair
- [cf-checks] https://cran.r-project.org/web/checks/check_results_clinicalfair.html

fairmodels and DALEX

- [fm-cran] https://CRAN.R-project.org/package=fairmodels
- [fm-archive] https://cran.r-project.org/src/contrib/Archive/fairmodels/
- [fm-refman] https://cran.r-project.org/web/packages/fairmodels/refman/fairmodels.html
- [fm-checks] https://cran.r-project.org/web/checks/check_results_fairmodels.html
- [fm-rj] Wiśniewski J, Biecek P (2022). fairmodels: a Flexible Tool for
  Bias Detection, Visualization, and Mitigation in Binary Classification
  Models. The R Journal 14(1):227-243. https://doi.org/10.32614/RJ-2022-019
- [dalex-cran] https://CRAN.R-project.org/package=DALEX

mlr3fairness

- [m3f-cran] https://CRAN.R-project.org/package=mlr3fairness
- [m3f-archive] https://cran.r-project.org/src/contrib/Archive/mlr3fairness/
- [m3f-refman] https://cran.r-project.org/web/packages/mlr3fairness/refman/mlr3fairness.html
- [m3f-checks] https://cran.r-project.org/web/checks/check_results_mlr3fairness.html
- [m3f-rj] Pfisterer F, Wei S, Vollmer S, Lang M, Bischl B (2023).
  Fairness Audits and Debiasing Using mlr3fairness. The R Journal
  15(1):234-253. https://doi.org/10.32614/RJ-2023-034

fairml

- [fml-cran] https://CRAN.R-project.org/package=fairml
- [fml-archive] https://cran.r-project.org/src/contrib/Archive/fairml/
- [fml-refman] https://cran.r-project.org/web/packages/fairml/refman/fairml.html
- [fml-changelog] https://cran.r-project.org/web/packages/fairml/ChangeLog
- [fml-checks] https://cran.r-project.org/web/checks/check_results_fairml.html
- [fml-paper] Scutari M, Panero F, Proissl M (2022). Achieving fairness
  with a simple ridge penalty. Statistics and Computing 32(5):77.
  https://doi.org/10.1007/s11222-022-10143-w

Other packages

- [fair-cran] https://CRAN.R-project.org/package=fairness
- [fair-archive] https://cran.r-project.org/src/contrib/Archive/fairness/
- [fair-refman] https://cran.r-project.org/web/packages/fairness/refman/fairness.html
- [fmet-cran] https://CRAN.R-project.org/package=fairmetrics
- [fmet-archive] https://cran.r-project.org/src/contrib/Archive/fairmetrics/
- [fmet-refman] https://cran.r-project.org/web/packages/fairmetrics/refman/fairmetrics.html
- [fmet-paper] Gao J, Chou B, McCaw ZR, Thurston H, Varghese P, Hong C,
  Gronsbell J (2025). What Is Fair? Defining Fairness in Machine Learning
  for Health. Statistics in Medicine 44(20-22):e70234.
  https://doi.org/10.1002/sim.70234
- [ys-cran] https://CRAN.R-project.org/package=yardstick
- [ys-news] https://cran.r-project.org/web/packages/yardstick/news/news.html
- [ys-refman] https://cran.r-project.org/web/packages/yardstick/refman/yardstick.html
- [tm-readmission] https://www.tidymodels.org/learn/work/fairness-readmission/
- [prob-cran] https://CRAN.R-project.org/package=probably
- [prob-refman] https://cran.r-project.org/web/packages/probably/refman/probably.html
- [aif-cran] https://CRAN.R-project.org/package=aif360

Methods

- [hardt] Hardt M, Price E, Srebro N (2016). Equality of Opportunity in
  Supervised Learning. https://doi.org/10.48550/arXiv.1610.02413
  (Sections 4 and 4.2 read in the rendering at
  https://ar5iv.labs.arxiv.org/html/1610.02413)
- [obermeyer] Obermeyer Z, Powers B, Vogeli C, Mullainathan S (2019).
  Dissecting racial bias in an algorithm used to manage the health of
  populations. Science 366(6464):447-453.
  https://doi.org/10.1126/science.aax2342 (summary read from the Crossref
  record, https://api.crossref.org/works/10.1126/science.aax2342)
