#!/usr/bin/env python3
"""Stratified stand-cluster uncertainty and model behavior checks; run on firebreather."""
import json
from pathlib import Path
import numpy as np
import pandas as pd

B=Path(__file__).resolve().parent
R=B/'results'
plots=pd.read_csv(B/'plots.csv',dtype={'Stand':str})[['PLOT_ID','Stand','Matrix','Unit']]
paths=[R/'fvs_ne.csv',R/'fvs_acd.csv',R/'osm.csv']+[f for f in sorted(R.glob('acd_v*.csv')) if '_errors' not in f.name and '_part' not in f.name and '.smoke' not in f.name]
x=pd.concat([pd.read_csv(f,dtype={'stand_id':str}) for f in paths],ignore_index=True)
x=x.merge(plots,left_on='plot_id',right_on='PLOT_ID',validate='many_to_one')
assert x.duplicated(['plot_id','model','year_offset']).sum()==0
assert x.groupby(['plot_id','model']).year_offset.nunique().eq(21).all()
YEARS=(0,25,50,75,100)
NBOOT=2000
rng=np.random.default_rng(20261117)

def cluster_ci(d, value='ba_ft2ac', strata=False):
    """Bootstrap stands, keeping all their plots together; optional Matrix stratification."""
    groups=[]
    if strata:
        for _,g in d.groupby('Matrix'):
            groups.append(g.groupby('Stand')[value].agg(['sum','count']).to_numpy(float))
    else:
        groups=[d.groupby('Stand')[value].agg(['sum','count']).to_numpy(float)]
    sums=np.zeros(NBOOT); counts=np.zeros(NBOOT)
    for group in groups:
        idx=rng.integers(0,len(group),size=(NBOOT,len(group)))
        sums+=group[idx,0].sum(axis=1)
        counts+=group[idx,1].sum(axis=1)
    vals=sums/counts
    return np.quantile(vals,[.025,.975])

summary=[]
for (stratum,model,year),g in x[x.year_offset.isin(YEARS)].groupby(['Matrix','model','year_offset']):
    ci=cluster_ci(g) if g.Stand.nunique()>=5 else (np.nan,np.nan)
    summary.append(dict(stratum=stratum,model=model,year_offset=int(year),n_plots=g.plot_id.nunique(),n_stands=g.Stand.nunique(),
        mean_ba_ft2ac=g.ba_ft2ac.mean(),median_ba_ft2ac=g.ba_ft2ac.median(),
        p05_ba_ft2ac=g.ba_ft2ac.quantile(.05),p95_ba_ft2ac=g.ba_ft2ac.quantile(.95),
        ci_low_mean_ba=ci[0],ci_high_mean_ba=ci[1],mean_tpa=g.tpa.mean(),mean_qmd_in=g.qmd_in.mean()))
pd.DataFrame(summary).to_csv(R/'strata_uncertainty.csv',index=False)

overall=[]
for (model,year),g in x[x.year_offset.isin(YEARS)].groupby(['model','year_offset']):
    ci=cluster_ci(g,strata=True)
    sw=g.groupby('Stand').ba_ft2ac.mean()
    overall.append(dict(model=model,year_offset=int(year),n_plots=g.plot_id.nunique(),n_stands=g.Stand.nunique(),
        mean_ba_ft2ac=g.ba_ft2ac.mean(),ci_low_mean_ba=ci[0],ci_high_mean_ba=ci[1],
        stand_weighted_mean_ba=sw.mean(),median_ba_ft2ac=g.ba_ft2ac.median(),
        p05_ba_ft2ac=g.ba_ft2ac.quantile(.05),p95_ba_ft2ac=g.ba_ft2ac.quantile(.95),
        mean_tpa=g.tpa.mean(),mean_qmd_in=g.qmd_in.mean()))
pd.DataFrame(overall).to_csv(R/'overall_uncertainty.csv',index=False)

# Common one-plot-per-stand panel for every displayed model arm.
sample=set(pd.read_csv(B/'version_sample_plots.csv').PLOT_ID.astype(int))
matched=[]
for (model,year),g in x[x.plot_id.isin(sample)&x.year_offset.isin(YEARS)].groupby(['model','year_offset']):
    ci=cluster_ci(g,strata=True)
    matched.append(dict(model=model,year_offset=int(year),n_plots=g.plot_id.nunique(),n_stands=g.Stand.nunique(),
        mean_ba_ft2ac=g.ba_ft2ac.mean(),ci_low_mean_ba=ci[0],ci_high_mean_ba=ci[1],
        mean_tpa=g.tpa.mean(),mean_qmd_in=g.qmd_in.mean()))
pd.DataFrame(matched).to_csv(R/'matched_overall_uncertainty.csv',index=False)

matched_strata=[]
for (stratum,model,year),g in x[x.plot_id.isin(sample)&x.year_offset.isin(YEARS)].groupby(['Matrix','model','year_offset']):
    ci=cluster_ci(g) if g.Stand.nunique()>=5 else (np.nan,np.nan)
    matched_strata.append(dict(stratum=stratum,model=model,year_offset=int(year),n_plots=g.plot_id.nunique(),n_stands=g.Stand.nunique(),
        mean_ba_ft2ac=g.ba_ft2ac.mean(),ci_low_mean_ba=ci[0],ci_high_mean_ba=ci[1]))
pd.DataFrame(matched_strata).to_csv(R/'matched_strata_uncertainty.csv',index=False)

base=x[x.year_offset==100][['plot_id','Stand','Matrix','model','ba_ft2ac']]
w=base.pivot_table(index=['plot_id','Stand','Matrix'],columns='model',values='ba_ft2ac').reset_index()
diffs=[]
models=[m for m in w.columns if m not in ('plot_id','Stand','Matrix')]
version_pairs=[('ACD-v14.1-L2L','ACD-v14.0.4-L2'),('ACD-v14.1-L2L','ACD-v13.1-base'),
               ('ACD-v13.1-base','ACD-v12.11.1')]
for a,b in [('FVS-ACD','FVS-NE'),('OSM','FVS-NE')]+[(m,'FVS-ACD') for m in models if m.startswith('ACD-')]+version_pairs:
    if a not in w or b not in w:continue
    d=w[['Stand','Matrix',a,b]].dropna().copy();d['difference']=d[a]-d[b]
    for strata,g in [('ALL',d)]+list(d.groupby('Matrix')):
        ci=cluster_ci(g,value='difference',strata=(strata=='ALL')) if g.Stand.nunique()>=5 else (np.nan,np.nan)
        diffs.append(dict(stratum=strata,model_a=a,model_b=b,n_plots=len(g),n_stands=g.Stand.nunique(),
            mean_difference_ft2ac=g.difference.mean(),ci_low=ci[0],ci_high=ci[1]))
pd.DataFrame(diffs).to_csv(R/'year100_paired_differences.csv',index=False)

flags=[]
for model,g in x.groupby('model'):
    wide=g.pivot(index='plot_id',columns='year_offset',values='ba_ft2ac').sort_index(axis=1)
    tpa=g.pivot(index='plot_id',columns='year_offset',values='tpa').sort_index(axis=1)
    qmd=g.pivot(index='plot_id',columns='year_offset',values='qmd_in').sort_index(axis=1)
    y100=wide[100]; peak=wide.max(axis=1)
    flags.append(dict(model=model,n_plots=len(wide),year100_ba_gt300=int((y100>300).sum()),year100_ba_gt400=int((y100>400).sum()),
        any_5yr_ba_decline=int((wide.diff(axis=1).iloc[:,1:]<0).any(axis=1).sum()),
        year100_ba_25pct_below_peak=int((y100<.75*peak).sum()),
        any_5yr_tpa_gain=int((tpa.diff(axis=1).iloc[:,1:]>0).any(axis=1).sum()),
        any_5yr_qmd_decline=int((qmd.diff(axis=1).iloc[:,1:]<0).any(axis=1).sum())))
pd.DataFrame(flags).to_csv(R/'stress_flags.csv',index=False)
tail=x[x.year_offset==100].groupby(['Matrix','model']).agg(
    n_plots=('plot_id','nunique'),n_stands=('Stand','nunique'),
    ba_gt300=('ba_ft2ac',lambda s:int((s>300).sum())),
    ba_gt400=('ba_ft2ac',lambda s:int((s>400).sum()))).reset_index()
tail.to_csv(R/'strata_tail_flags.csv',index=False)
print(json.dumps(dict(models=models,plots=len(w),strata=x.Matrix.nunique(),stands=x.Stand.nunique(),boot=NBOOT)))
