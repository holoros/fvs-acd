#!/usr/bin/env python3
"""
Figure 3. Bakuzis law-like relations, pass and flag matrix by model.

The five law-like relations (Eichhorn, Reineke self-thinning, site ordering,
yield-density plateau, Sukachev) tested against the four version entrants that
carry the biological-realism story (v12.5.0, v12.7.0, v12.7.1, v12.9.x). Green
is a pass, brick red is a flag; bold PASS / FLAG labels give a redundant,
colorblind-safe encoding on top of the fill.

R-first is the house standard; a matching ggplot2 script lives alongside at
fig3_bakuzis_relations.R. This Python/matplotlib generator is the renderer that
actually produced the shipped PNG because R was not available in the build
sandbox (no root for apt, network behind a deny-all allowlist blocked CRAN).

Pass/flag pattern is read verbatim from the frozen Bakuzis assessment and is
NOT recomputed. Source of truth:
  figures/_data/bakuzis_relations.csv

Author: Aaron Weiskittel workspace (CRSF-Cowork)
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch, Rectangle

# ----------------------------------------------------------------------------
# Paths (sandbox mount; the companion .R uses the real repo path)
# ----------------------------------------------------------------------------
REPO = "/sessions/brave-jolly-tesla/mnt/CRSF-Cowork/repos/fvs-acd"
DATA = os.path.join(REPO, "figures", "_data", "bakuzis_relations.csv")
OUT  = os.path.join(REPO, "figures", "fig3_bakuzis_relations.png")

# ----------------------------------------------------------------------------
# Layout: rows are the version entrants (top to bottom), columns the relations
# ----------------------------------------------------------------------------
MODEL_ORDER = ["v125", "v1270", "v1271", "v129x"]          # top to bottom
MODEL_LABEL = {"v125": "v12.5.0", "v1270": "v12.7.0",
               "v1271": "v12.7.1", "v129x": "v12.9.x"}

# CSV column  ->  display label for each relation (x axis, left to right)
RELATIONS = [
    ("Eichhorn",              "Eichhorn"),
    ("Reineke",               "Reineke\nself-thinning"),
    ("SiteOrdering",          "Site\nordering"),
    ("YieldDensity_plateau",  "Yield-density\nplateau"),
    ("Sukachev",              "Sukachev"),
]

# Suite-consistent, muted flag palette (matches fig1); text labels give the
# redundant encoding that makes the green/red safe for colorblind readers.
FILL = {"PASS": "#4C8C5A", "FLAG": "#C0504D"}
TXT  = "#FFFFFF"

# ----------------------------------------------------------------------------
# Load pass/flag matrix (read verbatim; do NOT recompute)
# ----------------------------------------------------------------------------
df = pd.read_csv(DATA)
df = df.set_index("model")

ncol, nrow = len(RELATIONS), len(MODEL_ORDER)

# ----------------------------------------------------------------------------
# Figure
# ----------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9.2, 6.0), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

check = []  # verification rows: (model, relation, status)
for yi, mod in enumerate(MODEL_ORDER):
    y = nrow - 1 - yi                       # invert so v12.5.0 sits at top
    for xi, (col, _lab) in enumerate(RELATIONS):
        status = str(df.loc[mod, col]).strip().upper()
        ax.add_patch(Rectangle((xi, y), 1, 1, facecolor=FILL[status],
                               edgecolor="white", linewidth=2.4))
        ax.text(xi + 0.5, y + 0.5, status, ha="center", va="center",
                fontsize=12.5, fontweight="bold", color=TXT)
        check.append((MODEL_LABEL[mod], col, status))

# Axes framing
ax.set_xlim(0, ncol)
ax.set_ylim(0, nrow)
ax.set_xticks([i + 0.5 for i in range(ncol)])
ax.set_xticklabels([lab for _c, lab in RELATIONS], fontsize=11.5)
ax.set_yticks([i + 0.5 for i in range(nrow)])
ax.set_yticklabels([MODEL_LABEL[m] for m in reversed(MODEL_ORDER)], fontsize=12)
ax.xaxis.set_ticks_position("bottom")
ax.tick_params(axis="both", length=0)
for spine in ax.spines.values():
    spine.set_visible(False)
ax.set_aspect("equal")

# Title and caption
ax.set_title("Biological realism: Bakuzis law-like relations",
             fontsize=14, fontweight="bold", loc="center", pad=16)
fig.text(0.5, 0.045,
         "Green passes, red flags. Reineke self-thinning slope and the "
         "yield-density plateau separate the models.",
         ha="center", fontsize=10, color="#555555")

# Legend
handles = [Patch(facecolor=FILL["PASS"], edgecolor="white", label="PASS"),
           Patch(facecolor=FILL["FLAG"], edgecolor="white", label="FLAG")]
ax.legend(handles=handles, loc="upper left", bbox_to_anchor=(0, -0.10),
          ncol=2, frameon=False, fontsize=10.5, handlelength=1.3,
          columnspacing=1.6, handletextpad=0.6)

fig.subplots_adjust(left=0.13, right=0.98, top=0.90, bottom=0.19)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo the plotted pass/flag matrix
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}\n")
print(f"{'model':<9}{'relation':<22}{'status':>7}")
for mod, rel, st in check:
    print(f"{mod:<9}{rel:<22}{st:>7}")
