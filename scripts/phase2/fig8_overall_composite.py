#!/usr/bin/env python3
"""
Figure 8. Weighted overall composite score for the FVS-ACD v12.10.1 benchmark.

Ranked horizontal bars of the PRIMARY composite (volume + value weighted blend
of accuracy and per-stand efficiency across the nine metrics; total volume and
value carry the highest weight) per model on the pooled in-domain set. The
equal-weight composite is drawn as a reference marker on each bar, and the
by-forest-type primary composites are overlaid as markers. Scores are read
straight from composite_scores_frozen.csv and are NOT recomputed.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig8_overall_composite.R. This matplotlib generator produced the shipped PNG
because R is unavailable in the build sandbox (as with fig1).
"""
import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "data", "composite_scores_frozen.csv")
OUT  = os.path.join(REPO, "figures", "fig8_overall_composite.png")

df = pd.read_csv(DATA)
pooled = (df[df["stratum"] == "POOLED_indomain"]
          .sort_values("composite_primary", ascending=True).reset_index(drop=True))
models = pooled["model"].tolist()               # ascending, best on top after barh
n_pool = int(pooled["n"].iloc[0])

BAR_COLOR = "#3B6B8F"                            # muted steel blue
REF_COLOR = "#22384A"                            # equal-weight reference marker
FT_STYLE = {                                    # forest-type marker styling
    "Softwood":  ("#1B7837", "o", "Softwood"),
    "Mixedwood": ("#7B3294", "s", "Mixedwood"),
    "Hardwood":  ("#B35806", "^", "Hardwood"),
}

fig, ax = plt.subplots(figsize=(10, 6.2), dpi=300)
fig.patch.set_facecolor("white"); ax.set_facecolor("white")

ypos = np.arange(len(models))
vals = pooled["composite_primary"].values
eqv  = pooled["composite_equalweight"].values
ax.barh(ypos, vals, height=0.62, color=BAR_COLOR, edgecolor="white",
        zorder=2, label="Pooled in-domain (primary)")
for yi, v in zip(ypos, vals):
    ax.text(v - 1.2, yi, f"{v:.1f}", va="center", ha="right",
            fontsize=10.5, fontweight="bold", color="#FFFFFF", zorder=4)

# equal-weight composite as a reference tick on each bar
ax.scatter(eqv, ypos, s=150, marker="|", color=REF_COLOR, linewidth=2.2,
           zorder=5, label="Equal-weight reference")

# overlay by-forest-type primary composites as markers
for ft, (col, mk, lab) in FT_STYLE.items():
    sub = df[df["stratum"] == ft].set_index("model")
    xs = [sub.loc[m, "composite_primary"] for m in models]
    ax.scatter(xs, ypos, s=52, marker=mk, facecolor=col, edgecolor="white",
               linewidth=0.7, zorder=3, label=lab)

ax.set_yticks(ypos)
ax.set_yticklabels(models, fontsize=11)
ax.set_xlim(0, 100)
ax.set_xlabel("Overall composite score (0 to 100, higher is better)", fontsize=10.5)
ax.set_axisbelow(True)
ax.xaxis.grid(True, color="#DDDDDD", linewidth=0.7)
for sp in ("top", "right", "left"):
    ax.spines[sp].set_visible(False)
ax.tick_params(axis="y", length=0)

title = ("Figure 8. Volume and value weighted overall composite score by model: pooled\n"
         f"in-domain primary composite (bars, n = {n_pool}), equal-weight reference "
         "(ticks),\nand by-forest-type primary composites (markers)")
ax.set_title(title, fontsize=12, fontweight="bold", loc="left", pad=12)

handles = [
    plt.Rectangle((0, 0), 1, 1, color=BAR_COLOR, label="Pooled primary (bar)"),
    Line2D([0], [0], marker="|", color=REF_COLOR, markersize=11, linewidth=0,
           markeredgewidth=2.2, label="Equal-weight reference"),
    Line2D([0], [0], marker="o", color="none", markerfacecolor="#1B7837",
           markeredgecolor="white", markersize=8, label="Softwood"),
    Line2D([0], [0], marker="s", color="none", markerfacecolor="#7B3294",
           markeredgecolor="white", markersize=8, label="Mixedwood"),
    Line2D([0], [0], marker="^", color="none", markerfacecolor="#B35806",
           markeredgecolor="white", markersize=8, label="Hardwood"),
]
ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, -0.14),
          frameon=False, fontsize=9.6, ncol=5, columnspacing=1.6,
          handletextpad=0.5)

fig.subplots_adjust(left=0.11, right=0.985, top=0.83, bottom=0.17)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)
print(f"Wrote: {OUT}")
print(pooled[["model", "composite_primary", "composite_equalweight"]].to_string(index=False))
