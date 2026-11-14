#!/usr/bin/env python3
"""Stand volume, biomass and SDI scorer (2026-11-12, Aaron: "assessments on volume and biomass since it includes height"; "use SDI too").
For each pair of a set and each run: observed stand values at t1 and t2 from the observed tree lists, predicted values at t2 from
the run's tree list (DBH, height and species at the end year). Trees at or above the pair's scoring floor (SCORE_MINDBH).
  BA   m2 ha-1
  SDI  Reineke summation, sum TPH x (DBH / 25.4)^1.605, trees ha-1 at Dq 25.4 cm
  VOL  gross merchantable stem volume (FIA VOLCFGRS definition, trees >= 12.7 cm), m3 ha-1
  BIO  aboveground dry biomass (FIA DRYBIO_AG), Mg ha-1
VOL and BIO from the NSVB emulator fitted on US Forest Service FIA Maine trees (log y ~ log DIA^2 HT by species group, Duan
smearing; coefficients in nsvb_emulator_coefs.csv, R2 0.97 to 0.998), so observed and predicted trees use the same equations.
Observed trees without a measured height get one from a height-diameter model fitted on the measured heights of the same set
(ln(HT - 1.37) = a_group + b_group / (DBH + 1) + jurisdiction shift). Pairs whose observed trees above the floor carry measured
heights at both visits (>= 80% of trees) form the subset "ht_measured", where volume and biomass test height growth directly.
Per block and pooled: ratio of summed predicted to observed net change ((pred t2 - obs t1) / (obs t2 - obs t1)), RMSE of annual
net change, ratio of summed predicted to observed t2 level; 1,000 SITE-cluster bootstrap draws (seed 20261112), paired differences
for every run a 95% interval on each statistic, and for every pair of runs the paired difference with its 95% interval
(RMSE, |ln net ratio|, |ln level ratio|; "better" only when the interval excludes zero). Bootstrap draws resample plots within
each of nine strata, forest type (softwood share of t1 basal area >= 0.65 SW, <= 0.35 HW, otherwise MX) x site tercile (ESI cut
points fixed in strata_cuts.json from all evaluation sets pooled), and statistics are reported for programs, for each stratum and
pooled; pairwise tests and model groups use the overall (pooled) score only. Model groups: runs ranked by each statistic; runs share a letter when no pairwise interval excludes zero (compact letter
display, a = best). Pooled values only.
usage: vol_score.py SET BASE RUN[,RUN..] TAG"""
import sys, glob, json, sqlite3, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); S = H / "fvsacd142/state"; HA = 2.4710538; FT = 0.3048
st, base, cands, tag = sys.argv[1], sys.argv[2], sys.argv[3].split(","), sys.argv[4]; runs = [base] + cands
P = pd.read_csv(S / (f"restricted/t14/{st}_pairs.csv" if st == "g2" else f"restricted/r0e/{st}_pairs.csv"), dtype={"pair_id": str, "t1_id": str})
P["sid"] = "P" + P.pair_id.str.strip().str[-12:]; P["fl"] = P.SCORE_MINDBH.astype(float)
rs = pd.read_csv(H / "jobs/bakuzis_fvsconus_20261027/repos/fvs-modern/data/NSBE/REF_SPECIES.csv", usecols=["SPCD", "SPECIES_SYMBOL", "E_SPGRPCD", "SFTWD_HRDWD"])
GRP = dict(zip(rs.SPCD, rs.E_SPGRPCD)); SW = dict(zip(rs.SPCD, rs.SFTWD_HRDWD == "S")); SYM = dict(zip(rs.SPECIES_SYMBOL, rs.SPCD))
SYM.update({"ACER": 310, "PICEA": 90, "LARIX": 70, "POPUL": 740, "QUERC": 800, "ULMUS": 970, "SALIX": 920, "ALNUS": 350, "MALUS": 660, "AMELA": 356, "T_X": 998})
sys.path.insert(0, str(H / "perseus_me/tracks/v25_Q/engines/acd141")); import acd_engine as AE
ALPHA = dict(AE.AGY); ALPHA.update({"OS": 299, "OH": 998, "RP": 125})
co = pd.read_csv(H / "jobs/v142p14/in/ref/nsvb_emulator_coefs.csv").set_index("SPGRPCD")
def grp(spcd):
    g = pd.Series(spcd).map(GRP); sw = pd.Series(spcd).map(SW).fillna(False)
    g = g.where(g.isin(co.index), np.where(sw, 6, 32)); return g.to_numpy()
def nsvb(spcd, dbh_cm, ht_m, resp):
    g = grp(spcd); c = co.loc[g]; X = np.log((dbh_cm / 2.54) ** 2 * (ht_m / FT))
    return np.exp(c[f"{resp}_a"].to_numpy() + c[f"{resp}_b"].to_numpy() * X) * c[f"{resp}_sm"].to_numpy()
# ---- observed tree lists (t1, t2) per pair_id
def obs_trees():
    if st in ("gy2", "gy2L"):
        c = sqlite3.connect(H / "gydb2/release/all/GYDB2_ALL.sqlite")
        k = P.t1_id.str.split("__"); P["gplot"] = k.str[0]; yy = k.str[1].str.split("_"); P["Y1"] = yy.str[0].astype(int); P["Y2"] = yy.str[1].astype(int)
        v = pd.read_sql("select gplot, gvisit, YR from visits", c); v = v[v.gplot.isin(set(P.gplot))].drop_duplicates(["gplot", "YR"])
        t = pd.read_sql(f"select gvisit, SpeciesCD, DBH, HT, PTF from trees where Live=1 and DBH is not null and gvisit in ({','.join('?' * len(v))})", c, params=list(v.gvisit))
        t = t.merge(v, on="gvisit"); out = []
        for w, y in (("1", "Y1"), ("2", "Y2")):
            m = t.merge(P[["pair_id", "gplot", y, "JURIS"]].rename(columns={y: "YR"}), on=["gplot", "YR"])
            out.append(pd.DataFrame({"pair_id": m.pair_id, "t": w, "spcd": m.SpeciesCD.map(SYM), "dbh": m.DBH, "ht": m.HT, "tph": m.PTF, "juris": m.JURIS}))
        return pd.concat(out, ignore_index=True)
    if st == "g2":
        idm = pd.read_csv(S / "restricted/t14/g2_idmap.csv", dtype=str); stand = dict(zip(idm.pair_id, idm.STAND)); fr = H / "gydb2/release/_prev_20261112/frames_PREV_20261112"
        fr = fr if fr.exists() else H / "gydb2/release/frames"
        pref = sorted({stand[p].split(":")[0].lower() for p in P.pair_id})
    else:
        stand = dict(zip(P.pair_id, P.t1_id)); fr = H / "perseus_me/me_state/acd142/restricted/regional/frames"; pref = sorted(P.SET.unique())
    inv = {v: k for k, v in stand.items()}; out = []
    for f in sorted(glob.glob(str(fr / "bench_gyr_*_tree_init.csv*"))):
        nm = Path(f).name.replace("bench_gyr_", "").split("_tree_init")[0]
        if nm not in pref: continue
        for w, fn in (("1", f), ("2", f.replace("tree_init", "tree_t2"))):
            d = pd.read_csv(fn, dtype={"STAND": str}); d = d[d.STAND.isin(inv)]
            out.append(pd.DataFrame({"pair_id": d.STAND.map(inv), "t": w, "spcd": d.SP.astype(str).map(ALPHA), "dbh": d.DBH, "ht": d.HT, "tph": d.EXPF}))
    o = pd.concat(out, ignore_index=True); o["juris"] = o.pair_id.map(dict(zip(P.pair_id, P.JURIS))); return o
O = obs_trees(); O = O[O.dbh.notna() & (O.dbh > 0) & O.tph.notna()]; O["spcd"] = O.spcd.fillna(998).astype(int)
O["fl"] = O.pair_id.map(dict(zip(P.pair_id, P.fl))); O = O[O.dbh >= O.fl]
# ---- height-diameter model on measured heights of this set
O["g"] = grp(O.spcd); m = O.ht.notna() & (O.ht > 1.5)
gs = sorted(O.g.unique()); js = sorted(O.juris.dropna().unique())
def design(d):
    X = [np.ones(len(d))] + [(d.g == g).to_numpy(float) for g in gs[1:]] + [1 / (d.dbh.to_numpy() + 1) * (d.g == g).to_numpy(float) for g in gs] + [(d.juris == j).to_numpy(float) for j in js[1:]]
    return np.column_stack(X)
b = np.linalg.lstsq(design(O[m]), np.log(O.ht[m] - 1.37), rcond=None)[0]; res = np.log(O.ht[m] - 1.37) - design(O[m]) @ b
O["ht_imp"] = 1.37 + np.exp(design(O) @ b) * np.mean(np.exp(res)); O["meas"] = m; O["h"] = np.where(m, O.ht, O.ht_imp)
OUT = dict(set=st, runs=runs, hd_model=dict(n=int(m.sum()), rmse_log=round(float(res.std()), 4), share_measured=round(float(m.mean()), 3)))
def stand(d, h):
    vol = np.where(d.dbh >= 12.7, nsvb(d.spcd, d.dbh, h, "VOLCFGRS") * FT ** 3, 0.0); bio = nsvb(d.spcd, d.dbh, h, "DRYBIO_AG") * 0.45359237 / 1000
    x = pd.DataFrame({"pair_id": d.pair_id, "BA": np.pi / 40000 * d.dbh ** 2 * d.tph, "SDI": d.tph * (d.dbh / 25.4) ** 1.605, "VOL": vol * d.tph, "BIO": bio * d.tph})
    return x.groupby("pair_id").sum()
o1 = stand(O[O.t == "1"], O.h[O.t == "1"]); o2 = stand(O[O.t == "2"], O.h[O.t == "2"]).reindex(o1.index).fillna(0.0)
hm = O.groupby("pair_id").meas.mean()
t1 = O[O.t == "1"].assign(ba=lambda x: np.pi / 40000 * x.dbh ** 2 * x.tph, sw=lambda x: x.spcd.map(SW).fillna(False))
sws = t1[t1.sw].groupby("pair_id").ba.sum().reindex(o1.index).fillna(0) / o1.BA.replace(0, np.nan)
FT_ = pd.Series(np.where(sws >= 0.65, "SW", np.where(sws <= 0.35, "HW", "MX")), index=o1.index)
CUT = json.loads((Path(__file__).with_name("strata_cuts.json")).read_text())["esi_m"]   # fixed tercile cut points, all evaluation sets pooled
esi = (P.set_index("pair_id").SICOND_FVS / 3.2808399).reindex(o1.index)
SC_ = pd.Series(np.where(esi < CUT[0], "low", np.where(esi < CUT[1], "mid", "high")), index=o1.index)
def pred(run):
    dirs = {Path(p).name: Path(p) for p in glob.glob(str(S / f"restricted/batch/{run}/*/P*")) if Path(p, "fvsout.db").exists()}
    rows = []; ran = set()
    for r in P.itertuples():
        d = dirs.get(r.sid)
        if d is None: continue
        ran.add(r.pair_id)
        con = sqlite3.connect(str(d / "fvsout.db")); cols = [x[1] for x in con.execute("pragma table_info(FVS_TreeList)")]
        q = "select Year, TPA, DBH" + (", Ht, SpeciesFIA" if "Ht" in cols else ", NULL as Ht, 998 as SpeciesFIA") + " from FVS_TreeList"
        tl = pd.read_sql(q, con); con.close()
        tl = tl[tl.Year == tl.Year.max()]; tl = tl[tl.DBH * 2.54 >= r.fl]
        rows.append(pd.DataFrame({"pair_id": r.pair_id, "spcd": pd.to_numeric(tl.SpeciesFIA, errors="coerce").fillna(998).astype(int), "dbh": tl.DBH * 2.54, "ht": tl.Ht * FT, "tph": tl.TPA * HA}))
    d = pd.concat(rows, ignore_index=True); noht = d.ht.isna().all(); d = d[d.ht.isna() | (d.ht > 1.37)]
    x = stand(d, d.ht.fillna(10.0)).reindex(P.pair_id)
    x.loc[x.index.isin(ran)] = x.loc[x.index.isin(ran)].fillna(0.0)   # run but no tree above the floor: 0; never run: stays NaN
    if noht: x[["VOL", "BIO"]] = np.nan
    return x
PR = {}
for k in runs:
    PR[k] = pred(k)
runs = [k for k in runs if k in PR]
D = P.set_index("pair_id").loc[o1.index].copy(); D["hm"] = hm.reindex(D.index); D["cell"] = FT_ + "-" + SC_
OUT["cells"] = D.cell.value_counts().to_dict(); OUT["esi_cuts_m"] = CUT
ok = np.ones(len(D), bool)
for k in runs: ok &= PR[k].reindex(D.index)[["BA", "SDI"]].notna().all(1).to_numpy()
D = D[ok]; D = D.sort_index(); rng = np.random.default_rng(20261112); rows = []; prow = []
for sub in ("all", "ht_measured"):
    Ds = D if sub == "all" else D[D.hm >= 0.8]
    for blk in sorted(Ds.block.dropna().unique()) + ["CELL:" + c for c in sorted(Ds.cell.unique())] + ["ALL"]:
        d = Ds if blk == "ALL" else (Ds[Ds.cell == blk[5:]] if blk.startswith("CELL:") else Ds[Ds.block == blk])
        if len(d) < 5: continue
        W = np.zeros((1000, len(d)))
        for c in d.cell.unique():                       # stratified cluster bootstrap: plots resampled within each 3 x 3 cell
            ix = np.where(d.cell.to_numpy() == c)[0]; u, inv = np.unique(d.SITE.astype(str).to_numpy()[ix], return_inverse=True)
            for b_ in range(1000): W[b_, ix] = np.bincount(rng.integers(0, len(u), len(u)), minlength=len(u))[inv]
        for v in ("BA", "SDI", "VOL", "BIO"):
            y1 = o1.loc[d.index, v].to_numpy(); y2 = o2.loc[d.index, v].to_numpy(); dt = d.REMPER.to_numpy(float); bs = {}
            rk = [k for k in runs if not np.isnan(PR[k].loc[d.index, v].to_numpy()).any()]
            for k in rk:
                p2 = PR[k].loc[d.index, v].to_numpy(); e = (p2 - y2) / dt
                bs[k] = dict(rmse=np.sqrt(W @ e ** 2 / W.sum(1)), net=(W @ (p2 - y1)) / (W @ (y2 - y1)), lvl=(W @ p2) / (W @ y2))
                row = dict(subset=sub, block=blk, var=v, run=k, n=int(len(d)), obs_t2_mean=float(y2.mean()), net_ratio=float((p2 - y1).sum() / (y2 - y1).sum()),
                           rmse_annual=float(np.sqrt(np.mean(e ** 2))), level_ratio=float(p2.sum() / y2.sum()))
                for m_, nm in (("rmse", "rmse_annual"), ("net", "net_ratio"), ("lvl", "level_ratio")):
                    row[f"{nm}_lo"] = float(np.percentile(bs[k][m_], 2.5)); row[f"{nm}_hi"] = float(np.percentile(bs[k][m_], 97.5))
                rows.append(row)
            for i, a in enumerate(rk if blk == "ALL" else []):            # every pair of runs on the overall score: b minus a, same draws
                for b_ in rk[i + 1:]:
                    for m_ in ("rmse", "net", "lvl"):
                        f = (lambda x: x) if m_ == "rmse" else (lambda x: np.abs(np.log(np.abs(x))))
                        df = f(bs[b_][m_]) - f(bs[a][m_]); lo, hi = np.percentile(df, [2.5, 97.5])
                        prow.append(dict(subset=sub, block=blk, var=v, run_a=a, run_b=b_, metric={"rmse": "rmse_annual", "net": "abs_ln_net_ratio", "lvl": "abs_ln_level_ratio"}[m_],
                                         diff_b_minus_a=float(np.median(df)), lo=float(lo), hi=float(hi),
                                         verdict="b better" if hi < 0 else ("a better" if lo > 0 else "no clear difference")))
def cld(order, same):
    # ordered compact letter display: each letter is a maximal run of consecutive (ranked) models with no clear pairwise difference
    spans = []
    for i in range(len(order)):
        j = i
        while j + 1 < len(order) and all(same(order[k], order[j + 1]) for k in range(i, j + 1)): j += 1
        if not spans or j > spans[-1][1]: spans.append((i, j))
    lab = {r: "" for r in order}
    for L, (i, j) in enumerate(spans):
        for k in range(i, j + 1): lab[order[k]] += "abcdefghijklmnop"[L]
    return lab
PW = pd.DataFrame(prow); grows = []
if len(PW):
    for (sub, blk, v, met), g in PW.groupby(["subset", "block", "var", "metric"]):
        Rg = pd.DataFrame([r for r in rows if r["subset"] == sub and r["block"] == blk and r["var"] == v])
        col = {"rmse_annual": "rmse_annual", "abs_ln_net_ratio": "net_ratio", "abs_ln_level_ratio": "level_ratio"}[met]
        sc = Rg.set_index("run")[col]; sc = sc if met == "rmse_annual" else np.abs(np.log(np.abs(sc)))
        order = list(sc.sort_values().index); nd = {(a, b) for a, b, vv in zip(g.run_a, g.run_b, g.verdict) if vv == "no clear difference"}
        lab = cld(order, lambda a, b: a == b or (a, b) in nd or (b, a) in nd)
        for r in order: grows.append(dict(subset=sub, block=blk, var=v, metric=met, run=r, score=float(sc[r]), group=lab[r], n=int(Rg.n.iloc[0])))
pd.DataFrame(grows).to_csv(f"{Path(__file__).parent}/out/vol_{tag}_groups.csv", index=False)
R = pd.DataFrame(rows); R.to_csv(f"{Path(__file__).parent}/out/vol_{tag}.csv", index=False); pd.DataFrame(prow).to_csv(f"{Path(__file__).parent}/out/vol_{tag}_pairwise.csv", index=False); OUT["pairs_scored"] = int(len(D)); OUT["ht_measured_pairs"] = int((D.hm >= 0.8).sum())
Path(f"{Path(__file__).parent}/out/vol_{tag}.json").write_text(json.dumps(OUT, indent=1)); pd.set_option("display.width", 250); print(json.dumps(OUT))
print(R[R.block == "ALL"][["subset", "var", "run", "n", "net_ratio", "net_ratio_lo", "net_ratio_hi", "rmse_annual", "rmse_annual_lo", "rmse_annual_hi", "level_ratio"]].round(3).to_string())
