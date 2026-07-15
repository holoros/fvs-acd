#!/usr/bin/env python3
"""
Figure 4. Long-horizon self-thinning trajectories on matched stands.

Basal area (m2 ha-1) over a 160 year projection from an identical start, for
three matched sites (12, 16, 20) and the four version entrants. Early FVS-ACD
(v12.5.0) never self-thins and runs to about 65 m2 ha-1; v12.7.1 and v12.9.x
converge to a realistic plateau near 36 m2 ha-1 (their lines overlap by design,
which is the point). v12.7.0 sits between.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig4_selfthinning_trajectory.R. This Python/matplotlib generator is the renderer
that actually produced the shipped PNG because R was not available in the build
sandbox (no root for apt, network behind a deny-all allowlist blocked CRAN).

Trajectories are read verbatim from the frozen projection and are NOT recomputed.
Source of truth:
  figures/_data/bakuzis_traj_allmodels.csv   (columns model, site, age, BAPH, ...)

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ----------------------------------------------------------------------------
# Paths (sandbox mount; the companion .R uses the real repo path)
# ----------------------------------------------------------------------------
REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "figures", "_data", "bakuzis_traj_allmodels.csv")
OUT  = os.path.join(REPO, "figures", "fig4_selfthinning_trajectory.png")

# ----------------------------------------------------------------------------
# Model order, labels, colorblind-safe Okabe-Ito palette
# ----------------------------------------------------------------------------
MODEL_ORDER = ["v125", "v1270", "v1271", "v129x"]
MODEL_LABEL = {"v125": "v12.5.0", "v1270": "v12.7.0",
               "v1271": "v12.7.1", "v129x": "v12.9.x"}
# Okabe-Ito (deutan/protan safe). v12.7.1 and v12.9.x land on the same plateau;
# distinct hues keep them separable where they overlap.
MODEL_COLOR = {"v125": "#E69F00",   # orange
               "v1270": "#0072B2",  # blue
               "v1271": "#009E73",  # bluish green
               "v129x": "#000000"}  # black
MODEL_LW   = {"v125": 2.2, "v1270": 2.2, "v1271": 2.6, "v129x": 1.8}
MODEL_DASH = {"v125": None, "v1270": None, "v1271": None, "v129x": (0, (5, 2))}

SITES = [12, 16, 20]
BA_UNIT = r"$\mathregular{m^2\ ha^{-1}}$"

# ----------------------------------------------------------------------------
# Load trajectories (read verbatim; do NOT recompute)
# ----------------------------------------------------------------------------
df = pd.read_csv(DATA)
df = df[df["model"].isin(MODEL_ORDER) & df["site"].isin(SITES)].copy()

ymax = float(df["BAPH"].max())

# ----------------------------------------------------------------------------
# Figure: one facet per site, shared y axis
# ----------------------------------------------------------------------------
fig, axes = plt.subplots(1, len(SITES), figsize=(13.0, 5.0), dpi=300,
                         sharey=True)
fig.patch.set_facecolor("white")

for ax, site in zip(axes, SITES):
    ax.set_facecolor("white")
    sub = df[df["site"] == site]
    for mod in MODEL_ORDER:
        s = sub[sub["model"] == mod].sort_values("age")
        ax.plot(s["age"], s["BAPH"], color=MODEL_COLOR[mod],
                linewidth=MODEL_LW[mod], linestyle=(MODEL_DASH[mod] or "-"),
                solid_capstyle="round", label=MODEL_LABEL[mod], zorder=3)
    ax.set_title(f"Site {site}", fontsize=12.5, fontweight="bold", pad=8)
    ax.set_xlabel("Stand age (yr)", fontsize=11.5)
    ax.set_xlim(0, 162)
    ax.set_ylim(0, ymax * 1.03)
    ax.grid(True, color="#E7E7E7", linewidth=0.7, zorder=0)
    ax.set_axisbelow(True)
    ax.tick_params(axis="both", labelsize=10.5, length=0)
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    ax.spines["left"].set_color("#888888")
    ax.spines["bottom"].set_color("#888888")

axes[0].set_ylabel(f"Basal area ({BA_UNIT})", fontsize=11.5)

# Single shared legend in the first panel
axes[0].legend(loc="upper left", frameon=False, fontsize=10.5,
               handlelength=1.6, borderaxespad=0.4)

fig.suptitle("Long horizon: early FVS-ACD runs away, v12.7.1 onward self-thins "
             "to a realistic plateau",
             fontsize=13.5, fontweight="bold", y=0.99)
fig.text(0.5, 0.015,
         "Basal area over a 160 yr projection. v12.5.0 never self-thins "
         "(runs to about 65 m² ha⁻¹); "
         "v12.7.1 and v12.9.x plateau near 36 m² ha⁻¹.",
         ha="center", fontsize=10, color="#555555")

fig.subplots_adjust(left=0.065, right=0.99, top=0.86, bottom=0.15, wspace=0.06)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo start and end basal area for each site x model
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}\n")
print(f"{'site':>4}{'model':>9}{'age_min':>9}{'BA_start':>10}"
      f"{'age_max':>9}{'BA_end':>9}{'n':>5}")
for site in SITES:
    for mod in MODEL_ORDER:
        s = df[(df.site == site) & (df.model == mod)].sort_values("age")
        r0, r1 = s.iloc[0], s.iloc[-1]
        print(f"{site:>4}{MODEL_LABEL[mod]:>9}{int(r0.age):>9}"
              f"{r0.BAPH:>10.3f}{int(r1.age):>9}{r1.BAPH:>9.3f}{len(s):>5}")
