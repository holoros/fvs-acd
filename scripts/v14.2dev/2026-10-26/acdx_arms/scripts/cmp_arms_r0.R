## acdx arms identity check (26 October 2026): each arm's chunk outputs against the frozen v141LT outputs of the same frame.
## Compares every common numeric column of c*_results.csv and c*_pred_t2_tree.csv (and c*_traj files when present) after
## ordering by all character key columns. Aggregates only: prints counts and worst absolute differences, no identifiers.
## Usage: Rscript cmp_arms.R <frozen_dir> <arm_dir> <label> <out_csv>. No em dashes.
suppressMessages(library(data.table))
a <- commandArgs(TRUE); FZ <- a[1]; AD <- a[2]; LB <- a[3]; OUT <- a[4]
if (file.exists(OUT)) stop("REFUSE ", OUT)
skip <- c("CONFIG_TAG", "config_tag", "RUN_TIME", "run_time", "elapsed", "ELAPSED", "host", "HOST", "start", "end", "GYR_lasterr", "ERR", "err")
pats <- c("_results.csv$", "_pred_t2_tree.csv$", "_pd_t1.csv$", "_pd_t2.csv$", "_traj.*csv$")
rows <- list()
for (pt in pats) {
  ff <- sort(list.files(FZ, pt)); fa <- sort(list.files(AD, pt))
  if (!length(ff) && !length(fa)) next
  if (!identical(ff, fa)) { rows[[length(rows) + 1]] <- data.table(label = LB, kind = pt, files = length(fa), files_frozen = length(ff), rows = NA, cols = NA, worst_abs = NA, n_diff = NA, char_mismatch = NA, note = "file sets differ"); next }
  wa <- 0; nd <- 0L; nr <- 0L; nc <- 0L; cm <- 0L
  for (f in ff) {
    x <- fread(file.path(FZ, f)); y <- fread(file.path(AD, f))
    cc <- setdiff(intersect(names(x), names(y)), skip)
    if (nrow(x) != nrow(y)) { cm <- cm + 1L; next }
    num <- cc[vapply(cc, function(k) is.numeric(x[[k]]) && is.numeric(y[[k]]), logical(1))]; chr <- setdiff(cc, num)
    if (length(chr)) { ox <- do.call(order, unname(as.list(x[, ..chr]))); oy <- do.call(order, unname(as.list(y[, ..chr]))); x <- x[ox]; y <- y[oy]
      cm <- cm + sum(vapply(chr, function(k) !identical(as.character(x[[k]]), as.character(y[[k]])), logical(1))) }
    for (k in num) { d <- abs(x[[k]] - y[[k]]); bad <- xor(is.na(x[[k]]), is.na(y[[k]])); d[is.na(d)] <- 0
      wa <- max(wa, d); nd <- nd + sum(d > 0) + sum(bad) }
    nr <- nr + nrow(x); nc <- max(nc, length(num)) }
  rows[[length(rows) + 1]] <- data.table(label = LB, kind = pt, files = length(fa), files_frozen = length(ff), rows = nr, cols = nc, worst_abs = wa, n_diff = nd, char_mismatch = cm, note = "") }
R <- rbindlist(rows); print(R); fwrite(R, OUT)
cat(if (nrow(R) && all(R$note == "") && all(R$n_diff == 0) && all(R$char_mismatch == 0)) "IDENTICAL\n" else "DIFFERS\n")
