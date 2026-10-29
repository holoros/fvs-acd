#!/usr/bin/env python3
"""
composite_score_weighted.py

Stand-years-weighted overall composite benchmark score for FVS-ACD v12.11 (candidate),
OSM-ACD v2.26.1, and base v12.10.1, pooled across the project's named benchmark sources.

[STACK: Python, R/Cardinal unavailable this session]. This is the executed equivalent of the
canonical production script scripts/composite_score_weighted.R, which should be re-run on
Cardinal (data.table) once HPC access is restored, against the same two source CSVs, to confirm
these numbers exactly. No underlying model score is recomputed here; this script only combines
already-frozen TOTVOL %RMSE / %bias values from figures/_data/master_scorecard_sources.csv and
figures/_data/master_scorecard.csv.

Weighting formula: weight = n * interval_years ("stand-years of observation"), the standard way
to pool error metrics across studies of different sample size and remeasurement length. More
stand-years is more information, both because there are more plots and because a longer interval
is a harder, more informative test of long-horizon model behavior. This is a chosen weighting
scheme, not the only defensible one; inverse-variance weighting is the classical meta-analytic
alternative but requires a per-source variance estimate that is not available at this
aggregation level (only point RMSE/bias per source, not the underlying plot-level residuals).

Bootstrap: only source-level aggregates exist in this sandbox (no row-level plot data to
resample), so the bootstrap resamples AT THE SOURCE level -- each included dataset is one
cluster, resampled with replacement, 2000 iterations, 2.5/97.5 percentile interval reported.
This is a coarser resampling unit than the plot-level bootstrap Aaron's modeling philosophy
prefers (principle 15/16: no point estimate travels alone) because there are fewer than a dozen
clusters total in any scenario here. A proper plot-level bootstrap on Cardinal would resample
individual stand-pairs (plot x remeasurement) within each source, which requires the row-level
scored output (e.g. cb_v12102_results.csv-style per-stand residuals) rather than the
already-aggregated per-source RMSE/bias this sandbox has access to.
"""

import json
import numpy as np
import pandas as pd

RNG_SEED = 20260811
N_BOOT = 2000

import os

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_CSV = os.path.join(REPO_ROOT, "figures/_data/composite_score_weighted.csv")
OUT_PNG = os.path.join(REPO_ROOT, "figures/fig21_weighted_composite_score.png")
SRC_CSV = os.path.join(REPO_ROOT, "figures/_data/master_scorecard_sources.csv")

rng = np.random.default_rng(RNG_SEED)

# ---------------------------------------------------------------------------
# 1. Row-level input table: n, interval_years (with flags), RMSE/bias per model
# ---------------------------------------------------------------------------
# All RMSE/bias values below are read directly from figures/_data/master_scorecard_sources.csv
# (TOTVOL_rmse_pct, TOTVOL_bias_pct). NS-long uses the pooled bench_ns_long_scorecard row from
# that same file. Interval-year values and their evidence flags are as researched this session
# and specified in the task brief; see the ASSUMPTION/UNKNOWN tags in each row's `interval_flag`.

rows = [
    # dataset_id, n_base, n_v1211, n_osm, interval_years, interval_flag,
    # base_rmse, base_bias, v1211_rmse, v1211_bias, osm_rmse, osm_bias, osm_available
    dict(dataset="Baxter (mature, held-out)", n_base=91, n_v1211=91, n_osm=91,
         interval=11.0, interval_flag="STATED",
         base_rmse=48.28, base_bias=9.12, v1211_rmse=48.14, v1211_bias=6.92,
         osm_rmse=50.81, osm_bias=12.37, osm_available=True),
    dict(dataset="CFRU CTRN (managed)", n_base=1086, n_v1211=1086, n_osm=1033,
         interval=1.0, interval_flag="STATED",
         base_rmse=24.81, base_bias=-9.78, v1211_rmse=18.06, v1211_bias=-2.24,
         osm_rmse=20.51, osm_bias=-4.81, osm_available=True),
    dict(dataset="Maine FIA subplot (developing)", n_base=2858, n_v1211=2858, n_osm=np.nan,
         interval=20.0, interval_flag="ASSUMPTION: same population as ME FIA whole-plot/long, finer grain",
         base_rmse=51.11, base_bias=-24.90, v1211_rmse=51.26, v1211_bias=-24.82,
         osm_rmse=np.nan, osm_bias=np.nan, osm_available=False),
    dict(dataset="Maine FIA whole-plot (= 20-yr long)", n_base=918, n_v1211=918, n_osm=918,
         interval=20.0, interval_flag="STATED",
         base_rmse=38.67, base_bias=-16.60, v1211_rmse=38.56, v1211_bias=-16.13,
         osm_rmse=31.93, osm_bias=-6.29, osm_available=True),
    dict(dataset="PEF (developing)", n_base=2853, n_v1211=2853, n_osm=2853,
         interval=1.0, interval_flag="UNKNOWN: no stated interval; excluded from temporal weight, n-only weighting used (weight=n*1); NB/QC combined-mean proxy rejected as cross-network borrowing (PEF is a distinct plot system, not part of the NB/QC legacy set)",
         base_rmse=18.03, base_bias=1.23, v1211_rmse=17.91, v1211_bias=1.37,
         osm_rmse=14.65, osm_bias=0.26, osm_available=True),
    dict(dataset="SILC/Seven Islands (calibration, managed)", n_base=73, n_v1211=73, n_osm=69,
         interval=11.5, interval_flag="ASSUMPTION: midpoint of stated 8-15 yr range for the n=60 long-horizon subset, applied to the full n=73 (subset identity not confirmed)",
         base_rmse=65.01, base_bias=-6.34, v1211_rmse=64.24, v1211_bias=-5.65,
         osm_rmse=62.99, osm_bias=-18.07, osm_available=True),
    dict(dataset="NB MagPlot (managed)", n_base=355, n_v1211=355, n_osm=355,
         interval=7.0, interval_flag="ASSUMPTION: NB+QC combined legacy mean (~7 yr) applied to NB individually",
         base_rmse=48.88, base_bias=-11.84, v1211_rmse=41.85, v1211_bias=-5.96,
         osm_rmse=43.77, osm_bias=-8.07, osm_available=True),
    dict(dataset="QC MagPlot (managed)", n_base=378, n_v1211=378, n_osm=np.nan,
         interval=7.0, interval_flag="ASSUMPTION: NB+QC combined legacy mean (~7 yr) applied to QC individually",
         base_rmse=59.34, base_bias=1.23, v1211_rmse=58.50, v1211_bias=9.46,
         osm_rmse=np.nan, osm_bias=np.nan, osm_available=False),
]

NS_ROW = dict(dataset="NS (overall, bench_ns_scorecard)", n_base=4504, n_v1211=4504, n_osm=4499,
              interval=5.1, interval_flag="ASSUMPTION: NS-long's own <15 yr bucket mean (5.1 yr, n=3939) applied to NS overall per pass-6 handoff language placing NS overall in the same <15 yr band",
              base_rmse=182.44, base_bias=-41.28, v1211_rmse=156.69, v1211_bias=-30.61,
              osm_rmse=153.05, osm_bias=-29.22, osm_available=True)

# NS-long pooled row. Bucket-level RMSE by model IS recoverable from master_scorecard.csv
# (determinant=projection_length, region=NS: <15 n=3939, 15-30 n=506, >30 n=903, matching NS-long's
# n=5348 exactly, 3939+506+903=5348). Bucket-level BIAS is NOT present in that file (RMSE-only
# columns). To keep the RMSE and bias composites built from an identical, consistent row set (and
# to keep bootstrap cluster counts consistent across metrics), this script uses the single pooled
# NS-long row (bench_ns_long_scorecard) for BOTH metrics in the primary composite. The three-bucket
# RMSE-only breakdown is reported separately below (not fed into the bootstrap) as a finding: the
# bucket-level breakdown could not be applied to weighting for bias, only for RMSE, and mixing row
# counts between the two metrics would make the composite internally inconsistent.
NS_LONG_BUCKETS = pd.DataFrame([
    dict(bucket="<15 yr", n=3939, interval=5.1, base_rmse=163.46, v1211_rmse=132.88, osm_rmse=134.24),
    dict(bucket="15-30 yr", n=506, interval=21.9, base_rmse=145.83, v1211_rmse=127.29, osm_rmse=127.57),
    dict(bucket=">30 yr", n=903, interval=36.3, base_rmse=49.79, v1211_rmse=52.35, osm_rmse=50.28),
])
NS_LONG_POOLED_INTERVAL = float((NS_LONG_BUCKETS["n"] * NS_LONG_BUCKETS["interval"]).sum() / NS_LONG_BUCKETS["n"].sum())

NS_LONG_ROW = dict(dataset="NS-long (all-consecutive-pairs, bench_ns_long_scorecard)",
                    n_base=5348, n_v1211=5348, n_osm=5344,
                    interval=NS_LONG_POOLED_INTERVAL,
                    interval_flag=f"COMPUTED: n-weighted mean of NS-long's own three stated projection-length bucket means (<15 yr 5.1, n=3939; 15-30 yr 21.9, n=506; >30 yr 36.3, n=903) = {NS_LONG_POOLED_INTERVAL:.2f} yr. Bucket-level RMSE by model is recoverable and reported separately below; bucket-level bias is not present in master_scorecard.csv, so the pooled row is used for both metrics here to keep row counts consistent",
                    base_rmse=153.97, base_bias=-39.75, v1211_rmse=127.35, v1211_bias=-30.41,
                    osm_rmse=128.34, osm_bias=-31.99, osm_available=True)

df_base = pd.DataFrame(rows)

# memat / medev: EXCLUDED explicitly. No score exists for either v12.11 or OSM per the finalized
# scorecard (20260811_final_scorecard_all_datasets.md, Table 30); a composite cannot weight a
# score that does not exist. They are not in `rows` above and are not silently dropped -- they are
# named here and in the report.
EXCLUDED_NO_SCORE = ["Maine FIA mature (memat, n=1757)", "Maine FIA control (medev, n=1759)"]


def make_scenario_df(ns_treatment):
    d = df_base.copy()
    ns_row = NS_ROW if ns_treatment == "NS" else NS_LONG_ROW
    d = pd.concat([d, pd.DataFrame([ns_row])], ignore_index=True)
    return d


def weighted_composite(d, model, restrict_common_cells=False):
    """weight = n_model * interval_years; drop rows missing this model's score."""
    d = d.copy()
    if restrict_common_cells:
        d = d[d["osm_available"]]
    n_col = {"base": "n_base", "v1211": "n_v1211", "osm": "n_osm"}[model]
    rmse_col = f"{model}_rmse"
    bias_col = f"{model}_bias"
    d = d[d[rmse_col].notna() & d[n_col].notna()]
    w = d[n_col] * d["interval"]
    rmse = float((w * d[rmse_col]).sum() / w.sum())
    bias = float((w * d[bias_col]).sum() / w.sum())
    return rmse, bias, d, w


def bootstrap_composite(d, model, restrict_common_cells=False, n_boot=N_BOOT, seed_offset=0):
    d = d.copy()
    if restrict_common_cells:
        d = d[d["osm_available"]]
    n_col = {"base": "n_base", "v1211": "n_v1211", "osm": "n_osm"}[model]
    rmse_col = f"{model}_rmse"
    bias_col = f"{model}_bias"
    d = d[d[rmse_col].notna() & d[n_col].notna()].reset_index(drop=True)
    k = len(d)
    local_rng = np.random.default_rng(RNG_SEED + seed_offset)
    rmse_draws = np.empty(n_boot)
    bias_draws = np.empty(n_boot)
    n_arr = d[n_col].to_numpy()
    interval_arr = d["interval"].to_numpy()
    rmse_arr = d[rmse_col].to_numpy()
    bias_arr = d[bias_col].to_numpy()
    for b in range(n_boot):
        idx = local_rng.integers(0, k, size=k)
        w = n_arr[idx] * interval_arr[idx]
        rmse_draws[b] = np.sum(w * rmse_arr[idx]) / np.sum(w)
        bias_draws[b] = np.sum(w * bias_arr[idx]) / np.sum(w)
    rmse_ci = np.percentile(rmse_draws, [2.5, 97.5])
    bias_ci = np.percentile(bias_draws, [2.5, 97.5])
    return rmse_ci, bias_ci, k


# ---------------------------------------------------------------------------
# 2. Run all scenarios
# ---------------------------------------------------------------------------
results = []
detail_rows = []

for ns_treat in ["NS", "NS-long"]:
    d = make_scenario_df(ns_treat)

    # store row-level detail (for CSV output), tagged by scenario
    for _, r in d.iterrows():
        detail_rows.append(dict(
            ns_treatment=ns_treat, dataset=r["dataset"],
            n_base=r["n_base"], n_v1211=r["n_v1211"], n_osm=r["n_osm"],
            interval_years=round(r["interval"], 2), interval_flag=r["interval_flag"],
            weight_base=r["n_base"] * r["interval"] if pd.notna(r["n_base"]) else np.nan,
            weight_v1211=r["n_v1211"] * r["interval"] if pd.notna(r["n_v1211"]) else np.nan,
            weight_osm=(r["n_osm"] * r["interval"]) if pd.notna(r["n_osm"]) else np.nan,
            base_rmse=r["base_rmse"], base_bias=r["base_bias"],
            v1211_rmse=r["v1211_rmse"], v1211_bias=r["v1211_bias"],
            osm_rmse=r["osm_rmse"], osm_bias=r["osm_bias"],
            osm_available=r["osm_available"],
        ))

    # v1211-only, ALL rows it has data for (context figure, not head-to-head)
    rmse, bias, dd, w = weighted_composite(d, "v1211", restrict_common_cells=False)
    rmse_ci, bias_ci, k = bootstrap_composite(d, "v1211", restrict_common_cells=False, seed_offset=1)
    results.append(dict(ns_treatment=ns_treat, comparison="v1211_all_own_data", model="v1211",
                         n_sources=k, n_stands=int(dd[{"v1211":"n_v1211"}["v1211"]].sum()),
                         rmse=rmse, rmse_lo=rmse_ci[0], rmse_hi=rmse_ci[1],
                         bias=bias, bias_lo=bias_ci[0], bias_hi=bias_ci[1]))

    # common-cells head-to-head: base, v1211, osm on the 7 shared rows
    for model in ["base", "v1211", "osm"]:
        rmse, bias, dd, w = weighted_composite(d, model, restrict_common_cells=True)
        rmse_ci, bias_ci, k = bootstrap_composite(d, model, restrict_common_cells=True, seed_offset=2)
        n_col = {"base": "n_base", "v1211": "n_v1211", "osm": "n_osm"}[model]
        results.append(dict(ns_treatment=ns_treat, comparison="common_cells", model=model,
                             n_sources=k, n_stands=int(dd[n_col].sum()),
                             rmse=rmse, rmse_lo=rmse_ci[0], rmse_hi=rmse_ci[1],
                             bias=bias, bias_lo=bias_ci[0], bias_hi=bias_ci[1]))

results_df = pd.DataFrame(results)
detail_df = pd.DataFrame(detail_rows)

print("=" * 100)
print("STAND-YEARS-WEIGHTED COMPOSITE SCORES")
print("=" * 100)
with pd.option_context("display.width", 200, "display.max_columns", None):
    print(results_df.round(2))

print()
print("NS-long bucket-level RMSE (supplementary, RMSE only, not fed into the bootstrap):")
print(NS_LONG_BUCKETS)
print(f"NS-long pooled interval (n-weighted mean of buckets): {NS_LONG_POOLED_INTERVAL:.2f} yr")

print()
print("Excluded from the composite (no score for either model):", EXCLUDED_NO_SCORE)

# ---------------------------------------------------------------------------
# 3. Write CSV
# ---------------------------------------------------------------------------
detail_df.to_csv(OUT_CSV, index=False)
# append composite results and bucket table below the per-row detail, same file, clearly sectioned
with open(OUT_CSV, "a") as f:
    f.write("\n# --- composite results (stand-years weighted, bootstrap 2.5/97.5 pct, source-level cluster resample, n_boot=%d, seed=%d) ---\n" % (N_BOOT, RNG_SEED))
    results_df.to_csv(f, index=False)
    f.write("\n# --- NS-long bucket-level RMSE, supplementary only, RMSE not bias, not used in bootstrap ---\n")
    NS_LONG_BUCKETS.to_csv(f, index=False)
    f.write("\n# --- excluded (no score for either model) ---\n")
    for x in EXCLUDED_NO_SCORE:
        f.write(f"# {x}\n")

print(f"\nWrote {OUT_CSV}")

# ---------------------------------------------------------------------------
# 4. Figure
# ---------------------------------------------------------------------------
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

fig, axes = plt.subplots(1, 2, figsize=(13, 6), gridspec_kw={"width_ratios": [1.3, 1]})
ax1, ax2 = axes

model_order = ["base", "v1211", "osm"]
model_labels = {"base": "Base\n(v12.10.1)", "v1211": "Candidate\n(v12.11)", "osm": "OSM-ACD\n(v2.26.1)"}
model_colors = {"base": "#999999", "v1211": "#1b6ca8", "osm": "#c1440e"}

# Panel 1: common-cells head-to-head composite %RMSE, both NS treatments, with bootstrap CI
plot_rows = results_df[results_df["comparison"] == "common_cells"].copy()
x_positions = {"NS": 0, "NS-long": 1}
width = 0.25
offsets = {"base": -width, "v1211": 0, "osm": width}

for model in model_order:
    xs, ys, lo, hi = [], [], [], []
    for ns_treat in ["NS", "NS-long"]:
        row = plot_rows[(plot_rows["ns_treatment"] == ns_treat) & (plot_rows["model"] == model)].iloc[0]
        xs.append(x_positions[ns_treat] + offsets[model])
        ys.append(row["rmse"])
        lo.append(row["rmse"] - row["rmse_lo"])
        hi.append(row["rmse_hi"] - row["rmse"])
    ax1.bar(xs, ys, width=width * 0.9, color=model_colors[model], label=model_labels[model].replace("\n", " "))
    ax1.errorbar(xs, ys, yerr=[lo, hi], fmt="none", ecolor="black", capsize=4, linewidth=1.3)

ax1.set_xticks([0, 1])
ax1.set_xticklabels(["NS treatment\n(overall, n=4,504)", "NS-long treatment\n(all-consecutive-pairs, n=5,348)"])
ax1.set_ylabel("Stand-years-weighted composite TOTVOL %RMSE")
ax1.set_title("Common-cells composite %RMSE by model\n(7 shared sources; error bars = 95% source-cluster bootstrap CI)", fontsize=10)
ax1.legend(loc="upper right", fontsize=9, frameon=False)
ax1.spines[["top", "right"]].set_visible(False)

# Panel 2: stand-years weight contributed by each dataset (drives the composite), NS treatment shown
d_ns = make_scenario_df("NS")
d_ns = d_ns.assign(weight_v1211=d_ns["n_v1211"] * d_ns["interval"])
d_ns = d_ns.sort_values("weight_v1211", ascending=True)
is_maine = d_ns["dataset"].str.contains("Maine|Baxter|PEF|SILC|CFRU|CTRN", case=False)
bar_colors = ["#1b6ca8" if m else "#c9c9c9" for m in is_maine]

ax2.barh(d_ns["dataset"], d_ns["weight_v1211"], color=bar_colors)
ax2.set_xlabel("Stand-years (n x interval_years), v12.11 weight basis")
ax2.set_title("What drives the composite:\nstand-years weight per source (NS treatment)", fontsize=10)
ax2.spines[["top", "right"]].set_visible(False)
maine_total = d_ns.loc[is_maine, "weight_v1211"].sum()
all_total = d_ns["weight_v1211"].sum()
ax2.annotate(f"Maine sources (Baxter, CFRU CTRN, FIA subplot/whole-plot,\nPEF, SILC) = {maine_total/all_total:.0%} of total stand-years weight",
             xy=(0.98, 0.03), xycoords="axes fraction", ha="right", va="bottom", fontsize=8, style="italic")

fig.suptitle("Figure 21. Stand-years-weighted composite benchmark score, FVS-ACD v12.11 vs OSM-ACD v2.26.1 vs base v12.10.1",
              fontsize=11, fontweight="bold", y=1.02)
fig.tight_layout()
fig.savefig(OUT_PNG, dpi=300, bbox_inches="tight")
print(f"Wrote {OUT_PNG}")

# ---------------------------------------------------------------------------
# 5. Dump a JSON of headline numbers for the markdown-writing step
# ---------------------------------------------------------------------------
headline = results_df.round(2).to_dict(orient="records")
print(json.dumps(headline, indent=2))
