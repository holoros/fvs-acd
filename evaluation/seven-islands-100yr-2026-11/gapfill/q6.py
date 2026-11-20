import pandas as pd, json
from pathlib import Path
R=Path.home()/"restricted/silc_agmbench_gapfill_20261117"; RS=R/"results"
SB=pd.read_csv(R/"silc_sdib.csv"); SB["plot_id"]=SB.sid.str[1:].astype(int); smx=(SB.set_index("plot_id").sdimax/2.471054)
K=pd.read_csv(R/"key_start.csv",dtype={"stand_id":str}).set_index("plot_id")
out={}
for lab,r in (("prod no ingrowth","prod_fix_ing1"),("prod ingrowth","prod_fix_ingT0"),("14.2 no ingrowth","x142sb_ing1"),("14.2 ingrowth","x142sb_ingT0")):
    D=pd.read_csv(RS/f"{r}.csv"); o={}
    for y in (0,25,50,75,100):
        d=D[D.year_offset==y].set_index("plot_id")
        o[y]=dict(ba=round(d.ba_ft2ac.mean(),1),tpa=round(d.tpa.mean(),1),qmd=round(d.qmd_in.mean(),2),sdi=round(d.sdi.mean(),1),mcuft=round(d.mcuft_ac.mean(),0),topht=round(d.topht_ft.mean(),1),
                  pct_over_brms=round(float((d.sdi/smx.loc[d.index]>1).mean()*100),1),rd_brms=round(float((d.sdi/smx.loc[d.index]).mean()),3))
    a=D[D.year_offset==0].set_index("plot_id").ba_ft2ac; z=D[D.year_offset==100].set_index("plot_id").ba_ft2ac
    o["pct_plots_ba_lower_100"]=round(float((z<a).mean()*100),1); o["p99_ba100"]=round(float(z.quantile(.99)),1)
    # stand-cluster bootstrap for BA100
    import numpy as np
    rng=np.random.default_rng(20261117); st=K.loc[z.index,"stand_id"]; s=z.groupby(st.values).sum(); n=z.groupby(st.values).size(); idx=rng.integers(0,len(s),(2000,len(s)))
    b=s.values[idx].sum(1)/n.values[idx].sum(1); o["ba100_ci"]=[round(float(x),1) for x in np.percentile(b,[2.5,97.5])]
    out[lab]=o
f={}
for k,r in (("production","prod_fix_ing1"),("multipliers only","fact_mult_only"),("brms SDImax only","fact_sdib_only"),("14.2 both","x142sb_ing1")): f[k]=pd.read_csv(RS/f"{r}.csv")
ids=set(f["multipliers only"].plot_id)&set(f["brms SDImax only"].plot_id); out["factorial_n"]=len(ids)
for k,d in f.items():
    d=d[d.plot_id.isin(ids)&(d.year_offset==100)]; out["fact_"+k]=[round(float(v),1) for v in d[["ba_ft2ac","tpa","qmd_in"]].mean()]
print(json.dumps(out,indent=0))
(Path.home()/"jobs/silc_agmbench_100yr_20261117/agg/ingrowth_rerun_summary.json").write_text(json.dumps(out,indent=1))
