#!/bin/bash
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd ~/jobs/silc_agmbench_100yr_20261117
python3 04_collate_bridge.py x143m1l5_ingT0 ACD-143-l5 | head -1
python3 04_collate_bridge.py x143m1l5m2_ingT0 ACD-143-l5m2 | head -1
python3 - <<'PY'
import pandas as pd, numpy as np, json
from pathlib import Path
R=Path.home()/"restricted/silc_agmbench_gapfill_20261117"; RS=R/"results"
SB=pd.read_csv(R/"silc_sdib.csv"); SB["plot_id"]=SB.sid.str[1:].astype(int); smx=SB.set_index("plot_id").sdimax/2.471054
K=pd.read_csv(R/"key_start.csv",dtype={"stand_id":str}).set_index("plot_id"); out={}
for lab,r in (("prod ingrowth","prod_fix_ingT0"),("14.2 ingrowth","x142sb_ingT0"),("14.3 hazard ln5","x143m1l5_ingT0"),("14.3 hazard ln5 + cap","x143m1l5m2_ingT0")):
    D=pd.read_csv(RS/f"{r}.csv"); o={}
    for y in (0,5,25,50,75,100):
        d=D[D.year_offset==y].set_index("plot_id")
        o[y]=dict(ba=round(d.ba_ft2ac.mean(),1),tpa=round(d.tpa.mean(),1),qmd=round(d.qmd_in.mean(),2),sdi=round(d.sdi.mean(),1),mcuft=round(d.mcuft_ac.mean()),pct_over=round(float((d.sdi/smx.loc[d.index]>1).mean()*100),1))
    a=D[D.year_offset==0].set_index("plot_id").ba_ft2ac; z=D[D.year_offset==100].set_index("plot_id").ba_ft2ac
    rng=np.random.default_rng(20261117); st=K.loc[z.index,"stand_id"]; s=z.groupby(st.values).sum(); n=z.groupby(st.values).size(); idx=rng.integers(0,len(s),(2000,len(s)))
    b=s.values[idx].sum(1)/n.values[idx].sum(1)
    o.update(n=int(z.size),pct_lower=round(float((z<a).mean()*100),1),ci=[round(float(x),1) for x in np.percentile(b,[2.5,97.5])]); out[lab]=o
print(json.dumps(out))
PY
