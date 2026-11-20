#!/usr/bin/env Rscript
# SILC products figure (fig5): merchantable cords, sawlog MBF, stumpage value and aboveground live carbon over 100 years, five primary arms,
# means with 95% stand-cluster bootstrap bands. Same palette and theme as 16_final_figures.R. Headless, 300 dpi.
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(ggplot2); library(dplyr) })
O <- path.expand("~/jobs/silc_agmbench_100yr_20261117/final")
T <- read.csv(file.path(O, "products_trajectory.csv"))
prim <- c("OSM 2.26.1", "FVS-NE", "FVS-ACD 12.5.2 production", "FVS-ACD 14.2 brms SDImax", "FVS-ACD 14.3 + SDImax cap")
pal <- setNames(c("#0072B2", "#E69F00", "#999999", "#CC79A7", "#009E73"), prim)
th <- theme_bw(base_size = 11) + theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#E6ECEF", linewidth = 0.3),
  strip.background = element_rect(fill = "#1a3d28", colour = NA), strip.text = element_text(colour = "white", face = "bold"),
  legend.position = "bottom", legend.title = element_blank(), panel.border = element_rect(colour = "#1a3d28"))
lab <- c(tot_cd = "Merchantable~volume~(cords~ac^-1)", saw_mbf = "Sawlog~volume~(MBF~ac^-1)",
         val = "Stumpage~value~('$'~ac^-1*','~2024)", co2e_tac = "Aboveground~carbon~(t~CO[2]*e~ac^-1)")
d <- T %>% filter(arm %in% prim, metric %in% names(lab)) %>% mutate(arm = factor(arm, prim), panel = factor(lab[metric], lab))
p <- ggplot(d, aes(year, mean, colour = arm, fill = arm)) + geom_ribbon(aes(ymin = lo95, ymax = hi95), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.4) + expand_limits(y = 0) +
  facet_wrap(~panel, scales = "free_y", ncol = 2, labeller = label_parsed) + scale_colour_manual(values = pal) + scale_fill_manual(values = pal) +
  scale_x_continuous(breaks = c(0, 25, 50, 75, 100)) + labs(x = "Years after inventory", y = NULL) + th + guides(colour = guide_legend(nrow = 2))
ggsave(file.path(O, "fig5_products.png"), p, width = 8.5, height = 7, dpi = 300, bg = "white")
cat("fig5 done\n")
