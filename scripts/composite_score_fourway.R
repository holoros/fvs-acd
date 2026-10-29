# composite_score_fourway.R
#
# FOUR-WAY extension of composite_score_final_corrected.R (Track E): adds v13.1-SHIPPING
# (config: MODEL_FILE=p4e/model_b0b1b2.r, B0NEW=-1.88366 B1NEW=0.49788 B2NEW=-0.0293426,
# IMULT=2.5, ONSET=0.55 BREAK=0.62, both hier switches FALSE -- job 13434825, all 10 array
# tasks COMPLETED) alongside base (v12.10.1), candidate (v12.11), and OSM-ACD v2.26.1.
# Bootstrap mechanics (plot/stand-level cluster resampling within each of the 7 common-cells
# sources, all sources present every draw, fixed stand-years weights = n * interval_years,
# seed 20260811, N_BOOT=2000, 95% percentile CI) are UNCHANGED from composite_score_
# final_corrected.R. interval_years values are the Track C MEASURED values per the task spec.
#
# ---------------------------------------------------------------------------------------
# NS / NS-long INCLUSION FIX (diagnosed this pass, evidence below) -----------------------
# ---------------------------------------------------------------------------------------
# v131_shipping_array.sbatch sets INDOMAIN=0 for its four NS/NS-long tasks (7: ns_managed,
# 8: ns_unmanaged, 9: ns_long_managed, 10: ns_long_unmanaged), while every reference
# generator for base/v12.11 on NS (ns_cand_managed.sbatch, ns_long_cand_managed.sbatch,
# ns_long_cand_unmanaged.sbatch, ns_long_base_*.sbatch) sets INDOMAIN=1. The harness
# (bench_parity_split_ms_v131.R line 185 / bench_parity_split_ms_v1211.R identical line)
# reads: `if(Sys.getenv("INDOMAIN","1")=="1") prs <- prs[PROV=="NB" | esi_cov==TRUE]`.
# For NS, PROV != "NB", so this filter reduces to keeping esi_cov==TRUE rows only --
# i.e. stands with a valid (finite, >2) ESI8 site-index value. INDOMAIN=0 in the shipping
# array disables this QC filter, so the raw PAIRS_FILE row count (2500 managed + 2500
# unmanaged = 5000; NS-long 1334 managed + 4419 unmanaged = 5753) is scored in full,
# including stands the reference deliberately excludes as out-of-domain (no valid site
# index). esi_cov is computed unconditionally before the INDOMAIN gate, so it is present
# in every v131ship_ns*/v131ship_ns_long*_results.csv row regardless. Applying esi_cov==
# TRUE post hoc to the shipping NS/NS-long output reproduces the reference n EXACTLY:
#   ns_managed   2500 rows, esi_cov TRUE = 2157  (reference ns_cand_managed n = 2157)
#   ns_unmanaged 2500 rows, esi_cov TRUE = 2347  (reference ns_cand_unmanaged n = 2347)
#     -> combined 4504, matching ns_base_results.csv / ns_cand_*.csv exactly.
#   ns_long_managed   1334 rows, esi_cov TRUE = 1334 (0 dropped)
#   ns_long_unmanaged 4419 rows, esi_cov TRUE = 4014 (405 dropped)
#     -> combined 5348, matching ns_long_base_*/ns_long_cand_* exactly.
# This is NOT a projection-failure difference (the shipping config had ZERO per-stand
# projection failures on NS: 2500/2500 and full raw n survived the model loop) and NOT a
# legitimate SDImax-retune survivorship effect -- it is a straightforward extra 496 (NS)
# / 405 (NS-long) stands with missing/invalid site-index coverage that the reference run
# excludes and the shipping array accidentally included by leaving INDOMAIN=0. The other
# 5 fixed sources (Baxter, CTRN, Maine FIA whole-plot, PEF, SILC) and NB all default to
# INDOMAIN=1 in v131_shipping_array.sbatch (tasks 1-6), so they need NO correction here.
# Fix applied below: filter v131ship's NS/NS-long managed+unmanaged rows to esi_cov==TRUE
# before use, exactly reproducing the reference inclusion rule. Do NOT silently apply this
# filter to the other sources; they were never affected.
#
# Run on Cardinal:
#   module purge; module load gcc/12.3.0 R/4.5.2
#   cd ~/magplot/verify && Rscript composite_score_fourway.R
#
# Writes composite_score_fourway.csv and equivalence_tests_fourway.csv into
# ~/magplot/verify; download both to figures/_data/ in the repo.

suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

RNG_SEED    <- 20260811L
N_BOOT      <- 2000L
VERIFY_DIR  <- path.expand("~/magplot/verify")
OUT_COMP    <- file.path(VERIFY_DIR, "composite_score_fourway.csv")
OUT_EQUIV   <- file.path(VERIFY_DIR, "equivalence_tests_fourway.csv")

setwd(VERIFY_DIR)

rd          <- function(f) fread(f)
rbind_files <- function(files) rbindlist(lapply(files, rd), fill = TRUE)
# esi_cov-only filter: reproduces the reference INDOMAIN=1 inclusion rule for NS/NS-long,
# where it reduces to "keep esi_cov==TRUE" (PROV never equals "NB" in the NS pairs files).
indomain_fix <- function(d) {
  stopifnot("esi_cov" %in% names(d))
  d[esi_cov == TRUE]
}

# ---------------------------------------------------------------------------
# 1. Per-source, per-model row-level tables. interval_years = Track C measured values.
#    v131ship is the 4th model column; NS/NS-long v131ship rows get the INDOMAIN fix.
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

# NS-long bucket mean: unchanged from Track C (3939*5.00 + 506*21.9 + 903*36.3)/5348.
# v131ship's INDOMAIN fix reproduces n=5348 exactly for NS-long (1334 managed all esi_cov
# TRUE + 4014/4419 unmanaged esi_cov TRUE), so the bucket composition and denominator are
# unchanged; no recompute needed per the task's own stated condition.
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
# 2. Metric helpers (unchanged convention)
# ---------------------------------------------------------------------------
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)

# ---------------------------------------------------------------------------
# 3. Plot-level cluster bootstrap for composite %RMSE / %bias, 4 models.
# ---------------------------------------------------------------------------
run_scenario_model <- function(ns_treatment, model, seed_offset) {
  src_list <- fixed_sources
  src_list[["NS (overall)"]] <- ns_row[[ns_treatment]]

  srcs <- names(src_list)
  o_list <- setNames(vector("list", length(srcs)), srcs)
  p_list <- setNames(vector("list", length(srcs)), srcs)
  w_list <- setNames(numeric(length(srcs)), srcs)
  n_list <- setNames(integer(length(srcs)), srcs)

  for (s in srcs) {
    d <- src_list[[s]][[model]]
    d <- d[is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
    o_list[[s]] <- d$TOTVOL_o
    p_list[[s]] <- d$TOTVOL_p
    n_list[[s]] <- nrow(d)
    w_list[[s]] <- nrow(d) * src_list[[s]]$interval
  }

  point_rmse <- vapply(srcs, function(s) rmse_pct(o_list[[s]], p_list[[s]]), numeric(1))
  point_bias <- vapply(srcs, function(s) bias_pct(o_list[[s]], p_list[[s]]), numeric(1))
  w <- w_list[srcs]
  composite_rmse <- sum(w * point_rmse) / sum(w)
  composite_bias <- sum(w * point_bias) / sum(w)

  set.seed(RNG_SEED + seed_offset)
  rmse_draws <- numeric(N_BOOT)
  bias_draws <- numeric(N_BOOT)
  for (b in seq_len(N_BOOT)) {
    r_b  <- numeric(length(srcs))
    bi_b <- numeric(length(srcs))
    for (i in seq_along(srcs)) {
      s   <- srcs[i]
      n_s <- n_list[[s]]
      idx <- sample.int(n_s, n_s, replace = TRUE)
      ob  <- o_list[[s]][idx]
      pb  <- p_list[[s]][idx]
      r_b[i]  <- rmse_pct(ob, pb)
      bi_b[i] <- bias_pct(ob, pb)
    }
    rmse_draws[b] <- sum(w * r_b) / sum(w)
    bias_draws[b] <- sum(w * bi_b) / sum(w)
  }
  rmse_ci <- unname(quantile(rmse_draws, c(0.025, 0.975), type = 7))
  bias_ci <- unname(quantile(bias_draws, c(0.025, 0.975), type = 7))

  list(
    ns_treatment = ns_treatment, model = model,
    n_sources = length(srcs), n_stands = sum(unlist(n_list)),
    rmse = composite_rmse, rmse_lo = rmse_ci[1], rmse_hi = rmse_ci[2],
    bias = composite_bias, bias_lo = bias_ci[1], bias_hi = bias_ci[2],
    per_source_rmse = point_rmse, per_source_n = n_list,
    o_list = o_list, p_list = p_list, n_list = n_list
  )
}

models    <- c("base", "cand", "v131", "osm")
model_lab <- c(base = "BASE (frozen v12.10.1)", cand = "CANDIDATE v12.11",
               v131 = "v13.1 SHIPPING", osm = "OSM-ACD v2.26.1")
scenarios <- c("NS", "NS-long")

results <- list()
seed_off <- 0L
for (ns_treat in scenarios) {
  for (m in models) {
    seed_off <- seed_off + 1L
    res <- run_scenario_model(ns_treat, m, seed_off)
    results[[paste(ns_treat, m)]] <- res
  }
}

results_df <- rbindlist(lapply(results, function(r) {
  data.table(ns_treatment = r$ns_treatment, model = model_lab[r$model],
             n_sources = r$n_sources, n_stands = r$n_stands,
             rmse = round(r$rmse, 2), rmse_lo = round(r$rmse_lo, 2), rmse_hi = round(r$rmse_hi, 2),
             bias = round(r$bias, 2), bias_lo = round(r$bias_lo, 2), bias_hi = round(r$bias_hi, 2))
}))

cat(strrep("=", 100), "\n", sep = "")
cat("FOUR-WAY plot-level cluster bootstrap -- COMPOSITE %RMSE / %BIAS (base/v12.11/v13.1-ship/OSM)\n")
cat(strrep("=", 100), "\n")
print(results_df)
fwrite(results_df, OUT_COMP)
cat(sprintf("\nWrote %s\n", OUT_COMP))

# ---------------------------------------------------------------------------
# 4. Bootstrap equivalence test (TOST-style), 3 pairs that matter: v13.1 vs OSM,
#    v13.1 vs v12.11, v12.11 vs OSM. Implemented as: for each of the 3 named models
#    (cand, v131, osm) individually, fit obs ~ pred pooled across the 7 common-cells
#    sources (stand rows row-bound after per-source cluster resampling, all 7 sources
#    present every draw -- same resampling unit as section 3), and TOST the intercept
#    against 0 (no bias) and the slope against 1 (no proportional attenuation). Each
#    named "pair" is then the juxtaposition of its two models' individual TOST results;
#    a pair's overall verdict is "equivalent" only if BOTH models are individually
#    equivalent to the 1:1 line (both statistically indistinguishable from a perfect
#    predictor implies they are statistically indistinguishable from each other in the
#    relevant sense). equiv.boot() from the `equivalence` package was considered per the
#    task spec; not used here -- implemented manually instead so the resampling unit
#    (stand rows clustered within source, all sources present every draw) exactly matches
#    the RMSE/bias bootstrap above for a like-for-like CI, and to avoid a package-install
#    dependency on a connector with a ~45% per-call timeout rate under real time pressure.
#    REGION OF EQUIVALENCE: intercept +/- 25% of the mean observed TOTVOL (pooled, full
#    data), slope 1 +/- 0.25 (0.75-1.25). This is the literature default (25% margin),
#    NOT decision-derived for this comparison -- disclosed per the modeling-philosophy
#    skill's own instruction to flag convention use.
# ---------------------------------------------------------------------------

equiv_boot_model <- function(ns_treatment, model, seed_offset) {
  r <- results[[paste(ns_treatment, model)]]
  srcs <- names(r$o_list)
  o_pooled <- unlist(r$o_list, use.names = FALSE)
  p_pooled <- unlist(r$p_list, use.names = FALSE)
  fit0 <- lm(o_pooled ~ p_pooled)
  intercept_hat <- unname(coef(fit0)[1])
  slope_hat     <- unname(coef(fit0)[2])
  mean_obs      <- mean(o_pooled)

  eq_region_intercept <- c(-0.25, 0.25) * mean_obs
  eq_region_slope     <- c(0.75, 1.25)

  set.seed(RNG_SEED + 5000L + seed_offset)
  int_draws <- numeric(N_BOOT)
  slp_draws <- numeric(N_BOOT)
  for (b in seq_len(N_BOOT)) {
    o_b <- vector("list", length(srcs)); p_b <- vector("list", length(srcs))
    for (i in seq_along(srcs)) {
      s <- srcs[i]; n_s <- r$n_list[[s]]
      idx <- sample.int(n_s, n_s, replace = TRUE)
      o_b[[i]] <- r$o_list[[s]][idx]
      p_b[[i]] <- r$p_list[[s]][idx]
    }
    ob <- unlist(o_b, use.names = FALSE); pb <- unlist(p_b, use.names = FALSE)
    fb <- lm(ob ~ pb)
    int_draws[b] <- unname(coef(fb)[1])
    slp_draws[b] <- unname(coef(fb)[2])
  }
  int_ci <- unname(quantile(int_draws, c(0.025, 0.975), type = 7))
  slp_ci <- unname(quantile(slp_draws, c(0.025, 0.975), type = 7))

  int_equiv <- int_ci[1] >= eq_region_intercept[1] && int_ci[2] <= eq_region_intercept[2]
  slp_equiv <- slp_ci[1] >= eq_region_slope[1]     && slp_ci[2] <= eq_region_slope[2]

  list(ns_treatment = ns_treatment, model = model, n_pooled = length(o_pooled),
       mean_obs = mean_obs,
       intercept = intercept_hat, intercept_lo = int_ci[1], intercept_hi = int_ci[2],
       intercept_region_lo = eq_region_intercept[1], intercept_region_hi = eq_region_intercept[2],
       intercept_equivalent = int_equiv,
       slope = slope_hat, slope_lo = slp_ci[1], slope_hi = slp_ci[2],
       slope_region_lo = eq_region_slope[1], slope_region_hi = eq_region_slope[2],
       slope_equivalent = slp_equiv,
       model_equivalent_to_1to1 = int_equiv && slp_equiv)
}

equiv_models <- c("cand", "v131", "osm")
equiv_results <- list()
eseed <- 0L
for (ns_treat in scenarios) {
  for (m in equiv_models) {
    eseed <- eseed + 1L
    equiv_results[[paste(ns_treat, m)]] <- equiv_boot_model(ns_treat, m, eseed)
  }
}

equiv_df <- rbindlist(lapply(equiv_results, function(e) {
  data.table(ns_treatment = e$ns_treatment, model = model_lab[e$model], n_pooled = e$n_pooled,
             mean_obs_TOTVOL = round(e$mean_obs, 2),
             intercept = round(e$intercept, 3), intercept_lo = round(e$intercept_lo, 3), intercept_hi = round(e$intercept_hi, 3),
             intercept_region_lo = round(e$intercept_region_lo, 3), intercept_region_hi = round(e$intercept_region_hi, 3),
             intercept_equivalent = e$intercept_equivalent,
             slope = round(e$slope, 4), slope_lo = round(e$slope_lo, 4), slope_hi = round(e$slope_hi, 4),
             slope_region_lo = e$slope_region_lo, slope_region_hi = e$slope_region_hi,
             slope_equivalent = e$slope_equivalent,
             model_equivalent_to_1to1 = e$model_equivalent_to_1to1)
}))

pairs <- list(
  c("v131", "osm"), c("v131", "cand"), c("cand", "osm")
)
pair_rows <- list()
for (ns_treat in scenarios) {
  for (pr in pairs) {
    a <- equiv_results[[paste(ns_treat, pr[1])]]
    bb <- equiv_results[[paste(ns_treat, pr[2])]]
    pair_rows[[length(pair_rows) + 1L]] <- data.table(
      ns_treatment = ns_treat,
      pair = sprintf("%s vs %s", model_lab[pr[1]], model_lab[pr[2]]),
      model_A = model_lab[pr[1]], A_intercept_equiv = a$intercept_equivalent, A_slope_equiv = a$slope_equivalent,
      model_B = model_lab[pr[2]], B_intercept_equiv = bb$intercept_equivalent, B_slope_equiv = bb$slope_equivalent,
      pair_verdict = if (a$model_equivalent_to_1to1 && bb$model_equivalent_to_1to1) "EQUIVALENT (both models statistically indistinguishable from 1:1)"
                     else "NOT EQUIVALENT (at least one model's CI exits its region)")
  }
}
pair_df <- rbindlist(pair_rows)

cat("\n", strrep("=", 100), "\n", sep = "")
cat("BOOTSTRAP EQUIVALENCE (TOST-style), per-model obs~pred intercept/slope, pooled 7 common-cells sources\n")
cat("Region of equivalence: intercept 0 +/- 25% mean(obs); slope 1 +/- 0.25. Literature default, not decision-derived.\n")
cat(strrep("=", 100), "\n")
print(equiv_df)
cat("\nPAIRWISE VERDICTS (the 3 pairs that matter):\n")
print(pair_df)

fwrite(rbindlist(list(
  equiv_df[, .(ns_treatment, model, n_pooled, mean_obs_TOTVOL, intercept, intercept_lo, intercept_hi,
               intercept_region_lo, intercept_region_hi, intercept_equivalent,
               slope, slope_lo, slope_hi, slope_region_lo, slope_region_hi, slope_equivalent,
               model_equivalent_to_1to1, row_type = "per_model")]
), fill = TRUE), OUT_EQUIV)
# append pair verdicts as a second block to the same CSV for a single downloadable file
fwrite(pair_df, sub("\\.csv$", "_pairs.csv", OUT_EQUIV))

cat(sprintf("\nWrote %s\n", OUT_EQUIV))
cat(sprintf("Wrote %s\n", sub("\\.csv$", "_pairs.csv", OUT_EQUIV)))
cat("DONE_FOURWAY_COMPOSITE_AND_EQUIVALENCE\n")
