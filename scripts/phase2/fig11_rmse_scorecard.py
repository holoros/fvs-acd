#!/usr/bin/env python3
"""
Figure 11. Percent RMSE scorecard heatmap for the FVS-ACD frozen benchmark.

Model x metric heatmap of %RMSE (= 100 * RMSE / mean observed) on the
operational in-domain set (POOLED_indomain, n = 705). %RMSE blends accuracy and
precision in one number, so it does not deflate on high-mean metrics the way a
percent-bias tile can. Lower is better, so the colour ramp runs dark (low %RMSE,
good) to light/warm (high %RMSE, poor). Each cell prints %RMSE with its
within-province stratified bootstrap 95 percent interval.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig11_rmse_scorecard.R. This Python/matplotlib generator produced the shipped
PNG because R is not available in the build sandbox. Values are read straight
from scorecard_rmse_frozen.csv and are NOT recomputed.

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from matplotlib.colors import LinearSegmentedColormap, Normalize
from matplotlib.cm import ScalarMappable

REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "data", "scorecard_rmse_frozen.csv")
OUT = os.path.join(REPO, "figures", "fig11_rmse_scorecard.png")

SUBSET = "POOLED_indomain"
MODELS = ["v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM"]
METRICS = ["BA", "SDI", "QMD", "TOPHT", "TOTVOL",
           "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE"]
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

# lower %RMSE is better -> dark green (good) to warm (poor)
CMAP = LinearSegmentedColormap.from_list(
    "rmse_gyr", ["#1A5D33", "#4C8C5A", "#9CBF86", "#E7D67A",
                 "#E0A03A", "#C0504D", "#8E2A28"])
VMIN, VMAX = 20, 90
NORM = Normalize(vmin=VMIN, vmax=VMAX)


def _text_color_rgba(rgba):
    lum = 0.299 * rgba[0] + 0.587 * rgba[1] + 0.114 * rgba[2]
    return "#111111" if lum > 0.60 else "#FFFFFF"


df = pd.read_csv(DATA)
d = df[(df["stratum"] == SUBSET) & (df["model"].isin(MODELS))].copy()
n_val = int(d["n"].iloc[0])
piv = d.pivot_table(index="metric", columns="model", values="pct_rmse")
lo = d.pivot_table(index="metric", columns="model", values="pct_rmse_lo95")
hi = d.pivot_table(index="metric", columns="model", values="pct_rmse_hi95")

nrow, ncol = len(METRICS), len(MODELS)
fig, ax = plt.subplots(figsize=(9.6, 7.7), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

for yi, met in enumerate(METRICS):
    y = nrow - 1 - yi
    for xi, mod in enumerate(MODELS):
        v = float(piv.loc[met, mod])
        rgba = CMAP(NORM(v))
        ax.add_patch(Rectangle((xi, y), 1, 1, facecolor=rgba,
                               edgecolor="white", linewidth=1.6))
        tcol = _text_color_rgba(rgba)
        ax.text(xi + 0.5, y + 0.60, f"{v:.1f}", ha="center", va="center",
                fontsize=10.5, fontweight="bold", color=tcol)
        ax.text(xi + 0.5, y + 0.30,
                f"[{lo.loc[met, mod]:.0f}, {hi.loc[met, mod]:.0f}]",
                ha="center", va="center", fontsize=7.2, color=tcol)

ax.set_xlim(0, ncol)
ax.set_ylim(0, nrow)
ax.set_xticks(np.arange(ncol) + 0.5)
ax.set_xticklabels(MODELS, fontsize=10.5)
ax.set_yticks(np.arange(nrow) + 0.5)
ax.set_yticklabels([METRIC_LABEL[m] for m in reversed(METRICS)], fontsize=9.8)
ax.xaxis.set_ticks_position("top")
ax.xaxis.set_label_position("top")
ax.tick_params(axis="both", length=0)
for spine in ax.spines.values():
    spine.set_visible(False)
ax.set_aspect("auto")

title = ("Figure 11. Percent RMSE scorecard (%RMSE = 100 x RMSE / mean observed), nine "
         "NSVB metrics by model\non the operational in-domain set (n = "
         f"{n_val}). Lower is better; brackets are within-province bootstrap 95%\n"
         "intervals. %RMSE blends accuracy and precision, so it does not deflate on "
         "high-mean metrics.")
fig.suptitle(title, fontsize=10.4, fontweight="bold", x=0.012, ha="left", y=0.992)

# colourbar
sm = ScalarMappable(norm=NORM, cmap=CMAP)
sm.set_array([])
cbar = fig.colorbar(sm, ax=ax, orientation="vertical", fraction=0.045,
                    pad=0.02, extend="both")
cbar.set_label("%RMSE (lower is better)", fontsize=9)
cbar.ax.tick_params(labelsize=8)

fig.subplots_adjust(left=0.285, right=0.995, top=0.855, bottom=0.03)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

print(f"Wrote: {OUT}")
print(f"n (POOLED_indomain) = {n_val}\n")
print(piv.reindex(index=METRICS, columns=MODELS).round(1).to_string())
