## PREREG49 NS measured frontier (choice 3a: reported, not gated), built as frontier_p45.R (3c946234) does for QC: relative top
## height TOPHT/esi8 over admitted ns_c stands (esi8 finite and above 2; the runner INDOMAIN rule, 5731 stands as in the PREREG22
## taskmap), t1 and observed t2 visits, frozen v141LTfi results (observed columns only, md5 9fe608de); the 99th percentile,
## rounded to 3 decimals, is the bound. Computed before the draw; its md5 goes to logs/frontier_md5.txt. Aggregates only.
## Usage: Rscript frontier_p49.R OUT. No coordinates. No em dashes.
suppressMessages(library(data.table)); a <- commandArgs(TRUE); if (file.exists(a[1])) stop("REFUSE ", a[1])
f <- "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_c_results.csv"; m <- unname(tools::md5sum(f)); if (m != "9fe608de2e4261bd60d637019c83022e") stop("md5 ", f)
x <- fread(f); x <- x[is.finite(esi8) & esi8 > 2]
cat("md5", m, "admitted", nrow(x), "\n"); if (nrow(x) != 5731) stop("admitted count not 5731")
r <- c(x$TOPHT_t1 / x$esi8, x$TOPHT_o / x$esi8); r <- r[is.finite(r) & r > 0]
q <- quantile(r, c(.5, .9, .95, .99, 1))
out <- data.table(source = "ns_c admitted stands, measured t1 and t2 TOPHT over esi8, frozen v141LTfi observed columns", n_visits = length(r),
  q50 = q[1], q90 = q[2], q95 = q[3], q99 = q[4], max = q[5], bound = round(q[4], 3), md5_input = m)
print(out); fwrite(out, a[1])
