#!/usr/bin/env python3
"""Seven Islands Bakuzis assessment: stand trajectories from tree lists (all arms on one definition), relation tests, scorecard.
Tree-list metrics (trees >= 2.54 cm): HT top height (mean height of the 100 largest stems ha-1), TPH, BAPH (m2 ha-1), QMD (cm),
SDI (Reineke summation, 25.4 cm), VOL (NSVB emulator gross merchantable volume, trees >= 12.7 cm, m3 ha-1; same coefficients
as the regional bakz_traj.py). Writes JOB/bakz_out/: traj_<arm>.csv (stand label, site, year; no identifiers or coordinates),
relations_by_arm.csv, relations_by_stand.csv, checks.json. Usage: 13_bakz_assess.py"""
import glob, json, sqlite3, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); R = H / "restricted/silc_agmbench_gapfill_20261117/bakz"; O = H / "jobs/silc_agmbench_100yr_20261117/bakz_out"; O.mkdir(exist_ok=True)
S = pd.read_csv(R / "stands.csv", dtype={"Stand": str}).set_index("sid"); PL = pd.read_csv(R.parent / "plots.csv", dtype={"Stand": str})
silc_smx = PL.groupby("Stand").SDImaxMetric.first()          # Seven Islands stand SDImax, metric
FT, HA = 0.3048, 2.4710538147
co = pd.read_csv(H / "jobs/v142p14/in/ref/nsvb_emulator_coefs.csv").set_index("SPGRPCD")
rs = pd.read_csv(H / "jobs/bakuzis_fvsconus_20261027/repos/fvs-modern/data/NSBE/REF_SPECIES.csv", usecols=["SPCD", "E_SPGRPCD", "SFTWD_HRDWD"])
GRP = dict(zip(rs.SPCD, rs.E_SPGRPCD)); SW = dict(zip(rs.SPCD, rs.SFTWD_HRDWD == "S"))
def vol(sp, d, h):
    g = pd.Series(sp).map(GRP); sw = pd.Series(sp).map(SW).fillna(False); g = g.where(g.isin(co.index), np.where(sw, 6, 32)); c = co.loc[g.to_numpy()]
    return np.exp(c.VOLCFGRS_a.to_numpy() + c.VOLCFGRS_b.to_numpy() * np.log((d / 2.54) ** 2 * (h / FT))) * c.VOLCFGRS_sm.to_numpy() * FT ** 3
def summ(t):
    t = t[(t.dbh_cm >= 2.54) & (t.tph > 0) & (t.ht_m > 0)].sort_values("dbh_cm", ascending=False)
    n = float(t.tph.sum()); ba = float((np.pi / 40000 * t.dbh_cm ** 2 * t.tph).sum())
    cum = t.tph.cumsum(); w = np.minimum(t.tph, np.clip(100 - (cum - t.tph), 0, None))
    m = t.dbh_cm >= 12.7
    return dict(HT=float(np.average(t.ht_m, weights=w)) if w.sum() > 0 else np.nan, TPH=n, BAPH=ba,
                QMD=float(np.sqrt(ba / n / (np.pi / 40000))) if n > 0 else np.nan, SDI=float((t.tph * (t.dbh_cm / 25.4) ** 1.605).sum()),
                VOL=float((vol(t.spcd[m].to_numpy(), t.dbh_cm[m].to_numpy(), t.ht_m[m].to_numpy()) * t.tph[m].to_numpy()).sum()))
ARMS = {"OSM 2.26.1": "osm", "FVS-NE": "fvs_ne", "ACD 12.5.2 production": "prod", "ACD 14.2 brms SDImax": "x142",
        "ACD 14.3 hazard ln5": "l5", "ACD 14.3 hazard ln5 + cap": "l5m2", "ACD 14.3 hazard L0": "l0", "ACD 14.3 hazard L0 + cap": "l0m2"}
chk = {}; trajs = {}
for arm, slug in ARMS.items():
    rows = []
    if slug in ("osm", "fvs_ne"):
        f = R / f"tl_{slug}.csv"
        if not f.exists(): chk[arm] = "missing"; continue
        T = pd.read_csv(f)
        for (sid, yr), g in T.groupby(["sid", "year"]):
            if yr % 5 == 0 and 0 <= yr <= 100: rows.append(dict(sid=sid, year=int(yr), **summ(g)))
    else:
        dbs = sorted(glob.glob(str(R / f"batch/{slug}/b*/B*/fvsout.db")))
        if not dbs: chk[arm] = "missing"; continue
        for f in dbs:
            sid = Path(f).parent.name
            try: t = pd.read_sql("select Year, TPA, DBH, Ht, SpeciesFIA from FVS_TreeList", sqlite3.connect(f))
            except Exception: continue
            t = pd.DataFrame(dict(year=t.Year - int(S.loc[sid, "inv_year"]), spcd=pd.to_numeric(t.SpeciesFIA, errors="coerce").fillna(998).astype(int),
                                  dbh_cm=t.DBH * 2.54, ht_m=t.Ht * FT, tph=t.TPA * HA))
            for yr, g in t.groupby("year"):
                if yr % 5 == 0 and 0 <= yr <= 100: rows.append(dict(sid=sid, year=int(yr), **summ(g)))
    D = pd.DataFrame(rows).merge(S[["label", "site", "sdimax", "Stand", "ba"]], left_on="sid", right_index=True)
    n = D.groupby("sid").year.nunique(); D = D[D.sid.isin(n.index[n == 21])]
    y0 = D[D.year == 0].set_index("sid"); dba = (y0.BAPH * 4.356 - S.loc[y0.index, "ba"]).abs() / S.loc[y0.index, "ba"]
    chk[arm] = dict(runs_complete=int(len(n[n == 21])), runs_expected=int(len(S)), max_rel_ba0_diff_vs_key=round(float(dba.max()), 4))
    D["rd_brms"] = D.SDI / D.sdimax; D["rd_silc"] = D.SDI / D.Stand.map(silc_smx)
    trajs[arm] = D; D.drop(columns=["sid", "Stand", "ba"]).round(4).to_csv(O / f"traj_{slug}.csv", index=False)
# relation tests -------------------------------------------------------------------------------------------------------
rel, per = [], []
for arm, D in trajs.items():
    st = []
    for lab, g in D.groupby("label"):
        G = {s: x.sort_values("year") for s, x in g.groupby("site")}
        if len(G) != 3: continue
        lo, md, hi = (G[s] for s in sorted(G))
        r = dict(arm=arm, label=lab)
        # monotonicity
        r["ht_monotone"] = all(np.all(np.diff(x.HT.to_numpy()) >= -0.01 * x.HT.to_numpy()[:-1]) for x in G.values())
        r["tph_monotone"] = all(np.all(np.diff(x.TPH.to_numpy()) <= 0.01 * x.TPH.to_numpy()[:-1]) for x in G.values())
        # site ordering of HT and VOL, every 5-year step after year 0 (1% tolerance), and at year 100
        def ordered(v, yrs):
            a, b, c = (x.set_index("year").loc[yrs, v].to_numpy() for x in (lo, md, hi))
            return (b >= a * 0.99) & (c >= b * 0.99)
        yrs = list(range(5, 101, 5))
        oh, ov = ordered("HT", yrs), ordered("VOL", yrs)
        r.update(ht_site_order_all=bool(oh.all()), vol_site_order_all=bool(ov.all()), ht_site_order_100=bool(oh[-1]), vol_site_order_100=bool(ov[-1]),
                 ht_spread_100=float(hi.HT.iloc[-1] - lo.HT.iloc[-1]), vol_spread_100=float(hi.VOL.iloc[-1] - lo.VOL.iloc[-1]))
        # Sukachev: better sites lose stems faster (TPH at year 50 high <= low)
        r["sukachev_50"] = bool(hi.set_index("year").TPH[50] <= lo.set_index("year").TPH[50] * 1.01)
        # Reineke on self-thinning intervals (QMD gain > 0.10 cm per year and stem loss > 1% per step), per trajectory
        sl = []
        for x in G.values():
            q, n = x.QMD.to_numpy(), x.TPH.to_numpy(); iv = (np.diff(q) > 0.5) & (np.diff(n) < -0.01 * n[:-1])
            p = np.r_[False, iv]; p[:-1] |= iv
            sl.append(float(np.polyfit(np.log(q[p]), np.log(n[p]), 1)[0]) if p.sum() >= 3 and np.ptp(np.log(q[p])) > 1e-3 else np.nan)
        r["reineke_slopes"] = sl
        # Eichhorn: CV of VOL across sites at matched HT
        hl, hx = max(x.HT.min() for x in G.values()), min(x.HT.max() for x in G.values())
        if hx > hl:
            grid = np.linspace(hl, hx, 8); cv = [np.std([np.interp(h, x.HT, x.VOL) for x in G.values()], ddof=1) / max(np.mean([np.interp(h, x.HT, x.VOL) for x in G.values()]), 1e-9) for h in grid]
            r["eichhorn_cv"] = float(np.mean(cv))
        else: r["eichhorn_cv"] = np.nan
        r["max_rd_brms"] = float(g.rd_brms.max()); r["max_rd_silc"] = float(g.rd_silc.max())
        r["vol_decline_late"] = any(x.set_index("year").VOL[100] < 0.95 * x.VOL.max() for x in G.values())
        st.append(r)
    P = pd.DataFrame(st); per.append(P.drop(columns=["reineke_slopes"]))
    sl = np.array([v for L in P.reineke_slopes for v in L], float); ev = np.isfinite(sl)
    y100 = D[D.year == 100]
    rel.append(dict(arm=arm, stands=len(P), trajectories=3 * len(P),
        ht_monotone_pct=100 * P.ht_monotone.mean(), tph_monotone_pct=100 * P.tph_monotone.mean(),
        ht_site_order_all_pct=100 * P.ht_site_order_all.mean(), vol_site_order_all_pct=100 * P.vol_site_order_all.mean(),
        vol_site_order_100_pct=100 * P.vol_site_order_100.mean(), mean_ht_spread_100_m=P.ht_spread_100.mean(), mean_vol_spread_100_m3=P.vol_spread_100.mean(),
        sukachev_50_pct=100 * P.sukachev_50.mean(),
        reineke_evaluated=int(ev.sum()), reineke_median_slope=float(np.median(sl[ev])) if ev.any() else np.nan,
        reineke_in_band_pct=100 * float(((sl[ev] > -2.2) & (sl[ev] < -1.2)).mean()) if ev.any() else np.nan,
        eichhorn_cv_median_pct=100 * float(P.eichhorn_cv.median()), eichhorn_pass_pct=100 * float((P.eichhorn_cv < 0.15).mean()),
        stands_rd_brms_gt1_pct=100 * float((P.max_rd_brms > 1).mean()), stands_rd_silc_gt1_pct=100 * float((P.max_rd_silc > 1).mean()),
        vol_late_decline_pct=100 * P.vol_decline_late.mean(),
        **{f"ba100_site{s}": float((y100[y100.site == s].BAPH * 4.356).mean()) for s in sorted(D.site.unique())},
        **{f"vol100_site{s}": float(y100[y100.site == s].VOL.mean()) for s in sorted(D.site.unique())}))
pd.DataFrame(rel).round(2).to_csv(O / "relations_by_arm.csv", index=False); pd.concat(per).round(3).to_csv(O / "relations_by_stand.csv", index=False)
(O / "checks.json").write_text(json.dumps(chk, indent=1)); print(json.dumps(chk, indent=1)); print(pd.DataFrame(rel).round(1).T.to_string())
