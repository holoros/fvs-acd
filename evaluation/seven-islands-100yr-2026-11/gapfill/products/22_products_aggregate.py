#!/usr/bin/env python3
"""SILC products add-on, step 4: aggregates only. Stand-cluster bootstrap (2,000 draws, seed 20261117), same as 15_final_aggregate.py.
Writes JOB/final/products_trajectory.csv, products_year100.csv, products_paired_vs_osm.csv, products_checks.json."""
import json, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); R = H / "restricted/silc_agmbench_gapfill_20261117"; O = H / "jobs/silc_agmbench_100yr_20261117/final"
K = pd.read_csv(R / "key_start.csv", dtype={"stand_id": str}).set_index("plot_id")
A = pd.read_csv(R / "products/products_by_plot.csv")
c = A.groupby(["arm_label", "plot_id"]).year_offset.nunique().unstack(0); full = c.index[(c == 5).all(axis=1)]
chk = dict(plots_complete={k: int(v) for k, v in (c == 5).sum().items()}, common_plots=int(len(full)))
A = A[A.plot_id.isin(full)].copy(); A["stand"] = K.loc[A.plot_id, "stand_id"].to_numpy()
st = np.sort(A.stand.unique()); rng = np.random.default_rng(20261117); idx = rng.integers(0, len(st), (2000, len(st)))
M = ["tot_cd", "saw_cd", "pulp_cd", "saw_mbf", "val", "val_v22pulp", "val_state", "agc_mgha", "agc05_mgha", "co2e_tac"]
def boot(x):  # x: series indexed by plot_id
    sid = A.drop_duplicates("plot_id").set_index("plot_id").stand.loc[x.index]
    sm = x.groupby(sid.values).sum().reindex(st).fillna(0).to_numpy(); n = x.groupby(sid.values).size().reindex(st).fillna(0).to_numpy()
    b = sm[idx].sum(1) / n[idx].sum(1); return x.mean(), np.percentile(b, 2.5), np.percentile(b, 97.5)
rows = []
for (arm, y), g in A.groupby(["arm_label", "year_offset"]):
    g = g.set_index("plot_id")
    for m in M: mu, lo, hi = boot(g[m]); rows.append(dict(arm=arm, year=int(y), metric=m, mean=mu, lo95=lo, hi95=hi))
T = pd.DataFrame(rows); T.round(4).to_csv(O / "products_trajectory.csv", index=False)
W = T[T.year == 100].pivot(index="arm", columns="metric", values="mean"); W.round(2).to_csv(O / "products_year100.csv")
pr = []
for m in ["tot_cd", "saw_mbf", "val", "co2e_tac", "agc_mgha"]:
    z = A[A.year_offset == 100].pivot(index="plot_id", columns="arm_label", values=m)
    for arm in z.columns:
        if arm == "OSM 2.26.1": continue
        mu, lo, hi = boot(z[arm] - z["OSM 2.26.1"]); pr.append(dict(metric=m, arm=arm, diff_vs_osm=mu, lo95=lo, hi95=hi))
pd.DataFrame(pr).round(3).to_csv(O / "products_paired_vs_osm.csv", index=False)
y0 = A[A.year_offset == 0].pivot(index="plot_id", columns="arm_label", values="tot_cd")
chk["year0_tot_cd_mean_by_arm"] = {k: round(float(v), 3) for k, v in y0.mean().items()}
chk["year0_agc_mean_by_arm"] = {k: round(float(v), 3) for k, v in A[A.year_offset == 0].groupby("arm_label").agc_mgha.mean().items()}
# order-safety (F14): shuffle rows and recompute two headline means
S = A.sample(frac=1, random_state=7); chk["shuffle_check"] = {m: bool(np.isclose(S[S.year_offset == 100].groupby("arm_label")[m].mean(), A[A.year_offset == 100].groupby("arm_label")[m].mean()).all()) for m in ("val", "co2e_tac")}
(O / "products_checks.json").write_text(json.dumps(chk, indent=1)); print(json.dumps(chk, indent=1))
print(T[T.year.isin([0, 100]) & T.metric.isin(["tot_cd", "saw_mbf", "val", "co2e_tac"])].round(1).to_string(index=False))
print(pd.DataFrame(pr).round(1).to_string(index=False))
