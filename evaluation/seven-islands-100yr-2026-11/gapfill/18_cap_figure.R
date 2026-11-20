#!/usr/bin/env Rscript
# Cap check figure: relative density as the model computes it (SDI exponent 1.6, trees >= 10 cm) against the plot brms SDImax.
.libPaths(c("~/Rlib", .libPaths())); suppressPackageStartupMessages({ library(ggplot2); library(jsonlite); library(dplyr) })
O <- path.expand("~/jobs/silc_agmbench_100yr_20261117/final"); j <- fromJSON(file.path(O, "cap_check.json"))
lab <- c(x142sb_ingT0 = "FVS-ACD 14.2 brms SDImax", x143m1l5_ingT0 = "FVS-ACD 14.3, no cap", x143m1l5m2_ingT0 = "FVS-ACD 14.3 + SDImax cap")
d <- bind_rows(lapply(names(j), function(a) bind_rows(lapply(names(j[[a]]), function(y) data.frame(arm = lab[[a]], year = as.integer(y), pct = j[[a]][[y]]$pct_gt_1_01, mx = j[[a]][[y]]$max_rd)))))
d <- tidyr::pivot_longer(d, c(pct, mx)) %>% mutate(name = factor(ifelse(name == "pct", "Plots above relative density 1.0 (%)", "Highest plot relative density"), c("Plots above relative density 1.0 (%)", "Highest plot relative density")), arm = factor(arm, lab))
p <- ggplot(d, aes(year, value, colour = arm)) + geom_line(linewidth = 1) + geom_point(size = 2) + facet_wrap(~name, scales = "free_y") +
  scale_colour_manual(values = c("#CC79A7", "#56B4E9", "#009E73")) + labs(x = "Years after inventory", y = NULL) +
  theme_bw(base_size = 11) + theme(panel.grid.minor = element_blank(), strip.background = element_rect(fill = "#1a3d28", colour = NA),
  strip.text = element_text(colour = "white", face = "bold"), legend.position = "bottom", legend.title = element_blank(), panel.border = element_rect(colour = "#1a3d28"))
ggsave(file.path(O, "fig4_cap_check.png"), p, width = 8.5, height = 4, dpi = 300, bg = "white"); cat("fig4 done\n")
