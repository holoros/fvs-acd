# composite_score_plotlevel_bootstrap.R
#
# Genuine STAND/PLOT-LEVEL cluster bootstrap for the stand-years-weighted composite
# TOTVOL %RMSE / %bias score (base v12.10.1 vs candidate v12.11 vs OSM-ACD v2.26.1),
# common-cells restricted to the 7 sources scored by all three models (Baxter,
# CFRU CTRN, Maine FIA whole-plot, PEF, SILC/Seven Islands, NB MagPlot, Nova Scotia),
# under both the NS and NS-long treatments of the Nova Scotia network.
#
# This replaces the coarse SOURCE-level cluster bootstrap in composite_score_weighted.R/.py
# (7 to 9 whole-source clusters resampled 2000 times) with resampling at the level the
# modeling philosophy actually calls for: individual stand rows, resampled WITHIN each
# source, not sources themselves. Concretely, for each of 2000 replicate draws: within
# every one of the 7 sources, n_s rows are resampled with replacement from that source's
# own per-stand results (all 7 sources present in every draw, unlike the coarse bootstrap,
# which could drop or duplicate whole sources); each source's %RMSE and %bias are
# recomputed from its resampled rows; the 7 resampled source estimates are combined into
# one composite draw using the SAME fixed stand-years weights (weight = n * interval_years)
# as the frozen composite_score_weighted script -- weights are not resampled, since n and
# interval_years are fixed, known per-source quantities, not sampling-varying ones. The
# 2.5th/97.5th percentile of the 2000 composite draws is the plot-level 95% CI.
#
# Same seed (20260811), same n_boot (2000), same percentile-interval convention, and the
# same interval_years values/flags as composite_score_weighted.py, so the two bootstraps
# are an apples-to-apples comparison of resampling-unit coarseness only.
#
# Row-level input: per-stand TOTVOL_o (observed) / TOTVOL_p (predicted) columns from the
# project's standard verify harness output in ~/magplot/verify/ (base_*_results.csv,
# cand_*_results.csv, osm_score_*_results.csv / g4_osm_score_*_results.csv family), the
# same harness family documented in scripts/regen_five_way_scorecard_frozen.R and
# scripts/forestgroup_scorecard_v1211.R. File-to-source mapping and row counts were
# confirmed against figures/_data/master_scorecard_sources.csv n values before writing
# this script (all 7 sources x 3 models matched exactly on row count).
#
# NB MagPlot and QC MagPlot share base_nb_results.csv/cand_nb_results.csv, split by the
# PROV column (NB vs QC); QC has no OSM score and is excluded from the 7 common-cells
# sources exactly as the frozen composite does. NS treatment concatenates ns_base_results.csv
# (already the full combined file, n=4504) with the managed+unmanaged split candidate
# files; NS-long concatenates the managed+unmanaged split files for both base and
# candidate. All row counts were verified to sum to the exact n in
# figures/_data/master_scorecard_sources.csv before this script was written.
#
# Run on Cardinal:
#   module purge; module load gcc/12.3.0 R/4.5.2
#   cd ~/magplot/verify && Rscript composite_score_plotlevel_bootstrap.R
#
# Writes composite_score_plotlevel.csv into the working directory (~/magplot/verify on
# Cardinal); download to figures/_data/composite_score_plotlevel.csv in the repo.

suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

RNG_SEED   <- 20260811L
N_BOOT     <- 2000L
VERIFY_DIR <- path.expand("~/magplot/verify")
OUT_CSV    <- file.path(VERIFY_DIR, "composite_score_plotlevel.csv")

setwd(VERIFY_DIR)

rd    <- function(f) fread(f)
rbind_files <- function(files) rbindlist(lapply(files, rd), fill = TRUE)

# ---------------------------------------------------------------------------
# 1. Per-source, per-model row-level tables (the 6 sources shared across NS
#    treatments) plus the two NS-treatment-specific NS rows.
#    interval_years values and flags are copied verbatim from
#    composite_score_weighted.py so the weighting formula matches exactly.
# ---------------------------------------------------------------------------
fixed_sources <- list(
  "Baxter (mature, held-out)" = list(
    interval = 11.0,
    base = rd("base_baxter_results.csv"),
    cand = rd("cand_baxter_results.csv"),
    osm  = rd("osm_score_baxter_results.csv")),
  "CFRU CTRN (managed)" = list(
    interval = 1.0,
    base = rd("base_ctrn_results.csv"),
    cand = rd("cand_ctrn_results.csv"),
    osm  = rd("osm_score_ctrn_results.csv")),
  "Maine FIA whole-plot (= 20-yr long)" = list(
    interval = 20.0,
    base = rd("base_mefia_l_results.csv"),
    cand = rd("cand_mefia_l_results.csv"),
    osm  = rd("osm_score_me_fia_l_results.csv")),
  "PEF (developing)" = list(
    # UNKNOWN interval (no stated remeasurement interval); excluded from temporal
    # weighting, n-only weighting used (weight = n * 1), matching composite_score_weighted.py
    interval = 1.0,
    base = rd("base_pef_results.csv"),
    cand = rd("cand_pef_results.csv"),
    osm  = rd("osm_score_pef_results.csv")),
  "SILC/Seven Islands (calibration, managed)" = list(
    interval = 11.5,
    base = rd("base_silc_l_results.csv"),
    cand = rd("cand_silc_l_results.csv"),
    osm  = rd("osm_score_silc_l_results.csv")),
  "NB MagPlot (managed)" = list(
    interval = 7.0,
    base = rd("base_nb_results.csv")[PROV == "NB"],
    cand = rd("cand_nb_results.csv")[PROV == "NB"],
    osm  = rd("g4_osm_score_nb_results.csv")[PROV == "NB"])
)

ns_long_interval <- (3939 * 5.1 + 506 * 21.9 + 903 * 36.3) / 5348  # n-weighted bucket mean

ns_row <- list(
  NS = list(
    interval = 5.1,
    base = rd("ns_base_results.csv"),
    cand = rbind_files(c("ns_cand_managed_results.csv", "ns_cand_unmanaged_results.csv")),
    osm  = rd("osm_score_ns_results.csv")),
  `NS-long` = list(
    interval = ns_long_interval,
    base = rbind_files(c("ns_long_base_managed_results.csv", "ns_long_base_unmanaged_results.csv")),
    cand = rbind_files(c("ns_long_cand_managed_results.csv", "ns_long_cand_unmanaged_results.csv")),
    osm  = rd("osm_score_ns_long_results.csv"))
)

# ---------------------------------------------------------------------------
# 2. Metric helpers (match composite_score_weighted.py / master_scorecard convention)
# ---------------------------------------------------------------------------
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)

# ---------------------------------------------------------------------------
# 3. Plot-level cluster bootstrap: resample rows WITHIN each source, all 7
#    sources present every draw, fixed stand-years weights.
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
    per_source_rmse = point_rmse, per_source_n = n_list
  )
}

# ---------------------------------------------------------------------------
# 4. Run all scenario x model combinations
# ---------------------------------------------------------------------------
models <- c("base", "cand", "osm")
scenarios <- c("NS", "NS-long")

results <- list()
seed_off <- 0L
for (ns_treat in scenarios) {
  for (m in models) {
    seed_off <- seed_off + 1L
    res <- run_scenario_model(ns_treat, m, seed_off)
    results[[length(results) + 1L]] <- res
  }
}

results_df <- rbindlist(lapply(results, function(r) {
  data.table(ns_treatment = r$ns_treatment, model = r$model,
             n_sources = r$n_sources, n_stands = r$n_stands,
             rmse = round(r$rmse, 2), rmse_lo = round(r$rmse_lo, 2), rmse_hi = round(r$rmse_hi, 2),
             bias = round(r$bias, 2), bias_lo = round(r$bias_lo, 2), bias_hi = round(r$bias_hi, 2))
}))

cat("=" , strrep("=", 99), "\n", sep = "")
cat("PLOT-LEVEL (stand-within-source) CLUSTER BOOTSTRAP -- COMPOSITE %RMSE / %BIAS\n")
cat(strrep("=", 100), "\n")
print(results_df)

cat("\nPer-source point %RMSE (sanity check vs figures/_data/master_scorecard_sources.csv):\n")
for (r in results) {
  cat(sprintf("\n[%s / %s]\n", r$ns_treatment, r$model))
  for (s in names(r$per_source_rmse)) {
    cat(sprintf("  %-42s n=%-5d RMSE%%=%.2f\n", s, r$per_source_n[[s]], r$per_source_rmse[[s]]))
  }
}

fwrite(results_df, OUT_CSV)
cat(sprintf("\nWrote %s\n", OUT_CSV))
cat("DONE_PLOTLEVEL_BOOTSTRAP\n")
