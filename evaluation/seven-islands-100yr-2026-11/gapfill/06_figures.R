#!/usr/bin/env Rscript
# Seven Islands 100-year comparison figures from aggregate files only. Headless, color, 300 dpi.
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(ggplot2); library(dplyr) })
A <- path.expand("~/jobs/silc_agmbench_100yr_20261117/agg")
T <- read.csv(file.path(A, "overall_trajectory.csv")); S <- read.csv(file.path(A, "strata_summary.csv"))
ord <- c("OSM", "FVS-NE", "FVS-ACD native", "ACD 12.5.2 production", "ACD 14.2 brms SDImax", "ACD v12.11.1", "ACD v13.1 base", "ACD v14.0.4 L2", "ACD v14.1 L2L")
pal <- setNames(c("#0072B2", "#E69F00", "#999933", "#D55E00", "#CC79A7", "#56B4E9", "#009E73", "#882255", "#332288"), ord)
theme_silc <- theme_bw(base_size = 10) + theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#E6ECEF", linewidth = 0.3),
  strip.background = element_rect(fill = "#1F4E3D", colour = NA), strip.text = element_text(colour = "white", face = "bold"),
  legend.position = "bottom", legend.title = element_blank(), panel.border = element_rect(colour = "#1F4E3D"))
lab <- c(ba_ft2ac = "Basal~area~(ft^2~ac^-1)", tpa = "Trees~ac^-1", qmd_in = "Quadratic~mean~diameter~('in')", sdi = "Stand~density~index~(trees~ac^-1)")
d <- T %>% filter(model %in% ord, metric %in% names(lab)) %>% mutate(model = factor(model, ord), panel = factor(lab[metric], lab))
p1 <- ggplot(d, aes(year, mean, colour = model, fill = model)) + geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.12, colour = NA) + geom_line(linewidth = 0.7) +
  facet_wrap(~panel, scales = "free_y", ncol = 2, labeller = label_parsed) + scale_colour_manual(values = pal) + scale_fill_manual(values = pal) +
  labs(x = "Projection year", y = NULL) + theme_silc + guides(colour = guide_legend(nrow = 3))
ggsave(file.path(A, "2026-11-18_seven-islands-100yr-trajectories_DRAFT.png"), p1, width = 7.5, height = 7, dpi = 300)
s <- S %>% filter(model %in% ord, year_offset == 100) %>% mutate(model = factor(model, rev(ord)), matrix = paste0(matrix, " (", n_stands, ")"))
p2 <- ggplot(s, aes(matrix, model, fill = ba_ft2ac)) + geom_tile(colour = "white") + geom_text(aes(label = round(ba_ft2ac)), size = 2.6, colour = "black") +
  scale_fill_viridis_c(option = "D", begin = 0.25, name = expression(Basal~area~at~year~100~(ft^2~ac^-1))) +
  labs(x = "Stratum (stands)", y = NULL) + theme_silc + theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.key.width = unit(1.2, "cm"))
ggsave(file.path(A, "2026-11-18_seven-islands-100yr-strata-ba100_DRAFT.png"), p2, width = 7.5, height = 4.8, dpi = 300)
ing <- T %>% filter(grepl("12.5.2|14.2", model), metric %in% names(lab)) %>% mutate(panel = factor(lab[metric], lab))
if (length(unique(ing$model)) == 4) {
  p3 <- ggplot(ing, aes(year, mean, colour = model, fill = model)) + geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.12, colour = NA) + geom_line(linewidth = 0.7) +
    facet_wrap(~panel, scales = "free_y", ncol = 2, labeller = label_parsed) + scale_colour_manual(values = c("#D55E00", "#E69F00", "#CC79A7", "#882255")) +
    scale_fill_manual(values = c("#D55E00", "#E69F00", "#CC79A7", "#882255")) + labs(x = "Projection year", y = NULL) + theme_silc + guides(colour = guide_legend(nrow = 2))
  ggsave(file.path(A, "2026-11-18_seven-islands-100yr-ingrowth-switch_DRAFT.png"), p3, width = 7.5, height = 7, dpi = 300) }
cat("figures done\n")
