## PREREG33 figures, headless, 180 mm wide, 300 dpi, theme_classic, SI axis expressions, white panels. Reads assembled tables
## only (no coordinates exist in them); writes downscaled JPEG copies for inspection. Refuses to overwrite. No em dashes.
suppressMessages({library(data.table); library(ggplot2); library(png); library(jpeg)})
J <- "/home/aaron/jobs/v142p33"; FD <- file.path(J, "figs"); chk <- function(fn) if (file.exists(fn)) stop("REFUSE ", fn)
th <- theme_classic(base_size = 8) + theme(strip.background = element_blank(), legend.position = "bottom", panel.background = element_rect(fill = "white", colour = NA), plot.background = element_rect(fill = "white", colour = NA))
## Figure 1: benchmark height increment, screened qc_c, folds A and B, 95 percent site cluster intervals
H <- fread(file.path(J, "assembled/bench/gyr142-p33-hinc_DATA_2026-10-01.csv"))[set == "qc_c" & arm %in% c("p19_a0111", "p28b_small", "p33_dyn") & group != "dominant"]
H[, Arm := factor(arm, levels = c("p19_a0111", "p28b_small", "p33_dyn"), labels = c("0.111 (14.1)", "PREREG28b, static", "p33_dyn, dynamic"))]
H[, Panel := factor(group, levels = c("overall", "below 12.7", "12.7 to 25", "25 and over"),
  labels = c("Pooled~ratio", "Bias~(m~yr^-1)*','~'below 12.7 cm'", "Bias~(m~yr^-1)*','~'12.7 to 25 cm'", "Bias~(m~yr^-1)*','~'25 cm and over'"))]
H[, `:=`(y = fifelse(group == "overall", ratio, bias_m_yr), lo = fifelse(group == "overall", ratio_lo, bias_lo), hi = fifelse(group == "overall", ratio_hi, bias_hi), ref = fifelse(group == "overall", 1, 0))]
H[, Fold := fifelse(fold == "A", "Fold A (fit)", "Fold B (held out)")]
p1 <- ggplot(H, aes(Arm, y, colour = Fold)) + geom_hline(aes(yintercept = ref), linetype = 2, colour = "grey45", linewidth = 0.3) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, position = position_dodge(width = 0.5), linewidth = 0.4) + geom_point(size = 1.6, position = position_dodge(width = 0.5)) +
  facet_wrap(~Panel, scales = "free_y", ncol = 2, labeller = label_parsed) + scale_colour_manual(values = c(`Fold A (fit)` = "#1b6ca8", `Fold B (held out)` = "#b5452b"), name = NULL) +
  labs(x = "QC height anchor", y = expression(Predicted~against~observed~annual~height~increment)) + th
f1 <- file.path(FD, "gyr142-p33-hinc-by-class_2026-10-01.png"); chk(f1); ggsave(f1, p1, width = 180, height = 130, units = "mm", dpi = 300)
## Figure 2: grid top height, stems and volume by year, N0 3,000, qc141 and p33_dyn (PREREG33) and p28b_small (PREREG31)
T5 <- rbind(fread(file.path(J, "assembled/grid/gyr142-p33grid-traj-5yr_DATA_2026-10-01.csv")),
            fread("/home/aaron/jobs/v142p31/assembled/gyr142-p31-traj-5yr_DATA_2026-09-30.csv")[arm == "p28b_small"], fill = TRUE)
T5 <- T5[n0 == 3000]; T5[, ESI := factor(esi)][, Arm := factor(arm, levels = c("qc141", "p28b_small", "p33_dyn"), labels = c("qc141 (14.1)", "p28b_small, static", "p33_dyn, dynamic"))]
T5[, Mix := factor(mix, levels = c("BF", "SM", "MX"), labels = c("Balsam~fir", "Sugar~maple", "QC~mix"))]
L <- melt(T5, id.vars = c("Arm", "Mix", "ESI", "age"), measure.vars = c("HT", "TPH", "VOL"))
L[, Var := factor(variable, levels = c("HT", "TPH", "VOL"), labels = c("Top~height~(m)", "Stems~(ha^-1)", "Volume~(m^3~ha^-1)"))]
p2 <- ggplot(L, aes(age, value, colour = ESI, linetype = Arm)) + geom_line(linewidth = 0.4) +
  facet_grid(Var ~ Mix, scales = "free_y", labeller = label_parsed, switch = "y") + scale_colour_viridis_d(end = 0.85, name = "ESI (m)") +
  scale_linetype_manual(values = c("solid", "22", "62"), name = NULL) + labs(x = "Projection year", y = NULL) + th + theme(strip.placement = "outside")
f2 <- file.path(FD, "gyr142-p33-grid-height-stems-volume_2026-10-01.png"); chk(f2); ggsave(f2, p2, width = 180, height = 150, units = "mm", dpi = 300)
for (fn in c(f1, f2)) { im <- readPNG(fn); k <- 3L; im <- im[seq(1, dim(im)[1], k), seq(1, dim(im)[2], k), 1:3, drop = FALSE]; writeJPEG(im, sub("\\.png$", "_small.jpg", fn), quality = 0.8) }
cat("P33_FIGURES_DONE\n")
