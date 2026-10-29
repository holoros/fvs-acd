## 2026-10-16_acdx_analyze.R
## FVS-ACD cross-version benchmark (October 16, 2026). Scores three versions on Cardinal outputs:
##   v131h  = v13.1 hierarchical (Seven Islands configuration), new runs
##   v141off = 14.0.4 L2 (14.1 overlay sourced, gates off), frozen bench141 runs plus new post-harvest and 200 yr runs
##   v141LT = 14.1 release (L and T on); on Maine plots it equals the 14.2 qc141 reference (QC_AFAC acts on QC only)
## Part A, hindcast: 19 frozen benchmark sets plus the new post-harvest Maine FIA set (mefia_ph_c).
##   Paired stands only (RUN_OK in every arm). Bias % with 95% stand bootstrap interval, RMSE %, R2, and a
##   bootstrap equivalence test of observed on predicted (Robinson et al. 2005 form): intercept of observed on
##   mean-centred predicted compared with mean predicted, region +/- 25% of mean observed; slope region 1 +/- 0.25;
##   90% bootstrap intervals (TOST at alpha 0.05). Regions fixed before reading any new output.
## Part B, 200 yr no-harvest projections of the 918 unmanaged Maine FIA stands (mefia_l_c t1 lists): projected
##   AGB against the published Maine FIA AGB curves (Zenodo 10.5281/zenodo.23406410), net change by age class
##   against observed FIA net change, peak and decline behavior, and empirical Bakuzis relations.
## Restricted data: plot coordinates are never read. Outputs are aggregates by set, version, type or age class.
## Usage: Rscript 2026-10-16_acdx_analyze.R <out_dir> [nboot]
suppressMessages({ library(data.table); library(ggplot2) })
a <- commandArgs(TRUE); OD <- a[1]; NB <- if (length(a) > 1) as.integer(a[2]) else 1000L
dir.create(OD, showWarnings = FALSE, recursive = TRUE); dir.create(file.path(OD, "fig"), showWarnings = FALSE)
set.seed(20261016)
H <- path.expand("~")
B141 <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141")
X <- file.path(H, "acdx_20261016")
FR <- file.path(H, "magplot/verify/gydbreg20260916/frames")
YC <- file.path(H, "maine_agb_yc_20261015/out_b")
ARMS <- c(v131h = "13.1h", v141off = "14.0.4 L2", v141LT = "14.1")
FTN <- c(SF = "Spruce-fir", MBB = "Maple-beech-birch", AB = "Aspen-birch", WRPH = "White-red pine-hemlock", OAK = "Oak and oak-pine", EAC = "Elm-ash-cottonwood", OTH = "Other")
COLS <- c(v131h = "#8c5a3c", v141off = "#7f9c6b", v141LT = "#1a3d28")
MET <- c("BA", "QMD", "TOPHT", "TOTVOL", "MERCHVOL", "BIOMASS", "SDI")
log_err <- function(...) cat(sprintf(...), "\n", file = file.path(OD, "error_log.txt"), append = TRUE)
th <- theme_bw(base_size = 9) + theme(panel.grid.minor = element_blank(), strip.background = element_rect(fill = "grey95"),
  legend.position = "bottom", plot.title = element_text(face = "bold", size = 10))

## ---------------- Part A: hindcast ----------------
rd <- function(arm, set) {
  d <- if (set == "mefia_ph_c") file.path(X, "postharv/out", arm, set) else if (arm == "v131h") file.path(X, "bench131h/out/v131h", set) else file.path(B141, "out", arm, set)
  f <- list.files(d, pattern = "_results\\.csv$", full.names = TRUE)
  if (!length(f)) { log_err("no results %s %s", arm, set); return(NULL) }
  z <- rbindlist(lapply(f, fread), fill = TRUE); z[, `:=`(arm = arm, set = set)]; z }
sets <- sort(unique(fread(file.path(B141, "work/bench141_taskmap_DATA_2026-09-25.csv"))$set))
sets <- c(sets, "mefia_ph_c")
R <- rbindlist(lapply(sets, function(s) rbindlist(lapply(names(ARMS), rd, set = s), fill = TRUE)), fill = TRUE)
R <- R[RUN_OK == 1]
okst <- R[, .(na = uniqueN(arm)), by = .(set, STAND)][na == length(ARMS)]
R <- merge(R, okst[, .(set, STAND)], by = c("set", "STAND"))
fwrite(R[, .N, by = .(set, arm)][order(set, arm)], file.path(OD, "acdx_hindcast_n_DATA.csv"))

eqv <- function(o, p, nb = NB) {
  n <- length(o); mo <- mean(o); mp <- mean(p)
  st <- function(i) { oo <- o[i]; pp <- p[i]; pc <- pp - mean(pp); b <- if (var(pc) > 0) cov(oo, pc) / var(pc) else NA_real_
    c(bias = 100 * (mean(pp) / mean(oo) - 1), dint = mean(oo) - mean(pp), slope = b, rmse = 100 * sqrt(mean((pp - oo)^2)) / mean(oo)) }
  full <- st(seq_len(n)); bt <- t(replicate(nb, st(sample.int(n, n, TRUE))))
  q <- function(j, pr) unname(quantile(bt[, j], pr, na.rm = TRUE))
  reg <- 0.25 * mo
  data.table(n = n, mean_obs = mo, mean_pred = mp, bias_pct = full[["bias"]], bias_lo = q("bias", .025), bias_hi = q("bias", .975),
    rmse_pct = full[["rmse"]], r2 = 1 - sum((o - p)^2) / sum((o - mo)^2),
    dint = full[["dint"]], dint_lo90 = q("dint", .05), dint_hi90 = q("dint", .95), int_region = reg,
    slope = full[["slope"]], slope_lo90 = q("slope", .05), slope_hi90 = q("slope", .95),
    int_equiv = q("dint", .05) > -reg & q("dint", .95) < reg, slope_equiv = q("slope", .05) > 0.75 & q("slope", .95) < 1.25) }
S <- rbindlist(lapply(MET, function(m) {
  oc <- paste0(m, "_o"); pc <- paste0(m, "_p")
  R[is.finite(get(oc)) & is.finite(get(pc)), eqv(get(oc), get(pc)), by = .(set, arm)][, metric := m] }))
S[, equiv := int_equiv & slope_equiv][, version := ARMS[arm]]
fwrite(S, file.path(OD, "acdx_hindcast_scores_DATA.csv"))

## bridge: frozen bench141 per set scores for the 14.x arms must be reproduced on the frozen sets
P <- fread(file.path(B141, "score/tables/gyr141-bench-perset-scores_DATA_2026-09-25.csv"))
br <- merge(S[arm != "v131h" & set != "mefia_ph_c" & metric %in% c("BA", "TOTVOL", "BIOMASS"), .(set, arm, metric, n_new = n, bias_new = bias_pct)],
  P[, .(set, arm = column_id, metric, n_frozen = n, bias_frozen = bias_pct)], by = c("set", "arm", "metric"), all.x = TRUE)
br[, diff := bias_new - bias_frozen]
fwrite(br, file.path(OD, "acdx_bridge_bench141_DATA.csv"))
cat(sprintf("bridge rows %d, matched %d, max |diff| %.3f\n", nrow(br), br[is.finite(diff), .N], br[is.finite(diff), max(abs(diff))]))
fwrite(P[set %in% c("mefia_l_c", "silc_l_c") & metric %in% c("BA", "TOTVOL", "BIOMASS")], file.path(OD, "acdx_frozen_context_columns_DATA.csv"))

## post-harvest by FCCL harvest type
CL <- fread(file.path(X, "postharv/work/mefia_ph_class_DATA_2026-10-16_r1.csv"))
tcol <- intersect(c("HARVEST_TYPE", "harvest_type", "TYPE", "type"), names(CL))[1]
setnames(CL, tcol, "htype")
PH <- merge(R[set == "mefia_ph_c"], CL[, .(STAND, htype)], by = "STAND")
SPH <- PH[is.finite(BIOMASS_o) & is.finite(BIOMASS_p), c(eqv(BIOMASS_o, BIOMASS_p),
  .(t1 = mean(BIOMASS_t1), rec_obs = mean(BIOMASS_o - BIOMASS_t1) / mean(iv), rec_pred = mean(BIOMASS_p - BIOMASS_t1) / mean(iv))), by = .(htype, arm)]
## recovery rate interval (Mg/ha/yr) by stand bootstrap
rr <- PH[, { d <- (BIOMASS_p - BIOMASS_o) / iv; b <- replicate(NB, mean(sample(d, length(d), TRUE)))
  .(gap = mean(d), gap_lo = quantile(b, .025), gap_hi = quantile(b, .975)) }, by = .(htype, arm)]
SPH <- merge(SPH, rr, by = c("htype", "arm"))[, version := ARMS[arm]]
fwrite(SPH, file.path(OD, "acdx_postharvest_by_type_DATA.csv"))

## Figures A
key <- c("mefia_l_c", "mefia_ph_c", "silc_l_c")
f1 <- S[set %in% key & metric %in% c("BA", "TOTVOL", "BIOMASS")]
f1[, setlab := factor(fcase(set == "mefia_l_c", "Maine FIA, unmanaged", set == "mefia_ph_c", "Maine FIA, post-harvest", set == "silc_l_c", "Seven Islands CFI"),
  levels = c("Maine FIA, unmanaged", "Maine FIA, post-harvest", "Seven Islands CFI"))]
f1[, metlab := factor(metric, levels = c("BA", "TOTVOL", "BIOMASS"), labels = c("Basal area", "Total volume", "Aboveground biomass"))]
p1 <- ggplot(f1, aes(bias_pct, version, colour = arm)) + geom_vline(xintercept = 0, linewidth = 0.3) +
  geom_errorbar(aes(xmin = bias_lo, xmax = bias_hi), width = 0.25, orientation = "y") + geom_point(size = 1.8) +
  facet_grid(setlab ~ metlab) + scale_colour_manual(values = COLS, guide = "none") +
  labs(x = "Bias at remeasurement (%), 95% stand bootstrap interval", y = NULL) + th
ggsave(file.path(OD, "fig/acdx_fig1_hindcast_bias.png"), p1, width = 7.2, height = 4.6, dpi = 300, bg = "white")
f2 <- S[set %in% key & metric == "BIOMASS"][, setlab := f1[metric == "BIOMASS"]$setlab[match(set, f1[metric == "BIOMASS"]$set)]]
p2 <- ggplot(f2, aes(x = dint / mean_obs * 100, y = slope, colour = arm)) +
  annotate("rect", xmin = -25, xmax = 25, ymin = 0.75, ymax = 1.25, fill = "grey90") +
  geom_errorbar(aes(ymin = slope_lo90, ymax = slope_hi90), width = 0) + geom_errorbar(aes(xmin = dint_lo90 / mean_obs * 100, xmax = dint_hi90 / mean_obs * 100), width = 0, orientation = "y") +
  geom_point(size = 1.8) + facet_wrap(~setlab) + scale_colour_manual(values = COLS, labels = ARMS, name = NULL) +
  labs(x = "Mean observed minus mean predicted AGB (% of observed)", y = "Slope, observed on predicted") + th
ggsave(file.path(OD, "fig/acdx_fig2_equivalence_agb.png"), p2, width = 7.2, height = 3.2, dpi = 300, bg = "white")
SPH[, htlab := factor(htype, levels = c("light", "intermediate", "heavy", "low_volume"), labels = c("Light", "Intermediate", "Heavy", "Low volume"))]
p3 <- ggplot(SPH, aes(htlab, gap, colour = arm)) + geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_pointrange(aes(ymin = gap_lo, ymax = gap_hi), position = position_dodge(0.5), size = 0.3) +
  scale_colour_manual(values = COLS, labels = ARMS, name = NULL) +
  labs(x = "FCCL harvest type at the previous visit", y = expression(atop("Predicted minus observed", "AGB change (Mg ha"^-1*" yr"^-1*")"))) + th
ggsave(file.path(OD, "fig/acdx_fig3_postharvest_recovery.png"), p3, width = 5.6, height = 3.4, dpi = 300, bg = "white")
gc()

## ---------------- Part B: 200 yr projections ----------------
TJ <- rbindlist(lapply(names(ARMS), function(arm) {
  f <- list.files(file.path(X, "long200/out", arm, "mefia_l_c"), pattern = "_traj\\.csv$", full.names = TRUE)
  if (!length(f)) { log_err("no traj %s", arm); return(NULL) }
  z <- rbindlist(lapply(f, fread, select = c("STAND", "yr", "TPH", "BA", "QMD", "TOPHT", "TOTVOL", "SDI", "BIOMASS")))
  z[, arm := arm] }))
LR <- rbindlist(lapply(names(ARMS), function(arm) { f <- list.files(file.path(X, "long200/out", arm, "mefia_l_c"), pattern = "_results\\.csv$", full.names = TRUE)
  rbindlist(lapply(f, fread, select = c("STAND", "RUN_OK", "FAIL_REASON")))[, arm := arm] }))
fwrite(LR[, .(n = .N, ok = sum(RUN_OK == 1)), by = arm], file.path(OD, "acdx_long200_completion_DATA.csv"))
okL <- LR[RUN_OK == 1, .(na = uniqueN(arm)), by = STAND][na == length(ARMS), STAND]
TJ <- TJ[STAND %in% okL]

## stand attributes from FIADB (no coordinates read): root CN chain, visit at Y1, single condition type and age, section
pr <- fread(file.path(FR, "bench_gyr_mefia_l_c_pairs.csv"), select = c("STAND", "SITE", "PLOTKEY", "Y1"))
es <- fread(file.path(FR, "bench_gyr_mefia_l_c_site_esi.csv"))
pr <- merge(pr, es, by = "SITE", all.x = TRUE)
pr[, ROOT := sub("^FIA", "", PLOTKEY)]
PL <- fread(file.path(H, "fia_data/ME_PLOT.csv"), select = c("CN", "PREV_PLT_CN", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "MEASYEAR"), colClasses = list(character = c("CN", "PREV_PLT_CN")))
PL[, pid := paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "_")]
GE <- fread(file.path(H, "fia_data/ME_PLOTGEOM.csv"), select = c("CN", "ECOSUBCD"), colClasses = list(character = "CN"))
PL <- merge(PL, GE, by = "CN", all.x = TRUE)[, section := sub("[a-z]+$", "", gsub(" ", "", ECOSUBCD))]
pr <- merge(pr, PL[, .(ROOT = CN, pid)], by = "ROOT", all.x = TRUE)
pr <- merge(pr, PL[, .(pid, Y1 = MEASYEAR, CN1 = CN, section)], by = c("pid", "Y1"), all.x = TRUE)
pr <- pr[!duplicated(STAND)]
CO <- fread(file.path(H, "fia_data/ME_COND.csv"), select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "FORTYPCD", "STDAGE"), colClasses = list(character = "PLT_CN"))
CO <- CO[COND_STATUS_CD == 1][order(PLT_CN, CONDID)][!duplicated(PLT_CN)]
CO[, g10 := (FORTYPCD %/% 10) * 10][, ftg := fcase(g10 == 120, "SF", g10 == 800, "MBB", g10 == 900, "AB", g10 == 100, "WRPH",
  g10 %in% c(400, 500, 510, 520), "OAK", g10 == 700, "EAC", default = "OTH")]
pr <- merge(pr, CO[, .(CN1 = PLT_CN, ftg, STDAGE)], by = "CN1", all.x = TRUE)
## FIADB AGB at t1 (all live trees, DRYBIO_AG, Mg/ha) for the basis ratio to the engine NSVB biomass
TR <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("PLT_CN", "STATUSCD", "DRYBIO_AG", "TPA_UNADJ"), colClasses = list(character = "PLT_CN"))[PLT_CN %in% pr$CN1]
TR <- TR[STATUSCD == 1 & is.finite(DRYBIO_AG) & is.finite(TPA_UNADJ), .(AGB_fia = sum(DRYBIO_AG * TPA_UNADJ) * 0.453592 / 1000 * 2.471054), by = PLT_CN]
pr <- merge(pr, TR[, .(CN1 = PLT_CN, AGB_fia)], by = "CN1", all.x = TRUE)
rm(TR); gc()
b0 <- TJ[yr == 0 & arm == "v141LT", .(STAND, B0 = BIOMASS)]
pr <- merge(pr, b0, by = "STAND", all.x = TRUE)
kb <- pr[is.finite(AGB_fia) & B0 > 5, median(AGB_fia / B0)]
cat(sprintf("basis ratio FIADB AGB / engine NSVB biomass at t1 (median) = %.4f\n", kb))
attrs <- pr[, .(STAND, ftg, STDAGE, section, esi8, AGB_fia, B0)]
fwrite(attrs[, .(n = .N, n_age = sum(is.finite(STDAGE))), by = ftg], file.path(OD, "acdx_long200_population_DATA.csv"))
TJ <- merge(TJ, attrs[, .(STAND, ftg, STDAGE, esi8)], by = "STAND")
TJ[, `:=`(AGBadj = BIOMASS * kb, age = STDAGE + yr)]

## curves (statewide) and observed references
CV <- fread(file.path(YC, "stress/final_curves_capped_DATA.csv"))[section == "ALL", .(ftg, age, AGB_med, lo95, hi95, extrapolated)]
MG <- fread(file.path(YC, "bakuzis/magnitude_reference_DATA.csv"))
NC <- fread(file.path(YC, "bakuzis/net_change_by_age_DATA.csv"))[screen == "hf"]
BD <- fread(file.path(YC, "stress/bootstrap_decline_DATA.csv"))

## B1: projected against curve at matching age
TJc <- merge(TJ[is.finite(age)], CV[, .(ftg, age = as.integer(age), AGB_cur = AGB_med, cur_lo = lo95, cur_hi = hi95)], by = c("ftg", "age"))
B1 <- TJc[yr %in% c(0, 50, 100, 150, 200) & AGB_cur > 1, {
  r <- AGBadj / AGB_cur; b <- replicate(NB, median(sample(r, length(r), TRUE)))
  .(n = .N, ratio_med = as.numeric(median(r)), ratio_lo = quantile(b, .025), ratio_hi = quantile(b, .975), in_band = mean(AGBadj >= cur_lo & AGBadj <= cur_hi)) },
  by = .(arm, ftg, yr)][order(arm, ftg, yr)]
fwrite(B1, file.path(OD, "acdx_long200_vs_curves_DATA.csv"))

## B2: peak and decline per stand
PK <- TJ[, .(peak_yr = yr[which.max(AGBadj)], bmax = max(AGBadj), b200 = AGBadj[yr == max(yr)], age0 = STDAGE[1]), by = .(arm, STAND, ftg)]
PK[, `:=`(r200 = b200 / bmax, declining = b200 < 0.95 * bmax)]
B2 <- PK[, { bb <- replicate(NB, mean(sample(declining, .N, TRUE)))
  .(n = .N, share_declining = mean(declining), dec_lo = quantile(bb, .025), dec_hi = quantile(bb, .975),
    peak_yr_med = as.numeric(median(peak_yr)), peak_age_med = as.numeric(median(peak_yr + age0, na.rm = TRUE)), r200_med = as.numeric(median(r200))) }, by = .(arm, ftg)]
B2 <- merge(B2, BD[, .(ftg, curve_p_peak_before_250 = p_decline_250, curve_peak_q50 = peak_q50)], by = "ftg", all.x = TRUE)
fwrite(B2, file.path(OD, "acdx_long200_peak_decline_DATA.csv"))

## B3: projected net change by age class against observed FIA net change
setorder(TJ, arm, STAND, yr)
TJ[, dB := (shift(AGBadj, -1) - AGBadj) / (shift(yr, -1) - yr), by = .(arm, STAND)]
TJ[, amid := age + 2.5]
brk <- c(0, 20, 40, 60, 80, 100, 120, 250, Inf)
TJ[, ageclass := as.character(cut(amid, brk, right = FALSE))]
B3 <- TJ[is.finite(dB) & is.finite(amid), { m <- .SD[, .(d = mean(dB)), by = STAND]
  bb <- replicate(NB, mean(sample(m$d, nrow(m), TRUE))); .(n_stands = nrow(m), dB_pred = mean(m$d), pred_lo = quantile(bb, .025), pred_hi = quantile(bb, .975)) },
  by = .(arm, ftg, ageclass)]
B3 <- merge(B3, NC[, .(ftg, ageclass, dB_obs = dB_mean, obs_lo = dB_lo, obs_hi = dB_hi, obs_plots = plots)], by = c("ftg", "ageclass"), all.x = TRUE)
fwrite(B3, file.path(OD, "acdx_long200_netchange_by_age_DATA.csv"))

## B4: empirical Bakuzis relations on the FIA trajectories
bk <- rbindlist(lapply(names(ARMS), function(ar) {
  T0 <- TJ[arm == ar]
  y100 <- T0[yr == 100]
  so <- y100[is.finite(esi8), { if (.N >= 15) { ct <- suppressWarnings(cor(esi8, AGBadj, method = "spearman")); bb <- replicate(NB, { i <- sample.int(.N, .N, TRUE); suppressWarnings(cor(esi8[i], AGBadj[i], method = "spearman")) })
    .(rho = ct, lo = quantile(bb, .025, na.rm = TRUE), hi = quantile(bb, .975, na.rm = TRUE), n = .N) } else NULL }, by = ftg][, relation := "site ordering: Spearman(ESI, AGB at yr 100) > 0"]
  q999 <- MG[, .(ftg, AGB_q999, SDI_q999)]
  mx <- merge(T0[, .(bmax = max(AGBadj), smax = max(SDI)), by = .(STAND, ftg)], q999, by = "ftg")
  mag <- mx[, .(rho = mean(bmax > AGB_q999), lo = NA_real_, hi = NA_real_, n = .N), by = ftg][, relation := "magnitude: share of stands whose max AGB exceeds observed 99.9th percentile"]
  rei <- mx[, .(rho = mean(smax > SDI_q999), lo = NA_real_, hi = NA_real_, n = .N), by = ftg][, relation := "Reineke: share of stands whose max SDI exceeds observed 99.9th percentile"]
  T0[, est := cut(esi8, quantile(esi8, c(0, 1/3, 2/3, 1), na.rm = TRUE), include.lowest = TRUE, labels = c("low", "mid", "high"))]
  ei <- T0[yr >= 20 & TOPHT > 5 & is.finite(est), .(b = coef(lm(log(TOTVOL + 1) ~ log(TOPHT)))[2]), by = est]
  eic <- data.table(ftg = "ALL", rho = ei[est == "high", b] / ei[est == "low", b], lo = NA_real_, hi = NA_real_, n = nrow(T0[yr == 0]),
    relation = "Eichhorn: slope ratio of log volume on log top height, high over low ESI tercile (near 1 holds)")
  yd <- merge(T0[yr == 0, .(STAND, tph0 = TPH)], T0[yr == 100, .(STAND, b100 = AGBadj)], by = "STAND")
  ydc <- data.table(ftg = "ALL", rho = suppressWarnings(cor(yd$tph0, yd$b100, method = "spearman")), lo = NA_real_, hi = NA_real_, n = nrow(yd),
    relation = "yield-density: Spearman(initial TPH, AGB at yr 100), near 0 holds")
  rbind(so, mag, rei, eic, ydc, fill = TRUE)[, arm := ar] }))
fwrite(bk, file.path(OD, "acdx_long200_bakuzis_DATA.csv"))

## Figures B
mt <- TJc[, .(med = median(AGBadj), q25 = quantile(AGBadj, .25), q75 = quantile(AGBadj, .75), n = uniqueN(STAND)), by = .(arm, ftg, age = 10 * (age %/% 10) + 5)][n >= 15]
mt[, ftgl := factor(FTN[ftg], levels = FTN)]
cvp <- CV[ftg %in% unique(mt$ftg) & age <= max(mt$age)][, ftgl := factor(FTN[ftg], levels = FTN)]
p4 <- ggplot() + geom_ribbon(data = cvp, aes(age, ymin = lo95, ymax = hi95), fill = "grey80") +
  geom_line(data = cvp, aes(age, AGB_med), colour = "grey30", linewidth = 0.5) +
  geom_line(data = mt, aes(age, med, colour = arm), linewidth = 0.7) +
  facet_wrap(~ftgl, scales = "free_y") + scale_colour_manual(values = COLS, labels = ARMS, name = NULL) + coord_cartesian(xlim = c(0, 300)) +
  labs(x = "Stand age (yr)", y = expression("AGB (Mg ha"^-1*")"), caption = "Grey: Maine FIA AGB curve, 95% band. Lines: median projection, 10 yr age bins with at least 15 stands.") + th
ggsave(file.path(OD, "fig/acdx_fig4_long200_vs_curves.png"), p4, width = 7.2, height = 4.8, dpi = 300, bg = "white")
f5 <- B3[ftg %in% c("SF", "MBB", "AB", "WRPH") & ageclass != "[250,Inf)"]
f5[, ftgl := factor(FTN[ftg], levels = FTN)][, ac := factor(ageclass, levels = c("[0,20)", "[20,40)", "[40,60)", "[60,80)", "[80,100)", "[100,120)", "[120,250)"))]
p5 <- ggplot(f5, aes(ac)) + geom_pointrange(aes(y = dB_obs, ymin = obs_lo, ymax = obs_hi), colour = "black", shape = 15, size = 0.25) +
  geom_pointrange(aes(y = dB_pred, ymin = pred_lo, ymax = pred_hi, colour = arm), position = position_dodge(0.6), size = 0.2) +
  geom_hline(yintercept = 0, linewidth = 0.3) + facet_wrap(~ftgl) + scale_colour_manual(values = COLS, labels = ARMS, name = NULL) +
  labs(x = "Age class (yr)", y = expression("Net AGB change (Mg ha"^-1*" yr"^-1*")"), caption = "Black squares: observed FIA net change, harvest free intervals, 95% interval. Coloured: projected.") +
  th + theme(axis.text.x = element_text(angle = 40, hjust = 1))
ggsave(file.path(OD, "fig/acdx_fig5_netchange_by_age.png"), p5, width = 7.2, height = 4.8, dpi = 300, bg = "white")
cat("done\n")
