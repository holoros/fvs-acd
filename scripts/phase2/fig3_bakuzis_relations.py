#!/usr/bin/env python3
"""
Figure 3. Bakuzis law-like relations, pass and flag matrix by model.

The five law-like relations (Eichhorn, Reineke self-thinning, site ordering,
yield-density plateau, Sukachev) tested against the four AcadianGY version
entrants that carry the biological-realism story (v12.5.0, v12.7.0, v12.7.1,
v12.9.x), plus OSM as an external comparison model. Green is a pass, brick red
is a flag, neutral grey is not scored; bold PASS / FLAG / N/S labels give a
redundant, colorblind-safe encoding on top of the fill.

OSM is now scored on ALL FIVE relations from its own long-horizon run: OSM was
projected 160 years (YEARS 160, YPC 1) over the 73 SILC/CFI stands, binned into
three site-productivity terciles by T50HT (OSM dominant height at reference age
50) as the analog of the seeded ESI 12/16/20 gradient. Relation tests reuse the
AcadianGY Bakuzis battery definitions verbatim. Over the full horizon OSM PASSES
Reineke self-thinning (log SDI slope -1.56, pooled -1.69), the yield-density
plateau (mid-site basal area peaks near 35.8 m2 ha-1 and levels/self-thins to
34.7 rather than accumulating without bound), and Sukachev (quadratic mean
diameter rises as density falls). OSM FLAGS Eichhorn (cross-site volume-at-height
coefficient of variation 26.3 percent, above the 15 percent bound) and site
ordering (trajectory crossings, 42 height and 105 volume inversions). The two
flags partly reflect the real-stand substitution: OSM stands carry heterogeneous
starting ages on a projection-year axis rather than an age-aligned seeded
gradient. The earlier short-horizon (age 60) matched-stand read that flagged
Reineke and the plateau is superseded by this 150-plus-year run.

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
MODEL_ORDER = ["v125", "v1270", "v1271", "v129x", "OSM"]    # top to bottom
MODEL_LABEL = {"v125": "v12.5.0", "v1270": "v12.7.0",
               "v1271": "v12.7.1", "v129x": "v12.9.x",
               "OSM": "OSM\n(external)"}

# CSV column  ->  display label for each relation (x axis, left to right)
RELATIONS = [
    ("Eichhorn",              "Eichhorn"),
    ("Reineke",               "Reineke\nself-thinning"),
    ("SiteOrdering",          "Site\nordering"),
    ("YieldDensity_plateau",  "Yield-density\nplateau"),
    ("Sukachev",              "Sukachev"),
]

# Suite-consistent, muted flag palette (matches fig1); text labels give the
# redundant encoding that makes the green/red/grey safe for colorblind readers.
FILL = {"PASS": "#4C8C5A", "FLAG": "#C0504D", "NOT SCORED": "#8C8C8C"}
# Cell text: PASS and FLAG print verbatim, NOT SCORED prints as compact N/S.
CELL_TXT = {"PASS": "PASS", "FLAG": "FLAG", "NOT SCORED": "N/S"}
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
fig, ax = plt.subplots(figsize=(9.4, 6.8), dpi=300)
fig.patch.set_facecolor("white")
ax.set_facecolor("white")

check = []  # verification rows: (model, relation, status)
for yi, mod in enumerate(MODEL_ORDER):
    y = nrow - 1 - yi                       # invert so v12.5.0 sits at top
    for xi, (col, _lab) in enumerate(RELATIONS):
        status = str(df.loc[mod, col]).strip().upper()
        ax.add_patch(Rectangle((xi, y), 1, 1, facecolor=FILL[status],
                               edgecolor="white", linewidth=2.4))
        ax.text(xi + 0.5, y + 0.5, CELL_TXT[status], ha="center", va="center",
                fontsize=12.5, fontweight="bold", color=TXT)
        check.append((MODEL_LABEL[mod].replace("\n", " "), col, status))

# Set OSM (external model) apart from the seeded AcadianGY entrants with a slim
# divider line above its row.
ax.plot([0, ncol], [1, 1], color="#333333", linewidth=1.1,
        linestyle=(0, (5, 3)), zorder=5, clip_on=False)

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
fig.text(0.5, 0.05,
         "Green passes, red flags. OSM (external) is scored on all five relations "
         "from its own 150-plus-year run over the SILC/CFI stands binned into three "
         "T50HT site terciles; it passes self-thinning, the yield-density plateau, "
         "and Sukachev, and flags Eichhorn and site ordering under the real-stand "
         "substitution (projection-year axis, heterogeneous starting ages).",
         ha="center", fontsize=9, color="#555555", wrap=True)

# Legend
handles = [Patch(facecolor=FILL["PASS"], edgecolor="white", label="PASS"),
           Patch(facecolor=FILL["FLAG"], edgecolor="white", label="FLAG")]
# Only advertise the not-scored key if a cell actually carries it.
if any(st == "NOT SCORED" for _m, _r, st in check):
    handles.append(Patch(facecolor=FILL["NOT SCORED"], edgecolor="white",
                         label="N/S (not scored)"))
ax.legend(handles=handles, loc="upper left", bbox_to_anchor=(0, -0.12),
          ncol=3, frameon=False, fontsize=10.5, handlelength=1.3,
          columnspacing=1.4, handletextpad=0.6)

fig.subplots_adjust(left=0.15, right=0.98, top=0.90, bottom=0.24)
fig.savefig(OUT, dpi=300, facecolor="white")
plt.close(fig)

# ----------------------------------------------------------------------------
# Verification: echo the plotted pass/flag matrix
# ----------------------------------------------------------------------------
print(f"Wrote: {OUT}\n")
print(f"{'model':<9}{'relation':<22}{'status':>7}")
for mod, rel, st in check:
    print(f"{mod:<9}{rel:<22}{st:>7}")
