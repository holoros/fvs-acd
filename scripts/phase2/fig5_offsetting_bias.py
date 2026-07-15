#!/usr/bin/env python3
"""
Figure 5. The offsetting bias signature, in domain.

Level bias (percent) for v12.10.1 on the Acadian-core operational domain
(n = 492): basal area under-predicts, top height over-predicts, and the two
cancel in total volume, leaving near-parity that hides the underlying signature
the v13.0 joint re-anchor targets.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig5_offsetting_bias.R. This Python/matplotlib generator is the renderer that
actually produced the shipped PNG because R was not available in the build
sandbox (no root for apt, network behind a deny-all allowlist blocked CRAN).

Values are read verbatim from the frozen operational-domain recompute and are
NOT recomputed. Source of truth:
  _context/v13_autosubmit/pulled/scorecard_domain_v12101.csv
  (subset POOLED_indomain; BA, TOPHT, TOTVOL bias_pct). This is the in-domain
  masked subset the deck and report cite; BA -9.20, TOPHT +4.16, TOTVOL -1.63.

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
DATA = os.path.join(REPO, "_context", "v13_autosubmit", "pulled",
                    "scorecard_domain_v12101.csv")
OUT  = os.path.join(REPO, "figures", "fig5_offsetting_bias.png")

# ----------------------------------------------------------------------------
# Metrics shown (read verbatim; do NOT recompute)
# ----------------------------------------------------------------------------
METRICS = [("BA", "Basal area"), ("TOPHT", "Top height"), ("TOTVOL", "Total volume")]
# Diverging semantic: warm for over-prediction, cool for under-prediction.
UNDER = "#3B6FA0"   # steel blue
OVER  = "#C0504D"   # brick red

df = pd.read_csv(DATA)
d = df[df["subset"] == "POOLED_indomain"].set_index("metric")
n_val = int(d["n"].iloc[0])

labels = [lab for _m, lab in METRICS]
vals   = [float(d.loc[m, "bias_pct"]) for m, _lab in METRICS]
cols   = [OVER if v >= 0 else UNDER for v in vals]

# ----------------------------------------------------------------------------
# Figure
# ----------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(7.6, 5.4), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

x = range(len(METRICS))
ax.bar(x, vals, width=0.62, color=cols, edgecolor="#333333",
       linewidth=0.6, zorder=3)
ax.axhline(0, color="#222222", linewidth=1.0, zorder=4)

for xi, v in zip(x, vals):
    va = "bottom" if v >= 0 else "top"
    dy = 0.28 if v >= 0 else -0.28
    ax.text(xi, v + dy, f"{v:+.2f}%", ha="center", va=va,
            fontsize=12, fontweight="bold", color="#1A1A1A", zorder=5)

# Axes framing
ax.set_xticks(list(x))
ax.set_xticklabels(labels, fontsize=12.5)
ax.set_ylabel("Level bias (%)", fontsize=11.5)
lo, hi = min(vals), max(vals)
ax.set_ylim(lo - 3.4, hi + 3.4)
ax.yaxis.grid(True, color="#E7E7E7", linewidth=0.7, zorder=0)
ax.set_axisbelow(True)
ax.tick_params(axis="both", length=0, labelsize=10.5)
for spine in ("top", "right"):
    ax.spines[spine].set_visible(False)
ax.spines["left"].set_color("#888888")
ax.spines["bottom"].set_color("#888888")

ax.set_title("The offsetting bias signature, in domain",
             fontsize=13.5, fontweight="bold", loc="left", pad=14)
fig.text(0.5, 0.055,
         f"v12.10.1 in the Acadian-core domain (n = {n_val}). Basal area "
         "under-predicts and top height over-predicts,",
         ha="center", fontsize=9.2, color="#555555")
fig.text(0.5, 0.018,
         "canceling in total volume. Target of the v13.0 joint re-anchor.",
         ha="center", fontsize=9.2, color="#555555")

fig.subplots_adjust(left=0.115, right=0.975, top=0.90, bottom=0.17)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo the plotted values
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}")
print(f"subset = POOLED_indomain, n = {n_val}\n")
print(f"{'metric':<9}{'label':<13}{'bias_pct':>12}")
for m, lab in METRICS:
    print(f"{m:<9}{lab:<13}{float(d.loc[m, 'bias_pct']):>+12.5f}")
