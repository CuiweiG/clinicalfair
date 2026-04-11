# CRAN Pre-Flight Audit: clinicalfair

**Audit date:** 2026-04-06  
**Package version:** 0.1.0  
**R version:** 4.5.3 (Windows 10 x64)

------------------------------------------------------------------------

## Summary

| Category | Issues | Auto-fixed |
|----------|--------|------------|
| FORMAT   | 1      | 1          |
| URL      | 0      | —          |
| CHECK    | 1      | 1          |
| DONTRUN  | 0      | —          |
| EXAMPLES | 0      | —          |
| CONSOLE  | 0      | —          |

**Overall: Package is in excellent shape.** Only version bump required.

------------------------------------------------------------------------

## \[FORMAT\] DESCRIPTION

- **Title:** “Algorithmic Fairness Assessment for Clinical Prediction
  Models” — ✅ Title case, no leading package name, 57 chars, no
  trailing period
- **<Authors@R>:**
  `person("Cuiwei", "Gao", ..., role = c("aut", "cre", "cph"))` — ✅
  proper format
- **License:** `MIT + file LICENSE` — ✅ valid CRAN license, LICENSE
  file present with YEAR/COPYRIGHT HOLDER
- **Version:** `0.1.0` — ⚠️ **MUST BUMP** (see CHECK below)
- **Description field:** ✅ multi-sentence, includes doi references,
  proper formatting
- **Encoding/Language:** ✅ UTF-8, en-US
- **Depends/Imports/Suggests:** ✅ all properly versioned

### Issue: Version must be bumped to 0.1.1

- **Category:** \[FORMAT\]
- **Severity:** Blocking (CRAN will reject resubmission at same version)
- **Auto-fixable:** ✅ Yes — bumped to 0.1.1

------------------------------------------------------------------------

## \[URL\] Link Check

All URLs tested and reachable:

| URL                                                                         | Status |
|-----------------------------------------------------------------------------|--------|
| <https://github.com/CuiweiG/clinicalfair>                                   | ✅ 200 |
| <https://github.com/CuiweiG/clinicalfair/issues>                            | ✅ 200 |
| <https://github.com/CuiweiG/clinicalfair/actions/workflows/R-CMD-check.yml> | ✅ 200 |
| <https://opensource.org/licenses/MIT>                                       | ✅ 200 |

No dead links found.

------------------------------------------------------------------------

## \[CHECK\] R CMD check –as-cran

**Result: 0 errors \| 1 warning \| 0 notes**

### WARNING: CRAN incoming feasibility

    Maintainer: 'Cuiwei Gao <48gaocuiwei@gmail.com>'
    Insufficient package version (submitted: 0.1.0, existing: 0.1.0)
    Days since last update: 4

- **Category:** \[CHECK\]
- **Cause:** Package 0.1.0 already exists on CRAN; must bump version for
  resubmission
- **Auto-fixable:** ✅ Yes — version bumped to 0.1.1 in DESCRIPTION,
  CITATION, cran-comments.md

**All other checks passed cleanly**, including: - Package installation,
loading, unloading - S3 registration and method consistency - Rd files,
cross-references, line widths - Examples (including –run-donttest) -
Tests (testthat) - Vignette rebuild - PDF and HTML manual generation

------------------------------------------------------------------------

## \[DONTRUN\] vs Audit

**No usage found anywhere** (R files or Rd files).

Three functions use `\donttest{}` appropriately for plotting examples: -
`autoplot.fairness_metrics.Rd` - `plot_calibration.Rd` - `plot_roc.Rd`

This is correct CRAN practice — plotting examples are suitable for
`\donttest{}`.

------------------------------------------------------------------------

## \[EXAMPLES\] Example Timing

All examples use lightweight simulated data (n=200–1000) with simple
computations. No heavy computation detected:

| Function                              | Data size | Heavy ops?  | Est. time |
|---------------------------------------|-----------|-------------|-----------|
| fairness_data()                       | n=200     | No          | \<0.1s    |
| fairness_metrics()                    | n=200     | No          | \<0.5s    |
| fairness_metrics(ci=TRUE, n_boot=500) | n=200     | Moderate    | ~2s       |
| fairness_report()                     | n=200     | No          | \<0.5s    |
| threshold_optimize()                  | n=1000    | Grid search | ~1s       |
| intersectional_fairness()             | n=400     | No          | \<0.5s    |
| plot_calibration()                    | n=1000    |             | N/A       |
| plot_roc()                            | n=200     |             | N/A       |
| autoplot()                            | n=200     |             | N/A       |
| compas_sim data                       | n=1000    | No          | \<0.1s    |

All within 5-second limit. ✅

------------------------------------------------------------------------

## \[CONSOLE\] print()/cat() Audit

**No inappropriate print() or cat() calls found.**

All console output uses
[`cli::cli_text()`](https://cli.r-lib.org/reference/cli_text.html),
[`cli::cli_h3()`](https://cli.r-lib.org/reference/cli_h1.html),
`cli::cli_alert_*()` and similar — which is best practice.

The four `print.*` S3 methods (`print.fairness_data`,
`print.fairness_metrics`, `print.fairness_report`,
`print.fairness_mitigation`) all use cli functions and return
`invisible(x)`. ✅

------------------------------------------------------------------------

## Auto-fixes Applied

1.  **DESCRIPTION:** Version bumped `0.1.0` → `0.1.1`
2.  **inst/CITATION:** Version note updated to `0.1.1`
3.  **cran-comments.md:** Updated to reflect current check results (1
    WARNING about version/timing is expected for resubmission and
    resolves with version bump)

------------------------------------------------------------------------

## Items Requiring Human Review

| \#  | Issue                               | Action needed                                                                                                               |
|-----|-------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| 1   | “Days since last update: 4” warning | CRAN policy requires 1–2 weeks between submissions. Wait before resubmitting, or provide justification in cran-comments.md. |
| 2   | NEWS.md                             | Consider adding a 0.1.1 section documenting what changed since 0.1.0                                                        |

------------------------------------------------------------------------

## Verdict

**Package is CRAN-ready** after version bump. The only blocking issue
was the version number, which has been auto-fixed. The “days since last
update” warning will resolve naturally with time or can be addressed in
cran-comments.md with justification.

Code quality is high: proper S3 methods, cli-based output, no abuse,
clean namespace, good documentation with DOI references.
