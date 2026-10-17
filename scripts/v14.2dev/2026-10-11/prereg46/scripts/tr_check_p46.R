## PREREG46 trace gate TR (ST1 design, now registered): recompute every traced dht.mult from ht/cs with the fitted rounded a and b,
## the arm's form and the fill rule. Pass: worst absolute difference below 1e-12; no ingrowth row carries m = 1 unless m(r) is 1;
## every tree with r at or above the zero carries m = 0. Writes aggregates only.
suppressMessages(library(data.table)); a <- commandArgs(TRUE); arm <- a[1]
F <- fread("/home/aaron/jobs/v142p46/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv")
A <- F[arm == a[1] & param == "a", value_rounded]; B <- F[arm == a[1] & param == "b", value_rounded]; RMAX <- 1.285; CSI_DEFAULT <- 14
mf <- function(r) if (arm == "qc_lz") pmax(0, A + B * r) else exp(A + B * r) * pmax(0, 1 - r / RMAX)
zero <- if (arm == "qc_lz") -A / B else RMAX
x <- fread(a[2], colClasses = list(character = "STAND"))
x[, cs := fifelse(is.finite(csi_site) & csi_site > 2, csi_site, CSI_DEFAULT)][, ok := is.finite(ht) & ht > 0][, me := mf(ht / cs)]
x[, fill := { k <- ok & expf > 0; if (any(k)) sum(me[k] * expf[k]) / sum(expf[k]) else mf(0.815) }, by = call]
x[, exp_m := fifelse(ok, me, fill)]; fc <- x[, .(c0 = min(call)), by = STAND]; x <- merge(x, fc, by = "STAND")
n0 <- x[call == c0, .(n_init = max(tree)), by = STAND]; x <- merge(x, n0, by = "STAND"); x[, ing := tree > n_init]
out <- data.table(gate = "TR", arm = arm, a = A, b = B, zero_r = zero, calls = uniqueN(x$call), rows = nrow(x), worst_abs_diff = max(abs(x$m - x$exp_m)),
  ingrowth_rows = x[ing == TRUE, .N], ingrowth_m1_not_expected = x[ing == TRUE & ok & abs(m - 1) < 1e-12 & abs(me - 1) >= 1e-12, .N],
  rows_at_or_above_zero = x[ok & ht / cs >= zero, .N], rows_at_or_above_zero_m_not0 = x[ok & ht / cs >= zero & m != 0, .N], m_min = min(x$m), m_max = max(x$m))
out[, `:=`(ingrowth_exercised = ingrowth_rows > 0, zero_exercised = rows_at_or_above_zero > 0)]  # reported; FALSE is logged as a deviation, not a failure
out[, pass := worst_abs_diff < 1e-12 & ingrowth_m1_not_expected == 0 & rows_at_or_above_zero_m_not0 == 0]
print(out); fwrite(out, a[3]); if (!out$pass) quit(status = 1)
