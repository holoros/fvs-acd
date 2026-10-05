## ST1 (post hoc stress test, not registered): recompute every traced dht.mult from ht/csi with the fitted a, b and the fill
## rule, and count year 0 fills and ingrowth rows. Aggregates only out. No em dashes.
suppressMessages(library(data.table)); a <- 0.9595; b <- -1.1239
x <- fread("/home/aaron/jobs/v142p45st/out/st1_trace_SERVERONLY.csv", colClasses = list(character = "STAND"))
x[, cs := fifelse(is.finite(csi_site) & csi_site > 2, csi_site, 14)][, ok := is.finite(ht) & ht > 0]
x[, me := exp(a + b * ht / cs)]; x[, fill := { k <- ok & expf > 0; if (any(k)) sum(me[k] * expf[k]) / sum(expf[k]) else NA_real_ }, by = call]
x[, exp_m := fifelse(ok, me, fill)]; n0 <- x[call == min(call), .(n_init = max(tree)), by = STAND]; x <- merge(x, n0, by = "STAND")
x[, `:=`(ing = tree > n_init, ord = frank(call, ties.method = "dense")), by = STAND]
out <- data.table(calls = uniqueN(x$call), rows = nrow(x), worst_abs_diff = max(abs(x$m - x$exp_m)), year0_filled = x[ord == 1 & !ok, .N],
  year0_rows = x[ord == 1, .N], ingrowth_rows = x[ing == TRUE, .N], ingrowth_m_eq_1 = x[ing == TRUE & abs(m - 1) < 1e-12, .N], m_min = min(x$m), m_max = max(x$m))
print(out); fwrite(out, "/home/aaron/jobs/v142p45st/assembled/st1_branch-trace_DATA_2026-10-05.csv")
cat(if (out$worst_abs_diff < 1e-12) "ST1_PASS\n" else "ST1_FAIL\n")
