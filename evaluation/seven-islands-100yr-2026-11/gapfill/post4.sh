#!/bin/bash
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd ~/jobs/silc_agmbench_100yr_20261117
for f in logs/silc_*ing0*.log logs/silc_fact*.log logs/silc_*ingT0*.log; do echo "== $f: $(tail -1 $f | cut -c1-120)"; done
cat launch2.log | cut -c1-200
python3 04_collate_bridge.py prod_fix_ing0 ACD-prod-12.5.2-ing0 | head -1
python3 04_collate_bridge.py x142sb_ing0 ACD-14.2-brmsSDImax-ing0 | head -1
python3 04_collate_bridge.py fact_mult_only ACD-mult-only | head -1
python3 04_collate_bridge.py fact_sdib_only ACD-sdib-only | head -1
python3 - <<'PY'
import pandas as pd, json
from pathlib import Path
R=Path.home()/"restricted/silc_agmbench_gapfill_20261117/results"; out={}
for a,b in (("prod_fix_ing1","prod_fix_ing0"),("x142sb_ing1","x142sb_ing0")):
    m=pd.read_csv(R/f"{a}.csv").merge(pd.read_csv(R/f"{b}.csv"),on=["plot_id","year_offset"])
    out[b]=dict(rows=len(m),plots=int(m.plot_id.nunique()),max_abs_ba=float((m.ba_ft2ac_x-m.ba_ft2ac_y).abs().max()),max_abs_tpa=float((m.tpa_x-m.tpa_y).abs().max()))
f={}
for k,r in (("production","prod_fix_ing1"),("multipliers only","fact_mult_only"),("brms SDImax only","fact_sdib_only"),("14.2 (both)","x142sb_ing1")):
    p=R/f"{r}.csv"
    if p.exists() and p.stat().st_size>50: f[k]=pd.read_csv(p)
if "multipliers only" in f and "brms SDImax only" in f:
    ids=set(f["multipliers only"].plot_id)&set(f["brms SDImax only"].plot_id)
    c1=f["multipliers only"].groupby("plot_id").year_offset.nunique(); c2=f["brms SDImax only"].groupby("plot_id").year_offset.nunique()
    ids={i for i in ids if c1[i]==21 and c2[i]==21}; out["factorial_plots"]=len(ids)
    for k,d in f.items():
        d=d[d.plot_id.isin(ids)]; out["fact_"+k]={int(y):[round(float(v),1) for v in g[["ba_ft2ac","tpa","qmd_in","sdi"]].mean()] for y,g in d[d.year_offset.isin([0,50,100])].groupby("year_offset")}
(Path.home()/"jobs/silc_agmbench_100yr_20261117/agg/stress_checks2.json").write_text(json.dumps(out,indent=1)); print(json.dumps(out,indent=1))
PY
~/bin/fbq status | sed -n 1,12p; echo POST4_DONE
