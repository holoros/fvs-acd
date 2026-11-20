#!/usr/bin/env Rscript
# Seven Islands deck and report figures from final/ aggregates. Headless, color, 300 dpi, colorblind-safe (Okabe-Ito).
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(tidyr) })
O <- path.expand("~/jobs/silc_agmbench_100yr_20261117/final")
T <- read.csv(file.path(O, "trajectory.csv")); S <- read.csv(file.path(O, "strata.csv")); Y <- read.csv(file.path(O, "year100_summary.csv"))
prim <- c("OSM 2.26.1", "FVS-NE", "FVS-ACD 12.5.2 production", "FVS-ACD 14.2 brms SDImax", "FVS-ACD 14.3 + SDImax cap")
pal <- setNames(c("#0072B2", "#E69F00", "#999999", "#CC79A7", "#009E73"), prim)
th <- theme_bw(base_size = 11) + theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#E6ECEF", linewidth = 0.3),
  strip.background = element_rect(fill = "#1a3d28", colour = NA), strip.text = element_text(colour = "white", face = "bold"),
  legend.position = "bottom", legend.title = element_blank(), panel.border = element_rect(colour = "#1a3d28"))
lab <- c(ba_ft2ac = "Basal~area~(ft^2~ac^-1)", tpa = "Trees~ac^-1", qmd_in = "Quadratic~mean~diameter~('in')", rd = "Relative~density~(all-stem~SDI)")
d <- T %>% filter(arm %in% prim, metric %in% names(lab)) %>% mutate(arm = factor(arm, prim), panel = factor(lab[metric], lab))
p1 <- ggplot(d, aes(year, mean, colour = arm, fill = arm)) + geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.15, colour = NA) + geom_line(linewidth = 0.9) +
  facet_wrap(~panel, scales = "free_y", ncol = 2, labeller = label_parsed) + scale_colour_manual(values = pal) + scale_fill_manual(values = pal) +
  labs(x = "Years after inventory", y = NULL) + th + guides(colour = guide_legend(nrow = 2))
ggsave(file.path(O, "fig1_trajectories.png"), p1, width = 8.5, height = 7, dpi = 300, bg = "white")
s <- S %>% filter(arm %in% prim, year_offset == 100) %>% mutate(arm = factor(arm, rev(prim)), stratum = paste0(stratum, " (", n_stands, ")"))
p2 <- ggplot(s, aes(stratum, arm, fill = ba)) + geom_tile(colour = "white") + geom_text(aes(label = round(ba)), size = 3.1) +
  scale_fill_viridis_c(option = "D", begin = 0.25, name = expression(Basal~area~at~year~100~(ft^2~ac^-1))) +
  labs(x = "Stratum (stands)", y = NULL) + th + theme(axis.text.x = element_text(angle = 40, hjust = 1), legend.title = element_text(), legend.key.width = unit(1.4, "cm"))
ggsave(file.path(O, "fig2_strata_ba100.png"), p2, width = 9, height = 4.6, dpi = 300, bg = "white")
ord <- c("FVS-ACD 12.5.2 production", "FVS-ACD 12.5.2 + ingrowth", "FVS-ACD 14.2 brms SDImax", "FVS-ACD 14.3, no cap", "FVS-ACD 14.3 + SDImax cap", "OSM 2.26.1", "FVS-NE")
y <- T %>% filter(arm %in% ord, year == 100, metric %in% names(lab)) %>% mutate(arm = factor(arm, rev(ord)), panel = factor(lab[metric], lab),
  grp = ifelse(grepl("FVS-ACD", arm), "FVS-ACD configurations", "Reference models"))
p3 <- ggplot(y, aes(mean, arm, colour = grp)) + geom_errorbarh(aes(xmin = lo95, xmax = hi95), height = 0.25, linewidth = 0.7) + geom_point(size = 2.4) +
  facet_wrap(~panel, scales = "free_x", ncol = 2, labeller = label_parsed) + scale_colour_manual(values = c("FVS-ACD configurations" = "#009E73", "Reference models" = "#0072B2")) +
  labs(x = "Mean at year 100 (95% stand-cluster bootstrap)", y = NULL) + th
ggsave(file.path(O, "fig3_configurations_y100.png"), p3, width = 9, height = 6, dpi = 300, bg = "white")
cat("figures done\n")
