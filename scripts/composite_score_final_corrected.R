# composite_score_final_corrected.R
#
# Track E synthesis: rerun of composite_score_plotlevel_bootstrap.R (Track B) with
# interval_years corrected to MEASURED remeasurement intervals recovered from primary
# plot metadata (Track C), replacing the OLD ASSUMED values. Bootstrap mechanics,
# per-stand resampling logic, seed, N_BOOT, and percentile-interval convention are
# UNCHANGED from Track B -- only the interval_years lookup values below differ.
#
# Corrections applied (measured vs. old assumed, from Track C):
#   Maine FIA whole-plot : 20.41 (was 20.0)  -- negligible change
#   SILC/Seven Islands   : 10.37 (was 11.5)  -- from bench_silc_l_pairs.csv, n=73
#   NB MagPlot            : 4.90 (was 7.0, previously shared with QC) -- iv col, base_nb_results.csv, n=355
#   Nova Scotia (NS)      : 5.00 (was 5.1)   -- negligible change
#   PEF                   : 5.61 (was 1.0 PLACEHOLDER -- PEF's interval was "unknown" in
#                           Track B, so it was weighted n-only (weight = n*1), NOT excluded
#                           from the composite. PEF was already one of the 7 common-cells
#                           sources in Track B (confirmed against figures/_data/
#                           master_scorecard_sources.csv: PEF has all_three_present = TRUE,
#                           OSM scored, n=2853). This script does NOT add an eighth source;
#                           it corrects PEF's existing weight from n*1.0 to n*5.61.
#
# QC MagPlot's measured interval (9.76 yr) is NOT applied anywhere in this script: QC has
# no OSM score (all_three_present = FALSE in master_scorecard_sources.csv) and stays
# excluded from the 7-source common-cells composite exactly as in Track B.
#
# Judgment call: the NS-long derived interval is an n-weighted bucket mean,
# (3939 * NS_short + 506 * 21.9 + 903 * 36.3) / 5348, where the first bucket (n=3939) is
# the same underlying NS short-interval quantity used in the plain "NS" row. That bucket's
# assumed value is updated from 5.1 to the measured 5.00 for internal consistency; the other
# two bucket assumptions (21.9, 36.3 yr) were not measured by Track C and are left
# unchanged. Effect is negligible either way (5.1 -> 5.00).
#
# Run on Cardinal:
#   module purge; module load gcc/12.3.0 R/4.5.2
#   cd ~/magplot/verify && Rscript composite_score_final_corrected.R
#
# Writes composite_score_final_corrected.csv into ~/magplot/verify; download to
# figures/_data/composite_score_final_corrected.csv in the repo.

suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

RNG_SEED   <- 20260811L
N_BOOT     <- 2000L
VERIFY_DIR <- path.expand("~/magplot/verify")
OUT_CSV    <- file.path(VERIFY_DIR, "composite_score_final_corrected.csv")

setwd(VERIFY_DIR)

rd    <- function(f) fread(f)
rbind_files <- function(files) rbindlist(lapply(files, rd), fill = TRUE)

# ---------------------------------------------------------------------------
# 1. Per-source, per-model row-level tables. interval_years values below are the
#    Track C MEASURED values where available; Baxter and CFRU CTRN are unchanged
#    (not remeasured by Track C, no correction supplied).
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
    interval = 20.41,   # CORRECTED: measured, was 20.0
    base = rd("base_mefia_l_results.csv"),
    cand = rd("cand_mefia_l_results.csv"),
    osm  = rd("osm_score_me_fia_l_results.csv")),
  "PEF (developing)" = list(
    interval = 5.61,    # CORRECTED: measured, was 1.0 placeholder (interval previously unknown)
    base = rd("base_pef_results.csv"),
    cand = rd("cand_pef_results.csv"),
    osm  = rd("osm_score_pef_results.csv")),
  "SILC/Seven Islands (calibration, managed)" = list(
    interval = 10.37,   # CORRECTED: measured, was 11.5
    base = rd("base_silc_l_results.csv"),
    cand = rd("cand_silc_l_results.csv"),
    osm  = rd("osm_score_silc_l_results.csv")),
  "NB MagPlot (managed)" = list(
    interval = 4.90,    # CORRECTED: measured, was 7.0 (previously shared with QC)
    base = rd("base_nb_results.csv")[PROV == "NB"],
    cand = rd("cand_nb_results.csv")[PROV == "NB"],
    osm  = rd("g4_osm_score_nb_results.csv")[PROV == "NB"])
)

# NS-long bucket mean: first bucket (n=3939) updated to the measured NS short interval
# (5.00, was 5.1); other two buckets (21.9, 36.3) not measured by Track C, unchanged.
ns_long_interval <- (3939 * 5.00 + 506 * 21.9 + 903 * 36.3) / 5348

ns_row <- list(
  NS = list(
    interval = 5.00,    # CORRECTED: measured, was 5.1
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
# 2. Metric helpers (UNCHANGED from Track B)
# ---------------------------------------------------------------------------
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)

# ---------------------------------------------------------------------------
# 3. Plot-level cluster bootstrap (UNCHANGED mechanics from Track B): resample rows
#    WITHIN each source, all 7 sources present every draw, fixed stand-years weights.
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
# 4. Run all scenario x model combinations (UNCHANGED)
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
cat("FINAL CORRECTED plot-level bootstrap -- COMPOSITE %RMSE / %BIAS (measured intervals)\n")
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
cat("DONE_FINAL_CORRECTED_BOOTSTRAP\n")
