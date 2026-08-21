suppressMessages(library(data.table))
p21 <- fread("~/magplot/verify/p21/p21_v132_persource.csv")
qc  <- fread("~/magplot/verify/p22/p22_qc_reconciled.csv")
mm  <- fread("~/magplot/verify/p22/p22_memat_medev_reduced.csv")

core <- p21[, .(source, n, rmse_cand, bias_cand, rmse_v132, bias_v132, slope_v132)]
core[, d_rmse_v132_minus_cand := round(rmse_v132 - rmse_cand, 2)]
core[, d_bias_v132_minus_cand := round(bias_v132 - bias_cand, 2)]
core[, note := "full comparison: v12.11 (candidate) vs v13.2 (site-fsm, pass 20)"]

qc2 <- qc[, .(source, n, rmse_cand, bias_cand, rmse_v132, bias_v132, slope_v132)]
qc2[, d_rmse_v132_minus_cand := round(rmse_v132 - rmse_cand, 2)]
qc2[, d_bias_v132_minus_cand := round(bias_v132 - bias_cand, 2)]
qc2[, note := "full comparison: v12.11 (candidate) vs v13.2 (site-fsm, pass 20)"]

mm2 <- mm[, .(source, n, rmse_v132, bias_v132, slope_v132)]
mm2[, rmse_cand := NA_real_][, bias_cand := NA_real_]
mm2[, d_rmse_v132_minus_cand := NA_real_][, d_bias_v132_minus_cand := NA_real_]
mm2[, note := "no v12.11 (candidate) run exists for this source"]
setcolorder(mm2, names(core))

out <- rbindlist(list(core, qc2, mm2))
setorder(out, source)
print(out)
fwrite(out, "v1211_vs_v132_comparison.csv")
cat("\nDONE\n")
