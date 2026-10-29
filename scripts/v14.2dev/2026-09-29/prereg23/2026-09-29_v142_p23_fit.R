## PREREG23 step 1 fit, fold A only. Screened qc_c fold A (PREREG12 screen: the PREREG19 scorer cut flag), tag matched
## survivors with measured height at both ends. For each frozen PREREG19 arm (QC_AFAC 0.030 to 1.000), pooled predicted over
## observed annual height increment, R(a) = sum(Hp - H1) / sum(H2 - H1), overall and by diameter class at t1 (below 12.7,
## 12.7 to 25, 25 cm and over). The anchor a_h solves R(a) = 1 by linear interpolation of log R on log a between adjacent
## grid values, or by extension of the last segment (0.500 to 1.000) if R(1.000) < 1. Site cluster bootstrap B = 1000, seed
## 20260929, the same site draws for every arm. Fold B stands are dropped before any tree or model output is read.
## Also reported (fold A): t2 height level on the same trees, sum(Hp)/sum(H2), overall and on the t1 dominant cohort.
## Writes to ~/jobs/v142p23/fit/, refuses to overwrite. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p23/scripts/2026-09-29_v142_p23_hkey.R")
set.seed(20260929); B <- 1000L
J <- "/home/aaron/jobs/v142p23"; O <- file.path(J, "fit"); dir.create(O, showWarnings = FALSE)
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
GRID <- c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000); ARMS <- sprintf("p19_a%04d", round(GRID * 1000))
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
## stand frame from the 0.111 arm; K1 was 0 in every arm, so the RUN_OK set is checked identical across arms
S0 <- stand_frame(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), "qc_c", CUTF)
for (a in ARMS) { s <- stand_frame(file.path(P19, sprintf("results/%s/gyr_%s_qc_c_results.csv", a, a)), "qc_c", CUTF)
  if (!setequal(s$STAND, S0$STAND)) stop("RUN_OK stand set differs in ", a) }
SA <- S0[fold == "A"]; rm(S0)           # fold B dropped here
cat(sprintf("fold A: %d RUN_OK stands on %d sites; screened %d stands on %d sites\n", nrow(SA), uniqueN(SA$SITE), SA[cut == FALSE, .N], SA[cut == FALSE, uniqueN(SITE)]))
TK <- tag_key("qc_c", SA$STAND); K <- merge(TK$K, SA[, .(STAND, SITE, cut)], by = "STAND")
for (i in seq_along(ARMS)) { p <- pred_ht(arm_dirs(file.path(P19, "home"), ARMS[i], "qc_c"), TK$M, SA$STAND)
  if (i == 1) K <- merge(K, p[, .(STAND, row0, iv, nsplit, sp1 = Hp_spread)], by = c("STAND", "row0"), all.x = TRUE)
  K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", ARMS[i])) }
if (K[, anyNA(.SD), .SDcols = paste0("Hp_", ARMS)]) stop("tag record without prediction")
iv_chk <- merge(K[, .(iv = iv[1]), by = STAND], SA[, .(STAND, iv2 = Y2 - Y1)], by = "STAND")[, max(abs(iv - iv2))]
cat(sprintf("interval check: max |iv - (Y2 - Y1)| = %g; max split height spread %.3g m\n", iv_chk, max(K$sp1)))
K[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
K[, dho := (H2 - H1) / iv]; for (a in ARMS) K[, paste0("dp_", a) := (get(paste0("Hp_", a)) - H1) / iv]
## anchor from a vector of ratios on the grid (log log interpolation / last segment extension)
anchor <- function(r) { lr <- log(r); la <- log(GRID); if (any(!is.finite(lr))) return(NA_real_)
  if (lr[length(lr)] < 0) { k <- length(lr); return(exp(la[k] + (0 - lr[k]) * (la[k] - la[k - 1]) / (lr[k] - lr[k - 1]))) }
  if (lr[1] > 0) return(exp(la[1] + (0 - lr[1]) * (la[2] - la[1]) / (lr[2] - lr[1])))
  k <- max(which(lr <= 0)); exp(la[k] + (0 - lr[k]) * (la[k + 1] - la[k]) / (lr[k + 1] - lr[k])) }
pops <- list(screened = K[cut == FALSE], all_foldA = K)
TAB <- list(); BOOT <- list()
for (pn in names(pops)) { X <- pops[[pn]]
  grp <- list(overall = X, `below 12.7` = X[cls == "below 12.7"], `12.7 to 25` = X[cls == "12.7 to 25"], `25 and over` = X[cls == "25 and over"],
              dominant = X[dom == TRUE])
  sites <- unique(X$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
  for (g in names(grp)) { Y <- grp[[g]]
    SS <- Y[, c(list(o = sum(dho), h2 = sum(H2)), lapply(setNames(ARMS, ARMS), function(a) sum(get(paste0("dp_", a)))),
                lapply(setNames(ARMS, paste0("L_", ARMS)), function(a) sum(get(paste0("Hp_", a))))), by = SITE]
    w <- matrix(0, nrow(SS), B); m <- match(SS$SITE, sites); for (b in 1:B) w[, b] <- tabulate(IDX[, b], ns)[m]
    rat <- sapply(ARMS, function(a) sum(SS[[a]]) / sum(SS$o)); lev <- sapply(ARMS, function(a) sum(SS[[paste0("L_", a)]]) / sum(SS$h2))
    RB <- sapply(ARMS, function(a) colSums(w * SS[[a]]) / colSums(w * SS$o))
    ab <- apply(RB, 1, anchor)
    TAB[[paste(pn, g)]] <- data.table(pop = pn, group = g, trees = nrow(Y), sites = uniqueN(Y$SITE), stands = uniqueN(Y$STAND),
      obs_m_yr = mean(Y$dho), QC_AFAC = GRID, ratio = rat, ratio_lo = apply(RB, 2, quantile, .025), ratio_hi = apply(RB, 2, quantile, .975),
      level_t2 = lev, a_h = anchor(rat), a_h_lo = quantile(ab, .025, na.rm = TRUE), a_h_hi = quantile(ab, .975, na.rm = TRUE), a_h_na = sum(!is.finite(ab)))
    BOOT[[paste(pn, g)]] <- data.table(pop = pn, group = g, draw = 1:B, a_h = ab) } }
TAB <- rbindlist(TAB); BOOT <- rbindlist(BOOT)
SL <- TAB[, .(slope_0500_1000 = diff(log(ratio[QC_AFAC %in% c(0.5, 1)])) / log(2), slope_0030_1000 = diff(log(ratio[QC_AFAC %in% c(0.03, 1)])) / log(1 / 0.03)), by = .(pop, group)]
fwrite(TAB, f_out("gyr142-p23-fit-hinc-foldA_DATA_2026-09-29.csv")); fwrite(BOOT, f_out("gyr142-p23-fit-boot-foldA_DATA_2026-09-29.csv"))
fwrite(SL, f_out("gyr142-p23-fit-slope-foldA_DATA_2026-09-29.csv"))
print(TAB[, .(pop, group, trees, sites, QC_AFAC, ratio = round(ratio, 4), lo = round(ratio_lo, 4), hi = round(ratio_hi, 4), lev = round(level_t2, 4))], nrows = 200)
print(unique(TAB[, .(pop, group, trees, a_h, a_h_lo, a_h_hi, a_h_na)]), digits = 4); print(SL, digits = 4)
cat("P23_FIT_DONE\n")
