## PREREG38 assembly. Formulas are the PREREG28b assembly (2026-09-30_v142_p28b_assemble.R, md5 90e6c5bc) with the height key
## run twice: pass 1 under the helper's default run frames (TREE = row index), frozen arms only, seed 20260929, to reproduce
## the PREREG23 height table; pass 2 under the MAGPlot field tag frames (v142p14/in/pass28qc, as PREREG37), seed 20261001,
## the basis of every height gate. H0 (p38_one subset against frozen p19_a1000), K1, reproduction stops R1 to R5, gates on
## screened qc_c fold B, decision rule in the PREREG38 order, tables and figure into ~/jobs/v142p38/assembled/ (refuses if it
## exists). Candidate p38_fit (single QC_AFAC from the fold A fit file), reference frozen p19_a0111 (qc141), TOPHT comparator
## frozen p23_a1061, reported p28b_small and every frozen single value arm. Site cluster bootstrap B = 1000. No coordinates.
## No em dashes.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")
suppressMessages({ library(ggplot2); library(patchwork) }); B <- 1000L
J <- "/home/aaron/jobs/v142p38"; P23 <- "/home/aaron/jobs/v142p23"; P28B <- "/home/aaron/jobs/v142p28b"; P37 <- "/home/aaron/jobs/v142p37"
FR_RUN <- FR; FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"; DT <- "2026-10-01"
O <- file.path(J, "assembled"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
## ---- margins from the PREREG23 assembly (as PREREG28b)
A23 <- file.path(P23, "scripts/2026-09-29_v142_p23_assemble.R"); L23 <- readLines(A23)
if (unname(tools::md5sum(A23)) != "429f441e5522b644a011d267193fd3db") stop("PREREG23 assembly md5 differs")
ml <- grep("^CAND <- \"p23_a1061\"; REF <- \"p19_a0111\"; M_CLS <- [0-9.]+; M_DOM <- [0-9.]+$", L23, value = TRUE); if (length(ml) != 1) stop("PREREG23 margin line not found")
M_CLS <- as.numeric(sub(".*M_CLS <- ([0-9.]+);.*", "\\1", ml)); M_DOM <- as.numeric(sub(".*M_DOM <- ([0-9.]+)$", "\\1", ml))
if (!any(endsWith(L23, "<= 1.0),")) || !any(endsWith(L23, "<= 2.0))"))) stop("PREREG23 B1 or B2 margin not found")
M_B1 <- 1.0; M_B2 <- 2.0; M_V2 <- -0.5; if (!any(endsWith(L23, ">= -0.5),"))) stop("PREREG23 V2 margin not found")
H1_LO <- 0.90; H1_HI <- 1.10
P14 <- "/home/aaron/jobs/v142p14/PREREG14_steps1-2.md"; if (!any(grepl("outside 0.9 to 1.1", readLines(P14)))) stop("PREREG14 window not found")
cat(sprintf("margins: M_CLS %.3f M_DOM %.3f B1 %.1f B2 %.1f V2 %.1f; H1 window %.2f to %.2f (PREREG14)\n", M_CLS, M_DOM, M_B1, M_B2, M_V2, H1_LO, H1_HI))
## ---- fit value, R5
FF <- file.path(J, "fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv"); fm <- strsplit(readLines(file.path(J, "logs/fit_md5.txt")), " +")[[1]][1]
if (unname(tools::md5sum(FF)) != fm) stop("fit file md5 differs from logs/fit_md5.txt")
FIT <- fread(FF, colClasses = list(character = "value")); fitv <- as.numeric(FIT$value)
r37A <- fread(file.path(P37, "assembled/gyr142-p37-ratio-foldA_DATA_2026-10-01.csv"))[tagkey == "field tag" & scheme == "all" & group == "all"]$R
R5 <- sprintf("%.3f", round(r37A, 3)) == FIT$value; if (!R5) stop("R5 fit value does not equal round(R_A, 3)")
cat(sprintf("fit value %s from R_A %.12f\n", FIT$value, r37A))
## ---- arms
AR <- data.table(arm = c("p19_a0030", "p19_a0060", "p19_a0111", "p19_a0250", "p19_a0500", "p19_a1000", "p23_a1061", "p23_a1250", "p28b_small", "p38_fit"),
                 qc_afac = c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000, 1.061, 1.250, NA, fitv))
AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p28b"), P28B, J)))]
AR[, home := file.path(root, "home")]
AR[, stands := fifelse(startsWith(arm, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p23"), file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p28b"), file.path(P28B, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(J, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"))))]
FROZEN <- AR[arm != "p38_fit"]$arm; REF <- "p19_a0111"; TOPC <- "p23_a1061"; CAND <- "p38_fit"
res <- function(a, s) { x <- AR[arm == a]; fread(file.path(x$root, "results", a, sprintf("gyr_%s_%s_results.csv", a, s)))[, STAND := as.character(STAND)] }
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
rd <- function(h, arm, s) { acc <- NULL; for (d in arm_dirs(h, arm, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
chunk_res <- function(h, arm, s) { fs <- sort(list.files(file.path(h, "out", arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE)); if (!length(fs)) stop("no chunk results ", arm, " ", s)
  r <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]
  for (k in 1:3) { g <- list.files(file.path(h, sprintf("out_retry_a%d", k), arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE); if (!length(g)) next
    x <- rbindlist(lapply(g, fread), fill = TRUE)[, STAND := as.character(STAND)][STAND %in% r$STAND]; r <- rbind(r[!STAND %in% x$STAND], x, fill = TRUE) }
  if (anyDuplicated(r$STAND)) stop("duplicated STAND ", arm, " ", s); r }
## ---- H0: p38_one (SMALL = LARGE = 1.000, subset) against frozen p19_a1000
H0 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { a <- chunk_res(file.path(J, "home"), "p38_one", s); b <- res("p19_a1000", s)[STAND %in% a$STAND]
  if (!setequal(a$STAND, b$STAND)) stop("H0 stand sets differ ", s); setkey(a, STAND); setkey(b, STAND)
  cols <- c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK")
  per <- sapply(cols, function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; d }); per <- matrix(per, nrow = nrow(b))
  wr <- max(per); ws <- apply(per, 1, max)
  ta <- rd(file.path(J, "home"), "p38_one", s); tb <- rd(file.path(P19, "home"), "p19_a1000", s); tb <- tb[STAND %in% unique(ta$STAND)]
  m <- merge(ta, tb, by = c("STAND", "tree")); if (nrow(m) != nrow(ta) || nrow(m) != nrow(tb)) stop("H0 per tree rows differ ", s)
  m[, dd := pmax(abs(ht.x - ht.y) / pmax(1, abs(ht.y)), abs(dbh.x - dbh.y) / pmax(1, abs(dbh.y)), abs(expf.x - expf.y) / pmax(1, abs(expf.y)), abs(ing.x - ing.y))]
  wt <- max(m$dd); st_t <- m[, .(w = max(dd)), by = STAND]
  data.table(set = s, stands = nrow(b), trees = nrow(m), worst_results = wr, worst_trees = wt, stands_over_1e9 = sum(!is.finite(ws) | ws > 1e-9) + st_t[!is.finite(w) | w > 1e-9, .N],
    pass = is.finite(wr) && is.finite(wt) && wr <= 1e-9 && wt <= 1e-9) }))
print(H0)
K1 <- rbind(rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(CAND, s)
  data.table(arm = CAND, set = s, stands = nrow(r), not_ok = sum(r$RUN_OK != 1), timelimit_left = sum(grepl("elapsed time limit", r$FAIL_REASON))) })),
  rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- chunk_res(file.path(J, "home"), "p38_one", s)
  data.table(arm = "p38_one", set = s, stands = nrow(r), not_ok = sum(r$RUN_OK != 1), timelimit_left = sum(grepl("elapsed time limit", r$FAIL_REASON))) })))
k1_pass <- K1[arm == CAND, sum(not_ok)] == 0; print(K1)
## ---- stand level summaries by fold (PREREG19 formulas, as PREREG23 and 28b)
pt <- function(o, p) c(ratio = sum(p) / sum(o), bias_pct = 100 * (mean(p) - mean(o)) / mean(o), rmse_pct = 100 * sqrt(mean((p - o)^2)) / mean(o))
tph <- function(ba, qmd) ba / (pi / 40000 * qmd^2)
STS <- rbindlist(lapply(AR$arm, function(a) { x <- AR[arm == a]; STN <- fread(x$stands)[, STAND := as.character(STAND)]
  rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(a, s)[RUN_OK == 1]; r[, fold := fold_of(SITE)]
    v <- merge(STN[label == s & arm == a], r[, .(STAND, SITE, fold, BA_o, BA_p, QMD_o, QMD_p, TOPHT_o, TOPHT_p)], by = "STAND")
    pops <- list(`screened A` = v[cut == FALSE & fold == "A"], `screened B` = v[cut == FALSE & fold == "B"], screened = v[cut == FALSE], all = v)
    rbindlist(lapply(names(pops), function(pn) { z <- pops[[pn]]; c1 <- pt(z$V_oh, z$V_ph); z2 <- z[is.finite(tph(BA_o, QMD_o)) & is.finite(tph(BA_p, QMD_p))]
      data.table(set = s, arm = a, qc_afac = x$qc_afac, pop = pn, stands = nrow(z), sites = uniqueN(z$SITE), C0_ratio = sum(z$V_p) / sum(z$V_o),
        C1_ratio = c1[[1]], C1_bias_pct = c1[[2]], C1_rmse_pct = c1[[3]], ba_ratio = sum(z2$BA_p) / sum(z2$BA_o),
        stems_ratio = sum(tph(z2$BA_p, z2$QMD_p)) / sum(tph(z2$BA_o, z2$QMD_o)), qmd_ratio = mean(z2$QMD_p) / mean(z2$QMD_o),
        topht_bias_pct = 100 * (mean(z$TOPHT_p, na.rm = TRUE) - mean(z$TOPHT_o, na.rm = TRUE)) / mean(z$TOPHT_o, na.rm = TRUE)) })) })) }))
## ---- R2: frozen stand level reproduction (PREREG19 grid, PREREG23 stands summary, PREREG28b stands summary)
G19 <- fread(file.path(P19, "assembled/gyr142-p19-grid_DATA_2026-09-28.csv")); S23 <- fread(file.path(P23, "assembled/gyr142-p23-stands-summary_DATA_2026-09-29.csv"))
S28B <- fread(file.path(P28B, "assembled/gyr142-p28b-stands-summary_DATA_2026-09-30.csv"))
cmpf <- function(ref, sel) { chk <- merge(STS[arm %in% sel], ref, by = c("set", "arm", "pop"), suffixes = c("", ".g"))
  list(n = nrow(chk), w = chk[, max(abs(C1_ratio - C1_ratio.g), abs(C1_rmse_pct - C1_rmse_pct.g), abs(ba_ratio - ba_ratio.g), abs(stems_ratio - stems_ratio.g), abs(topht_bias_pct - topht_bias_pct.g))]) }
r19 <- cmpf(G19, grep("^p19", AR$arm, value = TRUE)); r23 <- cmpf(S23, grep("^p23", AR$arm, value = TRUE)); r28 <- cmpf(S28B, "p28b_small")
cat(sprintf("R2: PREREG19 worst %.3g over %d rows; PREREG23 worst %.3g over %d; PREREG28b worst %.3g over %d\n", r19$w, r19$n, r23$w, r23$n, r28$w, r28$n))
if (r19$n < 16 || r19$w > 1e-9 || r23$n < 16 || r23$w > 1e-9 || r28$n < 8 || r28$w > 1e-9) stop("R2 FROZEN STAND REPRO FAIL")
## ---- R4: r2 stand rows for p19_a0111 against the frozen PREREG19 stands table
T2 <- fread(file.path(J, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"))[arm == REF][, STAND := as.character(STAND)]
T1 <- fread(CUTF)[arm == REF & label %in% c("qc_c", "qc_fl")][, STAND := as.character(STAND)]
if (nrow(T1) != nrow(T2)) stop("R4 row counts differ ", nrow(T1), " ", nrow(T2))
num <- intersect(names(T1)[sapply(T1, is.numeric)], names(T2)[sapply(T2, is.numeric)]); mm <- merge(T1, T2, by = c("label", "STAND"), suffixes = c(".f", ".r"))
if (nrow(mm) != nrow(T1)) stop("R4 merge rows differ")
r4 <- max(sapply(setdiff(num, "STAND"), function(k) { d <- abs(mm[[paste0(k, ".f")]] - mm[[paste0(k, ".r")]]); d[is.na(mm[[paste0(k, ".f")]]) & is.na(mm[[paste0(k, ".r")]])] <- 0; max(d) }))
cat(sprintf("R4: r2 against frozen p19 stands table, worst %.3g over %d rows and %d numeric columns\n", r4, nrow(mm), length(num)))
if (!is.finite(r4) || r4 > 1e-9) stop("R4 r2 REPRO FAIL")
## ---- height increment key, both passes (PREREG23 code path)
build_hk <- function(arms) { K0 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { S0 <- stand_frame(file.path(P19, sprintf("results/p19_a0111/gyr_p19_a0111_%s_results.csv", s)), s, CUTF)
  TK <- tag_key(s, S0$STAND); K <- merge(TK$K, S0[, .(STAND, SITE, cut, fold)], by = "STAND")
  for (a in arms) { p <- pred_ht(arm_dirs(AR[arm == a]$home, a, s), TK$M, S0$STAND)
    if (a == arms[1]) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
    K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", a)) }
  if (K[, anyNA(.SD), .SDcols = paste0("Hp_", arms)]) stop("tag record without prediction ", s)
  K[, set := s] }))
  K0[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
  K0[, dho := (H2 - H1) / iv]; for (a in arms) K0[, paste0("dp_", a) := (get(paste0("Hp_", a)) - H1) / iv]; K0 }
ht_tab <- function(HK, arms, seed, key) { set.seed(seed); HT <- list()
  for (s in c("qc_c", "qc_fl")) for (fd in c("A", "B")) { X <- HK[set == s & fold == fd & cut == FALSE]
    sites <- unique(X$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
    grp <- list(overall = X, `below 12.7` = X[cls == "below 12.7"], `12.7 to 25` = X[cls == "12.7 to 25"], `25 and over` = X[cls == "25 and over"], dominant = X[dom == TRUE])
    for (g in names(grp)) { Y <- grp[[g]]; if (!nrow(Y)) next
      SS <- Y[, c(list(n = .N, o = sum(dho), h2 = sum(H2)), lapply(setNames(arms, paste0("d_", arms)), function(a) sum(get(paste0("dp_", a)))),
                  lapply(setNames(arms, paste0("L_", arms)), function(a) sum(get(paste0("Hp_", a))))), by = SITE]
      w <- matrix(0, nrow(SS), B); m <- match(SS$SITE, sites); for (b in 1:B) w[, b] <- tabulate(IDX[, b], ns)[m]
      for (a in arms) { d <- SS[[paste0("d_", a)]]; L <- SS[[paste0("L_", a)]]
        rb <- colSums(w * d) / colSums(w * SS$o); bb <- (colSums(w * d) - colSums(w * SS$o)) / colSums(w * SS$n); lb <- colSums(w * L) / colSums(w * SS$h2)
        HT[[paste(s, fd, g, a)]] <- data.table(tagkey = key, set = s, fold = fd, group = g, arm = a, qc_afac = AR[arm == a]$qc_afac, trees = sum(SS$n), sites = nrow(SS),
          obs_m_yr = sum(SS$o) / sum(SS$n), pred_m_yr = sum(d) / sum(SS$n), ratio = sum(d) / sum(SS$o), ratio_lo = quantile(rb, .025, na.rm = TRUE), ratio_hi = quantile(rb, .975, na.rm = TRUE),
          bias_m_yr = (sum(d) - sum(SS$o)) / sum(SS$n), bias_lo = quantile(bb, .025, na.rm = TRUE), bias_hi = quantile(bb, .975, na.rm = TRUE),
          level_t2 = sum(L) / sum(SS$h2), level_lo = quantile(lb, .025, na.rm = TRUE), level_hi = quantile(lb, .975, na.rm = TRUE)) } } }
  rbindlist(HT) }
## pass 1, row index, frozen arms only: R1
ARM1 <- setdiff(FROZEN, "p28b_small"); FR <- FR_RUN; HK1 <- build_hk(ARM1)
HT1 <- ht_tab(HK1, ARM1, 20260929, "row index")
HT23 <- fread(file.path(P23, "assembled/gyr142-p23-hinc_DATA_2026-09-29.csv"))
hc <- merge(HT1, HT23, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))
hw <- hc[, max(abs(ratio - ratio.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r))]
hwi <- hc[, max(abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r), abs(level_lo - level_lo.r))]
cat(sprintf("R1: PREREG23 height table reproduction, point worst %.3g, interval worst %.3g, over %d rows\n", hw, hwi, nrow(hc)))
if (nrow(hc) < 60 || hw > 1e-9) stop("R1 P23 HINC REPRO FAIL")
w_out(HT1, sprintf("gyr142-p38-hinc-rowidx_DATA_%s.csv", DT))
## pass 2, field tags: R3
FR <- FR_FIELD; sets2 <- c("qc_c", "qc_fl")
HK2 <- build_hk(AR$arm); HT <- ht_tab(HK2, AR$arm, 20261001, "field tag"); FR <- FR_RUN
n37 <- sapply(c("A", "B"), function(fd) fread(file.path(P37, sprintf("assembled/gyr142-p37-counts-fold%s_DATA_2026-10-01.csv", fd)))[tagkey == "field tag"]$records)
n38 <- sapply(c("A", "B"), function(fd) HT[set == "qc_c" & fold == fd & group == "overall" & arm == CAND]$trees)
cat(sprintf("R3: field tag screened qc_c records fold A %d (PREREG37 %d), fold B %d (PREREG37 %d)\n", n38[1], n37[1], n38[2], n37[2]))
if (any(n37 != n38)) stop("R3 FIELD TAG COUNT FAIL")
w_out(HT, sprintf("gyr142-p38-hinc_DATA_%s.csv", DT))
REPRO <- data.table(check = c("R1 PREREG23 height table (row index)", "R2 PREREG19 grid", "R2 PREREG23 stands summary", "R2 PREREG28b stands summary", "R3 field tag counts A", "R3 field tag counts B", "R4 r2 against frozen p19 stands", "R5 fit value"),
  rows = c(nrow(hc), r19$n, r23$n, r28$n, 1, 1, nrow(mm), 1), worst = c(hw, r19$w, r23$w, r28$w, abs(n38[1] - n37[1]), abs(n38[2] - n37[2]), r4, as.numeric(!R5)), pass = TRUE)
w_out(REPRO, sprintf("gyr142-p38-repro_DATA_%s.csv", DT))
## ---- gates on screened qc_c fold B, field tags
hb <- function(a, g) HT[set == "qc_c" & fold == "B" & group == g & arm == a]
sb <- function(a) STS[set == "qc_c" & pop == "screened B" & arm == a]
gate_arm <- function(a) { c0 <- hb(REF, "overall"); c1 <- hb(a, "overall"); d0 <- hb(REF, "dominant"); d1 <- hb(a, "dominant"); s0 <- sb(REF); s1 <- sb(a); sT <- sb(TOPC)
  cl <- rbindlist(lapply(c("below 12.7", "12.7 to 25", "25 and over"), function(g) { r <- hb(REF, g); x <- hb(a, g)
    data.table(group = g, bias_ref = r$bias_m_yr, bias_arm = x$bias_m_yr, worse_by = abs(x$bias_m_yr) - abs(r$bias_m_yr)) }))
  data.table(arm = a, qc_afac = AR[arm == a]$qc_afac, ratio = c1$ratio, ratio_lo = c1$ratio_lo, ratio_hi = c1$ratio_hi, trees = c1$trees, sites = c1$sites,
    bias_small = cl$bias_arm[1], bias_mid = cl$bias_arm[2], bias_large = cl$bias_arm[3], worst_class_worse_by = max(cl$worse_by), worst_class = cl$group[which.max(cl$worse_by)],
    topht = s1$topht_bias_pct, topht_limit = sT$topht_bias_pct, dom_level = d1$level_t2, dom_ref = d0$level_t2,
    rmse = s1$C1_rmse_pct, rmse_ref = s0$C1_rmse_pct, ba_pts = 100 * abs(s1$ba_ratio - 1), ba_ref_pts = 100 * abs(s0$ba_ratio - 1),
    stems_pts = 100 * abs(s1$stems_ratio - 1), stems_ref_pts = 100 * abs(s0$stems_ratio - 1),
    p_H1 = c1$ratio >= H1_LO && c1$ratio <= H1_HI, p_CLS = all(cl$worse_by <= M_CLS),
    p_TOP = abs(s1$topht_bias_pct) <= abs(sT$topht_bias_pct) && abs(d1$level_t2 - 1) <= abs(d0$level_t2 - 1) + M_DOM,
    p_TOPHT_only = abs(s1$topht_bias_pct) <= abs(sT$topht_bias_pct), p_DOM_only = abs(d1$level_t2 - 1) <= abs(d0$level_t2 - 1) + M_DOM,
    p_V2 = s0$C1_rmse_pct - s1$C1_rmse_pct >= M_V2, p_B1 = 100 * (abs(s1$ba_ratio - 1) - abs(s0$ba_ratio - 1)) <= M_B1,
    p_B2 = 100 * (abs(s1$stems_ratio - 1) - abs(s0$stems_ratio - 1)) <= M_B2) }
GA <- rbindlist(lapply(AR$arm, gate_arm)); GA[, all_pass := p_H1 & p_CLS & p_TOP & p_V2 & p_B1 & p_B2]; GA[, role := fifelse(arm == CAND, "candidate", fifelse(arm == REF, "reference", "reported"))]
print(GA[, .(arm, qc_afac, ratio, worst_class, worst_class_worse_by, topht, dom_level, rmse, p_H1, p_CLS, p_TOP, p_V2, p_B1, p_B2, all_pass)], digits = 4)
w_out(GA, sprintf("gyr142-p38-gates-all_DATA_%s.csv", DT))
g <- GA[arm == CAND]
GATES <- rbind(
  data.table(gate = "H0 harness", detail = sprintf("p38_one against frozen p19_a1000 (subset): qc_c %d stands, results %.2e, trees %.2e; qc_fl %d stands, results %.2e, trees %.2e", H0[set == "qc_c"]$stands, H0[set == "qc_c"]$worst_results, H0[set == "qc_c"]$worst_trees, H0[set == "qc_fl"]$stands, H0[set == "qc_fl"]$worst_results, H0[set == "qc_fl"]$worst_trees), pass = all(H0$pass)),
  data.table(gate = "K1 failures", detail = sprintf("RUN_OK other than 1 for p38_fit after retries: qc_c %d, qc_fl %d", K1[arm == CAND & set == "qc_c"]$not_ok, K1[arm == CAND & set == "qc_fl"]$not_ok), pass = k1_pass),
  data.table(gate = "H1 level", detail = sprintf("fold B field tag pooled ratio %.3f [%.3f, %.3f] (window %.2f to %.2f); qc141 %.3f; %d trees on %d sites", g$ratio, g$ratio_lo, g$ratio_hi, H1_LO, H1_HI, GA[arm == REF]$ratio, g$trees, g$sites), pass = g$p_H1),
  data.table(gate = "H classes", detail = sprintf("bias below 12.7 %+.3f, 12.7 to 25 %+.3f, 25 and over %+.3f m/yr; qc141 %+.3f, %+.3f, %+.3f; worst worse by %+.3f (%s), margin %.2f", g$bias_small, g$bias_mid, g$bias_large, GA[arm == REF]$bias_small, GA[arm == REF]$bias_mid, GA[arm == REF]$bias_large, g$worst_class_worse_by, g$worst_class, M_CLS), pass = g$p_CLS),
  data.table(gate = "TOPHT", detail = sprintf("TOPHT bias %+.2f percent against limit %+.2f at 1.061 (%s); dominant cohort t2 level %.3f against %.3f for qc141, margin %.2f (%s)", g$topht, g$topht_limit, if (g$p_TOPHT_only) "within" else "over", g$dom_level, g$dom_ref, M_DOM, if (g$p_DOM_only) "within" else "outside"), pass = g$p_TOP),
  data.table(gate = "V2 %RMSE", detail = sprintf("C1 %%RMSE %.2f against %.2f, d %+.2f", g$rmse, g$rmse_ref, g$rmse_ref - g$rmse), pass = g$p_V2),
  data.table(gate = "B1 basal area", detail = sprintf("|BA - 1| %.2f against %.2f points", g$ba_pts, g$ba_ref_pts), pass = g$p_B1),
  data.table(gate = "B2 stems", detail = sprintf("|stems - 1| %.2f against %.2f points", g$stems_pts, g$stems_ref_pts), pass = g$p_B2))
print(GATES)
p <- setNames(GATES$pass, c("H0", "K1", "H1", "HC", "TOP", "V2", "B1", "B2"))
elig <- GA[arm %in% FROZEN & arm != REF & !is.na(qc_afac) & all_pass == TRUE]$arm
verdict <- if (!p["H0"] || !p["K1"]) "Rule 1: harness or failure gate fails; no verdict" else
  if (!p["H1"]) sprintf("Rule 2: fold B field tag pooled height increment ratio %.3f outside %.2f to %.2f; not adopted", g$ratio, H1_LO, H1_HI) else
  if (!p["HC"]) sprintf("Rule 3: diameter class %s worse than qc141 by %.3f m/yr, more than %.2f; not adopted", g$worst_class, g$worst_class_worse_by, M_CLS) else
  if (!p["TOP"]) sprintf("Rule 4: TOPHT %+.2f percent against the %+.2f limit at 1.061, dominant cohort t2 level %.3f against %.3f for qc141; not adopted", g$topht, g$topht_limit, g$dom_level, g$dom_ref) else
  if (!(p["V2"] && p["B1"] && p["B2"])) "Rule 5: height gates pass but volume, basal area or stems fail; not adopted; trade off reported" else
  sprintf("Rule 6: every gate passes; the single field tag QC anchor %s is the 14.2 QC candidate, a regional usage setting, pending a Bakuzis QC grid under PREREG39", FIT$value)
el_txt <- if (startsWith(verdict, "Rule 6")) "not applicable (candidate passed)" else if (length(elig)) paste(elig, collapse = ", ") else "none"
cat("VERDICT:", verdict, "\n"); cat("ELIGIBLE frozen single value arms (for separate confirmation only):", el_txt, "\n")
w_out(GATES, sprintf("gyr142-p38-gates_DATA_%s.csv", DT)); w_out(H0, sprintf("gyr142-p38-H0_DATA_%s.csv", DT)); w_out(K1, sprintf("gyr142-p38-K1_DATA_%s.csv", DT))
w_out(STS, sprintf("gyr142-p38-stands-summary_DATA_%s.csv", DT))
writeLines(c(sprintf("candidate=%s", CAND), sprintf("qc_afac_fit=%s", FIT$value), sprintf("reference=%s", REF), sprintf("topht_comparator=%s", TOPC),
  paste0("verdict=", verdict), paste0("eligible_frozen_single_value_arms=", el_txt)), file.path(O, sprintf("gyr142-p38-verdict_DATA_%s.txt", DT)))
## ---- figure
lab <- function(a) c(p19_a0111 = "qc141 (0.111)", p28b_small = "p28b_small", p19_a1000 = "one (1.000)", p38_fit = sprintf("p38_fit (%s)", FIT$value))[a]
SV <- GA[!is.na(qc_afac)][, .(arm, qc_afac, ratio, ratio_lo, ratio_hi, topht, dom_level, cand = arm == CAND)]
SV <- merge(SV, HT[set == "qc_c" & fold == "B" & group == "dominant", .(arm, dom_lo = level_lo, dom_hi = level_hi)], by = "arm")
CB <- HT[set == "qc_c" & fold == "B" & group %in% c("below 12.7", "12.7 to 25", "25 and over") & arm %in% c(REF, "p28b_small", "p19_a1000", CAND),
         .(arm, group, bias_m_yr, bias_lo, bias_hi)]
CB[, armlab := factor(lab(arm), levels = lab(c(REF, "p28b_small", "p19_a1000", CAND)))]; CB[, group := factor(group, levels = c("below 12.7", "12.7 to 25", "25 and over"))]
FD <- rbind(SV[, .(panel = "a", arm, x = qc_afac, y = ratio, lo = ratio_lo, hi = ratio_hi, group = NA_character_)], SV[, .(panel = "b", arm, x = qc_afac, y = topht, lo = NA_real_, hi = NA_real_, group = NA_character_)],
            CB[, .(panel = "c", arm, x = NA_real_, y = bias_m_yr, lo = bias_lo, hi = bias_hi, group = as.character(group))], SV[, .(panel = "d", arm, x = qc_afac, y = dom_level, lo = dom_lo, hi = dom_hi, group = NA_character_)])
dir.create(file.path(J, "figs"), showWarnings = FALSE)
fwrite(FD, file.path(J, "figs", sprintf("gyr142-p38-fieldtag-anchor_DATA_%s.csv", DT)))
th <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
cl <- c(`FALSE` = "grey25", `TRUE` = "#b5452b")
ga <- ggplot(SV, aes(qc_afac, ratio, colour = cand)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = H1_LO, ymax = H1_HI, alpha = 0.15, fill = "#1b6ca8") +
  geom_errorbar(aes(ymin = ratio_lo, ymax = ratio_hi), width = 0.02) + geom_point(size = 1.8) + scale_colour_manual(values = cl, guide = "none") +
  labs(x = "QC_AFAC", y = "Predicted over observed\nannual height increment") + th
gb <- ggplot(SV, aes(qc_afac, topht, colour = cand)) + geom_hline(yintercept = abs(sb(TOPC)$topht_bias_pct), linetype = 2) + geom_point(size = 1.8) +
  scale_colour_manual(values = cl, guide = "none") + labs(x = "QC_AFAC", y = "TOPHT bias (%)") + th
gc <- ggplot(CB, aes(group, bias_m_yr, colour = armlab)) + geom_hline(yintercept = 0, linetype = 2, colour = "grey40") +
  geom_errorbar(aes(ymin = bias_lo, ymax = bias_hi), width = 0.2, position = position_dodge(width = 0.6)) + geom_point(size = 1.6, position = position_dodge(width = 0.6)) +
  scale_colour_manual(values = c("grey40", "#1b6ca8", "#6a8f3a", "#b5452b")) + labs(x = "t1 DBH class (cm)", y = expression("Height increment bias (m "*yr^{-1}*")"), colour = NULL) + th
gd <- ggplot(SV, aes(qc_afac, dom_level, colour = cand)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1 - (abs(GA[arm == REF]$dom_level - 1) + M_DOM), ymax = 1 + (abs(GA[arm == REF]$dom_level - 1) + M_DOM), alpha = 0.15, fill = "#1b6ca8") +
  geom_errorbar(aes(ymin = dom_lo, ymax = dom_hi), width = 0.02) + geom_point(size = 1.8) + scale_colour_manual(values = cl, guide = "none") +
  labs(x = "QC_AFAC", y = "Dominant cohort\npredicted over observed t2 height") + th
fig <- (ga + gb) / (gc + gd) + plot_annotation(tag_levels = "a")
ggsave(file.path(J, "figs", sprintf("gyr142-p38-fieldtag-anchor_%s.png", DT)), fig, width = 180, height = 150, units = "mm", dpi = 300)
cat("P38_ASSEMBLE_DONE\n")
