## PREREG44 assembly (plan revision 1), r2: as r1 (md5 recorded in logs/launch_md5s.txt) with as.numeric() in the reported dht.mult
## table only, after r1 stopped on an integer/double type clash there (logs/assemble.log, kept as assemble_r1_typeerror.log); no gate,
## relation or rule line changed. Arms qc141 (reference, QC_AFAC 0.111) and p38_fit (QC_AFAC 1.242 for every tree), 36
## measured qc_c fold B stand lists, 100 annual steps, read every 5 years. Relations are the PREREG31 set (assemble_p31.R) with
## the two registered changes (Reineke after the trajectory first reaches relative density 0.5 of the QC frontier; site
## ordering on ESI bin means) and the registered mapping of the stand level units (N0 becomes the SDI bin; mix is the observed
## mix, one unit). Non inferiority rule unchanged. The outcome informs 14.3 only and cannot reopen the 14.2 QC decision.
## Writes no stand IDs except the SERVERONLY trajectory copy. Refuses to overwrite. No coordinates. No em dashes.
suppressMessages({library(data.table)})
a <- commandArgs(TRUE); J <- "/home/aaron/jobs/v142p44"; OD <- if (length(a) >= 1) a[1] else file.path(J, "assembled")
IN <- if (length(a) >= 2) a[2] else file.path(J, "out"); LG <- if (length(a) >= 3) a[3] else file.path(J, "logs"); dir.create(OD, showWarnings = FALSE, recursive = TRUE)
DT <- "2026-10-05"; f <- function(x) file.path(OD, sprintf("gyr142-p44-%s", sub("^(.*)(\\.[a-z]+)$", paste0("\\1_", DT, "\\2"), x)))
wr <- function(x, nm) { fn <- f(nm); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(x, fn); fn }
REF <- "qc141"; CAND <- "p38_fit"; ARMS <- c(REF, CAND); ESIB <- 1:4; SDIB <- 1:3
TH <- fread("/home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv"); th <- setNames(TH$value, TH$quantity)
SL <- fread(file.path(J, "plan/stands_p44_SERVERONLY.csv"), colClasses = list(character = "STAND")); NST <- nrow(SL)
TR <- rbindlist(lapply(ARMS, function(ar) rbindlist(lapply(SDIB, function(s) { fn <- file.path(IN, sprintf("traj_%s_S%d.csv", ar, s)); if (file.exists(fn)) fread(fn, colClasses = list(character = "STAND")) else NULL }))))
frontTPH <- function(q) 10^(th[["frontier_a"]] + th[["frontier_b"]] * log10(q))
## ---------------- relations for one arm ----------------
relations <- function(tr) {
  d <- tr[age %% 5 == 0][order(cell, age)]
  d[, QMD_s := fifelse(TPH_s > 0, sqrt((BAPH_s/TPH_s)/(pi/40000)), NA_real_)][, SDI_s := fifelse(TPH_s > 0, TPH_s*(QMD_s/25)^1.605, 0)]
  d[, RD := fifelse(TPH_s > 0, TPH_s/frontTPH(QMD_s), 0)]
  out <- list()
  for (k in unique(d$cell)) { g <- d[cell == k]; u <- k
    ## Reineke, registered change 1: points from the first age at which RD >= 0.5 onward, QMD advancing more than 0.5 cm per step
    a0 <- if (any(g$RD >= 0.5)) min(g[RD >= 0.5]$age) else NA_real_
    if (is.finite(a0)) { h <- g[age >= a0]; keep <- c(TRUE, diff(h$QMD) > 0.10*5); gk <- h[keep] } else gk <- g[0]
    if (nrow(gk) >= 3 && sd(log(gk$QMD)) > 1e-3) { sl <- unname(coef(lm(log(TPH) ~ log(QMD), gk))[2]); fl <- !(is.finite(sl) && sl > -2.2 && sl < -1.2)
      mg <- if (!fl) 0 else if (!is.finite(sl)) Inf else if (sl >= -1.2) sl + 1.2 else -2.2 - sl
      out[[length(out)+1]] <- data.table(relation = "Reineke", unit = u, evaluated = TRUE, flag = fl, margin = mg, stat = sl, npts = nrow(gk), note = sprintf("from age %g", a0))
    } else out[[length(out)+1]] <- data.table(relation = "Reineke", unit = u, evaluated = FALSE, flag = FALSE, margin = 0, stat = NA_real_, npts = nrow(gk),
      note = if (is.finite(a0)) "fewer than 3 advancing points after RD 0.5" else "never reaches RD 0.5")
    h <- g[TPH_s > 0]; exc <- if (nrow(h)) log10(h$TPH_s) - (th[["frontier_a"]] + th[["frontier_b"]]*log10(h$QMD_s)) else -Inf
    out[[length(out)+1]] <- data.table(relation = "Frontier", unit = u, evaluated = nrow(h) > 0, flag = any(exc > 0), margin = max(0, exc), stat = max(exc), npts = nrow(h), note = "")
    r <- max(max(g$BAPH_s)/th[["BA_q999"]], max(g$SDI_s)/th[["SDI_q999"]])
    out[[length(out)+1]] <- data.table(relation = "Magnitude", unit = u, evaluated = TRUE, flag = r > 1, margin = max(0, r - 1), stat = r, npts = nrow(g), note = "")
    fall <- max(0, -diff(g$HT))
    out[[length(out)+1]] <- data.table(relation = "HT_monotone", unit = u, evaluated = TRUE, flag = fall > 0.01, margin = if (fall > 0.01) fall else 0, stat = fall, npts = nrow(g), note = "") }
  ## bin means (registered change 2 and the stand level mapping)
  M <- d[, .(age, HT, VOL, BAPH, lost = TPH_cohort[age == 0] - TPH_cohort), by = .(cell, esi_bin, sdi_bin)][, .(HT = mean(HT), VOL = mean(VOL), BAPH = mean(BAPH), LOST = mean(lost), n = .N), by = .(esi_bin, sdi_bin, age)]
  for (s in SDIB) { g <- M[sdi_bin == s]; u <- sprintf("S%d", s); eb <- sort(unique(g$esi_bin))
    if (length(eb) >= 2) { hi <- max(sapply(eb, function(e) min(g[esi_bin == e]$HT))); hx <- min(sapply(eb, function(e) max(g[esi_bin == e]$HT))) } else { hi <- 1; hx <- 0 }
    if (hx > hi) { gr <- seq(hi, hx, length.out = 8)
      cv <- mean(sapply(gr, function(hg) { vv <- sapply(eb, function(e) { z <- g[esi_bin == e][order(age)]; approx(z$HT, z$VOL, hg, rule = 2, ties = mean)$y }); sd(vv)/mean(vv) }))
      out[[length(out)+1]] <- data.table(relation = "Eichhorn", unit = u, evaluated = TRUE, flag = cv >= 0.15, margin = max(0, cv - 0.15), stat = cv, npts = 8L, note = sprintf("%d ESI bins", length(eb)))
    } else out[[length(out)+1]] <- data.table(relation = "Eichhorn", unit = u, evaluated = FALSE, flag = TRUE, margin = Inf, stat = NA_real_, npts = 0L, note = "no common top height range")
    for (v in c("HT","VOL","BAPH")) { inv <- 0L; mx <- 0
      for (ag in seq(5, 100, 5)) { z <- g[age == ag][order(esi_bin)][[v]]; if (length(z) >= 2 && is.unsorted(z)) { inv <- inv + 1L; mx <- max(mx, max(cummax(z) - z)/max(z)) } }
      out[[length(out)+1]] <- data.table(relation = paste0("SiteOrder_", v), unit = u, evaluated = TRUE, flag = inv > 0, margin = inv, stat = mx, npts = 20L, note = "ESI bin means") } }
  for (e in ESIB) { g <- M[esi_bin == e]; u <- sprintf("E%d", e)
    viol <- 0L; for (ag in c(50, 100)) { z <- g[age == ag][order(sdi_bin)]$LOST; viol <- viol + sum(diff(z) <= 0) }
    out[[length(out)+1]] <- data.table(relation = "Sukachev", unit = u, evaluated = TRUE, flag = viol > 0, margin = viol, stat = viol, npts = 2L*(length(unique(g$sdi_bin)) - 1L), note = "SDI bin means")
    v100 <- g[age == 100]$VOL; v30 <- g[age == 30]$VOL; c100 <- sd(v100)/mean(v100); c30 <- sd(v30)/mean(v30); fl <- !(c100 < 0.15 && c100 < c30)
    out[[length(out)+1]] <- data.table(relation = "YieldDensity", unit = u, evaluated = TRUE, flag = fl, margin = if (fl) max(c100 - 0.15, c100 - c30) else 0, stat = c100, npts = length(v100), note = "SDI bin means") }
  rbindlist(out) }
## ---------------- harness gates ----------------
gates <- list(); G <- function(g, val, thr, pass, prov) gates[[length(gates)+1]] <<- data.table(gate = g, value = as.character(val), threshold = thr, pass = isTRUE(pass), provenance = prov)
for (gg in c("G0", "G0b")) { x <- tryCatch(fread(file.path(LG, sprintf("%s_result.csv", tolower(gg)))), error = function(e) NULL)
  G(gg, if (is.null(x)) "missing" else paste(names(x), unlist(x), sep = "=", collapse = " "), if (gg == "G0") "<= 1e-9" else "identical", !is.null(x) && isTRUE(x$pass),
    if (gg == "G0") "driver_p44 g0 against frozen p19_a0111 qc_c (md5 979101be)" else "driver_p44 grid against frozen PREREG31 dry trajectory") }
nt <- if (nrow(TR)) TR[, .(rows = .N, ok = all(run_ok == 1)), by = .(arm, cell)] else data.table(rows = integer(), ok = logical())
G("G1", sprintf("%d of %d trajectories complete with 101 rows", nt[rows == 101 & ok, .N], NST*2L), "all", nt[rows == 101 & ok, .N] == NST*2L, "out/traj_<arm>_S<bin>.csv")
ti <- fread("/home/aaron/jobs/v142p28b/home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_init.csv", colClasses = list(character = "STAND"))[STAND %in% SL$STAND]
m0 <- ti[is.finite(DBH) & EXPF > 0, .(TPH_all_o = sum(EXPF), BA4_o = sum((EXPF * pi * (DBH/200)^2)[DBH >= 4])), by = STAND]
z0 <- merge(TR[age == 0, .(arm, STAND, TPH_all, BAPH)], m0, by = "STAND")
d0 <- if (nrow(z0)) max(abs(z0$TPH_all - z0$TPH_all_o)/pmax(1, z0$TPH_all_o), abs(z0$BAPH - z0$BA4_o)/pmax(1, z0$BA4_o)) else Inf
G("G2", sprintf("worst scaled age 0 difference %.3g over %d stand arms", d0, nrow(z0)), "<= 1e-6 and all stand arms present", d0 <= 1e-6 && nrow(z0) == NST*2L, "measured qc_c t1 tree list (md5 6fb1ff68)")
harness_ok <- all(sapply(gates, function(x) x$pass))
## ---------------- relations and NI ----------------
REL <- rbindlist(lapply(ARMS, function(ar) { x <- TR[arm == ar]; if (!nrow(x)) return(NULL); r <- relations(x); r[, arm := ar]; r })); setcolorder(REL, "arm")
A <- merge(REL[arm == CAND], REL[arm == REF], by = c("relation","unit"), suffixes = c("", "_ref")); A[, newflag := flag & !flag_ref]
B <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0, ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0,
  ref_not_evaluated = sum(!evaluated_ref), cand_not_evaluated = sum(!evaluated)), by = relation]
B[, marginB_ok := cand_flags == 0 | cand_worst <= ref_worst + 1e-9][, ni_ok := new_flags == 0 & marginB_ok]
for (i in seq_len(nrow(B))) with(B[i], G(sprintf("NI %s", relation), sprintf("flags p38_fit %d, qc141 %d, new %d; worst margin p38_fit %.4g, qc141 %.4g", cand_flags, ref_flags, new_flags, cand_worst, ref_worst),
  "no new flag; candidate worst margin <= qc141 worst", ni_ok, "PREREG44 relations"))
NI_ok <- all(B$ni_ok)
## ---------------- realism and site ordering of growth (reported, not gated) ----------------
RL <- dcast(TR[age %in% c(0, 50, 100), .(arm, cell, esi_bin, sdi_bin, esi, age, HT, TPH, VOL)], cell + esi_bin + sdi_bin + esi + age ~ arm, value.var = c("HT","TPH","VOL"))
RL[, HT_ratio := HT_p38_fit/HT_qc141][, TPH_ratio := TPH_p38_fit/TPH_qc141][, VOL_ratio := VOL_p38_fit/VOL_qc141]
GR <- TR[age %% 5 == 0, .(esi_bin, sdi_bin, age, dHT = HT - HT[age == 0], dVOL = VOL - VOL[age == 0]), by = .(arm, cell)][, .(dHT = mean(dHT), dVOL = mean(dVOL)), by = .(arm, esi_bin, sdi_bin, age)]
GI <- GR[age > 0, .(inv_dHT = sum(is.unsorted(dHT[order(esi_bin)])), inv_dVOL = sum(is.unsorted(dVOL[order(esi_bin)]))), by = .(arm, sdi_bin, age)][, .(inv_dHT = sum(inv_dHT), inv_dVOL = sum(inv_dVOL)), by = .(arm, sdi_bin)]
DM <- TR[age %in% c(0, 1, 25, 50, 100), .(DHTM_cohort_min = min(as.numeric(DHTM_cohort), na.rm = TRUE), DHTM_cohort_max = max(as.numeric(DHTM_cohort), na.rm = TRUE),
  DHTM_ing_min = suppressWarnings(min(as.numeric(DHTM_ing), na.rm = TRUE)), DHTM_ing_max = suppressWarnings(max(as.numeric(DHTM_ing), na.rm = TRUE))), by = .(arm, age)]
## ---------------- write ----------------
TRo <- copy(TR)[, STAND := NULL]
fn <- file.path(OD, sprintf("gyr142-p44-traj-annual_SERVERONLY_%s.csv", DT)); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(TR, fn)
files <- c(wr(rbindlist(gates), "gates_DATA.csv"), wr(REL, "relations_DATA.csv"), wr(A, "relations-paired_DATA.csv"), wr(B, "ni-by-relation_DATA.csv"),
  wr(TRo[age %% 5 == 0], "traj-5yr_DATA.csv"), wr(RL, "realism_DATA.csv"), wr(GR, "growth-binmeans_DATA.csv"), wr(GI, "growth-siteorder_DATA.csv"), wr(DM, "dhtmult_DATA.csv"))
outcome <- if (!harness_ok) "RULE1_HARNESS_FAILURE" else if (!NI_ok) "RULE2_NOT_CLEARED" else "RULE3_CLEARED"
V <- c(sprintf("plan_md5=%s", Sys.getenv("P44_PLAN_MD5", "unset")), sprintf("outcome=%s", outcome), sprintf("harness_ok=%s NI_ok=%s", harness_ok, NI_ok),
  sprintf("stands=%d new_flags=%d", NST, sum(A$newflag)), sprintf("new_flag_units=%s", paste(A[newflag == TRUE, paste(relation, unit, sep = ":")], collapse = ";")),
  sprintf("marginB_fail_relations=%s", paste(B[marginB_ok == FALSE, relation], collapse = ";")),
  sprintf("reineke_not_evaluated qc141=%d p38_fit=%d of %d", REL[arm == REF & relation == "Reineke", sum(!evaluated)], REL[arm == CAND & relation == "Reineke", sum(!evaluated)], NST),
  sprintf("HT_ratio_50=%.3f..%.3f HT_ratio_100=%.3f..%.3f VOL_ratio_100=%.3f..%.3f", min(RL[age == 50]$HT_ratio), max(RL[age == 50]$HT_ratio), min(RL[age == 100]$HT_ratio), max(RL[age == 100]$HT_ratio), min(RL[age == 100]$VOL_ratio), max(RL[age == 100]$VOL_ratio)),
  "decision_weight=informs 14.3 only; cannot reopen the 14.2 QC decision (Aaron, 5 October 2026)")
vf <- f("verdict_DATA.txt"); if (file.exists(vf)) stop("REFUSE ", vf); writeLines(V, vf)
print(rbindlist(gates)); print(B); print(GI); cat(V, sep = "\n"); cat("ASSEMBLY_DONE\n")
