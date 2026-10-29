# Howland cross-version FVS-ACD projections, 26 October 2026. Reads the 23 October 12.3.6 and v13.1 ship18 summaries and the
# per plot trajectories of v131h, v141off (job 15888501) and v141L (job 15795712). Biomass is shown as percent of year 0 within
# each version, because 12.3.6 and ship18 report Jenkins AGB and the runner arms report runner biomass. Bands are 95% plot
# bootstrap intervals of the mean (B = 2000, seed 20261026). No em dashes.
import sys, numpy as np, pandas as pd, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
R, PKL, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
rng = np.random.default_rng(20261026); B = 2000
D = pd.read_pickle(PKL)
S18 = pd.read_csv(f"{R}/v131_ship18_trajectories.csv.gz"); S18["yr"] = S18.year - 2025
V12 = pd.read_csv(f"{R}/v1236_csi_summary.csv")
J0 = 210.4  # initial mean Jenkins AGB, 23 October README

def boot(M):  # M: plots x years
    n = M.shape[0]; idx = rng.integers(0, n, (B, n))
    bm = M[idx].mean(1); return M.mean(0), np.percentile(bm, 2.5, 0), np.percentile(bm, 97.5, 0)

rows, curves = [], {}
for a in ["v131h", "v141off", "v141L"]:
    for e in [12, 15, 18]:
        d = D[(D.arm == a) & (D.E == e)]
        for v, col in [("bio", "BIOMASS"), ("ba", "BA")]:
            W = d.pivot_table(index="PLOT", columns="yr", values=col)
            if v == "bio": W = 100 * W / W[0].mean() - 100
            m, lo, hi = boot(W.values); curves[(a, e, v)] = (W.columns.values, m, lo, hi)
        Wb = d.pivot_table(index="PLOT", columns="yr", values="BIOMASS")
        rows.append(dict(version=a, site=f"ESI {e}", bio0=Wb[0].mean(), bio10=Wb[10].mean(), bio50=Wb[50].mean(),
                         pct50=100*(Wb[50].mean()/Wb[0].mean()-1), ba50=d[d.yr == 50].BA.mean(),
                         n_decline=int((Wb[50] < Wb[0]).sum())))
for c in [10, 12, 14]:
    d = S18[S18.CSI == c]
    for v, col in [("bio", "agb_J"), ("ba", "ba")]:
        W = d.pivot_table(index="PLOT", columns="yr", values=col)
        if v == "bio": W = 100 * W / J0 - 100
        m, lo, hi = boot(W.values)
        x = np.r_[0, W.columns.values]; base = 0.0 if v == "bio" else 41.5
        curves[("ship18", c, v)] = (x, np.r_[base, m], np.r_[base, lo], np.r_[base, hi])
    W = d.pivot_table(index="PLOT", columns="yr", values="agb_J")
    rows.append(dict(version="v13.1 ship18", site=f"CSI {c}", bio0=J0, bio10=np.nan, bio50=W[50].mean(),
                     pct50=100*(W[50].mean()/J0-1), ba50=d[d.yr == 50].ba.mean(), n_decline=np.nan))
for c in [10, 12, 14]:
    v = V12[V12.CSI == c].set_index("year").agb
    rows.append(dict(version="12.3.6", site=f"CSI {c}", bio0=J0, bio10=np.nan, bio50=v[2075], pct50=100*(v[2075]/J0-1),
                     ba50=np.nan, n_decline=np.nan))
T = pd.DataFrame(rows); T.to_csv(f"{OUT}_table.csv", index=False, float_format="%.2f")

plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9, "axes.spines.top": False, "axes.spines.right": False})
COL = {"12.3.6": "#4d4d4d", "ship18": "#b2182b", "v131h": "#ef8a62", "v141off": "#2166ac", "v141L": "#67a9cf"}
LAB = {"12.3.6": "12.3.6 (CSI 12)", "ship18": "13.1 ship18 (CSI 12)", "v131h": "13.1h Seven Islands (ESI 15)",
       "v141off": "14.0.4 L2 (ESI 15)", "v141L": "14.1, L on (ESI 15)"}
MID = {"ship18": 12, "v131h": 15, "v141off": 15, "v141L": 15}
fig, ax = plt.subplots(1, 3, figsize=(7.5, 3.2), gridspec_kw=dict(width_ratios=[1.25, 1.25, 1]))
for k in ["ship18", "v131h", "v141off", "v141L"]:
    for j, v in enumerate(["bio", "ba"]):
        x, m, lo, hi = curves[(k, MID[k], v)]
        ax[j].fill_between(x, lo, hi, color=COL[k], alpha=.18, lw=0); ax[j].plot(x, m, color=COL[k], lw=1.4, label=LAB[k])
p = V12[V12.CSI == 12].set_index("year").agb
ax[0].plot([0, 8, 50], [0, 100*(p[2033]/J0-1), 100*(p[2075]/J0-1)], "o--", color=COL["12.3.6"], ms=3, lw=1, label=LAB["12.3.6"])
ax[0].axhline(0, color="k", lw=.5); ax[0].set_ylabel("Biomass change from year 0 (%)"); ax[0].set_xlabel("Projection year")
ax[1].set_ylabel(r"Basal area (m$^{2}$ ha$^{-1}$)"); ax[1].set_xlabel("Projection year")
h, l = ax[0].get_legend_handles_labels(); fig.legend(h, l, frameon=False, fontsize=7, ncol=5, loc="upper center", bbox_to_anchor=(.5, 1.0))
for i, k in enumerate(["ship18", "v131h", "v141off", "v141L"]):
    if k == "ship18":
        s = T[T.version == "v13.1 ship18"]; y = pd.read_csv(f"{R}/v131_ship18_summary.csv").n_decline_50yr.values
    else:
        y = T[T.version == k].n_decline.values
    ax[2].plot(np.arange(3) + (i - 1.5) * .12, y, "o-", color=COL[k], ms=3.5, lw=1)
ax[2].set_xticks(range(3)); ax[2].set_xticklabels(["low", "mid", "high"]); ax[2].set_xlabel("Site level")
ax[2].set_ylabel("Plots losing biomass by year 50 (of 93)"); ax[2].set_ylim(0, 93)
for a_, t in zip(ax, "abc"): a_.text(-.02, 1.04, t, transform=a_.transAxes, fontweight="bold")
fig.tight_layout(rect=(0, 0, 1, .9)); fig.savefig(f"{OUT}.png", dpi=300); fig.savefig(f"{OUT}.pdf")
print(T.to_string())
