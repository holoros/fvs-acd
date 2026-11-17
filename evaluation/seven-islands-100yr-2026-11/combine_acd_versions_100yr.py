#!/usr/bin/env python3
"""Combine version shards and check common starting state on the restricted server."""
from pathlib import Path
import json
import numpy as np
import pandas as pd

B=Path(__file__).resolve().parent
R=B/'results'
labels={
    'v12_11_1':'ACD-v12.11.1',
    'v13_1_base':'ACD-v13.1-base',
    'v14_0_4_L2':'ACD-v14.0.4-L2',
    'v14_1_L2L':'ACD-v14.1-L2L',
}
sample=set(pd.read_csv(B/'version_sample_plots.csv').PLOT_ID.astype(int))
native=pd.read_csv(R/'fvs_ne.csv')
native=native[(native.year_offset==0)&native.plot_id.isin(sample)].set_index('plot_id')
qc={}
for slug,label in labels.items():
    parts=[R/f'acd_{slug}_part{i:02d}.csv' for i in (1,2)]
    assert all(f.exists() for f in parts),(label,parts)
    x=pd.concat([pd.read_csv(f) for f in parts],ignore_index=True)
    assert set(x.model)=={label},label
    c=x.groupby('plot_id').year_offset.agg(['size','nunique','min','max'])
    complete=c[(c['size']==21)&(c['nunique']==21)&(c['min']==0)&(c['max']==100)]
    missing=sample-set(complete.index)
    efiles=[R/f'acd_{slug}_part{i:02d}_errors.csv' for i in (1,2)]
    errs=[]
    for f in efiles:
        if f.exists() and f.stat().st_size:
            errs.append(pd.read_csv(f))
    errors=pd.concat(errs,ignore_index=True) if errs else pd.DataFrame()
    y0=x[x.year_offset==0].set_index('plot_id')
    shared=y0.index.intersection(native.index)
    max_ba_error=float((y0.loc[shared,'ba_ft2ac']-native.loc[shared,'ba_ft2ac']).abs().max())
    max_tpa_error=float((y0.loc[shared,'tpa']-native.loc[shared,'tpa']).abs().max())
    qc[label]=dict(plots=len(c),complete_21=len(complete),missing=len(missing),
        error_rows=len(errors),max_year0_ba_difference=max_ba_error,max_year0_tpa_difference=max_tpa_error,
        negative_ba=int((x.ba_ft2ac<0).sum()),nonfinite_ba=int((~np.isfinite(x.ba_ft2ac)).sum()))
    x.sort_values(['plot_id','year_offset']).to_csv(R/f'acd_{slug}.csv',index=False)
(R/'version_qc.json').write_text(json.dumps(qc,indent=2))
print(json.dumps(qc,indent=2))
