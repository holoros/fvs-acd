## v143p2_score4.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 4: scoring of the selected candidate (arm SEL, run after the
## selection record md5) on every frame except the sealed set, and the decision rule of the plan, rules 1 to 6.
## mefia_ph_c is "previously inspected": every gate there carries that label.
##   V1    survivors in heavy and intermediate stands, pooled species, observed over predicted diameter increment by
##         d / Dq class (Dq the engine's start-of-projection Dq), predicted increment floored at 0.05 cm yr-1; every class
##         at or above 0.6 with 30 or more trees within 0.10 of 1 (point); paired plot bootstrap 95% interval, paired against
##         14.1. The class below 0.6 reported beside C2's and C5's (offline, not run: reported as not available if not run).
##   V1-L  light and low volume stands: paired upper 95% limit of the worsening against 14.1 (|ratio - 1| increase) <= 0.05.
##   P1-S  mean over heavy stands of S within 0.10 of mean S_obs; with and without the class below 0.6.
##   P1-NW total heavy gap no larger than A0 gap + implied release + 0.25 x observed heavy rate, and no larger than 14.1's.
##   P1    total heavy gap at tol 25% (reported). P2 intermediate, P3 light and low volume (as PREREG1: |gap| <= tol and,
##         for P3, the paired upper limit of the worsening against 14.1 <= 0.5 tol), tol 25%; read also at 15% and 35%.
##   P5    AGB bias over the 827 stands within +-5%.
##   N0    SEL on every set with no known tst equals frozen 14.1 byte for byte.
##   N1    leave one installation out arm SELN1: ctrn_c and pef_c TOTVOL %RMSE no worse than 14.1 by more than 0.5 points,
##         ctrn_fl TOTVOL absolute bias no larger; pef_c also split at tst 17.
##   N2    thinned grid (gSEL, REGIME thin, first 160 yr) has no relation flag that 14.1's frozen thinned grid lacks.
##   R1    100 and 200 yr gross volume production, thinned over unthinned twin, per cell: SEL ratio - 14.1 ratio (gC0f)
##         at most 0.02 in every cell.
##   R2    reported: survivor ratio by removal intensity (RF) class; a second thinning inside tau under C3 (m_T path).
## Usage: Rscript v143p2_score4.R <root>. Writes out/score4_*_DATA.csv (aggregates only). No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]
H <- "/users/PUOM0008/crsfaaron"
SD <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])))
source(file.path(SD, "v143p2_decomp_lib.R"))
O <- file.path(ROOT, "out"); W <- file.path(ROOT, "work"); A <- file.path(O, "arms")
PHW <- file.path(H, "acdx_20261016/postharv/work"); PHO <- file.path(H, "acdx_20261016/postharv/out")
B141 <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/out"); BAK <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bak141/out")
FRM <- file.path(H, "magplot/verify/gydbreg20260916/frames"); B141W <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/work")
wout <- function(x, nm) { f <- file.path(O, sprintf("score4_%s_DATA.csv", nm)); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "cn", "tree"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
FIT <- readRDS(file.path(W, "fit_SERVERONLY.rds")); SEL <- FIT$REC$selected
if (is.na(SEL)) stop("no selected candidate: step 4 does not run")
rd <- function(dir) { fs <- list.files(dir, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE); rbindlist(lapply(fs, fread), fill = TRUE) }
rdt <- function(dir, pat) rbindlist(lapply(list.files(dir, pattern = pat, full.names = TRUE), fread), fill = TRUE)
ci <- function(v) unname(quantile(v, c(.025, .975), na.rm = TRUE))
D2 <- readRDS(file.path(W, "decomp_mefia_ph_c_SERVERONLY.rds")); POP <- D2$POP; lk <- D2$lk
pr <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_pairs.csv"))
ti <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_init.csv")); t2 <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_t2.csv"))
cl <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"))[, .(STAND, PLOTKEY, HARVEST_TYPE, FORTYPGRP_V0_NAME, TST)]
## ---------------------------------------------------------------- decomposition and survivors under SEL (mefia_ph_c)
dS <- file.path(A, "SEL/mefia_ph_c"); resS <- rd(dS)
if (resS[RUN_OK != 1, .N] > 0) stop("SEL has stands with RUN_OK other than 1 on mefia_ph_c (K1)")
zS <- decompose(ti, t2, resS, rdt(dS, "_t1_split_tree\\.csv$"), rdt(dS, "_pred_t2_tree\\.csv$"), lk, pr, POP$STAND)
z0 <- D2$DEC$A0; z1 <- D2$DEC$`141`; z0$r1 <- D2$r1_A0; z1$r1 <- D2$r1_141
IDS <- merge(zS$D, POP[, .(STAND, HARVEST_TYPE)], by = "STAND")[, .(stands = .N, max_abs_resid = max(abs(resid))), by = HARVEST_TYPE]
M <- Reduce(function(x, y) merge(x, y, by = "STAND"), list(POP[, .(STAND, PLOTKEY, HARVEST_TYPE)],
  zS$D[, .(STAND, iv, t1 = BIOMASS_t1, o = BIOMASS_o, pS = BIOMASS_p, gS = gap, S_S = S, M_S = M, I_S = I, R_S = R, W_S = W)],
  z0$D[, .(STAND, g0 = gap, S_0 = S, S_obs = S_obs_rate, S_pred0 = S_pred_rate)], z1$D[, .(STAND, g1 = gap, p1 = BIOMASS_p, S_1 = S)]))
setorder(M, STAND)
set.seed(20261017L); NB <- 1000L; PL <- sort(unique(M$PLOTKEY))
WB <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL)))
WS <- WB[match(M$PLOTKEY, PL), , drop = FALSE]
cm <- function(x, i) { w <- WS[i, , drop = FALSE]; colSums(w * x[i]) / colSums(w) }
cls <- function(k) which(M$HARVEST_TYPE == k)
tolf <- function(k, f) f * mean(M$o[cls(k)] - M$t1[cls(k)]) / mean(M$iv[cls(k)])
PG <- rbindlist(lapply(c("heavy", "intermediate", "light", "low_volume"), function(k) { i <- cls(k); b <- cm(M$gS, i); b1 <- cm(M$g1, i)
  wors <- ci(abs(b) - abs(b1))[2]
  rbindlist(lapply(c(0.15, 0.25, 0.35), function(f) { t <- tolf(k, f); g <- mean(M$gS[i])
    data.table(class = k, gate = c(heavy = "P1", intermediate = "P2", light = "P3", low_volume = "P3")[[k]], tol_frac = f, tol = t, n = length(i),
               gap_SEL = g, lo = ci(b)[1], hi = ci(b)[2], gap_141 = mean(M$g1[i]), gap_A0 = mean(M$g0[i]), worsen_ul95 = wors,
               pass = if (k %in% c("heavy", "intermediate")) abs(g) <= t else abs(g) <= t && wors <= 0.5 * t) })) }))
P5 <- data.table(n = nrow(M), agb_bias_pct = 100 * (mean(M$pS) - mean(M$o)) / mean(M$o))[, pass := abs(agb_bias_pct) <= 5]
h <- cls("heavy")
P1S <- data.table(P1S = mean(M$S_S[h]), tol = 0.10 * mean(M$S_obs[h]), P1S_141 = mean(M$S_1[h]), P1S_A0 = mean(M$S_0[h]))[, pass := abs(P1S) <= tol]
## P1-S without the class below 0.6 (survivors at r >= 0.6 only), as in step 2
dqA <- zS$r1[is.finite(e1) & e1 > 0 & d1 > 0, .(DQ = sqrt(sum(e1 * d1^2) / sum(e1))), by = STAND]
rr <- merge(zS$r1, dqA, by = "STAND")[, lo06 := d1 / DQ < 0.6]
spn <- rr[U & fate == "surv" & !lo06, .(Sp = sum(e1 * (P - A1))), by = STAND]
ton <- merge(zS$trees_obs, unique(rr[, .(STAND, TREE_IDX, lo06)]), by = c("STAND", "TREE_IDX"))[U & fate == "surv" & !lo06, .(So = sum(e1 * (O - A1))), by = STAND]
x6 <- merge(merge(M[h, .(STAND, iv)], spn, by = "STAND", all.x = TRUE), ton, by = "STAND", all.x = TRUE); x6[is.na(Sp), Sp := 0][is.na(So), So := 0]
P1S[, `:=`(P1S_no06 = mean((x6$Sp - x6$So) / x6$iv), tol_no06 = 0.10 * mean(x6$So / x6$iv))][, pass_no06 := abs(P1S_no06) <= tol_no06]
impl <- mean(M$S_obs[h] - M$S_pred0[h]); obsr <- mean(M$o[h] - M$t1[h]) / mean(M$iv[h])
P1NW <- data.table(gap_SEL = mean(M$gS[h]), bound_release = mean(M$g0[h]) + impl + 0.25 * obsr, bound_141 = mean(M$g1[h]))[, pass := gap_SEL <= bound_release & gap_SEL <= bound_141]
ATT <- data.table(component = c("M", "I", "R"), value = c(mean(M$M_S[h]), mean(M$I_S[h]), mean(M$R_S[h])))[order(-abs(value))]
## ---------------------------------------------------------------- V1 and V1-L (survivor diameter increment)
svtree <- function(z, lab) { r <- z$r1[fate == "surv", .(dp = sum(e1 * dp) / sum(e1), d1 = d1[1], e1 = sum(e1), TREE2 = TREE2[1], sp = sp[1]), by = .(STAND, TREE_IDX)]
  r[t2[, .(STAND, TREE2 = TREE, d2 = DBH)], on = .(STAND, TREE2), d2 := i.d2]; setnames(r, "dp", paste0("dp_", lab)); r }
sv <- Reduce(function(x, y) merge(x, y[, c("STAND", "TREE_IDX", grep("^dp_", names(y), value = TRUE)), with = FALSE], by = c("STAND", "TREE_IDX")),
             list(svtree(zS, "S"), svtree(z1, "1"), svtree(z0, "0")))
sv <- merge(sv, dqA, by = "STAND"); sv <- merge(sv, M[, .(STAND, PLOTKEY, HARVEST_TYPE, iv)], by = "STAND"); sv <- merge(sv, cl[, .(STAND, FORTYPGRP_V0_NAME, TST)], by = "STAND")
sv[, `:=`(r = d1 / DQ, io = e1 * (d2 - d1))]
for (k in c("S", "1", "0")) sv[, (paste0("ip_", k)) := e1 * pmax(get(paste0("dp_", k)) - d1, 0.05 * iv)]
sv[, rcl := cut(r, c(0, 0.6, 0.85, 1.15, 1.5, Inf), right = FALSE)]
SWR <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
sv[, grp := fifelse(toupper(sp) %in% SWR, "softwood", "hardwood")]
qf <- fread(file.path(H, "v143p1/work/elig_quant_v143_SERVERONLY.csv"))[FRAME == "mefia_ph_c", .(STAND = KEY, RF)]
sv <- merge(sv, qf, by = "STAND", all.x = TRUE)
sv[, PJ := match(PLOTKEY, PL)]
v1cells <- function(z, by) z[, { bS <- vapply(seq_len(NB), function(b) { w <- WB[PJ, b]; sum(w * io) / sum(w * ip_S) }, 0)
    b1 <- vapply(seq_len(NB), function(b) { w <- WB[PJ, b]; sum(w * io) / sum(w * ip_1) }, 0)
    .(n_trees = .N, ratio_SEL = sum(io) / sum(ip_S), lo = ci(bS)[1], hi = ci(bS)[2], ratio_141 = sum(io) / sum(ip_1), lo_141 = ci(b1)[1], hi_141 = ci(b1)[2],
      ratio_A0 = sum(io) / sum(ip_0), worsen_ul95 = ci(abs(bS - 1) - abs(b1 - 1))[2]) }, by = by]
lb <- function(rcl) as.numeric(sub("^\\[([0-9.]+),.*$", "\\1", as.character(rcl)))
V1 <- v1cells(sv[HARVEST_TYPE %in% c("heavy", "intermediate")], "rcl")[order(rcl)][, gated := lb(rcl) >= 0.6 & n_trees >= 30][, pass := !gated | abs(ratio_SEL - 1) <= 0.10]
V1L <- v1cells(sv[HARVEST_TYPE %in% c("light", "low_volume")], "rcl")[order(rcl)][, gated := lb(rcl) >= 0.6 & n_trees >= 30][, pass := !gated | worsen_ul95 <= 0.05]
V1_SPLIT <- rbind(v1cells(sv[HARVEST_TYPE %in% c("heavy", "intermediate")], c("grp", "rcl"))[, split := "species group"],
  v1cells(sv[HARVEST_TYPE %in% c("heavy", "intermediate")], c("FORTYPGRP_V0_NAME", "rcl"))[n_trees >= 30][, split := "forest type group"],
  v1cells(sv[HARVEST_TYPE %in% c("heavy", "intermediate")][, sup := fifelse(r <= 2.9848 & is.finite(RF) & RF <= 0.7208, "in CTRN support", "out of support")], c("sup", "rcl"))[, split := "support"],
  v1cells(sv[HARVEST_TYPE %in% c("heavy", "intermediate")], c("TST"))[, split := "tst year"], fill = TRUE)
LEVEL <- if (!all(V1$pass)) { g <- V1[gated == TRUE]; data.table(same_side = all(g$ratio_SEL > 1) || all(g$ratio_SEL < 1), range = diff(range(g$ratio_SEL)))[, reading := fifelse(same_side & range < 0.10, "level (L or A0 question)", "form")] } else NULL
R2 <- v1cells(sv[HARVEST_TYPE %in% c("heavy", "intermediate", "light", "low_volume")][, rfc := cut(RF, c(-Inf, 0.35, 0.65, Inf))], c("rfc"))
## ---------------------------------------------------------------- N0
SUFF <- c("_results.csv", "_pred_t2_tree.csv", "_pred_yr1_tree.csv", "_t1_split_tree.csv", "_traj.csv", "_pd_t1.csv", "_pd_t2.csv")
N0 <- rbindlist(lapply(setdiff(list.dirs(file.path(A, "SEL"), recursive = FALSE, full.names = FALSE), c("counters", "mefia_ph_c", "ctrn_c", "ctrn_fl", "pef_c", "nhvt_ph_c")), function(s) {
  old <- file.path(B141, "v141LT", s); new <- file.path(A, "SEL", s); fs <- sort(list.files(old, pattern = "^c[0-9]{3}_results\\.csv$"))
  eq <- unlist(lapply(fs, function(f) { ch <- sub("_results\\.csv$", "", f); vapply(SUFF, function(sf) { fo <- file.path(old, paste0(ch, sf)); fn <- file.path(new, paste0(ch, sf))
    !file.exists(fo) || (file.exists(fn) && identical(unname(tools::md5sum(fo)), unname(tools::md5sum(fn)))) }, TRUE) }))
  data.table(set = s, files = length(eq), identical = all(eq)) }))
## ---------------------------------------------------------------- N1 (leave one installation out)
nmet <- function(p, o, kind) if (kind == "rmse") 100 * sqrt(mean((p - o)^2)) / mean(o) else abs(mean(p - o))
N1 <- rbindlist(lapply(list(c("ctrn_c", "rmse"), c("pef_c", "rmse"), c("ctrn_fl", "bias")), function(z) { s <- z[1]; k <- z[2]
  x <- merge(rd(file.path(B141, "v141LT", s))[, .(STAND, ok1 = RUN_OK, o = TOTVOL_o, p1 = TOTVOL_p)], rd(file.path(A, "SELN1", s))[, .(STAND, okS = RUN_OK, pS = TOTVOL_p)], by = "STAND")[ok1 == 1 & okS == 1]
  out <- data.table(set = s, metric = if (k == "rmse") "TOTVOL pct RMSE" else "TOTVOL abs bias", n = nrow(x), SEL_loio = nmet(x$pS, x$o, k), v141 = nmet(x$p1, x$o, k))
  out[, pass := if (k == "rmse") SEL_loio - v141 <= 0.5 else SEL_loio <= v141]
  if (s == "pef_c") { tp <- fread(file.path(B141W, "v142_bench141_tst_pef_c_DATA_2026-09-25.csv"), colClasses = list(character = "TST"))[, .(STAND, T = suppressWarnings(as.numeric(TST)))]
    y <- merge(x, tp, by = "STAND"); out[, `:=`(SEL_tst_le17 = y[is.finite(T) & T <= 17, nmet(pS, o, k)], v141_tst_le17 = y[is.finite(T) & T <= 17, nmet(p1, o, k)],
      SEL_tst_gt17 = y[is.finite(T) & T > 17, nmet(pS, o, k)], v141_tst_gt17 = y[is.finite(T) & T > 17, nmet(p1, o, k)])] }
  out }), fill = TRUE)
## ---------------------------------------------------------------- N2 and R1 (grid)
rdg <- function(dir, reg, cfg) rbindlist(lapply(sprintf("%s/traj_%s_%s_cell%02d.csv", dir, reg, cfg, 0:19), function(f) if (file.exists(f)) fread(f) else NULL), fill = TRUE)
FRp <- function(Dq) 10^(5.745 - 1.892 * log10(Dq))
rein <- function(D) { rs <- D[, { d <- .SD[order(age)]; dn <- diff(log10(d$TPH)); dq <- diff(log10(d$QMD)); k <- which(dn < -1e-9 & dq > 1e-9)
  .(sl = if (length(k)) median(dn[k] / dq[k]) else NA_real_) }, by = cell]; median(rs$sl, na.rm = TRUE) }
flags <- function(D) c(BAPH_bound = max(D$BAPH, na.rm = TRUE) > 74.9, frontier = D[exceed > 0, uniqueN(cell)] > 0,
  site_order = is.unsorted(D[age == 160, .(b = median(BAPH)), by = esi][order(esi)]$b), Q4_fail = !(abs(rein(D) + 1.52) < 0.5))
f141 <- flags(rdg(BAK, "thin", "v141LT")); fS <- flags(rdg(file.path(O, "grid/gSEL"), "thin", "v143p2gSEL")[age <= 160])
N2 <- data.table(flag = names(f141), v141 = f141, SEL = fS)[, new_violation := SEL & !v141]
gC <- rbind(rdg(file.path(O, "grid/gC0f"), "thin", "v143p2gC0f")[, arm := "141"], rdg(file.path(O, "grid/gC0f"), "none", "v143p2gC0f")[, arm := "141"],
            rdg(file.path(O, "grid/gSEL"), "thin", "v143p2gSEL")[, arm := "SEL"], rdg(file.path(O, "grid/gSEL"), "none", "v143p2gSEL")[, arm := "SEL"], fill = TRUE)
R1 <- dcast(gC[age %in% c(100, 200), .(arm, cell, age, REGIME, GROSS_VOL)], cell + age ~ arm + REGIME, value.var = "GROSS_VOL")
R1[, `:=`(ratio_141 = `141_thin` / `141_none`, ratio_SEL = SEL_thin / SEL_none)][, excess := ratio_SEL - ratio_141][, pass := is.finite(excess) & excess <= 0.02]
## gC0f thinned trajectory must equal the frozen 14.1 thinned grid over the frozen 160 yr in every frozen column (harness copy check)
HC <- rbindlist(lapply(0:19, function(c) { x <- fread(file.path(BAK, sprintf("traj_thin_v141LT_cell%02d.csv", c)))[, !"config"]
  y <- fread(file.path(O, "grid/gC0f", sprintf("traj_thin_v143p2gC0f_cell%02d.csv", c)))[age <= 160, names(x), with = FALSE]
  data.table(cell = c, equal = isTRUE(all.equal(x, y, check.attributes = FALSE, tolerance = 0))) }))
## ---------------------------------------------------------------- closed loop check on the fit set (ctrn_c, full-data SEL)
## R2 second thinning under C3: m_T path for a thinning at tst 0 and a second one 2 yr later, if C3 is selected
R2b <- if (SEL == "C3") { p <- FIT$REC$FULL$C3$par; t <- 0:15; data.table(tst = t, mT_first = 1 + p[["alpha"]] * (t / p[["tau"]]) * exp(1 - t / p[["tau"]]),
  mT_second_reset_at_2 = 1 + p[["alpha"]] * (pmax(t - 2, 0) / p[["tau"]]) * exp(1 - pmax(t - 2, 0) / p[["tau"]])) } else NULL
## ---------------------------------------------------------------- decision (rules 3 to 6)
fails <- c(if (!all(V1$pass)) "V1", if (!P1S$pass) "P1-S", if (!P1NW$pass) "P1-NW", if (!all(PG[tol_frac == 0.25 & gate %in% c("P2", "P3"), pass])) "P2/P3",
           if (!P5$pass) "P5", if (!all(N0$identical)) "N0", if (!all(N1$pass)) "N1", if (any(N2$new_violation)) "N2", if (!all(R1$pass)) "R1", if (!all(V1L$pass)) "V1-L")
rule <- if (!all(V1$pass)) "rule 3: V1 fails, not adopted" else if (any(c("P1-S", "P1-NW", "P2/P3", "P5") %in% fails)) "rule 4: not adopted" else
  if (length(fails)) "rule 5: not adopted, trade-off reported" else "rule 6: a 14.3 candidate (passes on a previously inspected set)"
sens <- PG[gate %in% c("P2", "P3"), .(pass_all = all(pass)), by = tol_frac]
DEC <- data.table(selected = SEL, failing = paste(fails, collapse = " "), verdict = rule, tolerance_sensitive = length(unique(sens$pass_all)) > 1,
                  heavy_label = sprintf("heavy AGB gap carried, attributed to %s; total heavy gap %.3f", ATT$component[1], mean(M$gS[h])))
print(DEC)
wout(PG, "pgates"); wout(P5, "p5"); wout(P1S, "p1s"); wout(P1NW, "p1nw"); wout(ATT, "attribution"); wout(IDS, "identity_SEL")
wout(V1, "v1"); wout(V1L, "v1l"); wout(V1_SPLIT, "v1_splits"); if (!is.null(LEVEL)) wout(LEVEL, "level_reading"); wout(R2, "r2_by_rf")
if (!is.null(R2b)) wout(R2b, "r2_second_thinning_C3"); wout(N0, "n0"); wout(N1, "n1"); wout(N2, "n2"); wout(R1, "r1"); wout(HC, "grid_harness_copy_check"); wout(DEC, "decision")
saveRDS(list(M = M, sv = sv, zS = zS[c("D", "trees_obs")]), file.path(W, "score4_SERVERONLY.rds"))
cat("SCORE4_DONE\n")
