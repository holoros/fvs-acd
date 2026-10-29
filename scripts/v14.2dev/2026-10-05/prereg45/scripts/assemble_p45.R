## PREREG45 assembly (plan revision 1, md5 d032682d). Part 1, benchmark: PREREG38 assembly pass 2 formulas (assemble_p38.R,
## v142p38) on field tags, seed 20261001, B = 1000, with t1 relative height bins added; arms qc_rh (candidate), frozen qc141
## (p19_a0111, reference), p23_a1061 (TOPHT comparator), p19_a1000 and p38_fit (reported). Reproduction stops [F9]: field tag
## counts equal PREREG37 (698, 737); STS and the height table rows of the frozen arms equal the PREREG38 tables at 1e-9.
## H0 qc_rh0 against p19_a1000; K1. Part 2, long run: relations() parsed verbatim from v142p44 assemble_p44_r2.R (no edit),
## qc_rh against frozen PREREG44 qc141 (non inferiority, PREREG44 rule) and gate C (credibility bound from frontier_p45).
## Decision rule in the registered order. Refuses to overwrite. Aggregates only. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p45/scripts/2026-09-29_v142_p23_hkey.R")
suppressMessages({ library(ggplot2); library(patchwork) }); B <- 1000L
J <- "/home/aaron/jobs/v142p45"; P23 <- "/home/aaron/jobs/v142p23"; P38 <- "/home/aaron/jobs/v142p38"; P37 <- "/home/aaron/jobs/v142p37"; P44 <- "/home/aaron/jobs/v142p44"
FR_RUN <- FR; FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"; DT <- "2026-10-05"
O <- file.path(J, "assembled"); if (length(list.files(O))) stop("REFUSE ", O, " not empty"); dir.create(O, showWarnings = FALSE)
w_out <- function(x, n) { f <- file.path(O, sprintf("gyr142-p45-%s_%s", sub("^(.*)(\\.[a-z]+)$", "\\1", n), DT)); f <- paste0(f, sub("^.*(\\.[a-z]+)$", "\\1", n)); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f); f }
if (unname(tools::md5sum(file.path(J, "plan/2026-10-05_v142_qc-relht-increment_PREREG45.md"))) != "d032682db98c684d99435d808fd86d4e") stop("plan md5 differs")
## margins (as PREREG38)
L23 <- readLines(file.path(P23, "scripts/2026-09-29_v142_p23_assemble.R"))
ml <- grep("^CAND <- \"p23_a1061\"; REF <- \"p19_a0111\"; M_CLS <- [0-9.]+; M_DOM <- [0-9.]+$", L23, value = TRUE); if (length(ml) != 1) stop("PREREG23 margin line not found")
M_CLS <- as.numeric(sub(".*M_CLS <- ([0-9.]+);.*", "\\1", ml)); M_DOM <- as.numeric(sub(".*M_DOM <- ([0-9.]+)$", "\\1", ml))
M_B1 <- 1.0; M_B2 <- 2.0; M_V2 <- -0.5; H1_LO <- 0.90; H1_HI <- 1.10; M_ABS <- 0.04; MIN_BIN <- 30L; BOUND_C <- fread(file.path(J, "plan/frontier_p45_DATA.csv"))$bound
if (unname(tools::md5sum(file.path(J, "plan/frontier_p45_DATA.csv"))) != "63826d67b93754b48aa0947d6cf072a9") stop("frontier file md5 differs")
FF <- file.path(J, "fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv"); if (unname(tools::md5sum(FF)) != strsplit(readLines(file.path(J, "logs/fit_md5.txt")), " +")[[1]][1]) stop("fit md5 differs")
FIT <- fread(FF); fa <- FIT[param == "a"]$value_rounded; fb <- FIT[param == "b"]$value_rounded
cat(sprintf("margins M_CLS %.3f M_DOM %.3f; abs %.2f; bound C %.3f; fit a %.4f b %.4f\n", M_CLS, M_DOM, M_ABS, BOUND_C, fa, fb))
## arms
P19 <- "/home/aaron/jobs/v142p19"; CAND <- "qc_rh"; REF <- "p19_a0111"; TOPC <- "p23_a1061"
AR <- data.table(arm = c("p19_a0111", "p19_a1000", "p23_a1061", "p38_fit", "qc_rh"), qc_afac = c(0.111, 1.000, 1.061, 1.242, NA))
AR[, root := c(P19, P19, P23, P38, J)]; AR[, home := file.path(root, "home")]
AR[, stands := c(file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"), file.path(P38, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"), file.path(J, "tables/gyr142-p45-fb-stands_DATA_2026-09-27.csv"))]
res <- function(a, s) { x <- AR[arm == a]; fread(file.path(x$root, "results", a, sprintf("gyr_%s_%s_results.csv", a, s)))[, STAND := as.character(STAND)] }
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
rd <- function(h, arm, s) { acc <- NULL; for (d in arm_dirs(h, arm, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
chunk_res <- function(h, arm, s) { fs <- sort(list.files(file.path(h, "out", arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE)); if (!length(fs)) stop("no chunk results ", arm, " ", s)
  r <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]
  for (k in 1:3) { g <- list.files(file.path(h, sprintf("out_retry_a%d", k), arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE); if (!length(g)) next
    x <- rbindlist(lapply(g, fread), fill = TRUE)[, STAND := as.character(STAND)][STAND %in% r$STAND]; r <- rbind(r[!STAND %in% x$STAND], x, fill = TRUE) }
  if (anyDuplicated(r$STAND)) stop("duplicated STAND ", arm, " ", s); r }
## H0: qc_rh0 (a = b = 0) against frozen p19_a1000 (PREREG38 H0 code)
H0 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { a <- chunk_res(file.path(J, "home"), "qc_rh0", s); b <- res("p19_a1000", s)[STAND %in% a$STAND]
  if (!setequal(a$STAND, b$STAND)) stop("H0 stand sets differ ", s); setkey(a, STAND); setkey(b, STAND)
  cols <- c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK")
  per <- sapply(cols, function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; d }); per <- matrix(per, nrow = nrow(b))
  ta <- rd(file.path(J, "home"), "qc_rh0", s); tb <- rd(file.path(P19, "home"), "p19_a1000", s); tb <- tb[STAND %in% unique(ta$STAND)]
  m <- merge(ta, tb, by = c("STAND", "tree")); if (nrow(m) != nrow(ta) || nrow(m) != nrow(tb)) stop("H0 per tree rows differ ", s)
  m[, dd := pmax(abs(ht.x - ht.y) / pmax(1, abs(ht.y)), abs(dbh.x - dbh.y) / pmax(1, abs(dbh.y)), abs(expf.x - expf.y) / pmax(1, abs(expf.y)), abs(ing.x - ing.y))]
  wr <- max(per); wt <- max(m$dd); data.table(set = s, stands = nrow(b), trees = nrow(m), worst_results = wr, worst_trees = wt, pass = is.finite(wr) && is.finite(wt) && wr <= 1e-9 && wt <= 1e-9) }))
print(H0)
K1 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(CAND, s); data.table(arm = CAND, set = s, stands = nrow(r), not_ok = sum(r$RUN_OK != 1), timelimit_left = sum(grepl("elapsed time limit", r$FAIL_REASON))) }))
k1_pass <- sum(K1$not_ok) == 0; print(K1)
## stand level summaries (PREREG38 formulas)
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
S38 <- fread(file.path(P38, "assembled/gyr142-p38-stands-summary_DATA_2026-10-01.csv"))
cs <- merge(STS[arm != CAND], S38, by = c("set", "arm", "pop"), suffixes = c("", ".r"))
rs <- cs[, max(abs(C1_ratio - C1_ratio.r), abs(C1_rmse_pct - C1_rmse_pct.r), abs(ba_ratio - ba_ratio.r), abs(stems_ratio - stems_ratio.r), abs(topht_bias_pct - topht_bias_pct.r))]
cat(sprintf("RS: frozen stand summaries against PREREG38, worst %.3g over %d rows\n", rs, nrow(cs))); if (nrow(cs) < 24 || !is.finite(rs) || rs > 1e-9) stop("RS FROZEN STAND REPRO FAIL")
## height key, field tags, with t1 relative height
build_hk <- function(arms) { K0 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { S0 <- stand_frame(file.path(P19, sprintf("results/p19_a0111/gyr_p19_a0111_%s_results.csv", s)), s, CUTF)
  TK <- tag_key(s, S0$STAND); K <- merge(TK$K, S0[, .(STAND, SITE, cut, fold, esi8)], by = "STAND")
  for (a in arms) { p <- pred_ht(arm_dirs(AR[arm == a]$home, a, s), TK$M, S0$STAND)
    if (a == arms[1]) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
    K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", a)) }
  if (K[, anyNA(.SD), .SDcols = paste0("Hp_", arms)]) stop("tag record without prediction ", s)
  K[, set := s] }))
  K0[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
  K0[, rel := H1 / fifelse(is.finite(esi8) & esi8 > 2, esi8, 14)]
  K0[, relb := cut(rel, c(0, 0.5, 0.75, 1, 1.25, Inf), right = FALSE, labels = c("rel below 0.5", "rel 0.5 to 0.75", "rel 0.75 to 1", "rel 1 to 1.25", "rel 1.25 and over"))]
  K0[, dho := (H2 - H1) / iv]; for (a in arms) K0[, paste0("dp_", a) := (get(paste0("Hp_", a)) - H1) / iv]; K0 }
ht_tab <- function(HK, arms, seed, key) { set.seed(seed); HT <- list()
  for (s in c("qc_c", "qc_fl")) for (fd in c("A", "B")) { X <- HK[set == s & fold == fd & cut == FALSE]
    sites <- unique(X$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
    grp <- list(overall = X, `below 12.7` = X[cls == "below 12.7"], `12.7 to 25` = X[cls == "12.7 to 25"], `25 and over` = X[cls == "25 and over"], dominant = X[dom == TRUE])
    for (rb in levels(X$relb)) grp[[rb]] <- X[relb == rb]
    for (g in names(grp)) { Y <- grp[[g]]; if (!nrow(Y)) next
      SS <- Y[, c(list(n = .N, o = sum(dho), h2 = sum(H2)), lapply(setNames(arms, paste0("d_", arms)), function(a) sum(get(paste0("dp_", a)))),
                  lapply(setNames(arms, paste0("L_", arms)), function(a) sum(get(paste0("Hp_", a))))), by = SITE]
      w <- matrix(0, nrow(SS), B); m <- match(SS$SITE, sites); for (b in 1:B) w[, b] <- tabulate(IDX[, b], ns)[m]
      for (a in arms) { d <- SS[[paste0("d_", a)]]; L <- SS[[paste0("L_", a)]]
        rbt <- colSums(w * d) / colSums(w * SS$o); bb <- (colSums(w * d) - colSums(w * SS$o)) / colSums(w * SS$n); lb <- colSums(w * L) / colSums(w * SS$h2)
        HT[[paste(s, fd, g, a)]] <- data.table(tagkey = key, set = s, fold = fd, group = g, arm = a, qc_afac = AR[arm == a]$qc_afac, trees = sum(SS$n), sites = nrow(SS),
          obs_m_yr = sum(SS$o) / sum(SS$n), pred_m_yr = sum(d) / sum(SS$n), ratio = sum(d) / sum(SS$o), ratio_lo = quantile(rbt, .025, na.rm = TRUE), ratio_hi = quantile(rbt, .975, na.rm = TRUE),
          bias_m_yr = (sum(d) - sum(SS$o)) / sum(SS$n), bias_lo = quantile(bb, .025, na.rm = TRUE), bias_hi = quantile(bb, .975, na.rm = TRUE),
          level_t2 = sum(L) / sum(SS$h2), level_lo = quantile(lb, .025, na.rm = TRUE), level_hi = quantile(lb, .975, na.rm = TRUE)) } } }
  rbindlist(HT) }
FR <- FR_FIELD; HK <- build_hk(AR$arm); HT <- ht_tab(HK, AR$arm, 20261001, "field tag"); FR <- FR_RUN
n37 <- sapply(c("A", "B"), function(fd) fread(file.path(P37, sprintf("assembled/gyr142-p37-counts-fold%s_DATA_2026-10-01.csv", fd)))[tagkey == "field tag"]$records)
n45 <- sapply(c("A", "B"), function(fd) HT[set == "qc_c" & fold == fd & group == "overall" & arm == CAND]$trees)
cat(sprintf("R3: field tag records fold A %d (PREREG37 %d), fold B %d (PREREG37 %d)\n", n45[1], n37[1], n45[2], n37[2])); if (any(n37 != n45)) stop("R3 FIELD TAG COUNT FAIL")
H38 <- fread(file.path(P38, "assembled/gyr142-p38-hinc_DATA_2026-10-01.csv"))
ch <- merge(HT[arm != CAND], H38, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))
rh <- ch[, max(abs(ratio - ratio.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r), abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r))]
cat(sprintf("RH: frozen field tag height rows against PREREG38, worst %.3g over %d rows\n", rh, nrow(ch))); if (nrow(ch) < 60 || !is.finite(rh) || rh > 1e-9) stop("RH HEIGHT TABLE REPRO FAIL")
REPRO <- data.table(check = c("fit reproduction (fit_p45.R)", "R3 field tag counts A", "R3 field tag counts B", "RS frozen stand summaries = PREREG38", "RH frozen height rows = PREREG38"),
  rows = c(698, 1, 1, nrow(cs), nrow(ch)), worst = c(abs(FIT$R37_reproduced[1] - 1.2418873575799), abs(n45[1] - n37[1]), abs(n45[2] - n37[2]), rs, rh), pass = TRUE)
## gates, screened qc_c fold B
hb <- function(a, g) HT[set == "qc_c" & fold == "B" & group == g & arm == a]; sb <- function(a) STS[set == "qc_c" & pop == "screened B" & arm == a]
CLS <- c("below 12.7", "12.7 to 25", "25 and over"); RELB <- c("rel below 0.5", "rel 0.5 to 0.75", "rel 0.75 to 1", "rel 1 to 1.25")
gate_arm <- function(a) { c1 <- hb(a, "overall"); d0 <- hb(REF, "dominant"); d1 <- hb(a, "dominant"); s0 <- sb(REF); s1 <- sb(a); sT <- sb(TOPC)
  cl <- rbindlist(lapply(CLS, function(g) data.table(group = g, bias = hb(a, g)$bias_m_yr, worse_by = abs(hb(a, g)$bias_m_yr) - abs(hb(REF, g)$bias_m_yr))))
  rl <- rbindlist(lapply(RELB, function(g) { x <- hb(a, g); if (!nrow(x)) return(NULL); data.table(group = g, trees = x$trees, bias = x$bias_m_yr) }))
  rlg <- rl[trees >= MIN_BIN]
  data.table(arm = a, ratio = c1$ratio, ratio_lo = c1$ratio_lo, ratio_hi = c1$ratio_hi, trees = c1$trees, sites = c1$sites,
    bias_small = cl$bias[1], bias_mid = cl$bias[2], bias_large = cl$bias[3], worst_abs_class = max(abs(cl$bias)), worst_class_worse_by = max(cl$worse_by),
    rel_bins_gated = nrow(rlg), rel_bias = paste(sprintf("%s %+.3f (%d)", rl$group, rl$bias, rl$trees), collapse = "; "), worst_abs_rel = if (nrow(rlg)) max(abs(rlg$bias)) else NA_real_,
    topht = s1$topht_bias_pct, topht_limit = sT$topht_bias_pct, dom_level = d1$level_t2, dom_ref = d0$level_t2, rmse = s1$C1_rmse_pct, rmse_ref = s0$C1_rmse_pct,
    ba_pts = 100 * abs(s1$ba_ratio - 1), ba_ref_pts = 100 * abs(s0$ba_ratio - 1), stems_pts = 100 * abs(s1$stems_ratio - 1), stems_ref_pts = 100 * abs(s0$stems_ratio - 1),
    p_H1 = c1$ratio >= H1_LO && c1$ratio <= H1_HI, p_CLS = all(abs(cl$bias) <= M_ABS) && all(cl$worse_by <= M_CLS), p_REL = nrow(rlg) > 0 && all(abs(rlg$bias) <= M_ABS),
    p_TOP = abs(s1$topht_bias_pct) <= abs(sT$topht_bias_pct) && abs(d1$level_t2 - 1) <= abs(d0$level_t2 - 1) + M_DOM,
    p_V2 = s0$C1_rmse_pct - s1$C1_rmse_pct >= M_V2, p_B1 = 100 * (abs(s1$ba_ratio - 1) - abs(s0$ba_ratio - 1)) <= M_B1, p_B2 = 100 * (abs(s1$stems_ratio - 1) - abs(s0$stems_ratio - 1)) <= M_B2) }
GA <- rbindlist(lapply(AR$arm, gate_arm)); print(GA[, .(arm, ratio, bias_small, bias_mid, bias_large, worst_abs_rel, topht, dom_level, rmse, p_H1, p_CLS, p_REL, p_TOP, p_V2, p_B1, p_B2)], digits = 4)
g <- GA[arm == CAND]
## part 2: long run
L44 <- readLines(file.path(P44, "scripts/assemble_p44_r2.R")); i1 <- grep("^## ---------------- relations for one arm", L44); i2 <- grep("^## ---------------- harness gates", L44)
TH <- fread("/home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv"); th <- setNames(TH$value, TH$quantity); ESIB <- 1:4; SDIB <- 1:3
frontTPH <- function(q) 10^(th[["frontier_a"]] + th[["frontier_b"]] * log10(q)); eval(parse(text = L44[(i1 + 1):(i2 - 1)]))
SL <- fread(file.path(P44, "plan/stands_p44_SERVERONLY.csv"), colClasses = list(character = "STAND")); NST <- nrow(SL)
rt <- function(dir, ar) rbindlist(lapply(SDIB, function(s) fread(file.path(dir, sprintf("traj_%s_S%d.csv", ar, s)), colClasses = list(character = "STAND"))))
TR <- rbind(rt(file.path(P44, "out"), "qc141"), rt(file.path(P44, "out"), "p38_fit"), rt(file.path(J, "out"), "qc_rh"), fill = TRUE)
nt <- TR[arm == CAND, .(rows = .N, ok = all(run_ok == 1)), by = cell]; G1 <- nt[rows == 101 & ok, .N] == NST
ti <- fread(file.path(J, "home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_init.csv"), colClasses = list(character = "STAND"))[STAND %in% SL$STAND]
m0 <- ti[is.finite(DBH) & EXPF > 0, .(TPH_all_o = sum(EXPF), BA4_o = sum((EXPF * pi * (DBH/200)^2)[DBH >= 4])), by = STAND]
z0 <- merge(TR[arm == CAND & age == 0, .(STAND, TPH_all, BAPH)], m0, by = "STAND"); d0 <- max(abs(z0$TPH_all - z0$TPH_all_o)/pmax(1, z0$TPH_all_o), abs(z0$BAPH - z0$BA4_o)/pmax(1, z0$BA4_o))
G2 <- nrow(z0) == NST && d0 <= 1e-6
gr <- function(gg) { x <- fread(file.path(J, "logs", sprintf("%s_result.csv", gg))); isTRUE(x$pass) }
G0 <- gr("g0"); G0b <- gr("g0b")
REL <- rbindlist(lapply(c("qc141", "p38_fit", CAND), function(ar) { r <- relations(TR[arm == ar]); r[, arm := ar]; r })); setcolorder(REL, "arm")
R44 <- fread(file.path(P44, "assembled/gyr142-p44-relations_DATA_2026-10-05.csv"))
rr <- merge(REL[arm != CAND], R44, by = c("arm", "relation", "unit"), suffixes = c("", ".r")); rrw <- rr[, max(abs(fifelse(is.finite(margin), margin, 0) - fifelse(is.finite(margin.r), margin.r, 0)), sum(flag != flag.r))]
cat(sprintf("RL: frozen PREREG44 relations reproduced, worst %.3g over %d rows\n", rrw, nrow(rr))); if (nrow(rr) != nrow(R44) || rrw > 1e-9) stop("RL PREREG44 RELATIONS REPRO FAIL")
A <- merge(REL[arm == CAND], REL[arm == "qc141"], by = c("relation", "unit"), suffixes = c("", "_ref")); A[, newflag := flag & !flag_ref]
BB <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0, ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0), by = relation]
BB[, ni_ok := new_flags == 0 & (cand_flags == 0 | cand_worst <= ref_worst + 1e-9)]; NI_ok <- all(BB$ni_ok); print(BB)
C100 <- TR[age == 100, .(rel100 = HT / esi, HT100 = HT), by = .(arm, cell)]; C0 <- TR[age == 0, .(rel0 = HT / esi), by = .(arm, cell)]
CS <- merge(C100, C0, by = c("arm", "cell"))[, .(stands = .N, median_rel0 = median(rel0), median_rel100 = median(rel100), max_rel100 = max(rel100), n_over = sum(rel100 > BOUND_C),
  share_over = mean(rel100 > BOUND_C), median_HT100 = median(HT100), mean_HT100 = mean(HT100)), by = arm]
CS[, pass_C := median_rel100 <= BOUND_C & share_over <= 0.10]; print(CS); pC <- CS[arm == CAND]$pass_C
## decision
harness <- all(H0$pass) && k1_pass && G0 && G0b && G1 && G2
outcome <- if (!harness) "RULE1_HARNESS_FAILURE" else if (!(g$p_H1 && g$p_CLS && g$p_REL)) "RULE2_NOT_ADOPTED_HEIGHT" else if (!(g$p_TOP && g$p_V2 && g$p_B1 && g$p_B2)) "RULE3_NOT_ADOPTED_TRADEOFF" else
  if (!(pC && NI_ok)) "RULE4_NOT_CLEARED_LONGRUN" else "RULE5_CANDIDATE"
fails <- c(if (!all(H0$pass)) "H0", if (!k1_pass) "K1", if (!G0) "G0", if (!G0b) "G0b", if (!G1) "G1", if (!G2) "G2", if (!g$p_H1) "H1 level", if (!g$p_CLS) "H classes", if (!g$p_REL) "H relht",
  if (!g$p_TOP) "TOPHT", if (!g$p_V2) "V2", if (!g$p_B1) "B1", if (!g$p_B2) "B2", if (!pC) "C bound", if (!NI_ok) paste("NI", paste(BB[ni_ok == FALSE]$relation, collapse = ",")))
GATES <- data.table(gate = c("H0", "K1", "G0", "G0b", "G1", "G2", "H1 level", "H classes", "H relht", "TOPHT", "V2", "B1", "B2", "C bound", "NI long run"),
  detail = c(sprintf("qc_rh0 vs p19_a1000: worst results %.2e, trees %.2e", max(H0$worst_results), max(H0$worst_trees)), sprintf("not ok %d", sum(K1$not_ok)), "driver_p45 g0 vs frozen p19_a0111", "driver_p45 grid vs PREREG31 dry",
    sprintf("%d of %d trajectories with 101 rows", nt[rows == 101 & ok, .N], NST), sprintf("worst %.3g over %d", d0, nrow(z0)),
    sprintf("ratio %.3f [%.3f, %.3f]; qc141 %.3f; p38_fit %.3f", g$ratio, g$ratio_lo, g$ratio_hi, GA[arm == REF]$ratio, GA[arm == "p38_fit"]$ratio),
    sprintf("bias %+.3f, %+.3f, %+.3f m/yr; worst worse than qc141 by %+.3f", g$bias_small, g$bias_mid, g$bias_large, g$worst_class_worse_by), g$rel_bias,
    sprintf("TOPHT %+.2f%% vs limit %+.2f%%; dominant %.3f vs qc141 %.3f", g$topht, g$topht_limit, g$dom_level, g$dom_ref), sprintf("%%RMSE %.2f vs %.2f", g$rmse, g$rmse_ref),
    sprintf("%.2f vs %.2f pts", g$ba_pts, g$ba_ref_pts), sprintf("%.2f vs %.2f pts", g$stems_pts, g$stems_ref_pts),
    sprintf("median rel100 %.3f, %d of %d over %.3f", CS[arm == CAND]$median_rel100, CS[arm == CAND]$n_over, CS[arm == CAND]$stands, BOUND_C), sprintf("new flags %d; failing %s", sum(A$newflag), paste(BB[ni_ok == FALSE]$relation, collapse = ","))),
  pass = c(all(H0$pass), k1_pass, G0, G0b, G1, G2, g$p_H1, g$p_CLS, g$p_REL, g$p_TOP, g$p_V2, g$p_B1, g$p_B2, pC, NI_ok))
print(GATES)
files <- c(w_out(GATES, "gates_DATA.csv"), w_out(GA, "gates-all_DATA.csv"), w_out(HT, "hinc_DATA.csv"), w_out(STS, "stands-summary_DATA.csv"), w_out(H0, "H0_DATA.csv"), w_out(K1, "K1_DATA.csv"),
  w_out(REPRO, "repro_DATA.csv"), w_out(REL, "relations_DATA.csv"), w_out(BB, "ni-by-relation_DATA.csv"), w_out(CS, "credibility_DATA.csv"),
  w_out(TR[age %% 5 == 0][, STAND := NULL], "traj-5yr_DATA.csv"))
V <- c("plan_md5=d032682d", sprintf("fit a=%.4f b=%.4f", fa, fb), paste0("outcome=", outcome), paste0("failing=", paste(fails, collapse = ";")), "decision_weight=informs 14.3 only; 14.2 keeps QC_AFAC 0.111")
vf <- file.path(O, sprintf("gyr142-p45-verdict_DATA_%s.txt", DT)); writeLines(V, vf); cat(V, sep = "\n")
## figure: (a) relht bin bias, fold B; (b) DBH class bias; (c) top height over ESI to 100 years, three arms
FB <- HT[set == "qc_c" & fold == "B" & group %in% c(RELB, CLS) & arm %in% c(REF, "p38_fit", CAND)]
FB[, armlab := factor(c(p19_a0111 = "qc141 (0.111)", p38_fit = "p38_fit (1.242)", qc_rh = "qc_rh, m(r)")[arm], levels = c("qc141 (0.111)", "p38_fit (1.242)", "qc_rh, m(r)"))]
FB[, panel := fifelse(group %in% RELB, "rel", "cls")]; FB[, grp := factor(sub("^rel ", "", group), levels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", CLS))]
TT <- TR[age %% 5 == 0, .(rel = mean(HT / esi), lo = quantile(HT / esi, .1), hi = quantile(HT / esi, .9)), by = .(arm, age)]
TT[, armlab := factor(c(qc141 = "qc141 (0.111)", p38_fit = "p38_fit (1.242)", qc_rh = "qc_rh, m(r)")[arm], levels = levels(FB$armlab))]
fwrite(FB, file.path(J, "figs", sprintf("gyr142-p45-relht_DATA_%s.csv", DT))); fwrite(TT, file.path(J, "figs", sprintf("gyr142-p45-topht100_DATA_%s.csv", DT)))
cols <- c("grey40", "#1b6ca8", "#b5452b"); th0 <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
pa <- ggplot(FB[panel == "rel"], aes(grp, bias_m_yr, colour = armlab)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -M_ABS, ymax = M_ABS, alpha = .12, fill = "#1b6ca8") + geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(ymin = bias_lo, ymax = bias_hi), width = .2, position = position_dodge(.6)) + geom_point(size = 1.6, position = position_dodge(.6)) + scale_colour_manual(values = cols) +
  labs(x = "t1 height over ESI", y = expression("Height increment bias (m "*yr^{-1}*")"), colour = NULL) + th0
pb <- pa %+% FB[panel == "cls"] + labs(x = "t1 DBH class (cm)")
pc <- ggplot(TT, aes(age, rel, colour = armlab, fill = armlab)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .12, colour = NA) + geom_line() + geom_hline(yintercept = BOUND_C, linetype = 2) +
  scale_colour_manual(values = cols) + scale_fill_manual(values = cols) + labs(x = "Years projected", y = "Top height over ESI", colour = NULL, fill = NULL) + th0
fig <- (pa + pb) / pc + plot_layout(guides = "collect") + plot_annotation(tag_levels = "a") & theme(legend.position = "bottom")
ggsave(file.path(J, "figs", sprintf("gyr142-p45-relht-longrun_%s.png", DT)), fig, width = 180, height = 160, units = "mm", dpi = 300)
cat("P45_ASSEMBLE_DONE\n")
