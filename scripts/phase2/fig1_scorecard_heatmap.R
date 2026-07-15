# =============================================================================
# Figure 1. Five-way scorecard heatmap for the FVS-ACD v12.10.1 benchmark.
#
# Level bias (percent) with bootstrap 95 percent CIs and green/yellow/red flags,
# nine NSVB metrics on the operational in-domain set (POOLED_indomain), PLUS a
# clearly separated Overall composite strip showing each model's PRIMARY
# %RMSE-weighted composite (0 to 100, higher is better). The composite blends
# accuracy and precision in one number and is read from composite_rmse_frozen.csv;
# the per-metric tiles remain the bias-and-CI view. The two panels are stacked
# with patchwork so the composite strip carries its own green colour scale,
# separate from the bias-flag tiles above it.
#
# House standard is R-first (ggplot2). Scores are read straight from the
# corrected, authoritative scorecard and are NOT recomputed here.
#
# NOTE: The shipped PNG in this repo was rendered by the companion Python
# generator (fig1_scorecard_heatmap.py) because R was not available in the
# build sandbox (no root for apt; network behind a deny-all allowlist blocked
# CRAN and micromamba). This script is the canonical ggplot2 reproduction and
# produces the content-equivalent figure wherever R + ggplot2 exist.
#
# Author: Aaron Weiskittel workspace (CRSF-Cowork)
# =============================================================================

suppressPackageStartupMessages({
  need <- c("data.table", "ggplot2", "patchwork")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) {
    install.packages(miss, repos = "https://cloud.r-project.org")
  }
  library(data.table)
  library(ggplot2)
  library(patchwork)
})

# ---- Paths ------------------------------------------------------------------
repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data_csv <- file.path(repo, "data", "scorecard_five_v1210_corrected.csv")
comp_csv <- file.path(repo, "data", "composite_rmse_frozen.csv")
out_png  <- file.path(repo, "figures", "fig1_scorecard_heatmap.png")

# ---- Flagship selection (read as-is; do NOT recompute scores) ---------------
subset_keep <- "POOLED_indomain"
models  <- c("v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM")  # x, drop v12.7.1
metrics <- c("BA", "SDI", "QMD", "TOPHT", "TOTVOL",
             "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE")             # y, BA at top

metric_label <- c(
  BA       = "Basal area (BA)",
  SDI      = "Stand density index (SDI)",
  QMD      = "Quadratic mean diameter (QMD)",
  TOPHT    = "Top height (TOPHT)",
  TOTVOL   = "Total volume (TOTVOL)",
  MERCHVOL = "Merch volume (MERCHVOL)",
  SAWVOL   = "Sawlog volume (SAWVOL)",
  BIOMASS  = "Aboveground biomass (BIOMASS)",
  VALUE    = "Stand value (VALUE)"
)

# Colorblind-safe, muted (not neon) flag palette
flag_fill <- c(green = "#4C8C5A", yellow = "#E0B33A", red = "#C0504D")

# ---- Load and shape ---------------------------------------------------------
dt <- fread(data_csv)
d  <- dt[subset == subset_keep & model %chin% models]
d[, model  := factor(model,  levels = models)]
d[, metric := factor(metric, levels = rev(metrics))]   # rev so BA sits at top
d[, flag   := factor(flag,   levels = c("green", "yellow", "red"))]

n_val <- d[, unique(n)][1]

# Tile text: bold signed bias percent, and the 95% CI beneath it
d[, bias_txt := sprintf("%+.1f%%", bias_pct)]
d[, ci_txt   := sprintf("[%.1f, %.1f]", bias_lo95, bias_hi95)]
# White text on the darker fills (green, red), near-black on gold
d[, txt_col := ifelse(flag == "yellow", "#111111", "#FFFFFF")]

# ---- Overall %RMSE composite strip (separate colour encoding) ---------------
cm <- fread(comp_csv)
cm <- cm[stratum == subset_keep & model %chin% models]
cm[, model := factor(model, levels = models)]
cm[, lab := sprintf("%.1f", composite_primary_rmse)]
cm[, rlab := sprintf("rank %d", rank_primary_rmse)]
cm[, strip := "Overall composite\n(%RMSE, 0 to 100)"]
cm[, txt_col := ifelse(composite_primary_rmse >= 50, "#FFFFFF", "#111111")]

# ---- Plot -------------------------------------------------------------------
title_txt <- sprintf(paste0(
  "Figure 1. Five-way scorecard: per-metric level bias percent with bootstrap ",
  "95%% CIs and green/yellow/red\nflags (nine NSVB metrics), plus the Overall ",
  "%%RMSE-weighted composite (0 to 100, higher is better) on\nthe operational ",
  "in-domain set (n = %d)"), n_val)

p_bias <- ggplot(d, aes(x = model, y = metric)) +
  geom_tile(aes(fill = flag), colour = "white", linewidth = 0.9) +
  geom_text(aes(label = bias_txt, colour = txt_col),
            nudge_y = 0.14, fontface = "bold", size = 3.7) +
  geom_text(aes(label = ci_txt, colour = txt_col),
            nudge_y = -0.20, size = 2.7) +
  scale_fill_manual(
    values = flag_fill,
    breaks = c("green", "yellow", "red"),
    labels = c("green  |bias| < 5% and NSE > 0.6",
               "yellow  intermediate",
               "red  |bias| >= 10% or NSE < 0.4"),
    name = "Per-metric bias tiles") +
  scale_colour_identity() +
  scale_x_discrete(position = "top") +
  scale_y_discrete(labels = metric_label) +
  labs(title = title_txt, x = NULL, y = NULL) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA),
    panel.grid        = element_blank(),
    axis.text.x.top   = element_text(size = 11),
    axis.text.y       = element_text(size = 10, hjust = 1),
    axis.ticks        = element_blank(),
    plot.title        = element_text(size = 10.8, face = "bold", hjust = 0),
    legend.position   = "bottom",
    legend.text       = element_text(size = 9),
    legend.key.size   = unit(0.5, "cm"),
    plot.margin       = margin(10, 14, 2, 10)
  ) +
  guides(fill = guide_legend(nrow = 1))

# Overall composite strip: own green sequential scale, 0 to 100
p_comp <- ggplot(cm, aes(x = model, y = strip)) +
  geom_tile(aes(fill = composite_primary_rmse),
            colour = "white", linewidth = 0.9) +
  geom_text(aes(label = lab, colour = txt_col),
            nudge_y = 0.12, fontface = "bold", size = 4.4) +
  geom_text(aes(label = rlab, colour = txt_col),
            nudge_y = -0.22, size = 2.8) +
  scale_fill_gradientn(
    colours = c("#EEF3EA", "#9CBF86", "#4C8C5A", "#265C36"),
    limits = c(0, 100), name = "Overall composite (%RMSE, 0 to 100)",
    guide  = guide_colourbar(barwidth = 9, barheight = 0.4,
                             title.position = "top")) +
  scale_colour_identity() +
  scale_x_discrete(position = "top") +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    panel.grid       = element_blank(),
    axis.text.x      = element_blank(),
    axis.text.y      = element_text(size = 9.6, face = "bold", hjust = 1),
    axis.ticks       = element_blank(),
    legend.position  = "bottom",
    legend.title     = element_text(size = 8.6),
    plot.margin      = margin(2, 14, 10, 10)
  )

# Stack: tall bias panel over a short composite strip
p <- p_bias / p_comp + plot_layout(heights = c(9, 1.35))

ggsave(out_png, p, width = 9, height = 7.9, units = "in", dpi = 300, bg = "white")

# ---- Verification -----------------------------------------------------------
cat(sprintf("Wrote: %s\n", out_png))
cat(sprintf("n (POOLED_indomain) = %d\n\n", n_val))
print(d[order(factor(metric, levels = metrics), model),
        .(metric, model, bias_pct = round(bias_pct, 1),
          lo95 = round(bias_lo95, 1), hi95 = round(bias_hi95, 1), flag)])
cat("\nOverall %RMSE composite (primary):\n")
print(cm[order(model), .(model, composite_primary_rmse, rank_primary_rmse)])
