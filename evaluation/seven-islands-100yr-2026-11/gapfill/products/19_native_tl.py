#!/usr/bin/env python3
"""SILC products add-on, step 1 (19 Nov 2026): rerun OSM 2.26.1 and FVS-NE on the 525 SILC plots exactly as in PR 30's
run_seven_islands_100yr.py, but keep tree lists (years 0, 25, 50, 75, 100). Writes RESTRICTED/products/tl_osm.csv and tl_fvs_ne.csv
(plot_id, year_offset, sp, dbh_cm, ht_m, tph, spcd) and repro_<model>.csv (plot BA from the tree list against the PR 30 result,
the F15 reproduction check). Tree lists stay in the restricted folder; nothing here leaves the server.
usage: 19_native_tl.py osm|fvs_ne [nworkers]"""
import sys, math, sqlite3, subprocess, tempfile, importlib.util
from pathlib import Path
from multiprocessing import Pool
import numpy as np, pandas as pd
H = Path.home(); S = H / "restricted/seven_islands_100yr_20261117"; O = H / "restricted/silc_agmbench_gapfill_20261117/products"; O.mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location("r30", S / "run_seven_islands_100yr.py"); r30 = importlib.util.module_from_spec(spec); spec.loader.exec_module(r30)
YRS = {0, 25, 50, 75, 100}; HA = r30.HA
KEY2 = r30.KEY.replace("DATABASE\nSUMMARY            2\nEND", "TREELIST           0\nDATABASE\nSUMMARY            2\nTREELIDB           2\nEND")
assert KEY2 != r30.KEY and KEY2.count("TREELIDB") == 1
p = pd.read_csv(S / "plots.csv", dtype={"Stand": str}); t = pd.read_csv(S / "trees.csv", dtype={"STAND_ID": str})
grouped = {int(k): r30.trees_for_plot(v) for k, v in t.groupby("PLOT_ID")}

def fvs_one(row):
    pid = int(row["PLOT_ID"]); trees = grouped.get(pid, [])
    if not trees: return pid, None, "no trees"
    pr = pd.Series(row)
    with tempfile.TemporaryDirectory(prefix="silctl_") as d:
        d = Path(d); db = d / "fvsout.db"; sid = f"P{pid}"
        si = pd.DataFrame([dict(stand_id=sid, variant="NE", inv_year=int(pr.INV_YEAR), latitude=float(pr.LATITUDE), longitude=float(pr.LONGITUDE),
            region=9, forest=0, district=0, basal_area_factor=float(pr.BASAL_AREA_FACTOR), inv_plot_size=500, brk_dbh=float(pr.BRK_DBH), num_plots=1,
            age=60, aspect=0, slope=5, elevft=float(pr.ElevationMeters) / 0.3048, site_species=12, site_index=float(pr.ClimateSiteIndexMeters) / 0.3048,
            state=23, county=21, forest_type=121, sam_wt=1.0)])
        ti = pd.DataFrame([dict(stand_id=sid, plot_id=1, tree_id=x["tree_id"], tree_count=1, species=x["species"], diameter=x["diameter"], ht=x["ht"], crratio=40) for x in trees])
        with sqlite3.connect(db) as c: si.to_sql("fvs_standinit", c, index=False); ti.to_sql("fvs_treeinit", c, index=False)
        (d / "run.key").write_text(KEY2.format(sid=sid, db=db))
        subprocess.run([str(r30.FVS["FVS-NE"]), "--keywordfile=run.key"], cwd=d, capture_output=True, text=True, timeout=600)
        try:
            with sqlite3.connect(db) as c: tl = pd.read_sql_query("select Year, SpeciesFVS as Species, SpeciesFIA, DBH, Ht, TPA from FVS_TreeList", c)
        except Exception as e: return pid, None, str(e)[:120]
    tl["year_offset"] = (tl.Year - tl.Year.min()).round().astype(int); tl = tl[tl.year_offset.isin(YRS) & (tl.TPA > 0)]
    return pid, pd.DataFrame(dict(plot_id=pid, year_offset=tl.year_offset, sp=tl.Species.str.strip().str.upper(), spcd=pd.to_numeric(tl.SpeciesFIA, errors="coerce"),
                                  dbh_cm=tl.DBH * 2.54, ht_m=tl.Ht * 0.3048, tph=tl.TPA * HA)), ""

def osm_batch(b):
    sys.path.insert(0, str(r30.OSM_LIB)); import osm_engine as oe
    with tempfile.TemporaryDirectory(prefix="silcosmtl_") as d:
        got, bad, rc = oe.run_osm(str(r30.OSM), d, [(i + 1, x[1], x[2]) for i, x in enumerate(b)], 105, 5, set(range(21)))
    out = []
    for i, x in enumerate(b):
        cy = got.get(i + 1, {})
        for c, recs in cy.items():
            if c * 5 in YRS: out += [dict(plot_id=x[0], year_offset=c * 5, sp=sp, dbh_cm=D, ht_m=Hh, tph=St) for (_, sp, D, Hh, St) in recs if St > 0]
    return out, bad, rc

def osm_inputs():
    lookup = pd.read_csv(H / "perseus_me/me_state/v23_D/work/eng/osmwork/acd_plt_cn_lookup_with_bgi_csi.csv", usecols=["LAT", "LON", "BGI"])
    lookup = lookup[pd.to_numeric(lookup.BGI, errors="coerce") > 0]; lat, lon, bgi = (np.asarray(lookup[c], float) for c in ("LAT", "LON", "BGI"))
    remap = {"PB": "WB", "TA": "TL", "PC": "PR", "CE": "WC", "HE": "EH"}
    ok = {'AB','AS','BA','BC','BF','BP','BS','BT','EC','EH','GA','GB','HH','HW','JP','NS','OH','OS','PR','QA','RB','RM','RN','RO','RP','RS','SB','SM','ST','SW','TL','WA','WB','WC','WP','WS','YB'}
    bs = []
    for q in p.itertuples():
        trees = grouped.get(int(q.PLOT_ID), [])
        if not trees: continue
        dd = (lat - float(q.LATITUDE)) ** 2 + ((lon - float(q.LONGITUDE)) * math.cos(math.radians(45))) ** 2
        bg = int(round(np.median(bgi[np.argpartition(dd, 5)[:5]])))
        rec = []
        for x in trees:
            sp = remap.get(x["species"], x["species"])
            if sp not in ok: sp = "OS" if x["species"] in {"NC"} else "OH"
            rec.append((sp, x["diameter"] * 2.54, x["ht"] * 0.3048 if x["ht"] > 0 else None, x["tpa"] * HA))
        bs.append((int(q.PLOT_ID), bg, rec))
    return [bs[i:i + 20] for i in range(0, len(bs), 20)]   # same 20-plot batching as PR 30 (OSM batch composition can matter)

if __name__ == "__main__":
    model = sys.argv[1]; nw = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    if model == "fvs_ne":
        with Pool(nw) as pool: res = pool.map(fvs_one, [r._asdict() for r in p.itertuples(index=False)])
        tl = pd.concat([x for _, x, _ in res if x is not None]); err = [(pid, e) for pid, x, e in res if x is None]
        ref = pd.read_csv(S / "results/fvs_ne.csv")
    else:
        with Pool(nw) as pool: res = pool.map(osm_batch, osm_inputs())
        tl = pd.DataFrame([r for x, _, _ in res for r in x]); err = [(None, f"bad={b} rc={rc}") for _, b, rc in res if b or rc]
        ref = pd.read_csv(S / "results/osm.csv")
    tl.to_csv(O / f"tl_{model}.csv", index=False)
    b = tl.assign(ba=np.pi / 40000 * tl.dbh_cm ** 2 * tl.tph * 4.356).groupby(["plot_id", "year_offset"]).ba.sum().rename("ba_tl").reset_index()
    m = b.merge(ref[["plot_id", "year_offset", "ba_ft2ac"]], on=["plot_id", "year_offset"], how="left")
    m["rel"] = (m.ba_tl / m.ba_ft2ac - 1); m.to_csv(O / f"repro_{model}.csv", index=False)
    print(model, "plots", tl.plot_id.nunique(), "rows", len(tl), "errors", len(err), err[:3])
    print("repro |rel| max", round(float(m.rel.abs().max()), 5), "p99", round(float(m.rel.abs().quantile(.99)), 5), "missing", int(m.ba_tl.isna().sum()), int(m.ba_ft2ac.isna().sum()))
