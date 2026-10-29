## v143 PREREG4 exploratory reading E0 (before registration; NOT registered; reads only frozen 14.1 long200 outputs that the
## 16 October benchmark already inspected, and no observed mortality). Question: in the frozen 14.1 200 yr runs, which branch
## of the 14.0.4 L2 stand decrement sets the kill as stands age, the Garcia branch or the cloglog floor? Approximation: the
## decrement is re-evaluated on 5 yr trajectory steps with traj TPH, BA, QMD, TOPHT and t1 species shares (bf, ih), dt = 5,
## 14.0.4 default fixes. Also: key alignment of t1_split_tree ids with frame init ids (mechanics only). Aggregates only.
suppressMessages(library(data.table))
Sys.setenv(ACD_V14_LEVER_ONLY = "1")
source("/users/PUOM0008/crsfaaron/v14_0_4_20260917/AcadianGY_14.0.4.r")
B <- .acd_v14_bundle("/users/PUOM0008/crsfaaron/magplot/verify/p23/v14_coef_bundle_2026-09-08.rds")
L <- "/users/PUOM0008/crsfaaron/acdx_20261016/long200/out/v141LT/mefia_l_c"
TJ <- rbindlist(lapply(list.files(L, "_traj\\.csv$", full.names = TRUE), fread, select = c("STAND", "yr", "TPH", "BA", "QMD", "TOPHT", "MORT_BA_ALL", "BIOMASS")))
T1 <- rbindlist(lapply(list.files(L, "_t1_split_tree\\.csv$", full.names = TRUE), fread))
T1[, sp2 := ifelse(sp %in% names(.acd_v14_spp_alias), .acd_v14_spp_alias[sp], sp)]
T1[, ba := dbh^2 * pi / 40000 * expf]
SFG <- c("BF", "RS", "WS", "BS", "NS", "TA", "WC"); PHG <- c("WP", "RP", "EH", "JP")
SW <- T1[, .(bf = sum(ba[sp2 == "BF"]) / sum(ba), ih = sum(ba[sp2 %in% .acd_v14_intol_hw]) / sum(ba),
            sfs = sum(ba[sp2 %in% SFG]) / sum(ba), phs = sum(ba[sp2 %in% PHG]) / sum(ba)), by = STAND]
SW[, cls := ifelse(sfs >= pmax(phs, 1 - sfs - phs), "SF", "NSF")]
setorder(TJ, STAND, yr); TJ[, `:=`(H2 = shift(TOPHT, -1), dt = shift(yr, -1) - yr), by = STAND]
cat("traj step lengths (yr):\n"); print(table(TJ$dt, useNA = "ifany"))
TJ <- merge(TJ[is.finite(H2) & dt > 0], SW, by = "STAND")
fx <- list(threshold = TRUE, pscale = FALSE, floordomain = FALSE, stepinv = TRUE, dref = 5)
res <- TJ[TPH > 0 & BA > 0, {
  d <- .acd_v14_stand_decrement(list(N1 = TPH, BA1 = BA, Dq1 = QMD, H1 = TOPHT, H2 = H2, bf = bf, ih = ih, mgd = 0, dt = dt), B, NA_character_, TRUE, fx)
  nf <- TPH * (1 - d$pf)
  .(floor_binds = as.integer(!d$fit_ok || nf < d$N2_L1), kill_L2 = TPH - d$N2_L2, kill_floor = TPH - nf, kill_L1 = TPH - d$N2_L1) },
  by = .(STAND, yr, cls)]
res[, yb := cut(yr, c(-1, 49, 99, 149, 200), labels = c("0-49", "50-99", "100-149", "150-199"))]
cat("QMD units check (median QMD in traj):", median(TJ$QMD), "\n")
out <- res[, .(stand_steps = .N, stands = uniqueN(STAND), share_floor_binds = round(mean(floor_binds), 3),
               med_kill_L2_tph_per_step = round(median(kill_L2), 2), med_kill_L1 = round(median(kill_L1), 2), med_kill_floor = round(median(kill_floor), 2)), by = .(cls, yb)][order(cls, yb)]
print(out)
fwrite(out, "/users/PUOM0008/crsfaaron/v143p4/explore/e0_branch_by_class_age_DATA.csv")
cat("class counts at t1 (composition rule):\n"); print(SW[, .N, by = cls])
## key alignment (mechanics only)
FR <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames"
I0 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_init.csv"), select = c("STAND", "TREE"))
k1 <- unique(paste(T1$STAND, T1$tree)); k0 <- unique(paste(I0$STAND, I0$TREE))
cat(sprintf("t1_split keys found in init: %.4f of %d; init keys found in t1_split: %.4f of %d\n", mean(k1 %in% k0), length(k1), mean(k0 %in% k1), length(k0)))
