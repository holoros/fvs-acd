# =============================================================================
# Figure 1. Five-way scorecard heatmap for the FVS-ACD v12.10.1 benchmark.
#
# Level bias (percent) with bootstrap 95 percent CIs and green/yellow/red flags,
# nine NSVB metrics on the operational in-domain set (POOLED_indomain).
#
# House standard is R-first (ggplot2). Scores are read straight from the
# corrected, authoritative scorecard and are NOT recomputed here.
#
# NOTE: The shipped PNG in this repo was rendered by the companion Python
# generator (fig1_scorecard_heatmap.py) because R was not available in the
# build sandbox (no root for apt; network behind a deny-all allowlist blocked
# CRAN and micromamba). This script is the canonical ggplot2 reproduction and
# produces the byte-for-content-equivalent figure wherever R + ggplot2 exist.
#
# Author: Aaron Weiskittel workspace (CRSF-Cowork)
# =============================================================================

suppressPackageStartupMessages({
  need <- c("data.table", "ggplot2")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) {
    install.packages(miss, repos = "https://cloud.r-project.org")
  }
  library(data.table)
  library(ggplot2)
})

# ---- Paths ------------------------------------------------------------------
repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data_csv <- file.path(repo, "data", "scorecard_five_v1210_corrected.csv")
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

# ---- Plot -------------------------------------------------------------------
title_txt <- sprintf(paste0(
  "Figure 1. Five-way scorecard, level bias percent with bootstrap 95%% CIs ",
  "and green/yellow/red flags,\nnine NSVB metrics on the operational ",
  "in-domain set (n = %d)"), n_val)

p <- ggplot(d, aes(x = model, y = metric)) +
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
    name = NULL) +
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
    plot.title        = element_text(size = 11.5, face = "bold", hjust = 0),
    legend.position   = "bottom",
    legend.text       = element_text(size = 9),
    legend.key.size   = unit(0.5, "cm"),
    plot.margin       = margin(10, 14, 10, 10)
  ) +
  guides(fill = guide_legend(nrow = 1))

ggsave(out_png, p, width = 9, height = 7, units = "in", dpi = 300, bg = "white")

# ---- Verification -----------------------------------------------------------
cat(sprintf("Wrote: %s\n", out_png))
cat(sprintf("n (POOLED_indomain) = %d\n\n", n_val))
print(d[order(factor(metric, levels = metrics), model),
        .(metric, model, bias_pct = round(bias_pct, 1),
          lo95 = round(bias_lo95, 1), hi95 = round(bias_hi95, 1), flag)])
