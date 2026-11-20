#!/usr/bin/env Rscript
# Seven Islands Bakuzis figures from bakz_out/ (stand-level trajectories, no identifiers). One 6-panel matrix per arm and a scorecard.
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(ggplot2); library(dplyr); library(tidyr) })
O <- path.expand("~/jobs/silc_agmbench_100yr_20261117/bakz_out")
pal <- c("12" = "#D69500", "15" = "#007D5D", "18" = "#1475A2")
th <- theme_bw(base_size = 9) + theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = "#E6ECEF", linewidth = 0.3),
  strip.background = element_rect(fill = "#1F4E3D", colour = NA), strip.text = element_text(colour = "white", face = "bold"),
  legend.position = "bottom", panel.border = element_rect(colour = "#1F4E3D"), plot.title = element_text(face = "bold", colour = "#1F4E3D"))
arms <- c(osm = "OSM 2.26.1", fvs_ne = "FVS-NE", prod = "ACD 12.5.2 production", x142 = "ACD 14.2 brms SDImax",
          l5 = "ACD 14.3 hazard ln5", l5m2 = "ACD 14.3 hazard ln5 + cap", l0 = "ACD 14.3 hazard L0", l0m2 = "ACD 14.3 hazard L0 + cap")
for (s in names(arms)) {
  f <- file.path(O, paste0("traj_", s, ".csv")); if (!file.exists(f)) next
  d <- read.csv(f) %>% mutate(site = factor(site), BA = BAPH * 4.356)
  m <- d %>% group_by(site, year) %>% summarise(across(c(HT, TPH, QMD, VOL, BAPH), mean), lTPH = exp(mean(log(TPH))), lQMD = exp(mean(log(QMD))), .groups = "drop")
  pan <- function(dd, x, y, xl, yl, logxy = FALSE, thin = TRUE) {
    p <- ggplot() + { if (thin) geom_path(data = d, aes(.data[[x]], .data[[y]], colour = site, group = interaction(label, site)), alpha = 0.12, linewidth = 0.3) } +
      geom_path(data = dd, aes(.data[[x]], .data[[y]], colour = site), linewidth = 1.1) + scale_colour_manual(values = pal, name = "Climate site index (m)") +
      labs(x = xl, y = yl) + th + theme(legend.position = "none")
    if (logxy) p <- p + scale_x_log10() + scale_y_log10()
    p }
  ps <- list(
    pan(m, "year", "HT", "Projection year", "Top height (m)") + ggtitle("1. Site curves"),
    pan(m, "year", "TPH", "Projection year", expression(Stems~ha^-1)) + ggtitle("3. Sukachev"),
    pan(m %>% mutate(QMD = lQMD, TPH = lTPH), "QMD", "TPH", "Quadratic mean diameter (cm)", expression(Stems~ha^-1), TRUE) + ggtitle("4. Reineke") +
      geom_abline(intercept = log10(1000 * 25.4^1.605) - 0, slope = -1.605, linetype = 2, colour = "#888888"),
    pan(m, "HT", "VOL", "Top height (m)", expression(Volume~(m^3~ha^-1))) + ggtitle("8. Eichhorn"),
    pan(m, "year", "BAPH", "Projection year", expression(Basal~area~(m^2~ha^-1))) + ggtitle("Basal area"),
    pan(m, "TPH", "VOL", expression(Stems~ha^-1), expression(Volume~(m^3~ha^-1))) + ggtitle("9. Yield-density"))
  leg <- cowplot::get_legend(ps[[1]] + theme(legend.position = "bottom"))
  g <- cowplot::plot_grid(cowplot::plot_grid(plotlist = ps, ncol = 3), leg, ncol = 1, rel_heights = c(1, 0.07))
  g <- cowplot::plot_grid(cowplot::ggdraw() + cowplot::draw_label(paste(arms[[s]], "| Seven Islands Bakuzis, 25 stands x 3 site levels"), fontface = "bold", colour = "#1F4E3D", size = 12), g, ncol = 1, rel_heights = c(0.05, 1))
  ggsave(file.path(O, sprintf("2026-11-19_seven-islands-bakuzis-%s_DRAFT.png", s)), g, width = 9, height = 6.6, dpi = 300, bg = "white")
}
r <- read.csv(file.path(O, "relations_by_arm.csv"))
sc <- r %>% transmute(arm, `HT monotone` = ht_monotone_pct, `HT site order` = ht_site_order_all_pct, `VOL site order` = vol_site_order_all_pct,
  `Sukachev` = sukachev_50_pct, `Reineke in band` = reineke_in_band_pct, `Eichhorn` = eichhorn_pass_pct, `Below brms SDImax` = 100 - stands_rd_brms_gt1_pct,
  `No late VOL decline` = 100 - vol_late_decline_pct) %>% pivot_longer(-arm, names_to = "relation", values_to = "pct") %>%
  mutate(arm = factor(arm, rev(arms)), relation = factor(relation, unique(relation)))
p <- ggplot(sc, aes(relation, arm, fill = pct)) + geom_tile(colour = "white") + geom_text(aes(label = round(pct)), size = 2.8) +
  scale_fill_gradient2(low = "#B2182B", mid = "#F7E9A0", high = "#1B7837", midpoint = 70, limits = c(0, 100), name = "Stands or trajectories passing (%)") +
  labs(x = NULL, y = NULL) + th + theme(axis.text.x = element_text(angle = 35, hjust = 1), legend.key.width = unit(1.2, "cm"))
ggsave(file.path(O, "2026-11-19_seven-islands-bakuzis-scorecard_DRAFT.png"), p, width = 7.5, height = 4.6, dpi = 300, bg = "white")
cat("figures done\n")
