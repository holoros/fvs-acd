## v143p4_cmp.R, PREREG4 (md5 a15bd92a) identity checks H1a, H1b, H2. Adapted from the acdx arms check cmp_arms_r0.R: every
## common numeric column of results, per tree predictions, pd files, t1 split lists and trajectories, but chunks are
## CONCATENATED and compared BY STAND on the arm's stand set (frozen outputs filtered to it), so keep-file runs compare too.
## Also counts stands run (RUN_OK) in each (gate H7). Aggregates only, no identifiers printed.
## Usage: Rscript v143p4_cmp.R <frozen_dir> <arm_dir> <label> <out_csv>. Refuses to overwrite. No em dashes.
suppressMessages(library(data.table))
a <- commandArgs(TRUE); FZ <- a[1]; AD <- a[2]; LB <- a[3]; OUT <- a[4]
if (file.exists(OUT)) stop("REFUSE ", OUT)
skip <- c("CONFIG_TAG", "config_tag", "RUN_TIME", "run_time", "elapsed", "ELAPSED", "host", "HOST", "start", "end", "GYR_lasterr", "ERR", "err")
kinds <- c(results = "_results.csv$", pred_t2_tree = "_pred_t2_tree.csv$", pred_yr1_tree = "_pred_yr1_tree.csv$", pd_t1 = "_pd_t1.csv$",
           pd_t2 = "_pd_t2.csv$", t1_split_tree = "_t1_split_tree.csv$", traj = "_traj.csv$")
rd <- function(d, p) { f <- list.files(d, p, full.names = TRUE); if (!length(f)) return(NULL); rbindlist(lapply(f, fread), fill = TRUE) }
ra <- rd(AD, kinds[["results"]]); rf <- rd(FZ, kinds[["results"]])
if (is.null(ra) || is.null(rf)) stop("no results files in one of the directories")
st <- unique(ra$STAND); rf <- rf[STAND %in% st]
rows <- list(data.table(label = LB, kind = "completeness", files = NA, rows = length(st), cols = NA, worst_abs = NA_real_, n_diff = NA_integer_,
  char_mismatch = NA_integer_, note = sprintf("stands in arm %d; frozen RUN_OK %d; arm RUN_OK %d; frozen RUN_OK also RUN_OK in arm %d", length(st),
  rf[RUN_OK == 1, uniqueN(STAND)], ra[RUN_OK == 1, uniqueN(STAND)], length(intersect(rf[RUN_OK == 1, STAND], ra[RUN_OK == 1, STAND])))))
for (k in names(kinds)) {
  x <- if (k == "results") rf else { z <- rd(FZ, kinds[[k]]); if (is.null(z)) NULL else z[STAND %in% st] }
  y <- if (k == "results") ra else rd(AD, kinds[[k]])
  if (is.null(x) && is.null(y)) next
  if (is.null(x) || is.null(y) || nrow(x) != nrow(y)) {
    rows[[length(rows) + 1]] <- data.table(label = LB, kind = k, files = NA, rows = if (is.null(y)) 0L else nrow(y), cols = NA, worst_abs = NA_real_, n_diff = NA_integer_,
      char_mismatch = NA_integer_, note = sprintf("row counts differ: frozen %s arm %s", if (is.null(x)) "none" else nrow(x), if (is.null(y)) "none" else nrow(y))); next }
  cc <- setdiff(intersect(names(x), names(y)), skip)
  num <- cc[vapply(cc, function(j) is.numeric(x[[j]]) && is.numeric(y[[j]]), logical(1))]; chr <- setdiff(cc, num)
  key <- unique(c(chr, intersect(c("iv", "yr", "tree", "n_init"), num)))
  setorderv(x, key); setorderv(y, key)
  cm <- sum(vapply(chr, function(j) !identical(as.character(x[[j]]), as.character(y[[j]])), logical(1)))
  wa <- 0; nd <- 0L
  for (j in num) { d <- abs(x[[j]] - y[[j]]); bad <- xor(is.na(x[[j]]), is.na(y[[j]])); d[is.na(d)] <- 0; wa <- max(wa, d); nd <- nd + sum(d > 0) + sum(bad) }
  rows[[length(rows) + 1]] <- data.table(label = LB, kind = k, files = length(list.files(AD, kinds[[k]])), rows = nrow(y), cols = length(num), worst_abs = wa,
    n_diff = nd, char_mismatch = cm, note = "") }
R <- rbindlist(rows, fill = TRUE); print(R); fwrite(R, OUT)
cmpr <- R[kind != "completeness"]
cat(if (nrow(cmpr) && all(cmpr$note == "") && all(cmpr$n_diff == 0) && all(cmpr$char_mismatch == 0)) "IDENTICAL\n" else "DIFFERS\n")
