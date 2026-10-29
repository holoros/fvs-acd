## PREREG41 figure: top height, basal area and the Reineke plane (log TPH against log QMD) for qc141 (frozen PREREG31) and
## p38_fit by mix at ESI 17.3 and 19.8 m, N0 3,000, five year points; from the assembled 5 year trajectories. No em dashes.
suppressMessages({ library(data.table); library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p41"; DT <- "2026-10-02"
X <- fread(file.path(J, sprintf("assembled/gyr142-p41-traj-5yr_DATA_%s.csv", DT)))[n0 == 3000 & esi %in% c(17.3, 19.8)]
X[, arm := factor(arm, levels = c("qc141", "p38_fit"), labels = c("qc141 (0.111)", "p38_fit (1.242)"))][, ESI := factor(sprintf("%.1f m", esi))]
X[, mix := factor(mix, levels = c("BF", "SM", "MX"), labels = c("Balsam fir", "Sugar maple", "QC mix"))]
out <- file.path(J, sprintf("figs/gyr142-p41-grid_DATA_%s.csv", DT)); if (file.exists(out)) stop("REFUSE"); fwrite(X[, .(arm, mix, esi, n0, age, HT, BAPH, TPH, QMD)], out)
th <- theme_classic(base_size = 8) + theme(legend.position = "bottom", strip.background = element_blank(), plot.tag = element_text(face = "bold"))
cols <- c("qc141 (0.111)" = "grey40", "p38_fit (1.242)" = "#b5452b")
p1 <- ggplot(X, aes(age, HT, colour = arm, linetype = ESI)) + geom_line(linewidth = 0.4) + facet_wrap(~mix) + scale_colour_manual(values = cols) +
  labs(x = "Age (yr)", y = "Top height (m)", colour = NULL, linetype = "ESI") + th
p2 <- ggplot(X, aes(age, BAPH, colour = arm, linetype = ESI)) + geom_line(linewidth = 0.4) + facet_wrap(~mix) + scale_colour_manual(values = cols) +
  labs(x = "Age (yr)", y = expression(Basal~area~(m^2~ha^-1)), colour = NULL, linetype = "ESI") + th
p3 <- ggplot(X[TPH > 0 & QMD > 0], aes(QMD, TPH, colour = arm, linetype = ESI)) + geom_path(linewidth = 0.4) + facet_wrap(~mix) +
  scale_x_log10() + scale_y_log10() + scale_colour_manual(values = cols) + labs(x = "QMD (cm, log scale)", y = expression(Trees~ha^-1~(log~scale)), colour = NULL, linetype = "ESI") + th
pn <- file.path(J, sprintf("figs/gyr142-p41-grid_%s.png", DT)); if (file.exists(pn)) stop("REFUSE")
ggsave(pn, p1 / p2 / p3 + plot_layout(guides = "collect") + plot_annotation(tag_levels = "a") & theme(legend.position = "bottom"), width = 180, height = 150, units = "mm", dpi = 300)
cat("P41_FIG_DONE\n")
