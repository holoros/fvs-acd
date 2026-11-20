#!/usr/bin/env python3
"""Relative density as the model computes it for the M2 cap (production rd.mod: SDI exponent 1.6 over trees >= 10 cm, or all
trees when QMD < 10 cm, against the plot's brms SDImax), from the bridge tree lists. Aggregate output only."""
import glob, sqlite3, json, numpy as np, pandas as pd
from pathlib import Path
R = Path.home() / "restricted/silc_agmbench_gapfill_20261117"; K = pd.read_csv(R / "key_start.csv").set_index("plot_id")
SB = pd.read_csv(R / "silc_sdib.csv"); SB["plot_id"] = SB.sid.str[1:].astype(int); smx = SB.set_index("plot_id").sdimax   # metric
out = {}
for run in ("x143m1l5m2_ingT0", "x143m1l5_ingT0", "x142sb_ingT0"):
    rows = []
    for f in glob.glob(str(R / f"batch/{run}/b*/P*/fvsout.db")):
        pid = int(Path(f).parent.name[1:]); t = pd.read_sql("select Year, TPA, DBH from FVS_TreeList", sqlite3.connect(f))
        t["off"] = t.Year - int(K.loc[pid, "inv_year"]); t = t[t.off.isin([5, 25, 50, 75, 100])]
        for off, g in t.groupby("off"):
            d = g.DBH * 2.54; e = g.TPA * 2.4710538147; qmd = np.sqrt((d ** 2 * e).sum() / e.sum())
            sdi = ((d / 25.4) ** 1.6 * e)[d >= 10].sum() if qmd >= 10 else ((d / 25.4) ** 1.6 * e).sum()
            rows.append(dict(pid=pid, off=int(off), rd=sdi / smx[pid]))
    x = pd.DataFrame(rows)
    out[run] = {int(o): dict(mean_rd=round(float(g.rd.mean()), 3), pct_gt_1_01=round(float((g.rd > 1.01).mean() * 100), 1), max_rd=round(float(g.rd.max()), 3)) for o, g in x.groupby("off")}
print(json.dumps(out, indent=1)); (Path.home() / "jobs/silc_agmbench_100yr_20261117/final/cap_check.json").write_text(json.dumps(out, indent=1))
