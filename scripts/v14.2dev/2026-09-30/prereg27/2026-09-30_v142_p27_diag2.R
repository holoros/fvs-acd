## PREREG27 step 1b and 1c continued, fold A only, candidate arm v141LTfi (PREREG22). Survivor ratio (predicted over observed
## surviving stems of t1 trees at or above the threshold) and recruit ratio by set, interval class and program (NS_OP,
## NS_RS by STAND prefix), with site cluster intervals (B = 1000, seed 20260930; SITE is used only as an integer index);
## within plot contrast (plots with both a 5 year and a longer interval); stand state strata (t1 QMD tercile, t1 stems
## tercile, within ns_c and ns_long_c). No fold B row is used. No coordinates. Headless, theme_classic, 300 dpi. No em dashes.
suppressMessages({library(data.table); library(ggplot2)}); set.seed(20260930); options(width = 200)
J <- "/home/aaron/jobs/v142p27"; source(file.path(J, "scripts/p27_lib.R")); OUT <- file.path(J, "fit")
KA <- readRDS(file.path(J, "in/p27_foldA_keys.rds"))$KA; stopifnot(all(KA$fold == "A"))
KA[, sidx := as.integer(factor(SITE))]
pk <- rbindlist(lapply(unique(KA$set), function(s) fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "PLOTKEY"))[, set := s]))
KA <- merge(KA, pk, by = c("set", "STAND")); KA[, pidx := as.integer(factor(paste(set, PLOTKEY)))]; KA[, PLOTKEY := NULL]
X <- rbindlist(lapply(unique(KA$set), function(s) stand_comp(s, "fi", KA[set == s, .(STAND, thr = SCORE_MINDBH_USED)])))
X <- merge(X, KA[, .(set, STAND, sidx, pidx, ivc, iv = interval_years)], by = c("set", "STAND")); X[, prog := prog_of(STAND)]
X[, iv3 := fcase(iv <= 5, "iv05", iv <= 15, "iv06_15", default = "iv16_60")]
tab <- function(d, by) { R <- d[, .(stands = .N, sites = uniqueN(sidx), iv_mean = mean(iv), n1 = sum(n1), surv_o = sum(surv_o), surv_p = sum(surv_p), rec_o = sum(rec_o), rec_p = sum(rec_p)), by = by]
  R[, `:=`(surv_ratio = surv_p / surv_o, rec_ratio = rec_p / rec_o, stems_ratio = (surv_p + rec_p) / (surv_o + rec_o),
           d_surv_pct = 100 * (surv_p - surv_o) / (surv_o + rec_o), d_rec_pct = 100 * (rec_p - rec_o) / (surv_o + rec_o),
           ann_surv_o = (surv_o / n1)^(1 / iv_mean), ann_surv_p = (surv_p / n1)^(1 / iv_mean))]
  CI <- d[, { a <- bsr(.SD, "surv_p", "surv_o"); b <- bsr(.SD, "rec_p", "rec_o"); .(surv_lo = a$lo, surv_hi = a$hi, rec_lo = b$lo, rec_hi = b$hi) }, by = by]
  merge(R, CI, by = by) }
T1 <- rbind(tab(X, c("set", "ivc")), tab(X, "set")[, ivc := "all"])[, prog := "all"]
T2 <- rbind(tab(X, c("set", "ivc", "prog")), tab(X, c("set", "prog"))[, ivc := "all"])
TT <- rbind(T1, T2, use.names = TRUE)[order(set, prog, ivc)]; print(TT[, .(set, prog, ivc, stands, iv_mean, surv_ratio, surv_lo, surv_hi, rec_ratio, rec_lo, rec_hi, d_surv_pct, d_rec_pct, ann_surv_o, ann_surv_p)], digits = 3)
fwrite(TT, file.path(OUT, "gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv"))
## within plot: consecutive sets, plots carrying both a 5 year interval and a longer one
WP <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { d <- X[set == s]; both <- d[, .(a = any(iv <= 5), b = any(iv > 5)), by = pidx][a & b, pidx]
  tab(d[pidx %in% both], c("set", "iv3"))[, plots := length(both)] }))
print(WP[, .(set, iv3, plots, stands, iv_mean, surv_ratio, surv_lo, surv_hi, rec_ratio, ann_surv_o, ann_surv_p)], digits = 3)
fwrite(WP, file.path(OUT, "gyr142-p27-diag-withinplot-foldA_DATA_2026-09-30.csv"))
## stand state strata within the consecutive sets
X[, `:=`(qmd1 = sqrt(ba1 / n1 / (pi / 40000)))]
ST <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { d <- X[set == s & n1 > 0]
  d[, `:=`(q3 = cut(qmd1, quantile(qmd1, 0:3 / 3), include.lowest = TRUE, labels = c("qmd_lo", "qmd_mid", "qmd_hi")),
           n3 = cut(n1, quantile(n1, 0:3 / 3), include.lowest = TRUE, labels = c("tph_lo", "tph_mid", "tph_hi")))]
  rbind(tab(d, c("set", "q3", "iv3"))[, `:=`(stratum = q3, q3 = NULL)], tab(d, c("set", "n3", "iv3"))[, `:=`(stratum = n3, n3 = NULL)], use.names = TRUE) }))
print(ST[, .(set, stratum, iv3, stands, surv_ratio, surv_lo, surv_hi, ann_surv_o, ann_surv_p)], digits = 3)
fwrite(ST, file.path(OUT, "gyr142-p27-diag-state-foldA_DATA_2026-09-30.csv"))
saveRDS(X, file.path(J, "in/p27_foldA_stand_components.rds"))
## figure: survivor and recruit ratio by interval class, four sets, fold A, v141LTfi
F <- melt(T1[ivc != "all"], id.vars = c("set", "ivc", "iv_mean", "stands"), measure.vars = list(r = c("surv_ratio", "rec_ratio"), lo = c("surv_lo", "rec_lo"), hi = c("surv_hi", "rec_hi")), variable.name = "comp")
F[, comp := c("Survivors", "Recruits")[comp]]
theme_p27 <- function() theme_classic(base_size = 10) + theme(strip.background = element_blank(), strip.text = element_text(face = "bold"), legend.position = "bottom")
g <- ggplot(F, aes(iv_mean, r, colour = set, shape = set)) + geom_hline(yintercept = 1, linetype = 2) +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 1.5), size = 0.3) + geom_line(position = position_dodge(width = 1.5)) +
  facet_wrap(~ comp, scales = "free_y") + scale_y_log10() + labs(x = "Mean interval length in class (years)", y = "Predicted / observed stems (log scale)",
  colour = NULL, shape = NULL, title = "v141LTfi, fold A: survivors fall and recruits rise with interval length") + theme_p27()
dir.create(file.path(J, "figs"), showWarnings = FALSE)
ggsave(file.path(J, "figs/gyr142-p27-diag-survrec-foldA_2026-09-30.png"), g, width = 8, height = 4, dpi = 300)
cat("DIAG2_DONE\n")
