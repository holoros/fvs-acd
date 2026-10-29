## PREREG45 figure revision 2: the assembly figure drawn again from its saved data with one legend (colour and fill merged);
## no number changes. Original kept. No em dashes.
suppressMessages({ library(data.table); library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p45"; FB <- fread(file.path(J, "figs/gyr142-p45-relht_DATA_2026-10-05.csv")); TT <- fread(file.path(J, "figs/gyr142-p45-topht100_DATA_2026-10-05.csv"))
out <- file.path(J, "figs/gyr142-p45-relht-longrun_rev2_2026-10-05.png"); if (file.exists(out)) stop("REFUSE")
lv <- c("qc141 (0.111)", "p38_fit (1.242)", "qc_rh, m(r)"); FB[, armlab := factor(armlab, lv)]; TT[, armlab := factor(armlab, lv)]
FB[, grp := factor(grp, c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", "below 12.7", "12.7 to 25", "25 and over"))]
cols <- setNames(c("grey40", "#1b6ca8", "#b5452b"), lv); th0 <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
yl <- expression("Height increment bias (m "*yr^{-1}*")")
pp <- function(d, xl) ggplot(d, aes(grp, bias_m_yr, colour = armlab)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -0.04, ymax = 0.04, alpha = .12, fill = "#1b6ca8") +
  geom_hline(yintercept = 0, linetype = 2, colour = "grey50") + geom_errorbar(aes(ymin = bias_lo, ymax = bias_hi), width = .2, position = position_dodge(.6)) +
  geom_point(size = 1.6, position = position_dodge(.6)) + scale_colour_manual(values = cols, name = NULL) + labs(x = xl, y = yl) + th0
pa <- pp(FB[panel == "rel"], "t1 height over ESI"); pb <- pp(FB[panel == "cls"], "t1 DBH class (cm)")
pc <- ggplot(TT, aes(age, rel, colour = armlab, fill = armlab)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .12, colour = NA, show.legend = FALSE) + geom_line() +
  geom_hline(yintercept = 1.175, linetype = 2) + annotate("text", x = 2, y = 1.2, label = "measured frontier, 99th percentile (1.175)", hjust = 0, size = 2.6) +
  scale_colour_manual(values = cols, name = NULL) + scale_fill_manual(values = cols, guide = "none") + labs(x = "Years projected", y = "Top height over ESI (mean, 10th to 90th percentile)") + th0
fig <- (pa + pb) / pc + plot_layout(guides = "collect") + plot_annotation(tag_levels = "a") & theme(legend.position = "bottom")
ggsave(out, fig, width = 180, height = 160, units = "mm", dpi = 300); cat("FIG_REV2_DONE\n")
