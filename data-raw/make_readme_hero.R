# Generates the README hero image for clinicalfair.
#
# Output: man/figures/fairness_audit_hero.png
#
# Shows selection-rate parity under the four-fifths rule using the
# package's built-in compas_sim dataset. Groups whose ratio versus the
# reference group falls outside [0.8, 1.25] are flagged as violations.

library(clinicalfair)
library(ggplot2)

data(compas_sim)

fd <- fairness_data(
  predictions    = compas_sim$risk_score,
  labels         = compas_sim$recidivism,
  protected_attr = compas_sim$race
)

fm <- fairness_metrics(fd, metrics = "selection_rate")
ref_group <- attr(fm, "reference_group")
ref_rate  <- fm$value[fm$group == ref_group]

fm$violation <- fm$ratio < 0.8 | fm$ratio > 1.25
fm$bar_class <- ifelse(fm$group == ref_group, "Reference",
                ifelse(fm$violation, "Four-fifths violation",
                                     "Within 0.8–1.25"))
fm$bar_class <- factor(fm$bar_class,
                       levels = c("Reference", "Within 0.8–1.25",
                                  "Four-fifths violation"))
fm$label_text <- sprintf("%.0f%%\n(ratio %.2f)", fm$value * 100, fm$ratio)

p <- ggplot(fm, aes(x = group, y = value, fill = bar_class)) +
  geom_col(width = 0.55) +
  geom_hline(yintercept = ref_rate * 0.8,
             linetype = "dashed", colour = "grey40", linewidth = 0.5) +
  annotate("text", x = 0.55, y = ref_rate * 0.8,
           label = "Four-fifths threshold (0.8 × reference)",
           hjust = 0, vjust = -0.5, size = 3.3, colour = "grey35") +
  geom_text(aes(label = label_text), vjust = -0.3,
            size = 4.2, fontface = "bold", colour = "grey15") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.22))) +
  scale_fill_manual(
    name = NULL,
    values = c(
      "Reference"             = "#546E7A",
      "Within 0.8–1.25"       = "#2E7D32",
      "Four-fifths violation" = "#C62828"
    )
  ) +
  labs(
    title    = "Four-fifths rule audit: COMPAS-like recidivism predictions",
    subtitle = sprintf(
      "Selection rate by race (n = %d, threshold = 0.5). Reference: %s.",
      nrow(compas_sim), ref_group),
    caption  = "Data: compas_sim (clinicalfair package)  |  Metric: fairness_metrics()",
    x = NULL, y = "Selection rate"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "top",
    legend.justification = "left",
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(colour = "grey30"),
    plot.caption  = element_text(colour = "grey45", size = 9),
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text = element_text(colour = "black")
  )

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("man/figures/fairness_audit_hero.png", p,
       width = 1200, height = 800, units = "px", dpi = 144, bg = "white")

cat("Saved: man/figures/fairness_audit_hero.png\n")
print(fm[, c("group", "value", "ratio", "violation")])
