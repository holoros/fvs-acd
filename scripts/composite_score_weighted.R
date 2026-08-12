#!/usr/bin/env Rscript
# composite_score_weighted.R
#
# Canonical production script for the stand-years-weighted overall composite benchmark score,
# FVS-ACD v12.11 (candidate) vs OSM-ACD v2.26.1 vs base v12.10.1.
#
# [STACK NOTE] Written 11 August 2026 in a Cowork sandbox with no R installation and no reachable
# Cardinal SSH session (both confirmed down this session; see _context and CLAUDE.md sandbox
# provisioning notes). This script was authored and NOT executed here. The numbers reported in
# 20260811_weighted_composite_score.md were instead computed by the equivalent Python script,
# scripts/composite_score_weighted.py, run in this sandbox against the same two source CSVs. This
# script should be re-run on Cardinal (module purge; module load gcc/12.3.0 R/4.5.2) the next time
# that access is available, as a verification pass, and its output diffed against the Python run.
# Expect an exact match: both scripts use the same weighting formula, the same row set, the same
# RNG seed (20260811), and the same n_boot (2000); any divergence beyond floating-point noise is a
# bug, not an expected R-vs-Python discrepancy.
#
# Run:  Rscript scripts/composite_score_weighted.R
# Requires: data.table (module load gcc/12.3.0 R/4.5.2 on Cardinal; CRAN reachable there)

suppressPackageStartupMessages(library(data.table))

set.seed(20260811L)
N_BOOT <- 2000L

REPO_ROOT <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), ".."),
                            mustWork = FALSE)
`%||%` <- function(a, b) if (is.null(a)) b else a
if (interactive() || identical(REPO_ROOT, "..")) {
  REPO_ROOT <- getwd()  # fallback when sourced interactively / path not resolvable
}

OUT_CSV <- file.path(REPO_ROOT, "figures/_data/composite_score_weighted.csv")
OUT_PNG <- file.path(REPO_ROOT, "figures/fig21_weighted_composite_score.png")
SRC_CSV <- file.path(REPO_ROOT, "figures/_data/master_scorecard_sources.csv")
MSC_CSV <- file.path(REPO_ROOT, "figures/_data/master_scorecard.csv")

# ---------------------------------------------------------------------------------------------
# 1. Weighting formula: weight = n * interval_years ("stand-years of observation")
# ---------------------------------------------------------------------------------------------
# This is the standard way to pool an error metric across studies of differing sample size and
# remeasurement length: more stand-years is more information, both because there are more plots
# contributing independent residuals and because a longer remeasurement interval is a harder,
# more informative test of a growth model's long-horizon behavior (short-interval error is a
# weaker test of compounding growth and mortality dynamics than a multi-decade one). This is a
# CHOSEN weighting scheme, not the only defensible one. The classical meta-analytic alternative,
# inverse-variance weighting, would be preferable if a per-source variance estimate for TOTVOL
# %RMSE existed; it does not at this aggregation level, because only the already-pooled
# source-level RMSE/bias point estimates are available here, not the underlying plot-level
# residuals needed to compute a per-source sampling variance. This is stated as a limitation, not
# resolved by this script.

# ---------------------------------------------------------------------------------------------
# 2. Row-level input table
# ---------------------------------------------------------------------------------------------
# All RMSE/bias values are read directly from figures/_data/master_scorecard_sources.csv
# (TOTVOL_rmse_pct, TOTVOL_bias_pct); no score is recomputed by this script. Interval-year values
# and their evidence flags follow the task brief exactly; see interval_flag per row.

rows <- data.table(
  dataset       = c("Baxter (mature, held-out)", "CFRU CTRN (managed)",
                     "Maine FIA subplot (developing)", "Maine FIA whole-plot (= 20-yr long)",
                     "PEF (developing)", "SILC/Seven Islands (calibration, managed)",
                     "NB MagPlot (managed)", "QC MagPlot (managed)"),
  n_base        = c(91, 1086, 2858, 918, 2853, 73, 355, 378),
  n_v1211       = c(91, 1086, 2858, 918, 2853, 73, 355, 378),
  n_osm         = c(91, 1033, NA, 918, 2853, 69, 355, NA),
  interval      = c(11.0, 1.0, 20.0, 20.0, 1.0, 11.5, 7.0, 7.0),
  interval_flag = c(
    "STATED",
    "STATED",
    "ASSUMPTION: same population as ME FIA whole-plot/long, finer grain",
    "STATED",
    "UNKNOWN: no stated interval; excluded from temporal weight, n-only weighting used (weight=n*1); NB/QC combined-mean proxy rejected as cross-network borrowing",
    "ASSUMPTION: midpoint of stated 8-15 yr range for the n=60 long-horizon subset, applied to the full n=73 (subset identity not confirmed)",
    "ASSUMPTION: NB+QC combined legacy mean (~7 yr) applied to NB individually",
    "ASSUMPTION: NB+QC combined legacy mean (~7 yr) applied to QC individually"
  ),
  base_rmse  = c(48.28, 24.81, 51.11, 38.67, 18.03, 65.01, 48.88, 59.34),
  base_bias  = c(9.12, -9.78, -24.90, -16.60, 1.23, -6.34, -11.84, 1.23),
  v1211_rmse = c(48.14, 18.06, 51.26, 38.56, 17.91, 64.24, 41.85, 58.50),
  v1211_bias = c(6.92, -2.24, -24.82, -16.13, 1.37, -5.65, -5.96, 9.46),
  osm_rmse   = c(50.81, 20.51, NA, 31.93, 14.65, 62.99, 43.77, NA),
  osm_bias   = c(12.37, -4.81, NA, -6.29, 0.26, -18.07, -8.07, NA),
  osm_available = c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE)
)

ns_row <- data.table(
  dataset = "NS (overall, bench_ns_scorecard)", n_base = 4504, n_v1211 = 4504, n_osm = 4499,
  interval = 5.1,
  interval_flag = "ASSUMPTION: NS-long's own <15 yr bucket mean (5.1 yr, n=3939) applied to NS overall per pass-6 handoff language",
  base_rmse = 182.44, base_bias = -41.28, v1211_rmse = 156.69, v1211_bias = -30.61,
  osm_rmse = 153.05, osm_bias = -29.22, osm_available = TRUE
)

# NS-long bucket-level RMSE by model is recoverable from master_scorecard.csv
# (determinant == "projection_length", region == "NS": n = 3939 / 506 / 903, sum = 5348 = NS-long's
# own n). Bucket-level BIAS is not present in that file (RMSE-only columns), so this script uses
# the single pooled NS-long row (bench_ns_long_scorecard) for BOTH metrics in the primary
# composite, to keep the RMSE and bias composites built from an identical row set and keep
# bootstrap cluster counts consistent across metrics. The bucket breakdown is written to the
# output CSV separately as a supplementary, RMSE-only table, not fed into the bootstrap.
ns_long_buckets <- data.table(
  bucket = c("<15 yr", "15-30 yr", ">30 yr"),
  n = c(3939, 506, 903),
  interval = c(5.1, 21.9, 36.3),
  base_rmse = c(163.46, 145.83, 49.79),
  v1211_rmse = c(132.88, 127.29, 52.35),
  osm_rmse = c(134.24, 127.57, 50.28)
)
ns_long_pooled_interval <- ns_long_buckets[, sum(n * interval) / sum(n)]

ns_long_row <- data.table(
  dataset = "NS-long (all-consecutive-pairs, bench_ns_long_scorecard)",
  n_base = 5348, n_v1211 = 5348, n_osm = 5344,
  interval = ns_long_pooled_interval,
  interval_flag = sprintf(
    "COMPUTED: n-weighted mean of NS-long's own three stated bucket means = %.2f yr. Bucket RMSE recoverable, bucket bias not; pooled row used for both metrics for consistency.",
    ns_long_pooled_interval),
  base_rmse = 153.97, base_bias = -39.75, v1211_rmse = 127.35, v1211_bias = -30.41,
  osm_rmse = 128.34, osm_bias = -31.99, osm_available = TRUE
)

# memat / medev: EXCLUDED. No score for either v12.11 or OSM per the finalized scorecard
# (20260811_final_scorecard_all_datasets.md, Table 30). A composite cannot weight a score that
# does not exist; they are named here rather than silently dropped.
excluded_no_score <- c("Maine FIA mature (memat, n=1757)", "Maine FIA control (medev, n=1759)")

make_scenario <- function(ns_treatment = c("NS", "NS-long")) {
  ns_treatment <- match.arg(ns_treatment)
  extra <- if (ns_treatment == "NS") ns_row else ns_long_row
  rbindlist(list(rows, extra), use.names = TRUE)
}

# ---------------------------------------------------------------------------------------------
# 3. Weighted composite and source-level cluster bootstrap
# ---------------------------------------------------------------------------------------------
weighted_composite <- function(d, model, restrict_common_cells = FALSE) {
  dd <- copy(d)
  if (restrict_common_cells) dd <- dd[osm_available == TRUE]
  n_col <- sprintf("n_%s", model)
  rmse_col <- sprintf("%s_rmse", model)
  bias_col <- sprintf("%s_bias", model)
  dd <- dd[!is.na(get(rmse_col)) & !is.na(get(n_col))]
  w <- dd[[n_col]] * dd$interval
  list(rmse = sum(w * dd[[rmse_col]]) / sum(w),
       bias = sum(w * dd[[bias_col]]) / sum(w),
       n_sources = nrow(dd), n_stands = sum(dd[[n_col]]))
}

bootstrap_composite <- function(d, model, restrict_common_cells = FALSE,
                                 n_boot = N_BOOT, seed = 20260811L) {
  dd <- copy(d)
  if (restrict_common_cells) dd <- dd[osm_available == TRUE]
  n_col <- sprintf("n_%s", model)
  rmse_col <- sprintf("%s_rmse", model)
  bias_col <- sprintf("%s_bias", model)
  dd <- dd[!is.na(get(rmse_col)) & !is.na(get(n_col))]
  k <- nrow(dd)
  set.seed(seed)
  rmse_draws <- numeric(n_boot)
  bias_draws <- numeric(n_boot)
  n_vec <- dd[[n_col]]; interval_vec <- dd$interval
  rmse_vec <- dd[[rmse_col]]; bias_vec <- dd[[bias_col]]
  for (b in seq_len(n_boot)) {
    idx <- sample.int(k, k, replace = TRUE)
    w <- n_vec[idx] * interval_vec[idx]
    rmse_draws[b] <- sum(w * rmse_vec[idx]) / sum(w)
    bias_draws[b] <- sum(w * bias_vec[idx]) / sum(w)
  }
  list(rmse_ci = quantile(rmse_draws, c(0.025, 0.975)),
       bias_ci = quantile(bias_draws, c(0.025, 0.975)),
       k = k)
}

# ---------------------------------------------------------------------------------------------
# 4. Run all scenarios: v1211-only-all-data, and common-cells base/v1211/osm, x {NS, NS-long}
# ---------------------------------------------------------------------------------------------
results <- list()
detail <- list()

for (ns_treatment in c("NS", "NS-long")) {
  d <- make_scenario(ns_treatment)
  detail[[ns_treatment]] <- copy(d)[, ns_treatment := ns_treatment]

  wc <- weighted_composite(d, "v1211", restrict_common_cells = FALSE)
  bc <- bootstrap_composite(d, "v1211", restrict_common_cells = FALSE, seed = 20260811L + 1L)
  results[[length(results) + 1]] <- data.table(
    ns_treatment = ns_treatment, comparison = "v1211_all_own_data", model = "v1211",
    n_sources = wc$n_sources, n_stands = wc$n_stands,
    rmse = wc$rmse, rmse_lo = bc$rmse_ci[1], rmse_hi = bc$rmse_ci[2],
    bias = wc$bias, bias_lo = bc$bias_ci[1], bias_hi = bc$bias_ci[2])

  for (model in c("base", "v1211", "osm")) {
    wc <- weighted_composite(d, model, restrict_common_cells = TRUE)
    bc <- bootstrap_composite(d, model, restrict_common_cells = TRUE, seed = 20260811L + 2L)
    results[[length(results) + 1]] <- data.table(
      ns_treatment = ns_treatment, comparison = "common_cells", model = model,
      n_sources = wc$n_sources, n_stands = wc$n_stands,
      rmse = wc$rmse, rmse_lo = bc$rmse_ci[1], rmse_hi = bc$rmse_ci[2],
      bias = wc$bias, bias_lo = bc$bias_ci[1], bias_hi = bc$bias_ci[2])
  }
}

results_dt <- rbindlist(results)
detail_dt <- rbindlist(detail, use.names = TRUE)

print(results_dt)
cat("\nExcluded (no score for either model):\n"); print(excluded_no_score)
cat("\nNS-long bucket-level RMSE (supplementary only, not used in the bootstrap):\n")
print(ns_long_buckets)

# ---------------------------------------------------------------------------------------------
# 5. Write CSV (row detail + composite results + bucket table + exclusions, same layout as the
#    Python run this session's numbers actually came from)
# ---------------------------------------------------------------------------------------------
fwrite(detail_dt, OUT_CSV)
cat("\n# --- composite results ---\n", file = OUT_CSV, append = TRUE)
fwrite(results_dt, OUT_CSV, append = TRUE, col.names = TRUE)
cat("\n# --- NS-long bucket-level RMSE, supplementary only ---\n", file = OUT_CSV, append = TRUE)
fwrite(ns_long_buckets, OUT_CSV, append = TRUE, col.names = TRUE)
cat("\n# --- excluded (no score for either model) ---\n", file = OUT_CSV, append = TRUE)
for (x in excluded_no_score) cat(sprintf("# %s\n", x), file = OUT_CSV, append = TRUE)

# ---------------------------------------------------------------------------------------------
# 6. Figure: headless PNG, 300 dpi, ggplot2, matches fig21_weighted_composite_score.png produced
#    by the Python run this session (bar + 95% bootstrap CI, common-cells composite %RMSE by
#    model under both NS treatments; second panel: stand-years weight per source)
# ---------------------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})

plot_rows <- results_dt[comparison == "common_cells"]
plot_rows[, model_label := factor(model, levels = c("base", "v1211", "osm"),
                                   labels = c("Base (v12.10.1)", "Candidate (v12.11)", "OSM-ACD (v2.26.1)"))]
plot_rows[, ns_label := factor(ns_treatment, levels = c("NS", "NS-long"),
                                labels = c("NS treatment\n(overall, n=4,504)",
                                           "NS-long treatment\n(all-consecutive-pairs, n=5,348)"))]

p1 <- ggplot(plot_rows, aes(x = ns_label, y = rmse, fill = model_label)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_errorbar(aes(ymin = rmse_lo, ymax = rmse_hi),
                position = position_dodge(width = 0.75), width = 0.2) +
  scale_fill_manual(values = c("Base (v12.10.1)" = "#999999",
                                "Candidate (v12.11)" = "#1b6ca8",
                                "OSM-ACD (v2.26.1)" = "#c1440e")) +
  labs(x = NULL, y = "Stand-years-weighted composite TOTVOL %RMSE", fill = NULL,
       title = "Common-cells composite %RMSE by model",
       subtitle = "7 shared sources; error bars = 95% source-cluster bootstrap CI") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

d_ns <- make_scenario("NS")
d_ns[, weight_v1211 := n_v1211 * interval]
d_ns[, is_maine := grepl("Maine|Baxter|PEF|SILC|CFRU|CTRN", dataset, ignore.case = TRUE)]
d_ns <- d_ns[order(weight_v1211)]
d_ns[, dataset := factor(dataset, levels = dataset)]

p2 <- ggplot(d_ns, aes(x = weight_v1211, y = dataset, fill = is_maine)) +
  geom_col() +
  scale_fill_manual(values = c(`TRUE` = "#1b6ca8", `FALSE` = "#c9c9c9"), guide = "none") +
  labs(x = expression(Stand-years~(n%*%interval[years])~", v12.11 weight basis"), y = NULL,
       title = "What drives the composite",
       subtitle = "Stand-years weight per source (NS treatment)") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

fig21 <- (p1 | p2) +
  plot_annotation(title = "Figure 21. Stand-years-weighted composite benchmark score, FVS-ACD v12.11 vs OSM-ACD v2.26.1 vs base v12.10.1")

ggsave(OUT_PNG, fig21, width = 13, height = 6, dpi = 300, bg = "white")

cat(sprintf("\nWrote %s\nWrote %s\n", OUT_CSV, OUT_PNG))
