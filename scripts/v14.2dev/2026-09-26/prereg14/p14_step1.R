## PREREG14 step 1 (qc_c, qc_fl, nb_c): (a) measured height share, (b) height level L0 to L3, (c) imputation facts,
## (d) volume decomposition, QC harvest screen all and screened. Arm v141LT tree lists. Diagnostic only. No em dashes.
source(file.path(Sys.getenv("P14_ROOT", "/home/aaron/jobs/v142p14"), "scripts/p14_common.R"))
SETS <- c("qc_c", "qc_fl", "nb_c")
## ---- C1 and C2 on the full results (always, also in smoke) ----------------------------------
C <- list(); SCR <- list()
for (s in SETS) {
  pr <- fread(file.path(IN, "frames", sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "PLOTKEY", "Y1", "Y2"))
  cs <- cut_stands(pr); SCR[[s]] <- data.table(STAND = pr$STAND, cut = pr$STAND %in% cs)
  for (arm in c("v141LT", "v141off")) { r <- fread(file.path(IN, arm, s, "c001_results.csv"))[RUN_OK == 1]; r[, cut := STAND %in% cs]
    for (pop in c("all", "screened")) { x <- if (pop == "all") r else r[cut == FALSE]
      C[[paste(s, arm, pop)]] <- data.table(set = s, arm = arm, pop = pop, stands = nrow(x), cut_stands = sum(r$cut), TOTVOL_ratio = sum(x$TOTVOL_p) / sum(x$TOTVOL_o)) } }
}
C <- rbindlist(C)
ref <- fread(file.path(IN, "ref/gyr142-qc-harvest-screen_DATA_2026-09-26.csv"))
chk <- merge(C, ref[, .(set, arm, pop, stands_ref = stands, cut_ref = cut_pairs, ratio_ref = TOTVOL_ratio)], by = c("set", "arm", "pop"))
print(chk, digits = 6)
if (nrow(chk) != nrow(C)) hs("C1/C2: diag3 screen table lacks rows")
if (any(chk$stands != chk$stands_ref | chk$cut_stands != chk$cut_ref)) hs("C1: screen counts differ from diag3")
if (C[set == "qc_c" & arm == "v141LT", cut_stands[1]] != 65L || C[set == "qc_fl" & arm == "v141LT", cut_stands[1]] != 11L) hs("C1: expected 65 qc_c and 11 qc_fl cut stands")
if (any(abs(chk$TOTVOL_ratio - chk$ratio_ref) > 1e-9)) hs("C2: TOTVOL ratios differ from diag3")
if (abs(C[set == "qc_c" & arm == "v141LT" & pop == "screened", TOTVOL_ratio] - 1.122) > 0.001 ||
    abs(C[set == "qc_c" & arm == "v141off" & pop == "screened", TOTVOL_ratio] - 1.100) > 0.001) hs("C2: inherited 1.122 or 1.100 not reproduced")
wout(chk, "check-C1C2-screen")

A <- list(); L <- list(); I <- list(); IC <- list(); VS <- list(); VP <- list()
for (s in SETS) {
  prov <- if (grepl("^qc", s)) "QC" else "NB"; cat(sprintf("==== %s (%s)\n", s, prov))
  pr <- fread(file.path(IN, "frames", sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "Y1", "Y2", "interval_years"))
  r <- fread(file.path(IN, "v141LT", s, "c001_results.csv"))[RUN_OK == 1, .(STAND, SMD = SCORE_MINDBH_USED, TOTVOL_t1, TOTVOL_o, TOTVOL_p, iv)]
  r <- merge(merge(r, pr, by = "STAND"), SCR[[s]], by = "STAND")
  if (SMOKE_N > 0) r <- r[seq_len(min(.N, SMOKE_N))]
  ST <- r$STAND
  cat(sprintf("stands %d (cut %d); runner horizon differs from Y2 - Y1 in %d stands\n", nrow(r), sum(r$cut), sum(r$iv != r$Y2 - r$Y1)))
  F  <- fread(file.path(IN, "frames", sprintf("bench_gyr_%s_tree_init.csv", s)))[, row0 := seq_len(.N), by = STAND][STAND %in% ST]
  O2 <- fread(file.path(IN, "frames", sprintf("bench_gyr_%s_tree_t2.csv", s)))[, row0 := seq_len(.N), by = STAND][STAND %in% ST]
  F[, `:=`(sp = mapsp(SP), meas = is.finite(HT) & HT > 0, cls = cls3(DBH))]; F[, hw := toupper(sp) %in% .a9$sp]
  O2[, `:=`(meas = is.finite(HT) & HT > 0, cls = cls3(DBH))]
  T1 <- fread(file.path(IN, "v141LT", s, "c001_t1_split_tree.csv"))[STAND %in% ST]
  YR <- fread(file.path(IN, "v141LT", s, "c001_pred_yr1_tree.csv"))[STAND %in% ST]
  P  <- fread(file.path(IN, "v141LT", s, "c001_pred_t2_tree.csv"))[STAND %in% ST]
  if (!setequal(unique(T1$STAND), ST) || !setequal(unique(P$STAND), ST) || !setequal(unique(YR$STAND), ST)) hs("%s: runner tree lists and RUN_OK stands differ", s)
  ## ---- split id map, checked record by record against the runner's t1 list
  if (s == SETS[1]) split_selftest(F)
  M <- split_map(F)
  x <- merge(M, T1, by = c("STAND", "tree"), all = TRUE, suffixes = c("", "_r"))
  bad <- x[is.na(row0) | is.na(sp_r) | sp != sp_r | abs(dbh - dbh_r) > 1e-6 | abs(expf - expf_r) > 1e-6 * pmax(1, expf)]
  if (nrow(bad)) hs("%s: split map disagrees with the runner t1 list on %d records (first %s tree %s)", s, nrow(bad), bad$STAND[1], bad$tree[1])
  cat(sprintf("split map ok: %d records, %d frame trees, %d hardwood trees\n", nrow(M), nrow(F), sum(F$hw)))
  ## ---- L0 identity: runner t1 ht equals measured HT; unmeasured trees enter as NA
  x <- merge(x, F[, .(STAND, row0, HT, meas)], by = c("STAND", "row0"))
  n_l0 <- x[meas == TRUE & !eqna(ht, HT), .N]; n_na <- x[meas == FALSE & !is.na(ht), .N]
  if (n_l0 > 0) hs("%s: L0 runner t1 ht differs from measured HT on %d records", s, n_l0)
  ## ---- per original tree: pht and year 1 height, predicted t2 height and diameter
  yy <- merge(YR[ing == 0], M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
  if (nrow(yy) != YR[ing == 0, .N]) hs("%s: year 1 records without a split map row", s)
  Y0 <- yy[, .(pht = sum(pht * expf) / sum(expf), pht_spread = max(pht) - min(pht), h_yr1 = sum(ht * expf) / sum(expf)), by = .(STAND, row0)]
  pp <- merge(P[ing == 0], M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
  if (nrow(pp) != P[ing == 0, .N]) hs("%s: t2 records without a split map row", s)
  P0 <- pp[, .(Hp = sum(ht * expf) / sum(expf), Dp = sum(dbh * expf) / sum(expf)), by = .(STAND, row0)]
  FT <- merge(merge(F, Y0, by = c("STAND", "row0"), all.x = TRUE), P0, by = c("STAND", "row0"), all.x = TRUE)
  FT <- merge(FT, r[, .(STAND, cut, interval_years)], by = "STAND")
  ## ---- QC pass 28 tags, row aligned with the frozen frames (hard stop otherwise)
  if (prov == "QC") {
    for (tt in c("init", "t2")) {
      G <- fread(file.path(IN, "pass28qc", sprintf("bench_gyr_%s_tree_%s.csv", s, tt)))[, row0 := seq_len(.N), by = STAND][STAND %in% ST]
      B <- if (tt == "init") F else O2
      z <- merge(B[, .(STAND, row0, SP, DBH, HT, EXPF)], G[, .(STAND, row0, SP2 = SP, DBH2 = DBH, HT2 = HT, EXPF2 = EXPF, TAG = TREE)], by = c("STAND", "row0"), all = TRUE)
      if (nrow(z) != nrow(B) || nrow(z) != nrow(G) || anyNA(z$SP) || anyNA(z$SP2) || any(z$SP != z$SP2) || any(!eqna(z$DBH, z$DBH2)) ||
          any(!eqna(z$HT, z$HT2)) || any(!eqna(z$EXPF, z$EXPF2))) hs("%s: pass 28 %s frame is not row aligned with the frozen frame", s, tt)
      if (tt == "init") FT <- merge(FT, z[, .(STAND, row0, TAG)], by = c("STAND", "row0")) else O2 <- merge(O2, z[, .(STAND, row0, TAG)], by = c("STAND", "row0"))
    }
    cat("pass 28 tag frames row aligned (t1 and t2)\n")
  }
  ## ---- (a) measured height share
  for (pop in c("all", "screened")) { fs <- if (pop == "all") FT else FT[cut == FALSE]; os <- O2[STAND %in% fs$STAND]
    for (tt in c("t1", "t2")) { d <- if (tt == "t1") fs else os
      a <- rbind(d[, .(trees = .N, stands = uniqueN(STAND), measured = sum(meas), share = mean(meas), share_expf = sum(EXPF * meas) / sum(EXPF)), by = .(cls = as.character(cls))],
                 d[, .(cls = "all", trees = .N, stands = uniqueN(STAND), measured = sum(meas), share = mean(meas), share_expf = sum(EXPF * meas) / sum(EXPF))])
      A[[paste(s, pop, tt)]] <- a[, `:=`(set = s, pop = pop, time = tt, note = if (prov == "QC") "pass 28 tag frames identical (row aligned check)" else "frozen frame only")] } }
  ## ---- (c) imputation facts
  IC[[s]] <- data.table(set = s, records = nrow(M), l0_mismatch = n_l0, unmeasured_with_ht = n_na, pht_missing = FT[is.na(pht), .N],
    pht_max_spread_within_tree = max(FT$pht_spread, na.rm = TRUE),
    yr1_minus_pht_unmeasured_min = FT[meas == FALSE, min(h_yr1 - pht, na.rm = TRUE)], yr1_minus_pht_unmeasured_median = FT[meas == FALSE, median(h_yr1 - pht, na.rm = TRUE)],
    yr1_minus_pht_unmeasured_max = FT[meas == FALSE, max(h_yr1 - pht, na.rm = TRUE)], yr1_minus_ht_measured_median = FT[meas == TRUE, median(h_yr1 - HT, na.rm = TRUE)],
    afac = AFAC[[prov]], equation = "pred_ht (AcadianGY_13.1 calc_ht) where ht NA, 0 or above 50 and dbh above 2.5; dht.mult scales dht only")
  ## ---- (b) level: L1 pht vs HT1, L2 himp vs HT1 on measured trees; L3 on tag matched survivors (QC)
  mt <- FT[meas == TRUE & is.finite(pht)][, `:=`(H1 = HT, himp1 = himp(sp, DBH))]
  S <- NULL
  if (prov == "QC") {
    t1g <- FT[TAG < 9e6]; t2g <- O2[TAG < 9e6, .(STAND, TAG, SP2 = SP, H2 = fifelse(meas, HT, NA_real_))]
    d1 <- t1g[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2g[, .N, by = .(STAND, TAG)][N > 1]
    t1g <- t1g[!d1, on = .(STAND, TAG)]; t2g <- t2g[!d2, on = .(STAND, TAG)]
    sv <- merge(t1g, t2g, by = c("STAND", "TAG"))
    S <- sv[SP == SP2 & is.finite(H2) & is.finite(Hp)]
    cat(sprintf("QC tag matched: %d pairs, same SP %d, with measured HT2 %d; duplicate tag keys dropped t1 %d t2 %d\n", nrow(sv), sv[SP == SP2, .N], nrow(S), nrow(d1), nrow(d2)))
    if (SMOKE_N == 0 && s == "qc_c") {  ## C3: diag3 reproduction, softwood records, diag3 filters verbatim
      c3 <- merge(FT[hw == FALSE & TAG < 9e6 & meas == TRUE & is.finite(Hp), .(STAND, TAG, D1 = DBH, H1 = HT, Hp, interval_years)],
                  O2[TAG < 9e6 & meas == TRUE, .(STAND, TAG, H2 = HT)], by = c("STAND", "TAG"))
      c3r <- c3[, .(trees = .N, ratio = mean((Hp - H1) / interval_years) / mean((H2 - H1) / interval_years)), by = .(cls = as.character(cls3(D1)))]
      rf <- fread(file.path(IN, "ref/gyr142-ht-tagcheck_DATA_2026-09-26.csv"))[set == "qc_c", .(cls, trees_ref = trees, ratio_ref = ratio)]
      c3r <- merge(c3r, rf, by = "cls", all = TRUE); print(c3r, digits = 8); wout(c3r, "check-C3-diag3")
      if (anyNA(c3r) || any(c3r$trees != c3r$trees_ref) || any(abs(c3r$ratio - c3r$ratio_ref) > 1e-9)) hs("C3: diag3 QC tag check not reproduced")
    }
  }
  for (pop in c("all", "screened")) { ok <- if (pop == "all") r$STAND else r[cut == FALSE, STAND]
    for (cc in c("all", levels(cls3(1)))) { sel <- function(d, dc) if (cc == "all") d[STAND %in% ok] else d[STAND %in% ok & as.character(cls3(dc)) == cc]
      m1 <- sel(mt, mt$DBH)
      L[[paste(s, pop, cc, "L1")]] <- cbind(data.table(set = s, prov = prov, pop = pop, cls = cc, measure = "L1 pht vs measured HT1"), levsum(m1, "H1", "pht"))
      L[[paste(s, pop, cc, "L2")]] <- cbind(data.table(set = s, prov = prov, pop = pop, cls = cc, measure = "L2 himp vs measured HT1"), levsum(m1, "H1", "himp1"))
      if (!is.null(S)) { s3 <- sel(S, S$DBH)
        L[[paste(s, pop, cc, "L3")]] <- cbind(data.table(set = s, prov = prov, pop = pop, cls = cc, measure = "L3 predicted t2 vs measured HT2, tag survivors"), levsum(s3, "H2", "Hp"))
        s4 <- s3[meas == TRUE][, `:=`(dho = (H2 - HT) / interval_years, dhp = (Hp - HT) / interval_years)]
        L[[paste(s, pop, cc, "L3i")]] <- cbind(data.table(set = s, prov = prov, pop = pop, cls = cc, measure = "L3 on the increment sample (HT1 also measured)"), levsum(s4, "H2", "Hp"))
        if (nrow(s4)) { b1 <- bratio(s4$STAND, s4$dhp, s4$dho); b2 <- bratio(s4$STAND, s4$dho, s4$dhp) * AFAC[[prov]]
          I[[paste(s, pop, cc)]] <- data.table(set = s, prov = prov, pop = pop, cls = cc, trees = nrow(s4), stands = uniqueN(s4$STAND),
            obs_dht_m_yr = mean(s4$dho), pred_dht_m_yr = mean(s4$dhp), pred_over_obs = b1[1], pred_over_obs_lo95 = b1[2], pred_over_obs_hi95 = b1[3],
            afac = AFAC[[prov]], R_static = b2[1], R_lo95 = b2[2], R_hi95 = b2[3], obs_neg_share = mean(s4$dho < 0), thin = nrow(s4) < 30 | uniqueN(s4$STAND) < 10) } } } }
  ## ---- (d) volume decomposition per stand
  sm <- r[, .(STAND, SMD)]
  vo <- merge(O2, sm, by = "STAND")[, .(V_o = totvol(mapsp(SP), DBH, HT, EXPF, SMD[1]), V_oh = totvol(mapsp(SP), DBH, rep(NA_real_, .N), EXPF, SMD[1])), by = STAND]
  vt <- merge(FT, sm, by = "STAND")[, .(V_t1 = totvol(sp, DBH, HT, EXPF, SMD[1]), V_t1m = totvol(sp, DBH, fifelse(meas, HT, pht), EXPF, SMD[1])), by = STAND]
  PX <- merge(P, M[, .(STAND, tree, row0)], by = c("STAND", "tree"), all.x = TRUE)
  if (!is.null(S)) PX <- merge(PX, S[, .(STAND, row0, H2s = H2)], by = c("STAND", "row0"), all.x = TRUE) else PX[, H2s := NA_real_]
  PX[ing == 1, H2s := NA_real_]
  vp <- merge(PX, sm, by = "STAND")[, .(V_p = totvol(sp, dbh, ht, expf, SMD[1]), V_ph = totvol(sp, dbh, rep(NA_real_, .N), expf, SMD[1]),
          V_x = totvol(sp, dbh, H2s, expf, SMD[1]), V_xm = totvol(sp, dbh, fifelse(is.finite(H2s), H2s, ht), expf, SMD[1]),
          subst_share_expf = sum(expf[is.finite(H2s) & dbh >= SMD[1]]) / sum(expf[dbh >= SMD[1]])), by = STAND]
  VV <- Reduce(function(a, b) merge(a, b, by = "STAND"), list(r[, .(STAND, cut, SMD, TOTVOL_t1, TOTVOL_o, TOTVOL_p)], vo, vt, vp))
  if (nrow(VV) != nrow(r)) hs("%s: volume table lost stands", s)
  rel <- function(a, b) abs(a - b) / pmax(1, abs(b))
  if (any(rel(VV$V_o, VV$TOTVOL_o) > 1e-6) || any(rel(VV$V_p, VV$TOTVOL_p) > 1e-6) || any(rel(VV$V_t1, VV$TOTVOL_t1) > 1e-6))
    hs("C5 %s: recomputed TOTVOL does not match c001_results (max rel o %.2e p %.2e t1 %.2e)", s, max(rel(VV$V_o, VV$TOTVOL_o)), max(rel(VV$V_p, VV$TOTVOL_p)), max(rel(VV$V_t1, VV$TOTVOL_t1)))
  cat(sprintf("C5 ok: %d stands\n", nrow(VV)))
  VS[[s]] <- VV[, set := s]
  for (pop in c("all", "screened")) { v <- if (pop == "all") VV else VV[cut == FALSE]
    for (pq in list(c("V_p", "V_o", "total"), c("V_x", "V_o", "diameter/stem part (observed HT2 on matched survivors, himp elsewhere)"),
                    c("V_p", "V_x", "height part"), c("V_ph", "V_oh", "himp on both sides"), c("V_xm", "V_o", "matched HT2 substituted, model height elsewhere"),
                    c("V_t1m", "V_t1", "t1: model imputation (pht) vs scoring imputation (himp)"))) {
      b <- bratio(v$STAND, v[[pq[1]]], v[[pq[2]]])
      VP[[paste(s, pop, pq[1], pq[2])]] <- data.table(set = s, prov = prov, pop = pop, stands = nrow(v), ratio = paste0(pq[1], "/", pq[2]), what = pq[3],
        est = b[1], lo95 = b[2], hi95 = b[3], subst_share_expf = sum(v$subst_share_expf * v$V_o) / sum(v$V_o), thin = nrow(v) < 10) }
    VP[[paste(s, pop, "sec")]] <- data.table(set = s, prov = prov, pop = pop, stands = nrow(v), ratio = "(V_p/V_o)/(V_ph/V_oh)", what = "height part, himp convention (point only)",
      est = (sum(v$V_p) / sum(v$V_o)) / (sum(v$V_ph) / sum(v$V_oh)), lo95 = NA_real_, hi95 = NA_real_, subst_share_expf = NA_real_, thin = nrow(v) < 10) }
}
A <- rbindlist(A); L <- rbindlist(L, fill = TRUE); I <- rbindlist(I); IC <- rbindlist(IC); VS <- rbindlist(VS); VP <- rbindlist(VP)
print(IC); print(L[cls == "all"], digits = 4); print(I, digits = 4); print(VP, digits = 4)
wout(A, "s1a-measured-share"); wout(L, "s1b-level"); wout(I, "s1b-increment-qc"); wout(IC, "s1c-imputation")
wout(VS, "s1d-volume-stand"); wout(VP, "s1d-volume-pooled")
## ---- pre-registered evidence (primary: QC screened, NB all)
prim <- function(d) d[(prov == "QC" & pop == "screened") | (prov == "NB" & pop == "all")]
E1 <- prim(L[grepl("^L1|^L3 predicted", measure) & trees > 0])[, .(hyp = "H-level", set, prov, pop, cls, measure, n = trees, stands, est = ratio, lo95, hi95, thin,
  supports = !thin & (ratio < 0.95 | ratio > 1.05) & (lo95 > 1 | hi95 < 1), strong = !thin & (lo95 > 1.05 | hi95 < 0.95))]
E2 <- prim(VP[ratio == "V_x/V_o"])[, .(hyp = "H-volume", set, prov, pop, cls = "all", measure = ratio, n = NA_integer_, stands, est, lo95, hi95, thin,
  supports = !thin & est > 1.05 & lo95 > 1, strong = !thin & hi95 < 1.05)][, strong := NA][, verdict := fifelse(supports, "supported", fifelse(!thin & hi95 < 1.05, "not supported", "inconclusive"))]
E3 <- if (nrow(I)) prim(I)[, .(hyp = "H-increment", set, prov, pop, cls, measure = "R = obs/pred x AFAC", n = trees, stands, est = R_static, lo95 = R_lo95, hi95 = R_hi95, thin,
  supports = !thin & (R_static < 0.9 | R_static > 1.1) & (R_lo95 > 1 | R_hi95 < 1), strong = NA)] else NULL
EV <- rbindlist(list(E1, E2, E3), fill = TRUE); print(EV, digits = 4); wout(EV, "s1-evidence")
cat("STEP1_DONE\n")
