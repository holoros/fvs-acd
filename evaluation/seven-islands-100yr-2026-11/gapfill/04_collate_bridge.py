#!/usr/bin/env python3
"""Collate bridge runs into PR 30's trajectory schema plus top height, SDI and total cubic volume, from FVS_TreeList.
usage: 04_collate_bridge.py RUN LABEL  -> RESTRICTED/results/<RUN>.csv, <RUN>_errors.csv ; prints counts only."""
import sys, glob, sqlite3, numpy as np, pandas as pd
from pathlib import Path
R = Path.home() / "restricted/silc_agmbench_gapfill_20261117"; run, label = sys.argv[1], sys.argv[2]
P = pd.read_csv(R / "key_start.csv", dtype={"stand_id": str}).set_index("plot_id")
rows, errs = [], []
for kf in sorted(glob.glob(str(R / f"batch/{run}/b*/P*.key"))):
    d = Path(kf[:-4]); pid = int(d.name[1:]); done = d / "DONE"
    if not done.exists(): errs.append(dict(plot_id=pid, model=label, reason="not run")); continue
    try:
        c = sqlite3.connect(str(d / "fvsout.db")); t = pd.read_sql("select Year, TPA, DBH, Ht, TCuFt, MCuFt, BdFt from FVS_TreeList", c); c.close()
    except Exception as e:
        errs.append(dict(plot_id=pid, model=label, reason=f"{done.read_text().strip()}; {str(e)[:120]}")); continue
    y0 = int(P.loc[pid, "inv_year"]); got = 0
    for yr, g in t.groupby("Year"):
        off = int(yr) - y0
        if off % 5 or not 0 <= off <= 100: continue
        g = g[(g.DBH > 0) & (g.TPA > 0)]; n = g.TPA.sum(); ba = (g.TPA * 0.005454154 * g.DBH ** 2).sum()
        s = g.sort_values("DBH", ascending=False); cum = s.TPA.cumsum(); w = np.minimum(s.TPA, np.clip(40.47 - (cum - s.TPA), 0, None))
        rows.append(dict(plot_id=pid, stand_id=P.loc[pid, "stand_id"], model=label, year_offset=off, calendar_year=int(yr), ba_ft2ac=ba, tpa=n,
            qmd_in=float(np.sqrt(ba / n / 0.005454154)) if n > 0 else np.nan, mcuft_ac=(g.TPA * g.MCuFt).sum(), bdft_ac=(g.TPA * g.BdFt).sum(),
            tcuft_ac=(g.TPA * g.TCuFt).sum(), sdi=(g.TPA * (g.DBH / 10) ** 1.605).sum(),
            topht_ft=float(np.average(s.Ht, weights=w)) if w.sum() > 0 else np.nan)); got += 1
    exp = 21 if "c100" not in run else 2
    if got != exp: errs.append(dict(plot_id=pid, model=label, reason=f"{got} of {exp} years; {done.read_text().strip()}"))
out = R / "results"; out.mkdir(exist_ok=True)
D = pd.DataFrame(rows); D.to_csv(out / f"{run}.csv", index=False); pd.DataFrame(errs, columns=["plot_id", "model", "reason"]).to_csv(out / f"{run}_errors.csv", index=False)
if len(D):
    z = D[D.year_offset == 0].set_index("plot_id"); k = z.index
    print(run, "plots", D.plot_id.nunique(), "rows", len(D), "errors", len(errs), "max |BA0 - key|", round(float((z.ba_ft2ac - P.loc[k, "ba_ft2ac"]).abs().max()), 3),
          "max |TPA0 - key|", round(float((z.tpa - P.loc[k, "tpa"]).abs().max()), 2))
    print(D.groupby("year_offset")[["ba_ft2ac", "tpa", "qmd_in", "tcuft_ac", "topht_ft"]].mean().round(1).iloc[::4].to_string())
else: print(run, "no rows; errors", len(errs))
