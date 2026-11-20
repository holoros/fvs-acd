#!/usr/bin/env python3
"""Stress-test diagnostics for the Seven Islands bridge arms. Aggregate output only (agg/stress_diag.json)."""
import glob, json, sqlite3, re, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); R = H / "restricted/silc_agmbench_gapfill_20261117"; S = H / "restricted/seven_islands_100yr_20261117"; O = H / "jobs/silc_agmbench_100yr_20261117/agg"
K = pd.read_csv(R / "key_start.csv").set_index("plot_id"); PL = pd.read_csv(R / "plots.csv").set_index("PLOT_ID")
SB = pd.read_csv(R / "silc_sdib.csv"); SB["plot_id"] = SB.sid.str[1:].astype(int); SB = SB.set_index("plot_id"); out = {}
runs = {"prod": "prod_fix_ing1", "x142sb": "x142sb_ing1"}
# 1 run integrity
for k, r in runs.items():
    calls = [int(Path(f).read_text().split()[3]) for f in glob.glob(str(R / f"batch/{r}/b*/P*/DONE"))]
    err = 0
    for f in glob.glob(str(R / f"batch/{r}/b*/P*/Acadian.log")):
        if re.search(r"Error|error in|try-error", Path(f).read_text(errors="replace")): err += 1
    out[f"integrity_{k}"] = dict(runs=len(calls), calls_min=min(calls), calls_max=max(calls), acadian_logs_with_error_text=err)
A = pd.read_csv(R / "results/prod_fix_ing1.csv"); B = pd.read_csv(R / "results/x142sb_ing1.csv")
a = A[A.year_offset == 100].set_index("plot_id"); b = B[B.year_offset == 100].set_index("plot_id").loc[a.index]
same = (a.ba_ft2ac - b.ba_ft2ac).abs() < 0.01
out["identical_ba100_between_arms"] = dict(plots=int(same.sum()), mean_start_ba=float(K.loc[a.index[same], "ba_ft2ac"].mean()) if same.any() else None,
    mean_ba100=float(a.ba_ft2ac[same].mean()) if same.any() else None, mean_start_tpa=float(K.loc[a.index[same], "tpa"].mean()) if same.any() else None,
    mean_n_rec=float(K.loc[a.index[same], "n_rec"].mean()) if same.any() else None)
# 2 share of plots above each ceiling by year, two SDI definitions (bridge arms have summation SDI)
smx_s = PL.sdi_max; smx_b = SB.sdimax / 2.471054; rows = []
def shares(D, lab, col):
    for y in (0, 25, 50, 75, 100):
        d = D[D.year_offset == y].set_index("plot_id"); s = d[col]
        rows.append(dict(model=lab, sdi=col, year=y, mean_sdi=float(s.mean()), pct_over_silc=float((s / smx_s.loc[d.index] > 1).mean() * 100), pct_over_brms=float((s / smx_b.loc[d.index] > 1).mean() * 100),
                         mean_rd_brms=float((s / smx_b.loc[d.index]).mean())))
for lab, D in (("ACD 12.5.2 production", A), ("ACD 14.2 brms SDImax", B)):
    D = D.assign(sdi_qmd=D.tpa * (D.qmd_in / 10) ** 1.605); shares(D, lab, "sdi"); shares(D, lab, "sdi_qmd")
for f, lab in (("fvs_ne.csv", "FVS-NE"), ("osm.csv", "OSM")):
    D = pd.read_csv(S / "results" / f); D = D.assign(sdi_qmd=D.tpa * (D.qmd_in / 10) ** 1.605); shares(D, lab, "sdi_qmd")
pd.DataFrame(rows).round(2).to_csv(O / "stress_ceiling_shares.csv", index=False)
# 3 size structure, diameter growth and mortality by DBH class, years 50 and 100
cls = [0, 5, 10, 15, 20, 25, 99]; rows = []
for k, r in runs.items():
    T = []
    for f in glob.glob(str(R / f"batch/{r}/b*/P*/fvsout.db")):
        pid = int(Path(f).parent.name[1:]); c = sqlite3.connect(f); t = pd.read_sql("select Year, TPA, MortPA, DBH, DG from FVS_TreeList", c); c.close()
        t["off"] = t.Year - int(K.loc[pid, "inv_year"]); T.append(t[t.off.isin([50, 100])])
    T = pd.concat(T); T["cl"] = pd.cut(T.DBH, cls, right=False)
    for (off, cl), g in T.groupby(["off", "cl"], observed=True):
        n = g.TPA.sum(); rows.append(dict(arm=k, year=int(off), dbh_class=str(cl), tpa_per_plot=float(n / 525), ba_per_plot=float((g.TPA * 0.005454154 * g.DBH ** 2).sum() / 525),
            dg5_in=float((g.DG * g.TPA).sum() / n) if n > 0 else None, mort5_pct=float(g.MortPA.sum() / (n + g.MortPA.sum()) * 100) if n > 0 else None))
    q = T[T.off == 100]; o = np.argsort(q.DBH.values); w = np.cumsum(q.TPA.values[o]) / q.TPA.sum()
    out[f"dbh100_{k}"] = dict(p50=float(q.DBH.values[o][np.searchsorted(w, .5)]), p90=float(q.DBH.values[o][np.searchsorted(w, .9)]), p99=float(q.DBH.values[o][np.searchsorted(w, .99)]), max=float(q.DBH.max()))
pd.DataFrame(rows).round(3).to_csv(O / "stress_size_growth_mortality.csv", index=False)
# 4 decadal basal area increment and late-century curvature, all models
T = pd.read_csv(O / "overall_trajectory.csv"); T = T[T.metric == "ba_ft2ac"].pivot(index="model", columns="year", values="mean")
out["ba_increment_ft2ac_per_decade"] = {m: {f"{y}-{y+10}": round(float(T.loc[m, y + 10] - T.loc[m, y]), 2) for y in range(0, 100, 10)} for m in T.index}
(O / "stress_diag.json").write_text(json.dumps(out, indent=1)); print(json.dumps(out, indent=1))
print(pd.read_csv(O / "stress_ceiling_shares.csv").to_string()); print(pd.read_csv(O / "stress_size_growth_mortality.csv").to_string())
