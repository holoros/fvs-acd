#!/usr/bin/env python3
"""Bakuzis trajectories from the bakz runs: one CSV per arm (origin = stand type, site = ESI m, age = 30 + years projected),
with HT = top height (mean height of the 100 largest trees per ha), TPH and BAPH (trees >= 2.54 cm), QMD, VOL (NSVB emulator gross
merchantable volume, trees >= 12.7 cm, m3 ha-1) and SDI (Reineke summation). Also writes the GYDB2 99th and 99.9th percentiles
of plot BA and SDI (trees >= 9.1 cm) for the magnitude check.
usage: bakz_traj.py RUN[,RUN..]"""
import sys, glob, sqlite3, json, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); S = H / "fvsacd142/state"; HA = 2.4710538; FT = 0.3048
sys.argv += [] ; runs = sys.argv[1].split(",")
P = pd.read_csv(S / "restricted/r0e/bakz_pairs.csv", dtype={"pair_id": str}); P["sid"] = "P" + P.pair_id.str[-12:]
k = P.t1_id.str.split("__"); P["origin"] = k.str[1]; P["site"] = k.str[2].str[2:].astype(int); P["h"] = k.str[3].str[1:].astype(int)
co = pd.read_csv(H / "jobs/v142p14/in/ref/nsvb_emulator_coefs.csv").set_index("SPGRPCD")
rs = pd.read_csv(H / "jobs/bakuzis_fvsconus_20261027/repos/fvs-modern/data/NSBE/REF_SPECIES.csv", usecols=["SPCD", "E_SPGRPCD", "SFTWD_HRDWD"])
GRP = dict(zip(rs.SPCD, rs.E_SPGRPCD)); SW = dict(zip(rs.SPCD, rs.SFTWD_HRDWD == "S"))
def vol(sp, d, h):
    g = pd.Series(sp).map(GRP); sw = pd.Series(sp).map(SW).fillna(False); g = g.where(g.isin(co.index), np.where(sw, 6, 32)); c = co.loc[g.to_numpy()]
    return np.exp(c.VOLCFGRS_a.to_numpy() + c.VOLCFGRS_b.to_numpy() * np.log((d / 2.54) ** 2 * (h / FT))) * c.VOLCFGRS_sm.to_numpy() * FT ** 3
def summ(t):
    t = t[t.dbh >= 2.54].sort_values("dbh", ascending=False); cum = t.tph.cumsum(); top = t[cum - t.tph < 100]
    ht = float(np.average(top.ht, weights=np.minimum(top.tph, 100 - (cum[top.index] - top.tph)).clip(lower=1e-9))) if len(top) else np.nan
    ba = float((np.pi / 40000 * t.dbh ** 2 * t.tph).sum()); n = float(t.tph.sum()); m = t.dbh >= 12.7
    return dict(HT=ht, TPH=n, BAPH=ba, QMD=float(np.sqrt(ba / n / (np.pi / 40000))) if n else np.nan,
                VOL=float((vol(t.spcd[m], t.dbh[m], t.ht[m]) * t.tph[m]).sum()), SDI=float((t.tph * (t.dbh / 25.4) ** 1.605).sum()))
for run in runs:
    dirs = {Path(p).name: Path(p) for p in glob.glob(str(S / f"restricted/batch/{run}/*/P*")) if Path(p, "fvsout.db").exists()}
    rows = []
    for r in P.itertuples():
        d = dirs.get(r.sid)
        if d is None: continue
        con = sqlite3.connect(str(d / "fvsout.db")); tl = pd.read_sql("select Year, TPA, DBH, Ht, SpeciesFIA from FVS_TreeList", con); con.close()
        for yr, age in ((tl.Year.max(), 30 + r.h),) + (((tl.Year.min(), 30),) if r.h == 10 else ()):
            t = tl[tl.Year == yr]; t = pd.DataFrame({"spcd": pd.to_numeric(t.SpeciesFIA, errors="coerce").fillna(998).astype(int), "dbh": t.DBH * 2.54, "ht": t.Ht * FT, "tph": t.TPA * HA})
            t = t[t.ht > 0]
            rows.append(dict(origin=r.origin, site=r.site, age=age, **summ(t)))
    D = pd.DataFrame(rows).drop_duplicates(["origin", "site", "age"]).sort_values(["origin", "site", "age"])
    D.to_csv(f"bakz/traj_{run}.csv", index=False); print(run, len(D), flush=True)
c = sqlite3.connect(H / "gydb2/release/all/GYDB2_ALL.sqlite")
s = pd.read_sql("select gvisit, DBH, PTF from trees where Live=1 and DBH>=9.1 and PTF is not null", c)
s = s.assign(ba=np.pi / 40000 * s.DBH ** 2 * s.PTF, sdi=s.PTF * (s.DBH / 25.4) ** 1.605).groupby("gvisit")[["ba", "sdi"]].sum()
q = {v: [round(float(s[v].quantile(p)), 1) for p in (.5, .99, .999)] for v in ("ba", "sdi")}
Path("bakz/obs_quantiles.json").write_text(json.dumps(dict(visits=int(len(s)), p50_p99_p999=q))); print(q)
