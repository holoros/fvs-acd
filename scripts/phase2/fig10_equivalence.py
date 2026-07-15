#!/usr/bin/env python3
"""
Figure 10. Observed-versus-predicted equivalence plots for the FVS-ACD frozen
benchmark (POOLED_indomain, n = 705).

Rows are metrics (TOTVOL, VALUE, BA), columns are the five models. Each panel
shows the per-stand observed value against the model prediction, the 1:1 line
(dashed), the OLS regression line fit as observed = a + b * predicted (solid),
and the shaded Robinson and Froese (2004) region of equivalence for the slope
(the wedge between y = 0.75 x and y = 1.25 x, i.e. slope 1 +/- 0.25). Points are
coloured by forest type so the hardwood scatter is visible. Each panel is
annotated with the OLS slope b and the joint equivalence verdict (both the
intercept region, +/- 25 percent of mean observed, and the slope region must
pass; flags are read from equivalence_frozen.csv).

R-first is the house standard; a matching ggplot2 script lives alongside at
fig10_equivalence.R. This Python/matplotlib generator produced the shipped PNG
because R is not available in the build sandbox. Values are read from the
authoritative frozen tables and per-stand obs/pred file; nothing is recomputed
except the plotted OLS line, which reproduces the frozen slope/intercept.

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
OBSPRED = os.path.join(REPO, "figures", "_data", "fig10_obspred_pooled.csv")
EQ = os.path.join(REPO, "data", "equivalence_frozen.csv")
OUT = os.path.join(REPO, "figures", "fig10_equivalence.png")
THUMB = os.path.join(REPO, "figures", "fig10_equivalence_thumb.png")

MODELS = ["v12.5.0", "v12.7.0", "v12.9.x", "v12.10.1", "OSM"]
METRICS = ["TOTVOL", "VALUE", "BA"]
METRIC_LAB = {
    "TOTVOL": "Total volume\n(m$^3$ ha$^{-1}$)",
    "VALUE":  "Stand value\n($ ha$^{-1}$)",
    "BA":     "Basal area\n(m$^2$ ha$^{-1}$)",
}
# muted, colourblind-aware forest-type palette
FT_COL = {"Softwood": "#2C7FB8", "Mixedwood": "#8C6BB1", "Hardwood": "#D95F0E"}
SLOPE_HW = 0.25   # slope region 1 +/- 0.25

op = pd.read_csv(OBSPRED)
eq = pd.read_csv(EQ)
eq = eq[eq["stratum"] == "POOLED_indomain"].set_index(["model", "metric"])

nrow, ncol = len(METRICS), len(MODELS)
fig, axes = plt.subplots(nrow, ncol, figsize=(15.5, 9.6), dpi=300)
fig.patch.set_facecolor("white")

for ri, met in enumerate(METRICS):
    sub_m = op[op["metric"] == met]
    # shared axis limits per metric row (obs and pred on the same scale)
    vmax = np.nanpercentile(
        np.concatenate([sub_m["obs"].values, sub_m["pred"].values]), 99.5)
    vmax *= 1.02
    for ci, mod in enumerate(MODELS):
        ax = axes[ri, ci]
        ax.set_facecolor("white")
        d = sub_m[sub_m["model"] == mod]
        # region of equivalence (slope wedge 0.75x to 1.25x)
        xg = np.array([0, vmax])
        ax.fill_between(xg, 0.75 * xg, 1.25 * xg, color="#BBBBBB",
                        alpha=0.30, linewidth=0, zorder=0)
        # 1:1 line
        ax.plot(xg, xg, color="#333333", linestyle=(0, (5, 4)),
                linewidth=1.2, zorder=2)
        # points by forest type (x = predicted, y = observed)
        for ft, col in FT_COL.items():
            dd = d[d["fortype"] == ft]
            ax.scatter(dd["pred"], dd["obs"], s=9, color=col, alpha=0.45,
                       edgecolors="none", zorder=3)
        # OLS observed ~ predicted line, from frozen coefficients
        try:
            row = eq.loc[(mod, met)]
            b, a = float(row["slope"]), float(row["intercept"])
            equiv = bool(row["overall_equiv"])
            se = bool(row["slope_equiv"])
            ie = bool(row["intercept_equiv"])
        except KeyError:
            b = a = np.nan; equiv = se = ie = False
        ax.plot(xg, a + b * xg, color="#B2182B", linewidth=1.9, zorder=4)
        ax.set_xlim(0, vmax); ax.set_ylim(0, vmax)
        ax.set_aspect("equal", adjustable="box")
        ax.tick_params(labelsize=7.5, length=2)
        # annotation
        verdict = "equivalent" if equiv else "not equivalent"
        vcol = "#1A7A3A" if equiv else "#B2182B"
        ax.text(0.045, 0.955, f"b = {b:.2f}", transform=ax.transAxes,
                ha="left", va="top", fontsize=8.6, fontweight="bold",
                color="#111111")
        ax.text(0.045, 0.865, verdict, transform=ax.transAxes,
                ha="left", va="top", fontsize=7.9, color=vcol,
                fontweight="bold")
        if not equiv:
            fail = []
            if not se:
                fail.append("slope")
            if not ie:
                fail.append("intercept")
            ax.text(0.045, 0.785, "(" + ", ".join(fail) + ")",
                    transform=ax.transAxes, ha="left", va="top",
                    fontsize=6.9, color="#777777")
        if ri == 0:
            ax.set_title(mod, fontsize=11, fontweight="bold", pad=6)
        if ci == 0:
            ax.set_ylabel("Observed\n" + METRIC_LAB[met], fontsize=8.6)
        for sp in ax.spines.values():
            sp.set_edgecolor("#999999")

fig.text(0.5, 0.055, "Predicted", ha="center", fontsize=11)

# legend
handles = [
    Line2D([0], [0], color="#B2182B", lw=1.9, label="OLS fit (observed = a + b x predicted)"),
    Line2D([0], [0], color="#333333", lw=1.2, linestyle=(0, (5, 4)), label="1:1 line"),
    Patch(facecolor="#BBBBBB", alpha=0.30, edgecolor="none",
          label="Region of equivalence (slope 1 $\\pm$ 0.25)"),
    Line2D([0], [0], marker="o", color="none", markerfacecolor=FT_COL["Softwood"],
           markersize=7, label="Softwood"),
    Line2D([0], [0], marker="o", color="none", markerfacecolor=FT_COL["Mixedwood"],
           markersize=7, label="Mixedwood"),
    Line2D([0], [0], marker="o", color="none", markerfacecolor=FT_COL["Hardwood"],
           markersize=7, label="Hardwood"),
]
fig.legend(handles=handles, loc="lower center", ncol=6, frameon=False,
           fontsize=8.7, bbox_to_anchor=(0.5, 0.0), columnspacing=1.4,
           handletextpad=0.5)

title = ("Figure 10. Observed versus predicted with the Robinson and Froese region "
         "of equivalence, FVS-ACD frozen benchmark (POOLED in-domain, n = 705). "
         "The joint\nverdict requires both the slope (1 $\\pm$ 0.25) and the intercept "
         "(within $\\pm$25% of mean observed) confidence intervals to fall inside "
         "their equivalence regions.")
fig.suptitle(title, fontsize=11, fontweight="bold", x=0.012, ha="left", y=0.995)

fig.subplots_adjust(left=0.075, right=0.995, top=0.915, bottom=0.115,
                    wspace=0.16, hspace=0.16)
fig.savefig(OUT, dpi=300, facecolor="white")

# thumbnail for in-session review
fig.savefig(THUMB, dpi=52, facecolor="white")
plt.close(fig)

print(f"Wrote: {OUT}")
print(f"Wrote: {THUMB}")
print("\nPOOLED equivalence (slope / intercept / flags):")
for met in METRICS:
    for mod in MODELS:
        r = eq.loc[(mod, met)]
        print(f"  {met:<7}{mod:<10} b={r['slope']:.3f}  a={r['intercept']:.2f}  "
              f"r2={r['r2']:.3f}  slope_eq={bool(r['slope_equiv'])}  "
              f"int_eq={bool(r['intercept_equiv'])}  overall={bool(r['overall_equiv'])}")
