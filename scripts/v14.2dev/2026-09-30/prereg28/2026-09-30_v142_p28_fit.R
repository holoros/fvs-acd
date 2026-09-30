## PREREG28 step 1 fit, fold A only, no engine run. Screened qc_c fold A (PREREG12 screen: the PREREG19 scorer cut flag),
## tag matched survivors with measured height at both ends (PREREG23 key, helper copied unedited to this bundle). Eight
## frozen arms: p19_a0030 to p19_a1000 (PREREG19) and p23_a1061, p23_a1250 (PREREG23). For each diameter class at t1 the
## QC_AFAC that sets mean annual height increment bias (m/yr) to zero is found by linear interpolation of bias on log
## QC_AFAC between the adjacent grid values that bracket zero (extension of the end segment if none does). Two parameter
## forms are then fitted by per tree interpolation of predicted t2 height on log QC_AFAC across the eight arms: a step
## (a_small below a knot, a_large at and above it) and a log linear taper, log a = c0 + c1 (D1 - 25). Site cluster bootstrap
## B = 1000, seed 20260930, the same site draws for every arm and form. Fold B stands are dropped right after the results
## files are read and before any tree record or model output is read. Writes to ~/jobs/v142p28/fit/, refuses to overwrite.
## No coordinates. No em dashes.
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
set.seed(20260930); B <- 1000L
J <- "/home/aaron/jobs/v142p28"; O <- file.path(J, "fit"); dir.create(O, showWarnings = FALSE)
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
P23 <- "/home/aaron/jobs/v142p23"
AR <- data.table(arm = c(sprintf("p19_a%04d", c(30, 60, 111, 250, 500, 1000)), "p23_a1061", "p23_a1250"),
                 a = c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000, 1.061, 1.250))
AR[, root := fifelse(startsWith(arm, "p19"), P19, P23)]
GRID <- AR$a; LA <- log(GRID); NA_ <- length(GRID)
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
resf <- function(i) file.path(AR$root[i], "results", AR$arm[i], sprintf("gyr_%s_qc_c_results.csv", AR$arm[i]))
S0 <- stand_frame(resf(3), "qc_c", CUTF)
for (i in seq_len(NA_)) { s <- stand_frame(resf(i), "qc_c", CUTF); if (!setequal(s$STAND, S0$STAND)) stop("RUN_OK stand set differs in ", AR$arm[i]) }
SA <- S0[fold == "A"]; rm(S0)             # fold B dropped here
## TOPHT (stand level, fold A screened) per arm, PREREG19 assembly formula
TOP <- rbindlist(lapply(seq_len(NA_), function(i) { r <- stand_frame(resf(i), "qc_c", CUTF)[fold == "A" & cut == FALSE]
  data.table(arm = AR$arm[i], a = AR$a[i], stands = nrow(r), topht_bias_pct = 100 * (mean(r$TOPHT_p, na.rm = TRUE) - mean(r$TOPHT_o, na.rm = TRUE)) / mean(r$TOPHT_o, na.rm = TRUE)) }))
SA <- SA[cut == FALSE]
cat(sprintf("fold A screened: %d stands on %d sites\n", nrow(SA), uniqueN(SA$SITE)))
TK <- tag_key("qc_c", SA$STAND); K <- merge(TK$K, SA[, .(STAND, SITE)], by = "STAND")
for (i in seq_len(NA_)) { p <- pred_ht(arm_dirs(file.path(AR$root[i], "home"), AR$arm[i], "qc_c"), TK$M, SA$STAND)
  if (i == 1) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
  K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", AR$arm[i])) }
if (K[, anyNA(.SD), .SDcols = paste0("Hp_", AR$arm)]) stop("tag record without prediction")
K[, dho := (H2 - H1) / iv]
HP <- as.matrix(K[, paste0("Hp_", AR$arm), with = FALSE]); DP <- (HP - K$H1) / K$iv
K[, cls3 := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
K[, cls5 := cut(D1, c(0, 10, 15, 20, 25, 30, 35, Inf), right = FALSE, labels = c("below 10", "10 to 15", "15 to 20", "20 to 25", "25 to 30", "30 to 35", "35 and over"))]
cat(sprintf("tag trees %d on %d sites; dominant %d\n", nrow(K), uniqueN(K$SITE), sum(K$dom)))
sites <- unique(K$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
W <- sapply(1:B, function(b) tabulate(IDX[, b], ns))            # site weights, ns x B
TW <- W[match(K$SITE, sites), , drop = FALSE]                    # tree weights, trees x B
## zero of bias on log a
zero_a <- function(b) { if (any(!is.finite(b))) return(NA_real_); s <- which(b[-NA_] <= 0 & b[-1] > 0)
  k <- if (length(s)) s[1] else if (all(b > 0)) 1L else NA_ - 1L
  exp(LA[k] + (0 - b[k]) * (LA[k + 1] - LA[k]) / (b[k + 1] - b[k])) }
## per tree interpolation of increment at tree specific anchor a_i (log linear in a, end segments extended)
interp <- function(ai) { la <- log(ai); k <- findInterval(la, LA, all.inside = TRUE); t <- (la - LA[k]) / (LA[k + 1] - LA[k])
  DP[cbind(seq_along(k), k)] * (1 - t) + DP[cbind(seq_along(k), k + 1)] * t }
gbias <- function(d, sel, w = NULL) if (is.null(w)) (sum(d[sel]) - sum(K$dho[sel])) / sum(sel) else (colSums(w[sel, , drop = FALSE] * (d[sel] - K$dho[sel]))) / colSums(w[sel, , drop = FALSE])
## ---- per class anchors (3 classes and 5 cm classes), grid biases with intervals
CL <- rbindlist(lapply(c("cls3", "cls5"), function(cc) rbindlist(lapply(c("overall", "dominant", levels(K[[cc]])), function(g) {
  if (cc == "cls5" && g %in% c("overall", "dominant")) return(NULL)
  sel <- if (g == "overall") rep(TRUE, nrow(K)) else if (g == "dominant") K$dom else K[[cc]] == g
  bg <- sapply(seq_len(NA_), function(j) gbias(DP[, j], sel)); bb <- sapply(seq_len(NA_), function(j) gbias(DP[, j], sel, TW))
  ab <- apply(bb, 1, zero_a)
  data.table(scheme = cc, group = g, trees = sum(sel), sites = uniqueN(K$SITE[sel]), obs_m_yr = mean(K$dho[sel]), QC_AFAC = GRID, arm = AR$arm,
    bias_m_yr = bg, bias_lo = apply(bb, 2, quantile, .025, na.rm = TRUE), bias_hi = apply(bb, 2, quantile, .975, na.rm = TRUE),
    level_t2 = sapply(seq_len(NA_), function(j) sum(HP[sel, j]) / sum(K$H2[sel])),
    a0 = zero_a(bg), a0_lo = quantile(ab, .025, na.rm = TRUE), a0_hi = quantile(ab, .975, na.rm = TRUE)) }))))
fwrite(CL, f_out("gyr142-p28-fit-class-foldA_DATA_2026-09-30.csv"))
print(unique(CL[, .(scheme, group, trees, sites, a0 = round(a0, 3), lo = round(a0_lo, 3), hi = round(a0_hi, 3))]))
## ---- step form: a_small, a_large at knots 20, 25, 30 (the pooled zero of each side; exact under per tree interpolation)
lo_side <- function(kn) K$D1 < kn
STEP <- rbindlist(lapply(c(20, 25, 30), function(kn) { s <- lo_side(kn)
  bs <- sapply(seq_len(NA_), function(j) gbias(DP[, j], s)); bl <- sapply(seq_len(NA_), function(j) gbias(DP[, j], !s))
  as <- zero_a(bs); al <- zero_a(bl)
  bbs <- sapply(seq_len(NA_), function(j) gbias(DP[, j], s, TW)); bbl <- sapply(seq_len(NA_), function(j) gbias(DP[, j], !s, TW))
  abs_ <- apply(bbs, 1, zero_a); abl <- apply(bbl, 1, zero_a)
  d <- interp(ifelse(s, as, al))
  r5 <- sapply(levels(K$cls5), function(g) gbias(d, K$cls5 == g))
  data.table(form = "step", knot = kn, p1 = as, p1_lo = quantile(abs_, .025, na.rm = TRUE), p1_hi = quantile(abs_, .975, na.rm = TRUE),
    p2 = al, p2_lo = quantile(abl, .025, na.rm = TRUE), p2_hi = quantile(abl, .975, na.rm = TRUE),
    max_abs_cls5_bias = max(abs(r5)), rms_cls5_bias = sqrt(mean(r5^2)), overall_ratio = sum(d) / sum(K$dho),
    cls3_below127 = gbias(d, K$cls3 == "below 12.7"), cls3_127to25 = gbias(d, K$cls3 == "12.7 to 25"), cls3_25over = gbias(d, K$cls3 == "25 and over"),
    dom_level = sum((d[K$dom] * K$iv[K$dom] + K$H1[K$dom])) / sum(K$H2[K$dom])) }))
## ---- taper: log a = c0 + c1 (D1 - 25), zero pooled bias below 25 and at and over 25
s25 <- K$D1 < 25
tap_fit <- function(w = NULL) { f <- function(c) { d <- interp(exp(c[1] + c[2] * (K$D1 - 25)))
    if (is.null(w)) sum(sapply(list(s25, !s25), function(s) (sum(d[s] - K$dho[s]) / sum(s))^2))
    else { v <- sum(sapply(list(s25, !s25), function(s) (sum(w[s] * (d[s] - K$dho[s])) / sum(w[s]))^2)); if (is.finite(v)) v else 1e6 } }
  optim(c(log(0.5), -0.1), f, control = list(reltol = 1e-12, maxit = 2000))$par }
tp <- tap_fit(); tb <- t(sapply(1:B, function(b) tap_fit(TW[, b])))
d <- interp(exp(tp[1] + tp[2] * (K$D1 - 25))); r5 <- sapply(levels(K$cls5), function(g) gbias(d, K$cls5 == g))
TAP <- data.table(form = "taper", knot = 25, p1 = tp[1], p1_lo = quantile(tb[, 1], .025, na.rm = TRUE), p1_hi = quantile(tb[, 1], .975, na.rm = TRUE),
  p2 = tp[2], p2_lo = quantile(tb[, 2], .025, na.rm = TRUE), p2_hi = quantile(tb[, 2], .975, na.rm = TRUE), max_abs_cls5_bias = max(abs(r5)), rms_cls5_bias = sqrt(mean(r5^2)),
  overall_ratio = sum(d) / sum(K$dho), cls3_below127 = gbias(d, K$cls3 == "below 12.7"), cls3_127to25 = gbias(d, K$cls3 == "12.7 to 25"),
  cls3_25over = gbias(d, K$cls3 == "25 and over"), dom_level = sum((d[K$dom] * K$iv[K$dom] + K$H1[K$dom])) / sum(K$H2[K$dom]))
FORMS <- rbind(STEP, TAP); fwrite(FORMS, f_out("gyr142-p28-fit-forms-foldA_DATA_2026-09-30.csv")); print(FORMS, digits = 4)
## class biases (5 cm) under each form, for the figure
CB <- rbindlist(lapply(seq_len(nrow(FORMS)), function(i) { f <- FORMS[i]
  ai <- if (f$form == "step") ifelse(K$D1 < f$knot, f$p1, f$p2) else exp(f$p1 + f$p2 * (K$D1 - 25)); d <- interp(ai)
  data.table(form = sprintf("%s knot %g", f$form, f$knot), group = levels(K$cls5), bias_m_yr = sapply(levels(K$cls5), function(g) gbias(d, K$cls5 == g))) }))
fwrite(CB, f_out("gyr142-p28-fit-formclass-foldA_DATA_2026-09-30.csv"))
## TOPHT fold A by arm, and interpolated at a_large of the knot 25 step (arms bracketing it named)
fwrite(TOP, f_out("gyr142-p28-fit-topht-foldA_DATA_2026-09-30.csv")); print(TOP)
al <- STEP[knot == 25]$p2; k <- findInterval(log(al), LA, all.inside = TRUE)
cat(sprintf("TOPHT fold A at a_large %.3f: interpolated %+.2f percent between %s (%+.2f) and %s (%+.2f)\n", al,
  TOP$topht_bias_pct[k] + (log(al) - LA[k]) / (LA[k + 1] - LA[k]) * (TOP$topht_bias_pct[k + 1] - TOP$topht_bias_pct[k]), AR$arm[k], TOP$topht_bias_pct[k], AR$arm[k + 1], TOP$topht_bias_pct[k + 1]))
## figure: fold A bias by 5 cm class against QC_AFAC with class zero anchors, and the form residuals
suppressMessages(library(ggplot2))
F1 <- CL[scheme == "cls5"]; F1[, group := factor(group, levels = levels(K$cls5))]
g1 <- ggplot(F1, aes(QC_AFAC, bias_m_yr)) + geom_hline(yintercept = 0, linetype = 2, colour = "grey40") +
  geom_errorbar(aes(ymin = bias_lo, ymax = bias_hi), width = 0.04, colour = "#1b6ca8") + geom_line(colour = "#1b6ca8") + geom_point(colour = "#1b6ca8", size = 1.4) +
  scale_x_log10(breaks = c(0.03, 0.111, 0.25, 0.5, 1.25), labels = c("0.030", "0.111", "0.250", "0.500", "1.250")) + facet_wrap(~group, ncol = 4) +
  labs(x = "QC_AFAC (log scale)", y = "Fold A annual height increment bias (m/yr)", title = "Screened qc_c fold A, tag matched survivors, by t1 DBH class (cm)") +
  theme_classic(base_size = 9) + theme(strip.background = element_blank())
ggsave(file.path(O, "gyr142-p28-fit-class-foldA_2026-09-30.png"), g1, width = 8, height = 4.6, dpi = 300)
cat("P28_FIT_DONE\n")
