## PREREG35 re-derivation [F9]. Sources no scorer and no PREREG35 script: its own read of results, frames, per tree t2 lists,
## site draws and the NSVB reference tables. Re-derives check (a) counts and t1 zero shares on every r2 set, and the
## established at t1 pooled ratio, bias, percent RMSE and 95 percent site cluster bounds (volume C0, C1, BA, stems) where the
## stratum fires, then compares with the r2 outputs. Aggregates only. No em dashes.
suppressMessages(library(data.table)); options(width = 200)
P <- "/home/aaron/jobs"; J <- file.path(P, "v142p35"); TOLR <- 1e-9; TOLP <- 1e-7
REF <- file.path(P, "v142p28/home/magplot/verify")
co <- fread(file.path(REF, "nsvb_emulator_coefs.csv")); g <- fread(file.path(REF, "spcd_spgrpcd.csv"))
## AcadianGY code to FIA SPCD, as published for the benchmark emulator
map <- data.table(code = c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB","WA","BA","GA",
  "RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC"),
  spcd = c(12,97,95,94,91,129,125,105,261,241,71,316,318,371,375,379,746,743,741,742,531,541,543,544,833,125,762,761,315,701,372,370,541,299,998,998,299,761))
map[, grp := g$SPGRPCD[match(spcd, g$SPCD)]][is.na(grp), grp := 998L]
map[, row := match(grp, co$SPGRPCD)][is.na(row), row := match(998, co$SPGRPCD)][is.na(row), row := 1L]
map[, `:=`(a = co$VOLCFGRS_a[row], b = co$VOLCFGRS_b[row], m = co$VOLCFGRS_sm[row])]
soft <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
tomap <- function(s) { s <- toupper(s); ifelse(s %in% map$code, s, ifelse(s %in% soft, "OS", "OH")) }
hgt <- function(s, d) ifelse(s %in% soft, 1.3 + 27 * (1 - exp(-0.030 * d)), 1.3 + 25 * (1 - exp(-0.028 * d)))
cuft <- function(s, d, h) { k <- match(s, map$code); hh <- ifelse(is.finite(h) & h > 0, h, hgt(s, d))
  y <- map$m[k] * exp(map$a[k] + map$b[k] * log((d / 2.54)^2 * (hh / 0.3048))); y[!is.finite(y)] <- 0; y }
stand_sum <- function(D, sp, dbh, ht, expf, mind, hcol = TRUE) {   # per stand m3 ha-1, BA m2 ha-1, stems ha-1 at the floor
  D <- copy(D); D[, ok := is.finite(get(dbh)) & get(dbh) >= mind & is.finite(get(expf)) & get(expf) > 0]
  D[, .(vol = sum(fifelse(ok, cuft(get(sp), get(dbh), if (hcol) get(ht) else NA_real_) * get(expf), 0)) * 0.0283168,
        ba = sum(fifelse(ok, pi * get(dbh)^2 / 40000 * get(expf), 0)), stems = sum(fifelse(ok, get(expf), 0)), nlive = sum(ok)), by = STAND] }
readdirs <- function(dirs, pat) { acc <- NULL; for (d in strsplit(dirs, ";", fixed = TRUE)[[1]]) { fs <- sort(list.files(d, pat, full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread), fill = TRUE)[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% x$STAND]; acc <- rbind(acc, x, fill = TRUE) }; acc }
X <- file.path(P, "v142p19/in/xfer"); FB <- file.path(P, "v142p14/in")
SETS <- list(
  nb_c = list(res = file.path(X, "v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv"), td = file.path(FB, "v141LT/nb_c"), fr = file.path(FB, "frames"), set = "nb_c", idx = file.path(X, "score/work/siteidx_nb_c.rds"), tab = "r2_fb"),
  qc_c = list(res = file.path(X, "v142_20260925/bench141/results/v141LT/gyr_v141LT_qc_c_results.csv"), td = file.path(FB, "v141LT/qc_c"), fr = file.path(FB, "frames"), set = "qc_c", idx = file.path(X, "score/work/siteidx_qc_c.rds"), tab = "r2_fb"),
  qc_fl = list(res = file.path(X, "v142_20260925/bench141/results/v141LT/gyr_v141LT_qc_fl_results.csv"), td = file.path(FB, "v141LT/qc_fl"), fr = file.path(FB, "frames"), set = "qc_fl", idx = file.path(X, "score/work/siteidx_qc_fl.rds"), tab = "r2_fb"),
  mnap_c_state = list(res = file.path(P, "v142p15/results_r1/v141LT/gyr_v141LT_mnap_c_results.csv"), td = paste(file.path(P, "v142p15/home/out/v141LT/mnap_c"), file.path(P, "v142p15/home/out_retry/v141LT/mnap_c"), sep = ";"),
    fr = file.path(P, "v142p15/home/magplot/verify/gydbreg20260916/frames"), set = "mnap_c", idx = "SEED:20260916:2000", tab = "r2_state"))
for (s in SETS) for (f in c(s$res, file.path(s$fr, sprintf("bench_gyr_%s_tree_%s.csv", s$set, c("t2", "init"))))) cat("md5", substr(tools::md5sum(f), 1, 8), f, "\n")
CK <- list(); ST <- list()
for (lab in names(SETS)) { s <- SETS[[lab]]
  r <- fread(s$res)[, STAND := as.character(STAND)]; sc <- r[RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p), .(STAND, SITE, SMD = SCORE_MINDBH_USED, TOTVOL_o, TOTVOL_p)]
  t2 <- fread(file.path(s$fr, sprintf("bench_gyr_%s_tree_t2.csv", s$set)), select = c("STAND", "SP", "DBH", "HT", "EXPF"))[, STAND := as.character(STAND)][STAND %in% sc$STAND]
  t1 <- fread(file.path(s$fr, sprintf("bench_gyr_%s_tree_init.csv", s$set)), select = c("STAND", "SP", "DBH", "HT", "EXPF"))[, STAND := as.character(STAND)][STAND %in% sc$STAND]
  pr <- readdirs(s$td, "^c[0-9]+_pred_t2_tree\\.csv$")[STAND %in% sc$STAND]
  t2[, s2 := tomap(SP)]; t1[, s2 := tomap(SP)]; t2 <- merge(t2, sc[, .(STAND, SMD)], by = "STAND"); t1 <- merge(t1, sc[, .(STAND, SMD)], by = "STAND"); pr <- merge(pr, sc[, .(STAND, SMD)], by = "STAND")
  o <- t2[, { k <- is.finite(DBH) & DBH >= SMD & is.finite(EXPF) & EXPF > 0
    .(Vo = sum(cuft(s2[k], DBH[k], HT[k]) * EXPF[k]) * 0.0283168, Voh = sum(cuft(s2[k], DBH[k], rep(NA_real_, sum(k))) * EXPF[k]) * 0.0283168,
      BAo = sum(pi * DBH[k]^2 / 40000 * EXPF[k]), No = sum(EXPF[k]), nlive = sum(k)) }, by = STAND]
  p <- pr[, { k <- is.finite(dbh) & dbh >= SMD & is.finite(expf) & expf > 0
    .(Vp = sum(cuft(sp[k], dbh[k], ht[k]) * expf[k]) * 0.0283168, Vph = sum(cuft(sp[k], dbh[k], rep(NA_real_, sum(k))) * expf[k]) * 0.0283168,
      BAp = sum(pi * dbh[k]^2 / 40000 * expf[k]), Np = sum(expf[k])) }, by = STAND]
  q <- t1[, { k <- is.finite(DBH) & DBH >= SMD & is.finite(EXPF) & EXPF > 0; .(V1 = sum(cuft(s2[k], DBH[k], HT[k]) * EXPF[k]) * 0.0283168, n1 = sum(k)) }, by = STAND]
  d <- Reduce(function(a, b) merge(a, b, by = "STAND", all.x = TRUE), list(sc, o, p, q))
  for (cc in c("Vo", "Voh", "BAo", "No", "nlive", "Vp", "Vph", "BAp", "Np", "V1", "n1")) set(d, which(is.na(d[[cc]])), cc, 0)
  idv <- max(abs(d$Vo - d$TOTVOL_o) / pmax(1, abs(d$TOTVOL_o)), abs(d$Vp - d$TOTVOL_p) / pmax(1, abs(d$TOTVOL_p)))
  dz <- d[TOTVOL_o == 0]; nD <- dz[nlive > 0, .N]; t1z <- d[V1 == 0, .N]; t1z_n <- d[n1 == 0, .N]
  r2d <- fread(file.path(J, "tables", s$tab, list.files(file.path(J, "tables", s$tab), "r2defect_DATA")))[label == lab]; r2s <- fread(file.path(J, "tables", s$tab, list.files(file.path(J, "tables", s$tab), "r2stratumshare_DATA")))[label == lab]   # rev 2: filter to the set
  CK[[lab]] <- data.table(label = lab, scored = nrow(d), identity_vs_results = idv, vo_zero = nrow(dz), defect = nD, t1_zero_vol = t1z, t1_zero_stems = t1z_n, share = t1z / nrow(d),
    r2_vo_zero = r2d$vo_zero, r2_defect = r2d$vo_zero_with_source_stem, r2_t1_zero = r2s$t1_zero, r2_fires = r2s$fires,
    match = r2d$scored == nrow(d) & r2d$vo_zero == nrow(dz) & r2d$vo_zero_with_source_stem == nD & r2s$t1_zero == t1z & t1z == t1z_n & r2s$fires == (t1z / nrow(d) > 0.05) & idv <= 1e-6)
  if (t1z / nrow(d) > 0.05) {
    ## site cluster draws, written as a matrix product: stand weight = draw count of its site
    sa <- as.character(r$SITE); u <- unique(sa)
    IX <- if (startsWith(s$idx, "SEED:")) { a <- as.integer(strsplit(s$idx, ":")[[1]][2:3]); set.seed(a[1]); matrix(sample.int(length(u), length(u) * a[2], replace = TRUE), length(u)) } else readRDS(s$idx)
    C <- apply(IX, 2, function(col) tabulate(col, nbins = length(u))); Wst <- C[match(sa, u), , drop = FALSE]; rownames(Wst) <- r$STAND
    vv <- list("volume C0" = c("Vo", "Vp"), "volume C1" = c("Voh", "Vph"), "basal area" = c("BAo", "BAp"), "stems" = c("No", "Np"))
    for (stn in c("all", "established_t1")) { e <- if (stn == "all") d else d[V1 > 0]; W <- Wst[e$STAND, , drop = FALSE]; nw <- colSums(W)
      for (vn in names(vv)) { ob <- e[[vv[[vn]][1]]]; pd <- e[[vv[[vn]][2]]]
        so <- drop(crossprod(W, ob)); sp_ <- drop(crossprod(W, pd)); se <- drop(crossprod(W, (pd - ob)^2))
        rb <- sp_ / so; mb <- 100 * sqrt(se / nw) / (so / nw)
        ST[[paste(lab, stn, vn)]] <- data.table(label = lab, stratum = stn, variable = vn, stands = nrow(e), v_ratio = sum(pd) / sum(ob), v_bias = 100 * (mean(pd) - mean(ob)) / mean(ob),
          v_rmse = 100 * sqrt(mean((pd - ob)^2)) / mean(ob), v_rlo = quantile(rb, 0.025, names = FALSE), v_rhi = quantile(rb, 0.975, names = FALSE),
          v_mlo = quantile(mb, 0.025, names = FALSE), v_mhi = quantile(mb, 0.975, names = FALSE)) } } } }
CK <- rbindlist(CK); print(CK)
ST <- rbindlist(ST); R2 <- fread(file.path(J, "tables/r2_fb/gyr142-volconv-r2stratum_DATA_2026-09-27.csv"))
M <- merge(ST, R2, by = c("label", "stratum", "variable"))
M[, `:=`(d_ratio = abs(v_ratio - ratio), d_rlo = abs(v_rlo - ratio_lo), d_rhi = abs(v_rhi - ratio_hi), d_bias = abs(v_bias - bias_pct), d_rmse = abs(v_rmse - rmse_pct), d_mlo = abs(v_mlo - rmse_lo), d_mhi = abs(v_mhi - rmse_hi))]
M[, pass := stands.x == stands.y & pmax(d_ratio, d_rlo, d_rhi) <= TOLR & pmax(d_bias, d_rmse, d_mlo, d_mhi) <= TOLP]
print(M[, .(label, stratum, variable, stands = stands.x, ratio = round(v_ratio, 4), d_ratio, d_rlo, d_rhi, d_bias, d_rmse, d_mlo, d_mhi, pass)])
## cross check: the all stands volume C0 and C1 rows against the frozen Cardinal PREREG16 scores
pub <- fread(file.path(P, "v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv"))[label == "nb_c" & arm == "v141LT" & pop == "all" & conv %in% c("C0", "C1")]
xc <- merge(ST[label == "nb_c" & stratum == "all" & variable %in% c("volume C0", "volume C1")][, conv := sub("volume ", "", variable)], pub, by = "conv")
xc[, worst := pmax(abs(v_ratio - ratio), abs(v_rlo - ratio_lo), abs(v_rhi - ratio_hi), abs(v_rmse - rmse_pct) / 100, abs(v_mlo - rmse_lo) / 100, abs(v_mhi - rmse_hi) / 100)]
cat(sprintf("cross check nb_c all stands C0 C1 vs frozen PREREG16 scores, worst %.2e\n", max(xc$worst)))
fwrite(CK, file.path(J, "verify_20261001", "p35_verify_checks.csv")); fwrite(M, file.path(J, "verify_20261001", "p35_verify_stratum.csv"))
ok <- all(CK$match) && nrow(M) == nrow(R2) && all(M$pass) && max(xc$worst) <= TOLR
cat(sprintf("tolerance ratio %.0e, percent %.0e; set checks %d of %d match; stratum rows %d of %d pass; worst ratio diff %.2e, worst percent diff %.2e\n",
  TOLR, TOLP, sum(CK$match), nrow(CK), sum(M$pass), nrow(R2), max(M[, pmax(d_ratio, d_rlo, d_rhi)]), max(M[, pmax(d_bias, d_rmse, d_mlo, d_mhi)])))
if (ok) cat("P35_VERIFY_DONE all checks pass\n") else cat("P35_VERIFY_FAILED\n")
