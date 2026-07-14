# =============================================================================
# Figure 6. Managed-cell out-of-sample bias by management class.
#
# Mean absolute level bias (percent), averaged across the nine NSVB metrics,
# under leave-one-installation-out (LOIO) cross-validation of the management
# modifier, for v12.9.x (gate off), v12.10.1 (gate on), and OSM, split by
# management class (Planted, PCT, Managed = Planted + PCT pooled).
#
# House standard is R-first (ggplot2). Values are read straight from the FROZEN
# leave-one-installation-out cross-validation on Cardinal and are NOT recomputed
# here. Source of truth:
#   ~/magplot/verify/mgmt_cv_frozen.R  ->  mgmt_cv_frozen.out
#   ("== FROZEN LOIO (leave-one-installation-out) additive CV ==",
#    the absMAE oos / v129x / osm columns)
# mirrored into figures/_data/fig6_mgmt_oos_mab_frozen.csv for provenance.
#
# The OSM bars are independent of the FVS-ACD freeze (OSM is an external model),
# so they are unchanged from the pre-freeze figure; only the v12.9.x and
# v12.10.1 bars move with the frozen harness.
#
# NOTE: The shipped PNG in this repo was rendered by the companion Python
# generator (fig6_managed_oos_bias.py) because R was not available in the build
# sandbox (no root for apt; network behind a deny-all allowlist blocked CRAN).
# This script is the canonical ggplot2 reproduction and produces the
# content-equivalent figure wherever R + ggplot2 exist.
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
repo     <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data_csv <- file.path(repo, "figures", "_data", "fig6_mgmt_oos_mab_frozen.csv")
out_png  <- file.path(repo, "figures", "fig6_managed_oos_bias.png")

# ---- Frozen LOIO values (read as-is; do NOT recompute) ----------------------
classes <- c("Planted", "PCT", "Managed")
models  <- c("v12.9.x", "v12.10.1", "OSM")

d <- fread(data_csv)
d[, class := factor(class, levels = classes)]
d[, model := factor(model, levels = models)]

# Bar palette matched to the pre-freeze fig6 (grey / green / red)
bar_fill <- c("v12.9.x" = "#888888", "v12.10.1" = "#2C7A3F", "OSM" = "#B4443B")

# Sample counts for the class axis labels (from the frozen harness)
class_lab <- c(Planted = "Planted\n(n=51)",
               PCT     = "PCT\n(n=95)",
               Managed = "Managed\n(n=146)")

# ---- Plot -------------------------------------------------------------------
title_txt <- "Management modifiers close the managed cell"
sub_txt   <- paste0("Out-of-sample mean absolute bias across nine NSVB metrics, ",
                    "leave one installation out")

p <- ggplot(d, aes(x = class, y = mab_oos_loio, fill = model)) +
  geom_col(position = position_dodge(0.74), width = 0.68,
           colour = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.1f", mab_oos_loio)),
            position = position_dodge(0.74), vjust = -0.35, size = 3.3) +
  scale_fill_manual(values = bar_fill, name = NULL) +
  scale_x_discrete(labels = class_lab) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.10))) +
  labs(title = title_txt, subtitle = sub_txt,
       x = NULL, y = "Mean absolute bias (%)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.x  = element_text(size = 11),
    axis.title.y = element_text(size = 11),
    plot.title    = element_text(size = 13, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 9.5, hjust = 0),
    legend.position = "top",
    legend.text     = element_text(size = 10),
    plot.margin     = margin(10, 14, 8, 10)
  )

ggsave(out_png, p, width = 9, height = 5.2, units = "in", dpi = 300, bg = "white")

# ---- Verification -----------------------------------------------------------
cat(sprintf("Wrote: %s\n\n", out_png))
print(d[order(class, model), .(class, model, mab_oos_loio)])
