#!/usr/bin/env python3
"""Seven Islands 100-year comparison: join PR 30's OSM, FVS-NE and native FVS-ACD with the gap-fill arms and write
aggregate-only summaries (no plot rows, no coordinates) to JOB/agg. Stand-cluster bootstrap, 2,000 draws, seed 20261117.
SDI here is Reineke's from QMD and TPA (TPA x (QMD/10)^1.605) so it is defined the same way for every model."""
import json, glob, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); R = H / "restricted/silc_agmbench_gapfill_20261117"; S = H / "restricted/seven_islands_100yr_20261117"
O = H / "jobs/silc_agmbench_100yr_20261117/agg"; O.mkdir(exist_ok=True)
K = pd.read_csv(R / "key_start.csv", dtype={"stand_id": str}); PL = pd.read_csv(R / "plots.csv", dtype={"Stand": str})
SB = pd.read_csv(R / "silc_sdib.csv"); SB["plot_id"] = SB.sid.str[1:].astype(int)
meta = K[["plot_id", "stand_id", "matrix"]].merge(PL[["PLOT_ID", "sdi_max"]].rename(columns={"PLOT_ID": "plot_id", "sdi_max": "sdimax_silc"}), on="plot_id")
meta = meta.merge(SB[["plot_id", "sdimax"]].assign(sdimax_brms=lambda d: d.sdimax / 2.471054).drop(columns="sdimax"), on="plot_id")
chk = {}; frames = []
def add(f, label=None):
    if not Path(f).exists() or Path(f).stat().st_size < 10: return None
    x = pd.read_csv(f); x = x[x.year_offset.isin(range(0, 101, 5))]
    if label: x["model"] = label
    frames.append(x[["plot_id", "model", "year_offset", "ba_ft2ac", "tpa", "qmd_in", "mcuft_ac"]]); return x
add(S / "results/osm.csv"); add(S / "results/fvs_ne.csv"); add(S / "results/fvs_acd.csv", "FVS-ACD native")
for run, lab in (("prod_fix_ing1", "ACD 12.5.2 production"), ("x142sb_ing1", "ACD 14.2 brms SDImax"),
                 ("prod_fix_ing0", "ACD 12.5.2 production, no ingrowth"), ("x142sb_ing0", "ACD 14.2 brms SDImax, no ingrowth")):
    e = R / f"results/{run}_errors.csv"; x = add(R / f"results/{run}.csv", lab)
    chk[run] = dict(plots=int(x.plot_id.nunique()) if x is not None else 0, errors=int(len(pd.read_csv(e))) if e.exists() else None)
for slug, lab in (("v12_11_1", "ACD v12.11.1"), ("v13_1_base", "ACD v13.1 base"), ("v14_0_4_L2", "ACD v14.0.4 L2"), ("v14_1_L2L", "ACD v14.1 L2L")):
    parts = sorted(glob.glob(str(R / f"research/results/acd_{slug}_part0*.csv")))
    x = pd.concat([pd.read_csv(p) for p in parts], ignore_index=True); c = x.groupby("plot_id").year_offset.nunique()
    old = pd.read_csv(S / f"results/acd_{slug}.csv"); m = old.merge(x, on=["plot_id", "year_offset"], suffixes=("_pr30", "_new"))
    chk[lab] = dict(plots=int(len(c)), complete_21=int((c == 21).sum()), pr30_plots_matched=int(m.plot_id.nunique()),
                    max_abs_ba_diff_vs_pr30=float((m.ba_ft2ac_pr30 - m.ba_ft2ac_new).abs().max()), max_abs_tpa_diff_vs_pr30=float((m.tpa_pr30 - m.tpa_new).abs().max()))
    x["model"] = lab; frames.append(x[["plot_id", "model", "year_offset", "ba_ft2ac", "tpa", "qmd_in", "mcuft_ac"]])
D = pd.concat(frames, ignore_index=True).merge(meta, on="plot_id")
D["sdi"] = D.tpa * (D.qmd_in / 10) ** 1.605; D.loc[D.tpa <= 0, "sdi"] = 0
D["rd_silc"] = D.sdi / D.sdimax_silc; D["rd_brms"] = D.sdi / D.sdimax_brms
# completeness and common plot set
c = D.groupby(["model", "plot_id"]).year_offset.nunique().unstack(0); full = c.index[(c == 21).all(axis=1)]
chk["plots_complete_by_model"] = {k: int(v) for k, v in (c == 21).sum().items()}; chk["common_plots"] = int(len(full))
D = D[D.plot_id.isin(full)]; chk["common_stands"] = int(D.stand_id.nunique())
y0 = D[D.year_offset == 0].pivot(index="plot_id", columns="model", values="ba_ft2ac")
chk["year0_ba_max_abs_diff_vs_FVS-NE"] = {k: round(float((y0[k] - y0["FVS-NE"]).abs().max()), 3) for k in y0}
chk["year0_ba_mean_diff_vs_FVS-NE"] = {k: round(float((y0[k] - y0["FVS-NE"]).mean()), 4) for k in y0}
# cycle-length check: 5-year cycles against one 100-year cycle, year 100
for run, lab in (("prod_fix_ing1", "ACD 12.5.2 production"), ("x142sb_ing1", "ACD 14.2 brms SDImax")):
    f = R / f"results/{run}_c100.csv"
    if f.exists():
        a = pd.read_csv(f); a = a[a.year_offset == 100].set_index("plot_id"); b = pd.read_csv(R / f"results/{run}.csv"); b = b[b.year_offset == 100].set_index("plot_id").loc[a.index]
        chk[f"cycle_check_{run}"] = dict(plots=int(len(a)), **{f"{v}_mean_5yr": round(float(b[v].mean()), 2) for v in ("ba_ft2ac", "tpa", "qmd_in")},
            **{f"{v}_mean_100yr": round(float(a[v].mean()), 2) for v in ("ba_ft2ac", "tpa", "qmd_in")},
            ba_median_abs_pct_diff=round(float(((b.ba_ft2ac - a.ba_ft2ac).abs() / a.ba_ft2ac.clip(lower=1)).median() * 100), 2))
# overall trajectories with stand-cluster bootstrap
rng = np.random.default_rng(20261117); st = np.sort(D.stand_id.unique()); idx = rng.integers(0, len(st), (2000, len(st)))
V = ["ba_ft2ac", "tpa", "qmd_in", "sdi", "rd_silc", "rd_brms", "mcuft_ac"]; rows = []
for mdl, g in D.groupby("model"):
    for v in V:
        if g[v].isna().all(): continue
        p = g.pivot(index="plot_id", columns="year_offset", values=v); sid = g.drop_duplicates("plot_id").set_index("plot_id").stand_id.loc[p.index]
        sm = p.groupby(sid.values).sum().reindex(st).to_numpy(); n = p.groupby(sid.values).size().reindex(st).to_numpy()
        b = sm[idx].sum(1) / n[idx].sum(1)[:, None]; lo, hi = np.percentile(b, [2.5, 97.5], axis=0)
        for j, yr in enumerate(p.columns): rows.append(dict(model=mdl, metric=v, year=int(yr), mean=float(p[yr].mean()), lo95=float(lo[j]), hi95=float(hi[j]), n_plots=int(len(p)), n_stands=int(len(st))))
pd.DataFrame(rows).round(4).to_csv(O / "overall_trajectory.csv", index=False)
# strata (Matrix) means at years 0, 50, 100
g = D[D.year_offset.isin([0, 50, 100])].groupby(["model", "matrix", "year_offset"])
s = g.agg(n_plots=("plot_id", "nunique"), n_stands=("stand_id", "nunique"), ba_ft2ac=("ba_ft2ac", "mean"), tpa=("tpa", "mean"), qmd_in=("qmd_in", "mean"), sdi=("sdi", "mean"), rd_silc=("rd_silc", "mean")).reset_index()
s.round(3).to_csv(O / "strata_summary.csv", index=False)
# behavior flags
f = []
for mdl, g in D.groupby("model"):
    a = g[g.year_offset == 0].set_index("plot_id"); z = g[g.year_offset == 100].set_index("plot_id").loc[a.index]; mx = g.groupby("plot_id").ba_ft2ac.max()
    f.append(dict(model=mdl, ba0=a.ba_ft2ac.mean(), ba100=z.ba_ft2ac.mean(), ba_change_pct=(z.ba_ft2ac.mean() / a.ba_ft2ac.mean() - 1) * 100, tpa100=z.tpa.mean(), qmd100=z.qmd_in.mean(),
        sdi100=z.sdi.mean(), pct_plots_ba_lower_at_100=(z.ba_ft2ac < a.ba_ft2ac).mean() * 100, pct_plots_ba100_over_250=(z.ba_ft2ac > 250).mean() * 100,
        pct_plots_peak_ba_over_300=(mx > 300).mean() * 100, p99_ba100=z.ba_ft2ac.quantile(.99), pct_rd_silc_over1_at_100=(z.rd_silc > 1).mean() * 100,
        pct_rd_brms_over1_at_100=(z.rd_brms > 1).mean() * 100, mean_rd_silc_100=z.rd_silc.mean(), mean_rd_brms_100=z.rd_brms.mean(), pct_plots_tpa100_under_50=(z.tpa < 50).mean() * 100))
pd.DataFrame(f).round(2).to_csv(O / "behavior_flags.csv", index=False)
(O / "checks.json").write_text(json.dumps(chk, indent=1)); print(json.dumps(chk, indent=1)); print(pd.DataFrame(f).round(1).to_string())
