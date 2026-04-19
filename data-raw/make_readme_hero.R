# Build clinicalfair README hero image on real ProPublica COMPAS data.
#
# Data: compas-scores-two-years.csv from the ProPublica 2016 investigation
#   (https://github.com/propublica/compas-analysis), public domain.
# Filtering: Larson, Mattu, Kirchner & Angwin (2016) -- the canonical subset
#   used by ProPublica's published two-year analysis.
# Reference group: highest-N race (Caucasian) chosen explicitly over the
#   alphabetical auto-default for methodological validity.
# Inference: 500-replicate bootstrap 95% CIs on selection rate, TPR, FPR.
#
# Output: man/figures/fairness_audit_hero.png (1400x900 @ 150 dpi).

suppressPackageStartupMessages({
  library(clinicalfair)
  library(ggplot2)
  library(patchwork)
  library(dplyr)
})

# ---- Data fetch ------------------------------------------------------------

COMPAS_URL <- paste0(
  "https://raw.githubusercontent.com/propublica/",
  "compas-analysis/master/compas-scores-two-years.csv"
)

options(timeout = 60)
raw <- tryCatch(
  read.csv(url(COMPAS_URL), stringsAsFactors = FALSE),
  error   = function(e) NULL,
  warning = function(w) NULL
)
if (is.null(raw)) stop("COMPAS fetch failed; aborting per spec.")
cat("Fetched ProPublica COMPAS: ", nrow(raw), " rows, ",
    ncol(raw), " columns.\n", sep = "")

# ---- ProPublica filtering (Larson et al. 2016) -----------------------------

compas <- raw |>
  filter(
    days_b_screening_arrest >= -30,
    days_b_screening_arrest <=  30,
    is_recid != -1,
    c_charge_degree != "O",
    score_text != "N/A",
    race %in% c("African-American", "Caucasian", "Hispanic")
  )

N_total <- nrow(compas)
cat("After ProPublica filter (3 races): N =", N_total, "\n")

group_counts <- compas |> count(race) |> arrange(desc(n))
cat("Per-group counts:\n")
print(group_counts)

# Reference: highest-N group (methodological choice, not alphabetical)
ref_group <- group_counts$race[1]
cat("Reference group:", ref_group, "\n")

# ---- Build fairness_data ---------------------------------------------------

# Normalise decile_score (1-10) to [0.1, 1.0]; threshold 0.5 corresponds to
# ProPublica's decile_score >= 5 "high-risk" cutoff.
fd <- fairness_data(
  predictions     = compas$decile_score / 10,
  labels          = compas$two_year_recid,
  protected_attr  = compas$race,
  threshold       = 0.5,
  reference_group = ref_group
)

# ---- Metric computation with bootstrap CIs ---------------------------------
# Pin the seed so the 500-replicate bootstrap CIs are deterministic across
# pkgdown CI rebuilds; point estimates are unaffected, CI endpoints match
# bit-for-bit between runs.

set.seed(42L)
fm <- fairness_metrics(
  fd,
  metrics = c("selection_rate", "tpr", "fpr"),
  ci      = TRUE,
  n_boot  = 500L
)
fm$metric <- factor(
  fm$metric,
  levels = c("selection_rate", "tpr", "fpr"),
  labels = c("Selection rate", "TPR", "FPR")
)

cat("\n=== Fairness metrics (fm) ===\n")
print(fm)

# ---- Four-fifths thresholds under BOTH reference choices ------------------
# The ratio used for the four-fifths rule depends on who counts as the
# reference group. ProPublica's 2016 analysis treated high-selection-rate
# groups as bearing the disparate-impact harm (being flagged at higher
# rates). To avoid hiding that choice, we show both thresholds on Panel A:
# (i)  0.8 x AA selection rate — lower bound if AA is the reference;
# (ii) 1.25 x Caucasian selection rate — upper bound if Caucasian is the
#      reference. A rate outside both bounds is flagged under either
#      reference.

sel <- fm |> filter(metric == "Selection rate")
aa_rate    <- sel$value[sel$group == "African-American"]
cauc_rate  <- sel$value[sel$group == "Caucasian"]
ff_low_AA   <- 0.8  * aa_rate
ff_high_Cauc <- 1.25 * cauc_rate

sel <- sel |>
  mutate(
    status = case_when(
      group == "African-American"                        ~ "Reference (AA)",
      value < ff_low_AA & value < ff_high_Cauc           ~ "Violation (both refs)",
      value < ff_low_AA | value > ff_high_Cauc           ~ "Violation (one ref)",
      TRUE                                               ~ "Within 0.8x-1.25x (both refs)"
    )
  ) |>
  left_join(group_counts |> rename(group = race, N = n), by = "group")
status_levels <- unique(sel$status)
sel$status <- factor(sel$status, levels = status_levels)

fr <- fairness_report(fd)
cat("\n=== fairness_report ===\n")
print(fr)

# ---- Panel A: selection rate with four-fifths reference line ---------------

pA <- ggplot(sel, aes(x = reorder(group, value),
                      y = value, fill = status)) +
  geom_col(width = 0.6, colour = "grey25", linewidth = 0.3) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, colour = "grey15") +
  # Two threshold lines — one per reference-group choice.
  geom_hline(yintercept = ff_low_AA,
             linetype = "dashed", colour = "#C62828", linewidth = 0.5) +
  geom_hline(yintercept = ff_high_Cauc,
             linetype = "dotted", colour = "#1565C0", linewidth = 0.5) +
  annotate("text", x = 0.55, y = ff_low_AA,
           label = sprintf("0.8 x AA = %.2f", ff_low_AA),
           hjust = -0.05, vjust = -0.5, size = 2.9, colour = "#C62828") +
  annotate("text", x = 0.55, y = ff_high_Cauc,
           label = sprintf("1.25 x Cauc = %.2f", ff_high_Cauc),
           hjust = 1.05, vjust = -0.5, size = 2.9, colour = "#1565C0") +
  geom_text(aes(label = sprintf("N = %s", format(N, big.mark = ","))),
            y = 1, hjust = 1.05, size = 3.3,
            fontface = "italic", colour = "grey20") +
  scale_fill_manual(
    values = c(
      "Reference (AA)"                 = "#455A64",
      "Within 0.8x-1.25x (both refs)"  = "#2E7D32",
      "Violation (one ref)"            = "#F57F17",
      "Violation (both refs)"          = "#C62828"
    ),
    name = NULL
  ) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    limits = c(0, 1),
    expand = c(0, 0)
  ) +
  coord_flip() +
  labs(
    title    = "Selection rate by race group (two reference views)",
    subtitle = "Bars: rate with 95% bootstrap CI (500 reps); dashed/dotted: FF thresholds",
    x = NULL,
    y = "Selection rate (decile_score >= 5)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.title         = element_text(face = "bold", size = 13),
    plot.subtitle      = element_text(colour = "grey30", size = 10),
    legend.position    = "bottom",
    legend.direction   = "vertical",
    legend.key.size    = unit(0.4, "cm"),
    legend.text        = element_text(size = 9),
    axis.text.y        = element_text(face = "bold")
  )

# ---- Panel B: TPR + FPR by group (full labels) ----------------------------

err <- fm |>
  filter(metric %in% c("TPR", "FPR")) |>
  mutate(metric = factor(
    as.character(metric),
    levels = c("TPR", "FPR"),
    labels = c("True positive rate (TPR)", "False positive rate (FPR)")
  ))

pB <- ggplot(err, aes(x = group, y = value, fill = metric)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65,
           colour = "grey25", linewidth = 0.3) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    position = position_dodge(width = 0.75),
    width = 0.18, colour = "grey15"
  ) +
  scale_fill_manual(
    values = c("True positive rate (TPR)" = "#1565C0",
               "False positive rate (FPR)" = "#E65100"),
    name = NULL
  ) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    limits = c(0, 1), expand = c(0, 0)
  ) +
  labs(
    title    = "True and false positive rates by group",
    subtitle = "Error bars: 95% bootstrap CI (500 reps)",
    x = NULL,
    y = "Rate"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.title         = element_text(face = "bold", size = 13),
    plot.subtitle      = element_text(colour = "grey30", size = 10),
    legend.position    = "bottom",
    legend.direction   = "vertical",
    legend.key.size    = unit(0.4, "cm"),
    legend.text        = element_text(size = 9),
    axis.text.x        = element_text(size = 10)
  )

# ---- Combine panels --------------------------------------------------------

combined <- (pA + pB) +
  plot_layout(widths = c(0.55, 0.45)) +
  plot_annotation(
    title = sprintf(
      "Fairness audit of ProPublica COMPAS data (N = %s)",
      format(N_total, big.mark = ",")
    ),
    subtitle = paste0(
      "AA N=3,175; Caucasian N=2,103; Hispanic N=509.  ",
      "500 bootstrap replicates (seed=42).  No multiple-comparison correction."
    ),
    caption  = paste0(
      "Data: ProPublica compas-scores-two-years (2016 investigation, public).  ",
      "Filtered per Larson et al. (2016).  Cutoff: decile_score >= 5.\n",
      "Ratio direction depends on reference-group choice.  ProPublica (2016) ",
      "identified African-Americans as disproportionately high-risk flagged;\n",
      "Panel A shows thresholds under both AA-as-reference and Cauc-as-reference.  ",
      "Method: clinicalfair::fairness_metrics()."
    ),
    theme = theme(
      plot.title            = element_text(face = "bold", size = 15),
      plot.subtitle         = element_text(colour = "grey30", size = 12),
      plot.caption          = element_text(colour = "grey35", size = 8.5,
                                           hjust = 0, lineheight = 1.3,
                                           margin = margin(t = 10)),
      plot.caption.position = "plot",
      plot.margin           = margin(10, 18, 10, 10)
    )
  )

# ---- Save ------------------------------------------------------------------

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
out <- "man/figures/fairness_audit_hero.png"
ggsave(out, combined,
       width = 1400, height = 900, units = "px",
       dpi = 150, bg = "white")
sz <- file.info(out)$size
cat("\nSaved:", out, "-", sz, "bytes\n")
stopifnot(sz > 50000)
