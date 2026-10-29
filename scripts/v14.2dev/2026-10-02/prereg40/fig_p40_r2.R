## PREREG40 figure revision 2. Revision 1 (assemble_p40.R, a70f0cd2) drew panel b with himp and the fold A fill called on a
## length one species vector, so ifelse returned one value and data.table recycled it (curves near 2 m). Panel a and every
## assembled number are unaffected. This script redraws from frozen files only: panel a and the binned fold A means from the
## r1 figure data, the curves from the hdfit table and the runner himp. No assembly is rerun. No em dashes.
suppressMessages({ library(data.table); library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p40"; DT <- "2026-10-02"; LIM <- 10
RL <- readLines("/home/aaron/jobs/v142p38/home/runner_p28_fb.R"); eval(parse(text = grep("^sw<-c\\(", RL, value = TRUE))); eval(parse(text = grep("^himp<-function", RL, value = TRUE)))
F1 <- fread(file.path(J, sprintf("figs/gyr142-p40-topht-measured_DATA_%s.csv", DT))); H <- fread(file.path(J, sprintf("assembled/gyr142-p40-hdfit_DATA_%s.csv", DT)))
k <- function(g, t) H[group == g & term == t]$estimate
dg <- seq(1, max(F1[panel == "b" & kind != "data"]$x), by = 1); n <- length(dg)
hd <- function(g, d) 1.3 + k(g, "a") * (1 - exp(-k(g, "b") * d))^k(g, "c")
FB <- rbind(data.table(curve = "himp", group = rep(c("softwood", "hardwood"), each = n), DBH = c(dg, dg), HT = c(himp(rep("BF", n), dg), himp(rep("RM", n), dg))),
  data.table(curve = "fold A fit", group = rep(c("softwood", "hardwood"), each = n), DBH = c(dg, dg), HT = c(hd("softwood", dg), hd("hardwood", dg))))
stopifnot(all(diff(FB[curve == "himp" & group == "softwood"]$HT) > 0), abs(FB[curve == "himp" & group == "softwood" & DBH == 20]$HT - (1.3 + 27 * (1 - exp(-0.6)))) < 1e-12)
FBo <- F1[panel == "b" & kind == "data"][, .(group = sub("fold A binned mean ", "", series), DBH = x, HT = y)]
FA <- F1[panel == "a"][, variant := factor(series, levels = c("published (himp fill)", "M, measured heights", "H, fold A fill"))]
out <- file.path(J, sprintf("figs/gyr142-p40-topht-measured-r2_DATA_%s.csv", DT)); if (file.exists(out)) stop("REFUSE")
fwrite(rbind(F1[panel == "a"], FB[, .(panel = "b", series = paste(curve, group), kind = curve, x = DBH, y = HT, lo = NA, hi = NA)], F1[panel == "b" & kind == "data"]), out)
th <- theme_classic(base_size = 9) + theme(legend.position = "bottom", legend.box = "vertical", plot.tag = element_text(face = "bold"))
cols <- c("published (himp fill)" = "grey45", "M, measured heights" = "#b5452b", "H, fold A fill" = "#2b6cb5"); pd <- position_dodge(width = 0.03)
fa <- ggplot(FA, aes(x, y, colour = variant)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -LIM, ymax = LIM, alpha = 0.08) +
  geom_hline(yintercept = 0, linetype = 2, colour = "grey50") + geom_line(data = FA[kind == "single value arm"], linewidth = 0.3) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.02) + geom_point(aes(shape = kind), size = 1.6) +
  scale_colour_manual(values = cols) + scale_shape_manual(values = c("single value arm" = 16, "p28b_small (1.265 below 25 cm, 0.111 above)" = 1)) +
  labs(x = "QC_AFAC", y = "TOPHT bias (%)", colour = NULL, shape = NULL) + th
fb <- ggplot() + geom_point(data = FBo, aes(DBH, HT), size = 0.8, colour = "grey55") + geom_line(data = FB, aes(DBH, HT, linetype = curve), linewidth = 0.4) +
  facet_wrap(~group) + labs(x = "DBH (cm)", y = "Height (m)", linetype = NULL) + th
png_out <- file.path(J, sprintf("figs/gyr142-p40-topht-measured-r2_%s.png", DT)); if (file.exists(png_out)) stop("REFUSE")
ggsave(png_out, fa + fb + plot_layout(widths = c(1.2, 1)) + plot_annotation(tag_levels = "a"), width = 180, height = 100, units = "mm", dpi = 300)
print(FB[DBH %in% c(10, 20, 30, 50)], digits = 4); cat("P40_FIG_R2_DONE\n")
