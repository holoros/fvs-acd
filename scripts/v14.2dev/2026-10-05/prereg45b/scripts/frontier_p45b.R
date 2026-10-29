## PREREG45b gate C bound and fill value, from measured data only: TOPHT/esi8 over nb_c stands (esi8 above 2) at t1 and at
## t2 where the t2 list is not empty (TOTVOL_o above 0), frozen v141LT observed columns. Aggregates only. No em dashes.
suppressMessages(library(data.table))
f <- "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv"
if (unname(tools::md5sum(f)) != "97ac93f026c408b50304f71bed4133b3") stop("md5"); O <- "/home/aaron/jobs/v142p45b/plan/frontier_p45b_DATA.csv"; if (file.exists(O)) stop("REFUSE")
x <- fread(f)[is.finite(esi8) & esi8 > 2]; r <- c(x$TOPHT_t1 / x$esi8, x[TOTVOL_o > 0]$TOPHT_o / x[TOTVOL_o > 0]$esi8); r <- r[is.finite(r) & r > 0]
q <- quantile(r, c(.5, .9, .95, .99, 1))
out <- data.table(source = "nb_c stands esi8 above 2, t1 and non empty t2 TOPHT over esi8, frozen v141LT observed columns", stands = nrow(x), n_visits = length(r),
  q50 = q[1], q90 = q[2], q95 = q[3], q99 = q[4], max = q[5], bound = round(q[4], 3), rfill = round(q[1], 3))
print(out); fwrite(out, O)
