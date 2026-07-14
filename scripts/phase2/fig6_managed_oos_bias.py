#!/usr/bin/env python3
"""
Figure 6. Managed-cell out-of-sample bias by management class.

Mean absolute level bias (percent), averaged across the nine NSVB metrics,
under leave-one-installation-out (LOIO) cross-validation of the management
modifier, for v12.9.x (gate off), v12.10.1 (gate on), and OSM, split by
management class (Planted, PCT, Managed = Planted + PCT pooled).

R-first is the house standard; a matching ggplot2 script lives alongside at
fig6_managed_oos_bias.R. This Python/matplotlib generator is the renderer that
actually produced the shipped PNG because R was not available in the build
sandbox (no root for apt, network behind a deny-all allowlist blocked CRAN).

Values are read straight from the FROZEN leave-one-installation-out
cross-validation on Cardinal and are NOT recomputed. Source of truth:
  ~/magplot/verify/mgmt_cv_frozen.R  ->  mgmt_cv_frozen.out
  ("== FROZEN LOIO (leave-one-installation-out) additive CV ==",
   the absMAE oos / v129x / osm columns)
mirrored into figures/_data/fig6_mgmt_oos_mab_frozen.csv for provenance.

The OSM bars are independent of the FVS-ACD freeze (OSM is an external model),
so they are unchanged from the pre-freeze figure; only the v12.9.x and v12.10.1
bars move with the frozen harness.

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
DATA = os.path.join(REPO, "figures", "_data", "fig6_mgmt_oos_mab_frozen.csv")
OUT  = os.path.join(REPO, "figures", "fig6_managed_oos_bias.png")

# ----------------------------------------------------------------------------
# Frozen LOIO values (read as-is; do NOT recompute)
# ----------------------------------------------------------------------------
CLASSES = ["Planted", "PCT", "Managed"]
MODELS  = ["v12.9.x", "v12.10.1", "OSM"]

# Bar palette matched to the pre-freeze fig6 (grey / green / red)
BAR_FILL = {"v12.9.x": "#888888", "v12.10.1": "#2C7A3F", "OSM": "#B4443B"}

# Sample counts for the class axis labels (from the frozen harness)
CLASS_LAB = {"Planted": "Planted\n(n=51)",
             "PCT":     "PCT\n(n=95)",
             "Managed": "Managed\n(n=146)"}

df = pd.read_csv(DATA)
d = df.pivot(index="class", columns="model", values="mab_oos_loio").reindex(CLASSES)

# ----------------------------------------------------------------------------
# Figure
# ----------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 5.2), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

x = np.arange(len(CLASSES))
nmod = len(MODELS)
w = 0.74 / nmod

for j, m in enumerate(MODELS):
    offset = (j - (nmod - 1) / 2) * w
    vals = d[m].values
    bars = ax.bar(x + offset, vals, width=w * 0.94, color=BAR_FILL[m],
                  edgecolor="white", linewidth=0.6, label=m, zorder=3)
    for xi, v in zip(x + offset, vals):
        ax.text(xi, v + 0.25, f"{v:.1f}", ha="center", va="bottom",
                fontsize=8.4, color="#222222", zorder=4)

# Axes framing
ax.set_xticks(x)
ax.set_xticklabels([CLASS_LAB[c] for c in CLASSES], fontsize=11)
ax.set_ylabel("Mean absolute bias (%)", fontsize=11)
ax.set_ylim(0, float(np.nanmax(d.values)) * 1.12)
ax.yaxis.grid(True, color="#DDDDDD", linewidth=0.8, zorder=0)
ax.set_axisbelow(True)
ax.tick_params(axis="both", length=0)
for spine in ("top", "right"):
    ax.spines[spine].set_visible(False)
ax.spines["left"].set_color("#888888")
ax.spines["bottom"].set_color("#888888")

# Title and legend
ax.set_title("Management modifiers close the managed cell",
             fontsize=13, fontweight="bold", loc="left", pad=24)
ax.text(0.0, 1.045,
        "Out-of-sample mean absolute bias across nine NSVB metrics, "
        "leave one installation out",
        transform=ax.transAxes, fontsize=9.5, color="#333333")
ax.legend(loc="upper right", frameon=False, fontsize=10, ncol=3,
          handlelength=1.1, columnspacing=1.3)

fig.subplots_adjust(left=0.085, right=0.985, top=0.85, bottom=0.11)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo the plotted values to stdout
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}\n")
print(f"{'class':<9}{'model':<11}{'mab_oos_loio':>13}")
for c in CLASSES:
    for m in MODELS:
        print(f"{c:<9}{m:<11}{d.loc[c, m]:>13.2f}")
