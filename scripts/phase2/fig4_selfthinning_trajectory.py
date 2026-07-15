#!/usr/bin/env python3
"""
Figure 4. Self-thinning is a timing difference, not a permanent divergence.

Two honest panels on two distinct, clearly labelled bases:

  Panel A. Matched Seven Islands stands, first 60 years, identical start. The
  nine matched stands run under FVS-ACD and OSM from the same year-0 condition
  (FVS-ACD 31.4, OSM 31.9 m2 ha-1). FVS-ACD peaks near 33 m2 ha-1 by age 10 to
  20 and self-thins to 27 by age 60; OSM is still accumulating at age 60 (about
  42 m2 ha-1). The age-60 gap is a 35 percent divergence in self-thinning
  TIMING, read on the same nine stands.
  Source: results/seven_islands/fvsacd_vs_osm_matched.csv

  Panel B. OSM over the full 160-year horizon, real-stand productivity terciles
  (low, mid, high site). OSM does plateau and self-thin: the mid-site line
  peaks near 36 m2 ha-1 and levels to about 35, so the age-60 snapshot in panel
  A captures earlier FVS-ACD self-thinning, not a claim that OSM never plateaus.
  Source: figures/_data/osm_bakuzis_traj_bysite.csv (from Cardinal
          silc_cfi/osm_150yr_bakuzis/osm_bakuzis_traj_bysite.csv)

The two panels are on different bases (matched Seven Islands stands vs OSM real-
stand terciles), so no single mixed-basis line is drawn; each basis is stated in
its panel and in the caption. Corrected finding: OSM DOES plateau and self-thin
over the full horizon. There is no "OSM does not plateau" claim anywhere here.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig4_selfthinning_trajectory.R. This matplotlib generator is the renderer that
produced the shipped PNG because R was not available in the build sandbox.

Trajectories are read verbatim from the frozen projections and are NOT recomputed.
No accuracy or benchmark numbers are altered here.

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch

# ----------------------------------------------------------------------------
# Paths (resolve sandbox mount or real repo, whichever exists)
# ----------------------------------------------------------------------------
CANDIDATES = [
    "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd",
    "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd",
]
REPO = next((p for p in CANDIDATES if os.path.isdir(p)), CANDIDATES[-1])
MATCHED = os.path.join(REPO, "results", "seven_islands", "fvsacd_vs_osm_matched.csv")
OSM_TRAJ = os.path.join(REPO, "figures", "_data", "osm_bakuzis_traj_bysite.csv")
OUT = os.path.join(REPO, "figures", "fig4_selfthinning_trajectory.png")

# ----------------------------------------------------------------------------
# Palette: Weiskittel paired accent (teal / salmon)
# ----------------------------------------------------------------------------
COL_FA = "#1B9E9E"   # teal  -> FVS-ACD
COL_OSM = "#E15554"  # salmon -> OSM
GREY = "#888888"
GRID = "#E7E7E7"
BA_UNIT = r"$\mathregular{m^2\ ha^{-1}}$"

# ----------------------------------------------------------------------------
# Load frozen trajectories (verbatim; do NOT recompute)
# ----------------------------------------------------------------------------
m = pd.read_csv(MATCHED).sort_values("Age")
o = pd.read_csv(OSM_TRAJ)
# Convert to numpy so plotting is robust across matplotlib/pandas versions.
mAge, mFA, mOSM = (m["Age"].to_numpy(float), m["BA_fa"].to_numpy(float),
                   m["BA_osm"].to_numpy(float))

# OSM tercile styling: mid emphasized (the mid-site analog in the prose)
TERC = {
    "MID":  dict(color=COL_OSM, lw=2.8, ls="-",  alpha=1.0, z=5, lab="OSM mid site"),
    "LOW":  dict(color=COL_OSM, lw=1.6, ls=(0, (1, 1.4)), alpha=0.55, z=3, lab="OSM low site"),
    "HIGH": dict(color=COL_OSM, lw=1.6, ls=(0, (5, 2)),  alpha=0.55, z=3, lab="OSM high site"),
}

# ----------------------------------------------------------------------------
# Figure: two panels
# ----------------------------------------------------------------------------
fig, (axA, axB) = plt.subplots(1, 2, figsize=(13.0, 5.6), dpi=300)
fig.patch.set_facecolor("white")

# ---- Panel A: matched stands, first 60 years -------------------------------
axA.set_facecolor("white")
axA.plot(mAge, mFA, color=COL_FA, lw=2.8, marker="o", ms=6,
         solid_capstyle="round", label="FVS-ACD", zorder=5)
axA.plot(mAge, mOSM, color=COL_OSM, lw=2.8, marker="s", ms=6,
         solid_capstyle="round", label="OSM", zorder=5)
# shade the age-60 timing gap between the two matched lines
axA.fill_between(mAge, mFA, mOSM, color=COL_OSM, alpha=0.08, zorder=1)

# annotate the timing story (no permanence claim)
axA.annotate("FVS-ACD self-thins earlier\n(peaks near 33, thins to 27 by age 60)",
             xy=(60, 27.4), xytext=(21, 20.0), fontsize=9.3, color=COL_FA,
             fontweight="bold", va="center", ha="left",
             arrowprops=dict(arrowstyle="-", color=COL_FA, lw=1.1))
axA.annotate("OSM still accumulating\nat age 60 (about 42)",
             xy=(60, 42.4), xytext=(15, 45.5), fontsize=9.3, color=COL_OSM,
             fontweight="bold", va="center", ha="left",
             arrowprops=dict(arrowstyle="-", color=COL_OSM, lw=1.1))
axA.text(2, 30.5, "identical start\n(31.4 vs 31.9)", fontsize=8.4,
         color="#555555", va="center", ha="left")

axA.set_title("Matched Seven Islands stands, first 60 years",
              fontsize=12.5, fontweight="bold", pad=8)
axA.set_xlabel("Stand age (yr)", fontsize=11.5)
axA.set_ylabel(f"Basal area ({BA_UNIT})", fontsize=11.5)
axA.set_xlim(-2, 66)
axA.set_ylim(0, 50)
axA.legend(loc="lower left", frameon=False, fontsize=10.5, handlelength=1.8,
           bbox_to_anchor=(0.0, 0.02))
axA.text(0.5, -0.185, "Same nine stands under each model from an identical\n"
         "year-0 start. The age-60 gap is a 35% timing difference.",
         transform=axA.transAxes, ha="center", va="top", fontsize=8.4,
         color="#666666", linespacing=1.4)

# ---- Panel B: OSM over the full 160-year horizon ---------------------------
axB.set_facecolor("white")
# shade the first-60-yr window to link to panel A
axB.axvspan(0, 60, color="#000000", alpha=0.035, zorder=0)
axB.text(30, 3.0, "window shown at left", fontsize=8.2, color="#888888",
         ha="center", va="center")
for terc, st in TERC.items():
    s = o[o["site"] == terc].sort_values("age")
    axB.plot(s["age"].to_numpy(float), s["BAPH"].to_numpy(float),
             color=st["color"], lw=st["lw"], linestyle=st["ls"], alpha=st["alpha"],
             solid_capstyle="round", label=st["lab"], zorder=st["z"])
# plateau reference at the mid-site leveling value
mid = o[o["site"] == "MID"].sort_values("age")
mid_plateau = float(mid["BAPH"].tail(20).mean())
axB.axhline(mid_plateau, color=GREY, lw=0.9, ls=(0, (2, 3)), zorder=2)
axB.annotate(f"OSM plateaus over the full horizon\n(mid site levels near "
             f"{mid_plateau:.0f} m² ha⁻¹)",
             xy=(150, mid_plateau), xytext=(74, 20.5), fontsize=9.3,
             color=COL_OSM, fontweight="bold", va="center", ha="left",
             arrowprops=dict(arrowstyle="-", color=COL_OSM, lw=1.1))

axB.set_title("OSM over the full 160-year horizon",
              fontsize=12.5, fontweight="bold", pad=8)
axB.set_xlabel("Stand age (yr)", fontsize=11.5)
axB.set_ylabel(f"Basal area ({BA_UNIT})", fontsize=11.5)
axB.set_xlim(-2, 164)
axB.set_ylim(0, 50)
axB.legend(loc="lower right", frameon=False, fontsize=10.0, handlelength=2.0)
axB.text(0.5, -0.185, "OSM real-stand productivity terciles (73 benchmark stands).\n"
         "All three level off; the mid site is the panel A analog.",
         transform=axB.transAxes, ha="center", va="top", fontsize=8.4,
         color="#666666", linespacing=1.4)

# ---- shared chrome ---------------------------------------------------------
for ax in (axA, axB):
    ax.grid(True, color=GRID, linewidth=0.7, zorder=0)
    ax.set_axisbelow(True)
    ax.tick_params(axis="both", labelsize=10.5, length=0)
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    ax.spines["left"].set_color(GREY)
    ax.spines["bottom"].set_color(GREY)

fig.suptitle("Self-thinning is a timing difference, not a permanent divergence: "
             "FVS-ACD self-thins earlier, OSM plateaus later",
             fontsize=13.5, fontweight="bold", y=0.995)

fig.subplots_adjust(left=0.065, right=0.985, top=0.885, bottom=0.22, wspace=0.19)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification echo (frozen values, nothing recomputed)
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}\n")
print("Panel A (matched Seven Islands stands, first 60 yr):")
print(f"  year 0     FVS-ACD {m.BA_fa.iloc[0]:.1f}  OSM {m.BA_osm.iloc[0]:.1f}")
print(f"  FVS-ACD peak {m.BA_fa.max():.1f}  age-60 {m.BA_fa.iloc[-1]:.1f}")
print(f"  OSM     age-60 {m.BA_osm.iloc[-1]:.1f}  diff "
      f"{m.BA_diff_pct.iloc[-1]:.1f}%")
print("\nPanel B (OSM full 160-yr horizon, terciles):")
for terc in ("LOW", "MID", "HIGH"):
    s = o[o["site"] == terc].sort_values("age")
    print(f"  {terc:>4}: start {s.BAPH.iloc[0]:5.1f}  peak {s.BAPH.max():5.1f} "
          f"@age{int(s.loc[s.BAPH.idxmax(),'age']):>3}  end {s.BAPH.iloc[-1]:5.1f} "
          f"@age{int(s.age.iloc[-1])}")
print(f"  mid-site plateau (last-20-yr mean): {mid_plateau:.1f} m2 ha-1")
