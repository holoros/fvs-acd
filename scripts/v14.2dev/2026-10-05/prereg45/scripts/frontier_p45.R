## PREREG45 credibility bound, computed before registration from measured data only: relative top height TOPHT/esi8 over
## admitted qc_c stands (esi8 finite and above 2), t1 and observed t2 visits, frozen p19_a0111 results (observed columns only).
## Aggregates only. No coordinates. No em dashes.
suppressMessages(library(data.table))
f <- "/home/aaron/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"
x <- fread(f); x <- x[is.finite(esi8) & esi8 > 2]
cat("md5", tools::md5sum(f), "admitted", nrow(x), "\n"); if (nrow(x) != 378) stop("admitted count not 378")
r <- c(x$TOPHT_t1 / x$esi8, x$TOPHT_o / x$esi8); r <- r[is.finite(r) & r > 0]
q <- quantile(r, c(.5, .9, .95, .99, 1))
out <- data.table(source = "qc_c admitted stands, measured t1 and t2 TOPHT over esi8, frozen p19_a0111 observed columns", n_visits = length(r),
  q50 = q[1], q90 = q[2], q95 = q[3], q99 = q[4], max = q[5], bound = round(q[4], 3), md5_input = unname(tools::md5sum(f)))
print(out); fwrite(out, "plan/frontier_p45_DATA.csv")
