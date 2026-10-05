## PREREG44 figure (r2: unit label with true superscripts): top height and stems over 100 years from measured qc_c t1 stand lists, ESI bin means with 95% intervals
## (mean +/- t SE over the stands in each bin), arms qc141 (0.111) and p38_fit (1.242). Headless, 180 mm, 300 dpi. No coordinates.
suppressMessages({library(data.table); library(ggplot2)})
d <- fread("/home/aaron/jobs/v142p44/assembled/gyr142-p44-traj-5yr_DATA_2026-10-05.csv")
m <- melt(d[, .(arm, cell, esi_bin, age, HT, TPH)], id.vars = c("arm", "cell", "esi_bin", "age"))
s <- m[, .(mu = mean(value), se = sd(value)/sqrt(.N), n = .N), by = .(arm, esi_bin, age, variable)][, `:=`(lo = mu - qt(0.975, n - 1)*se, hi = mu + qt(0.975, n - 1)*se)]
s[, Arm := factor(arm, c("qc141", "p38_fit"), c("QC_AFAC 0.111 (14.1)", "QC_AFAC 1.242 (field tag fit)"))]
s[, panel := factor(variable, c("HT", "TPH"), c("Top height (m)", "Stems (trees ha\u207b\u00b9, 4 cm and over)"))]; s[, ESI := factor(esi_bin, 1:4, paste("ESI bin", 1:4))]
g <- ggplot(s, aes(age, mu, colour = ESI, fill = ESI)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, colour = NA) + geom_line(linewidth = 0.6) +
  facet_grid(panel ~ Arm, scales = "free_y", switch = "y") + scale_colour_viridis_d(end = 0.85) + scale_fill_viridis_d(end = 0.85) +
  labs(x = "Years from measured t1 stand list", y = NULL, colour = NULL, fill = NULL) + theme_bw(base_size = 9) +
  theme(strip.placement = "outside", strip.background = element_blank(), panel.grid.minor = element_blank(), legend.position = "bottom")
out <- "/home/aaron/jobs/v142p44/figs/gyr142-p44-topht-stems_2026-10-05.png"; if (file.exists(out)) stop("REFUSE ", out)
png(out, width = 180, height = 130, units = "mm", res = 300); print(g); dev.off(); cat("FIG_DONE\n")
