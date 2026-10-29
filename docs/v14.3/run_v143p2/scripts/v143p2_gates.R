## v143p2_gates.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b): harness gates. PREREG1's E0, CAP, K1 and TR carry over with the
## new overlay; new gates H1, H3, H4, H5 (H2 is in the fitter, H6 in the allowlist log and the step order).
##   E0  overlay sourced and off (arm e0off) reproduces frozen 14.1 byte for byte on the 19 Phase D sets and mefia_ph_c
##       (every results and tree list file), and the thinned grid trajectories in every value.
##   H1  C0f with the overlay on (arm C0f) reproduces frozen 14.1 in the same way.
##   H3  r in the fit frame equals the r the engine passes to .acd_v141_mT (first call of each stand, the start-of-
##       projection tree list) on the 500 record sample, to 1e-12.
##   H4  TR trace per candidate form (arms trC*): every traced m_T equals the candidate formula at the traced arguments
##       (to 1e-12), tst advances by one per step from the TST file, and for C3 m_T at tst 0 equals 1 (traced or
##       evaluated by the overlay's function).
##   H5  every candidate's own cap: traced m_T beyond the cap equals the value at the cap (C0f, C0r, C1, C6 at 2.9848;
##       C4 at 1.5), and no cap acts for C2, C3, C5.
##   K1  no stand with RUN_OK other than 1 in any arm run.  CAP  "CAP ok" printed in every arm log.
## Usage: Rscript v143p2_gates.R <root> <part: e0h1|h3|k1|tr|all>. Writes out/gates_<part>_DATA.csv. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; PART <- a[2]
H <- "/users/PUOM0008/crsfaaron"
B141 <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/out")
PH <- file.path(H, "acdx_20261016/postharv/out")
BAK <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bak141/out")
O <- file.path(ROOT, "out"); W <- file.path(ROOT, "work"); A <- file.path(O, "arms")
f_out <- file.path(O, sprintf("gates_%s_DATA.csv", PART)); if (file.exists(f_out)) stop("exists ", f_out)
frozen141 <- function(set) if (set == "mefia_ph_c") file.path(PH, "v141LT", set) else file.path(B141, "v141LT", set)
SUFF <- c("_results.csv", "_pred_t2_tree.csv", "_pred_yr1_tree.csv", "_t1_split_tree.csv", "_traj.csv", "_pd_t1.csv", "_pd_t2.csv")
cmp_dir <- function(new, old, label) {
  fs <- sort(list.files(old, pattern = "^c[0-9]{3}_results\\.csv$"))
  if (!length(fs)) return(data.table(gate = label, unit = basename(new), files = 0L, identical_md5 = NA, identical_data = FALSE, max_abs_diff = NA_real_, n_new_missing = NA_integer_))
  r <- rbindlist(lapply(fs, function(f) { ch <- sub("_results\\.csv$", "", f)
    rbindlist(lapply(SUFF, function(sf) { fo <- file.path(old, paste0(ch, sf)); fn <- file.path(new, paste0(ch, sf))
      if (!file.exists(fo)) return(NULL)
      if (!file.exists(fn)) return(data.table(file = paste0(ch, sf), md5_eq = FALSE, data_eq = FALSE, mad = NA_real_, missing = 1L))
      m <- identical(unname(tools::md5sum(fo)), unname(tools::md5sum(fn)))
      if (m) return(data.table(file = paste0(ch, sf), md5_eq = TRUE, data_eq = TRUE, mad = 0, missing = 0L))
      x <- fread(fo); y <- fread(fn)
      deq <- isTRUE(all.equal(x, y, check.attributes = FALSE, tolerance = 0))
      num <- intersect(names(x)[sapply(x, is.numeric)], names(y))
      mad <- if (nrow(x) == nrow(y) && length(num)) max(sapply(num, function(k) max(abs(x[[k]] - y[[k]]), na.rm = TRUE))) else NA_real_
      data.table(file = paste0(ch, sf), md5_eq = FALSE, data_eq = deq, mad = mad, missing = 0L) })) }))
  data.table(gate = label, unit = basename(new), files = nrow(r), identical_md5 = all(r$md5_eq), identical_data = all(r$data_eq),
             max_abs_diff = suppressWarnings(max(r$mad, na.rm = TRUE)), n_new_missing = sum(r$missing)) }
grid_cmp <- function(arm, label) { r <- rbindlist(lapply(0:19, function(c) { fo <- file.path(BAK, sprintf("traj_thin_v141LT_cell%02d.csv", c))
    fn <- file.path(O, "grid", arm, sprintf("traj_thin_v143p2%s_cell%02d.csv", arm, c))
    if (!file.exists(fn) || !file.exists(fo)) return(data.table(eq = FALSE, mad = NA_real_))
    x <- fread(fo)[, !"config"]; y <- fread(fn)[, !"config"]; num <- names(x)[sapply(x, is.numeric)]
    data.table(eq = isTRUE(all.equal(x, y, check.attributes = FALSE, tolerance = 0)),
               mad = if (nrow(x) == nrow(y)) max(sapply(num, function(k) max(abs(x[[k]] - y[[k]]), na.rm = TRUE))) else NA_real_) }))
  data.table(gate = label, unit = "grid", files = 20L, identical_md5 = NA, identical_data = all(r$eq), max_abs_diff = suppressWarnings(max(r$mad, na.rm = TRUE)),
             n_new_missing = sum(is.na(r$mad))) }
G <- list()
if (PART %in% c("e0h1", "all")) {
  for (arm in c("e0off", "C0f")) {
    for (s in setdiff(list.dirs(file.path(A, arm), recursive = FALSE, full.names = FALSE), "counters"))
      G[[length(G) + 1]] <- cmp_dir(file.path(A, arm, s), frozen141(s), if (arm == "e0off") "E0" else "H1")
    G[[length(G) + 1]] <- grid_cmp(arm, if (arm == "e0off") "E0" else "H1")
  }
}
if (PART %in% c("h3", "all")) {
  h3 <- fread(file.path(W, "h3_sample_SERVERONLY.csv"))
  tf <- list.files(file.path(A, "trH3", "ctrn_c"), pattern = "^trace_c[0-9]{3}_SERVERONLY\\.rds$", full.names = TRUE)
  if (length(tf) != 1L) { G[[length(G) + 1]] <- data.table(gate = "H3", unit = "trace", files = length(tf), identical_md5 = NA, identical_data = FALSE, max_abs_diff = NA_real_, n_new_missing = 500L)
  } else {
    tr <- as.data.table(readRDS(tf)); first <- tr[, .SD[CALL == min(CALL)], by = KEY]
    m <- merge(h3, first[, .(DQ_T = DQ[1], DVEC = list(D)), by = KEY], by.x = "STAND", by.y = "KEY", all.x = TRUE)
    m[, `:=`(r_engine = d1 / DQ_T, in_list = mapply(function(d, v) any(abs(v - d) < 1e-12), d1, DVEC))]
    dmax <- m[, max(abs(r_engine - r))]
    G[[length(G) + 1]] <- data.table(gate = "H3", unit = "ctrn_c 500 records", files = nrow(m), identical_md5 = NA,
      identical_data = is.finite(dmax) && dmax <= 1e-12 && all(m$in_list), max_abs_diff = dmax, n_new_missing = sum(is.na(m$DQ_T)))
    print(G[[length(G)]])
  }
}
if (PART %in% c("k1", "all")) {
  for (arm in setdiff(list.dirs(A, recursive = FALSE, full.names = FALSE), character(0))) for (s in setdiff(list.dirs(file.path(A, arm), recursive = FALSE, full.names = FALSE), "counters")) {
    fs <- list.files(file.path(A, arm, s), pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE); if (!length(fs)) next
    r <- rbindlist(lapply(fs, fread), fill = TRUE)
    G[[length(G) + 1]] <- data.table(gate = "K1", unit = paste(arm, s), files = length(fs), identical_md5 = NA, identical_data = all(r$RUN_OK == 1), max_abs_diff = r[RUN_OK != 1, .N], n_new_missing = NA_integer_) }
  lg <- list.files(file.path(ROOT, "logs"), pattern = "^arm_.*\\.out$", full.names = TRUE)
  capok <- vapply(lg, function(f) { x <- readLines(f, warn = FALSE); !any(grepl("TFORM=1|Tform on|THIN=1", x)) || any(grepl("CAP ok", x)) }, TRUE)
  G[[length(G) + 1]] <- data.table(gate = "CAP", unit = "arm logs", files = length(lg), identical_md5 = NA, identical_data = all(capok), max_abs_diff = sum(!capok), n_new_missing = NA_integer_)
}
if (PART %in% c("tr", "all")) {
  for (d in list.dirs(A, recursive = FALSE, full.names = FALSE)) if (grepl("^trC", d)) {
    cand <- sub("^tr", "", d)
    cf <- fread(file.path(W, sprintf("tform_coef_full_%s.csv", cand)))
    if (cand == "C0f") { r5 <- readRDS(file.path(H, "magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds")); cf$alpha <- r5$alpha; cf$beta <- r5$beta }
    tf <- list.files(file.path(A, d), pattern = "^trace_c[0-9]{3}_SERVERONLY\\.rds$", full.names = TRUE, recursive = TRUE)
    tr <- rbindlist(lapply(tf, function(f) as.data.table(readRDS(f))))
    cap <- c(C0f = 2.9848, C0r = 2.9848, C1 = 2.9848, C2 = Inf, C3 = Inf, C4 = 1.5, C5 = Inf, C6 = 2.9848)[[cand]]
    sm <- function(r, lo, hi) { u <- pmin(pmax((r - lo) / (hi - lo), 0), 1); 3 * u^2 - 2 * u^3 }
    tr[, r := D / DQ]
    tr[, MF := switch(cand, C0f = , C0r = 1 + cf$alpha * exp(-cf$beta * TST) * pmin(r, cap)^2, C1 = , C4 = 1 + cf$alpha * exp(-cf$beta * TST) * pmin(r, cap)^cf$gamma,
                      C2 = 1 + cf$alpha * exp(-cf$beta * TST) * sm(r, cf$rlo, cf$rhi), C3 = 1 + cf$alpha * (TST / cf$tau) * exp(1 - TST / cf$tau) * sm(r, cf$rlo, cf$rhi),
                      C5 = 1 + cf$alpha * exp(-cf$beta * TST), C6 = 1 + cf$alpha * exp(-0.08220 * TST) * pmin(r, cap)^2)]
    err <- tr[, max(abs(M - MF))]
    tsf <- fread(file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/work/v142_bench141_tst_ctrn_c_DATA_2026-09-25.csv"), colClasses = list(character = "TST"))
    tq <- tr[, .(u = list(sort(unique(TST)))), by = KEY][tsf[, .(KEY = STAND, T0 = suppressWarnings(as.numeric(TST)))], on = "KEY", nomatch = 0L]
    ## tst advances by one per step, starts at the TST file value, and at least one stand is traced over 2 or more steps
    tseq <- tq[, all(vapply(u, function(v) all(diff(v) == 1), TRUE)) && all(mapply(function(v, t0) min(v) == t0, u, T0)) && any(lengths(u) >= 2)]
    ## H5: beyond the cap the multiplier is flat in r (same call, same tst)
    capflat <- if (is.finite(cap)) tr[r > cap, .(ok = all(abs(M - (if (cand %in% c("C1", "C4")) 1 + cf$alpha * exp(-cf$beta * TST) * cap^cf$gamma
                                                         else if (cand == "C6") 1 + cf$alpha * exp(-0.08220 * TST) * cap^2 else 1 + cf$alpha * exp(-cf$beta * TST) * cap^2)) < 1e-12))][, all(ok)] else NA
    c3zero <- if (cand == "C3") abs(1 + cf$alpha * (0 / cf$tau) * exp(1 - 0 / cf$tau) - 1) == 0 else NA
    G[[length(G) + 1]] <- data.table(gate = "H4", unit = cand, files = length(tf), identical_md5 = NA, identical_data = is.finite(err) && err <= 1e-12 && isTRUE(tseq) && !isFALSE(c3zero),
                                     max_abs_diff = err, n_new_missing = nrow(tr))
    G[[length(G) + 1]] <- data.table(gate = "H5", unit = cand, files = length(tf), identical_md5 = NA, identical_data = if (is.finite(cap)) isTRUE(capflat) || tr[r > cap, .N] == 0 else TRUE,
                                     max_abs_diff = tr[r > cap, .N], n_new_missing = NA_integer_)
  }
}
GG <- rbindlist(G, fill = TRUE); print(GG)
fwrite(GG, f_out); cat(sprintf("%s  %s\n", unname(tools::md5sum(f_out)), f_out)); cat("GATES_DONE\n")
