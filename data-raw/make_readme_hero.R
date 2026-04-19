# Publication-standard hero figure for clinicalfair on ProPublica COMPAS.
#
# Data: compas-scores-two-years.csv (Larson et al. 2016, ProPublica).
# Output: man/figures/fairness_audit_hero.{png, pdf} at 600 DPI, 183x95 mm.
# Layout: 2-panel patchwork with Okabe-Ito colorblind-safe palette.

suppressPackageStartupMessages({
  library(clinicalfair)
  library(ggplot2)
  library(patchwork)
  library(dplyr)
  library(ragg)
  library(systemfonts)
})

# ---- Publication theme ----------------------------------------------------

theme_publication <- function(base_size = 8) {
  theme_classic(base_size = base_size, base_family = "sans") +
    theme(
      plot.title            = element_text(face = "bold", size = rel(1.10),
                                           hjust = 0,
                                           margin = margin(b = 3)),
      plot.subtitle         = element_text(size = rel(0.95),
                                           color = "grey30",
                                           margin = margin(b = 5)),
      plot.caption          = element_text(size = rel(0.85),
                                           color = "grey40",
                                           hjust = 0,
                                           margin = margin(t = 5),
                                           lineheight = 1.15),
      plot.caption.position = "plot",
      plot.title.position   = "plot",
      axis.title            = element_text(size = rel(1.00), color = "black"),
      axis.text             = element_text(size = rel(0.90), color = "black"),
      axis.line             = element_line(linewidth = 0.35, color = "black"),
      axis.ticks            = element_line(linewidth = 0.35, color = "black"),
      panel.grid.major      = element_line(linewidth = 0.25, color = "grey88"),
      panel.grid.minor      = element_blank(),
      legend.title          = element_text(size = rel(1.00), face = "bold"),
      legend.text           = element_text(size = rel(0.90)),
      legend.key.size       = unit(3, "mm"),
      legend.margin         = margin(0, 0, 0, 0),
      legend.background     = element_blank(),
      plot.margin           = margin(4, 6, 4, 6),
      plot.tag              = element_text(face = "bold",
                                           size = rel(1.40),
                                           family = "sans")
    )
}

# Okabe-Ito palette (colorblind-safe; distinguishable in greyscale print).
okabe_ito <- c(
  "African-American" = "#333333",
  "Caucasian"        = "#E69F00",
  "Hispanic"         = "#56B4E9",
  "TPR"              = "#0072B2",
  "FPR"              = "#D55E00"
)

# ---- Data fetch + filter --------------------------------------------------

COMPAS_URL <- paste0(
  "https://raw.githubusercontent.com/propublica/",
  "compas-analysis/master/compas-scores-two-years.csv"
)
options(timeout = 60)
raw <- tryCatch(
  read.csv(url(COMPAS_URL), stringsAsFactors = FALSE),
  error = function(e) stop("COMPAS fetch failed: ", conditionMessage(e))
)
cat("Fetched ProPublica COMPAS: ", nrow(raw), " rows\n", sep = "")

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
group_counts <- compas |> count(race) |> arrange(desc(n))
cat("After filter: N =", N_total, "; groups:\n"); print(group_counts)

ref_group <- group_counts$race[1]

# ---- fairness_data + metrics (pinned bootstrap) ---------------------------

fd <- fairness_data(
  predictions     = compas$decile_score / 10,
  labels          = compas$two_year_recid,
  protected_attr  = compas$race,
  threshold       = 0.5,
  reference_group = ref_group
)

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
cat("\nfairness_metrics:\n"); print(fm)

# Reference thresholds under two framings.
sel <- fm |>
  filter(metric == "Selection rate") |>
  left_join(group_counts |> rename(group = race, N = n), by = "group")
aa_rate      <- sel$value[sel$group == "African-American"]
cauc_rate    <- sel$value[sel$group == "Caucasian"]
ff_AA_low    <- 0.8  * aa_rate
ff_Cauc_low  <- 0.8  * cauc_rate

# ---- Panel a: selection rate, 2 reference thresholds ----------------------

sel$group <- factor(sel$group,
                    levels = c("Hispanic", "Caucasian", "African-American"))

pA <- ggplot(sel, aes(x = group, y = value, fill = group)) +
  geom_col(width = 0.60, colour = "black", linewidth = 0.30) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.22, colour = "black", linewidth = 0.45) +
  geom_hline(yintercept = ff_AA_low,
             linetype = "dashed",
             colour   = "#D55E00", linewidth = 0.40) +
  geom_hline(yintercept = ff_Cauc_low,
             linetype = "dotted",
             colour   = "#0072B2", linewidth = 0.40) +
  annotate("text", x = 0.48, y = ff_AA_low,
           label  = sprintf("0.8 x AA = %.2f", ff_AA_low),
           hjust  = 0, vjust = -0.4,
           colour = "#D55E00", size = 2.2) +
  annotate("text", x = 0.48, y = ff_Cauc_low,
           label  = sprintf("0.8 x Cauc = %.2f", ff_Cauc_low),
           hjust  = 0, vjust = 1.3,
           colour = "#0072B2", size = 2.2) +
  geom_text(aes(label = sprintf("N = %s", format(N, big.mark = ","))),
            y = 0.79, hjust = 1,
            size = 2.3, fontface = "italic", colour = "grey25") +
  scale_fill_manual(values = okabe_ito, guide = "none") +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    limits = c(0, 0.80),
    breaks = seq(0, 0.75, 0.25),
    expand = c(0, 0)
  ) +
  coord_flip() +
  labs(
    title = "Disparate impact under two reference definitions",
    x = NULL,
    y = "Selection rate (decile score >= 5)"
  ) +
  theme_publication()

# ---- Panel b: TPR / FPR grouped bar ---------------------------------------

err <- fm |> filter(metric %in% c("TPR", "FPR"))
err$group <- factor(err$group,
                    levels = c("African-American", "Caucasian", "Hispanic"))
err$metric_full <- factor(
  as.character(err$metric),
  levels = c("TPR", "FPR"),
  labels = c("True positive rate", "False positive rate")
)

pB <- ggplot(err, aes(x = group, y = value, fill = metric_full)) +
  geom_col(position = position_dodge(width = 0.75),
           width = 0.68, colour = "black", linewidth = 0.30) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                position = position_dodge(width = 0.75),
                width = 0.20, colour = "black", linewidth = 0.45) +
  scale_fill_manual(
    values = c("True positive rate"  = okabe_ito[["TPR"]],
               "False positive rate" = okabe_ito[["FPR"]]),
    name = NULL
  ) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    limits = c(0, 0.85),
    breaks = seq(0, 0.80, 0.25),
    expand = c(0, 0)
  ) +
  labs(
    title = "True and false positive rates",
    x = NULL,
    y = "Rate"
  ) +
  theme_publication() +
  theme(
    legend.position      = c(0.5, 1.00),
    legend.justification = c(0.5, 1.00),
    legend.direction     = "horizontal",
    legend.background    = element_rect(fill = "white", colour = NA),
    legend.key.size      = unit(2.6, "mm")
  )

# ---- Compose --------------------------------------------------------------

combined <- (pA + pB) +
  plot_layout(widths = c(0.55, 0.45)) +
  plot_annotation(
    title    = "Algorithmic fairness audit of COMPAS risk scores",
    subtitle = paste0(
      "ProPublica cohort, N = 5,787 across three racial groups; ",
      "95% bootstrap CIs (500 reps, seed = 42)."
    ),
    caption  = paste0(
      "Data: ProPublica two-year recidivism cohort ",
      "(Larson et al. 2016, CC-BY-SA). Decile score >= 5 = high risk.\n",
      "Panel a shows thresholds under African-American (highest-N) and ",
      "Caucasian (historical reference) framings.\n",
      "No multiple-comparison correction. ",
      "Method: clinicalfair::fairness_metrics()."
    ),
    tag_levels = "a"
  ) &
  theme(
    plot.tag     = element_text(face = "bold", size = 11, family = "sans"),
    plot.caption = element_text(hjust = 0, color = "grey40",
                                size = rel(0.85), lineheight = 1.15,
                                margin = margin(t = 5)),
    plot.caption.position = "plot"
  )

# ---- Save PNG (600 DPI via ragg) + PDF (cairo_pdf, vector) ---------------

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)

ggsave(
  filename = "man/figures/fairness_audit_hero.png",
  plot     = combined,
  device   = ragg::agg_png,
  width    = 183, height = 95, units = "mm",
  res      = 600, scaling = 1, bg = "white"
)
cat("\nPNG saved:", file.info("man/figures/fairness_audit_hero.png")$size,
    "bytes\n")

ggsave(
  filename = "man/figures/fairness_audit_hero.pdf",
  plot     = combined,
  device   = cairo_pdf,
  width    = 183, height = 95, units = "mm"
)
cat("PDF saved:", file.info("man/figures/fairness_audit_hero.pdf")$size,
    "bytes\n")

stopifnot(file.info("man/figures/fairness_audit_hero.png")$size > 100000)
