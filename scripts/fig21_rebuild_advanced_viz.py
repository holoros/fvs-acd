#!/usr/bin/env python3
"""
fig21_rebuild_advanced_viz.py

Rebuilds figures/fig21_weighted_composite_score.png to satisfy the advanced-viz house-style
uncertainty and disclosure gates. Does NOT recompute anything: every number plotted here is read
straight out of figures/_data/composite_score_weighted.csv, the frozen output of
scripts/composite_score_weighted.py (executed earlier this session; source-level cluster
bootstrap, n=2000 resamples, seed=20260811, 95% percentile interval). This script only changes
how those numbers are drawn: palette, error bars, per-dataset n/interval annotation, and a
below-figure caption in journal register.

[STACK: Python smoke render this session; R/ggplot2 script written for Cardinal, not executed]
See scripts/fig21_weighted_composite_score.R for the canonical, unexecuted R/ggplot2 equivalent.

Palette choice:
  Panel 1 (3 categories: base v12.10.1 / candidate v12.11 / OSM-ACD v2.26.1) uses three discrete
  stops sampled from the GSEA-style purple-to-blue-to-lavender-to-pink-to-red journal-register
  ramp (purple start, lavender midpoint, red end), because the paired teal/salmon scheme is built
  for two-way comparisons and this panel has three model categories.
  Panel 2 (Maine-labeled sources vs NB/QC/NS sources, a genuine two-way split) uses the paired
  teal/salmon scheme (#1B9E9E / #E15554) instead, which is the better fit for a binary contrast.
"""

import os
import re
import numpy as np
import pandas as pd
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IN_CSV = os.path.join(REPO_ROOT, "figures/_data/composite_score_weighted.csv")
OUT_PNG = os.path.join(REPO_ROOT, "figures/fig21_weighted_composite_score.png")

# ---------------------------------------------------------------------------
# 1. Parse the frozen CSV (multi-section file: row detail, then composite results,
#    then NS-long bucket table, then exclusions), splitting on the "# ---" section markers.
# ---------------------------------------------------------------------------
with open(IN_CSV) as f:
    raw_lines = f.readlines()

section_starts = [i for i, l in enumerate(raw_lines) if l.startswith("# ---")]
section_starts.append(len(raw_lines))

# section 0: row detail (header at line 0, data until first "# ---")
detail_block = "".join(raw_lines[0:section_starts[0]])
detail_df = pd.read_csv(pd.io.common.StringIO(detail_block))

# section 1: composite results (header right after its "# ---" marker)
res_start = section_starts[0] + 1
res_end = section_starts[1]
results_block = "".join(l for l in raw_lines[res_start:res_end] if l.strip())
results_df = pd.read_csv(pd.io.common.StringIO(results_block))

print(f"Read {len(detail_df)} detail rows, {len(results_df)} composite result rows from {IN_CSV}")

# ---------------------------------------------------------------------------
# 2. Palette
# ---------------------------------------------------------------------------
model_order = ["base", "v1211", "osm"]
model_labels = {
    "base": "Base\n(v12.10.1)",
    "v1211": "Candidate\n(v12.11)",
    "osm": "OSM-ACD\n(v2.26.1)",
}
# GSEA-ramp endpoints + midpoint (purple -> lavender -> red), sampled discretely for 3 categories
model_colors = {"base": "#762A83", "v1211": "#9970AB", "osm": "#B2182B"}

TEAL = "#1B9E9E"
SALMON = "#E15554"

# ---------------------------------------------------------------------------
# 3. Figure
# ---------------------------------------------------------------------------
fig, axes = plt.subplots(1, 2, figsize=(14, 7.2), gridspec_kw={"width_ratios": [1.3, 1]})
ax1, ax2 = axes

# --- Panel 1: common-cells composite %RMSE by model, both NS treatments, 95% bootstrap CI ---
plot_rows = results_df[results_df["comparison"] == "common_cells"].copy()
x_positions = {"NS": 0, "NS-long": 1}
width = 0.25
offsets = {"base": -width, "v1211": 0, "osm": width}

n_sources_by_treat = {}
n_stands_by_treat = {}

for model in model_order:
    xs, ys, lo, hi = [], [], [], []
    for ns_treat in ["NS", "NS-long"]:
        row = plot_rows[(plot_rows["ns_treatment"] == ns_treat) & (plot_rows["model"] == model)].iloc[0]
        xs.append(x_positions[ns_treat] + offsets[model])
        ys.append(row["rmse"])
        lo.append(row["rmse"] - row["rmse_lo"])
        hi.append(row["rmse_hi"] - row["rmse"])
        n_sources_by_treat[ns_treat] = int(row["n_sources"])
        n_stands_by_treat.setdefault(ns_treat, {})[model] = int(row["n_stands"])
    ax1.bar(xs, ys, width=width * 0.9, color=model_colors[model],
            label=model_labels[model].replace("\n", " "), zorder=3)
    ax1.errorbar(xs, ys, yerr=[lo, hi], fmt="none", ecolor="black", capsize=4,
                 linewidth=1.3, zorder=4)
    # per-bar point-estimate label
    for x, y in zip(xs, ys):
        ax1.text(x, y + 3, f"{y:.1f}", ha="center", va="bottom", fontsize=7.5)

xtick_labels = []
for ns_treat, disp in [("NS", "NS treatment\n(overall)"), ("NS-long", "NS-long treatment\n(all-consecutive-pairs)")]:
    k = n_sources_by_treat[ns_treat]
    n_range = sorted(set(n_stands_by_treat[ns_treat].values()))
    n_txt = f"n={min(n_range):,}" + (f"-{max(n_range):,}" if min(n_range) != max(n_range) else "")
    xtick_labels.append(f"{disp}\n{k} source-clusters, {n_txt} stands")

ax1.set_xticks([0, 1])
ax1.set_xticklabels(xtick_labels, fontsize=9)
ax1.set_ylabel("Stand-years-weighted composite TOTVOL %RMSE")
ax1.set_title("(a) Common-cells composite %RMSE by model\n7 shared sources; error bars = 95% bootstrap CI", fontsize=10.5)
ax1.legend(loc="upper right", fontsize=9, frameon=False)
ax1.spines[["top", "right"]].set_visible(False)
ax1.set_ylim(0, plot_rows["rmse_hi"].max() * 1.12)

# --- Panel 2: stand-years weight per dataset, NS treatment, with n and interval-years annotated ---
d_ns = detail_df[detail_df["ns_treatment"] == "NS"].copy()
d_ns = d_ns.sort_values("weight_v1211", ascending=True).reset_index(drop=True)
is_maine = d_ns["dataset"].str.contains("Maine|Baxter|PEF|SILC|CFRU|CTRN", case=False, regex=True)
bar_colors = [TEAL if m else SALMON for m in is_maine]

ax2.barh(d_ns["dataset"], d_ns["weight_v1211"], color=bar_colors, zorder=3)
ax2.set_xlabel("Stand-years (n × interval$_{years}$), v12.11 weight basis")
ax2.set_title("(b) Stand-years weight per source\n(NS treatment); n and interval annotated per bar", fontsize=10.5)
ax2.spines[["top", "right"]].set_visible(False)

xmax = d_ns["weight_v1211"].max()
for i, row in d_ns.iterrows():
    n_val = int(row["n_v1211"])
    interval_val = row["interval_years"]
    label = f"n={n_val:,}, {interval_val:.1f} yr"
    ax2.text(row["weight_v1211"] + xmax * 0.015, i, label, va="center", ha="left", fontsize=7.3)

ax2.set_xlim(0, xmax * 1.30)

# legend proxies for Maine vs non-Maine
from matplotlib.patches import Patch
maine_total = d_ns.loc[is_maine, "weight_v1211"].sum()
all_total = d_ns["weight_v1211"].sum()
ax2.legend(
    handles=[Patch(color=TEAL, label="Maine source"), Patch(color=SALMON, label="NB / QC / NS source")],
    loc="upper right", bbox_to_anchor=(1.0, 0.30), fontsize=8, frameon=False,
)
ax2.annotate(f"Maine sources = {maine_total/all_total:.0%} of total stand-years weight",
             xy=(0.98, 0.06), xycoords="axes fraction", ha="right", va="bottom",
             fontsize=8, style="italic")

# ---------------------------------------------------------------------------
# 4. Title (bold label) and caption (below figure, journal register, upright sentence)
# ---------------------------------------------------------------------------
fig.suptitle(
    "Figure 21. Stand-years-weighted composite benchmark score, FVS-ACD v12.11 vs OSM-ACD v2.26.1 vs base v12.10.1",
    fontsize=12, fontweight="bold", y=1.03, x=0.5,
)

total_n = sum(n_stands_by_treat["NS"].values())
caption = (
    "Common-cells composite total-volume percent RMSE (panel a) pools seven benchmark sources "
    "shared by all three models, weighted by stand-years of observation (n × remeasurement "
    "interval in years); panel b shows the stand-years weight each source contributes under the "
    "NS treatment, with each source's n and interval in years labeled directly on its bar. Error "
    "bars are 95% bootstrap percentile intervals from a source-level cluster resample (resampling "
    "unit = benchmark source, not plot), n = 2,000 resamples, seed 20260811; the common-cells "
    "comparison in panel a resamples 7 source-clusters in both scenarios shown, rising to 9 in the "
    "fuller v12.11-only composite reported in the text but not plotted here, which is coarser than "
    "a plot-level bootstrap and widens the intervals accordingly. Total n across the seven "
    "common-cells sources is 9,880 stands (NS treatment) / 10,724 stands (NS-long treatment), "
    "summing to roughly 89,000 and 113,000 stand-years respectively. Data: "
    "figures/_data/composite_score_weighted.csv. Source write-up: 20260811_weighted_composite_score.md."
)
fig.text(0.02, -0.10, caption, ha="left", va="top", fontsize=8.3, wrap=True,
          transform=fig.transFigure)

fig.tight_layout(rect=[0, 0.02, 1, 0.98])
fig.savefig(OUT_PNG, dpi=300, bbox_inches="tight")
print(f"Wrote {OUT_PNG}")
