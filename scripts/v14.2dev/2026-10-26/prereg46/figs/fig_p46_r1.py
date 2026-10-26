# Companion figure for PREREG46 (26 October 2026): the frozen assembly figure gyr142-p46-relht-longrun_2026-10-11.png drew two
# legends, clipped the first and dropped qc_lz from the second. This redraws the same three panels from its own data CSVs
# (gyr142-p46-relht_DATA_2026-10-11.csv, gyr142-p46-topht100_DATA_2026-10-11.csv) with one legend. Values unchanged. No em dashes.
import sys, matplotlib; matplotlib.use("Agg")
import pandas as pd, matplotlib.pyplot as plt, numpy as np
D, O = sys.argv[1], sys.argv[2]
FB = pd.read_csv(f"{D}/gyr142-p46-relht_DATA_2026-10-11.csv"); TT = pd.read_csv(f"{D}/gyr142-p46-topht100_DATA_2026-10-11.csv")
LEV = ["qc141 (0.111)", "p38_fit (1.242)", "qc_rh, exp (frozen)", "qc_lz, linear zero"]
COL = dict(zip(LEV, ["#555555", "#1b6ca8", "#b5452b", "#2e8b57"]))
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9, "axes.spines.top": False, "axes.spines.right": False})
fig = plt.figure(figsize=(7.5, 7.0)); gs = fig.add_gridspec(2, 2, height_ratios=[1, 1.15], hspace=0.38, wspace=0.28)
def bias(ax, panel, order, xlab, tag):
    d = FB[FB.panel == panel]; off = np.linspace(-0.27, 0.27, len(LEV))
    ax.axhspan(-0.04, 0.04, color="#1b6ca8", alpha=0.10, lw=0); ax.axhline(0, ls="--", c="grey", lw=0.8)
    for k, a in enumerate(LEV):
        s = d[d.armlab == a].set_index("grp").reindex(order)
        x = np.arange(len(order)) + off[k]
        ax.errorbar(x, s.bias_m_yr, yerr=[s.bias_m_yr - s.bias_lo, s.bias_hi - s.bias_m_yr], fmt="o", ms=4, c=COL[a], capsize=2, lw=1, label=a)
    ax.set_xticks(range(len(order))); ax.set_xticklabels(order); ax.set_xlabel(xlab)
    ax.set_ylabel("Height increment bias (m yr$^{-1}$)"); ax.text(-0.12, 1.04, tag, transform=ax.transAxes, fontweight="bold", fontsize=12)
REL = ["below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25"]; CLS = ["below 12.7", "12.7 to 25", "25 and over"]
bias(fig.add_subplot(gs[0, 0]), "rel", REL, "t1 height over ESI", "a"); bias(fig.add_subplot(gs[0, 1]), "cls", CLS, "t1 DBH class (cm)", "b")
ax = fig.add_subplot(gs[1, :])
ARM = {"qc141": LEV[0], "p38_fit": LEV[1], "qc_rh": LEV[2], "qc_lz": LEV[3]}
for a, lab in ARM.items():
    s = TT[TT.arm == a].sort_values("age")
    ax.fill_between(s.age, s.lo, s.hi, color=COL[lab], alpha=0.12, lw=0); ax.plot(s.age, s.rel, c=COL[lab], lw=1.6)
ax.axhline(1.175, ls="--", c="black", lw=0.9); ax.axhline(1.285, ls=":", c="black", lw=0.9)
ax.text(101, 1.18, "1.175 (q99)", va="bottom", fontsize=8); ax.text(101, 1.29, "1.285 (max)", va="bottom", fontsize=8)
ax.set_xlim(0, 112); ax.set_xlabel("Years projected"); ax.set_ylabel("Top height over ESI (mean, P10 to P90)")
ax.text(-0.055, 1.04, "c", transform=ax.transAxes, fontweight="bold", fontsize=12)
h = [plt.Line2D([], [], c=COL[a], marker="o", lw=1.6, ms=4) for a in LEV]
fig.legend(h, LEV, loc="lower center", ncol=4, frameon=False, bbox_to_anchor=(0.5, 0.0))
fig.subplots_adjust(bottom=0.11, top=0.95, left=0.09, right=0.93)
fig.savefig(O, dpi=300); print("saved", O)
