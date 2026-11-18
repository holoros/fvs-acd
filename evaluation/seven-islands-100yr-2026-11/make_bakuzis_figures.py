#!/usr/bin/env python3
"""Headless aggregate-only plots for the common-axis Bakuzis screen."""
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

B=Path(__file__).resolve().parent;O=B.parent/'outputs'
x=pd.read_csv(O/'bakuzis_matched_trajectory.csv')
s=pd.read_csv(O/'bakuzis_common_axes.csv');s=s[s.scope=='matched']
order=['FVS-NE','FVS-ACD','OSM','ACD-v12.11.1','ACD-v13.1-base','ACD-v14.0.4-L2','ACD-v14.1-L2L']
colors=['#0072b2','#009e73','#e69f00','#cc79a7','#d55e00','#56b4e9','#134a31']
fig,axs=plt.subplots(2,2,figsize=(12,9.2))
for m,c in zip(order,colors):
    d=x[x.model==m].sort_values('year_offset')
    axs[0,0].plot(d.year_offset,d.mean_ba,color=c,lw=2,label=m)
    axs[0,1].plot(d.year_offset,d.mean_tpa,color=c,lw=2)
    axs[1,0].plot(d.mean_qmd_in,d.mean_tpa,color=c,lw=2)
    axs[1,1].plot(d.mean_tpa,d.mean_ba,color=c,lw=2)
axs[0,0].set(xlabel='Years after inventory',ylabel='Live basal area (ft² ac⁻¹)',title='Age to basal area')
axs[0,1].set(xlabel='Years after inventory',ylabel='Trees ac⁻¹',title='Age to stem density')
axs[1,0].set(xlabel='Quadratic mean diameter (in)',ylabel='Trees ac⁻¹',title='Diameter to stem density')
axs[1,1].set(xlabel='Trees ac⁻¹',ylabel='Live basal area (ft² ac⁻¹)',title='Stem density to basal area')
for a in axs.flat:a.grid(alpha=.18)
fig.legend(*axs[0,0].get_legend_handles_labels(),loc='upper center',ncol=4,fontsize=9,frameon=False,bbox_to_anchor=(.5,1.01))
fig.text(.08,.01,'Same 117 plots in every arm; five-year steps. Height and volume relations were not evaluated.',fontsize=9)
fig.tight_layout(rect=(0,.03,1,.96));fig.savefig(O/'seven_islands_bakuzis_common_axes.png',dpi=300);plt.close(fig)

fig,ax=plt.subplots(figsize=(10,5.8))
z=1.96
for i,(m,c) in enumerate(zip(order,colors)):
    r=s[s.model==m].iloc[0];n=int(r.reineke_evaluated);k=int(r.reineke_flagged)
    p=k/n;den=1+z*z/n;center=(p+z*z/(2*n))/den
    half=z*np.sqrt(p*(1-p)/n+z*z/(4*n*n))/den
    yy=len(order)-1-i
    ax.plot([center-half,center+half],[yy,yy],color=c,lw=3)
    ax.plot(p,yy,'o',color=c,ms=9)
    ax.text(min(1.02,center+half+.025),yy,f'{k}/{n}',va='center',fontsize=10)
ax.set_yticks(range(len(order)),list(reversed(order)))
ax.set_xlim(0,1.15)
ax.set(xlabel='Fraction flagged among evaluated plots',title='Reineke screening, matched 117-stand panel')
ax.grid(axis='x',alpha=.18)
fig.text(.12,.02,'Bars: 95% Wilson intervals. QMD gain screen: >0.10 cm yr⁻¹; 5-year output. Unevaluated plots excluded.',fontsize=9)
fig.tight_layout(rect=(0,.05,1,1));fig.savefig(O/'seven_islands_bakuzis_reineke.png',dpi=300);plt.close(fig)
