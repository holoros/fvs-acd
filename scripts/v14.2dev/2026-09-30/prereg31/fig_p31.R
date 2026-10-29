## PREREG31 figures, headless, 180 mm wide, 300 dpi, theme_classic, SI axis expressions. Reads the assembled five year
## trajectories only (no coordinates exist in them). Also writes downscaled JPEG copies for inspection. No em dashes.
suppressMessages({library(data.table); library(ggplot2); library(png); library(jpeg)})
J <- Sys.getenv("P31_FIG_ROOT", "/home/aaron/jobs/v142p31"); FD <- file.path(J, "figs")
T5 <- fread(file.path(J, "assembled/gyr142-p31-traj-5yr_DATA_2026-09-30.csv"))
T5[, ESI := factor(esi)][, N0 := factor(n0)][, Arm := factor(arm, levels = c("qc141","p28b_small"), labels = c("qc141 (14.1)","p28b_small"))]
T5[, Mix := factor(mix, levels = c("BF","SM","MX"), labels = c("Balsam~fir", "Sugar~maple", "QC~mix"))]
chk <- function(fn) if (file.exists(fn)) stop("REFUSE ", fn)
th <- theme_classic(base_size = 8) + theme(strip.background = element_blank(), legend.position = "bottom", panel.background = element_rect(fill = "white", colour = NA))
L <- melt(T5[n0 == 3000], id.vars = c("Arm","Mix","ESI","age"), measure.vars = c("HT","TPH","VOL"))
L[, Var := factor(variable, levels = c("HT","TPH","VOL"), labels = c("Top~height~(m)", "Stems~(ha^-1)", "Volume~(m^3~ha^-1)"))]
p1 <- ggplot(L, aes(age, value, colour = ESI, linetype = Arm)) + geom_line(linewidth = 0.45) +
  facet_grid(Var ~ Mix, scales = "free_y", labeller = label_parsed, switch = "y") + scale_colour_viridis_d(end = 0.85, name = "ESI (m)") +
  scale_linetype_manual(values = c("solid", "22"), name = NULL) + labs(x = "Projection year", y = NULL) + th + theme(strip.placement = "outside")
f1 <- file.path(FD, "gyr142-p31-height-stems-volume_2026-09-30.png"); chk(f1); ggsave(f1, p1, width = 180, height = 150, units = "mm", dpi = 300)
p2 <- ggplot(T5[TPH > 0], aes(QMD, TPH, colour = ESI, linetype = N0, group = cell)) + geom_path(linewidth = 0.4) +
  geom_abline(slope = -1.605, intercept = 5.2, colour = "grey55", linewidth = 0.9, alpha = 0.5, linetype = "solid") +
  scale_x_log10() + scale_y_log10() + facet_grid(Arm ~ Mix, labeller = labeller(Mix = label_parsed, Arm = label_value)) +
  scale_colour_viridis_d(end = 0.85, name = "ESI (m)") + scale_linetype_manual(values = c("solid","42","12"), name = expression(N[0]~(ha^-1))) +
  labs(x = expression(QMD~(cm)), y = expression(Stems~(ha^-1))) + th
f2 <- file.path(FD, "gyr142-p31-reineke_2026-09-30.png"); chk(f2); ggsave(f2, p2, width = 180, height = 120, units = "mm", dpi = 300)
for (fn in c(f1, f2)) { im <- readPNG(fn); k <- 3L; im <- im[seq(1, dim(im)[1], k), seq(1, dim(im)[2], k), 1:3, drop = FALSE]
  writeJPEG(im, sub("\\.png$", "_small.jpg", fn), quality = 0.8) }
cat("FIGURES_DONE\n")
