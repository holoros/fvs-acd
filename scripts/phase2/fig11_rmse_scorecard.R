# =============================================================================
# Figure 11. Percent RMSE scorecard heatmap, FVS-ACD frozen benchmark.
#
# Model x metric heatmap of %RMSE (= 100 * RMSE / mean observed) on the
# operational in-domain set (POOLED_indomain, n = 705). %RMSE blends accuracy
# and precision in one number, so it does not deflate on high-mean metrics the
# way a percent-bias tile can. Lower is better, so the ramp runs dark green
# (low %RMSE, good) to warm/red (high %RMSE, poor). Each cell prints %RMSE with
# its within-province stratified bootstrap 95% interval.
#
# House standard is R-first (ggplot2). The shipped PNG was rendered by the
# companion Python generator (fig11_rmse_scorecard.py) because R was unavailable
# in the build sandbox; this is the canonical ggplot2 reproduction. Values are
# read straight from scorecard_rmse_frozen.csv and are NOT recomputed.
#
# Author: Aaron Weiskittel workspace (CRSF-Cowork)
# =============================================================================

suppressPackageStartupMessages({
  need <- c("data.table", "ggplot2")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) install.packages(miss, repos = "https://cloud.r-project.org")
  library(data.table); library(ggplot2)
})

repo     <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data_csv <- file.path(repo, "data", "scorecard_rmse_frozen.csv")
out_png  <- file.path(repo, "figures", "fig11_rmse_scorecard.png")

subset_keep <- "POOLED_indomain"
models  <- c("v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM")
metrics <- c("BA", "SDI", "QMD", "TOPHT", "TOTVOL",
             "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE")
metric_label <- c(
  BA = "Basal area (BA)", SDI = "Stand density index (SDI)",
  QMD = "Quadratic mean diameter (QMD)", TOPHT = "Top height (TOPHT)",
  TOTVOL = "Total volume (TOTVOL)", MERCHVOL = "Merch volume (MERCHVOL)",
  SAWVOL = "Sawlog volume (SAWVOL)", BIOMASS = "Aboveground biomass (BIOMASS)",
  VALUE = "Stand value (VALUE)")

d <- fread(data_csv)[stratum == subset_keep & model %chin% models]
d[, model  := factor(model,  levels = models)]
d[, metric := factor(metric, levels = rev(metrics))]   # rev so BA at top
n_val <- d[, unique(n)][1]

d[, lab := sprintf("%.1f", pct_rmse)]
d[, ci  := sprintf("[%.0f, %.0f]", pct_rmse_lo95, pct_rmse_hi95)]
d[, txt_col := ifelse(pct_rmse >= 46, "#FFFFFF", "#111111")]

title_txt <- sprintf(paste0(
  "Figure 11. Percent RMSE scorecard (%%RMSE = 100 x RMSE / mean observed), ",
  "nine NSVB metrics by model\non the operational in-domain set (n = %d). ",
  "Lower is better; brackets are within-province bootstrap 95%% intervals."),
  n_val)

p <- ggplot(d, aes(x = model, y = metric)) +
  geom_tile(aes(fill = pct_rmse), colour = "white", linewidth = 1.0) +
  geom_text(aes(label = lab, colour = txt_col),
            nudge_y = 0.15, fontface = "bold", size = 3.7) +
  geom_text(aes(label = ci, colour = txt_col),
            nudge_y = -0.22, size = 2.5) +
  scale_fill_gradientn(
    colours = c("#1A5D33", "#4C8C5A", "#9CBF86", "#E7D67A",
                "#E0A03A", "#C0504D", "#8E2A28"),
    limits = c(20, 90), oob = scales::squish,
    name = "%RMSE (lower is better)") +
  scale_colour_identity() +
  scale_x_discrete(position = "top") +
  scale_y_discrete(labels = metric_label) +
  labs(title = title_txt, x = NULL, y = NULL) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    panel.grid       = element_blank(),
    axis.text.x.top  = element_text(size = 11),
    axis.text.y      = element_text(size = 10, hjust = 1),
    axis.ticks       = element_blank(),
    plot.title       = element_text(size = 10.6, face = "bold", hjust = 0),
    legend.position  = "right",
    plot.margin      = margin(10, 14, 10, 10))

ggsave(out_png, p, width = 9.6, height = 7.7, units = "in", dpi = 300, bg = "white")

cat(sprintf("Wrote: %s\n", out_png))
print(dcast(d, metric ~ model, value.var = "pct_rmse"))
