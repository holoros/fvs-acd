# =============================================================================
# Figure 4. Self-thinning is a timing difference, not a permanent divergence.
#
# Two honest panels on two clearly labelled bases.
#   Panel A. Matched Seven Islands stands, first 60 years, identical start. The
#   nine matched stands run under FVS-ACD and OSM from the same year-0 condition
#   (FVS-ACD 31.4, OSM 31.9 m^2 ha^-1). FVS-ACD peaks near 33 m^2 ha^-1 by age
#   10 to 20 and self-thins to 27 by age 60; OSM is still accumulating at age 60
#   (about 42 m^2 ha^-1). The age-60 gap is a 35 percent divergence in self-
#   thinning TIMING, read on the same nine stands.
#     Source: results/seven_islands/fvsacd_vs_osm_matched.csv
#   Panel B. OSM over the full 160-year horizon, real-stand productivity terciles
#   (low, mid, high site). OSM does plateau and self-thin: the mid-site line
#   peaks near 36 m^2 ha^-1 and levels to about 35, so the age-60 snapshot in
#   panel A captures earlier FVS-ACD self-thinning, not a claim that OSM never
#   plateaus.
#     Source: figures/_data/osm_bakuzis_traj_bysite.csv
#       (from Cardinal silc_cfi/osm_150yr_bakuzis/osm_bakuzis_traj_bysite.csv)
#
# The two panels sit on different bases (matched Seven Islands stands vs OSM
# real-stand terciles), so no single mixed-basis line is drawn; each basis is
# stated in its panel and in the caption. Corrected finding: OSM DOES plateau
# and self-thin over the full horizon. No "OSM does not plateau" claim appears.
#
# R-first house standard. A matching matplotlib renderer
# (fig4_selfthinning_trajectory.py) produced the shipped PNG because R was
# unavailable in the build sandbox. This is the reproducible R path.
#
# Trajectories read verbatim from the frozen projections; NOT recomputed. No
# accuracy or benchmark numbers are altered here.
# Author: A. Weiskittel (CRSF-Cowork)
# =============================================================================
suppressMessages({library(tidyverse); library(patchwork)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
matched_f <- file.path(repo, "results/seven_islands/fvsacd_vs_osm_matched.csv")
osm_f     <- file.path(repo, "figures/_data/osm_bakuzis_traj_bysite.csv")
out       <- file.path(repo, "figures/fig4_selfthinning_trajectory.png")

col_fa  <- "#1B9E9E"   # teal   -> FVS-ACD
col_osm <- "#E15554"   # salmon -> OSM
grey    <- "#888888"
ba_lab  <- expression("Basal area (" * m^2 ~ ha^-1 * ")")

# ---- Panel A. matched Seven Islands stands, first 60 years -----------------
m <- read_csv(matched_f, show_col_types = FALSE) |> arrange(Age)
m_long <- m |>
  select(Age, `FVS-ACD` = BA_fa, OSM = BA_osm) |>
  pivot_longer(-Age, names_to = "model", values_to = "BA") |>
  mutate(model = factor(model, levels = c("FVS-ACD", "OSM")))

pA <- ggplot() +
  geom_ribbon(data = m, aes(Age, ymin = BA_fa, ymax = BA_osm),
              fill = col_osm, alpha = 0.08) +
  geom_line(data = m_long, aes(Age, BA, colour = model), linewidth = 1.0) +
  geom_point(data = m_long, aes(Age, BA, colour = model, shape = model), size = 2.4) +
  annotate("text", x = 15, y = 46, hjust = 0, colour = col_osm, fontface = "bold",
           size = 3.3, label = "OSM still accumulating\nat age 60 (about 42)") +
  annotate("text", x = 21, y = 20, hjust = 0, colour = col_fa, fontface = "bold",
           size = 3.3, label = "FVS-ACD self-thins earlier\n(peaks near 33, thins to 27 by age 60)") +
  annotate("text", x = 2, y = 30.5, hjust = 0, colour = "#555555", size = 2.9,
           label = "identical start\n(31.4 vs 31.9)") +
  scale_colour_manual(values = c("FVS-ACD" = col_fa, "OSM" = col_osm), name = NULL) +
  scale_shape_manual(values = c("FVS-ACD" = 16, "OSM" = 15), name = NULL) +
  scale_x_continuous(limits = c(-2, 66)) +
  scale_y_continuous(limits = c(0, 50)) +
  labs(title = "Matched Seven Islands stands, first 60 years",
       x = "Stand age (yr)", y = ba_lab,
       caption = paste("Same nine stands under each model from an identical",
                       "year-0 start.\nThe age-60 gap is a 35% timing difference.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        plot.caption = element_text(colour = "grey40", hjust = 0.5, size = 8),
        legend.position = c(0.08, 0.12), legend.background = element_blank())

# ---- Panel B. OSM over the full 160-year horizon ---------------------------
o <- read_csv(osm_f, show_col_types = FALSE) |>
  mutate(site = factor(site, levels = c("MID", "LOW", "HIGH"),
                       labels = c("OSM mid site", "OSM low site", "OSM high site")))
mid_plateau <- o |> filter(site == "OSM mid site") |> arrange(age) |>
  slice_tail(n = 20) |> summarise(v = mean(BAPH)) |> pull(v)

pB <- ggplot(o, aes(age, BAPH, colour = site, linewidth = site, linetype = site)) +
  annotate("rect", xmin = 0, xmax = 60, ymin = 0, ymax = 50,
           fill = "black", alpha = 0.035) +
  annotate("text", x = 30, y = 3, label = "window shown at left",
           colour = grey, size = 2.8) +
  geom_hline(yintercept = mid_plateau, colour = grey, linewidth = 0.35, linetype = "22") +
  geom_line() +
  annotate("text", x = 74, y = 20.5, hjust = 0, colour = col_osm, fontface = "bold",
           size = 3.3,
           label = sprintf("OSM plateaus over the full horizon\n(mid site levels near %.0f m^2 ha^-1)", mid_plateau)) +
  scale_colour_manual(values = c("OSM mid site" = col_osm,
                                 "OSM low site" = col_osm,
                                 "OSM high site" = col_osm), name = NULL) +
  scale_linewidth_manual(values = c("OSM mid site" = 1.1,
                                    "OSM low site" = 0.6,
                                    "OSM high site" = 0.6), name = NULL) +
  scale_linetype_manual(values = c("OSM mid site" = "solid",
                                   "OSM low site" = "dotted",
                                   "OSM high site" = "dashed"), name = NULL) +
  scale_x_continuous(limits = c(-2, 164)) +
  scale_y_continuous(limits = c(0, 50)) +
  labs(title = "OSM over the full 160-year horizon",
       x = "Stand age (yr)", y = ba_lab,
       caption = paste("OSM real-stand productivity terciles (73 benchmark stands).",
                       "\nAll three level off; the mid site is the panel A analog.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        plot.caption = element_text(colour = "grey40", hjust = 0.5, size = 8),
        legend.position = c(0.80, 0.14), legend.background = element_blank())

fig <- (pA | pB) +
  plot_annotation(
    title = paste("Self-thinning is a timing difference, not a permanent divergence:",
                  "FVS-ACD self-thins earlier, OSM plateaus later"),
    theme = theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5)))

ggsave(out, fig, width = 33, height = 14.2, units = "cm", dpi = 300, bg = "white")
cat("Wrote", out, "\n")
cat("mid-site plateau (last 20 yr):", round(mid_plateau, 1), "m2 ha-1\n")
