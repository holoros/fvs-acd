## v143_gates.R
## 14.3 pre-registration 1 (md5 7f3e67c2), harness gates of rule 1: E0, E0b, E0c, CAP, TR, K1, TH. Compares new arm
## output with the frozen 16 October and 25 September 14.1 output, file by file and stand by stand, and never reruns or
## writes into a frozen directory. Writes out/gates_v143_DATA.csv (aggregates only).
## Usage: Rscript v143_gates.R <root> <part: e0|e0c|tr|k1|all> [frozen-root-override for the dry run]
## No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; PART <- a[2]; FZ <- if (length(a) > 2) a[3] else ""
H <- "/users/PUOM0008/crsfaaron"
B141 <- if (nzchar(FZ)) file.path(FZ, "bench141") else file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/out")
PH <- if (nzchar(FZ)) file.path(FZ, "postharv") else file.path(H, "acdx_20261016/postharv/out")
L2 <- if (nzchar(FZ)) file.path(FZ, "long200") else file.path(H, "acdx_20261016/long200/out")
BAK <- if (nzchar(FZ)) file.path(FZ, "bak141") else file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bak141/out")
O <- file.path(ROOT, "out"); W <- file.path(ROOT, "work")
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
             max_abs_diff = suppressWarnings(max(r$mad, na.rm = TRUE)), n_new_missing = sum(r$missing))
}
G <- list()
if (PART %in% c("e0", "all")) {
  for (s in list.dirs(file.path(O, "e0off"), recursive = FALSE, full.names = FALSE)) if (s != "counters")
    G[[length(G) + 1]] <- cmp_dir(file.path(O, "e0off", s), frozen141(s), "E0")
  for (s in list.dirs(file.path(O, "e0b"), recursive = FALSE, full.names = FALSE)) if (s != "counters")
    G[[length(G) + 1]] <- cmp_dir(file.path(O, "e0b", s), frozen141(s), "E0b")
  ## grid: the overlay off reproduces the frozen 14.1 thinned grid, and A0 reproduces the frozen 14.1 L only grid
  for (arm in c("e0off", "A0")) {
    ref <- if (arm == "e0off") "v141LT" else "v141L"
    r <- rbindlist(lapply(0:19, function(c) { fo <- file.path(BAK, sprintf("traj_thin_%s_cell%02d.csv", ref, c))
      fn <- file.path(O, "grid", arm, sprintf("traj_thin_v143%s_cell%02d.csv", arm, c))
      if (!file.exists(fn) || !file.exists(fo)) return(data.table(eq = FALSE, mad = NA_real_))
      x <- fread(fo)[, !"config"]; y <- fread(fn)[, !"config"]
      num <- names(x)[sapply(x, is.numeric)]
      data.table(eq = isTRUE(all.equal(x, y, check.attributes = FALSE, tolerance = 0)),
                 mad = if (nrow(x) == nrow(y)) max(sapply(num, function(k) max(abs(x[[k]] - y[[k]]), na.rm = TRUE))) else NA_real_) }))
    G[[length(G) + 1]] <- data.table(gate = if (arm == "e0off") "E0" else "A0grid_vs_v141L", unit = "grid", files = 20L, identical_md5 = NA,
      identical_data = all(r$eq), max_abs_diff = suppressWarnings(max(r$mad, na.rm = TRUE)), n_new_missing = sum(is.na(r$mad)))
  }
}
if (PART %in% c("e0c", "all")) G[[length(G) + 1]] <- cmp_dir(file.path(O, "e0c", "mefia_l_c"), file.path(L2, "v141LT", "mefia_l_c"), "E0c")
if (PART %in% c("tr", "all")) {
  cf <- readRDS(if (nzchar(FZ)) file.path(FZ, "coefs.rds") else file.path(H, "magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds"))
  st <- fread(file.path(W, "tr_stands_SERVERONLY.csv"))
  tf <- list.files(file.path(O, "trA3", "mefia_ph_c"), pattern = "^trace_c[0-9]{3}_SERVERONLY\\.rds$", full.names = TRUE)
  tsf <- if (nzchar(FZ)) file.path(ROOT, "inputs", "mefia_ph_tst_mefia_ph_c_DATA_2026-10-16.csv") else file.path(H, "acdx_20261016/postharv/work/mefia_ph_tst_mefia_ph_c_DATA_2026-10-16.csv")
  TS <- fread(tsf, colClasses = list(character = "TST"))[, .(KEY = STAND, TSTN = suppressWarnings(as.numeric(TST)))]
  ok <- FALSE; msg <- "no trace"
  if (length(tf) == 1L) {
    tr <- readRDS(tf); ca <- as.data.table(tr$calls); mt <- as.data.table(tr$mT)
    cap <- 2.9848
    mt[, MT_F := 1 + cf$alpha * exp(-cf$beta * TST) * pmin(D / DQ, cap)^cf$gamma]
    el <- st[TR_GROUP == "eligible", STAND]; ie <- st[TR_GROUP == "ineligible", STAND]
    e_err <- if (nrow(mt[KEY %in% el])) max(abs(mt[KEY %in% el, MT - MT_F])) else Inf
    ## the tst and Dq that reached m_T are the ones the runner and the tree list imply: tst = TSTN + (year - 1) at the start
    ## of each step, and Dq recomputed independently from the traced tree list of that call
    ca <- merge(ca, TS, by = "KEY", all.x = TRUE)
    tst_ok <- ca[KEY %in% c(el, ie), { u <- sort(unique(TST_IN)); length(u) >= 3 && isTRUE(all(abs(u - (TSTN[1] + seq_along(u) - 1)) < 1e-12)) }, by = KEY][, all(V1)]
    mj <- merge(mt, ca[, .(CALL, TST_IN, DQ_LIST)], by = "CALL")
    arg_ok <- nrow(mj) == nrow(mt) && mj[, all(abs(TST - TST_IN) < 1e-12 & abs(DQ - DQ_LIST) < 1e-9)]
    ## each eligible stand traced over its first 3 years: tst at the start of the step advances by one each year
    yrs_e <- ca[KEY %in% el, .(ny = uniqueN(TST_IN[is.finite(TST_IN)])), by = KEY]
    n_ie_mT <- nrow(mt[KEY %in% ie])
    yrs_i <- ca[KEY %in% ie, .(ny = uniqueN(TST_IN[is.finite(TST_IN)]), all0 = all(ELIG == 0L)), by = KEY]
    ok <- is.finite(e_err) && e_err <= 1e-12 && isTRUE(tst_ok) && isTRUE(arg_ok) && nrow(yrs_e) == 4L && all(yrs_e$ny >= 3) && n_ie_mT == 0L && nrow(yrs_i) == 4L && all(yrs_i$ny >= 3) && all(yrs_i$all0)
    msg <- sprintf("tst sequence ok %s; mT arguments match the call (tst, Dq) %s; eligible max |mT - formula| %.3e over %d calls; eligible stands traced %d (min years %s); ineligible mT calls %d; ineligible stands traced %d",
                   tst_ok, arg_ok, e_err, nrow(mt[KEY %in% el]), nrow(yrs_e), if (nrow(yrs_e)) min(yrs_e$ny) else NA, n_ie_mT, nrow(yrs_i))
  }
  G[[length(G) + 1]] <- data.table(gate = "TR", unit = "mefia_ph_c", files = length(tf), identical_md5 = NA, identical_data = ok, max_abs_diff = NA_real_, n_new_missing = NA_integer_, note = msg)
}
if (PART %in% c("k1", "all")) {
  for (arm in list.dirs(O, recursive = FALSE, full.names = FALSE)) {
    if (arm %in% c("grid", "trA3")) next
    for (s in list.dirs(file.path(O, arm), recursive = FALSE, full.names = FALSE)) { if (s == "counters") next
      fs <- list.files(file.path(O, arm, s), pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE); if (!length(fs)) next
      d <- rbindlist(lapply(fs, fread, select = c("STAND", "RUN_OK", "FAIL_REASON")))
      ref <- if (arm == "e0c") file.path(L2, "v141LT", s) else frozen141(s)
      r <- rbindlist(lapply(list.files(ref, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE), fread, select = c("STAND", "RUN_OK", "FAIL_REASON")))
      m <- merge(d, r, by = "STAND", all = TRUE, suffixes = c("", "_141"))
      G[[length(G) + 1]] <- data.table(gate = "K1", unit = paste(arm, s), files = length(fs), identical_md5 = NA,
        ## K1: RUN_OK other than 1 must be 0, except a stand that failed identically (same FAIL_REASON) in the frozen 14.1
        ## run, which no rerun can change (pre projection failures such as lt3trees); the PREREG38 retry rule is not
        ## re-implemented here, so this exemption is logged as the reading of that rule
        identical_data = m[!is.na(RUN_OK) & !(RUN_OK %in% 1L) & !(RUN_OK_141 %in% RUN_OK & FAIL_REASON == FAIL_REASON_141), .N] == 0L, max_abs_diff = NA_real_,
        n_new_missing = m[is.na(RUN_OK), .N], note = sprintf("RUN_OK not 1: %d (frozen 14.1: %d); stands %d", m[!(RUN_OK %in% 1L) & !is.na(RUN_OK), .N], m[!(RUN_OK_141 %in% 1L), .N], nrow(d)))
    }
  }
  ## CAP is asserted by the overlay at every load; its log line is collected here
  ## every task that reached R with the overlay (launcher start line present; dry run reference arms excluded) must carry
  ## the CAP line; a CAP failure stops the overlay before its loaded line, so selection is by the launcher's start line
  lg <- list.files(file.path(ROOT, "logs"), pattern = "^v143(arm|grid|L200)_.*\\.out$", full.names = TRUE)
  lg <- lg[vapply(lg, function(f) { x <- readLines(f, warn = FALSE)
    st <- grep("^\\[v143(arm|grid|L200)\\] (COL|ARM)=", x, value = TRUE)
    length(st) > 0 && !any(grepl("(COL|ARM)=(ref141|refL2|refL) ", st)) }, logical(1))]
  capok <- vapply(lg, function(f) any(grepl("^v143 CAP ok", readLines(f, warn = FALSE))), logical(1))
  G[[length(G) + 1]] <- data.table(gate = "CAP", unit = "all logs", files = length(lg), identical_md5 = NA, identical_data = length(lg) > 0 && all(capok),
    max_abs_diff = NA_real_, n_new_missing = sum(!capok), note = "V141_RELCAP 2.9848 against rds rel_cap at 4 decimals")
  thf <- file.path(ROOT, "logs/th_md5.txt")
  G[[length(G) + 1]] <- data.table(gate = "TH", unit = "logs/th_md5.txt", files = as.integer(file.exists(thf)), identical_md5 = NA,
    identical_data = file.exists(thf) && all(vapply(strsplit(trimws(readLines(thf)), "[[:space:]]+"), function(z) identical(unname(as.character(tools::md5sum(file.path(ROOT, z[2])))), z[1]), logical(1))),
    max_abs_diff = NA_real_, n_new_missing = NA_integer_, note = "every TH file still matches its recorded md5; written before any arm output (checked by thresholds_v143.R)")
}
R <- rbindlist(G, fill = TRUE)
of <- file.path(O, sprintf("gates_v143_%s_DATA.csv", PART)); if (file.exists(of)) of <- sub("_DATA\\.csv$", sprintf("_%s_DATA.csv", format(Sys.time(), "%Y%m%dT%H%M%S")), of)
fwrite(R, of); print(R); cat(sprintf("%s  %s\nGATES_DONE\n", unname(tools::md5sum(of)), of))
