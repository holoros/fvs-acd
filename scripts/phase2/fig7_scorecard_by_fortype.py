#!/usr/bin/env python3
"""
Figure 7. Forest-type scorecard for the FVS-ACD v12.10.1 benchmark (frozen basis).

Faceted tile heatmap of level bias (percent) with bootstrap 95 percent CIs and
green/yellow/red flags, faceted by forest type (Softwood, Mixedwood, Hardwood),
five models on x, nine metrics on y. Scores are read straight from the frozen
scorecard_five_by_fortype_frozen.csv and are NOT recomputed.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig7_scorecard_by_fortype.R. This matplotlib generator produced the shipped PNG
because R is unavailable in the build sandbox (as with fig1).
"""
import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch, Rectangle

REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "data", "scorecard_five_by_fortype_frozen.csv")
OUT  = os.path.join(REPO, "figures", "fig7_scorecard_by_fortype.png")

MODELS   = ["v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM"]      # x
METRICS  = ["BA", "SDI", "QMD", "TOPHT", "TOTVOL",
            "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE"]                # y, BA at top
FORTYPES = ["Softwood", "Mixedwood", "Hardwood"]                    # facets

METRIC_LABEL = {
    "BA": "Basal area (BA)", "SDI": "Stand density index (SDI)",
    "QMD": "Quad. mean diameter (QMD)", "TOPHT": "Top height (TOPHT)",
    "TOTVOL": "Total volume (TOTVOL)", "MERCHVOL": "Merch volume (MERCHVOL)",
    "SAWVOL": "Sawlog volume (SAWVOL)", "BIOMASS": "Aboveground biomass (BIOMASS)",
    "VALUE": "Stand value (VALUE)",
}
FLAG_FILL = {"green": "#4C8C5A", "yellow": "#E0B33A", "red": "#C0504D"}

def _text_color(hex_fill):
    h = hex_fill.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    return "#111111" if (0.299*r + 0.587*g + 0.114*b) > 0.55 else "#FFFFFF"

df = pd.read_csv(DATA)
nrow, ncol = len(METRICS), len(MODELS)

fig, axes = plt.subplots(1, 3, figsize=(16.5, 7.4), dpi=300, sharey=True)
fig.patch.set_facecolor("white")

n_by_ft = {}
for pi, ft in enumerate(FORTYPES):
    ax = axes[pi]
    ax.set_facecolor("white")
    d = df[df["fortype"] == ft]
    n_by_ft[ft] = int(d["n"].iloc[0])
    for _, row in d.iterrows():
        if row["model"] not in MODELS or row["metric"] not in METRICS:
            continue
        xi = MODELS.index(row["model"])
        yi = METRICS.index(row["metric"])
        y = nrow - 1 - yi                          # BA at top
        fill = FLAG_FILL.get(row["flag"], "#BBBBBB")
        ax.add_patch(Rectangle((xi, y), 1, 1, facecolor=fill,
                               edgecolor="white", linewidth=1.5))
        tcol = _text_color(fill)
        ax.text(xi + 0.5, y + 0.62, f"{row['bias_pct']:+.1f}%", ha="center",
                va="center", fontsize=9.2, fontweight="bold", color=tcol)
        ax.text(xi + 0.5, y + 0.29,
                f"[{row['bias_lo95']:.0f}, {row['bias_hi95']:.0f}]", ha="center",
                va="center", fontsize=6.9, color=tcol)
    ax.set_xlim(0, ncol); ax.set_ylim(0, nrow)
    ax.set_xticks(np.arange(ncol) + 0.5)
    ax.set_xticklabels(MODELS, fontsize=9.6, rotation=0)
    ax.xaxis.set_ticks_position("top"); ax.xaxis.set_label_position("top")
    ax.tick_params(axis="both", length=0)
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.set_aspect("auto")
    ax.set_title(f"{ft}  (n = {n_by_ft[ft]})", fontsize=11.5,
                 fontweight="bold", pad=26)

axes[0].set_yticks(np.arange(nrow) + 0.5)
axes[0].set_yticklabels([METRIC_LABEL[m] for m in reversed(METRICS)], fontsize=9.4)

suptitle = ("Figure 7. Forest-type scorecard: level bias percent with bootstrap "
            "95% CIs and green/yellow/red flags, nine metrics by five models, "
            "faceted by forest type (frozen basis)")
fig.suptitle(suptitle, fontsize=12, fontweight="bold", x=0.012, ha="left", y=0.99)

legend_handles = [
    Patch(facecolor=FLAG_FILL["green"], edgecolor="white",
          label="green  |bias| < 5% and NSE > 0.6"),
    Patch(facecolor=FLAG_FILL["yellow"], edgecolor="white",
          label="yellow  intermediate"),
    Patch(facecolor=FLAG_FILL["red"], edgecolor="white",
          label="red  |bias| >= 10% or NSE < 0.4"),
]
fig.legend(handles=legend_handles, loc="lower center", ncol=3, frameon=False,
           fontsize=9.4, handlelength=1.2, columnspacing=1.8, handletextpad=0.5,
           bbox_to_anchor=(0.5, -0.005))

fig.subplots_adjust(left=0.135, right=0.995, top=0.86, bottom=0.075, wspace=0.06)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)
print(f"Wrote: {OUT}")
for ft in FORTYPES:
    print(f"  {ft}: n = {n_by_ft[ft]}")
