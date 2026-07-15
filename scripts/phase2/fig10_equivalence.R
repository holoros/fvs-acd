# =============================================================================
# Figure 10. Observed-versus-predicted equivalence plots, FVS-ACD frozen
# benchmark (POOLED_indomain, n = 705).
#
# Rows are metrics (TOTVOL, VALUE, BA), columns are the five models. Each panel
# shows per-stand observed vs predicted, the 1:1 line (dashed), the OLS fit
# observed = a + b * predicted (solid red), and the shaded Robinson & Froese
# (2004) region of equivalence for the slope (the wedge between y = 0.75 x and
# y = 1.25 x, i.e. slope 1 +/- 0.25). Points are coloured by forest type so the
# hardwood scatter is visible. Panels are annotated with the OLS slope b and the
# joint equivalence verdict (both the intercept region, +/- 25% of mean observed,
# and the slope region must pass; flags read from equivalence_frozen.csv).
#
# House standard is R-first (ggplot2). The shipped PNG was rendered by the
# companion Python generator (fig10_equivalence.py) because R was unavailable in
# the build sandbox; this is the canonical ggplot2 reproduction. Frozen slope /
# intercept / flags are read as-is and not recomputed.
#
# Author: Aaron Weiskittel workspace (CRSF-Cowork)
# =============================================================================

suppressPackageStartupMessages({
  need <- c("data.table", "ggplot2", "ggtext")
  miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss)) install.packages(miss, repos = "https://cloud.r-project.org")
  library(data.table); library(ggplot2)
})

repo    <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
obspred <- file.path(repo, "figures", "_data", "fig10_obspred_pooled.csv")
eq_csv  <- file.path(repo, "data", "equivalence_frozen.csv")
out_png <- file.path(repo, "figures", "fig10_equivalence.png")

models  <- c("v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM")
metrics <- c("TOTVOL", "VALUE", "BA")
metric_lab <- c(
  TOTVOL = "Observed total volume (m^3~ha^-1)",
  VALUE  = "Observed stand value ($~ha^-1)",
  BA     = "Observed basal area (m^2~ha^-1)")
ft_col <- c(Softwood = "#2C7FB8", Mixedwood = "#8C6BB1", Hardwood = "#D95F0E")

op <- fread(obspred)
op[, metric := factor(metric, levels = metrics)]
op[, model  := factor(model,  levels = models)]
op[, fortype := factor(fortype, levels = names(ft_col))]

eq <- fread(eq_csv)[stratum == "POOLED_indomain" & metric %chin% metrics]
eq[, metric := factor(metric, levels = metrics)]
eq[, model  := factor(model,  levels = models)]
eq[, verdict := ifelse(overall_equiv, "equivalent", "not equivalent")]
eq[, ann := sprintf("b = %.2f\n%s", slope, verdict)]

# per-metric upper limit (shared obs/pred scale), for the wedge + 1:1 line
lims <- op[, .(vmax = 1.02 * quantile(c(obs, pred), 0.995, na.rm = TRUE)),
           by = metric]
wedge <- lims[, .(x = c(0, vmax), lo = c(0, 0.75 * vmax), hi = c(0, 1.25 * vmax)),
              by = metric]
diag  <- lims[, .(x = c(0, vmax), y = c(0, vmax)), by = metric]

p <- ggplot() +
  geom_ribbon(data = wedge, aes(x = x, ymin = lo, ymax = hi),
              fill = "#BBBBBB", alpha = 0.30) +
  geom_line(data = diag, aes(x = x, y = y),
            colour = "#333333", linetype = "dashed", linewidth = 0.5) +
  geom_point(data = op, aes(x = pred, y = obs, colour = fortype),
             size = 0.7, alpha = 0.45) +
  geom_abline(data = eq, aes(slope = slope, intercept = intercept),
              colour = "#B2182B", linewidth = 0.8) +
  geom_text(data = eq, aes(x = -Inf, y = Inf, label = ann),
            hjust = -0.08, vjust = 1.1, size = 2.9, fontface = "bold",
            lineheight = 0.95) +
  facet_grid(metric ~ model, scales = "free", switch = "y") +
  scale_colour_manual(values = ft_col, name = "Forest type") +
  coord_cartesian(expand = FALSE) +
  labs(
    title = paste0("Figure 10. Observed vs predicted with the Robinson & Froese ",
                   "region of equivalence (POOLED in-domain, n = 705)"),
    subtitle = paste0("Joint verdict requires both slope (1 +/- 0.25) and ",
                      "intercept (within +/-25% of mean observed) inside their ",
                      "equivalence regions"),
    x = "Predicted", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "grey92", linewidth = 0.3),
    panel.spacing    = unit(0.5, "lines"),
    strip.text       = element_text(face = "bold", size = 10),
    strip.placement  = "outside",
    plot.title       = element_text(face = "bold", size = 11.5),
    legend.position  = "bottom")

ggsave(out_png, p, width = 15.5, height = 9.6, units = "in", dpi = 300, bg = "white")

cat(sprintf("Wrote: %s\n", out_png))
print(eq[order(metric, model),
         .(metric, model, slope, intercept, r2, slope_equiv,
           intercept_equiv, overall_equiv)])
