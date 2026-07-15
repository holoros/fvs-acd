# fig7_scorecard_by_fortype.R  (R-first companion; the shipped PNG was rendered by
# fig7_scorecard_by_fortype.py because R is unavailable in the build sandbox, as with fig1).
#
# Figure 7. Forest-type scorecard: faceted tile heatmap of level bias (percent) with
# bootstrap 95 percent CIs and green/yellow/red flags, nine metrics by five models,
# faceted by forest type (Softwood, Mixedwood, Hardwood) on the frozen basis.
# Scores read straight from data/scorecard_five_by_fortype_frozen.csv (NOT recomputed).
suppressMessages({library(tidyverse); library(ggtext)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
d <- readr::read_csv(file.path(repo, "data", "scorecard_five_by_fortype_frozen.csv"),
                     show_col_types = FALSE)

models  <- c("v12.5.0","v12.7.0","v12.9.x","v12.10.1","OSM")
metrics <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
mlab <- c(BA="Basal area (BA)", SDI="Stand density index (SDI)",
          QMD="Quad. mean diameter (QMD)", TOPHT="Top height (TOPHT)",
          TOTVOL="Total volume (TOTVOL)", MERCHVOL="Merch volume (MERCHVOL)",
          SAWVOL="Sawlog volume (SAWVOL)", BIOMASS="Aboveground biomass (BIOMASS)",
          VALUE="Stand value (VALUE)")
flag_fill <- c(green="#4C8C5A", yellow="#E0B33A", red="#C0504D")

d <- d |>
  mutate(model = factor(model, levels = models),
         metric = factor(metric, levels = rev(metrics), labels = rev(mlab[metrics])),
         fortype = factor(fortype, levels = c("Softwood","Mixedwood","Hardwood")),
         lab = sprintf("%+.1f%%\n[%.0f, %.0f]", bias_pct, bias_lo95, bias_hi95),
         txt = if_else(flag == "yellow", "#111111", "#FFFFFF"))

p <- ggplot(d, aes(model, metric, fill = flag)) +
  geom_tile(color = "white", linewidth = 1.1) +
  geom_text(aes(label = lab, color = I(txt)), size = 2.7, lineheight = 0.9) +
  facet_wrap(~ fortype, nrow = 1) +
  scale_fill_manual(values = flag_fill,
    breaks = c("green","yellow","red"),
    labels = c("green  |bias| < 5% and NSE > 0.6", "yellow  intermediate",
               "red  |bias| >= 10% or NSE < 0.4"), name = NULL) +
  scale_x_discrete(position = "top") +
  labs(title = "Figure 7. Forest-type scorecard: level bias percent with 95% CIs and flags (frozen basis)",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom",
        panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 11),
        plot.title = element_text(face = "bold"))

ggsave(file.path(repo, "figures", "fig7_scorecard_by_fortype.png"), p,
       width = 16.5, height = 7.4, dpi = 300, bg = "white")
