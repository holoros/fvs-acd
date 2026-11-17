#!/usr/bin/env python3
"""Input sensitivity on the same one-plot-per-stand audit sample."""
from pathlib import Path
import pandas as pd
import numpy as np
from run_seven_islands_100yr import fvs_plot, osm_all, trees_for_plot

B=Path(__file__).resolve().parent
R=B/'results'
p=pd.read_csv(B/'plots.csv',dtype={'Stand':str})
t=pd.read_csv(B/'trees.csv')
ids=set(pd.read_csv(B/'version_sample_plots.csv').PLOT_ID.astype(int))
p=p[p.PLOT_ID.isin(ids)].copy()
assert len(p)==117
grouped={int(k):trees_for_plot(v) for k,v in t[t.PLOT_ID.isin(ids)].groupby('PLOT_ID')}
grouped={k:[dict(z,species={'CE':'WC','WB':'PB'}.get(z['species'],z['species'])) for z in v]
         for k,v in grouped.items()}
assert all(len(grouped[int(pid)]) for pid in ids)
rows=[];errors=[]
for model in ('FVS-NE','FVS-ACD'):
    for scenario in ('site_low','site_high','height_missing'):
        label=f'{model}_{scenario}'
        for i,plot in enumerate(p.itertuples(),1):
            pp=plot
            tr=grouped[int(plot.PLOT_ID)]
            if scenario.startswith('site_'):
                factor=.8 if scenario=='site_low' else 1.2
                pp=plot._replace(ClimateSiteIndexMeters=plot.ClimateSiteIndexMeters*factor)
            else:
                tr=[dict(x,ht=0.) for x in tr]
            got,err=fvs_plot(pp,tr,model)
            if err:errors.append(dict(model=label,plot_id=int(plot.PLOT_ID),reason=err))
            else:
                for v in got:
                    if v['year_offset']==100:
                        v['scenario']=label;rows.append(v)
            if i%40==0:print(label,i,'/',len(p),flush=True)
for scenario,factor in [('bgi_low',.8),('bgi_high',1.)]:
    if scenario=='bgi_high':factor=1.2
    got,err=osm_all(p,grouped,R,bgi_multiplier=factor,model_label='OSM_'+scenario)
    errors.extend(err)
    rows += [dict(v,scenario='OSM_'+scenario) for v in got if v['year_offset']==100]
tr={k:[dict(x,ht=0.) for x in v] for k,v in grouped.items()}
got,err=osm_all(p,tr,R,model_label='OSM_height_missing')
errors.extend(err)
rows += [dict(v,scenario='OSM_height_missing') for v in got if v['year_offset']==100]
pd.DataFrame(rows).to_csv(R/'sensitivity_year100_plot.csv',index=False)
pd.DataFrame(errors).to_csv(R/'sensitivity_errors.csv',index=False)
assert not errors,errors[:5]
assert pd.DataFrame(rows).groupby('scenario').plot_id.nunique().eq(117).all()
base=pd.concat([pd.read_csv(R/f'{m}.csv') for m in ('fvs_ne','fvs_acd','osm')])
base=base[(base.year_offset==100)&base.plot_id.isin(ids)][['plot_id','model','ba_ft2ac']]
base['scenario']=base.model+'_baseline'
x=pd.concat([base[['plot_id','scenario','ba_ft2ac']],pd.DataFrame(rows)[['plot_id','scenario','ba_ft2ac']]])
ref=base.set_index(['plot_id','model']).ba_ft2ac
x['base_model']=x.scenario.str.split('_').str[0]
x['baseline_ba']=x.apply(lambda v:ref.loc[(v.plot_id,v.base_model)],axis=1)
x['delta_ba']=x.ba_ft2ac-x.baseline_ba
q=x.groupby('scenario').agg(n=('plot_id','nunique'),mean_ba=('ba_ft2ac','mean'),mean_delta_from_baseline=('delta_ba','mean'),
    median_delta_from_baseline=('delta_ba','median')).reset_index()
q.to_csv(R/'sensitivity_summary.csv',index=False)
print(q.to_string(index=False))
