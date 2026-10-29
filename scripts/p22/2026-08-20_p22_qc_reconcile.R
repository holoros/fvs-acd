## 2026-08-20_p22_qc_reconcile.R
## Pass 22, task 10. QC MagPlot was never a missing baseline: base, cand (v12.11), ship18
## (v13.1), and v132 all already score the QC rows as a byproduct of the combined
## magp_qcnb source (the "NB MagPlot" task in bench_p9.R/p21 harness scores NB+QC together,
## PROV column distinguishes them; the composite scripts have only ever filtered to
## PROV=="NB" and silently dropped the 378 already-scored QC stands each time). No new
## Cardinal battery was needed; this reconciles what already exists. Only OSM never scored
## QC (g4_osm_score_nb_results.csv is NB-only, confirmed by inspection this pass), so OSM is
## excluded here as a real gap, not an oversight.
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
  library(data.table)
})
VERIFY_DIR <- path.expand("~/magplot/verify"); setwd(VERIFY_DIR)

rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)
ols_coef <- function(p, o) {
  mx <- mean(p); my <- mean(o)
  slope <- sum((p - mx) * (o - my)) / sum((p - mx)^2)
  intercept <- my - slope * mx
  c(intercept = intercept, slope = slope)
}

base  <- fread("base_nb_results.csv")[PROV == "QC"]
cand  <- fread("cand_nb_results.csv")[PROV == "QC"]
v131  <- fread("p9lev3/p9_ship18_nb_results.csv")[PROV == "QC"]
v132  <- fread("p21/p9_v132_nb_results.csv")[PROV == "QC"]

a <- base[, .(STAND = as.character(STAND), TOTVOL_o)][order(STAND, TOTVOL_o)]
b <- v132[, .(STAND = as.character(STAND), TOTVOL_o)][order(STAND, TOTVOL_o)]
keys_eq <- identical(a$STAND, b$STAND)
maxd <- if (nrow(a) == nrow(b)) max(abs(a$TOTVOL_o - b$TOTVOL_o)) else NA_real_
cat(sprintf("QC observed-basis check: n_base=%d n_v132=%d keys_identical=%s max_abs_dTOTVOL_o=%s\n",
    nrow(a), nrow(b), keys_eq, format(maxd)))
if (!isTRUE(keys_eq) || !is.finite(maxd) || maxd > 1e-6) stop("QC OBSERVED BASIS MISMATCH")

models <- list(base = base, cand = cand, ship18 = v131, v132 = v132)
met <- list()
for (mdl in names(models)) {
  d <- models[[mdl]][is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
  r <- rmse_pct(d$TOTVOL_o, d$TOTVOL_p); bi <- bias_pct(d$TOTVOL_o, d$TOTVOL_p)
  oc <- ols_coef(d$TOTVOL_p, d$TOTVOL_o)
  met[[mdl]] <- list(n = nrow(d), rmse = r, bias = bi, slope = unname(oc["slope"]))
}

RNG_SEED <- 20260811L; N_BOOT <- 2000L
d132 <- v132[is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
set.seed(RNG_SEED + 201L)
n_s <- nrow(d132)
rmse_draws <- numeric(N_BOOT); bias_draws <- numeric(N_BOOT)
for (bi in seq_len(N_BOOT)) {
  idx <- sample.int(n_s, n_s, replace = TRUE)
  rmse_draws[bi] <- rmse_pct(d132$TOTVOL_o[idx], d132$TOTVOL_p[idx])
  bias_draws[bi] <- bias_pct(d132$TOTVOL_o[idx], d132$TOTVOL_p[idx])
}
rmse_ci <- unname(quantile(rmse_draws, c(0.025,0.975), type = 7))
bias_ci <- unname(quantile(bias_draws, c(0.025,0.975), type = 7))

out <- data.table(
  source = "QC MagPlot", n = met$base$n,
  rmse_base = round(met$base$rmse,2), bias_base = round(met$base$bias,2),
  rmse_cand = round(met$cand$rmse,2), bias_cand = round(met$cand$bias,2),
  rmse_ship18 = round(met$ship18$rmse,2), bias_ship18 = round(met$ship18$bias,2), slope_ship18 = round(met$ship18$slope,4),
  rmse_v132 = round(met$v132$rmse,2), bias_v132 = round(met$v132$bias,2), slope_v132 = round(met$v132$slope,4),
  rmse_v132_lo = round(rmse_ci[1],2), rmse_v132_hi = round(rmse_ci[2],2),
  bias_v132_lo = round(bias_ci[1],2), bias_v132_hi = round(bias_ci[2],2),
  d_rmse_v132_minus_ship18 = round(met$v132$rmse - met$ship18$rmse,2),
  d_bias_v132_minus_ship18 = round(met$v132$bias - met$ship18$bias,2),
  note = "reduced: OSM never scored QC (g4_osm_score_nb_results.csv is NB-only)")
print(out)
fwrite(out, "p22/p22_qc_reconciled.csv")
cat("DONE_QC_RECONCILE\n")
