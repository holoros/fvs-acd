#!/usr/bin/env python3
"""FVS-NE (native) and OSM 2.26.1 on the Bakuzis stands x site levels, 100 years, tree lists every 5 years.
Same engines, species rules and defaults as PR 30 (run_seven_islands_100yr.py); pooled stand = all plots of the stand.
FVS-NE: site index = site level (m to ft), site species BF. OSM: BGI at the same empirical quantile of the 525 plots' BGI
(median of 5 nearest lookup points) as the site level's quantile in the 525 plots' climate site index.
usage: 11_bakz_native.py FVS-NE|OSM  -> RESTRICTED/bakz/tl_<model>.csv (tree lists) and _errors.csv"""
import sys, math, sqlite3, subprocess, tempfile, numpy as np, pandas as pd
from pathlib import Path
H = Path.home(); R = H / "restricted/silc_agmbench_gapfill_20261117"; O = R / "bakz"
sys.path.insert(0, str(H / "restricted/seven_islands_100yr_20261117"))
from run_seven_islands_100yr import FVS, OSM, OSM_LIB, HA
model = sys.argv[1]; S = pd.read_csv(O / "stands.csv", dtype={"Stand": str}); T = pd.read_csv(O / "trees.csv")
P = pd.read_csv(R / "plots.csv", dtype={"Stand": str})
KEY = """STDIDENT
{sid}
DATABASE
DSNIN
{db}
DSNOUT
{db}
STANDSQL
SELECT * FROM fvs_standinit WHERE stand_id = '%StandID%'
ENDSQL
TREESQL
SELECT * FROM fvs_treeinit WHERE stand_id = '%StandID%'
ENDSQL
END
TREELIST           0
DATABASE
SUMMARY            2
TREELIDB           2
END
TIMEINT            0         5
NUMCYCLE          20
PROCESS
STOP
"""
rows, errs = [], []
if model == "FVS-NE":
    for s in S.itertuples():
        tt = T[T.k == s.k]; pl = {p: i + 1 for i, p in enumerate(sorted(tt.PLOT_ID.unique()))}
        with tempfile.TemporaryDirectory(prefix="silcbakz_") as d:
            d = Path(d); db = d / "fvsout.db"
            si = pd.DataFrame([dict(stand_id=s.sid, variant="NE", inv_year=int(s.inv_year), region=9, forest=0, district=0,
                basal_area_factor=20.0, inv_plot_size=500, brk_dbh=4.6, num_plots=int(s.n_plots), age=60, aspect=0, slope=5,
                elevft=float(s.elev_m) / 0.3048, site_species=12, site_index=float(s.site) / 0.3048, state=23, county=21,
                forest_type=121, sam_wt=1.0)])
            ti = pd.DataFrame([dict(stand_id=s.sid, plot_id=pl[r.PLOT_ID], tree_id=i + 1, tree_count=1,
                species={"CE": "WC", "WB": "PB"}.get(str(r.SPECIES).strip().upper(), str(r.SPECIES).strip().upper()),
                diameter=float(r.DIAMETER), ht=float(r.HT) if pd.notna(r.HT) and r.HT > 0 else 0.0, crratio=40) for i, r in enumerate(tt.itertuples())])
            with sqlite3.connect(db) as c:
                si.to_sql("fvs_standinit", c, index=False); ti.to_sql("fvs_treeinit", c, index=False)
            (d / "run.key").write_text(KEY.format(sid=s.sid, db=db))
            r = subprocess.run([str(FVS["FVS-NE"]), "--keywordfile=run.key"], cwd=d, capture_output=True, text=True, timeout=900)
            try:
                with sqlite3.connect(db) as c:
                    x = pd.read_sql("select Year, TPA, DBH, Ht, SpeciesFIA from FVS_TreeList", c)
                x = x.assign(sid=s.sid, year=x.Year - int(s.inv_year), spcd=pd.to_numeric(x.SpeciesFIA, errors="coerce").fillna(998).astype(int),
                             dbh_cm=x.DBH * 2.54, ht_m=x.Ht * 0.3048, tph=x.TPA * HA)
                rows.append(x[["sid", "year", "spcd", "dbh_cm", "ht_m", "tph"]])
                if x.year.max() != 100: errs.append(dict(sid=s.sid, reason=f"last year {x.year.max()} rc={r.returncode}"))
            except Exception as e:
                errs.append(dict(sid=s.sid, reason=f"{str(e)[:150]} rc={r.returncode}"))
        print("FVS-NE", s.sid, flush=True)
else:
    sys.path.insert(0, str(OSM_LIB)); import osm_engine as oe
    lk = pd.read_csv(H / "perseus_me/me_state/v23_D/work/eng/osmwork/acd_plt_cn_lookup_with_bgi_csi.csv", usecols=["LAT", "LON", "BGI"])
    lk = lk[pd.to_numeric(lk.BGI, errors="coerce") > 0]; lat, lon, bgi = (np.asarray(lk[c], float) for c in ("LAT", "LON", "BGI"))
    pb = np.array([np.median(bgi[np.argpartition((lat - p.LATITUDE) ** 2 + ((lon - p.LONGITUDE) * math.cos(math.radians(45))) ** 2, 5)[:5]]) for p in P.itertuples()])
    csi = P.ClimateSiteIndexMeters.to_numpy(float)
    BG = {lv: int(round(float(np.quantile(pb, (csi <= lv).mean())))) for lv in sorted(S.site.unique())}
    print("BGI by site level", BG, "plot BGI range", pb.min(), pb.max(), flush=True)
    remap = {"PB": "WB", "TA": "TL", "PC": "PR", "CE": "WC", "HE": "EH"}
    ok = {"AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TL","WA","WB","WC","WP","WS","YB"}
    br = []
    for i, s in enumerate(S.itertuples()):
        tt = T[T.k == s.k]; recs = []
        for r in tt.itertuples():
            sp = str(r.SPECIES).strip().upper(); sp = remap.get(sp, sp); sp = sp if sp in ok else ("OS" if sp == "NC" else "OH")
            recs.append((sp, float(r.DIAMETER) * 2.54, float(r.HT) * 0.3048 if pd.notna(r.HT) and r.HT > 0 else None, float(r.tpa) * HA))
        br.append((i + 1, BG[int(s.site)], recs))
    sidmap = {i + 1: s.sid for i, s in enumerate(S.itertuples())}
    with tempfile.TemporaryDirectory(prefix="silcbakzosm_") as d:
        got, bad, rc = oe.run_osm(str(OSM), d, br, 105, 5, set(range(21)))
    print("OSM rc", rc, "bad rows", bad, "stands", len(got), flush=True)
    osm2fia = {"BF":12,"RS":97,"BS":95,"WS":94,"NS":91,"EH":261,"WC":241,"WP":129,"RN":125,"JP":105,"TL":71,"OS":299,"RM":316,"SM":318,"ST":315,
               "YB":371,"WB":375,"GB":379,"AB":531,"WA":541,"BA":543,"GA":544,"QA":746,"BT":743,"BP":741,"PR":761,"RO":833,"BC":762,"AS":540,"OH":998,
               "HH":701,"EC":742,"RB":372,"SB":373,"SW":95,"HW":998}
    for i, cyc in got.items():
        for c, recs in cyc.items():
            x = pd.DataFrame(recs, columns=["tid", "sp", "dbh_cm", "ht_m", "tph"]); x["spcd"] = x.sp.map(osm2fia).fillna(998).astype(int)
            rows.append(x.assign(sid=sidmap[i], year=c * 5)[["sid", "year", "spcd", "dbh_cm", "ht_m", "tph"]])
        if max(cyc) != 20: errs.append(dict(sid=sidmap[i], reason=f"last cycle {max(cyc)} rc={rc}"))
    for i in sidmap:
        if i not in got: errs.append(dict(sid=sidmap[i], reason=f"no output rc={rc}"))
slug = model.lower().replace("-", "_")
pd.concat(rows).to_csv(O / f"tl_{slug}.csv", index=False); pd.DataFrame(errs, columns=["sid", "reason"]).to_csv(O / f"tl_{slug}_errors.csv", index=False)
print(model, "stands", pd.concat(rows).sid.nunique(), "errors", len(errs))
