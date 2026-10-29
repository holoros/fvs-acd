## PREREG46 assembly (plan revision 1, md5 eb4b753d). Adapted from assemble_p45.R (v142p45, md5 61be8d08; PREREG45 assembly,
## one arm qc_rh). Structure, helpers and conventions are the template's; every change is marked "PREREG46". Changes:
##  1. Job root v142p46, date 2026-10-11, output prefix gyr142-p46, plan md5 eb4b753d; hkey sourced from the build_p46.sh copy.
##  2. Two candidate arms, qc_lz and qc_ez, each gated and decided separately (CANDS); frozen qc_rh (v142p45) added to the
##     benchmark and long run arms as a reported column beside qc141 and p38_fit; its stand summaries, height rows and
##     relations are reproduced against the PREREG45 assembled tables at 1e-9 [F9].
##  3. Fit stop conditions per arm from fit_p46.R output: fit file present (md5 equal logs/fit_md5.txt), Newton converged,
##     b negative, boot_nonconverged at most 50 (5 percent of B = 1000).
##  4. H0 per arm: qc_lz0 and qc_ez0 (m = 1) against frozen p19_a1000, PREREG45 H0 code. K1, G1, G2 per arm.
##  5. New harness gates G0x (logs/g0x_result.csv) and TR (logs/tr_result_qc_lz.csv, logs/tr_result_qc_ez.csv).
##  6. New benchmark gates H relbin (pooled pred over obs ratio in each HT/ESI bin of 30 or more trees within 0.80 to 1.25)
##     and H upper (site cluster bootstrap 95% interval of that ratio, upper at most 1.50 and lower at least 0.67, every bin of
##     30 or more trees); the interval is ht_tab's ratio_lo, ratio_hi (PREREG37/45 seed 20261001 and weights, unchanged).
##  7. Reported, not gated: engine fold A pooled ratio (screened qc_c fold A, field tags) per arm.
##  8. Gate C in two parts: (1) offset removed per st2_offset.R (md5 567fa63d): per cell offset = qc141 HT(1) - HT(0) minus
##     (qc141 HT(100) - HT(1)) / 99, subtracted from HT at 100; median HT/ESI at or below 1.175 and at most 3 of 36 over;
##     (2) raw median HT/ESI at 100 at or below 1.285. Reported: raw gate C as PREREG45, top height at 100, gain years 80 to
##     100 (mean, median), first year the median HT/ESI exceeds 1.175. Offset reproduced against the ST2 table [F9].
##  9. Decision rule per arm in the registered order (rules 1 to 5) and the tie rule (smaller worst absolute per bin bias on
##     fold B, rounded to three decimals; equal goes to qc_lz).
## 10. Outputs: the template's set with an arm column where needed, plus fit-stops and harness tables; every writer refuses an
##     existing file and refuses a stand, site or tree identifier column; verdict text per arm; figure with five arms.
## Refuses to overwrite. Aggregates only. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p46/scripts/2026-09-29_v142_p23_hkey.R")  # PREREG46: build_p46.sh copy of the PREREG45 hkey
suppressMessages({ library(ggplot2); library(patchwork) }); B <- 1000L
J <- "/home/aaron/jobs/v142p46"; P23 <- "/home/aaron/jobs/v142p23"; P38 <- "/home/aaron/jobs/v142p38"; P37 <- "/home/aaron/jobs/v142p37"; P44 <- "/home/aaron/jobs/v142p44"
P45 <- "/home/aaron/jobs/v142p45"; P45ST <- "/home/aaron/jobs/v142p45st"  # PREREG46: frozen qc_rh run and ST2 stress folder, read only
FR_RUN <- FR; FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"; DT <- "2026-10-11"  # PREREG46: date
O <- file.path(J, "assembled"); if (length(list.files(O))) stop("REFUSE ", O, " not empty"); dir.create(O, showWarnings = FALSE)
## PREREG46: prefix gyr142-p46; also refuses any identifier column (aggregates only)
w_out <- function(x, n) { if (any(tolower(names(x)) %in% c("stand", "site", "tree", "plot", "lat", "lon", "latitude", "longitude"))) stop("REFUSE identifier column in ", n)
  f <- file.path(O, sprintf("gyr142-p46-%s_%s", sub("^(.*)(\\.[a-z]+)$", "\\1", n), DT)); f <- paste0(f, sub("^.*(\\.[a-z]+)$", "\\1", n)); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f); f }
if (unname(tools::md5sum(file.path(J, "plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md"))) != "eb4b753d5ff58f8246cf89e8e2fc5c96") stop("plan md5 differs")  # PREREG46
## margins (as PREREG38)
L23 <- readLines(file.path(P23, "scripts/2026-09-29_v142_p23_assemble.R"))
ml <- grep("^CAND <- \"p23_a1061\"; REF <- \"p19_a0111\"; M_CLS <- [0-9.]+; M_DOM <- [0-9.]+$", L23, value = TRUE); if (length(ml) != 1) stop("PREREG23 margin line not found")
M_CLS <- as.numeric(sub(".*M_CLS <- ([0-9.]+);.*", "\\1", ml)); M_DOM <- as.numeric(sub(".*M_DOM <- ([0-9.]+)$", "\\1", ml))
M_B1 <- 1.0; M_B2 <- 2.0; M_V2 <- -0.5; H1_LO <- 0.90; H1_HI <- 1.10; M_ABS <- 0.04; MIN_BIN <- 30L
## PREREG46: frontier file is read from the PREREG45 plan folder (same md5); bound C (q99) and the raw ceiling (maximum, 1.285)
FRT <- fread(file.path(P45, "plan/frontier_p45_DATA.csv")); BOUND_C <- FRT$bound
if (unname(tools::md5sum(file.path(P45, "plan/frontier_p45_DATA.csv"))) != "63826d67b93754b48aa0947d6cf072a9") stop("frontier file md5 differs")
RAW_C <- 1.285; if (abs(FRT$max - RAW_C) > 5e-4) stop("PREREG46: frontier maximum is not 1.285 to three decimals")  # PREREG46
REL_LO <- 0.80; REL_HI <- 1.25; UP_HI <- 1.50; UP_LO <- 0.67; NOVER_C <- 3L; BOOT_NC_MAX <- 50L  # PREREG46: H relbin, H upper, gate C part 1, fit stop
## PREREG46: st2_offset.R is the registered definition of the gate C offset; its md5 is checked, the formula is restated below
if (!isTRUE(unname(tools::md5sum(file.path(P45ST, "scripts/st2_offset.R"))) == "567fa63daecf9bac5a6922d3c0be7ef8")) stop("PREREG46: st2_offset.R absent or md5 differs under ", P45ST)
## PREREG46: fit file of fit_p46.R (both forms); fit stop conditions per arm (rule 1)
CANDS <- c("qc_lz", "qc_ez"); H0ARM <- c(qc_lz = "qc_lz0", qc_ez = "qc_ez0")
FF <- file.path(J, "fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv")
if (!file.exists(FF)) { vf <- file.path(O, sprintf("gyr142-p46-verdict_DATA_%s.txt", DT)); if (file.exists(vf)) stop("REFUSE ", vf)
  writeLines(c("plan_md5=eb4b753d", paste0("outcome_", CANDS, "=RULE1_HARNESS_FAILURE"), paste0("failing_", CANDS, "=fit stop (fit file absent)"), "candidate=none", "decision_weight=informs 14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579"), vf)
  stop("FIT STOP: fit file absent ", FF) }
if (unname(tools::md5sum(FF)) != strsplit(readLines(file.path(J, "logs/fit_md5.txt")), " +")[[1]][1]) stop("fit md5 differs")
FIT <- fread(FF)
FS <- rbindlist(lapply(CANDS, function(ca) { x <- FIT[arm == ca]; one <- function(v) if (length(v) == 1) as.numeric(v) else NA_real_
  data.table(arm = ca, a_r = one(x[param == "a"]$value_rounded), b_r = one(x[param == "b"]$value_rounded), b_unrounded = one(x[param == "b"]$value),
    a_lo = one(x[param == "a"]$lo), a_hi = one(x[param == "a"]$hi), b_lo = one(x[param == "b"]$lo), b_hi = one(x[param == "b"]$hi), zero_r = x$zero_r[1],
    newton_iter = x$newton_iter[1], boot_nonconverged = x$boot_nonconverged[1], m_r0.25 = x$m_at_r0.25[1], m_r0.625 = x$m_at_r0.625[1],
    m_r0.875 = x$m_at_r0.875[1], m_r1.125 = x$m_at_r1.125[1], tags_r1_at_or_above_zero = x$tags_r1_at_or_above_zero[1]) }))
FS[, fit_ok := is.finite(a_r) & is.finite(b_r) & is.finite(newton_iter) & is.finite(b_unrounded) & b_r < 0 & b_unrounded < 0 & is.finite(boot_nonconverged) & boot_nonconverged <= BOOT_NC_MAX]
cat(sprintf("margins M_CLS %.3f M_DOM %.3f; abs %.2f; bound C %.3f; raw ceiling %.3f\n", M_CLS, M_DOM, M_ABS, BOUND_C, RAW_C))
for (i in seq_len(nrow(FS))) cat(sprintf("fit %s a %.4f b %.4f zero %.4f nonconverged %s fit_ok %s\n", FS$arm[i], FS$a_r[i], FS$b_r[i], FS$zero_r[i], FS$boot_nonconverged[i], FS$fit_ok[i]))
## arms (PREREG46: frozen qc_rh from v142p45 and the two candidates from v142p46)
P19 <- "/home/aaron/jobs/v142p19"; REF <- "p19_a0111"; TOPC <- "p23_a1061"
ST46 <- list.files(file.path(J, "tables"), "^gyr142-p46-fb-stands_DATA_[0-9-]+\\.csv$", full.names = TRUE)  # PREREG46: scoring stands table, VC_TAG p46-fb
if (length(ST46) != 1) stop("PREREG46: expected one tables/gyr142-p46-fb-stands_DATA_*.csv, found ", length(ST46))
AR <- data.table(arm = c("p19_a0111", "p19_a1000", "p23_a1061", "p38_fit", "qc_rh", CANDS), qc_afac = c(0.111, 1.000, 1.061, 1.242, NA, NA, NA))
AR[, root := c(P19, P19, P23, P38, P45, J, J)]; AR[, home := file.path(root, "home")]
AR[, stands := c(file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"), file.path(P38, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"), file.path(P45, "tables/gyr142-p45-fb-stands_DATA_2026-09-27.csv"), ST46, ST46)]
res <- function(a, s) { x <- AR[arm == a]; fread(file.path(x$root, "results", a, sprintf("gyr_%s_%s_results.csv", a, s)))[, STAND := as.character(STAND)] }
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
rd <- function(h, arm, s) { acc <- NULL; for (d in arm_dirs(h, arm, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
chunk_res <- function(h, arm, s) { fs <- sort(list.files(file.path(h, "out", arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE)); if (!length(fs)) stop("no chunk results ", arm, " ", s)
  r <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]
  for (k in 1:3) { g <- list.files(file.path(h, sprintf("out_retry_a%d", k), arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE); if (!length(g)) next
    x <- rbindlist(lapply(g, fread), fill = TRUE)[, STAND := as.character(STAND)][STAND %in% r$STAND]; r <- rbind(r[!STAND %in% x$STAND], x, fill = TRUE) }
  if (anyDuplicated(r$STAND)) stop("duplicated STAND ", arm, " ", s); r }
## H0: qc_lz0 and qc_ez0 (m = 1) against frozen p19_a1000 (PREREG38 H0 code). PREREG46: one block per H0 arm
H0 <- rbindlist(lapply(unname(H0ARM), function(a0) rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { a <- chunk_res(file.path(J, "home"), a0, s); b <- res("p19_a1000", s)[STAND %in% a$STAND]
  if (!setequal(a$STAND, b$STAND)) stop("H0 stand sets differ ", a0, " ", s); setkey(a, STAND); setkey(b, STAND)
  cols <- c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK")
  per <- sapply(cols, function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; d }); per <- matrix(per, nrow = nrow(b))
  ta <- rd(file.path(J, "home"), a0, s); tb <- rd(file.path(P19, "home"), "p19_a1000", s); tb <- tb[STAND %in% unique(ta$STAND)]
  m <- merge(ta, tb, by = c("STAND", "tree")); if (nrow(m) != nrow(ta) || nrow(m) != nrow(tb)) stop("H0 per tree rows differ ", a0, " ", s)
  m[, dd := pmax(abs(ht.x - ht.y) / pmax(1, abs(ht.y)), abs(dbh.x - dbh.y) / pmax(1, abs(dbh.y)), abs(expf.x - expf.y) / pmax(1, abs(expf.y)), abs(ing.x - ing.y))]
  wr <- max(per); wt <- max(m$dd); data.table(arm = a0, set = s, stands = nrow(b), trees = nrow(m), worst_results = wr, worst_trees = wt, pass = is.finite(wr) && is.finite(wt) && wr <= 1e-9 && wt <= 1e-9) }))))
print(H0)
## K1, PREREG46: per candidate arm
K1 <- rbindlist(lapply(CANDS, function(ca) rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(ca, s); data.table(arm = ca, set = s, stands = nrow(r), not_ok = sum(r$RUN_OK != 1), timelimit_left = sum(grepl("elapsed time limit", r$FAIL_REASON))) }))))
k1_pass <- K1[, .(pass = sum(not_ok) == 0), by = arm]; print(K1)
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
cs <- merge(STS[!arm %in% c(CANDS, "qc_rh")], S38, by = c("set", "arm", "pop"), suffixes = c("", ".r"))  # PREREG46: frozen PREREG38 arms only
rs <- cs[, max(abs(C1_ratio - C1_ratio.r), abs(C1_rmse_pct - C1_rmse_pct.r), abs(ba_ratio - ba_ratio.r), abs(stems_ratio - stems_ratio.r), abs(topht_bias_pct - topht_bias_pct.r))]
cat(sprintf("RS: frozen stand summaries against PREREG38, worst %.3g over %d rows\n", rs, nrow(cs))); if (nrow(cs) < 24 || !is.finite(rs) || rs > 1e-9) stop("RS FROZEN STAND REPRO FAIL")
## PREREG46: frozen qc_rh stand summaries against the PREREG45 assembled table [F9]
S45 <- fread(file.path(P45, "assembled/gyr142-p45-stands-summary_DATA_2026-10-05.csv"))
cq <- merge(STS[arm == "qc_rh"], S45[arm == "qc_rh"], by = c("set", "arm", "pop"), suffixes = c("", ".r"))
rsq <- cq[, max(abs(C1_ratio - C1_ratio.r), abs(C1_rmse_pct - C1_rmse_pct.r), abs(ba_ratio - ba_ratio.r), abs(stems_ratio - stems_ratio.r), abs(topht_bias_pct - topht_bias_pct.r))]
cat(sprintf("RSQ: frozen qc_rh stand summaries against PREREG45, worst %.3g over %d rows\n", rsq, nrow(cq))); if (nrow(cq) != 8 || !is.finite(rsq) || rsq > 1e-9) warning("RSQ QC_RH STAND REPRO FAIL (reported; qc_rh not gated)")
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
## ht_tab unchanged: ratio_lo and ratio_hi are the site cluster bootstrap interval used by PREREG46 H upper
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
n46 <- sapply(c("A", "B"), function(fd) HT[set == "qc_c" & fold == fd & group == "overall" & arm == CANDS[1]]$trees)  # PREREG46
cat(sprintf("R3: field tag records fold A %d (PREREG37 %d), fold B %d (PREREG37 %d)\n", n46[1], n37[1], n46[2], n37[2])); if (any(n37 != n46)) stop("R3 FIELD TAG COUNT FAIL")
H38 <- fread(file.path(P38, "assembled/gyr142-p38-hinc_DATA_2026-10-01.csv"))
ch <- merge(HT[!arm %in% c(CANDS, "qc_rh")], H38, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))  # PREREG46: frozen PREREG38 arms only
rh <- ch[, max(abs(ratio - ratio.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r), abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r))]
cat(sprintf("RH: frozen field tag height rows against PREREG38, worst %.3g over %d rows\n", rh, nrow(ch))); if (nrow(ch) < 60 || !is.finite(rh) || rh > 1e-9) stop("RH HEIGHT TABLE REPRO FAIL")
## PREREG46: frozen qc_rh height rows (ratio interval included) against the PREREG45 assembled hinc table [F9]
H45 <- fread(file.path(P45, "assembled/gyr142-p45-hinc_DATA_2026-10-05.csv"))[arm == "qc_rh"]
chq <- merge(HT[arm == "qc_rh"], H45, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))
rhq <- chq[, max(abs(ratio - ratio.r), abs(ratio_lo - ratio_lo.r), abs(ratio_hi - ratio_hi.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r), abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r))]
cat(sprintf("RHQ: frozen qc_rh height rows against PREREG45, worst %.3g over %d rows\n", rhq, nrow(chq))); if (nrow(chq) != nrow(H45) || nrow(chq) < 20 || !is.finite(rhq) || rhq > 1e-9) warning("RHQ QC_RH HEIGHT REPRO FAIL (reported)")
## gates, screened qc_c fold B
hb <- function(a, g) HT[set == "qc_c" & fold == "B" & group == g & arm == a]; sb <- function(a) STS[set == "qc_c" & pop == "screened B" & arm == a]
CLS <- c("below 12.7", "12.7 to 25", "25 and over"); RELB <- c("rel below 0.5", "rel 0.5 to 0.75", "rel 0.75 to 1", "rel 1 to 1.25")
gate_arm <- function(a) { c1 <- hb(a, "overall"); d0 <- hb(REF, "dominant"); d1 <- hb(a, "dominant"); s0 <- sb(REF); s1 <- sb(a); sT <- sb(TOPC)
  fA <- HT[set == "qc_c" & fold == "A" & group == "overall" & arm == a]  # PREREG46: engine fold A pooled ratio, reported
  cl <- rbindlist(lapply(CLS, function(g) data.table(group = g, bias = hb(a, g)$bias_m_yr, worse_by = abs(hb(a, g)$bias_m_yr) - abs(hb(REF, g)$bias_m_yr))))
  rl <- rbindlist(lapply(RELB, function(g) { x <- hb(a, g); if (!nrow(x)) return(NULL); data.table(group = g, trees = x$trees, bias = x$bias_m_yr, ratio = x$ratio, ratio_lo = x$ratio_lo, ratio_hi = x$ratio_hi) }))  # PREREG46: ratio and interval
  rlg <- rl[trees >= MIN_BIN]
  data.table(arm = a, ratio = c1$ratio, ratio_lo = c1$ratio_lo, ratio_hi = c1$ratio_hi, trees = c1$trees, sites = c1$sites, foldA_ratio = fA$ratio, foldA_trees = fA$trees,
    bias_small = cl$bias[1], bias_mid = cl$bias[2], bias_large = cl$bias[3], worst_abs_class = max(abs(cl$bias)), worst_class_worse_by = max(cl$worse_by),
    rel_bins_gated = nrow(rlg), rel_bias = paste(sprintf("%s %+.3f (%d)", rl$group, rl$bias, rl$trees), collapse = "; "), worst_abs_rel = if (nrow(rlg)) max(abs(rlg$bias)) else NA_real_,
    rel_ratio = paste(sprintf("%s %.3f [%.3f, %.3f] (%d)", rl$group, rl$ratio, rl$ratio_lo, rl$ratio_hi, rl$trees), collapse = "; "),
    rel_ratio_min = if (nrow(rlg)) min(rlg$ratio) else NA_real_, rel_ratio_max = if (nrow(rlg)) max(rlg$ratio) else NA_real_,
    rel_lo_min = if (nrow(rlg)) min(rlg$ratio_lo) else NA_real_, rel_hi_max = if (nrow(rlg)) max(rlg$ratio_hi) else NA_real_,
    topht = s1$topht_bias_pct, topht_limit = sT$topht_bias_pct, dom_level = d1$level_t2, dom_ref = d0$level_t2, rmse = s1$C1_rmse_pct, rmse_ref = s0$C1_rmse_pct,
    ba_pts = 100 * abs(s1$ba_ratio - 1), ba_ref_pts = 100 * abs(s0$ba_ratio - 1), stems_pts = 100 * abs(s1$stems_ratio - 1), stems_ref_pts = 100 * abs(s0$stems_ratio - 1),
    p_H1 = c1$ratio >= H1_LO && c1$ratio <= H1_HI, p_CLS = all(abs(cl$bias) <= M_ABS) && all(cl$worse_by <= M_CLS), p_REL = nrow(rlg) > 0 && all(abs(rlg$bias) <= M_ABS),
    p_RELBIN = nrow(rlg) > 0 && isTRUE(all(rlg$ratio >= REL_LO & rlg$ratio <= REL_HI)),  # PREREG46: H relbin
    p_UPPER = nrow(rlg) > 0 && isTRUE(all(rlg$ratio_hi <= UP_HI & rlg$ratio_lo >= UP_LO)),  # PREREG46: H upper
    p_TOP = abs(s1$topht_bias_pct) <= abs(sT$topht_bias_pct) && abs(d1$level_t2 - 1) <= abs(d0$level_t2 - 1) + M_DOM,
    p_V2 = s0$C1_rmse_pct - s1$C1_rmse_pct >= M_V2, p_B1 = 100 * (abs(s1$ba_ratio - 1) - abs(s0$ba_ratio - 1)) <= M_B1, p_B2 = 100 * (abs(s1$stems_ratio - 1) - abs(s0$stems_ratio - 1)) <= M_B2) }
GA <- rbindlist(lapply(AR$arm, gate_arm)); print(GA[, .(arm, ratio, foldA_ratio, bias_small, bias_mid, bias_large, worst_abs_rel, rel_ratio_max, rel_hi_max, rel_lo_min, topht, dom_level, rmse, p_H1, p_CLS, p_REL, p_RELBIN, p_UPPER, p_TOP, p_V2, p_B1, p_B2)], digits = 4)
## part 2: long run
L44 <- readLines(file.path(P44, "scripts/assemble_p44_r2.R")); i1 <- grep("^## ---------------- relations for one arm", L44); i2 <- grep("^## ---------------- harness gates", L44)
TH <- fread("/home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv"); th <- setNames(TH$value, TH$quantity); ESIB <- 1:4; SDIB <- 1:3
frontTPH <- function(q) 10^(th[["frontier_a"]] + th[["frontier_b"]] * log10(q)); eval(parse(text = L44[(i1 + 1):(i2 - 1)]))
SL <- fread(file.path(P44, "plan/stands_p44_SERVERONLY.csv"), colClasses = list(character = "STAND")); NST <- nrow(SL)
rt <- function(dir, ar) rbindlist(lapply(SDIB, function(s) fread(file.path(dir, sprintf("traj_%s_S%d.csv", ar, s)), colClasses = list(character = "STAND"))))
## PREREG46: frozen qc141 and p38_fit (PREREG44) and qc_rh (PREREG45); qc_lz and qc_ez from v142p46/out
TR <- rbind(rt(file.path(P44, "out"), "qc141"), rt(file.path(P44, "out"), "p38_fit"), rt(file.path(P45, "out"), "qc_rh"), rt(file.path(J, "out"), "qc_lz"), rt(file.path(J, "out"), "qc_ez"), fill = TRUE)
ti <- fread(file.path(J, "home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_init.csv"), colClasses = list(character = "STAND"))[STAND %in% SL$STAND]
m0 <- ti[is.finite(DBH) & EXPF > 0, .(TPH_all_o = sum(EXPF), BA4_o = sum((EXPF * pi * (DBH/200)^2)[DBH >= 4])), by = STAND]
## G1, G2, PREREG46: per candidate arm
G12 <- rbindlist(lapply(CANDS, function(ca) { nt <- TR[arm == ca, .(rows = .N, ok = all(run_ok == 1)), by = cell]
  z0 <- merge(TR[arm == ca & age == 0, .(STAND, TPH_all, BAPH)], m0, by = "STAND")
  d0 <- if (nrow(z0)) max(abs(z0$TPH_all - z0$TPH_all_o)/pmax(1, z0$TPH_all_o), abs(z0$BAPH - z0$BA4_o)/pmax(1, z0$BA4_o)) else Inf
  data.table(arm = ca, traj_101 = nt[rows == 101 & ok, .N], stands = NST, G1 = nt[rows == 101 & ok, .N] == NST, g2_rows = nrow(z0), g2_worst = d0, G2 = nrow(z0) == NST && d0 <= 1e-6) }))
print(G12)
## PREREG46: harness result files (G0, G0b, G0x shared; TR per arm), named by file stem
gr <- function(gg) { x <- fread(file.path(J, "logs", sprintf("%s.csv", gg))); nrow(x) >= 1 && "pass" %in% names(x) && isTRUE(all(as.logical(x$pass))) }  # PREREG46: an empty or pass-less result file fails
G0 <- gr("g0_result"); G0b <- gr("g0b_result"); G0x <- gr("g0x_result")
TRP <- setNames(sapply(CANDS, function(ca) gr(sprintf("tr_result_%s", ca))), CANDS)
TRG <- rbindlist(lapply(CANDS, function(ca) fread(file.path(J, "logs", sprintf("tr_result_%s.csv", ca)))), fill = TRUE)
GX <- fread(file.path(J, "logs/g0x_result.csv"))
HARN <- rbind(data.table(arm = "all", gate = c("G0", "G0b", "G0x"), detail = c("driver_p46 g0 vs frozen p19_a0111", "driver_p46 grid vs PREREG31 dry",
  sprintf("driver_p46 qc_rh form exp vs PREREG45 traj_qc_rh_S1: worst %.2e, rows %d of %d", GX$worst_scaled[1], GX$rows[1], GX$rows_ref[1])), pass = c(G0, G0b, G0x)),
  rbindlist(lapply(CANDS, function(ca) { t1 <- TRG[arm == ca]; data.table(arm = ca, gate = "TR", detail = sprintf("worst %.2e over %d rows, %d calls; ingrowth %d, m 1 unexpected %d; at or above zero %d, m not 0 %d",
    t1$worst_abs_diff[1], t1$rows[1], t1$calls[1], t1$ingrowth_rows[1], t1$ingrowth_m1_not_expected[1], t1$rows_at_or_above_zero[1], t1$rows_at_or_above_zero_m_not0[1]), pass = TRP[[ca]]) })))
print(HARN)
REL <- rbindlist(lapply(c("qc141", "p38_fit", "qc_rh", CANDS), function(ar) { r <- relations(TR[arm == ar]); r[, arm := ar]; r })); setcolorder(REL, "arm")  # PREREG46: five arms
R44 <- fread(file.path(P44, "assembled/gyr142-p44-relations_DATA_2026-10-05.csv"))
rr <- merge(REL[arm %in% c("qc141", "p38_fit")], R44, by = c("arm", "relation", "unit"), suffixes = c("", ".r")); rrw <- rr[, max(abs(fifelse(is.finite(margin), margin, 0) - fifelse(is.finite(margin.r), margin.r, 0)), sum(flag != flag.r))]
cat(sprintf("RL: frozen PREREG44 relations reproduced, worst %.3g over %d rows\n", rrw, nrow(rr))); if (nrow(rr) != nrow(R44) || rrw > 1e-9) stop("RL PREREG44 RELATIONS REPRO FAIL")
## PREREG46: frozen qc_rh relations against the PREREG45 assembled table [F9]
R45 <- fread(file.path(P45, "assembled/gyr142-p45-relations_DATA_2026-10-05.csv"))[arm == "qc_rh"]
rq <- merge(REL[arm == "qc_rh"], R45, by = c("arm", "relation", "unit"), suffixes = c("", ".r")); rqw <- rq[, max(abs(fifelse(is.finite(margin), margin, 0) - fifelse(is.finite(margin.r), margin.r, 0)), sum(flag != flag.r))]
cat(sprintf("RLQ: frozen qc_rh relations reproduced, worst %.3g over %d rows\n", rqw, nrow(rq))); if (nrow(rq) != nrow(R45) || nrow(rq) == 0 || !is.finite(rqw) || rqw > 1e-9) warning("RLQ QC_RH RELATIONS REPRO FAIL (reported)")
## non inferiority against qc141 (PREREG44 rule A and B), PREREG46: per arm; qc_rh reported
ni_arm <- function(ca) { A <- merge(REL[arm == ca], REL[arm == "qc141"], by = c("relation", "unit"), suffixes = c("", "_ref")); A[, newflag := flag & !flag_ref]
  BB <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0, ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0), by = relation]
  BB[, ni_ok := new_flags == 0 & (cand_flags == 0 | cand_worst <= ref_worst + 1e-9)]; BB[, arm := ca]; setcolorder(BB, "arm"); BB }
BB <- rbindlist(lapply(c("qc_rh", CANDS), ni_arm)); print(BB)
NI <- BB[, .(ni_ok = all(ni_ok), new_flags = sum(new_flags), failing = paste(relation[!ni_ok], collapse = ",")), by = arm]
## gate C, PREREG46: offset removed (st2_offset.R definition) and raw ceiling; reported raw as PREREG45, HT100, gain 80 to 100, crossing year
OFF <- TR[arm == "qc141", .(off = (HT[age == 1] - HT[age == 0]) - (HT[age == 100] - HT[age == 1]) / 99), by = cell]
C100 <- TR[age == 100, .(rel100 = HT / esi, HT100 = HT, esi100 = esi), by = .(arm, cell)]; C0 <- TR[age == 0, .(rel0 = HT / esi), by = .(arm, cell)]; C80 <- TR[age == 80, .(HT80 = HT), by = .(arm, cell)]
CC <- merge(merge(merge(C100, C0, by = c("arm", "cell")), C80, by = c("arm", "cell")), OFF, by = "cell"); CC[, rel100_corr := (HT100 - off) / esi100]
CS <- CC[, .(stands = .N, median_rel0 = median(rel0), median_rel100 = median(rel100), max_rel100 = max(rel100), n_over = sum(rel100 > BOUND_C),
  share_over = mean(rel100 > BOUND_C), median_HT100 = median(HT100), mean_HT100 = mean(HT100), median_off_m = median(off), median_rel100_corr = median(rel100_corr),
  n_over_corr = sum(rel100_corr > BOUND_C), gain80_100_mean = mean(HT100 - HT80), gain80_100_median = median(HT100 - HT80)), by = arm]
CR <- TR[, .(rel = median(HT / esi)), by = .(arm, age)][, .(year_cross_1175 = if (isTRUE(any(rel > BOUND_C, na.rm = TRUE))) as.numeric(min(age[which(rel > BOUND_C)])) else NA_real_), by = arm]
CS <- merge(CS, CR, by = "arm")
CS[, pass_C_p45 := median_rel100 <= BOUND_C & share_over <= 0.10]  # reported, PREREG45 gate C
CS[, pass_C1 := stands == NST & median_rel100_corr <= BOUND_C & n_over_corr <= NOVER_C]  # gate C part 1, offset removed
CS[, pass_C2 := stands == NST & median_rel100 <= RAW_C]  # gate C part 2, raw ceiling
CS[, pass_C := pass_C1 & pass_C2]; print(CS)
## PREREG46: offset reproduction against the ST2 table for the frozen arms [F9]
S2 <- fread(file.path(P45ST, "assembled/st2_gatec-offset_DATA_2026-10-05.csv"))
c2 <- merge(CS[arm %in% c("qc141", "p38_fit", "qc_rh")], S2, by = "arm", suffixes = c("", ".r"))
r2w <- c2[, max(abs(median_off_m - median_off_m.r), abs(median_rel100 - median_rel100.r), abs(median_rel100_corr - median_rel100_corr.r), abs(n_over_corr - n_over_corr.r), abs(n_over - n_over.r))]
cat(sprintf("RC: gate C offset reproduces ST2, worst %.3g over %d arms\n", r2w, nrow(c2))); if (nrow(c2) != 3 || !is.finite(r2w) || r2w > 1e-9) stop("RC ST2 OFFSET REPRO FAIL")
REPRO <- data.table(check = c("fit reproduction (fit_p46.R)", "R3 field tag counts A", "R3 field tag counts B", "RS frozen stand summaries = PREREG38", "RH frozen height rows = PREREG38",
    "RSQ qc_rh stand summaries = PREREG45", "RHQ qc_rh height rows = PREREG45", "RL frozen relations = PREREG44", "RLQ qc_rh relations = PREREG45", "RC gate C offset = ST2"),
  rows = c(698, 1, 1, nrow(cs), nrow(ch), nrow(cq), nrow(chq), nrow(rr), nrow(rq), nrow(c2)),
  worst = c(abs(FIT$R37_reproduced[1] - 1.2418873575799), abs(n46[1] - n37[1]), abs(n46[2] - n37[2]), rs, rh, rsq, rhq, rrw, rqw, r2w),
  pass = c(TRUE, TRUE, TRUE, TRUE, TRUE, nrow(cq) == 8 && is.finite(rsq) && rsq <= 1e-9, nrow(chq) == nrow(H45) && nrow(chq) >= 20 && is.finite(rhq) && rhq <= 1e-9, TRUE,
    nrow(rq) == nrow(R45) && nrow(rq) > 0 && is.finite(rqw) && rqw <= 1e-9, TRUE))  # PREREG46: qc_rh rows reported, the rest are stops above
## decision, PREREG46: per arm in the registered order, then the tie rule
okv <- function(...) { x <- list(...); vapply(x, function(v) length(v) == 1 && isTRUE(as.logical(v)), logical(1)) }  # PREREG46: a missing or NA gate counts as a fail
DEC <- lapply(CANDS, function(ca) { g <- GA[arm == ca]; f <- FS[arm == ca]; h0 <- H0[arm == H0ARM[[ca]]]; gg <- G12[arm == ca]; cc <- CS[arm == ca]; ni <- NI[arm == ca]
  r1 <- okv(`fit stop` = f$fit_ok, G0 = G0, G0b = G0b, G0x = G0x, H0 = nrow(h0) == 2 && all(h0$pass), TR = TRP[[ca]], K1 = k1_pass[arm == ca]$pass, G1 = gg$G1, G2 = gg$G2)
  r2 <- okv(`H1 level` = g$p_H1, `H classes` = g$p_CLS, `H relht` = g$p_REL, `H relbin` = g$p_RELBIN, `H upper` = g$p_UPPER)
  r3 <- okv(TOPHT = g$p_TOP, V2 = g$p_V2, B1 = g$p_B1, B2 = g$p_B2)
  r4 <- okv(`C offset removed` = cc$pass_C1, `C raw ceiling` = cc$pass_C2, `NI long run` = ni$ni_ok)
  outcome <- if (!all(r1)) "RULE1_HARNESS_FAILURE" else if (!all(r2)) "RULE2_NOT_ADOPTED_HEIGHT" else if (!all(r3)) "RULE3_NOT_ADOPTED_TRADEOFF" else
    if (!all(r4)) "RULE4_NOT_CLEARED_LONGRUN" else "RULE5_CANDIDATE"
  allg <- c(r1, r2, r3, r4); fails <- names(allg)[!allg]; if (!isTRUE(ni$ni_ok) && nrow(ni)) fails[fails == "NI long run"] <- paste("NI", ni$failing)
  list(arm = ca, outcome = outcome, fails = fails, pass = allg) })
names(DEC) <- CANDS
R5 <- CANDS[vapply(DEC, function(d) d$outcome == "RULE5_CANDIDATE", logical(1))]
TIE <- round(setNames(GA[match(CANDS, arm)]$worst_abs_rel, CANDS), 3)
candidate <- if (length(R5) == 2) { if (TIE[["qc_ez"]] < TIE[["qc_lz"]]) "qc_ez" else "qc_lz" } else if (length(R5) == 1) R5 else "none"
GATES <- rbindlist(lapply(CANDS, function(ca) { g <- GA[arm == ca]; f <- FS[arm == ca]; h0 <- H0[arm == H0ARM[[ca]]]; k <- K1[arm == ca]; gg <- G12[arm == ca]; cc <- CS[arm == ca]; ni <- NI[arm == ca]
  q <- function(x, v) GA[arm == x][[v]]
  det <- c(sprintf("a %.4f b %.4f (unrounded b %.6f); zero r %.4f; Newton iter %s; nonconverged %s of %d", f$a_r, f$b_r, f$b_unrounded, f$zero_r, f$newton_iter, f$boot_nonconverged, B),
    "driver_p46 g0 vs frozen p19_a0111", "driver_p46 grid vs PREREG31 dry", HARN[gate == "G0x"]$detail,
    sprintf("%s vs p19_a1000: worst results %.2e, trees %.2e", H0ARM[[ca]], max(h0$worst_results), max(h0$worst_trees)), HARN[arm == ca & gate == "TR"]$detail,
    sprintf("not ok %d", sum(k$not_ok)), sprintf("%d of %d trajectories with 101 rows", gg$traj_101, NST), sprintf("worst %.3g over %d", gg$g2_worst, gg$g2_rows),
    sprintf("ratio %.3f [%.3f, %.3f]; qc141 %.3f; p38_fit %.3f; qc_rh %.3f", g$ratio, g$ratio_lo, g$ratio_hi, q(REF, "ratio"), q("p38_fit", "ratio"), q("qc_rh", "ratio")),
    sprintf("bias %+.3f, %+.3f, %+.3f m/yr; worst worse than qc141 by %+.3f", g$bias_small, g$bias_mid, g$bias_large, g$worst_class_worse_by), g$rel_bias,
    sprintf("ratio per bin: %s; bounds %.2f to %.2f", g$rel_ratio, REL_LO, REL_HI), sprintf("bins of %d or more trees: highest upper %.3f (at most %.2f), lowest lower %.3f (at least %.2f)", MIN_BIN, g$rel_hi_max, UP_HI, g$rel_lo_min, UP_LO),
    sprintf("TOPHT %+.2f%% vs limit %+.2f%%; dominant %.3f vs qc141 %.3f", g$topht, g$topht_limit, g$dom_level, g$dom_ref), sprintf("%%RMSE %.2f vs %.2f", g$rmse, g$rmse_ref),
    sprintf("%.2f vs %.2f pts", g$ba_pts, g$ba_ref_pts), sprintf("%.2f vs %.2f pts", g$stems_pts, g$stems_ref_pts),
    sprintf("offset removed: median rel100 %.3f, %d of %d over %.3f (median offset %.2f m)", cc$median_rel100_corr, cc$n_over_corr, cc$stands, BOUND_C, cc$median_off_m),
    sprintf("raw median rel100 %.3f vs ceiling %.3f", cc$median_rel100, RAW_C), sprintf("new flags %d; failing %s", ni$new_flags, ni$failing),
    sprintf("engine fold A pooled ratio %.3f (%d trees); qc_rh %.3f", g$foldA_ratio, g$foldA_trees, q("qc_rh", "foldA_ratio")),
    sprintf("raw median rel100 %.3f, %d of %d over %.3f; HT100 median %.2f m; gain 80 to 100 mean %.2f, median %.2f m; median crosses %.3f at year %s",
      cc$median_rel100, cc$n_over, cc$stands, BOUND_C, cc$median_HT100, cc$gain80_100_mean, cc$gain80_100_median, BOUND_C, cc$year_cross_1175))
  data.table(arm = ca, gate = c("fit stop", "G0", "G0b", "G0x", "H0", "TR", "K1", "G1", "G2", "H1 level", "H classes", "H relht", "H relbin", "H upper", "TOPHT", "V2", "B1", "B2",
      "C offset removed", "C raw ceiling", "NI long run", "fold A ratio (reported)", "C raw as PREREG45 (reported)"),
    detail = det, pass = c(unname(DEC[[ca]]$pass), NA, NA)) }))
print(GATES)
files <- c(w_out(GATES, "gates_DATA.csv"), w_out(GA, "gates-all_DATA.csv"), w_out(HT, "hinc_DATA.csv"), w_out(STS, "stands-summary_DATA.csv"), w_out(H0, "H0_DATA.csv"), w_out(K1, "K1_DATA.csv"),
  w_out(REPRO, "repro_DATA.csv"), w_out(REL, "relations_DATA.csv"), w_out(BB, "ni-by-relation_DATA.csv"), w_out(CS, "credibility_DATA.csv"),
  w_out(FS, "fit-stops_DATA.csv"), w_out(rbind(HARN, G12[, .(arm, gate = "G1", detail = sprintf("%d of %d with 101 rows", traj_101, stands), pass = G1)], G12[, .(arm, gate = "G2", detail = sprintf("worst %.3g over %d", g2_worst, g2_rows), pass = G2)]), "harness_DATA.csv"),  # PREREG46
  w_out(TR[age %% 5 == 0][, (intersect(c("STAND", "SITE"), names(TR))) := NULL], "traj-5yr_DATA.csv"))  # PREREG46: SITE dropped too if present
## verdict, PREREG46: per arm, then the candidate under the tie rule
V <- c("plan_md5=eb4b753d", unlist(lapply(CANDS, function(ca) { f <- FS[arm == ca]; c(sprintf("fit %s a=%.4f b=%.4f zero_r=%.4f", ca, f$a_r, f$b_r, f$zero_r),
    sprintf("outcome_%s=%s", ca, DEC[[ca]]$outcome), sprintf("failing_%s=%s", ca, paste(DEC[[ca]]$fails, collapse = ";"))) })),
  sprintf("tie_metric_worst_abs_relbin_bias_foldB qc_lz=%.3f qc_ez=%.3f", TIE[["qc_lz"]], TIE[["qc_ez"]]), paste0("repro_reported_fail=", paste(REPRO$check[!REPRO$pass], collapse = ";")), paste0("candidate=", candidate),
  "decision_weight=informs 14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579")
vf <- file.path(O, sprintf("gyr142-p46-verdict_DATA_%s.txt", DT)); if (file.exists(vf)) stop("REFUSE ", vf); writeLines(V, vf); cat(V, sep = "\n")
## figure: (a) relht bin bias, fold B; (b) DBH class bias; (c) top height over ESI to 100 years. PREREG46: five arms, both bounds
LAB <- c(p19_a0111 = "qc141 (0.111)", qc141 = "qc141 (0.111)", p38_fit = "p38_fit (1.242)", qc_rh = "qc_rh, exp (frozen)", qc_lz = "qc_lz, linear zero", qc_ez = "qc_ez, exp to RMAX")
LEV <- c("qc141 (0.111)", "p38_fit (1.242)", "qc_rh, exp (frozen)", "qc_lz, linear zero", "qc_ez, exp to RMAX")
FB <- HT[set == "qc_c" & fold == "B" & group %in% c(RELB, CLS) & arm %in% c(REF, "p38_fit", "qc_rh", CANDS)]
FB[, armlab := factor(LAB[arm], levels = LEV)]
FB[, panel := fifelse(group %in% RELB, "rel", "cls")]; FB[, grp := factor(sub("^rel ", "", group), levels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", CLS))]
TT <- TR[age %% 5 == 0, .(rel = mean(HT / esi, na.rm = TRUE), lo = quantile(HT / esi, .1, na.rm = TRUE), hi = quantile(HT / esi, .9, na.rm = TRUE)), by = .(arm, age)]
TT[, armlab := factor(LAB[arm], levels = LEV)]
dir.create(file.path(J, "figs"), showWarnings = FALSE)  # PREREG46: figs folder is not made by the chain
FGF <- file.path(J, "figs", sprintf(c("gyr142-p46-relht_DATA_%s.csv", "gyr142-p46-topht100_DATA_%s.csv", "gyr142-p46-relht-longrun_%s.png"), DT)); if (any(file.exists(FGF))) stop("REFUSE ", paste(FGF[file.exists(FGF)], collapse = " "))
fwrite(FB, FGF[1]); fwrite(TT, FGF[2])
cols <- c("grey40", "#1b6ca8", "#b5452b", "#2e8b57", "#8e44ad"); th0 <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
pa <- ggplot(FB[panel == "rel"], aes(grp, bias_m_yr, colour = armlab)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -M_ABS, ymax = M_ABS, alpha = .12, fill = "#1b6ca8") + geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(ymin = bias_lo, ymax = bias_hi), width = .2, position = position_dodge(.7)) + geom_point(size = 1.6, position = position_dodge(.7)) + scale_colour_manual(values = cols, drop = FALSE) +
  labs(x = "t1 height over ESI", y = expression("Height increment bias (m "*yr^{-1}*")"), colour = NULL) + th0
pb <- pa %+% FB[panel == "cls"] + labs(x = "t1 DBH class (cm)")
pc <- ggplot(TT, aes(age, rel, colour = armlab, fill = armlab)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .12, colour = NA) + geom_line() + geom_hline(yintercept = BOUND_C, linetype = 2) +
  geom_hline(yintercept = RAW_C, linetype = 3) + scale_colour_manual(values = cols, drop = FALSE) + scale_fill_manual(values = cols, drop = FALSE) + labs(x = "Years projected", y = "Top height over ESI", colour = NULL, fill = NULL) + th0
fig <- (pa + pb) / pc + plot_layout(guides = "collect") + plot_annotation(tag_levels = "a") & theme(legend.position = "bottom")
ggsave(FGF[3], fig, width = 180, height = 160, units = "mm", dpi = 300)
cat("P46_ASSEMBLE_DONE\n")
