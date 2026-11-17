#!/usr/bin/env python3
"""Validate native FVS standardized trajectories before promoting them."""
from pathlib import Path
import numpy as np
import pandas as pd

R=Path(__file__).resolve().parent/'results'
for m in ('fvs_ne','fvs_acd'):
    p=R/(m+'_standardized.csv')
    e=R/(m+'_standardized_errors.csv')
    x=pd.read_csv(p)
    errors=pd.read_csv(e)
    c=x.groupby('plot_id').year_offset.agg(['size','nunique','min','max'])
    assert len(x)==11025 and len(c)==525 and len(errors)==11
    assert ((c['size']==21)&(c['nunique']==21)&(c['min']==0)&(c['max']==100)).all()
    assert x.duplicated(['plot_id','year_offset']).sum()==0
    assert np.isfinite(x.ba_ft2ac).all() and (x.ba_ft2ac>=0).all()
for m in ('fvs_ne','fvs_acd'):
    (R/(m+'.csv')).rename(R/(m+'_rawcodes.csv'))
    (R/(m+'_standardized.csv')).rename(R/(m+'.csv'))
    (R/(m+'_errors.csv')).rename(R/(m+'_rawcodes_errors.csv'))
    (R/(m+'_standardized_errors.csv')).rename(R/(m+'_errors.csv'))
print('promoted standardized native FVS trajectories after checks')
