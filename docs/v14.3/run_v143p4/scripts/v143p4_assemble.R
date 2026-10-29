## v143p4_assemble.R, PREREG4 (md5 a15bd92a) step 7: assembly, gates and verdict. Its md5 is recorded in logs/assemble_md5.txt
## before it runs. Reads frozen outputs in place (bench141 v141LT and v141off, acdx long200 v131h and v141LT), the PREREG4 arm
## outputs under ~/v143p4/out, the identity check CSVs (H1a, H1b, H2), the fit record (H4, H5, selection), the frame step's
## SERVERONLY files, FIADB COND, PLOT and TREE tables (no coordinates) and the Maine AGB curve products. Definitions are those of
## the 16 October benchmark analysis (2026-10-16_acdx_analyze_r1.R, md5 afb04157): eqv(), part B1 to B4, the basis ratio.
## Every bootstrap uses seed 20261028, reset before each arm so 14.1 and a candidate are resampled identically on the same
## stands. Writes aggregates only (assembled/, fig/). Refuses to overwrite. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) })
NB <- 1000L; SEED <- 20261028L
H <- "/users/PUOM0008/crsfaaron"; P <- file.path(H, "v143p4"); SO <- file.path(P, "serveronly_SERVERONLY"); OD <- file.path(P, "assembled"); FD <- file.path(P, "fig")
TAG <- "2026-10-28"
B141 <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141"); X <- file.path(H, "acdx_20261016")
FR <- file.path(H, "magplot/verify/gydbreg20260916/frames"); YC <- file.path(H, "maine_agb_yc_20261015/out_b")
fo_out <- file.path(OD, sprintf("v143p4_gates_DATA_%s.csv", TAG))
if (file.exists(fo_out)) stop("REFUSE: assembly outputs exist")
dir.create(FD, showWarnings = FALSE)
SEL <- fread(file.path(OD, "v143p4_selection_DATA_2026-10-28.csv"))
CANDS <- intersect(c("candL", "candS"), paste0("cand", SEL[eligible == TRUE, unique(form)]))
cat("candidates:", if (length(CANDS)) paste(CANDS, collapse = " ") else "none", "\n")
G <- list()   # gate rows
addg <- function(gate, arm, pass, value = NA_real_, detail = "") G[[length(G) + 1]] <<- data.table(gate = gate, arm = arm, pass = pass, value = value, detail = detail)

## ---------------- harness ----------------
for (f in c("cmp_H1a", "cmp_H1b", "cmp_H2")) {
  ff <- list.files(file.path(P, "logs"), sprintf("^%s.*_DATA\\.csv$", f), full.names = TRUE)
  if (!length(ff)) { addg(sub("cmp_", "", f), "off/g0", FALSE, NA, "identity check file missing"); next }
  z <- rbindlist(lapply(ff, fread), fill = TRUE); zz <- z[kind != "completeness"]
  ok <- nrow(zz) > 0 && all(zz$note == "" | is.na(zz$note)) && all(zz$n_diff == 0) && all(zz$char_mismatch == 0)
  addg(sub("cmp_", "", f), "off/g0", ok, max(zz$worst_abs, na.rm = TRUE), sprintf("%d files of checks, %d kinds compared", length(ff), nrow(zz))) }
FH <- fread(file.path(OD, "v143p4_fit_harness_DATA_2026-10-28.csv"))
## an H5 row with no stands in its population cannot show a non-monotone R; it is recorded as not evaluable and does not fail
FH[gate == "H5" & is.na(pass), `:=`(pass = TRUE, note = paste(note, "(no stands in the population; not evaluable)"))]
for (i in seq_len(nrow(FH))) addg(FH$gate[i], paste(FH$form[i], FH$class[i]), FH$pass[i], FH$value[i], FH$note[i])

## ---------------- hindcast ----------------
eqv <- function(o, p, nb = NB) {
  n <- length(o); mo <- mean(o); mp <- mean(p)
  st <- function(i) { oo <- o[i]; pp <- p[i]; pc <- pp - mean(pp); b <- if (var(pc) > 0) cov(oo, pc) / var(pc) else NA_real_
    c(bias = 100 * (mean(pp) / mean(oo) - 1), dint = mean(oo) - mean(pp), slope = b, rmse = 100 * sqrt(mean((pp - oo)^2)) / mean(oo)) }
  full <- st(seq_len(n)); bt <- t(replicate(nb, st(sample.int(n, n, TRUE))))
  q <- function(j, pr) unname(quantile(bt[, j], pr, na.rm = TRUE))
  reg <- 0.25 * mo
  data.table(n = n, mean_obs = mo, mean_pred = mp, bias_pct = full[["bias"]], bias_lo = q("bias", .025), bias_hi = q("bias", .975),
    rmse_pct = full[["rmse"]], dint = full[["dint"]], dint_lo90 = q("dint", .05), dint_hi90 = q("dint", .95), int_region = reg,
    slope = full[["slope"]], slope_lo90 = q("slope", .05), slope_hi90 = q("slope", .95),
    int_equiv = q("dint", .05) > -reg & q("dint", .95) < reg, slope_equiv = q("slope", .05) > 0.75 & q("slope", .95) < 1.25) }
MET <- c("BA", "TOTVOL", "BIOMASS")
sets <- sort(unique(fread(file.path(B141, "work/bench141_taskmap_DATA_2026-09-25.csv"))$set))
rdr <- function(d) { f <- list.files(d, "_results\\.csv$", full.names = TRUE); if (!length(f)) return(NULL); rbindlist(lapply(f, fread), fill = TRUE) }
FZ <- rbindlist(lapply(sets, function(s) rbindlist(lapply(c("v141LT", "v141off"), function(a) { z <- rdr(file.path(B141, "out", a, s)); if (!is.null(z)) z[, `:=`(arm = a, set = s)]; z }), fill = TRUE)), fill = TRUE)
fo <- fread(file.path(SO, "folds_mefia_l_c_SERVERONLY.csv"))
## H3 bridge: frozen v141LT paired with v141off as bench141 paired them
PS <- fread(file.path(B141, "score/tables/gyr141-bench-perset-scores_DATA_2026-09-25.csv"))
okb <- FZ[RUN_OK == 1, .(na = uniqueN(arm)), by = .(set, STAND)][na == 2]
BR <- merge(FZ[arm == "v141LT"], okb[, .(set, STAND)], by = c("set", "STAND"))
br <- rbindlist(lapply(MET, function(m) { set.seed(SEED); BR[is.finite(get(paste0(m, "_o"))) & is.finite(get(paste0(m, "_p"))), .(n = .N, bias = 100 * (mean(get(paste0(m, "_p"))) / mean(get(paste0(m, "_o"))) - 1)), by = set][, metric := m] }))
br <- merge(br, PS[column_id == "v141LT" & metric %in% MET, .(set, metric, n_frozen = n, bias_frozen = bias_pct)], by = c("set", "metric"), all.x = TRUE)
br[, `:=`(n_match = n == n_frozen, diff = bias - bias_frozen)]
fwrite(br, file.path(OD, sprintf("v143p4_H3_bridge_DATA_%s.csv", TAG)))
h3ok <- br[, .(nm = sum(n_match, na.rm = TRUE), worst = max(abs(diff[n_match %in% TRUE]), -Inf)), by = metric]
addg("H3_bridge", "v141LT frozen", all(h3ok$nm >= 15) && all(h3ok$worst <= 5e-4), max(h3ok$worst), sprintf("matching sets per metric: %s", paste(h3ok$metric, h3ok$nm, collapse = ", ")))
## candidate scoring against frozen 14.1, paired per candidate; mefia_l_c fold B only
HS <- list()
for (cd in CANDS) {
  CR <- rbindlist(lapply(sets, function(s) { z <- rdr(file.path(P, "out/hc", cd, s)); if (!is.null(z)) z[, `:=`(arm = cd, set = s)]; z }), fill = TRUE)
  for (s in sets) {
    f14 <- FZ[arm == "v141LT" & set == s & RUN_OK == 1]; fc <- CR[set == s]
    comp <- if (nrow(f14)) fc[RUN_OK == 1, uniqueN(intersect(STAND, f14$STAND))] / uniqueN(f14$STAND) else NA_real_
    addg("H7_hc", paste(cd, s), is.finite(comp) && comp >= 0.99, comp, "share of stands frozen 14.1 ran that the candidate ran") }
  pa <- merge(FZ[arm == "v141LT" & RUN_OK == 1, .(set, STAND)], CR[RUN_OK == 1, .(set, STAND)], by = c("set", "STAND"))
  pa <- pa[!(set == "mefia_l_c" & !(STAND %in% fo[FOLD == "B", STAND]))]
  for (ar in c("v141LT", cd)) {
    src <- if (ar == "v141LT") FZ[arm == "v141LT"] else CR
    R <- merge(src, pa, by = c("set", "STAND"))
    for (m in MET) { set.seed(SEED)
      z <- R[is.finite(get(paste0(m, "_o"))) & is.finite(get(paste0(m, "_p"))), eqv(get(paste0(m, "_o")), get(paste0(m, "_p"))), by = set]
      HS[[length(HS) + 1]] <- z[, `:=`(metric = m, arm = ar, pair = cd)] } } }
HS <- rbindlist(HS, fill = TRUE)
if (nrow(HS)) { HS[, equiv := int_equiv & slope_equiv]; fwrite(HS, file.path(OD, sprintf("v143p4_hindcast_scores_DATA_%s.csv", TAG))) }
for (cd in CANDS) {
  w <- dcast(HS[pair == cd & metric %in% c("BA", "BIOMASS")], set + metric ~ arm, value.var = "bias_pct")
  setnames(w, c("v141LT", cd), c("b141", "bc")); w[, worse := abs(bc) - abs(b141)]
  fwrite(w[, pair := cd], file.path(OD, sprintf("v143p4_HB1_%s_DATA_%s.csv", cd, TAG)))
  for (tol in c(1.0, 0.5, 2.0)) addg(sprintf("HB1_tol%.1f", tol), cd, all(w$worse <= tol), max(w$worse), sprintf("sets over tolerance: %s", paste(w[worse > tol, paste(set, metric)], collapse = "; ")))
  a <- HS[pair == cd & metric == "BIOMASS"]
  m141 <- median(abs(a[arm == "v141LT", bias_pct])); mc <- median(abs(a[arm == cd, bias_pct]))
  addg("HB2", cd, mc <= m141 + 0.5, mc - m141, sprintf("median absolute AGB bias, candidate %.3f, 14.1 %.3f, over %d sets", mc, m141, a[arm == cd, .N]))
  e141 <- a[arm == "v141LT", sum(equiv)]; ec <- a[arm == cd, sum(equiv)]
  addg("HB3", cd, ec >= e141, ec - e141, sprintf("AGB equivalence passes, candidate %d, 14.1 %d", ec, e141)) }

## HB4: fold B mortality ratio by t1 class
I0 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_init.csv")); T2 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_t2.csv"))
fb <- fo[FOLD == "B" & (is.na(CHURN_FLAG) | CHURN_FLAG != 1), STAND]
SFG <- c("BF", "RS", "WS", "BS", "NS", "TA", "WC"); PHG <- c("WP", "RP", "RN", "JP", "EH", "OS")
I0[, ok := is.finite(EXPF) & EXPF > 0 & is.finite(DBH) & DBH > 0][, ba := fifelse(ok, DBH^2 * pi / 40000 * EXPF, 0)]
TCB <- I0[STAND %in% fb, { tot <- sum(ba); sfs <- sum(ba[SP %in% SFG]) / tot; phs <- sum(ba[SP %in% PHG]) / tot
  .(CLASS = if (tot > 0) { if (sfs >= phs && sfs >= 1 - sfs - phs) "SF" else "NSF" } else NA_character_) }, by = STAND]
RSB <- FZ[arm == "v141LT" & set == "mefia_l_c" & STAND %in% fb, .(STAND, SMD = SCORE_MINDBH_USED)]
IB <- merge(I0[STAND %in% fb], RSB, by = "STAND"); T2B <- T2[STAND %in% fb & is.finite(EXPF) & EXPF > 0]
IB[, live2 := paste(STAND, PLOT, TREE) %chin% T2B[, paste(STAND, PLOT, TREE)]]
OMB <- IB[, .(OBS = sum((EXPF * pi * (DBH / 200)^2)[ok & !live2 & DBH >= SMD])), by = STAND]
rdt <- function(d) { f <- list.files(d, "_traj\\.csv$", full.names = TRUE); rbindlist(lapply(f, fread, select = c("STAND", "yr", "MORT_BA_S")))[, .SD[which.max(yr)], by = STAND] }
MR <- list()
for (ar in c("v141LT", CANDS)) {
  tj <- rdt(if (ar == "v141LT") file.path(B141, "out/v141LT/mefia_l_c") else file.path(P, "out/hc", ar, "mefia_l_c"))
  z <- merge(merge(OMB, TCB, by = "STAND"), tj[, .(STAND, PRED = MORT_BA_S)], by = "STAND")
  MR[[ar]] <- z[, .(n = .N, sum_pred = sum(PRED), sum_obs = sum(OBS), ratio = sum(PRED) / sum(OBS)), by = CLASS][, arm := ar] }
MR <- rbindlist(MR); fwrite(MR, file.path(OD, sprintf("v143p4_HB4_mortratio_foldB_DATA_%s.csv", TAG)))
for (cd in CANDS) { m <- MR[arm == cd]; addg("HB4", cd, all(m$ratio >= 0.80 & m$ratio <= 1.25), NA, paste(m[, sprintf("%s %.3f (n %d)", CLASS, ratio, n)], collapse = "; ")) }
rm(I0, T2, IB, T2B); gc()

## ---------------- 200 yr ----------------
L2ARMS <- c("v131h", "v141LT", CANDS, if (length(list.files(file.path(P, "out/l200/D1/mefia_l_c"), "_traj"))) "D1")
VL <- c(v131h = "13.1h", v141LT = "14.1", candL = "14.3 candidate L", candS = "14.3 candidate S", D1 = "D1, no floor in NSF")
l2dir <- function(a) if (a %in% c("v131h", "v141LT")) file.path(X, "long200/out", a, "mefia_l_c") else file.path(P, "out/l200", a, "mefia_l_c")
TJ <- rbindlist(lapply(L2ARMS, function(a) rbindlist(lapply(list.files(l2dir(a), "_traj\\.csv$", full.names = TRUE), fread,
  select = c("STAND", "yr", "TPH", "BA", "QMD", "TOPHT", "TOTVOL", "SDI", "BIOMASS")))[, arm := a]))
LR <- rbindlist(lapply(L2ARMS, function(a) rbindlist(lapply(list.files(l2dir(a), "_results\\.csv$", full.names = TRUE), fread, select = c("STAND", "RUN_OK")))[, arm := a]))
f14 <- LR[arm == "v141LT" & RUN_OK == 1, STAND]
for (a in setdiff(L2ARMS, c("v131h", "v141LT"))) { comp <- length(intersect(LR[arm == a & RUN_OK == 1, STAND], f14)) / length(f14); addg("H7_l200", a, comp >= 0.99, comp, "share of stands frozen 14.1 ran that the arm ran") }
okL <- LR[RUN_OK == 1, .(na = uniqueN(arm)), by = STAND][na == length(L2ARMS), STAND]
TJ <- TJ[STAND %in% okL]
pr <- fread(file.path(FR, "bench_gyr_mefia_l_c_pairs.csv"), select = c("STAND", "SITE", "PLOTKEY", "Y1"))
es <- fread(file.path(FR, "bench_gyr_mefia_l_c_site_esi.csv")); pr <- merge(pr, es, by = "SITE", all.x = TRUE)
pr[, ROOT := sub("^FIA", "", PLOTKEY)]
PL <- fread(file.path(H, "fia_data/ME_PLOT.csv"), select = c("CN", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "MEASYEAR"), colClasses = list(character = "CN"))
PL[, pid := paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "_")]
pr <- merge(pr, PL[, .(ROOT = CN, pid)], by = "ROOT", all.x = TRUE)
pr <- merge(pr, PL[, .(pid, Y1 = MEASYEAR, CN1 = CN)], by = c("pid", "Y1"), all.x = TRUE)[!duplicated(STAND)]
CO <- fread(file.path(H, "fia_data/ME_COND.csv"), select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "FORTYPCD", "STDAGE"), colClasses = list(character = "PLT_CN"))
CO <- CO[COND_STATUS_CD == 1][order(PLT_CN, CONDID)][!duplicated(PLT_CN)]
CO[, g10 := (FORTYPCD %/% 10) * 10][, ftg := fcase(g10 == 120, "SF", g10 == 800, "MBB", g10 == 900, "AB", g10 == 100, "WRPH",
  g10 %in% c(400, 500, 510, 520), "OAK", g10 == 700, "EAC", default = "OTH")]
pr <- merge(pr, CO[, .(CN1 = PLT_CN, ftg, STDAGE)], by = "CN1", all.x = TRUE)
TR <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("PLT_CN", "STATUSCD", "DRYBIO_AG", "TPA_UNADJ"), colClasses = list(character = "PLT_CN"))[PLT_CN %in% pr$CN1]
TR <- TR[STATUSCD == 1 & is.finite(DRYBIO_AG) & is.finite(TPA_UNADJ), .(AGB_fia = sum(DRYBIO_AG * TPA_UNADJ) * 0.453592 / 1000 * 2.471054), by = PLT_CN]
pr <- merge(pr, TR[, .(CN1 = PLT_CN, AGB_fia)], by = "CN1", all.x = TRUE); rm(TR); gc()
## basis ratio on the benchmark's own population (all 918, frozen v141LT year 0, stands run in the three benchmark arms)
LR0 <- rbindlist(lapply(c("v131h", "v141off", "v141LT"), function(a) rbindlist(lapply(list.files(file.path(X, "long200/out", a, "mefia_l_c"), "_results\\.csv$", full.names = TRUE), fread, select = c("STAND", "RUN_OK")))[, arm := a]))
ok0 <- LR0[RUN_OK == 1, .(na = uniqueN(arm)), by = STAND][na == 3, STAND]
b0 <- rbindlist(lapply(list.files(file.path(X, "long200/out/v141LT/mefia_l_c"), "_traj\\.csv$", full.names = TRUE), fread, select = c("STAND", "yr", "BIOMASS")))[yr == 0 & STAND %in% ok0, .(STAND, B0 = BIOMASS)]
kb <- merge(pr, b0, by = "STAND")[is.finite(AGB_fia) & B0 > 5, median(AGB_fia / B0)]
addg("H3_basis", "frozen", abs(kb - 1.0672) <= 5e-5, kb, "FIADB over engine biomass at t1, median; benchmark 1.0672")
fl <- fread(file.path(SO, "folds_long200_SERVERONLY.csv"))
attrs <- merge(pr[, .(STAND, ftg, STDAGE, esi8)], fl[, .(STAND, FOLD)], by = "STAND")
TJ <- merge(TJ, attrs, by = "STAND"); TJ[, `:=`(AGBadj = BIOMASS * kb, age = STDAGE + yr)]
fwrite(TJ[yr == 0 & arm == "v141LT", .(n = .N), by = .(FOLD, ftg)][order(FOLD, ftg)], file.path(OD, sprintf("v143p4_long200_population_DATA_%s.csv", TAG)))
CV <- fread(file.path(YC, "stress/final_curves_capped_DATA.csv"))[section == "ALL", .(ftg, age, AGB_med, lo95, hi95, extrapolated)]
MG <- fread(file.path(YC, "bakuzis/magnitude_reference_DATA.csv")); NC <- fread(file.path(YC, "bakuzis/net_change_by_age_DATA.csv"))[screen == "hf"]
BD <- fread(file.path(YC, "stress/bootstrap_decline_DATA.csv"))
FTN <- c(SF = "Spruce-fir", MBB = "Maple-beech-birch", AB = "Aspen-birch", WRPH = "White-red pine-hemlock", OAK = "Oak and oak-pine", EAC = "Elm-ash-cottonwood", OTH = "Other")
## B2 decline, by fold
PK <- TJ[, .(bmax = max(AGBadj), b200 = AGBadj[yr == max(yr)], peak_yr = yr[which.max(AGBadj)]), by = .(arm, STAND, ftg, FOLD)]
PK[, declining := b200 < 0.95 * bmax]
DEC <- rbindlist(lapply(L2ARMS, function(a) { set.seed(SEED); PK[arm == a, { bb <- replicate(NB, mean(sample(declining, .N, TRUE)))
  .(n = .N, share_declining = mean(declining), dec_lo = quantile(bb, .025), dec_hi = quantile(bb, .975), peak_yr_med = as.numeric(median(peak_yr))) }, by = .(arm, FOLD, ftg)] }))
DEC <- merge(DEC, BD[, .(ftg, curve_p = p_decline_250)], by = "ftg", all.x = TRUE)[, version := VL[arm]]
fwrite(DEC[order(FOLD, ftg, arm)], file.path(OD, sprintf("v143p4_long200_decline_DATA_%s.csv", TAG)))
GT <- c("SF", "MBB", "AB", "WRPH", "OAK", "EAC")
for (a in c("v131h", "v141LT", CANDS, intersect("D1", L2ARMS))) {
  d <- DEC[arm == a & FOLD == "B" & ftg %in% GT & n >= 15]
  for (tol in c(0.30, 0.20, 0.40)) addg(sprintf("LR1_tol%.2f", tol), a, nrow(d) > 0 && all(abs(d$share_declining - d$curve_p) <= tol), max(abs(d$share_declining - d$curve_p)),
    paste(d[abs(share_declining - curve_p) > tol, sprintf("%s %.3f vs %.3f", ftg, share_declining, curve_p)], collapse = "; ")) }
## B1 against curves, fold B
TJc <- merge(TJ[is.finite(age)], CV[, .(ftg, age = as.integer(age), AGB_cur = AGB_med, cur_lo = lo95, cur_hi = hi95)], by = c("ftg", "age"))
B1 <- rbindlist(lapply(L2ARMS, function(a) { set.seed(SEED); TJc[arm == a & yr %in% c(0, 50, 100, 150, 200) & AGB_cur > 1, {
  r <- AGBadj / AGB_cur; b <- replicate(NB, median(sample(r, length(r), TRUE)))
  .(n = .N, ratio_med = as.numeric(median(r)), ratio_lo = quantile(b, .025), ratio_hi = quantile(b, .975), in_band = mean(AGBadj >= cur_lo & AGBadj <= cur_hi)) }, by = .(arm, FOLD, ftg, yr)] }))
fwrite(B1[order(FOLD, arm, ftg, yr)], file.path(OD, sprintf("v143p4_long200_vs_curves_DATA_%s.csv", TAG)))
for (a in c("v131h", "v141LT", CANDS, intersect("D1", L2ARMS))) {
  d <- B1[arm == a & FOLD == "B" & ftg %in% GT & yr %in% c(100, 200) & n >= 15]
  addg("LR2", a, nrow(d) > 0 && all(d$ratio_med >= 0.67 & d$ratio_med <= 1.50), NA, paste(d[ratio_med < 0.67 | ratio_med > 1.50, sprintf("%s yr %d %.3f", ftg, yr, ratio_med)], collapse = "; ")) }
## B3 net change by age class (reported)
setorder(TJ, arm, STAND, yr)
TJ[, dB := (shift(AGBadj, -1) - AGBadj) / (shift(yr, -1) - yr), by = .(arm, STAND)][, amid := age + 2.5]
brk <- c(0, 20, 40, 60, 80, 100, 120, 250, Inf); TJ[, ageclass := as.character(cut(amid, brk, right = FALSE))]
B3 <- rbindlist(lapply(L2ARMS, function(a) { set.seed(SEED); TJ[arm == a & FOLD == "B" & is.finite(dB) & is.finite(amid), { m <- .SD[, .(d = mean(dB)), by = STAND]
  bb <- replicate(NB, mean(sample(m$d, nrow(m), TRUE))); .(n_stands = nrow(m), dB_pred = mean(m$d), pred_lo = quantile(bb, .025), pred_hi = quantile(bb, .975)) }, by = .(arm, ftg, ageclass)] }))
B3 <- merge(B3, NC[, .(ftg, ageclass, dB_obs = dB_mean, obs_lo = dB_lo, obs_hi = dB_hi, obs_plots = plots)], by = c("ftg", "ageclass"), all.x = TRUE)
fwrite(B3, file.path(OD, sprintf("v143p4_long200_netchange_foldB_DATA_%s.csv", TAG)))
## B4 Bakuzis, fold B
BK <- rbindlist(lapply(L2ARMS, function(ar) { set.seed(SEED)
  T0 <- TJ[arm == ar & FOLD == "B"]; y100 <- T0[yr == 100]
  so <- y100[is.finite(esi8), { if (.N >= 15) { ct <- suppressWarnings(cor(esi8, AGBadj, method = "spearman")); bb <- replicate(NB, { i <- sample.int(.N, .N, TRUE); suppressWarnings(cor(esi8[i], AGBadj[i], method = "spearman")) })
    .(rho = ct, lo = quantile(bb, .025, na.rm = TRUE), hi = quantile(bb, .975, na.rm = TRUE), n = .N) } else NULL }, by = ftg][, relation := "site_ordering"]
  mx <- merge(T0[, .(bmax = max(AGBadj), smax = max(SDI)), by = .(STAND, ftg)], MG[, .(ftg, AGB_q999, SDI_q999)], by = "ftg")
  mag <- mx[, .(rho = mean(bmax > AGB_q999), lo = NA_real_, hi = NA_real_, n = .N), by = ftg][, relation := "magnitude"]
  rei <- mx[, .(rho = mean(smax > SDI_q999), lo = NA_real_, hi = NA_real_, n = .N), by = ftg][, relation := "reineke"]
  T0[, est := cut(esi8, quantile(esi8, c(0, 1/3, 2/3, 1), na.rm = TRUE), include.lowest = TRUE, labels = c("low", "mid", "high"))]
  ei <- T0[yr >= 20 & TOPHT > 5 & is.finite(est), .(b = coef(lm(log(TOTVOL + 1) ~ log(TOPHT)))[2]), by = est]
  eic <- data.table(ftg = "ALL", rho = ei[est == "high", b] / ei[est == "low", b], lo = NA_real_, hi = NA_real_, n = nrow(T0[yr == 0]), relation = "eichhorn")
  yd <- merge(T0[yr == 0, .(STAND, tph0 = TPH)], T0[yr == 100, .(STAND, b100 = AGBadj)], by = "STAND")
  ydc <- data.table(ftg = "ALL", rho = suppressWarnings(cor(yd$tph0, yd$b100, method = "spearman")), lo = NA_real_, hi = NA_real_, n = nrow(yd), relation = "yield_density")
  rbind(so, mag, rei, eic, ydc, fill = TRUE)[, arm := ar] }))
fwrite(BK, file.path(OD, sprintf("v143p4_bakuzis_foldB_DATA_%s.csv", TAG)))
for (a in c(CANDS, intersect("D1", L2ARMS))) {
  b <- BK[arm == a]; b14 <- BK[arm == "v141LT"]
  m <- b[relation == "magnitude" & ftg %in% GT & n >= 15]; addg("BK1", a, all(m$rho <= 0.10), max(m$rho), paste(m[rho > 0.10, sprintf("%s %.3f", ftg, rho)], collapse = "; "))
  r <- b[relation == "reineke" & ftg %in% GT & n >= 15]; addg("BK2", a, all(r$rho <= 0.05), max(r$rho), paste(r[rho > 0.05, sprintf("%s %.3f", ftg, rho)], collapse = "; "))
  s14 <- b14[relation == "site_ordering" & lo > 0, ftg]; sc <- b[relation == "site_ordering" & ftg %in% s14]
  addg("BK3", a, all(sc$lo > 0) && nrow(sc) == length(s14), NA, sprintf("types with 14.1 lower limit above 0: %s; candidate lower limits: %s", paste(s14, collapse = " "), paste(sc[, sprintf("%s %.3f", ftg, lo)], collapse = "; ")))
  e <- b[relation == "eichhorn", rho]; addg("BK4", a, length(e) == 1 && e >= 0.80 && e <= 1.25, e, "")
  y <- b[relation == "yield_density", rho]; addg("BK5", a, length(y) == 1 && abs(y) <= 0.20, y, "") }

## ---------------- H6 timing ----------------
st <- readLines(file.path(P, "logs/selection_md5.txt")); tsel <- as.POSIXct(sub(".*recorded ([0-9T:-]+)[-+][0-9]{4}.*", "\\1", st[1]), format = "%Y-%m-%dT%H:%M:%S")
cf <- unlist(lapply(c(CANDS, "D1"), function(a) list.files(c(file.path(P, "out/hc", a), file.path(P, "out/l200", a)), "_results\\.csv$", recursive = TRUE, full.names = TRUE)))
early <- if (length(cf)) sum(file.mtime(cf) < tsel) else 0L
addg("H6_timing", "candidates", is.finite(tsel) && early == 0, early, sprintf("candidate or D1 result files written before the selection md5 time: %d of %d", early, length(cf)))

## ---------------- verdict ----------------
GG <- rbindlist(G, fill = TRUE); fwrite(GG, fo_out)
harness <- GG[grepl("^H[0-9]", gate)]
hp <- all(harness$pass %in% TRUE)
V <- c(sprintf("harness_pass=%s", hp), sprintf("harness_fail=%s", paste(harness[!(pass %in% TRUE), paste(gate, arm)], collapse = "; ")))
if (!hp) V <- c(V, "outcome=RULE1_NO_VERDICT") else if (!length(CANDS)) V <- c(V, "outcome=RULE2_H0_NO_ELIGIBLE_FORM") else {
  adopt <- character(0)
  for (cd in CANDS) {
    g <- GG[arm == cd]
    f3 <- g[gate %in% c("LR1_tol0.30", "LR2") & !(pass %in% TRUE), gate]; f4 <- g[gate %in% c("HB1_tol1.0", "HB2", "HB3", "HB4") & !(pass %in% TRUE), gate]
    f5 <- g[gate %in% paste0("BK", 1:5) & !(pass %in% TRUE), gate]
    r <- if (length(f3)) sprintf("RULE3_NOT_ADOPTED(%s)", paste(f3, collapse = ",")) else if (length(f4)) sprintf("RULE4_NOT_ADOPTED(%s)", paste(f4, collapse = ",")) else if (length(f5)) sprintf("RULE5_NOT_ADOPTED(%s)", paste(f5, collapse = ",")) else "RULE6_PASSES"
    V <- c(V, sprintf("%s=%s; all failing gates: %s", cd, r, paste(g[!(pass %in% TRUE) & gate %in% c("LR1_tol0.30", "LR2", "HB1_tol1.0", "HB2", "HB3", "HB4", paste0("BK", 1:5)), gate], collapse = ",")))
    if (r == "RULE6_PASSES") adopt <- c(adopt, cd) }
  V <- c(V, sprintf("outcome=%s", if ("candL" %in% adopt) "RULE6_CANDIDATE_L" else if ("candS" %in% adopt) "RULE6_CANDIDATE_S" else "NOT_ADOPTED")) }
writeLines(V, file.path(OD, sprintf("v143p4_verdict_DATA_%s.txt", TAG))); cat(V, sep = "\n")
print(GG)

## ---------------- figure ----------------
fd <- DEC[FOLD == "B" & ftg %in% GT][, ftgl := factor(FTN[ftg], levels = FTN[GT])][, version := factor(VL[arm], levels = VL[L2ARMS])]
cols <- c("13.1h" = "#8c5a3c", "14.1" = "#1a3d28", "14.3 candidate L" = "#2f6db5", "14.3 candidate S" = "#7fa7d9", "D1, no floor in NSF" = "#9a9a9a")
cp <- unique(fd[, .(ftgl, curve_p)])
pf <- ggplot(fd, aes(x = version, y = share_declining, colour = version)) +
  geom_hline(data = cp, aes(yintercept = curve_p), linetype = "dashed", linewidth = 0.4, colour = "grey30") +
  geom_errorbar(aes(ymin = dec_lo, ymax = dec_hi), width = 0.25) + geom_point(size = 2) +
  facet_wrap(~ftgl, nrow = 2) + scale_colour_manual(values = cols, name = NULL) + scale_y_continuous(limits = c(0, 1)) +
  labs(x = NULL, y = "Share of stands declining by year 200",
       caption = "Fold B unmanaged Maine FIA stands, 200 yr without harvest. Bars: 95% stand bootstrap intervals (1,000 resamples).\nDashed line: probability that the Maine FIA AGB curve peaks before 250 yr. Declining: year 200 AGB below 95% of the projection maximum.") +
  theme_bw(base_size = 9) + theme(panel.grid.minor = element_blank(), strip.background = element_rect(fill = "grey95"), axis.text.x = element_blank(),
    axis.ticks.x = element_blank(), legend.position = "bottom", plot.caption = element_text(hjust = 0, size = 7))
ggsave(file.path(FD, sprintf("v143p4_fig_share_declining_%s.png", TAG)), pf, width = 7.2, height = 5.0, dpi = 300, bg = "white")
ggsave(file.path(FD, sprintf("v143p4_fig_share_declining_%s.pdf", TAG)), pf, width = 7.2, height = 5.0, bg = "white")
cat("ASSEMBLE_DONE\n")
