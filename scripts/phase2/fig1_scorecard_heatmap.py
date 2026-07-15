#!/usr/bin/env python3
"""
Figure 1. Five-way scorecard heatmap for the FVS-ACD v12.10.1 benchmark.

Per-metric level bias (percent) with bootstrap 95 percent CIs and
green/yellow/red flags, nine NSVB metrics on the operational in-domain set
(POOLED_indomain), PLUS a clearly separated Overall composite row that shows
each model's PRIMARY %RMSE-weighted composite (0 to 100, higher is better).
The composite blends accuracy and precision in one number and is read straight
from composite_rmse_frozen.csv; the per-metric tiles remain the bias-and-CI view.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig1_scorecard_heatmap.R. This Python/matplotlib generator is the renderer that
actually produced the shipped PNG because R was not available in the build
sandbox (no root for apt, network behind a deny-all allowlist). Scores are read
straight from the authoritative frozen tables and are NOT recomputed.

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch, Rectangle
from matplotlib.colors import LinearSegmentedColormap, Normalize

# ----------------------------------------------------------------------------
# Paths
# ----------------------------------------------------------------------------
REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "data", "scorecard_five_v1210_corrected.csv")
COMP = os.path.join(REPO, "data", "composite_rmse_frozen.csv")
OUT  = os.path.join(REPO, "figures", "fig1_scorecard_heatmap.png")

# ----------------------------------------------------------------------------
# Flagship selection (do NOT recompute scores; read as-is)
# ----------------------------------------------------------------------------
SUBSET  = "POOLED_indomain"
MODELS  = ["v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM"]   # x, drop v12.7.1
METRICS = ["BA", "SDI", "QMD", "TOPHT", "TOTVOL",
           "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE"]              # y, BA at top

METRIC_LABEL = {
    "BA":       "Basal area (BA)",
    "SDI":      "Stand density index (SDI)",
    "QMD":      "Quadratic mean diameter (QMD)",
    "TOPHT":    "Top height (TOPHT)",
    "TOTVOL":   "Total volume (TOTVOL)",
    "MERCHVOL": "Merch volume (MERCHVOL)",
    "SAWVOL":   "Sawlog volume (SAWVOL)",
    "BIOMASS":  "Aboveground biomass (BIOMASS)",
    "VALUE":    "Stand value (VALUE)",
}

# Colorblind-safe, muted (not neon) flag palette
FLAG_FILL = {
    "green":  "#4C8C5A",   # muted forest green
    "yellow": "#E0B33A",   # gold
    "red":    "#C0504D",   # muted brick red
}

# Sequential ramp for the Overall composite (light -> forest green; higher = better)
COMP_CMAP = LinearSegmentedColormap.from_list(
    "comp_green", ["#EEF3EA", "#9CBF86", "#4C8C5A", "#265C36"])
COMP_NORM = Normalize(vmin=0, vmax=100)

def _text_color(hex_fill):
    """Pick black or white text for legibility against the fill luminance."""
    h = hex_fill.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    return "#111111" if lum > 0.55 else "#FFFFFF"

def _text_color_rgba(rgba):
    r, g, b = rgba[0], rgba[1], rgba[2]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    return "#111111" if lum > 0.55 else "#FFFFFF"

# ----------------------------------------------------------------------------
# Load and shape
# ----------------------------------------------------------------------------
df = pd.read_csv(DATA)
d = df[(df["subset"] == SUBSET) & (df["model"].isin(MODELS))].copy()
d["model"]  = pd.Categorical(d["model"],  categories=MODELS,  ordered=True)
d["metric"] = pd.Categorical(d["metric"], categories=METRICS, ordered=True)
d = d.sort_values(["metric", "model"])
n_val = int(d["n"].iloc[0])

# Overall %RMSE composite (0 to 100), one value per model
comp = pd.read_csv(COMP)
comp = comp[comp["stratum"] == SUBSET].set_index("model")
comp_val = {m: float(comp.loc[m, "composite_primary_rmse"]) for m in MODELS}
comp_rank = {m: int(comp.loc[m, "rank_primary_rmse"]) for m in MODELS}

# ----------------------------------------------------------------------------
# Figure
# ----------------------------------------------------------------------------
nrow, ncol = len(METRICS), len(MODELS)
OVR_GAP, OVR_H = 0.55, 1.0                 # gap below tiles, then the overall row
y_ovr = -(OVR_GAP + OVR_H)                  # bottom-left y of overall tiles

fig, ax = plt.subplots(figsize=(9, 7.9), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

# --- per-metric bias tiles (unchanged view) ---
for _, row in d.iterrows():
    xi = MODELS.index(row["model"])
    yi = METRICS.index(row["metric"])          # 0 = BA
    y  = nrow - 1 - yi                          # invert so BA sits at top
    fill = FLAG_FILL.get(row["flag"], "#BBBBBB")
    ax.add_patch(Rectangle((xi, y), 1, 1, facecolor=fill,
                           edgecolor="white", linewidth=1.6))
    tcol = _text_color(fill)
    bias = f"{row['bias_pct']:+.1f}%"
    ci   = f"[{row['bias_lo95']:.1f}, {row['bias_hi95']:.1f}]"
    ax.text(xi + 0.5, y + 0.62, bias, ha="center", va="center",
            fontsize=10.5, fontweight="bold", color=tcol)
    ax.text(xi + 0.5, y + 0.30, ci, ha="center", va="center",
            fontsize=7.6, color=tcol)

# --- Overall composite row (separated, own color encoding) ---
for xi, m in enumerate(MODELS):
    v = comp_val[m]
    rgba = COMP_CMAP(COMP_NORM(v))
    ax.add_patch(Rectangle((xi, y_ovr), 1, OVR_H, facecolor=rgba,
                           edgecolor="white", linewidth=1.6))
    tcol = _text_color_rgba(rgba)
    ax.text(xi + 0.5, y_ovr + 0.60, f"{v:.1f}", ha="center", va="center",
            fontsize=12.5, fontweight="bold", color=tcol)
    ax.text(xi + 0.5, y_ovr + 0.27, f"rank {comp_rank[m]}", ha="center",
            va="center", fontsize=7.8, color=tcol)

# separator line between the bias tiles and the composite row
ax.plot([0, ncol], [-(OVR_GAP) + 0.16, -(OVR_GAP) + 0.16],
        color="#888888", linewidth=0.8, linestyle=(0, (4, 3)))

# Axes framing
ax.set_xlim(0, ncol)
ax.set_ylim(y_ovr - 0.15, nrow)
ax.set_xticks(np.arange(ncol) + 0.5)
ax.set_xticklabels(MODELS, fontsize=10.5)
yt = list(np.arange(nrow) + 0.5) + [y_ovr + OVR_H / 2]
ytl = [METRIC_LABEL[m] for m in reversed(METRICS)] + ["Overall composite\n(%RMSE, 0 to 100)"]
ax.set_yticks(yt)
ax.set_yticklabels(ytl, fontsize=9.8)
# bold the overall composite y label
ax.get_yticklabels()[-1].set_fontweight("bold")
ax.xaxis.set_ticks_position("top")
ax.xaxis.set_label_position("top")
ax.tick_params(axis="both", length=0)
for spine in ax.spines.values():
    spine.set_visible(False)
ax.set_aspect("auto")

# Title (full figure width so it does not clip past the axes)
title = ("Figure 1. Five-way scorecard: per-metric level bias percent with bootstrap "
         "95% CIs and green/yellow/red\nflags (nine NSVB metrics), plus the Overall "
         "%RMSE-weighted composite (0 to 100, higher is better) on\nthe operational "
         f"in-domain set (n = {n_val})")
fig.suptitle(title, fontsize=10.6, fontweight="bold", x=0.012, ha="left", y=0.992)

# Flag legend (bias tiles) + composite note
legend_handles = [
    Patch(facecolor=FLAG_FILL["green"],  edgecolor="white",
          label="green  |bias| < 5% and NSE > 0.6"),
    Patch(facecolor=FLAG_FILL["yellow"], edgecolor="white",
          label="yellow  intermediate"),
    Patch(facecolor=FLAG_FILL["red"],    edgecolor="white",
          label="red  |bias| >= 10% or NSE < 0.4"),
]
leg = ax.legend(handles=legend_handles, loc="upper left",
                bbox_to_anchor=(0, -0.02), ncol=3, frameon=False,
                fontsize=8.6, handlelength=1.2, columnspacing=1.4,
                handletextpad=0.5, title="Per-metric bias tiles")
leg.get_title().set_fontsize(8.6)
leg.get_title().set_ha("left")
fig.text(0.275, 0.028,
         "Overall row: PRIMARY composite, weighted mean of nine metric scores "
         "(metric_score = 100 x max(0, 1 - %RMSE/100);\nvolume and value weighted "
         "highest). Green scale runs 0 (light) to 100 (dark); it is a separate "
         "encoding from the bias tiles above.",
         fontsize=7.6, color="#333333", ha="left", va="top")

fig.subplots_adjust(left=0.275, right=0.99, top=0.855, bottom=0.135)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo the plotted flagship table + composite to stdout
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}")
print(f"n (POOLED_indomain) = {n_val}\n")
print(f"{'metric':<9}{'model':<11}{'bias_pct':>10}{'lo95':>9}{'hi95':>9}  flag")
for _, row in d.iterrows():
    print(f"{str(row['metric']):<9}{str(row['model']):<11}"
          f"{row['bias_pct']:>+10.1f}{row['bias_lo95']:>9.1f}"
          f"{row['bias_hi95']:>9.1f}  {row['flag']}")
print("\nOverall %RMSE composite (primary):")
for m in MODELS:
    print(f"  {m:<11}{comp_val[m]:>7.1f}   rank {comp_rank[m]}")
