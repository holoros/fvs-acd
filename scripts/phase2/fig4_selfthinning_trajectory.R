# =============================================================================
# Figure 4. Long-horizon self-thinning trajectories on matched stands.
#
# Basal area (m^2 ha^-1) over a 160 yr projection from an identical start, three
# matched sites (12, 16, 20), four version entrants. v12.5.0 never self-thins
# (~65 m^2 ha^-1); v12.7.1 and v12.9.x converge to ~36 m^2 ha^-1 (lines overlap
# by design). Okabe-Ito colorblind-safe palette; v12.9.x dashed so it reads over
# the overlapping v12.7.1.
#
# R-first house standard. A matching matplotlib renderer
# (fig4_selfthinning_trajectory.py) produced the shipped PNG because R was
# unavailable in the build sandbox. This is the reproducible R path.
#
# Trajectories read verbatim from the frozen projection; NOT recomputed.
#   Source: figures/_data/bakuzis_traj_allmodels.csv
# Author: A. Weiskittel (CRSF-Cowork)
# =============================================================================
suppressMessages({library(tidyverse)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data <- file.path(repo, "figures/_data/bakuzis_traj_allmodels.csv")
out  <- file.path(repo, "figures/fig4_selfthinning_trajectory.png")

model_order <- c("v125", "v1270", "v1271", "v129x")
model_lab   <- c(v125 = "v12.5.0", v1270 = "v12.7.0",
                 v1271 = "v12.7.1", v129x = "v12.9.x")
model_col   <- c("v12.5.0" = "#E69F00", "v12.7.0" = "#0072B2",
                 "v12.7.1" = "#009E73", "v12.9.x" = "#000000")
model_lty   <- c("v12.5.0" = "solid", "v12.7.0" = "solid",
                 "v12.7.1" = "solid", "v12.9.x" = "22")

d <- read_csv(data, show_col_types = FALSE) |>
  filter(model %in% model_order, site %in% c(12, 16, 20)) |>
  mutate(model = factor(model_lab[model], levels = unname(model_lab)),
         site  = factor(paste("Site", site),
                        levels = paste("Site", c(12, 16, 20))))

p <- ggplot(d, aes(age, BAPH, colour = model, linetype = model)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~ site, nrow = 1) +
  scale_colour_manual(values = model_col, name = NULL) +
  scale_linetype_manual(values = model_lty, name = NULL) +
  scale_x_continuous(limits = c(0, 162), expand = expansion(mult = c(0.01, 0.02))) +
  labs(title = paste("Long horizon: early FVS-ACD runs away, v12.7.1 onward",
                     "self-thins to a realistic plateau"),
       caption = paste0("Basal area over a 160 yr projection. v12.5.0 never ",
                        "self-thins (runs to about 65 m² ha⁻¹); ",
                        "v12.7.1 and v12.9.x plateau near 36 m² ha⁻¹."),
       x = "Stand age (yr)",
       y = expression("Basal area (" * m^2 ~ ha^-1 * ")")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", size = 12),
        plot.title = element_text(face = "bold", size = 13),
        plot.caption = element_text(colour = "grey40", hjust = 0.5, size = 9),
        legend.position = c(0.055, 0.86),
        legend.background = element_blank())

ggsave(out, p, width = 33, height = 13, units = "cm", dpi = 300, bg = "white")
cat("Wrote", out, "\n")
d |> group_by(site, model) |>
  summarise(BA_end = last(BAPH[order(age)]), .groups = "drop") |> print(n = 99)
