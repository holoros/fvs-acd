## PREREG26 threshold re-derivation [F9] from ns_c t1 tree lists (trees 9.1 cm and over): tau 0.99 self thinning frontier,
## BA and SDI 99th and 99.9th percentiles, and the observed CV of NSVB-free volume proxy is not used; Eichhorn observed CV uses
## BA x top height (no volume equation on observed plots is needed for a CV across ESI at matched height). No coordinates.
suppressMessages({library(data.table); library(quantreg)})
F <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"; O <- "/home/aaron/jobs/v142p26/assembled/thresholds_p26_DATA_2026-09-30.csv"
if (file.exists(O)) stop("REFUSE ", O)
p <- merge(fread(file.path(F,"bench_gyr_ns_c_pairs.csv")), fread(file.path(F,"bench_gyr_ns_c_site_esi.csv")), by = "SITE")
p[, esi8 := as.numeric(esi8)]; p <- p[is.finite(esi8) & esi8 > 2]
t <- fread(file.path(F,"bench_gyr_ns_c_tree_init.csv"))[STAND %in% p$STAND & is.finite(DBH) & DBH >= 9.1 & EXPF > 0]
s <- t[, .(TPH = sum(EXPF), BA = sum(pi*(DBH/200)^2*EXPF), HT = { o <- order(-DBH); cw <- cumsum(EXPF[o]); i <- which(cw <= 100); if (!length(i)) i <- 1L; h <- HT[o][i]; mean(h[is.finite(h) & h > 0]) }), by = STAND]
s[, QMD := sqrt((BA/TPH)/(pi/40000))][, SDI := TPH*(QMD/25)^1.605]; s <- merge(s, p[, .(STAND, esi8)], by = "STAND")
s <- s[TPH > 0 & QMD > 0]
qr <- rq(log10(TPH) ~ log10(QMD), tau = 0.99, data = s); cf <- coef(qr)
R <- data.table(quantity = c("n_stands","frontier_a","frontier_b","BA_q99","BA_q999","SDI_q99","SDI_q999"),
  value = c(nrow(s), cf[1], cf[2], quantile(s$BA,.99), quantile(s$BA,.999), quantile(s$SDI,.99), quantile(s$SDI,.999)))
## observed Eichhorn: CV of BA*HT across ESI terciles within 2 m top height bins (bins with all three terciles and 20+ stands each)
e <- s[is.finite(HT)]; e[, terc := cut(esi8, quantile(esi8, c(0,1/3,2/3,1)), include.lowest = TRUE, labels = FALSE)][, hb := floor(HT/2)*2]
g <- e[, .(v = mean(BA*HT), n = .N), by = .(hb, terc)][n >= 20]; g <- g[, if (.N == 3) .(cv = sd(v)/mean(v)) , by = hb]
R <- rbind(R, data.table(quantity = c("eichhorn_obs_meanCV","eichhorn_obs_bins"), value = c(mean(g$cv), nrow(g))))
print(R); print(g); fwrite(R, O); cat("THRESHOLDS_DONE\n")
