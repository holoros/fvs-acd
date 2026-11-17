#!/usr/bin/env python3
"""Reproject native FVS with common cedar and birch species identities."""
import argparse
from pathlib import Path
import pandas as pd
from run_seven_islands_100yr import fvs_plot,trees_for_plot

B=Path(__file__).resolve().parent
R=B/'results'
a=argparse.ArgumentParser();a.add_argument('model',choices=['FVS-NE','FVS-ACD']);args=a.parse_args()
p=pd.read_csv(B/'plots.csv',dtype={'Stand':str})
t=pd.read_csv(B/'trees.csv')
by={int(k):trees_for_plot(g) for k,g in t.groupby('PLOT_ID')}
rows=[];errors=[]
for i,plot in enumerate(p.itertuples(),1):
    tt=by.get(int(plot.PLOT_ID),[])
    if not tt:
        errors.append(dict(plot_id=int(plot.PLOT_ID),model=args.model,reason='no live input trees'))
        continue
    tt=[dict(z,species={'CE':'WC','WB':'PB'}.get(z['species'],z['species'])) for z in tt]
    z,err=fvs_plot(plot,tt,args.model)
    rows.extend(z)
    if err:errors.append(dict(plot_id=int(plot.PLOT_ID),model=args.model,reason=err))
    if i%40==0:print(args.model,i,'/',len(p),flush=True)
slug=args.model.lower().replace('-','_')
pd.DataFrame(rows).to_csv(R/(slug+'_standardized.csv'),index=False)
pd.DataFrame(errors).to_csv(R/(slug+'_standardized_errors.csv'),index=False)
print(args.model,len(rows),len(errors),flush=True)
