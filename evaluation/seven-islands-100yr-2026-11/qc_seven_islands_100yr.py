#!/usr/bin/env python3
"""Check all plot trajectories and write aggregate model comparisons."""
import json, math
from pathlib import Path
import pandas as pd
import numpy as np

base=Path(__file__).resolve().parent
p=pd.read_csv(base/'plots.csv')
t=pd.read_csv(base/'trees.csv')
parts=[pd.read_csv(base/'results'/f'{m}.csv') for m in ('fvs_ne','fvs_acd','osm')]
x=pd.concat(parts,ignore_index=True)
x['plot_id']=x.plot_id.astype(int)
x.sort_values(['plot_id','model','year_offset']).to_csv(base/'results'/'plot_model_trajectory.csv',index=False)
expected={}
for pid,g in t.groupby('PLOT_ID'):
    ba=0.; tpa=0.
    for r in g.itertuples():
        d=float(r.DIAMETER)
        if not np.isfinite(d) or d*2.54<1: continue
        n=float(r.TREE_COUNT)*(20/(math.pi*(d/24)**2) if d>=4.6 else 500.)
        tpa+=n; ba+=n*math.pi*(d/24)**2
    expected[int(pid)]=(ba,tpa)
models=sorted(x.model.unique())
q={'plots_input':len(p),'plots_with_live_trees':len(expected),'models':{},
   'input_md5':json.loads((base/'results'/'meta.json').read_text())['input_md5']}
for m in models:
    a=x[x.model==m]
    ct=a.groupby('plot_id').year_offset.agg(['size','nunique','min','max'])
    y0=a[a.year_offset==0].drop_duplicates('plot_id').set_index('plot_id')
    errs=[]; tpa_err=[]
    for pid,(ba,tpa) in expected.items():
        if pid in y0.index:
            errs.append(abs(float(y0.loc[pid,'ba_ft2ac'])-ba)/max(ba,1))
            tpa_err.append(abs(float(y0.loc[pid,'tpa'])-tpa)/max(tpa,1))
    q['models'][m]={'plots':len(ct),'complete_21':int(((ct['size']==21)&(ct['nunique']==21)&(ct['min']==0)&(ct['max']==100)).sum()),
        'missing_eligible':len(set(expected)-set(ct.index)),'duplicate_plot_year':int(a.duplicated(['plot_id','year_offset']).sum()),
        'max_initial_ba_relative_error':max(errs) if errs else None,'max_initial_tpa_relative_error':max(tpa_err) if tpa_err else None,
        'nonfinite_ba':int((~np.isfinite(a.ba_ft2ac)).sum()),'negative_ba':int((a.ba_ft2ac<0).sum()),
        'year100_ba_gt300':int((a[a.year_offset==100].ba_ft2ac>300).sum())}
    v=q['models'][m]
    assert v['plots']==len(expected)==525 and v['complete_21']==525 and v['missing_eligible']==0
    assert v['duplicate_plot_year']==0 and v['nonfinite_ba']==0 and v['negative_ba']==0
    assert v['max_initial_ba_relative_error']<1e-4 and v['max_initial_tpa_relative_error']<1e-4
s=x.groupby(['model','year_offset']).agg(n=('plot_id','nunique'),mean_ba_ft2ac=('ba_ft2ac','mean'),
    median_ba_ft2ac=('ba_ft2ac','median'),mean_tpa=('tpa','mean'),mean_qmd_in=('qmd_in','mean')).reset_index()
z=x.groupby(['model','year_offset']).ba_ft2ac.quantile([.05,.25,.75,.95]).unstack().reset_index()
z=z.rename(columns={.05:'p05_ba_ft2ac',.25:'p25_ba_ft2ac',.75:'p75_ba_ft2ac',.95:'p95_ba_ft2ac'})
s=s.merge(z,on=['model','year_offset']);s.to_csv(base/'results'/'aggregate_trajectory.csv',index=False)
w=x.pivot_table(index=['plot_id','year_offset'],columns='model',values='ba_ft2ac')
dif=[]
for yr,g in w.groupby(level='year_offset'):
    if all(m in g.columns for m in ('FVS-NE','FVS-ACD','OSM')):
        d=g.dropna(subset=['FVS-NE','FVS-ACD','OSM'])
        dif.append(dict(year_offset=int(yr),n=len(d),mean_acd_minus_ne=float((d['FVS-ACD']-d['FVS-NE']).mean()),
            mean_osm_minus_ne=float((d['OSM']-d['FVS-NE']).mean()),
            mean_osm_minus_acd=float((d['OSM']-d['FVS-ACD']).mean())))
pd.DataFrame(dif).to_csv(base/'results'/'aggregate_differences.csv',index=False)
(base/'results'/'qc.json').write_text(json.dumps(q,indent=2))
print(json.dumps(q,indent=2))
