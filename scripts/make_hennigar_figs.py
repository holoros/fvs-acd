#!/usr/bin/env python3
# Hennigar deck figures from the clean scorecard. Aggregates only. matplotlib.
import pandas as pd, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FIG  = os.path.join(ROOT, "figures")
os.makedirs(FIG, exist_ok=True)
d = pd.read_csv(os.path.join(ROOT, "results/seven_islands/scorecard_clean_all.csv"))

METS = ["BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE"]
MODS = ["v125","v1270","v1271","v129x","osm"]
LAB  = {"v125":"FVS v12.5.0","v1270":"FVS v12.7.0","v1271":"FVS v12.7.1","v129x":"FVS v12.9.x","osm":"OSM v2.26.1"}
FOREST="#2C5F2D"; MOSS="#97BC62"; CREAM="#F5F5F5"; OSMC="#B85042"; GREY="#7A7A7A"; LT="#C7DBB5"
MCOL={"v125":GREY,"v1270":LT,"v1271":MOSS,"v129x":FOREST,"osm":OSMC}
plt.rcParams.update({"font.family":"DejaVu Sans","font.size":11,"axes.edgecolor":"#444444"})

# ---------- 1. Heatmap of level bias% (POOLED) ----------
P = d[(d.subset=="POOLED")].pivot(index="model", columns="metric", values="bias_pct").reindex(MODS)[METS]
fig, ax = plt.subplots(figsize=(11,4.2))
vmax=25
im = ax.imshow(P.values, cmap="RdYlGn_r", vmin=-vmax, vmax=vmax, aspect="auto")
ax.set_xticks(range(len(METS))); ax.set_xticklabels(METS, fontsize=10)
ax.set_yticks(range(len(MODS))); ax.set_yticklabels([LAB[m] for m in MODS], fontsize=11)
for i,m in enumerate(MODS):
    for j,me in enumerate(METS):
        v=P.loc[m,me]
        ax.text(j,i,f"{v:+.0f}", ha="center", va="center", fontsize=9.5,
                color="white" if abs(v)>13 else "#222222", fontweight="bold")
ax.set_title("Level bias (%), predicted vs observed, pooled in-domain (n=685)", fontsize=13, color=FOREST, fontweight="bold", pad=10)
cb=fig.colorbar(im, ax=ax, fraction=0.025, pad=0.02); cb.set_label("bias %", fontsize=9)
fig.tight_layout(); fig.savefig(os.path.join(FIG,"hennigar_scorecard_heatmap.png"), dpi=160); plt.close(fig)

# ---------- 2. Radar of NSE (modeling efficiency), POOLED ----------
N = d[(d.subset=="POOLED")].pivot(index="model", columns="metric", values="nse").reindex(MODS)[METS]
ang = np.linspace(0, 2*np.pi, len(METS), endpoint=False).tolist(); ang += ang[:1]
fig = plt.figure(figsize=(7.4,7.0)); ax = plt.subplot(111, polar=True)
for m in MODS:
    vals = N.loc[m].tolist(); vals += vals[:1]
    lw = 3 if m in ("v129x","osm") else 1.8
    ax.plot(ang, vals, color=MCOL[m], lw=lw, label=LAB[m])
    ax.fill(ang, vals, color=MCOL[m], alpha=0.06)
ax.set_xticks(ang[:-1]); ax.set_xticklabels(METS, fontsize=10)
ax.set_ylim(0,1.0); ax.set_yticks([0.25,0.5,0.75,1.0]); ax.set_yticklabels(["0.25","0.50","0.75","1.0"], fontsize=8)
ax.set_title("Modeling efficiency (Nash-Sutcliffe), pooled\nhigher is more precise per-stand", fontsize=13, color=FOREST, fontweight="bold", pad=22)
ax.legend(loc="upper right", bbox_to_anchor=(1.28,1.12), fontsize=9, frameon=False)
fig.tight_layout(); fig.savefig(os.path.join(FIG,"hennigar_scorecard_radar.png"), dpi=160, bbox_inches="tight"); plt.close(fig)

# ---------- 3. Performance by forest type: TOTVOL bias% + equivalence markers ----------
ft = d[(d.cut=="fortype")&(d.metric=="TOTVOL")]
types=["Softwood","Mixedwood","Hardwood"]
fig, ax = plt.subplots(figsize=(10.5,5.0))
x=np.arange(len(types)); w=0.16
for k,m in enumerate(MODS):
    vals=[ft[(ft.subset==t)&(ft.model==m)]["bias_pct"].values[0] for t in types]
    eqs =[ft[(ft.subset==t)&(ft.model==m)]["tost_lvl_equiv"].values[0] for t in types]
    bars=ax.bar(x+(k-2)*w, vals, w, color=MCOL[m], label=LAB[m], edgecolor="#333333", linewidth=0.4)
    for xi,(v,eq) in enumerate(zip(vals,eqs)):
        if eq: ax.text(x[xi]+(k-2)*w, v+(1.2 if v>=0 else -2.4), "✓", ha="center", va="bottom", color=FOREST, fontsize=11, fontweight="bold")
ax.axhline(0, color="#333333", lw=0.8)
ax.axhspan(-10,10, color=MOSS, alpha=0.12, zorder=0)
ax.set_xticks(x); ax.set_xticklabels(types, fontsize=12)
ax.set_ylabel("Total volume level bias (%)"); ax.set_title("Bias is composition-driven: total volume by forest type\nshaded band = equivalence region (±10%); ✓ = statistically equivalent (TOST)", fontsize=12.5, color=FOREST, fontweight="bold")
ax.legend(ncol=5, fontsize=9, frameon=False, loc="upper left")
ax.set_ylim(-15, 68)
fig.tight_layout(); fig.savefig(os.path.join(FIG,"hennigar_perf_by_fortype.png"), dpi=160); plt.close(fig)

# ---------- 4. Equivalence-region plot (caterpillar), BA + TOTVOL, POOLED ----------
def ci_pct(row):
    dmean = row.pred_mean - row.obs_mean
    var = max(row.rmse**2 - dmean**2, 1e-9)
    se = np.sqrt(var)/np.sqrt(row.n)
    ci = 1.645*se
    return 100*dmean/row.obs_mean, 100*ci/row.obs_mean
fig, axes = plt.subplots(1,2, figsize=(11,4.6), sharey=True)
for ax,met in zip(axes,["BA","TOTVOL"]):
    sub=d[(d.subset=="POOLED")&(d.metric==met)].set_index("model").reindex(MODS)
    ax.axvspan(-10,10, color=MOSS, alpha=0.15)
    ax.axvline(0, color="#333333", lw=0.8, ls="--")
    for i,m in enumerate(MODS):
        b,c = ci_pct(sub.loc[m])
        eq = sub.loc[m,"tost_lvl_equiv"]
        ax.errorbar(b, i, xerr=c, fmt="o", color=MCOL[m], ecolor=MCOL[m], capsize=4, ms=9, lw=2)
        ax.text(b, i+0.28, ("equivalent" if eq else "not equiv."), ha="center", fontsize=8,
                color=FOREST if eq else OSMC)
    ax.set_yticks(range(len(MODS))); ax.set_yticklabels([LAB[m] for m in MODS] if met=="BA" else [])
    ax.set_xlabel("bias (% of observed mean), 90% CI"); ax.set_title(met, fontsize=12, fontweight="bold", color=FOREST, pad=12)
    ax.set_xlim(-20,25); ax.set_ylim(-0.85, len(MODS)-0.15); ax.invert_yaxis()
fig.suptitle("Equivalence testing (TOST): is predicted statistically equivalent to observed within ±10%?", fontsize=12.5, color=FOREST, fontweight="bold")
fig.tight_layout(rect=[0,0,1,0.94]); fig.savefig(os.path.join(FIG,"hennigar_equivalence_plot.png"), dpi=160); plt.close(fig)

# ---------- 5. Site productivity: anchor bake-off + edge over-prediction ----------
fig, (a1,a2) = plt.subplots(1,2, figsize=(11,4.6))
mets=["ESI","CSI","CPSI","BGI"]; ef=[0.335,0.321,0.223,0.198]; corsi=[0.667,0.488,0.156,0.020]
xb=np.arange(len(mets))
a1.bar(xb-0.2, ef, 0.4, color=FOREST, label="anchor EF (out of sample)")
a1.bar(xb+0.2, corsi, 0.4, color=MOSS, label="cor with measured site index")
a1.set_xticks(xb); a1.set_xticklabels(mets); a1.set_ylim(0,0.75)
a1.set_title("Dominant-height anchor bake-off\nESI wins both criteria", fontsize=12, color=FOREST, fontweight="bold")
a1.legend(fontsize=9, frameon=False)
for i,(e,c) in enumerate(zip(ef,corsi)):
    a1.text(i-0.2,e+0.01,f"{e:.2f}",ha="center",fontsize=8); a1.text(i+0.2,c+0.01,f"{c:.2f}",ha="center",fontsize=8)
reg=["NB\n(in-domain)","QC\n(edge)"]; ratio=[1.89,6.40]
a2.bar(reg, ratio, color=[MOSS,OSMC], edgecolor="#333")
a2.axhline(1.0, color="#333", ls="--", lw=1); a2.text(1.4,1.05,"observed = 1.0", fontsize=8, color="#333")
for i,r in enumerate(ratio): a2.text(i, r+0.12, f"{r:.1f}x", ha="center", fontweight="bold")
a2.set_ylabel("predicted / observed height increment"); a2.set_ylim(0,7.2)
a2.set_title("ESI anchor runs high at the domain edge\n(a v13 height fix, not a metric swap)", fontsize=12, color=FOREST, fontweight="bold")
fig.tight_layout(); fig.savefig(os.path.join(FIG,"hennigar_site_productivity.png"), dpi=160); plt.close(fig)

print("figures written to", FIG)
for f in ["hennigar_scorecard_heatmap","hennigar_scorecard_radar","hennigar_perf_by_fortype","hennigar_equivalence_plot","hennigar_site_productivity"]:
    print("  ", f+".png")
