#!/usr/bin/env python3
"""Aggregate-only Bakuzis diagnostics from restricted Seven Islands reruns."""
from pathlib import Path
import json
import numpy as np
import pandas as pd

B = Path(__file__).resolve().parent
R = B / 'results'
P = pd.read_csv(B / 'plots.csv')[['PLOT_ID', 'Stand', 'Matrix', 'ClimateSiteIndexMeters']]
sample = set(pd.read_csv(B / 'version_sample_plots.csv').PLOT_ID.astype(int))
src = {
    'FVS-NE': ('fvs_ne.csv', 'bakuzis_height_fvs_ne.csv'),
    'FVS-ACD': ('fvs_acd.csv', 'bakuzis_height_fvs_acd.csv'),
    'OSM': ('osm.csv', 'bakuzis_height_osm.csv'),
    'ACD-v12.11.1': ('acd_v12_11_1.csv', 'bakuzis_acd_v12_11_1_part[0-9][0-9].csv'),
    'ACD-v13.1-base': ('acd_v13_1_base.csv', 'bakuzis_acd_v13_1_base_part[0-9][0-9].csv'),
    'ACD-v14.0.4-L2': ('acd_v14_0_4_L2.csv', 'bakuzis_acd_v14_0_4_L2_part[0-9][0-9].csv'),
    'ACD-v14.1-L2L': ('acd_v14_1_L2L.csv', 'bakuzis_acd_v14_1_L2L_part[0-9][0-9].csv'),
}
rows = []
audit = {}
for model, (base, pattern) in src.items():
    f = sorted(R.glob(pattern))
    assert len(f) == (2 if 'part[' in pattern else 1), (model, f)
    h = pd.concat([pd.read_csv(z) for z in f], ignore_index=True)
    assert h[['plot_id', 'year_offset']].notna().all().all()
    assert not h.duplicated(['plot_id', 'year_offset']).any()
    b = pd.read_csv(R / base)
    if 'ba_ft2ac' in h:
        check = b.merge(h[['plot_id','year_offset','ba_ft2ac','tpa','qmd_in']],on=['plot_id','year_offset'],suffixes=('_base','_rerun'),validate='one_to_one')
        assert len(check)==len(b)
        audit[model]={key:float(np.max(np.abs(check[key+'_base']-check[key+'_rerun']))) for key in ['ba_ft2ac','tpa','qmd_in']}
        assert audit[model]['ba_ft2ac']<1e-5 and audit[model]['tpa']<1e-4 and audit[model]['qmd_in']<1e-6, audit[model]
    h = h[['plot_id', 'year_offset', 'HT']].copy()
    z = b.merge(h, on=['plot_id', 'year_offset'], validate='one_to_one')
    assert len(z) == len(b), (model, len(z), len(b))
    assert (z.HT.dropna() > 0).all(), model
    assert z.loc[z.HT.isna(),'year_offset'].eq(0).all(), model
    assert z.groupby('plot_id').year_offset.nunique().eq(21).all(), model
    z['VOL'] = z.ba_ft2ac * 0.229568411 * z.HT * .40
    z['model'] = model
    rows.append(z)
x = pd.concat(rows, ignore_index=True).merge(P, left_on='plot_id', right_on='PLOT_ID', validate='many_to_one')
# A global site cutpoint makes the classes comparable across the seven arms.
cut = P.ClimateSiteIndexMeters.quantile([1/3, 2/3]).to_numpy()
x['site_class'] = np.select([x.ClimateSiteIndexMeters <= cut[0], x.ClimateSiteIndexMeters <= cut[1]], ['low', 'mid'], default='high')

res=[]
for (model, pid), g in x.groupby(['model', 'plot_id']):
    g=g.sort_values('year_offset')
    ht=g.HT.to_numpy();q=g.qmd_in.to_numpy();vol=g.VOL.to_numpy();ba=g.ba_ft2ac.to_numpy();t=g.tpa.to_numpy()
    hd_reversal = (((np.diff(ht)<-.01*ht[:-1]) & (np.diff(q)>.005*q[:-1])) |
                   ((np.diff(ht)>.01*ht[:-1]) & (np.diff(q)<-.005*q[:-1]))).any()
    res.append(dict(model=model, plot_id=pid, Matrix=g.Matrix.iloc[0], Stand=g.Stand.iloc[0], site_class=g.site_class.iloc[0],
        height_points=int(np.isfinite(ht).sum()),height_complete=bool(np.isfinite(ht).all()),
        ht_decrease_1pct=bool((np.diff(ht)<-.01*ht[:-1]).any()),
        hd_reversal=bool(hd_reversal),
        spacing_reversal=bool(((np.diff(ht)>.01*ht[:-1])&(np.diff(t)>.01*t[:-1])).any()),
        proxy_vol_decrease_1pct=bool((np.diff(vol)<-.01*vol[:-1]).any()),
        proxy_vol_25pct_below_peak=bool(vol[-1]<.75*np.nanmax(vol)),
        ht_0=float(ht[0]), ht_100=float(ht[-1]), vol_100=float(vol[-1]),
        ba_100=float(ba[-1])))
d=pd.DataFrame(res)
out=[]
for scope, sub in [('matched',d[d.plot_id.isin(sample)]), ('all_available',d)]:
    for model,g in sub.groupby('model'):
        a={'scope':scope,'model':model,'n_plots':len(g),'n_stands':g.Stand.nunique()}
        for col in ['ht_decrease_1pct','hd_reversal','spacing_reversal','proxy_vol_decrease_1pct','proxy_vol_25pct_below_peak']:
            a[col]=int(g[col].sum())
        a['height_complete']=int(g.height_complete.sum())
        a['height_partial']=int((~g.height_complete).sum())
        a.update(mean_ht_0=float(g.ht_0.mean()),mean_ht_100=float(g.ht_100.mean()),mean_proxy_vol_100=float(g.vol_100.mean()))
        out.append(a)
pd.DataFrame(out).to_csv(R/'bakuzis_full_axes.csv',index=False)
strata=[]
for (model,matrix),z in d[d.plot_id.isin(sample)].groupby(['model','Matrix']):
    row={'model':model,'stratum':matrix,'n_plots':len(z),'n_stands':z.Stand.nunique()}
    for col in ['height_complete','ht_decrease_1pct','hd_reversal','spacing_reversal','proxy_vol_decrease_1pct','proxy_vol_25pct_below_peak']:
        row[col]=int(z[col].sum())
    strata.append(row)
pd.DataFrame(strata).to_csv(R/'bakuzis_full_axes_strata.csv',index=False)

# Matched plot sample, site-class means with denominators for descriptive ordering.
g=x[x.plot_id.isin(sample)].groupby(['model','year_offset','site_class']).agg(n_plots=('plot_id','nunique'),n_ht=('HT','count'),n_stands=('Stand','nunique'),mean_ht=('HT','mean'),mean_proxy_vol=('VOL','mean'),mean_ba=('ba_ft2ac','mean'),mean_tpa=('tpa','mean'),mean_qmd=('qmd_in','mean')).reset_index()
g.to_csv(R/'bakuzis_site_trajectories.csv',index=False)
order=[]
for (model,year),a in g.groupby(['model','year_offset']):
    a=a.set_index('site_class').reindex(['low','mid','high'])
    for var in ['mean_ht','mean_proxy_vol']:
        v=a[var].to_numpy()
        order.append(dict(model=model,year_offset=year,axis=var,ordered=bool(np.all(np.diff(v)>=0)),low=v[0],mid=v[1],high=v[2]))
pd.DataFrame(order).to_csv(R/'bakuzis_site_ordering.csv',index=False)
(R/'bakuzis_height_rerun_audit.json').write_text(json.dumps(audit,indent=2))
thresholds=R/'bakuzis_thresholds.json'
meta=json.loads(thresholds.read_text())
meta['available_axes']=['top_height','height_diameter','spacing','standing_volume_proxy','descriptive_site_ordering']
meta['unavailable_axes']=['total_volume_production','Eichhorn_total_production']
meta['volume_proxy']='BA_m2ha × top_height_m × 0.40; not model-reported total volume'
thresholds.write_text(json.dumps(meta,indent=2))
print(pd.DataFrame(out).query("scope=='matched'").to_string(index=False))
