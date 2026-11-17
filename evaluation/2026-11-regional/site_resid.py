#!/usr/bin/env python3
"""Site response check. For a set and its runs: per stand predicted and observed annual net BA change above the scoring floor
(same definitions as reg_score.py), then by ESI quintile (SICOND_FVS, m at base 50) the ratio of summed predicted to observed
net change and the mean residual (pred - obs, m2 ha-1 yr-1), and the slope of the residual on ESI (m) with t1 BA and interval
as covariates. 1,000 SITE-cluster bootstrap draws, seed 20261112. Pooled values only.
usage: site_resid.py SET RUN[,RUN..] TAG [fe]   (fe: program or block intercepts in the residual slope)"""
import sys, glob, sqlite3, json, numpy as np, pandas as pd
from pathlib import Path
S = Path.home() / "fvsacd142/state"; HA = 2.4710538; st, runs, tag = sys.argv[1], sys.argv[2].split(","), sys.argv[3]; FE = len(sys.argv) > 4 and sys.argv[4] == "fe"
P = pd.read_csv(S / (f"restricted/t14/{st}_pairs.csv" if st == "g2" else f"restricted/r0e/{st}_pairs.csv"), dtype={"pair_id": str, "t1_id": str})
P["sid"] = "P" + P.pair_id.str.strip().str[-12:]; P["obs"] = (P.obsBA2 - P.obsBA1) / P.REMPER; P["fl"] = P.SCORE_MINDBH.astype(float)
P["esi"] = P.SICOND_FVS / 3.2808399
def pred(run):
    dirs = {Path(p).name: Path(p) for p in glob.glob(str(S / f"restricted/batch/{run}/b*/P*")) + glob.glob(str(S / f"restricted/batch/{run}/all/P*")) if Path(p, "fvsout.db").exists()}
    out = {}
    for r in P.itertuples():
        d = dirs.get(r.sid)
        if d is None: continue
        con = sqlite3.connect(str(d / "fvsout.db")); tl = pd.read_sql("select Year, TPA, DBH from FVS_TreeList", con); con.close()
        ys = sorted(tl.Year.unique())
        if len(ys) < 2: continue
        ba = lambda t: float((np.pi / 40000 * (t.DBH * 2.54) ** 2 * t.TPA * HA)[t.DBH * 2.54 >= r.fl].sum())
        out[r.sid] = (ba(tl[tl.Year == ys[-1]]) - ba(tl[tl.Year == ys[0]])) / r.REMPER
    return pd.Series(out)
for k in runs: P[k] = P.sid.map(pred(k))
D = P.dropna(subset=runs + ["esi", "obs"]).sort_values("sid").reset_index(drop=True)
D["q"] = pd.qcut(D.esi, 5, labels=False)
rng = np.random.default_rng(20261112); u, inv = np.unique(D.SITE.astype(str), return_inverse=True)
W = np.stack([np.bincount(rng.integers(0, len(u), len(u)), minlength=len(u))[inv] for _ in range(1000)]).astype(float)
rows = []
for k in runs:
    res = (D[k] - D.obs).to_numpy()
    for q in range(5):
        m = (D.q == q).to_numpy(); w = W[:, m]
        ratio = (w @ D[k].to_numpy()[m]) / (w @ D.obs.to_numpy()[m]); mr = (w @ res[m]) / w.sum(1)
        rows.append(dict(run=k, quintile=q + 1, esi_lo=round(float(D.esi[m].min()), 2), esi_hi=round(float(D.esi[m].max()), 2), n=int(m.sum()),
                         ratio=float(D[k][m].sum() / D.obs[m].sum()), ratio_lo=float(np.percentile(ratio, 2.5)), ratio_hi=float(np.percentile(ratio, 97.5)),
                         mean_res=float(res[m].mean()), res_lo=float(np.percentile(mr, 2.5)), res_hi=float(np.percentile(mr, 97.5))))
    X = np.c_[np.ones(len(D)), D.esi, D.obsBA1, D.REMPER, pd.get_dummies(D.block, drop_first=True).to_numpy(float)] if FE else np.c_[np.ones(len(D)), D.esi, D.obsBA1, D.REMPER]; b = []
    for i in range(200):
        w = W[i]; Xw = X * w[:, None]; b.append(np.linalg.lstsq(X.T @ Xw, Xw.T @ res, rcond=None)[0][1])
    bb = np.linalg.lstsq(X, res, rcond=None)[0][1]
    rows.append(dict(run=k, quintile="slope_res_on_esi" + ("_within_block" if FE else ""), n=int(len(D)), mean_res=float(bb), res_lo=float(np.percentile(b, 2.5)), res_hi=float(np.percentile(b, 97.5))))
R = pd.DataFrame(rows); R.to_csv(f"out/site_resid_{tag}.csv", index=False)
pd.set_option("display.width", 250); print(R.round(3).to_string())
