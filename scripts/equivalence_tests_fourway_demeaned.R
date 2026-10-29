# equivalence_tests_fourway_demeaned.R
#
# SOURCE-DEMEANED (fixed-effects) fix for the pooled bootstrap equivalence test in
# composite_score_fourway.R. That script regressed obs~pred TOTVOL pooled UNSTRATIFIED
# across all 7 common-cells sources. Because the 7 sources differ hugely in mean TOTVOL
# level (a between-source confound, Simpson's-paradox-style), v13.1-shipping's pooled fit
# came back intercept ~+79 / slope ~0.56 -- apparent severe attenuation -- while a
# per-source spot check on Baxter alone gave a much more defensible intercept 9.4 /
# slope 0.81. The pooled number is very likely an artifact of between-source level
# differences, not real within-stand attenuation.
#
# Fix, per Aaron Weiskittel's modeling-philosophy skill principle 3 (mixed-effects /
# hierarchical default for nested structure -- stands nested in source): a standard,
# lightweight within-group demeaning equivalent. For each model, within each of the 7
# sources, compute that source's own mean observed TOTVOL and mean predicted TOTVOL
# (fixed, computed ONCE from the full per-source sample), subtract them from every
# stand's obs/pred in that source, pool the resulting residuals across all 7 sources,
# and regress demeaned-obs on demeaned-pred. By the Frisch-Waugh-Lovell theorem this is
# algebraically identical to obs ~ pred + factor(source) and removes exactly the
# between-source level confound while preserving the within-source relationship the
# test is meant to capture.
#
# Bootstrap: cluster-resample (with replacement) the FIXED per-stand demeaned residual
# pairs, within source, all 7 sources present every draw -- same resampling unit,
# N_BOOT=2000, seed 20260811 as composite_score_fourway.R -- then pool and refit OLS
# each draw. Demeaning is done ONCE on the full sample and the bootstrap resamples the
# resulting residuals, rather than re-deriving group means inside each draw. The latter
# would force the pooled intercept to be identically 0 in every single draw by
# construction (sum of a group's own deviations from its own mean is always exactly 0,
# regardless of which stands got resampled), which would make the intercept CI a
# degenerate point mass and the intercept-equivalence test uninformative. Resampling the
# FIXED residuals instead preserves genuine stand-level sampling variability in both the
# intercept and the slope, which is what a bootstrap CI is for.
#
# ALSO reports, for context / sanity check, the per-source (UNPOOLED, non-demeaned)
# intercept/slope AND %RMSE/%bias for each of the 4 models x 7 sources x {NS, NS-long},
# each with its own within-source cluster-bootstrap 95% CI (no point estimate travels
# alone -- weiskittel-modeling-philosophy principle 1). This is the same kind of check
# that caught the Baxter discrepancy in the first place, and lets a source-level pattern
# stay visible if the demeaned pooled test still shows something surprising.
#
# Also writes the full per-stand DEMEANED point data (obs_demeaned, pred_demeaned) for
# the 3 models that matter (cand, v131, osm) x 2 scenarios, for traceability and so the
# equivalence figure (fig29) does not need to re-derive it from scratch.
#
# Run on Cardinal:
#   module purge; module load gcc/12.3.0 R/4.5.2
#   cd ~/magplot/verify && Rscript equivalence_tests_fourway_demeaned.R
#
# Writes into ~/magplot/verify (download all three to figures/_data/ in the repo):
#   equivalence_tests_fourway_demeaned.csv        (pooled pairwise, demeaned, 3 pairs x 2 scenarios)
#   equivalence_tests_fourway_persource.csv       (7 sources x 4 models x 2 scenarios, unpooled)
#   equivalence_tests_fourway_demeaned_pointdata.csv (per-stand demeaned obs/pred, for fig29)

suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

RNG_SEED    <- 20260811L
N_BOOT      <- 2000L
VERIFY_DIR  <- path.expand("~/magplot/verify")
OUT_DEMEAN  <- file.path(VERIFY_DIR, "equivalence_tests_fourway_demeaned.csv")
OUT_PERSRC  <- file.path(VERIFY_DIR, "equivalence_tests_fourway_persource.csv")
OUT_POINTS  <- file.path(VERIFY_DIR, "equivalence_tests_fourway_demeaned_pointdata.csv")

setwd(VERIFY_DIR)

rd          <- function(f) fread(f)
rbind_files <- function(files) rbindlist(lapply(files, rd), fill = TRUE)
indomain_fix <- function(d) {
  stopifnot("esi_cov" %in% names(d))
  d[esi_cov == TRUE]
}

# ---------------------------------------------------------------------------
# 1. Per-source, per-model row-level tables. IDENTICAL to composite_score_fourway.R
#    (see that script for the full NS/NS-long INDOMAIN provenance note).
# ---------------------------------------------------------------------------
fixed_sources <- list(
  "Baxter (mature, held-out)" = list(
    interval = 11.0,
    base = rd("base_baxter_results.csv"),
    cand = rd("cand_baxter_results.csv"),
    v131 = rd("v131ship_baxter_results.csv"),
    osm  = rd("osm_score_baxter_results.csv")),
  "CFRU CTRN (managed)" = list(
    interval = 1.0,
    base = rd("base_ctrn_results.csv"),
    cand = rd("cand_ctrn_results.csv"),
    v131 = rd("v131ship_ctrn_results.csv"),
    osm  = rd("osm_score_ctrn_results.csv")),
  "Maine FIA whole-plot (= 20-yr long)" = list(
    interval = 20.41,
    base = rd("base_mefia_l_results.csv"),
    cand = rd("cand_mefia_l_results.csv"),
    v131 = rd("v131ship_mefia_l_results.csv"),
    osm  = rd("osm_score_me_fia_l_results.csv")),
  "PEF (developing)" = list(
    interval = 5.61,
    base = rd("base_pef_results.csv"),
    cand = rd("cand_pef_results.csv"),
    v131 = rd("v131ship_pef_results.csv"),
    osm  = rd("osm_score_pef_results.csv")),
  "SILC/Seven Islands (calibration, managed)" = list(
    interval = 10.37,
    base = rd("base_silc_l_results.csv"),
    cand = rd("cand_silc_l_results.csv"),
    v131 = rd("v131ship_silc_l_results.csv"),
    osm  = rd("osm_score_silc_l_results.csv")),
  "NB MagPlot (managed)" = list(
    interval = 4.90,
    base = rd("base_nb_results.csv")[PROV == "NB"],
    cand = rd("cand_nb_results.csv")[PROV == "NB"],
    v131 = rd("v131ship_nb_results.csv")[PROV == "NB"],
    osm  = rd("g4_osm_score_nb_results.csv")[PROV == "NB"])
)

ns_long_interval <- (3939 * 5.00 + 506 * 21.9 + 903 * 36.3) / 5348

ns_row <- list(
  NS = list(
    interval = 5.00,
    base = rd("ns_base_results.csv"),
    cand = rbind_files(c("ns_cand_managed_results.csv", "ns_cand_unmanaged_results.csv")),
    v131 = indomain_fix(rbind_files(c("v131ship_ns_managed_results.csv", "v131ship_ns_unmanaged_results.csv"))),
    osm  = rd("osm_score_ns_results.csv")),
  `NS-long` = list(
    interval = ns_long_interval,
    base = rbind_files(c("ns_long_base_managed_results.csv", "ns_long_base_unmanaged_results.csv")),
    cand = rbind_files(c("ns_long_cand_managed_results.csv", "ns_long_cand_unmanaged_results.csv")),
    v131 = indomain_fix(rbind_files(c("v131ship_ns_long_managed_results.csv", "v131ship_ns_long_unmanaged_results.csv"))),
    osm  = rd("osm_score_ns_long_results.csv"))
)

# ---------------------------------------------------------------------------
# 2. Fast closed-form OLS (exact match to lm() coefficients) and RMSE/bias helpers.
#    Closed-form avoids lm()-object overhead across the large number of bootstrap
#    refits below (2000 draws x 3 pooled-pair models x 2 scenarios for the demeaned
#    test, plus 2000 x 4 models x 7 sources x 2 scenarios for the per-source table).
# ---------------------------------------------------------------------------
ols_coef <- function(x, y) {
  mx <- mean(x); my <- mean(y)
  sxx <- sum((x - mx)^2)
  slope <- sum((x - mx) * (y - my)) / sxx
  intercept <- my - slope * mx
  c(intercept = intercept, slope = slope)
}
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)

# ---------------------------------------------------------------------------
# 3. Load per-source o/p vectors for both scenarios (mirrors composite_score_fourway.R's
#    run_scenario_model() data assembly step, without the stand-years-weighted composite,
#    which is not needed here).
# ---------------------------------------------------------------------------
load_scenario_model <- function(ns_treatment, model) {
  src_list <- fixed_sources
  src_list[["NS (overall)"]] <- ns_row[[ns_treatment]]
  srcs <- names(src_list)
  o_list <- setNames(vector("list", length(srcs)), srcs)
  p_list <- setNames(vector("list", length(srcs)), srcs)
  n_list <- setNames(integer(length(srcs)), srcs)
  for (s in srcs) {
    d <- src_list[[s]][[model]]
    d <- d[is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
    o_list[[s]] <- d$TOTVOL_o
    p_list[[s]] <- d$TOTVOL_p
    n_list[[s]] <- nrow(d)
  }
  list(o_list = o_list, p_list = p_list, n_list = n_list, srcs = srcs)
}

models    <- c("base", "cand", "v131", "osm")
model_lab <- c(base = "BASE (frozen v12.10.1)", cand = "CANDIDATE v12.11",
               v131 = "v13.1 SHIPPING", osm = "OSM-ACD v2.26.1")
scenarios    <- c("NS", "NS-long")
equiv_models <- c("cand", "v131", "osm")

loaded <- list()
for (ns_treat in scenarios) for (m in models) {
  loaded[[paste(ns_treat, m)]] <- load_scenario_model(ns_treat, m)
}

cat(strrep("=", 100), "\n", sep = "")
cat("SOURCE-DEMEANED bootstrap equivalence test -- fixes the pooled Simpson's-paradox artifact\n")
cat(strrep("=", 100), "\n")

# ---------------------------------------------------------------------------
# 4. Per-source (UNPOOLED) intercept/slope/%RMSE/%bias, 4 models x 7 sources x 2
#    scenarios, each with its own within-source cluster-bootstrap 95% CI.
# ---------------------------------------------------------------------------
persource_rows <- list()
seed_ps <- 0L
for (ns_treat in scenarios) {
  for (m in models) {
    L <- loaded[[paste(ns_treat, m)]]
    for (s in L$srcs) {
      seed_ps <- seed_ps + 1L
      o <- L$o_list[[s]]; p <- L$p_list[[s]]; n_s <- L$n_list[[s]]
      pt   <- ols_coef(p, o)
      pt_r <- rmse_pct(o, p)
      pt_b <- bias_pct(o, p)

      set.seed(RNG_SEED + 9000L + seed_ps)
      int_d <- numeric(N_BOOT); slp_d <- numeric(N_BOOT)
      rmse_d <- numeric(N_BOOT); bias_d <- numeric(N_BOOT)
      for (b in seq_len(N_BOOT)) {
        idx <- sample.int(n_s, n_s, replace = TRUE)
        ob <- o[idx]; pb <- p[idx]
        cf <- ols_coef(pb, ob)
        int_d[b] <- cf["intercept"]; slp_d[b] <- cf["slope"]
        rmse_d[b] <- rmse_pct(ob, pb); bias_d[b] <- bias_pct(ob, pb)
      }
      int_ci  <- unname(quantile(int_d, c(0.025, 0.975), type = 7))
      slp_ci  <- unname(quantile(slp_d, c(0.025, 0.975), type = 7))
      rmse_ci <- unname(quantile(rmse_d, c(0.025, 0.975), type = 7))
      bias_ci <- unname(quantile(bias_d, c(0.025, 0.975), type = 7))

      persource_rows[[length(persource_rows) + 1L]] <- data.table(
        ns_treatment = ns_treat, model = model_lab[m], source = s, n = n_s,
        mean_obs = round(mean(o), 2),
        intercept = round(unname(pt["intercept"]), 3),
        intercept_lo = round(int_ci[1], 3), intercept_hi = round(int_ci[2], 3),
        slope = round(unname(pt["slope"]), 4),
        slope_lo = round(slp_ci[1], 4), slope_hi = round(slp_ci[2], 4),
        rmse_pct = round(pt_r, 2), rmse_pct_lo = round(rmse_ci[1], 2), rmse_pct_hi = round(rmse_ci[2], 2),
        bias_pct = round(pt_b, 2), bias_pct_lo = round(bias_ci[1], 2), bias_pct_hi = round(bias_ci[2], 2)
      )
    }
  }
}
persource_df <- rbindlist(persource_rows)
fwrite(persource_df, OUT_PERSRC)
cat("\nPER-SOURCE (unpooled) intercept/slope/%RMSE/%bias, 4 models x 7 sources x 2 scenarios:\n")
print(persource_df)
cat(sprintf("\nWrote %s\n", OUT_PERSRC))

# ---------------------------------------------------------------------------
# 5. Pooled SOURCE-DEMEANED equivalence test, per model, both scenarios.
# ---------------------------------------------------------------------------
run_demeaned_equiv <- function(ns_treatment, model, seed_offset) {
  L <- loaded[[paste(ns_treatment, model)]]
  srcs <- L$srcs

  # Fixed per-source means, computed ONCE from the full (non-resampled) sample.
  mean_o <- setNames(vapply(srcs, function(s) mean(L$o_list[[s]]), numeric(1)), srcs)
  mean_p <- setNames(vapply(srcs, function(s) mean(L$p_list[[s]]), numeric(1)), srcs)
  od_list <- setNames(vector("list", length(srcs)), srcs)
  pd_list <- setNames(vector("list", length(srcs)), srcs)
  for (s in srcs) {
    od_list[[s]] <- L$o_list[[s]] - mean_o[[s]]
    pd_list[[s]] <- L$p_list[[s]] - mean_p[[s]]
  }

  o_pooled_raw <- unlist(L$o_list, use.names = FALSE)
  mean_obs_raw <- mean(o_pooled_raw)   # sizes the intercept equivalence region, raw units
  od_pooled <- unlist(od_list, use.names = FALSE)
  pd_pooled <- unlist(pd_list, use.names = FALSE)
  pt <- ols_coef(pd_pooled, od_pooled)

  eq_region_intercept <- c(-0.25, 0.25) * mean_obs_raw
  eq_region_slope     <- c(0.75, 1.25)

  set.seed(RNG_SEED + 6000L + seed_offset)
  int_draws <- numeric(N_BOOT); slp_draws <- numeric(N_BOOT)
  for (b in seq_len(N_BOOT)) {
    ob <- vector("list", length(srcs)); pb <- vector("list", length(srcs))
    for (i in seq_along(srcs)) {
      s <- srcs[i]; n_s <- L$n_list[[s]]
      idx <- sample.int(n_s, n_s, replace = TRUE)   # resample the FIXED demeaned pairs
      ob[[i]] <- od_list[[s]][idx]
      pb[[i]] <- pd_list[[s]][idx]
    }
    cf <- ols_coef(unlist(pb, use.names = FALSE), unlist(ob, use.names = FALSE))
    int_draws[b] <- cf["intercept"]; slp_draws[b] <- cf["slope"]
  }
  int_ci <- unname(quantile(int_draws, c(0.025, 0.975), type = 7))
  slp_ci <- unname(quantile(slp_draws, c(0.025, 0.975), type = 7))
  int_equiv <- int_ci[1] >= eq_region_intercept[1] && int_ci[2] <= eq_region_intercept[2]
  slp_equiv <- slp_ci[1] >= eq_region_slope[1]     && slp_ci[2] <= eq_region_slope[2]

  list(ns_treatment = ns_treatment, model = model, n_pooled = length(od_pooled),
       mean_obs_raw = mean_obs_raw,
       intercept = unname(pt["intercept"]), intercept_lo = int_ci[1], intercept_hi = int_ci[2],
       intercept_region_lo = eq_region_intercept[1], intercept_region_hi = eq_region_intercept[2],
       intercept_equivalent = int_equiv,
       slope = unname(pt["slope"]), slope_lo = slp_ci[1], slope_hi = slp_ci[2],
       slope_region_lo = eq_region_slope[1], slope_region_hi = eq_region_slope[2],
       slope_equivalent = slp_equiv,
       model_equivalent_to_1to1 = int_equiv && slp_equiv,
       od_pooled = od_pooled, pd_pooled = pd_pooled, srcs_per_row = rep(srcs, vapply(od_list, length, integer(1))))
}

equiv_results <- list()
eseed <- 0L
for (ns_treat in scenarios) for (m in equiv_models) {
  eseed <- eseed + 1L
  equiv_results[[paste(ns_treat, m)]] <- run_demeaned_equiv(ns_treat, m, eseed)
}

equiv_df <- rbindlist(lapply(equiv_results, function(e) data.table(
  ns_treatment = e$ns_treatment, model = model_lab[e$model], n_pooled = e$n_pooled,
  mean_obs_TOTVOL_raw = round(e$mean_obs_raw, 2),
  intercept = round(e$intercept, 3), intercept_lo = round(e$intercept_lo, 3), intercept_hi = round(e$intercept_hi, 3),
  intercept_region_lo = round(e$intercept_region_lo, 3), intercept_region_hi = round(e$intercept_region_hi, 3),
  intercept_equivalent = e$intercept_equivalent,
  slope = round(e$slope, 4), slope_lo = round(e$slope_lo, 4), slope_hi = round(e$slope_hi, 4),
  slope_region_lo = e$slope_region_lo, slope_region_hi = e$slope_region_hi,
  slope_equivalent = e$slope_equivalent,
  model_equivalent_to_1to1 = e$model_equivalent_to_1to1
)))

pairs <- list(c("v131", "osm"), c("v131", "cand"), c("cand", "osm"))
pair_rows <- list()
for (ns_treat in scenarios) {
  for (pr in pairs) {
    a  <- equiv_results[[paste(ns_treat, pr[1])]]
    bb <- equiv_results[[paste(ns_treat, pr[2])]]
    pair_rows[[length(pair_rows) + 1L]] <- data.table(
      ns_treatment = ns_treat,
      pair = sprintf("%s vs %s", model_lab[pr[1]], model_lab[pr[2]]),
      model_A = model_lab[pr[1]],
      A_intercept = round(a$intercept, 3), A_intercept_lo = round(a$intercept_lo, 3), A_intercept_hi = round(a$intercept_hi, 3),
      A_intercept_equiv = a$intercept_equivalent,
      A_slope = round(a$slope, 4), A_slope_lo = round(a$slope_lo, 4), A_slope_hi = round(a$slope_hi, 4),
      A_slope_equiv = a$slope_equivalent,
      model_B = model_lab[pr[2]],
      B_intercept = round(bb$intercept, 3), B_intercept_lo = round(bb$intercept_lo, 3), B_intercept_hi = round(bb$intercept_hi, 3),
      B_intercept_equiv = bb$intercept_equivalent,
      B_slope = round(bb$slope, 4), B_slope_lo = round(bb$slope_lo, 4), B_slope_hi = round(bb$slope_hi, 4),
      B_slope_equiv = bb$slope_equivalent,
      pair_verdict = if (a$model_equivalent_to_1to1 && bb$model_equivalent_to_1to1)
        "EQUIVALENT (both models statistically indistinguishable from 1:1, within-source)"
      else "NOT EQUIVALENT (at least one model's within-source CI exits its region)"
    )
  }
}
pair_df <- rbindlist(pair_rows)

fwrite(pair_df, OUT_DEMEAN)

cat("\n", strrep("=", 100), "\n", sep = "")
cat("SOURCE-DEMEANED per-model obs~pred intercept/slope, pooled 7 common-cells sources (fixed effects)\n")
cat("Region of equivalence: intercept 0 +/- 25% mean(obs, raw); slope 1 +/- 0.25.\n")
cat(strrep("=", 100), "\n")
print(equiv_df)
cat("\nPAIRWISE VERDICTS (demeaned, the 3 pairs that matter):\n")
print(pair_df)
cat(sprintf("\nWrote %s\n", OUT_DEMEAN))

# ---------------------------------------------------------------------------
# 6. Per-stand demeaned point data (cand, v131, osm x NS, NS-long) -- traceability for
#    fig29 and any downstream check.
# ---------------------------------------------------------------------------
point_rows <- list()
for (ns_treat in scenarios) {
  for (m in equiv_models) {
    e <- equiv_results[[paste(ns_treat, m)]]
    point_rows[[length(point_rows) + 1L]] <- data.table(
      ns_treatment = ns_treat, model = model_lab[m],
      source = e$srcs_per_row,
      obs_demeaned = e$od_pooled, pred_demeaned = e$pd_pooled
    )
  }
}
points_df <- rbindlist(point_rows)
fwrite(points_df, OUT_POINTS)
cat(sprintf("Wrote %s (%d rows)\n", OUT_POINTS, nrow(points_df)))

cat("DONE_DEMEANED_EQUIVALENCE\n")
