#!/usr/bin/env python3
"""
Python fallback for fig9_species_composition_over_time.png.

Rebuilds the two-panel species-composition figure from the aggregate CSVs
produced by species_composition_over_time.R:
  - species_composition_perstand_frozen.csv  (per-stand softwood BA fraction)
  - species_composition_over_time_frozen.csv (per model x stratum summary)
R (ggplot2) is the primary path; this reproduces the same figure with
matplotlib if R is unavailable. Aggregates only. No em dashes.
"""
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.abspath(os.path.join(HERE, "..", "..", "data"))
FIGS = os.path.abspath(os.path.join(HERE, "..", "..", "figures"))
per = pd.read_csv(os.path.join(DATA, "species_composition_perstand_frozen.csv"))
summ = pd.read_csv(os.path.join(DATA, "species_composition_over_time_frozen.csv"))

models = ["v12.5.0", "v12.7.0", "v12.10.1", "OSM"]
ftpal = {"Softwood": "#1B9E9E", "Mixedwood": "#B08A3E", "Hardwood": "#E15554"}
mpal = {"v12.5.0": "#4C72B0", "v12.7.0": "#55A868", "v12.10.1": "#C44E52", "OSM": "#8172B3"}

fig = plt.figure(figsize=(11, 8.4))
gs = fig.add_gridspec(2, 4, height_ratios=[1.15, 1], hspace=0.42, wspace=0.18)

# ---- Panel A: predicted vs observed softwood fraction at t2, per model ----
for j, m in enumerate(models):
    ax = fig.add_subplot(gs[0, j])
    d = per[per.model == m]
    for ft, col in ftpal.items():
        s = d[d.fortype == ft]
        ax.scatter(s.swf_o, s.swf_p, s=7, alpha=0.55, color=col, edgecolors="none",
                   label=ft if j == 0 else None)
    ax.plot([0, 100], [0, 100], ls=(0, (2, 2)), color="grey", lw=0.9)
    row = summ[(summ.model == m) & (summ.stratum == "Pooled")].iloc[0]
    dirok = 100 * np.mean(np.sign(d.swf_o - d.swf_t1) == np.sign(d.swf_p - d.swf_t1))
    ax.text(4, 96, f"bias {row.bias_swf_pts:+.1f} pts\ndir OK {dirok:.0f}%",
            ha="left", va="top", fontsize=8.5, color="0.2")
    ax.set_title(m, fontweight="bold", fontsize=11)
    ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.set_aspect("equal")
    ax.set_xlabel("Observed softwood fraction at t2 (%)", fontsize=9)
    if j == 0:
        ax.set_ylabel("Predicted softwood fraction at t2 (%)", fontsize=9)
    ax.grid(True, color="0.92", lw=0.4)
    ax.set_axisbelow(True)
fig.legend(handles=[plt.Line2D([0], [0], marker="o", ls="", color=c, label=k)
                    for k, c in ftpal.items()],
           loc="upper center", bbox_to_anchor=(0.5, 0.52), ncol=3, frameon=False,
           title="Forest type")
fig.suptitle("Predicted versus observed softwood basal-area fraction at remeasurement",
             fontweight="bold", fontsize=13, x=0.5, y=0.98)

# ---- Panel B: observed vs predicted compositional shift by forest type ----
axB = fig.add_subplot(gs[1, :])
fts = ["Softwood", "Mixedwood", "Hardwood"]
x = np.arange(len(fts))
obs = [summ[(summ.stratum == f)].obs_shift_pts.iloc[0] for f in fts]
axB.axhline(0, color="0.55", lw=0.6)
axB.bar(x, obs, width=0.62, color="0.82", edgecolor="0.55", lw=0.4, zorder=1)
for k, m in enumerate(models):
    yy = [summ[(summ.model == m) & (summ.stratum == f)].pred_shift_pts.iloc[0] for f in fts]
    axB.scatter(x + (k - 1.5) * 0.14, yy, s=42, color=mpal[m], label=m, zorder=3)
axB.set_xticks(x); axB.set_xticklabels(fts)
axB.set_xlabel("Forest type"); axB.set_ylabel("Softwood fraction shift t1 to t2 (pts)")
axB.set_title("Observed versus predicted compositional shift (grey bar = observed mean)",
              fontweight="bold", fontsize=12, loc="left")
axB.legend(title="Model prediction", ncol=4, frameon=False, loc="upper left", fontsize=9)
axB.grid(True, axis="y", color="0.92", lw=0.4); axB.set_axisbelow(True)

out = os.path.join(FIGS, "fig9_species_composition_over_time.png")
fig.savefig(out, dpi=300, bbox_inches="tight", facecolor="white")
fig.savefig(out.replace(".png", "_thumb.png"), dpi=72, bbox_inches="tight", facecolor="white")
print("wrote", out)
