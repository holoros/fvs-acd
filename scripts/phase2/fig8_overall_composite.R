# fig8_overall_composite.R  (R-first companion; the shipped PNG was rendered by
# fig8_overall_composite.py because R is unavailable in the build sandbox, as with fig1).
#
# Figure 8. Volume and value weighted overall composite score by model: pooled in-domain
# PRIMARY composite (total volume and value carry the highest weight) as ranked horizontal
# bars, with the equal-weight composite drawn as a reference tick on each bar and the
# by-forest-type primary composites overlaid as markers.
# Scores read straight from data/composite_scores_frozen.csv (NOT recomputed).
suppressMessages({library(tidyverse)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
d <- readr::read_csv(file.path(repo, "data", "composite_scores_frozen.csv"),
                     show_col_types = FALSE)

pooled <- d |> filter(stratum == "POOLED_indomain") |> arrange(composite_primary)
lev <- pooled$model
ft <- d |> filter(stratum %in% c("Softwood","Mixedwood","Hardwood")) |>
  mutate(model = factor(model, levels = lev),
         stratum = factor(stratum, levels = c("Softwood","Mixedwood","Hardwood")))
pooled <- pooled |> mutate(model = factor(model, levels = lev))

ft_col <- c(Softwood = "#1B7837", Mixedwood = "#7B3294", Hardwood = "#B35806")

p <- ggplot() +
  geom_col(data = pooled, aes(composite_primary, model),
           fill = "#3B6B8F", width = 0.62) +
  geom_text(data = pooled, aes(composite_primary - 1.2, model,
            label = sprintf("%.1f", composite_primary)),
            hjust = 1, color = "white", fontface = "bold", size = 3.6) +
  geom_point(data = pooled, aes(composite_equalweight, model),
             shape = 124, size = 6, stroke = 1.4, color = "#22384A") +
  geom_point(data = ft, aes(composite_primary, model, color = stratum, shape = stratum),
             size = 3, stroke = 0.6) +
  scale_color_manual(values = ft_col, name = NULL) +
  scale_shape_manual(values = c(Softwood = 16, Mixedwood = 15, Hardwood = 17), name = NULL) +
  scale_x_continuous(limits = c(0, 100)) +
  labs(title = "Figure 8. Volume and value weighted overall composite score by model (pooled bars, equal-weight ticks, forest-type markers)",
       x = "Overall composite score (0 to 100, higher is better)", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.major.y = element_blank(),
        legend.position = c(0.85, 0.15),
        plot.title = element_text(face = "bold"))

ggsave(file.path(repo, "figures", "fig8_overall_composite.png"), p,
       width = 10, height = 6.2, dpi = 300, bg = "white")
