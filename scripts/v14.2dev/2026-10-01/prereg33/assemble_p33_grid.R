## PREREG33 grid assembly: copy of PREREG31 assemble_p31.R (md5 f815991d, post type fix) with the job root, candidate
## (p33_dyn), thresholds path (the PREREG31 file copied, md5 checked), output names and outcome labels changed; G0d added and
## G2 redefined as the qc141 grid through driver_p33.R against the PREREG31 qc141 trajectories (PREREG33 plan). Relations,
## thresholds and NI rule A and B unchanged. Diff in ../diffs/. No coordinates. No em dashes.
## PREREG31 assembly. PREREG26 assemble_p26.R (post attribution fix) with the QC grid (mixes BF, SM, MX; ESI 17.3, 18.5,
## 19.1, 19.8), the arms qc141 (reference) and p33_dyn (candidate), the QC thresholds, and no follow up arms; figures
## are drawn by figs/fig_p31.R, not here. Usage: Rscript assemble_p31.R [OUTDIR] [INDIR] [DRYFILE]. Reads out/traj_<arm>_<mix>.csv,
## the harness gate files and the re-derived thresholds; writes gates, relations, paired relations, trajectories, realism,
## the dht.mult table, the checker cross check and the verdict. Refuses to overwrite. No coordinates. No em dashes.
suppressMessages({library(data.table)})
a <- commandArgs(TRUE); J <- "/home/aaron/jobs/v142p33"; OD <- if (length(a) >= 1) a[1] else file.path(J, "assembled/grid")
IN <- if (length(a) >= 2) a[2] else file.path(J, "out"); P31OUT <- if (length(a) >= 3) a[3] else "/home/aaron/jobs/v142p31/out"
dir.create(OD, showWarnings = FALSE, recursive = TRUE)
DT <- "2026-10-01"; f <- function(x) file.path(OD, sprintf("gyr142-p33grid-%s", sub("^(.*)(\\.[a-z]+)$", paste0("\\1_", DT, "\\2"), x)))
wr <- function(x, nm) { fn <- f(nm); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(x, fn); fn }
MIXES <- c("BF","SM","MX"); ESI <- c(17.3, 18.5, 19.1, 19.8); N0 <- c(1500, 3000, 6000); REF <- "qc141"; CAND <- "p33_dyn"; ARMS <- c(REF, CAND)
rd_arm <- function(arm) rbindlist(lapply(MIXES, function(m) { fn <- file.path(IN, sprintf("traj_%s_%s.csv", arm, m)); if (!file.exists(fn)) NULL else fread(fn) }))
THF <- file.path(J, "tables/thresholds_p31_DATA_2026-09-30.csv"); if (unname(tools::md5sum(THF)) != "fa5a852af4d673423da62de538242b66") stop("thresholds md5"); TH <- fread(THF); th <- setNames(TH$value, TH$quantity)
## ---------------- relations for one arm (PREREG26 rules unchanged) ----------------
relations <- function(tr) {
  d <- tr[age %% 5 == 0][order(mix, esi, n0, age)]
  d[, QMD_s := fifelse(TPH_s > 0, sqrt((BAPH_s/TPH_s)/(pi/40000)), NA_real_)][, SDI_s := fifelse(TPH_s > 0, TPH_s*(QMD_s/25)^1.605, 0)]
  out <- list()
  for (k in unique(d$cell)) { g <- d[cell == k]; u <- k
    keep <- c(TRUE, diff(g$QMD) > 0.10*5); gk <- g[keep]; loses <- (max(g$TPH) - min(g$TPH))/max(g$TPH) > 0.01
    if (nrow(gk) >= 3 && sd(log(gk$QMD)) > 1e-3) { sl <- unname(coef(lm(log(TPH) ~ log(QMD), gk))[2]); fl <- !(is.finite(sl) && sl > -2.2 && sl < -1.2)
      mg <- if (!fl) 0 else if (!is.finite(sl)) Inf else if (sl >= -1.2) sl + 1.2 else -2.2 - sl
      out[[length(out)+1]] <- data.table(relation = "Reineke", unit = u, evaluated = TRUE, flag = fl, margin = mg, stat = sl, npts = nrow(gk))
    } else out[[length(out)+1]] <- data.table(relation = "Reineke", unit = u, evaluated = FALSE, flag = loses, margin = if (loses) Inf else 0, stat = NA_real_, npts = nrow(gk))
    h <- g[TPH_s > 0]; exc <- if (nrow(h)) log10(h$TPH_s) - (th[["frontier_a"]] + th[["frontier_b"]]*log10(h$QMD_s)) else -Inf
    out[[length(out)+1]] <- data.table(relation = "Frontier", unit = u, evaluated = nrow(h) > 0, flag = any(exc > 0), margin = max(0, exc), stat = max(exc), npts = nrow(h))
    r <- max(max(g$BAPH_s)/th[["BA_q999"]], max(g$SDI_s)/th[["SDI_q999"]])
    out[[length(out)+1]] <- data.table(relation = "Magnitude", unit = u, evaluated = TRUE, flag = r > 1, margin = max(0, r - 1), stat = r, npts = nrow(g))
    fall <- max(0, -diff(g$HT))
    out[[length(out)+1]] <- data.table(relation = "HT_monotone", unit = u, evaluated = TRUE, flag = fall > 0.01, margin = if (fall > 0.01) fall else 0, stat = fall, npts = nrow(g)) }
  for (m in MIXES) for (n in N0) { g <- d[mix == m & n0 == n]; u <- sprintf("%s_N%d", m, n)
    hi <- max(sapply(ESI, function(s) min(g[esi == s]$HT))); hx <- min(sapply(ESI, function(s) max(g[esi == s]$HT)))
    if (hx > hi) { gr <- seq(hi, hx, length.out = 8)
      cv <- mean(sapply(gr, function(hg) { vv <- sapply(ESI, function(s) { z <- g[esi == s]; approx(z$HT, z$VOL, hg, rule = 2, ties = mean)$y }); sd(vv)/mean(vv) }))
      out[[length(out)+1]] <- data.table(relation = "Eichhorn", unit = u, evaluated = TRUE, flag = cv >= 0.15, margin = max(0, cv - 0.15), stat = cv, npts = 8L)
    } else out[[length(out)+1]] <- data.table(relation = "Eichhorn", unit = u, evaluated = FALSE, flag = TRUE, margin = Inf, stat = NA_real_, npts = 0L)
    for (v in c("HT","VOL","BAPH")) { inv <- 0L; mx <- 0
      for (ag in seq(5, 100, 5)) { z <- g[age == ag][order(esi)][[v]]; if (length(z) == 4 && is.unsorted(z)) { inv <- inv + 1L; mx <- max(mx, max(cummax(z) - z)/max(z)) } }
      out[[length(out)+1]] <- data.table(relation = paste0("SiteOrder_", v), unit = u, evaluated = TRUE, flag = inv > 0, margin = inv, stat = mx, npts = 20L) } }
  for (m in MIXES) for (s in ESI) { g <- d[mix == m & esi == s]; u <- sprintf("%s_E%g", m, s)
    viol <- 0L; for (ag in c(50, 100)) { z <- g[age == ag][order(n0)]; lost <- z$n0 - z$TPH_cohort; viol <- viol + sum(diff(lost) <= 0) }
    out[[length(out)+1]] <- data.table(relation = "Sukachev", unit = u, evaluated = TRUE, flag = viol > 0, margin = viol, stat = viol, npts = 6L)
    v100 <- g[age == 100]$VOL; v30 <- g[age == 30]$VOL; c100 <- sd(v100)/mean(v100); c30 <- sd(v30)/mean(v30)
    fl <- !(c100 < 0.15 && c100 < c30)
    out[[length(out)+1]] <- data.table(relation = "YieldDensity", unit = u, evaluated = TRUE, flag = fl, margin = if (fl) max(c100 - 0.15, c100 - c30) else 0, stat = c100, npts = 3L) }
  rbindlist(out) }
## ---------------- harness gates ----------------
gates <- list(); G <- function(g, val, thr, pass, prov) gates[[length(gates)+1]] <<- data.table(gate = g, value = as.character(val), threshold = thr, pass = isTRUE(pass), provenance = prov)
g0 <- tryCatch(fread(file.path(J, "logs/grid_g0_result.csv")), error = function(e) NULL)
G("G0", if (is.null(g0)) "missing" else sprintf("worst scaled %.3g over %d stands, %d columns", g0$worst_scaled, g0$stands, g0$columns), "<= 1e-9", !is.null(g0) && g0$pass, "frozen p19_a0111 qc_c results, md5 979101be; logs/grid_g0_result.csv")
g0d <- tryCatch(fread(file.path(J, "logs/grid_g0d_result.csv")), error = function(e) NULL)
G("G0d", if (is.null(g0d)) "missing" else sprintf("worst scaled %.3g over %d stands, %d columns", g0d$worst_scaled, g0d$stands, g0d$columns), "<= 1e-9", !is.null(g0d) && g0d$pass, "driver_p33 QC_AFAC_DYNAMIC 2, flat 0.111, against frozen p19_a0111 qc_c; logs/grid_g0d_result.csv")
g0c <- tryCatch(readLines(file.path(J, "logs/g0c_status.txt")), error = function(e) "missing")
G("G0c", g0c[1], "G0C_PASS", identical(g0c[1], "G0C_PASS"), "stored v1402 report md5 7a04368c; logs/g0c_diff.txt")
TR <- rbindlist(lapply(ARMS, rd_arm))
nt <- if (nrow(TR)) TR[, .(rows = .N, ok = all(run_ok == 1)), by = .(arm, cell)] else data.table(rows = integer(), ok = logical())
G("G1", sprintf("%d of %d trajectories complete with 101 rows (arms %s)", nt[rows == 101 & ok, .N], 36L*length(ARMS), paste(ARMS, collapse = " ")), "all", nt[rows == 101 & ok, .N] == 36L*length(ARMS), "out/traj_<arm>_<mix>.csv")
## PREREG33 G2: the qc141 grid through driver_p33.R (QC_AFAC_DYNAMIC unset) equals the PREREG31 qc141 trajectories, every cell and year
P31Q <- tryCatch(rbindlist(lapply(MIXES, function(m) fread(file.path(P31OUT, sprintf("traj_qc141_%s.csv", m))))), error = function(e) NULL)
if (!is.null(P31Q) && nrow(TR)) { gg <- TR[arm == REF][order(cell, age)]; P31Q <- P31Q[order(cell, age)]; num <- names(P31Q)[sapply(P31Q, is.numeric)]
  same <- nrow(gg) == nrow(P31Q) && identical(gg$cell, P31Q$cell) && isTRUE(all.equal(as.matrix(P31Q[, ..num]), as.matrix(gg[, ..num]), tolerance = 0)) } else same <- FALSE
G("G2", if (same) sprintf("identical, %d rows", nrow(P31Q)) else "differs or missing", "identical", same, "qc141 through driver_p33 against ~/jobs/v142p31/out/traj_qc141_<mix>.csv")
harness_ok <- all(sapply(gates, function(x) x$pass))
## ---------------- relations and NI ----------------
REL <- rbindlist(lapply(ARMS, function(ar) { x <- TR[arm == ar]; if (!nrow(x)) return(NULL); r <- relations(x); r[, arm := ar]; r }))
setcolorder(REL, "arm")
ni <- function(cand) { A <- merge(REL[arm == cand], REL[arm == REF], by = c("relation","unit"), suffixes = c("", "_ref"))
  A[, newflag := flag & !flag_ref]
  B <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0,
             ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0), by = relation]
  B[, marginB_ok := cand_flags == 0 | cand_worst <= ref_worst + 1e-9][, ni_ok := new_flags == 0 & marginB_ok]; list(A = A, B = B) }
N <- ni(CAND)
for (i in seq_len(nrow(N$B))) with(N$B[i], G(sprintf("NI %s", relation), sprintf("flags p33_dyn %d, qc141 %d, new %d; worst margin p33_dyn %.4g, qc141 %.4g", cand_flags, ref_flags, new_flags, cand_worst, ref_worst), "no new flag; candidate worst margin <= qc141 worst", ni_ok, "PREREG31 relations (PREREG26 rules), QC thresholds in plan"))
NI_ok <- all(N$B$ni_ok)
## ---------------- realism (reported) ----------------
RL <- dcast(TR[age %in% c(50, 100), .(arm, mix, esi, n0, age, HT, TPH, TPH_s, VOL)], mix + esi + n0 + age ~ arm, value.var = c("HT","TPH","TPH_s","VOL"))
RL[, HT_ratio := HT_p33_dyn/HT_qc141][, TPH_ratio := TPH_p33_dyn/TPH_qc141][, TPHs_ratio := TPH_s_p33_dyn/TPH_s_qc141][, VOL_ratio := VOL_p33_dyn/VOL_qc141]
RL[, HT50_over_ESI_cand := fifelse(age == 50, HT_p33_dyn/esi, NA_real_)][, HT50_over_ESI_ref := fifelse(age == 50, HT_qc141/esi, NA_real_)]
implaus_lo <- RL[(HT_ratio < 0.90) | (age == 50 & HT_p33_dyn < 0.85*esi)]; implaus_lo_ref <- RL[age == 50 & HT_qc141 < 0.85*esi]
implaus_hi <- RL[(HT_ratio > 1/0.90) | (age == 50 & HT_p33_dyn > 1.15*esi)]; implaus_hi_ref <- RL[age == 50 & HT_qc141 > 1.15*esi]
## ---------------- dht.mult carried (reported) ----------------
DM <- TR[age %in% c(0, 1, 25, 50, 75, 100), .(DHTM_cohort_min = min(as.numeric(DHTM_cohort), na.rm = TRUE), DHTM_cohort_max = max(as.numeric(DHTM_cohort), na.rm = TRUE),
  DHTM_ing_min = suppressWarnings(min(as.numeric(DHTM_ing), na.rm = TRUE)), DHTM_ing_max = suppressWarnings(max(as.numeric(DHTM_ing), na.rm = TRUE)),
  cohort_ge25_max = max(as.numeric(TPH_cohort_ge25)), cohort_ge25_share_max = max(TPH_cohort_ge25/pmax(TPH_cohort, 1e-9)),
  DHTM_ge25_min = suppressWarnings(min(as.numeric(DHTM_cohort_ge25), na.rm = TRUE)), DHTM_ge25_max = suppressWarnings(max(as.numeric(DHTM_cohort_ge25), na.rm = TRUE))), by = .(arm, age)]
## ---------------- checker cross check ----------------
CK <- list(); dir.create(file.path(OD, "checker"), showWarnings = FALSE)
for (ar in ARMS) for (m in MIXES) { x <- TR[arm == ar & mix == m & age %% 5 == 0, .(site = esi, origin = paste0("N0=", n0), age, HT, TPH, BAPH, QMD, VOL)]
  if (!nrow(x)) next
  fn <- file.path(OD, "checker", sprintf("traj5_%s_%s.csv", ar, m)); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(x, fn)
  o <- system2("Rscript", c("--vanilla", "/home/aaron/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R", fn), stdout = TRUE, stderr = TRUE)
  writeLines(o, sub("\\.csv$", "_check.txt", fn)); fl <- grep("^FLAGS:", o, value = TRUE); if (!length(fl)) fl <- "no FLAGS line"
  CK[[length(CK)+1]] <- data.table(arm = ar, mix = m, summary = fl[1], reineke_flags = length(grep("Reineke slope", o)), eichhorn_flags = length(grep("^  - Eichhorn", o)), tph_nonmono = length(grep("TPH not monotone", o))) }
CK <- rbindlist(CK)
## ---------------- write ----------------
files <- c(wr(rbindlist(gates), "gates_DATA.csv"), wr(REL, "relations_DATA.csv"), wr(N$A, "relations-paired_DATA.csv"), wr(N$B, "ni-by-relation_DATA.csv"), wr(TR, "traj-annual_DATA.csv"),
  wr(TR[age %% 5 == 0], "traj-5yr_DATA.csv"), wr(RL, "realism_DATA.csv"), wr(DM, "dhtmult_DATA.csv"), wr(CK, "checker_DATA.csv"))
outcome <- if (!harness_ok) "GRID_HARNESS_FAILURE" else if (!NI_ok) "NI_FAIL" else "NI_PASS"
V <- c(sprintf("plan_md5=%s", Sys.getenv("P33_PLAN_MD5", "unset")), sprintf("outcome=%s", outcome),
  sprintf("harness_ok=%s NI_ok=%s", harness_ok, NI_ok), sprintf("new_flags=%d", sum(N$A$newflag)),
  sprintf("new_flag_units=%s", paste(N$A[newflag == TRUE, paste(relation, unit, sep = ":")], collapse = ";")),
  sprintf("marginB_fail_relations=%s", paste(N$B[marginB_ok == FALSE, relation], collapse = ";")),
  sprintf("realism_low_rows=%d (qc141 below 0.85 ESI at 50: %d)", nrow(implaus_lo), nrow(implaus_lo_ref)),
  sprintf("realism_high_rows=%d (qc141 above 1.15 ESI at 50: %d)", nrow(implaus_hi), nrow(implaus_hi_ref)),
  sprintf("HT_ratio_range=%.4f..%.4f TPH100_ratio_range=%.3f..%.3f VOL100_ratio_range=%.3f..%.3f", min(RL$HT_ratio), max(RL$HT_ratio), min(RL[age == 100]$TPH_ratio), max(RL[age == 100]$TPH_ratio), min(RL[age == 100]$VOL_ratio), max(RL[age == 100]$VOL_ratio)))
vf <- f("verdict_DATA.txt"); if (file.exists(vf)) stop("REFUSE ", vf); writeLines(V, vf)
print(rbindlist(gates)); print(N$B); print(DM); cat(V, sep = "\n"); cat("P33_GRID_ASSEMBLY_DONE\n")
