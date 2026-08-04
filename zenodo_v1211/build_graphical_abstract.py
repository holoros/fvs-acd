#!/usr/bin/env python3
"""Graphical abstract for the FVS-ACD v12.11 benchmark deposit.

Three panels, deliberately kept on separate populations rather than merged into
one trajectory: the legacy 705-stand in-domain set carries the generational
comparison through v12.10.1, the all-sites benchmark carries v12.11, and the
height-coverage census carries the integrity finding. Merging the first two
would imply a single continuous series that was never scored as one.

Uncertainty is shown where it exists and withheld where it does not. Panel A
carries the 95 percent intervals already in the frozen scorecard. Panel B
carries stand-level bootstrap intervals (allsites_bias_ci.csv); if that file is
absent the panel degrades to bars and says so. Panel C is a complete
enumeration of the staged tree lists, so it has no sampling uncertainty and
gets no error bars; drawing them there would invent a quantity.

Usage: build_graphical_abstract.py [--doi 10.5281/zenodo.XXXXXXX]
"""
import argparse
import csv
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "figures", "_data")
GREEN, GOLD, GREY, RED = "#1a3d28", "#c5a55a", "#8c8c8c", "#b03a2e"

ap = argparse.ArgumentParser()
ap.add_argument("--doi", default=None)
ap.add_argument("--out", default=os.path.join(HERE, "00_FVS-ACD_v1211_graphical_abstract.png"))
args = ap.parse_args()


def rows(fn):
    with open(os.path.join(DATA, fn), encoding="utf8") as fh:
        return list(csv.DictReader(fh))


fig = plt.figure(figsize=(13.0, 6.6), dpi=200)
gs = fig.add_gridspec(2, 3, height_ratios=[0.13, 1.0], hspace=0.30, wspace=0.32,
                      left=0.058, right=0.982, top=0.97, bottom=0.205)

# ---- title band ----
band = fig.add_subplot(gs[0, :])
band.axis("off")
band.add_patch(plt.Rectangle((0, 0), 1, 1, transform=band.transAxes,
                             facecolor=GREEN, edgecolor="none"))
band.text(0.014, 0.60, "FVS-ACD v12.11: six model generations benchmarked against OSM-ACD v2.26.1",
          transform=band.transAxes, color="white", fontsize=14.5, fontweight="bold", va="center")
band.text(0.014, 0.17, "Acadian growth and yield, independent multi-source benchmark on the FIA NSVB system",
          transform=band.transAxes, color=GOLD, fontsize=9.6, va="center")

# ---- Panel A: generational trajectory, legacy 705-stand in-domain ----
ax = fig.add_subplot(gs[1, 0])
r = [x for x in rows("scorecard_five_v1210_frozen.csv")
     if x["subset"] == "POOLED_indomain" and x["metric"] == "TOTVOL"]
order = ["v12.5.0", "v12.7.0", "v12.7.1", "v12.9.x", "v12.10.1"]
vals = {x["model"]: float(x["bias_pct"]) for x in r}
y = [vals[m] for m in order]
osm = vals.get("OSM")
lo = {x["model"]: float(x["bias_lo95"]) for x in r}
hi = {x["model"]: float(x["bias_hi95"]) for x in r}
ylo = [lo[m] for m in order]
yhi = [hi[m] for m in order]
ax.axhline(0, color="black", lw=0.9, zorder=1)
if osm is not None:
    ax.axhspan(lo["OSM"], hi["OSM"], color=RED, alpha=0.10, zorder=0)
    ax.axhline(osm, color=RED, lw=1.4, ls="--", zorder=2, label="OSM v2.26.1 (95% CI band)")
ax.errorbar(range(len(order)), y, yerr=[np.array(y) - np.array(ylo), np.array(yhi) - np.array(y)],
            fmt="-o", color=GREEN, lw=2.0, ms=6.0, capsize=3.5, elinewidth=1.4,
            zorder=3, label="FVS-ACD (95% CI)")
ax.set_ylim(min(ylo) - 1.6, max(yhi) + 2.2)
for i, m in enumerate(order):
    if lo[m] * hi[m] > 0:
        ax.plot(i, yhi[i] + 0.8, marker="*", color=GREEN, ms=7, zorder=4)
ax.set_xticks(range(len(order)))
ax.set_xticklabels(order, rotation=32, ha="right", fontsize=8.4)
ax.set_ylabel("Total volume bias (%)", fontsize=9.4)
ax.set_title("A. Recent generations are not separable from OSM\nlegacy in-domain set, n = 705; star = CI excludes zero",
             fontsize=9.8, loc="left", color=GREEN, fontweight="bold")
ax.legend(fontsize=7.0, frameon=False, loc="upper right")
ax.grid(axis="y", alpha=0.22, lw=0.6)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

# ---- Panel B: v12.11 by source, all-sites benchmark ----
ax = fig.add_subplot(gs[1, 1])
r = rows("v1211_allsites_scorecard.csv")
srcs, seen = [], set()
for x in r:
    s = x["source"]
    if s not in seen:
        seen.add(s)
        srcs.append(s)
def shorten(s):
    s = s.split("(")[0].strip()
    return {"CFRU CTRN": "CTRN", "NB MagPlot": "NB MagPlot", "QC MagPlot": "QC MagPlot",
            "Maine FIA": "ME FIA", "Penobscot Exp. Forest": "PEF", "Baxter": "Baxter",
            "SILC/Seven Islands CFI": "SILC"}.get(s, s[:11])
key = {"BASE (frozen, no levers)": "base", "CANDIDATE v12.11": "v1211", "OSM-ACD v2.26.1": "osm"}
D = {}
for x in r:
    D.setdefault(x["source"], {})[key.get(x["model"], x["model"])] = float(x["TOTVOL_bias_pct"])
srcs = [s for s in srcs if "base" in D.get(s, {}) and "v1211" in D.get(s, {})]

# Stand-level bootstrap intervals, if the Cardinal job has been run. The two
# files spell three source names differently ("held-out" vs "held out", PEF vs
# Penobscot Exp. Forest, SILC vs SILC/Seven Islands CFI), so join on a
# normalized key rather than the raw string.
def canon(name):
    t = name.split("(")[0].strip().lower().replace("-", " ")
    for k, v in (("baxter", "baxter"), ("ctrn", "ctrn"), ("maine fia", "mefia"),
                 ("pef", "pef"), ("penobscot", "pef"), ("silc", "silc"),
                 ("nb magplot", "nb"), ("qc magplot", "qc")):
        if k in t:
            return v
    return t


CI, has_ci = {}, False
try:
    for x in rows("allsites_bias_ci.csv"):
        CI.setdefault(canon(x["source"]), {})[x["model"]] = (
            float(x["bias_pct"]), float(x["bias_lo95"]), float(x["bias_hi95"]))
    has_ci = True
except (FileNotFoundError, KeyError):
    pass


def err(src, mdl):
    """Asymmetric yerr for one bar, or nan where no interval was computed."""
    v = CI.get(canon(src), {}).get(mdl)
    if v is None:
        return np.nan, np.nan, np.nan
    est, lo, hi = v
    return est, est - lo, hi - est


idx = np.arange(len(srcs))
w = 0.27
ax.axhline(0, color="black", lw=0.9)
for off, mdl, col, lab in ((-w, "base", GREY, "Base v12.10.1"),
                           (0.0, "v1211", GREEN, "v12.11"),
                           (w, "osm", RED, "OSM v2.26.1")):
    vals = [D[s].get(mdl, np.nan) for s in srcs]
    ax.bar(idx + off, vals, w, color=col, label=lab, zorder=2)
    if has_ci:
        packed = [err(s, mdl) for s in srcs]
        dn = np.array([p[1] for p in packed], dtype=float)
        up = np.array([p[2] for p in packed], dtype=float)
        ax.errorbar(idx + off, vals, yerr=[dn, up], fmt="none", ecolor="#333333",
                    elinewidth=1.0, capsize=2.2, zorder=4)
ax.set_xticks(idx)
ax.set_xticklabels([shorten(s) for s in srcs], rotation=32, ha="right", fontsize=8.2)
ax.set_ylabel("Total volume bias (%)", fontsize=9.4)
ax.set_title("B. v12.11 halves bias on its targets\n" +
             ("bars 95% bootstrap CI over stands" if has_ci else "no intervals computed"),
             fontsize=9.8, loc="left", color=GREEN, fontweight="bold")
ax.legend(fontsize=7.2, frameon=False, ncol=3, loc="lower center",
          bbox_to_anchor=(0.5, -0.02))
ax.grid(axis="y", alpha=0.22, lw=0.6)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

# ---- Panel C: measured-height coverage census ----
ax = fig.add_subplot(gs[1, 2])
r = [x for x in rows("height_coverage_census.csv") if x["group"] == "all"]
nice = {"pef": "PEF", "baxter": "Baxter", "magp_qcnb": "NB+QC MagPlot", "ctrn": "CTRN",
        "ns_long": "NS long", "ns": "Nova Scotia", "mefia": "ME FIA", "mefia_long": "ME FIA long",
        "mefia_subp": "ME FIA subp", "silc": "SILC", "silc_l": "SILC long"}
r.sort(key=lambda x: float(x["pct_ba_meas"]))
names = [nice.get(x["source"], x["source"]) for x in r]
cov = [float(x["pct_ba_meas"]) for x in r]
cols = [RED if c < 60 else (GOLD if c < 95 else GREEN) for c in cov]
ax.barh(np.arange(len(names)), cov, color=cols)
ax.set_yticks(np.arange(len(names)))
ax.set_yticklabels(names, fontsize=7.8)
for i, c in enumerate(cov):
    ax.text(c + 1.4, i, "%.0f%%" % c, va="center", fontsize=7.6, color="#333333")
ax.set_xlim(0, 112)
ax.set_xlabel("t2 basal area with a measured height (%)", fontsize=9.0)
ax.set_title("C. Managed sources are the imputed ones\ncensus, 11 sources; complete count, no CI",
             fontsize=9.8, loc="left", color=GREEN, fontweight="bold")
ax.grid(axis="x", alpha=0.22, lw=0.6)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

foot = ("Weiskittel, A. and Rice, B.  Center for Research on Sustainable Forests, University of Maine.  "
        "CC BY 4.0.  Aggregates only; no FIA true plot coordinates.")
if args.doi:
    foot = "DOI: %s   |   %s" % (args.doi, foot)
fig.text(0.058, 0.028, foot, fontsize=7.8, color="#444444")

fig.savefig(args.out, dpi=200, facecolor="white")
print("wrote", args.out)
