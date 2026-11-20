#!/usr/bin/env python3
"""SILC products add-on, step 2: tree lists (years 0, 25, 50, 75, 100) from the bridge runs of the three primary FVS-ACD arms.
Writes RESTRICTED/products/tl_<run>.csv with the same columns as step 1. usage: 20_collect_bridge_tl.py"""
import glob, sqlite3, pandas as pd
from pathlib import Path
R = Path.home() / "restricted/silc_agmbench_gapfill_20261117"; O = R / "products"; O.mkdir(exist_ok=True)
K = pd.read_csv(R / "key_start.csv", dtype={"stand_id": str}).set_index("plot_id"); HA = 2.4710538147; YRS = {0, 25, 50, 75, 100}
for run in ("prod_fix_ing1", "x142sb_ingT0", "x143m1l5m2_ingT0"):
    fr, miss = [], 0
    for f in sorted(glob.glob(str(R / f"batch/{run}/b*/P*/fvsout.db"))):
        pid = int(Path(f).parent.name[1:])
        try:
            c = sqlite3.connect(f); t = pd.read_sql("select Year, SpeciesFVS as Species, SpeciesFIA, DBH, Ht, TPA from FVS_TreeList", c); c.close()
        except Exception: miss += 1; continue
        t["year_offset"] = t.Year - int(K.loc[pid, "inv_year"]); t = t[t.year_offset.isin(YRS) & (t.TPA > 0)]
        fr.append(pd.DataFrame(dict(plot_id=pid, year_offset=t.year_offset, sp=t.Species.str.strip().str.upper(), spcd=pd.to_numeric(t.SpeciesFIA, errors="coerce"),
                                    dbh_cm=t.DBH * 2.54, ht_m=t.Ht * 0.3048, tph=t.TPA * HA)))
    D = pd.concat(fr); D.to_csv(O / f"tl_{run}.csv", index=False)
    print(run, "plots", D.plot_id.nunique(), "rows", len(D), "unreadable", miss, "years", sorted(D.year_offset.unique()))
