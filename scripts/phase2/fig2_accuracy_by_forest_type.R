# =============================================================================
# Figure 2. Total volume level bias by forest type.
#
# Total volume level bias (%) for softwood, mixedwood, hardwood across the five
# entrants (v12.5.0, v12.7.0, v12.7.1, v12.9.x, OSM v2.26.1). Shaded band is the
# +/- 10% equivalence region; a check mark flags a cell statistically equivalent
# to observed under TOST. Bias rises softwood -> mixedwood -> hardwood in every
# model (the shared composition-driven hardwood frontier).
#
# R-first house standard. A matching matplotlib renderer
# (fig2_accuracy_by_forest_type.py) produced the shipped PNG because R was
# unavailable in the build sandbox. This is the reproducible R path.
#
# Bias and TOST flags read verbatim; NOT recomputed.
#   Source: results/seven_islands/scorecard_clean_all.csv (cut==fortype, TOTVOL)
# Author: A. Weiskittel (CRSF-Cowork)
# =============================================================================
suppressMessages({library(tidyverse)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data <- file.path(repo, "results/seven_islands/scorecard_clean_all.csv")
out  <- file.path(repo, "figures/fig2_accuracy_by_forest_type.png")

types  <- c("Softwood", "Mixedwood", "Hardwood")
mods   <- c("v125", "v1270", "v1271", "v129x", "osm")
mlab   <- c(v125 = "FVS v12.5.0", v1270 = "FVS v12.7.0", v1271 = "FVS v12.7.1",
            v129x = "FVS v12.9.x", osm = "OSM v2.26.1")
mcol   <- c("FVS v12.5.0" = "#B8B8B8", "FVS v12.7.0" = "#A6D3A0",
            "FVS v12.7.1" = "#6FB07F", "FVS v12.9.x" = "#2C7A3F",
            "OSM v2.26.1" = "#B4443B")

d <- read_csv(data, show_col_types = FALSE) |>
  filter(cut == "fortype", metric == "TOTVOL", subset %in% types,
         model %in% mods) |>
  mutate(subset = factor(subset, levels = types),
         model  = factor(mlab[model], levels = unname(mlab)),
         tost   = as.logical(tost_lvl_equiv),
         ylab_y = if_else(bias_pct >= 0, bias_pct + 1.4, bias_pct - 3.0))

p <- ggplot(d, aes(subset, bias_pct, fill = model)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -10, ymax = 10,
           fill = "#6FB07F", alpha = 0.12) +
  geom_hline(yintercept = 0, colour = "grey20", linewidth = 0.4) +
  geom_col(position = position_dodge(width = 0.86), width = 0.8,
           colour = "grey20", linewidth = 0.2) +
  geom_text(data = filter(d, tost),
            aes(y = ylab_y, group = model), label = "✓",
            position = position_dodge(width = 0.86),
            colour = "#1F5C2E", fontface = "bold", size = 4) +
  scale_fill_manual(values = mcol, name = NULL) +
  scale_y_continuous(limits = c(-16, 50)) +
  labs(title = "Bias is composition-driven: total volume by forest type",
       subtitle = paste("Shaded band is the equivalence region (±10%);",
                        "a check mark is statistically equivalent to observed (TOST)."),
       x = NULL, y = "Total volume level bias (%)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(colour = "grey35", size = 10),
        legend.position = "top")

ggsave(out, p, width = 28, height = 14, units = "cm", dpi = 300, bg = "white")
cat("Wrote", out, "\n")
print(d |> select(subset, model, bias_pct, tost))
