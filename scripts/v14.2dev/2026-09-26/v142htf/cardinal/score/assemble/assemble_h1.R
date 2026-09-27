## PREREG11: assemble firebreather chunk results into results/<col>/gyr_<col>_<set>_results.csv (header once, chunks in
## order) and evaluate H1 (no run failures). Column given as argv[1], source dir argv[2]. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths())); suppressMessages(library(data.table))
a <- commandArgs(TRUE); col <- a[1]; src <- a[2]; H <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix"
tm <- fread(file.path(H, "work/htfix_taskmap_DATA_2026-09-26.csv"))[arm == col]
out <- file.path(H, "results", col); dir.create(out, recursive = TRUE, showWarnings = FALSE)
R <- rbindlist(lapply(split(tm, tm$set), function(x) { x <- x[order(chunk)]
  f <- file.path(src, x$set[1], sprintf("c%03d_results.csv", x$chunk)); stopifnot(all(file.exists(f)))
  d <- rbindlist(lapply(f, fread), use.names = TRUE)
  n_exp <- sum(x$to - x$from + 1)
  of <- file.path(out, sprintf("gyr_%s_%s_results.csv", col, x$set[1])); stopifnot(!file.exists(of)); fwrite(d, of)
  data.table(set = x$set[1], chunks = nrow(x), rows = nrow(d), rows_expected = n_exp, run_fail = sum(d$RUN_OK != 1, na.rm = TRUE), run_na = sum(is.na(d$RUN_OK)), md5 = unname(tools::md5sum(of))) }))
print(R); h1 <- R[, all(run_fail == 0 & run_na == 0 & rows == rows_expected)]
cat(sprintf("H1 %s (%s)\n", if (h1) "PASS" else "FAIL", col)); fwrite(R, file.path(H, sprintf("score/assemble/gyr142-htfix-h1-%s_DATA_2026-09-26.csv", col)))
