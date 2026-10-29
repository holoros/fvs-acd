## 2026-08-20_p22_memat_medev_reconcile.R
## Pass 22, task 11. Folds memat and medev into a reduced 3-way (base / ship18 / v13.2)
## comparison, matching the metric conventions in p21/2026-08-19_p21_composite_v132.R
## (rmse_pct, bias_pct, ols_coef) but NOT the candidate v12.11 or OSM columns, since no
## candidate or OSM run exists for these two sources anywhere on Cardinal (checked by find,
## this pass and pass 21). Also not pooled into the 8-source composite bootstrap: these two
## sources were never part of that composite's fixed_sources/ns_row lists and adding them now
## would silently change the pass-21 composite's meaning after the fact. This produces its own
## small reduced table instead.
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

srcs <- list(
  memat = list(base = fread("p9g_base_memat_results.csv"),
               v131 = fread("p9lev3/p9_ship18_memat_results.csv"),
               v132 = fread("p21/p9_v132_memat_results.csv")),
  medev = list(base = fread("p9g_base_medev_results.csv"),
               v131 = fread("p9lev3/p9_ship18_medev_results.csv"),
               v132 = fread("p21/p9_v132_medev_results.csv"))
)

RNG_SEED <- 20260811L; N_BOOT <- 2000L
rows <- list(); seed_off <- 100L
for (nm in names(srcs)) {
  d0 <- srcs[[nm]]
  ## observed-basis gate: base vs v132 STAND/TOTVOL_o must match
  a <- d0$base[, .(STAND = as.character(STAND), TOTVOL_o)][order(STAND, TOTVOL_o)]
  b <- d0$v132[, .(STAND = as.character(STAND), TOTVOL_o)][order(STAND, TOTVOL_o)]
  keys_eq <- identical(a$STAND, b$STAND)
  maxd <- if (nrow(a) == nrow(b)) max(abs(a$TOTVOL_o - b$TOTVOL_o)) else NA_real_
  cat(sprintf("%s observed-basis check: n_base=%d n_v132=%d keys_identical=%s max_abs_dTOTVOL_o=%s\n",
      nm, nrow(a), nrow(b), keys_eq, format(maxd)))
  if (!isTRUE(keys_eq) || !is.finite(maxd) || maxd > 1e-6) {
    cat(sprintf("STOP: %s observed-basis mismatch, skipping metrics for this source.\n", nm))
    next
  }
  met <- list()
  for (mdl in c("base","v131","v132")) {
    d <- d0[[mdl]][is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
    r <- rmse_pct(d$TOTVOL_o, d$TOTVOL_p); bi <- bias_pct(d$TOTVOL_o, d$TOTVOL_p)
    oc <- ols_coef(d$TOTVOL_p, d$TOTVOL_o)
    met[[mdl]] <- list(n = nrow(d), rmse = r, bias = bi, slope = unname(oc["slope"]), intercept = unname(oc["intercept"]))
  }
  ## per-source bootstrap CI on RMSE/bias for v132 vs v131(ship18), stand-level cluster resample
  d132 <- d0$v132[is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
  d131 <- d0$v131[is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
  seed_off <- seed_off + 1L
  set.seed(RNG_SEED + seed_off)
  n_s <- nrow(d132)
  rmse_draws <- numeric(N_BOOT); bias_draws <- numeric(N_BOOT)
  for (bi in seq_len(N_BOOT)) {
    idx <- sample.int(n_s, n_s, replace = TRUE)
    rmse_draws[bi] <- rmse_pct(d132$TOTVOL_o[idx], d132$TOTVOL_p[idx])
    bias_draws[bi] <- bias_pct(d132$TOTVOL_o[idx], d132$TOTVOL_p[idx])
  }
  rmse_ci <- unname(quantile(rmse_draws, c(0.025,0.975), type = 7))
  bias_ci <- unname(quantile(bias_draws, c(0.025,0.975), type = 7))

  rows[[nm]] <- data.table(
    source = nm, n = met$base$n,
    rmse_base = round(met$base$rmse,2), bias_base = round(met$base$bias,2),
    rmse_ship18 = round(met$v131$rmse,2), bias_ship18 = round(met$v131$bias,2), slope_ship18 = round(met$v131$slope,4),
    rmse_v132 = round(met$v132$rmse,2), bias_v132 = round(met$v132$bias,2), slope_v132 = round(met$v132$slope,4),
    rmse_v132_lo = round(rmse_ci[1],2), rmse_v132_hi = round(rmse_ci[2],2),
    bias_v132_lo = round(bias_ci[1],2), bias_v132_hi = round(bias_ci[2],2),
    d_rmse_v132_minus_ship18 = round(met$v132$rmse - met$v131$rmse,2),
    d_bias_v132_minus_ship18 = round(met$v132$bias - met$v131$bias,2),
    note = "reduced: no candidate v12.11 or OSM run exists for this source")
}
out <- rbindlist(rows)
print(out)
fwrite(out, "p22/p22_memat_medev_reduced.csv")
cat("DONE_MEMAT_MEDEV_RECONCILE\n")
