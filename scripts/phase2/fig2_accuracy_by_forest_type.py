#!/usr/bin/env python3
"""
Figure 2. Total volume level bias by forest type.

Total volume level bias (percent) for softwood, mixedwood, and hardwood stands
across the five entrants (v12.5.0, v12.7.0, v12.7.1, v12.9.x, OSM v2.26.1). The
shaded band is the +/- 10 percent equivalence region; a check mark flags a
model x forest-type cell that is statistically equivalent to observed under a
two one-sided test (TOST). Bias climbs softwood to mixedwood to hardwood in
every model, the composition-driven hardwood frontier they all share.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig2_accuracy_by_forest_type.R. This Python/matplotlib generator is the renderer
that actually produced the shipped PNG because R was not available in the build
sandbox (no root for apt, network behind a deny-all allowlist blocked CRAN).

Bias and TOST flags are read verbatim from the clean scorecard and are NOT
recomputed. Source of truth:
  results/seven_islands/scorecard_clean_all.csv  (cut == fortype, metric == TOTVOL)

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ----------------------------------------------------------------------------
# Paths (sandbox mount; the companion .R uses the real repo path)
# ----------------------------------------------------------------------------
REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "results", "seven_islands", "scorecard_clean_all.csv")
OUT  = os.path.join(REPO, "figures", "fig2_accuracy_by_forest_type.png")

# ----------------------------------------------------------------------------
# Order, labels, palette
# ----------------------------------------------------------------------------
TYPES  = ["Softwood", "Mixedwood", "Hardwood"]
MODELS = ["v125", "v1270", "v1271", "v129x", "osm"]
MLABEL = {"v125": "FVS v12.5.0", "v1270": "FVS v12.7.0", "v1271": "FVS v12.7.1",
          "v129x": "FVS v12.9.x", "osm": "OSM v2.26.1"}

# Version progression reads as an ordinal grey-to-green ramp (lightness carries
# the order, which is colorblind-safe); OSM is the contrasting external model.
MCOLOR = {"v125": "#B8B8B8", "v1270": "#A6D3A0", "v1271": "#6FB07F",
          "v129x": "#2C7A3F", "osm": "#B4443B"}

# ----------------------------------------------------------------------------
# Load (read verbatim; do NOT recompute)
# ----------------------------------------------------------------------------
df = pd.read_csv(DATA)
ft = df[(df["cut"] == "fortype") & (df["metric"] == "TOTVOL")].copy()

def val(t, m):
    r = ft[(ft["subset"] == t) & (ft["model"] == m)]
    return float(r["bias_pct"].values[0])

def tost(t, m):
    r = ft[(ft["subset"] == t) & (ft["model"] == m)]
    return bool(r["tost_lvl_equiv"].values[0])

# ----------------------------------------------------------------------------
# Figure
# ----------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11.0, 5.6), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

x = np.arange(len(TYPES))
nmod = len(MODELS)
w = 0.86 / nmod

# Equivalence region and zero line beneath the bars
ax.axhspan(-10, 10, color="#6FB07F", alpha=0.12, zorder=0)
ax.axhline(0, color="#333333", linewidth=0.9, zorder=2)

for k, m in enumerate(MODELS):
    offset = (k - (nmod - 1) / 2) * w
    vals = [val(t, m) for t in TYPES]
    eqs  = [tost(t, m) for t in TYPES]
    ax.bar(x + offset, vals, width=w * 0.92, color=MCOLOR[m],
           edgecolor="#333333", linewidth=0.5, label=MLABEL[m], zorder=3)
    for xi, (v, eq) in enumerate(zip(vals, eqs)):
        if eq:
            yy = v + 1.4 if v >= 0 else v - 3.0
            ax.text(x[xi] + offset, yy, "✓", ha="center", va="bottom",
                    color="#1F5C2E", fontsize=12, fontweight="bold", zorder=4)

# Axes framing
ax.set_xticks(x)
ax.set_xticklabels(TYPES, fontsize=12.5)
ax.set_ylabel("Total volume level bias (%)", fontsize=11.5)
ax.set_ylim(-16, 50)
ax.yaxis.grid(True, color="#E7E7E7", linewidth=0.7, zorder=0)
ax.set_axisbelow(True)
ax.tick_params(axis="both", length=0, labelsize=10.5)
for spine in ("top", "right"):
    ax.spines[spine].set_visible(False)
ax.spines["left"].set_color("#888888")
ax.spines["bottom"].set_color("#888888")

# Title and legend
ax.set_title("Bias is composition-driven: total volume by forest type",
             fontsize=13.5, fontweight="bold", loc="left", pad=26)
ax.text(0.0, 1.045,
        "Shaded band is the equivalence region (±10%); "
        "a check mark is statistically equivalent to observed (TOST).",
        transform=ax.transAxes, fontsize=9.8, color="#444444")
ax.legend(loc="upper left", ncol=5, frameon=False, fontsize=9.6,
          handlelength=1.1, columnspacing=1.3, handletextpad=0.5,
          bbox_to_anchor=(0.0, 1.0))

fig.subplots_adjust(left=0.075, right=0.985, top=0.83, bottom=0.09)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo the plotted values and TOST flags
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}\n")
print(f"{'fortype':<11}{'model':<8}{'bias_pct':>10}{'tost_equiv':>12}")
for t in TYPES:
    for m in MODELS:
        print(f"{t:<11}{m:<8}{val(t, m):>+10.4f}{str(tost(t, m)):>12}")
