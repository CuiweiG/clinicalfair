# Twitter/X Announcement Thread — clinicalfair

**Tweet 1:** The FDA expects fairness documentation for clinical AI.
Most teams lack a standardised toolkit for conducting those audits.

clinicalfair is now on CRAN — post-hoc fairness assessment for clinical
prediction models, model-agnostic, with regulatory-aligned reporting.
\#rstats \#FDACompliance

**Tweet 2:** What it does: takes predicted probabilities + true labels +
protected attributes → computes group-wise TPR, FPR, PPV, AUC,
calibration with bootstrap CIs → flags four-fifths rule violations →
generates audit reports. Works with any model. \#HealthEquity
\#OpenSource

**Tweet 3:** Intersectional analysis matters. A model can look fair by
race and fair by sex, yet fail for specific subgroups at the
intersection. intersectional_fairness() evaluates combinations of
multiple protected attributes with configurable minimum group sizes.

**Tweet 4:** When disparities are found, threshold_optimize() searches
for group-specific decision thresholds that equalise error rates while
maintaining an accuracy floor. The model stays untouched — critical in
regulated settings where modifications trigger re-validation.
\#ClinicalAI

**Tweet 5:** Calibration plots by group, ROC curves by group, disparity
bar charts — all publication-ready. Includes a COMPAS-style simulation
dataset for immediate exploration.

install.packages(“clinicalfair”)
<https://CRAN.R-project.org/package=clinicalfair> — @CuiweiG23
\#AlgorithmicFairness \#rstats
