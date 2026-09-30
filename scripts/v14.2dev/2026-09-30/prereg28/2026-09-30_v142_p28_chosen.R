## PREREG28 step 1b, fold A only: in sample reading of the chosen step pair (QC_AFAC_SMALL 1.265 below 25 cm t1 DBH,
## QC_AFAC_LARGE 0.030 at and above), by per tree interpolation of predicted t2 height on log QC_AFAC across the eight
## frozen arms, with the same site cluster bootstrap as step 1 (B = 1000, seed 20260930). Also the in sample reading at
## a_large 0.111 (only small trees changed). Same data path as 2026-09-30_v142_p28_fit.R; fold B dropped before any tree
## record is read. Writes fit/gyr142-p28-fit-chosen-foldA_DATA_2026-09-30.csv, refuses to overwrite. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
set.seed(20260930); B <- 1000L
J <- "/home/aaron/jobs/v142p28"; OF <- file.path(J, "fit/gyr142-p28-fit-chosen-foldA_DATA_2026-09-30.csv"); if (file.exists(OF)) stop("REFUSE ", OF)
P23 <- "/home/aaron/jobs/v142p23"
AR <- data.table(arm = c(sprintf("p19_a%04d", c(30, 60, 111, 250, 500, 1000)), "p23_a1061", "p23_a1250"), a = c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000, 1.061, 1.250))
AR[, root := fifelse(startsWith(arm, "p19"), P19, P23)]; LA <- log(AR$a)
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
SA <- stand_frame(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), "qc_c", CUTF)[fold == "A" & cut == FALSE]
TK <- tag_key("qc_c", SA$STAND); K <- merge(TK$K, SA[, .(STAND, SITE)], by = "STAND")
for (i in seq_len(nrow(AR))) { p <- pred_ht(arm_dirs(file.path(AR$root[i], "home"), AR$arm[i], "qc_c"), TK$M, SA$STAND)
  if (i == 1) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
  K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", AR$arm[i])) }
HP <- as.matrix(K[, paste0("Hp_", AR$arm), with = FALSE]); K[, dho := (H2 - H1) / iv]
interp <- function(ai) { la <- log(ai); k <- findInterval(la, LA, all.inside = TRUE); t <- (la - LA[k]) / (LA[k + 1] - LA[k])
  HP[cbind(seq_along(k), k)] * (1 - t) + HP[cbind(seq_along(k), k + 1)] * t }
K[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
sites <- unique(K$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
TW <- sapply(1:B, function(b) tabulate(IDX[, b], ns))[match(K$SITE, sites), , drop = FALSE]
CASES <- list(`reference 0.111` = rep(0.111, nrow(K)), `chosen 1.265 / 0.030` = ifelse(K$D1 < 25, 1.265, 0.030), `small only 1.265 / 0.111` = ifelse(K$D1 < 25, 1.265, 0.111), `flat 1.061` = rep(1.061, nrow(K)))
OUT <- rbindlist(lapply(names(CASES), function(cn) { h <- interp(CASES[[cn]]); d <- (h - K$H1) / K$iv
  rbindlist(lapply(c("overall", "dominant", levels(K$cls)), function(g) { s <- if (g == "overall") rep(TRUE, nrow(K)) else if (g == "dominant") K$dom else K$cls == g
    bb <- colSums(TW[s, , drop = FALSE] * (d[s] - K$dho[s])) / colSums(TW[s, , drop = FALSE]); lb <- colSums(TW[s, , drop = FALSE] * h[s]) / colSums(TW[s, , drop = FALSE] * K$H2[s])
    data.table(case = cn, group = g, trees = sum(s), ratio = sum(d[s]) / sum(K$dho[s]), bias_m_yr = mean(d[s] - K$dho[s]), bias_lo = quantile(bb, .025, na.rm = TRUE), bias_hi = quantile(bb, .975, na.rm = TRUE),
      level_t2 = sum(h[s]) / sum(K$H2[s]), level_lo = quantile(lb, .025, na.rm = TRUE), level_hi = quantile(lb, .975, na.rm = TRUE)) })) }))
OUT[, dom_share_below25 := NA_real_]; OUT[group == "dominant", dom_share_below25 := K[dom == TRUE, mean(D1 < 25)]]
fwrite(OUT, OF); print(OUT, digits = 4)
cat("P28_CHOSEN_DONE\n")
