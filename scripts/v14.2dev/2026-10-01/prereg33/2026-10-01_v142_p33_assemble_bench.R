## PREREG33 benchmark assembly: copy of the PREREG28b assembly (revision 2, md5 90e6c5bc) with the arm names, job roots, dry
## run stand in, output names and verdict text changed; H0 is cited from the PREREG33 G0a and G0b record (logs/g0_result.csv);
## the PREREG28b arm p28b_small is carried as a reported comparator and its height and stand rows are reproduced against the
## PREREG28b assembled tables before any p33 value is used [F9]. Candidate p33_dyn (QC_AFAC_DYNAMIC 1: 1.265 below 25 cm,
## 0.111 at and above, reassigned from current DBH every annual step). Diff in ../diffs/. No coordinates. No em dashes.
## PREREG28b assembly: copy of the PREREG28 assembly (md5 2734ff5d) with only the arm names, job roots, dry run stand ins,
## output names and verdict text changed. Candidate p28b_small (1.265 below 25 cm, 0.111 at and above); p28_g0 (H0) and
## p28_cand (reported) are read from ~/jobs/v142p28. No coordinates. No em dashes.
## PREREG28 assembly: H0 harness reproduction (p28_g0 against frozen p19_a0111), K1, H_inc pooled and by t1 diameter class,
## TOPHT with the dominant cohort level check, V2, B1 and B2 on screened qc_c fold B, the decision rule in the
## pre-registered order, tables and figure into ~/jobs/v142p28/assembled/ (refuses if it exists). Candidate p28_cand
## (QC_AFAC_SMALL 1.265 below 25 cm t1 DBH, QC_AFAC_LARGE 0.030 at and above), reference frozen p19_a0111 (QC_AFAC 0.111),
## TOPHT comparator frozen p23_a1061. Formulas are the PREREG23 assembly formulas (2026-09-29_v142_p23_assemble.R); the
## height key is the PREREG23 helper copied unedited. Margins are parsed from the PREREG23 assembly file, and the frozen
## PREREG19 grid and PREREG23 height table are reproduced before any p28 value is used [F9]. Site cluster bootstrap B = 1000,
## seed 20260929 (the PREREG23 draws). No coordinates. No em dashes.
source("/home/aaron/jobs/v142p33/scripts/2026-09-29_v142_p23_hkey.R")
suppressMessages(library(ggplot2)); set.seed(20260929); B <- 1000L
J <- "/home/aaron/jobs/v142p33"; P28 <- "/home/aaron/jobs/v142p28b"; P23 <- "/home/aaron/jobs/v142p23"; DRY <- Sys.getenv("P33_DRYRUN") == "1"; O <- if (DRY) file.path(J, "dry/bench_assembled") else file.path(J, "assembled/bench"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
## provenance: PREREG23 assembly (margins), PREREG23 height table and class gate (reference values), PREREG19 grid
A23 <- file.path(P23, "scripts/2026-09-29_v142_p23_assemble.R"); L23 <- readLines(A23)
ml <- grep("^CAND <- \"p23_a1061\"; REF <- \"p19_a0111\"; M_CLS <- [0-9.]+; M_DOM <- [0-9.]+$", L23, value = TRUE); if (length(ml) != 1) stop("PREREG23 margin line not found")
M_CLS <- as.numeric(sub(".*M_CLS <- ([0-9.]+);.*", "\\1", ml)); M_DOM <- as.numeric(sub(".*M_DOM <- ([0-9.]+)$", "\\1", ml))
if (!any(endsWith(L23, "<= 1.0),")) || !any(endsWith(L23, "<= 2.0))"))) stop("PREREG23 B1 or B2 margin not found")
M_B1 <- 1.0; M_B2 <- 2.0; M_V2 <- -0.5; if (!any(endsWith(L23, ">= -0.5),"))) stop("PREREG23 V2 margin not found")
cat(sprintf("margins from %s (md5 %s): M_CLS %.3f M_DOM %.3f B1 %.1f B2 %.1f V2 %.1f\n", A23, tools::md5sum(A23), M_CLS, M_DOM, M_B1, M_B2, M_V2))
HT23 <- fread(file.path(P23, "assembled/gyr142-p23-hinc_DATA_2026-09-29.csv")); CG23 <- fread(file.path(P23, "assembled/gyr142-p23-classgate_DATA_2026-09-29.csv"))
CAND <- "p33_dyn"; REF <- "p19_a0111"; TOPC <- "p23_a1061"
AR <- data.table(arm = c("p19_a0030", "p19_a0111", "p23_a1061", "p23_a1250", "p28b_small", "p33_dyn"), qc_afac = c(0.030, 0.111, 1.061, 1.250, NA, NA))
AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p33"), J, P28)))]; AR[, src := arm]
## dry run (P28_DRYRUN=1): the two new arms are stood in by frozen arms (p28_g0 by p19_a0111, p28_cand by p23_a1061), output to dryrun/
if (DRY) { AR[arm == "p33_dyn", `:=`(src = "p23_a1250", root = P23)] }  # PREREG33 dry run: p33_dyn stood in by frozen p23_a1250, output to dry/
AR[, `:=`(home = file.path(root, "home"), stands = fifelse(startsWith(src, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(src, "p23"), file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"), fifelse(root == J, file.path(J, "tables/gyr142-p33-fb-stands_DATA_2026-09-27.csv"), file.path(P28, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv")))))]
res <- function(a, s) { x <- AR[arm == a]; fread(file.path(x$root, "results", x$src, sprintf("gyr_%s_%s_results.csv", x$src, s)))[, STAND := as.character(STAND)] }
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
## ---- H0: p28_g0 reproduces frozen p19_a0111, results (every _p column, ING_p, RUN_OK) and per tree t2 lists
rd <- function(h, arm, s) { acc <- NULL; for (d in arm_dirs(h, arm, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
## PREREG33: H0 is cited from G0a (switch 0 against frozen p28b_small) and G0b (switch 2, flat 0.111, against frozen p19_a0111)
G0F <- file.path(J, "logs/g0_result.csv")
H0 <- if (file.exists(G0F)) fread(G0F)[gated == TRUE] else if (DRY) data.table(gate = "dry", set = c("qc_c", "qc_fl"), worst_results = NA_real_, worst_trees = NA_real_, stands_over_1e9 = 0L, pass = TRUE) else stop("G0 record missing")
print(H0)
K1 <- rbindlist(lapply(c("p28b_small", "p33_dyn"), function(a) rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(a, s)
  data.table(arm = a, set = s, stands = nrow(r), not_ok = sum(r$RUN_OK != 1), timelimit_left = sum(grepl("elapsed time limit", r$FAIL_REASON))) }))))
k1_pass <- K1[arm == CAND, sum(not_ok)] == 0
## ---- stand level summaries by fold (PREREG19 assembly formulas, as in PREREG23)
pt <- function(o, p) c(ratio = sum(p) / sum(o), bias_pct = 100 * (mean(p) - mean(o)) / mean(o), rmse_pct = 100 * sqrt(mean((p - o)^2)) / mean(o))
tph <- function(ba, qmd) ba / (pi / 40000 * qmd^2)
STS <- rbindlist(lapply(AR$arm, function(a) { x <- AR[arm == a]; STN <- fread(x$stands)[, STAND := as.character(STAND)]
  rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(a, s)[RUN_OK == 1]; r[, fold := fold_of(SITE)]
    v <- merge(STN[label == s & arm == x$src], r[, .(STAND, SITE, fold, BA_o, BA_p, QMD_o, QMD_p, TOPHT_o, TOPHT_p)], by = "STAND")
    pops <- list(`screened A` = v[cut == FALSE & fold == "A"], `screened B` = v[cut == FALSE & fold == "B"], screened = v[cut == FALSE], all = v)
    rbindlist(lapply(names(pops), function(pn) { z <- pops[[pn]]; c1 <- pt(z$V_oh, z$V_ph); z2 <- z[is.finite(tph(BA_o, QMD_o)) & is.finite(tph(BA_p, QMD_p))]
      data.table(set = s, arm = a, qc_afac = x$qc_afac, pop = pn, stands = nrow(z), sites = uniqueN(z$SITE), C0_ratio = sum(z$V_p) / sum(z$V_o),
        C1_ratio = c1[[1]], C1_bias_pct = c1[[2]], C1_rmse_pct = c1[[3]], ba_ratio = sum(z2$BA_p) / sum(z2$BA_o),
        stems_ratio = sum(tph(z2$BA_p, z2$QMD_p)) / sum(tph(z2$BA_o, z2$QMD_o)), qmd_ratio = mean(z2$QMD_p) / mean(z2$QMD_o),
        topht_bias_pct = 100 * (mean(z$TOPHT_p, na.rm = TRUE) - mean(z$TOPHT_o, na.rm = TRUE)) / mean(z$TOPHT_o, na.rm = TRUE)) })) })) }))
## reproduction of frozen stand level values (PREREG19 grid for p19 arms, PREREG23 stands summary for p23 arms); hard stop
G19 <- fread(file.path(P19, "assembled/gyr142-p19-grid_DATA_2026-09-28.csv")); S23 <- fread(file.path(P23, "assembled/gyr142-p23-stands-summary_DATA_2026-09-29.csv"))
cmpf <- function(ref, pre) { chk <- merge(STS[startsWith(arm, pre)], ref, by = c("set", "arm", "pop"), suffixes = c("", ".g"))
  list(n = nrow(chk), w = chk[, max(abs(C1_ratio - C1_ratio.g), abs(C1_rmse_pct - C1_rmse_pct.g), abs(ba_ratio - ba_ratio.g), abs(stems_ratio - stems_ratio.g), abs(topht_bias_pct - topht_bias_pct.g))]) }
r19 <- cmpf(G19, "p19"); r23 <- cmpf(S23, "p23")
cat(sprintf("frozen stand level reproduction: PREREG19 worst %.3g over %d rows; PREREG23 worst %.3g over %d rows\n", r19$w, r19$n, r23$w, r23$n))
if (r19$n < 16 || r19$w > 1e-9 || r23$n < 16 || r23$w > 1e-9) stop("FROZEN STAND REPRO FAIL")
## PREREG33: the PREREG28b arm reproduces the PREREG28b stands summary; hard stop
S28 <- fread(file.path(P28, "assembled/gyr142-p28b-stands-summary_DATA_2026-09-30.csv"))[arm == "p28b_small"]
c28 <- merge(STS[arm == "p28b_small"], S28, by = c("set", "arm", "pop"), suffixes = c("", ".g")); w28 <- c28[, max(abs(C1_ratio - C1_ratio.g), abs(C1_rmse_pct - C1_rmse_pct.g), abs(ba_ratio - ba_ratio.g), abs(stems_ratio - stems_ratio.g), abs(topht_bias_pct - topht_bias_pct.g))]
cat(sprintf("PREREG28b stand level reproduction: worst %.3g over %d rows\n", w28, nrow(c28))); if (nrow(c28) != nrow(S28) || nrow(c28) < 8 || w28 > 1e-9) stop("P28B STAND REPRO FAIL")
## ---- height increment key, all qc_c and qc_fl RUN_OK stands, both folds (PREREG23 code path)
HK <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { S0 <- stand_frame(file.path(P19, sprintf("results/p19_a0111/gyr_p19_a0111_%s_results.csv", s)), s, CUTF)
  TK <- tag_key(s, S0$STAND); K <- merge(TK$K, S0[, .(STAND, SITE, cut, fold)], by = "STAND")
  for (a in AR$arm) { p <- pred_ht(arm_dirs(AR[arm == a]$home, AR[arm == a]$src, s), TK$M, S0$STAND)
    if (a == AR$arm[1]) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
    K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", a)) }
  if (K[, anyNA(.SD), .SDcols = paste0("Hp_", AR$arm)]) stop("tag record without prediction ", s)
  K[, set := s] }))
HK[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
HK[, dho := (H2 - H1) / iv]; for (a in AR$arm) HK[, paste0("dp_", a) := (get(paste0("Hp_", a)) - H1) / iv]
HT <- list()
for (s in c("qc_c", "qc_fl")) for (fd in c("A", "B")) { X <- HK[set == s & fold == fd & cut == FALSE]
  sites <- unique(X$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
  grp <- list(overall = X, `below 12.7` = X[cls == "below 12.7"], `12.7 to 25` = X[cls == "12.7 to 25"], `25 and over` = X[cls == "25 and over"], dominant = X[dom == TRUE])
  for (g in names(grp)) { Y <- grp[[g]]; if (!nrow(Y)) next
    SS <- Y[, c(list(n = .N, o = sum(dho), h2 = sum(H2)), lapply(setNames(AR$arm, paste0("d_", AR$arm)), function(a) sum(get(paste0("dp_", a)))),
                lapply(setNames(AR$arm, paste0("L_", AR$arm)), function(a) sum(get(paste0("Hp_", a))))), by = SITE]
    w <- matrix(0, nrow(SS), B); m <- match(SS$SITE, sites); for (b in 1:B) w[, b] <- tabulate(IDX[, b], ns)[m]
    for (a in AR$arm) { d <- SS[[paste0("d_", a)]]; L <- SS[[paste0("L_", a)]]
      rb <- colSums(w * d) / colSums(w * SS$o); bb <- (colSums(w * d) - colSums(w * SS$o)) / colSums(w * SS$n); lb <- colSums(w * L) / colSums(w * SS$h2)
      HT[[paste(s, fd, g, a)]] <- data.table(set = s, fold = fd, group = g, arm = a, qc_afac = AR[arm == a]$qc_afac, trees = sum(SS$n), sites = nrow(SS),
        obs_m_yr = sum(SS$o) / sum(SS$n), pred_m_yr = sum(d) / sum(SS$n), ratio = sum(d) / sum(SS$o), ratio_lo = quantile(rb, .025, na.rm = TRUE), ratio_hi = quantile(rb, .975, na.rm = TRUE),
        bias_m_yr = (sum(d) - sum(SS$o)) / sum(SS$n), bias_lo = quantile(bb, .025, na.rm = TRUE), bias_hi = quantile(bb, .975, na.rm = TRUE),
        level_t2 = sum(L) / sum(SS$h2), level_lo = quantile(lb, .025, na.rm = TRUE), level_hi = quantile(lb, .975, na.rm = TRUE)) } } }
HT <- rbindlist(HT)
## reproduce the PREREG23 height table for the frozen arms, point values and intervals (same seed and draw order); hard stop
hc <- merge(HT[!startsWith(arm, "p28") & !startsWith(arm, "p33")], HT23, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))
hw <- hc[, max(abs(ratio - ratio.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r))]
hwi <- hc[, max(abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r), abs(level_lo - level_lo.r))]
cat(sprintf("PREREG23 height table reproduction: point worst %.3g, interval worst %.3g, over %d rows\n", hw, hwi, nrow(hc)))
if (nrow(hc) < 60 || hw > 1e-9) stop("P23 HINC REPRO FAIL")
## PREREG33: the PREREG28b arm reproduces the PREREG28b height table, points and intervals (same seed and draw order); hard stop on points
R28 <- fread(file.path(P28, "assembled/gyr142-p28b-hinc_DATA_2026-09-30.csv"))[arm == "p28b_small"]
h28 <- merge(HT[arm == "p28b_small"], R28, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))
h28w <- h28[, max(abs(ratio - ratio.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r))]; h28i <- h28[, max(abs(ratio_lo - ratio_lo.r), abs(ratio_hi - ratio_hi.r), abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r), abs(level_lo - level_lo.r))]
cat(sprintf("PREREG28b height table reproduction: point worst %.3g, interval worst %.3g, over %d rows\n", h28w, h28i, nrow(h28))); if (nrow(h28) != nrow(R28) || nrow(h28) < 10 || h28w > 1e-9) stop("P28B HINC REPRO FAIL")
w_out(HT, "gyr142-p33-hinc_DATA_2026-10-01.csv")
## ---- gates on screened qc_c fold B
hb <- function(a, g) HT[set == "qc_c" & fold == "B" & group == g & arm == a]
sb <- function(a) STS[set == "qc_c" & pop == "screened B" & arm == a]
c0 <- hb(REF, "overall"); c1 <- hb(CAND, "overall")
cls_tab <- rbindlist(lapply(c("below 12.7", "12.7 to 25", "25 and over"), function(g) { r <- hb(REF, g); c <- hb(CAND, g); r23 <- CG23[group == g]$bias_ref
  if (length(r23) != 1 || abs(r23 - r$bias_m_yr) > 1e-9) stop("reference class bias does not match PREREG23 classgate ", g)
  data.table(group = g, trees = c$trees, bias_ref = r$bias_m_yr, bias_cand = c$bias_m_yr, bias_cand_lo = c$bias_lo, bias_cand_hi = c$bias_hi, bias_1061 = hb(TOPC, g)$bias_m_yr,
    worse_by = abs(c$bias_m_yr) - abs(r$bias_m_yr), pass = abs(c$bias_m_yr) - abs(r$bias_m_yr) <= M_CLS) }))
d0 <- hb(REF, "dominant"); d1 <- hb(CAND, "dominant"); s0 <- sb(REF); s1 <- sb(CAND); sT <- sb(TOPC)
top_worse <- abs(s1$topht_bias_pct) > abs(sT$topht_bias_pct); dom_out <- abs(d1$level_t2 - 1) > abs(d0$level_t2 - 1) + M_DOM
GATES <- rbind(
  data.table(gate = "H0 harness", detail = paste(sprintf("%s %s: results %.2e, trees %.2e, stands over 1e-9 %d", H0$gate, H0$set, H0$worst_results, H0$worst_trees, H0$stands_over_1e9), collapse = "; "), pass = all(H0$pass)),
  data.table(gate = "K1 failures", detail = sprintf("RUN_OK other than 1 for p33_dyn after retries: qc_c %d, qc_fl %d", K1[arm == CAND & set == "qc_c"]$not_ok, K1[arm == CAND & set == "qc_fl"]$not_ok), pass = k1_pass),
  data.table(gate = "H_inc pooled", detail = sprintf("fold B ratio %.3f [%.3f, %.3f] for p33_dyn against %.3f at 0.111 (|dev| %.3f against %.3f); %d trees on %d sites", c1$ratio, c1$ratio_lo, c1$ratio_hi, c0$ratio, abs(c1$ratio - 1), abs(c0$ratio - 1), c1$trees, c1$sites), pass = abs(c1$ratio - 1) < abs(c0$ratio - 1)),
  data.table(gate = "H_inc classes", detail = paste(sprintf("%s: bias %+.3f against %+.3f m/yr (worse by %+.3f)", cls_tab$group, cls_tab$bias_cand, cls_tab$bias_ref, cls_tab$worse_by), collapse = "; "), pass = all(cls_tab$pass)),
  data.table(gate = "TOPHT reading", detail = sprintf("published TOPHT bias %+.2f percent for p33_dyn against %+.2f at 1.061 (%s) and %+.2f at 0.111; dominant cohort t2 level %.3f against %.3f at 0.111 (%s, margin %.2f)", s1$topht_bias_pct, sT$topht_bias_pct, if (top_worse) "worse" else "not worse", s0$topht_bias_pct, d1$level_t2, d0$level_t2, if (dom_out) "outside margin" else "within margin", M_DOM), pass = !top_worse && !dom_out),
  data.table(gate = "V2 %RMSE", detail = sprintf("fold B C1 %%RMSE %.2f against %.2f, d %+.2f", s1$C1_rmse_pct, s0$C1_rmse_pct, s0$C1_rmse_pct - s1$C1_rmse_pct), pass = s0$C1_rmse_pct - s1$C1_rmse_pct >= M_V2),
  data.table(gate = "B1 basal area", detail = sprintf("fold B |BA - 1| %.2f against %.2f points", 100 * abs(s1$ba_ratio - 1), 100 * abs(s0$ba_ratio - 1)), pass = 100 * (abs(s1$ba_ratio - 1) - abs(s0$ba_ratio - 1)) <= M_B1),
  data.table(gate = "B2 stems", detail = sprintf("fold B |stems - 1| %.2f against %.2f points", 100 * abs(s1$stems_ratio - 1), 100 * abs(s0$stems_ratio - 1)), pass = 100 * (abs(s1$stems_ratio - 1) - abs(s0$stems_ratio - 1)) <= M_B2))
print(GATES)
p <- setNames(GATES$pass, c("H0", "K1", "HP", "HC", "TOP", "V2", "B1", "B2"))
failcls <- paste(cls_tab[pass == FALSE]$group, collapse = ", ")
failg <- GATES$gate[!GATES$pass]
verdict <- if (!p["H0"] || !p["K1"]) "Rule 1: harness or failure gate fails; no verdict" else
  if (!all(p)) sprintf("Rule 2: benchmark gate fails (%s%s); not adopted", paste(failg, collapse = ", "), if (!p["HC"]) paste0("; class ", failcls) else "") else
  "Benchmark gates pass; the PREREG33 verdict reads the grid next (rule 3 or 4)"
cat("VERDICT:", verdict, "\n")
w_out(GATES, "gyr142-p33-gates_DATA_2026-10-01.csv"); w_out(H0, "gyr142-p33-H0_DATA_2026-10-01.csv"); w_out(K1, "gyr142-p33-K1_DATA_2026-10-01.csv")
w_out(cls_tab, "gyr142-p33-classgate_DATA_2026-10-01.csv"); w_out(STS, "gyr142-p33-stands-summary_DATA_2026-10-01.csv")
writeLines(c(sprintf("candidate=%s", CAND), sprintf("reference=%s", REF), sprintf("topht_comparator=%s", TOPC), paste0("verdict=", verdict), sprintf("bench_pass=%s", all(p)), sprintf("harness_ok=%s", p["H0"] && p["K1"])), file.path(O, "gyr142-p33-verdict_DATA_2026-10-01.txt"))
## ---- figure: screened qc_c, bias by class and pooled ratio, fold A and fold B, arms 0.030, 0.111, 1.061, 1.250 and the pair
F <- HT[set == "qc_c" & arm != "p28_g0" & group != "dominant"]
F[, armlab := factor(c(p19_a0030 = "0.030", p19_a0111 = "0.111", p23_a1061 = "1.061", p23_a1250 = "1.250", p28b_small = "Small only 1.265 / 0.111", p33_dyn = "Dynamic 1.265 / 0.111")[arm], levels = c("0.030", "0.111", "1.061", "1.250", "Small only 1.265 / 0.111", "Dynamic 1.265 / 0.111"))]
F[, panel := factor(fifelse(group == "overall", "Pooled ratio, all trees", paste0("Bias (m/yr), ", group, " cm")),
                    levels = c("Pooled ratio, all trees", "Bias (m/yr), below 12.7 cm", "Bias (m/yr), 12.7 to 25 cm", "Bias (m/yr), 25 and over cm"))]
F[, `:=`(y = fifelse(group == "overall", ratio, bias_m_yr), lo = fifelse(group == "overall", ratio_lo, bias_lo), hi = fifelse(group == "overall", ratio_hi, bias_hi))]
F[, ref := fifelse(group == "overall", 1, 0)]; F[, Fold := fifelse(fold == "A", "Fold A (fit)", "Fold B (held out)")]
g <- ggplot(F, aes(armlab, y, colour = Fold)) + geom_hline(aes(yintercept = ref), linetype = 2, colour = "grey40") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, position = position_dodge(width = 0.5)) + geom_point(size = 1.8, position = position_dodge(width = 0.5)) +
  scale_colour_manual(values = c(`Fold A (fit)` = "#1b6ca8", `Fold B (held out)` = "#b5452b")) + facet_wrap(~panel, scales = "free_y", ncol = 2) +
  labs(x = "QC height anchor (QC_AFAC, or the size dependent pair)", y = "Predicted against observed annual height increment", colour = NULL) +
  theme_classic(base_size = 10) + theme(legend.position = "bottom", strip.background = element_blank(), axis.text.x = element_text(size = 7.5), plot.margin = margin(10, 12, 6, 6))
ggsave(file.path(O, "gyr142-p33-hinc_2026-10-01.png"), g, width = 7.5, height = 6, dpi = 300)
cat("P33_BENCH_ASSEMBLE_DONE\n")
