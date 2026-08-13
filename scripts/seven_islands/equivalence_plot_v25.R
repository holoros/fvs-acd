#!/usr/bin/env Rscript
# equivalence_plot_v25.R
# v25 copy of equivalence_plot_v24.R -- same house r-analysis/advanced-viz
# equivalence-plot convention, unchanged. Retargeted to the v25 equivalence
# test outputs (six models: FVSACD_v1211_full and FVSACD_v131_full in place
# of FVSACD_v1211_silc73).

suppressMessages({
  library(ggplot2)
})

setwd("/users/PUOM0008/crsfaaron/silc_cfi")
plotdat <- readRDS("equivalence_plotdat_v25.rds")
results <- readRDS("equivalence_test_results_v25.rds")

pd <- do.call(rbind, plotdat)
model_order <- c("AcadianGY v8.35","FVS-ACD v12.11 (full137)","FVS-ACD v13.1 (full137)","FVS-ACD default","FVS-NE default","OSM-ACD")
pd$model <- factor(pd$model, levels = model_order)

# per-panel pass/fail + smallest-region annotation
ann <- do.call(rbind, lapply(names(results), function(key) {
  r <- results[[key]]
  parts <- strsplit(key, "__")[[1]]
  lab_map <- c(AGM_v835="AcadianGY v8.35", FVSACD_v1211_full="FVS-ACD v12.11 (full137)",
               FVSACD_v131_full="FVS-ACD v13.1 (full137)",
               FVS_ACD_default="FVS-ACD default", FVS_NE_default="FVS-NE default", OSM_ACD="OSM-ACD")
  data.frame(model = lab_map[parts[1]], metric = parts[2],
             lab = sprintf("slope %.2f [%.2f, %.2f]\nintercept %s | slope %s\nsmallest region: %.0f%%",
                            r$slope_hat, r$ci_b1[1], r$ci_b1[2],
                            ifelse(r$pass_b0,"PASS","FAIL"), ifelse(r$pass_b1,"PASS","FAIL"),
                            100*r$smallest_combined))
}))
ann$model <- factor(ann$model, levels = model_order)

house_theme <- theme_bw(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    strip.background = element_rect(fill = "grey20", color = NA),
    strip.text = element_text(color = "white", face = "bold", size = 10),
    axis.title = element_text(face = "bold"),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "grey30"),
    plot.caption = element_text(size = 8, color = "grey40", hjust = 0),
    legend.position = "none"
  )

make_panel <- function(metric_key, ylab_expr, xlab_expr, title, subtitle) {
  d <- pd[pd$metric == metric_key, ]
  a <- ann[ann$metric == metric_key, ]
  rng <- range(c(d$observed, d$predicted), na.rm = TRUE)
  pad <- diff(rng) * 0.08
  lims <- c(max(0, rng[1] - pad), rng[2] + pad)

  ggplot(d, aes(x = predicted, y = observed)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
    geom_smooth(method = "lm", formula = y ~ x, color = "#B2182B", fill = "#B2182B", alpha = 0.15, linewidth = 0.8) +
    geom_point(color = "#2166AC", alpha = 0.65, size = 1.8) +
    geom_text(data = a, aes(x = -Inf, y = Inf, label = lab), inherit.aes = FALSE,
              hjust = -0.03, vjust = 1.15, size = 2.6, color = "grey20", lineheight = 0.95) +
    coord_equal(xlim = lims, ylim = lims) +
    facet_wrap(~ model, nrow = 1) +
    labs(title = title, subtitle = subtitle, x = xlab_expr, y = ylab_expr,
         caption = "Dashed line: 1:1. Red line + band: OLS fit with 95% CI (visual reference; equivalence test itself is the bootstrap\nregion-of-similarity test in the companion table, not this parametric band). Points: SILC CFI routine plots (n=63-65).") +
    house_theme
}

p_val <- make_panel("tot_val",
  expression(bold(Observed~stumpage~value~(USD~ac^-1))),
  expression(bold(Predicted~stumpage~value~(USD~ac^-1))),
  "SILC CFI v25 equivalence test -- stumpage value per acre",
  "Plot-level observed vs. predicted, Aroostook County 2024 $; bootstrap TOST equivalence test in companion table (5000 resamples, plot-cluster)")

p_cd <- make_panel("tot_cd",
  expression(bold(Observed~merch~volume~(cords~ac^-1))),
  expression(bold(Predicted~merch~volume~(cords~ac^-1))),
  "SILC CFI v25 equivalence test -- merchantable volume per acre",
  "Plot-level observed vs. predicted, SILC merch spec; bootstrap TOST equivalence test in companion table (5000 resamples, plot-cluster)")

ggsave("equivalence_plot_value_v25.png", p_val, width = 18, height = 4.2, dpi = 300, bg = "white")
ggsave("equivalence_plot_volume_v25.png", p_cd, width = 18, height = 4.2, dpi = 300, bg = "white")

cat("Saved equivalence_plot_value_v25.png and equivalence_plot_volume_v25.png\n")
