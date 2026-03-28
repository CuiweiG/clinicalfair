.libPaths("C:/Users/win10/R/win-library/4.4")
devtools::load_all(".", quiet = TRUE)
library(ggplot2)
library(patchwork)

data(compas_sim)
fd <- fairness_data(compas_sim$risk_score, compas_sim$recidivism,
                     compas_sim$race)
fm <- fairness_metrics(fd)
mit <- threshold_optimize(fd, objective = "equalized_odds")

od <- "man/figures"

## Wong 2011 palette
pal <- c("#0072B2", "#D55E00", "#009E73", "#E69F00", "#CC79A7")

## ============================================================
## Fig 1: Disparity metrics — before vs after mitigation
## ============================================================
key_metrics <- c("selection_rate", "tpr", "fpr")

before_df <- mit$before[mit$before$metric %in% key_metrics, ]
before_df$stage <- "Before mitigation"
after_df <- mit$after[mit$after$metric %in% key_metrics, ]
after_df$stage <- "After mitigation"
cmp <- rbind(before_df, after_df)
cmp$stage <- factor(cmp$stage,
                     levels = c("Before mitigation",
                                "After mitigation"))

pa <- ggplot(cmp, aes(x = value, y = group, fill = group)) +
    geom_col(alpha = 0.8, width = 0.55) +
    geom_text(aes(label = sprintf("%.2f", value)),
              hjust = -0.1, size = 2.2) +
    facet_grid(metric ~ stage, scales = "free_x") +
    scale_fill_manual(values = pal) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.3))) +
    labs(x = NULL, y = NULL, fill = NULL,
         title = expression(bold("a"))) +
    theme_classic(base_size = 8, base_family = "sans") +
    theme(legend.position = "bottom",
          strip.text = element_text(face = "bold", size = 7),
          panel.grid = element_blank())

## ============================================================
## Fig 1b: ROC by group
## ============================================================
roc_rows <- list()
for (grp in fd$groups) {
    idx <- fd$protected == grp
    pred <- fd$predictions[idx]
    lab <- fd$labels[idx]
    thresholds <- sort(unique(c(0, pred, 1)))
    for (th in thresholds) {
        cls <- as.integer(pred >= th)
        tp <- sum(cls == 1 & lab == 1)
        fp <- sum(cls == 1 & lab == 0)
        fn <- sum(cls == 0 & lab == 1)
        tn <- sum(cls == 0 & lab == 0)
        tpr <- if (tp + fn > 0) tp / (tp + fn) else 0
        fpr <- if (fp + tn > 0) fp / (fp + tn) else 0
        roc_rows <- c(roc_rows, list(data.frame(
            group = grp, fpr = fpr, tpr = tpr,
            stringsAsFactors = FALSE)))
    }
}
roc_df <- do.call(rbind, roc_rows)

pb <- ggplot(roc_df, aes(x = fpr, y = tpr, color = group)) +
    geom_line(linewidth = 0.7) +
    geom_abline(linetype = "dashed", color = "#999999",
                linewidth = 0.3) +
    scale_color_manual(values = pal) +
    coord_equal() +
    labs(x = "False positive rate", y = "True positive rate",
         color = NULL, title = expression(bold("b"))) +
    theme_classic(base_size = 8, base_family = "sans") +
    theme(legend.position = c(0.7, 0.25),
          legend.background = element_blank(),
          legend.key.size = unit(8, "pt"),
          panel.grid = element_blank())

fig1 <- pa + pb + plot_layout(widths = c(1.5, 1))
ggsave(file.path(od, "fig1_fairness_audit.png"),
       fig1, width = 183, height = 80, units = "mm",
       dpi = 300, bg = "white")
cat("fig1 done\n")

## ============================================================
## Fig 2: Calibration by group
## ============================================================
cal_rows <- list()
for (grp in fd$groups) {
    idx <- fd$protected == grp
    pred <- fd$predictions[idx]
    lab <- fd$labels[idx]
    breaks <- seq(0, 1, length.out = 11)
    bins <- cut(pred, breaks, include.lowest = TRUE)
    for (b in levels(bins)) {
        b_idx <- bins == b
        if (sum(b_idx) < 2) next
        cal_rows <- c(cal_rows, list(data.frame(
            group = grp, bin_mid = mean(pred[b_idx]),
            observed = mean(lab[b_idx]), n = sum(b_idx),
            stringsAsFactors = FALSE)))
    }
}
cal_df <- do.call(rbind, cal_rows)

fig2 <- ggplot(cal_df, aes(x = bin_mid, y = observed,
                             color = group)) +
    geom_abline(linetype = "dashed", color = "#999999",
                linewidth = 0.3) +
    geom_line(linewidth = 0.7) +
    geom_point(aes(size = n), alpha = 0.7) +
    scale_color_manual(values = pal) +
    scale_size_continuous(range = c(1, 4), guide = "none") +
    coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    labs(x = "Predicted probability", y = "Observed rate",
         color = NULL) +
    theme_classic(base_size = 9, base_family = "sans") +
    theme(legend.position = c(0.15, 0.85),
          legend.background = element_blank(),
          panel.grid = element_blank())

ggsave(file.path(od, "fig2_calibration.png"),
       fig2, width = 89, height = 89, units = "mm",
       dpi = 300, bg = "white")
cat("fig2 done\n")
