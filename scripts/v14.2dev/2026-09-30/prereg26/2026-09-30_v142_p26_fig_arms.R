## PREREG26 reported figure (not gated): top height and NSVB volume over 100 years for all five arms, N0 3,000 stems per ha,
## ESI 9 and 18 m. Reads the follow up 5 year trajectory table. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) })
d <- fread("/home/aaron/jobs/v142p26/assembled/followup/gyr142-p26-traj-5yr_DATA_2026-09-30.csv")[n0 == 3000 & esi %in% c(9, 18)]
d[, arm := factor(arm, levels = c("v141LT", "v141LTf", "v141LTi", "v141LTfi", "v141LTfi5"),
  labels = c("14.1 (v141LT)", "Height form only (v141LTf)", "Threshold match only (v141LTi)", "Both, 9.1 cm (v141LTfi)", "Both, 5.0 cm (v141LTfi5)"))]
d[, mixl := factor(mix, levels = c("BF", "RS", "MX"), labels = c("Balsam fir", "Red spruce", "Mixed"))]
d[, esil := factor(paste0("ESI ", esi, " m"), levels = c("ESI 9 m", "ESI 18 m"))]
L <- rbind(d[, .(arm, mixl, esil, age, val = HT, var = "Top~height~(m)")], d[, .(arm, mixl, esil, age, val = VOL, var = "Volume~(m^3~ha^{-1})")])
p <- ggplot(L, aes(age, val, colour = arm, linetype = esil)) + geom_line(linewidth = 0.55) +
  facet_grid(var ~ mixl, scales = "free_y", switch = "y", labeller = labeller(var = label_parsed)) +
  scale_colour_manual(values = c("#1b1b1b", "#2166ac", "#b2182b", "#4d9221", "#e08214"), name = NULL) +
  scale_linetype_manual(values = c("dashed", "solid"), name = NULL) +
  guides(colour = guide_legend(nrow = 2)) + labs(x = "Projection year", y = NULL) + theme_classic(base_size = 10) +
  theme(strip.placement = "outside", strip.background = element_blank(), legend.position = "bottom", legend.box = "vertical",
        panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.3))
ggsave("gyr142-p26-arms-height-volume_2026-09-30.png", p, width = 180, height = 130, units = "mm", dpi = 300)
cat("FIG_DONE\n")
