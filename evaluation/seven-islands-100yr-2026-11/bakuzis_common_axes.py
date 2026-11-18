#!/usr/bin/env python3
"""Step-aware Bakuzis diagnostics on every projection using shared BA, TPA, QMD axes.

Run on the restricted server. Export aggregate files only.
"""
from pathlib import Path
import json
import numpy as np
import pandas as pd

B=Path(__file__).resolve().parent;R=B/'results'
sample=set(pd.read_csv(B/'version_sample_plots.csv').PLOT_ID.astype(int))
plots=pd.read_csv(B/'plots.csv')[['PLOT_ID','Stand','Matrix','ClimateSiteIndexMeters']]
paths=[R/f for f in ('fvs_ne.csv','fvs_acd.csv','osm.csv','acd_v12_11_1.csv','acd_v13_1_base.csv','acd_v14_0_4_L2.csv','acd_v14_1_L2L.csv')]
x=pd.concat([pd.read_csv(f) for f in paths],ignore_index=True)
x=x.merge(plots,left_on='plot_id',right_on='PLOT_ID',validate='many_to_one')
assert x.groupby(['plot_id','model']).year_offset.nunique().eq(21).all()
assert x.year_offset.isin(range(0,101,5)).all()
assert (x.tpa>0).all() and (x.qmd_in>0).all()
x['sdi']=x.tpa*(x.qmd_in/10.)**1.605
baseline=x[(x.model=='FVS-NE')&(x.year_offset==0)]
ba99=float(baseline.ba_ft2ac.quantile(.99));ba999=float(baseline.ba_ft2ac.quantile(.999))
sdi99=float(baseline.sdi.quantile(.99));sdi999=float(baseline.sdi.quantile(.999))

rows=[]
for (pid,model),g in x.groupby(['plot_id','model']):
    g=g.sort_values('year_offset');t=g.tpa.to_numpy(float);q=g.qmd_in.to_numpy(float)*2.54
    ba=g.ba_ft2ac.to_numpy(float);sdi=g.sdi.to_numpy(float)
    step=np.diff(g.year_offset.to_numpy(float));assert np.all(step==5)
    # 0.10 cm per year is the step-aware screen from the corrected skill script.
    intervals=(np.diff(q)>0.10*step)&(np.diff(t)<-0.01*t[:-1])
    points=np.r_[False,intervals]
    # Keep the starting point of the first selected thinning interval too.
    points[:-1] |= intervals
    enough=points.sum()>=3 and np.std(np.log(q[points]))>1e-3
    slope=float(np.polyfit(np.log(q[points]),np.log(t[points]),1)[0]) if enough else np.nan
    rows.append(dict(plot_id=pid,model=model,Stand=g.Stand.iloc[0],Matrix=g.Matrix.iloc[0],
        n_intervals=int(intervals.sum()),reineke_evaluated=bool(enough),reineke_slope=slope,
        reineke_flag=bool(enough and not (-2.2<slope<-1.2)),
        tpa_gain_1pct=bool((np.diff(t)>.01*t[:-1]).any()),
        ba_decline_1pct=bool((np.diff(ba)<-.01*ba[:-1]).any()),
        ba_25pct_below_peak=bool(ba[-1]<.75*ba.max()),
        ba_gt_observed_p999=bool(ba[-1]>ba999),
        sdi_gt_observed_p999=bool(sdi[-1]>sdi999),
        ba_gt300=bool(ba[-1]>300),
        year100_ba=float(ba[-1]),year100_sdi=float(sdi[-1])))
d=pd.DataFrame(rows)

def summarize(g):
    n=len(g);ev=g.reineke_evaluated.sum()
    return pd.Series(dict(n_plots=n,n_stands=g.Stand.nunique(),reineke_evaluated=int(ev),
        reineke_not_evaluated=int(n-ev),reineke_flagged=int(g.reineke_flag.sum()),
        median_reineke_slope=float(g.reineke_slope.median()) if ev else np.nan,
        tpa_gain_1pct=int(g.tpa_gain_1pct.sum()),ba_decline_1pct=int(g.ba_decline_1pct.sum()),
        ba_25pct_below_peak=int(g.ba_25pct_below_peak.sum()),
        ba_gt_observed_p999=int(g.ba_gt_observed_p999.sum()),
        sdi_gt_observed_p999=int(g.sdi_gt_observed_p999.sum()),ba_gt300=int(g.ba_gt300.sum()),
        mean_year100_sdi=float(g.year100_sdi.mean())))

summary=[]
for scope,sub in [('matched',d[d.plot_id.isin(sample)]),('all_available',d)]:
    for model,g in sub.groupby('model'):
        r=summarize(g).to_dict();r.update(scope=scope,model=model);summary.append(r)
pd.DataFrame(summary).to_csv(R/'bakuzis_common_axes.csv',index=False)
strata=[]
for (matrix,model),g in d[d.plot_id.isin(sample)].groupby(['Matrix','model']):
    r=summarize(g).to_dict();r.update(stratum=matrix,model=model);strata.append(r)
pd.DataFrame(strata).to_csv(R/'bakuzis_common_axes_strata.csv',index=False)

traj=x[x.plot_id.isin(sample)].groupby(['model','year_offset']).agg(
    n_plots=('plot_id','nunique'),mean_ba=('ba_ft2ac','mean'),mean_tpa=('tpa','mean'),
    mean_qmd_in=('qmd_in','mean'),mean_sdi=('sdi','mean')).reset_index()
traj.to_csv(R/'bakuzis_matched_trajectory.csv',index=False)
(R/'bakuzis_thresholds.json').write_text(json.dumps(dict(
    projection_step_years=5,qmd_rate_cm_per_year=.10,reineke_target=-1.605,
    reineke_acceptance=[-2.2,-1.2],observed_baseline_n=len(baseline),
    baseline_ba_p99=ba99,baseline_ba_p999=ba999,
    baseline_sdi_p99=sdi99,baseline_sdi_p999=sdi999,
    unavailable_axes=['height','volume','Eichhorn','height_site_ordering','volume_site_ordering'],
    note='Thresholds are descriptive screens from the observed starting distribution, not biological maxima.'),indent=2))
print(pd.DataFrame(summary).query("scope=='matched'").to_string(index=False))
