#!/usr/bin/env python3
"""Seven Islands 100-year comparison, final aggregates for the SILC deck and report (19 November 2026). Aggregates only.
Primary arms: OSM 2.26.1, FVS-NE, FVS-ACD 12.5.2 production as shipped (ingrowth cut point 0.95, no recruitment),
FVS-ACD 14.2 brms SDImax and FVS-ACD 14.3 (ln 5 tree hazard) with the brms SDImax cap, both with ingrowth at cut point 0 and 5 cm.
Secondary arms: production with the same ingrowth, 14.3 without the cap, research versions v12.11.1 to v14.1 (appendix).
QMD for groups is the ratio of means sqrt(mean BA / mean TPA / 0.005454154). Relative density uses SDI from plot QMD and TPA
(the one definition every arm supports) against each plot's brms SDImax. Stand-cluster bootstrap, 2,000 draws, seed 20261117."""
import json, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); R = H / "restricted/silc_agmbench_gapfill_20261117"; S = H / "restricted/seven_islands_100yr_20261117"
O = H / "jobs/silc_agmbench_100yr_20261117/final"; O.mkdir(exist_ok=True)
K = pd.read_csv(R / "key_start.csv", dtype={"stand_id": str}).set_index("plot_id")
SB = pd.read_csv(R / "silc_sdib.csv"); SB["plot_id"] = SB.sid.str[1:].astype(int); smx = SB.set_index("plot_id").sdimax / 2.471054
PL = pd.read_csv(R / "plots.csv").set_index("PLOT_ID")
ARMS = [("OSM 2.26.1", S / "results/osm.csv", "primary"), ("FVS-NE", S / "results/fvs_ne.csv", "primary"),
        ("FVS-ACD 12.5.2 production", R / "results/prod_fix_ing1.csv", "primary"),
        ("FVS-ACD 14.2 brms SDImax", R / "results/x142sb_ingT0.csv", "primary"),
        ("FVS-ACD 14.3 + SDImax cap", R / "results/x143m1l5m2_ingT0.csv", "primary"),
        ("FVS-ACD 12.5.2 + ingrowth", R / "results/prod_fix_ingT0.csv", "secondary"),
        ("FVS-ACD 14.3, no cap", R / "results/x143m1l5_ingT0.csv", "secondary"),
        ("FVS-ACD native", S / "results/fvs_acd.csv", "secondary"),
        ("ACD v12.11.1", R / "research/results/acd_v12_11_1_part0*.csv", "appendix"), ("ACD v13.1 base", R / "research/results/acd_v13_1_base_part0*.csv", "appendix"),
        ("ACD v14.0.4 L2", R / "research/results/acd_v14_0_4_L2_part0*.csv", "appendix"), ("ACD v14.1 L2L", R / "research/results/acd_v14_1_L2L_part0*.csv", "appendix")]
fr = []
for lab, f, tier in ARMS:
    x = pd.concat([pd.read_csv(p) for p in sorted(f.parent.glob(f.name))]) if "*" in f.name else pd.read_csv(f)
    x = x[x.year_offset.isin(range(0, 101, 5))][["plot_id", "year_offset", "ba_ft2ac", "tpa", "qmd_in", "mcuft_ac"]].assign(arm=lab, tier=tier)
    fr.append(x)
D = pd.concat(fr, ignore_index=True)
c = D.groupby(["arm", "plot_id"]).year_offset.nunique().unstack(0); full = c.index[(c == 21).all(axis=1)]
chk = dict(plots_complete={k: int(v) for k, v in (c == 21).sum().items()}, common_plots=int(len(full)))
D = D[D.plot_id.isin(full)].copy(); D["stand"] = K.loc[D.plot_id, "stand_id"].to_numpy(); D["stratum"] = PL.loc[D.plot_id, "Matrix"].to_numpy()
D["sdi"] = np.where(D.tpa > 0, D.tpa * (D.qmd_in / 10) ** 1.605, 0); D["rd"] = D.sdi / smx.loc[D.plot_id].to_numpy()
chk["common_stands"] = int(D.stand.nunique())
y0 = D[D.year_offset == 0].pivot(index="plot_id", columns="arm", values="ba_ft2ac"); chk["year0_ba_max_abs_diff_vs_FVS-NE"] = {k: round(float((y0[k] - y0["FVS-NE"]).abs().max()), 3) for k in y0}
rng = np.random.default_rng(20261117); st = np.sort(D.stand.unique()); idx = rng.integers(0, len(st), (2000, len(st)))
def boot(g, v):
    p = g.pivot(index="plot_id", columns="year_offset", values=v); sid = g.drop_duplicates("plot_id").set_index("plot_id").stand.loc[p.index]
    sm = p.groupby(sid.values).sum().reindex(st).fillna(0).to_numpy(); n = p.groupby(sid.values).size().reindex(st).fillna(0).to_numpy()
    b = sm[idx].sum(1) / n[idx].sum(1)[:, None]; return p.columns, p.mean().to_numpy(), b
rows = []
for arm, g in D.groupby("arm"):
    yrs, mba, bba = boot(g, "ba_ft2ac"); _, mtp, btp = boot(g, "tpa")
    for v in ("ba_ft2ac", "tpa", "rd", "mcuft_ac"):
        if g[v].isna().all(): continue
        yrs, m, b = boot(g, v); lo, hi = np.percentile(b, [2.5, 97.5], axis=0)
        for j, y in enumerate(yrs): rows.append(dict(arm=arm, metric=v, year=int(y), mean=m[j], lo95=lo[j], hi95=hi[j]))
    q = np.sqrt(bba / btp / 0.005454154); lo, hi = np.percentile(q, [2.5, 97.5], axis=0); m = np.sqrt(mba / mtp / 0.005454154)
    for j, y in enumerate(yrs): rows.append(dict(arm=arm, metric="qmd_in", year=int(y), mean=m[j], lo95=lo[j], hi95=hi[j]))
T = pd.DataFrame(rows).merge(pd.DataFrame([(a, t) for a, _, t in ARMS], columns=["arm", "tier"]), on="arm"); T.round(4).to_csv(O / "trajectory.csv", index=False)
# year 100 table and behavior
f = []
for arm, g in D.groupby("arm"):
    a = g[g.year_offset == 0].set_index("plot_id"); z = g[g.year_offset == 100].set_index("plot_id").loc[a.index]; mx = g.groupby("plot_id").ba_ft2ac.max()
    t = T[(T.arm == arm) & (T.year == 100)].set_index("metric")
    f.append(dict(arm=arm, ba100=z.ba_ft2ac.mean(), ba100_lo=t.loc["ba_ft2ac", "lo95"], ba100_hi=t.loc["ba_ft2ac", "hi95"], ba_change_pct=(z.ba_ft2ac.mean() / a.ba_ft2ac.mean() - 1) * 100,
        tpa100=z.tpa.mean(), qmd100=t.loc["qmd_in", "mean"], rd100=z.rd.mean(), mcuft100=z.mcuft_ac.mean() if z.mcuft_ac.notna().any() else np.nan,
        pct_ba_lower=(z.ba_ft2ac < a.ba_ft2ac).mean() * 100, pct_rd_gt1_y100=(z.rd > 1).mean() * 100, pct_peak_ba_gt300=(mx > 300).mean() * 100,
        ba_peak_year=int(T[(T.arm == arm) & (T.metric == "ba_ft2ac")].sort_values("mean").year.iloc[-1]),
        ba_change_last25=float(T[(T.arm == arm) & (T.metric == "ba_ft2ac") & (T.year == 100)]["mean"].iloc[0] - T[(T.arm == arm) & (T.metric == "ba_ft2ac") & (T.year == 75)]["mean"].iloc[0])))
pd.DataFrame(f).round(2).to_csv(O / "year100_summary.csv", index=False)
# strata at year 100
s = D[D.year_offset.isin([0, 100])].groupby(["arm", "stratum", "year_offset"]).agg(n_plots=("plot_id", "nunique"), n_stands=("stand", "nunique"), ba=("ba_ft2ac", "mean"), tpa=("tpa", "mean")).reset_index()
s["qmd"] = np.sqrt(s.ba / s.tpa / 0.005454154); s.round(2).to_csv(O / "strata.csv", index=False)
# paired year-100 BA differences against OSM, stand-cluster bootstrap
z = D[D.year_offset == 100].pivot(index="plot_id", columns="arm", values="ba_ft2ac"); sid = D.drop_duplicates("plot_id").set_index("plot_id").stand.loc[z.index]
pr = []
for arm in z.columns:
    if arm == "OSM 2.26.1": continue
    d = (z[arm] - z["OSM 2.26.1"]); sm = d.groupby(sid.values).sum().reindex(st).to_numpy(); n = d.groupby(sid.values).size().reindex(st).to_numpy()
    b = sm[idx].sum(1) / n[idx].sum(1); pr.append(dict(arm=arm, diff_vs_osm=d.mean(), lo95=np.percentile(b, 2.5), hi95=np.percentile(b, 97.5)))
pd.DataFrame(pr).round(2).to_csv(O / "paired_vs_osm.csv", index=False)
(O / "checks.json").write_text(json.dumps(chk, indent=1)); print(json.dumps(chk, indent=1)); print(pd.DataFrame(f).round(1).to_string()); print(pd.DataFrame(pr).round(1).to_string())
