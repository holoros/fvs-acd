#!/usr/bin/env python3
"""Plot aggregate-only firebreather outputs for the Seven Islands review."""
from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

B = Path(__file__).resolve().parent
O = B.parent / 'outputs'
O.mkdir(exist_ok=True)
overall = pd.read_csv(B/'matched_overall_uncertainty.csv')
strata = pd.read_csv(B/'matched_strata_uncertainty.csv')
full_strata = pd.read_csv(B/'strata_uncertainty.csv')
diff = pd.read_csv(B/'year100_paired_differences.csv')
styles = {
    'FVS-NE':('#0072b2','-'), 'FVS-ACD':('#009e73','-'), 'OSM':('#e69f00','-'),
    'ACD-v12.11.1':('#cc79a7','--'), 'ACD-v13.1-base':('#d55e00','--'),
    'ACD-v14.0.4-L2':('#56b4e9','--'), 'ACD-v14.1-L2L':('#134a31','--')}
models=[m for m in styles if m in overall.model.unique()]

fig,ax=plt.subplots(figsize=(11,6.8))
for m in models:
    d=overall[overall.model==m].sort_values('year_offset')
    c,ls=styles[m]
    ax.plot(d.year_offset,d.mean_ba_ft2ac,label=f'{m} (n={int(d.n_plots.max())})',color=c,ls=ls,lw=2.3)
    ax.fill_between(d.year_offset.to_numpy(),d.ci_low_mean_ba.to_numpy(),d.ci_high_mean_ba.to_numpy(),color=c,alpha=.11)
ax.set(xlabel='Years after inventory',ylabel='Mean live basal area (ft² ac⁻¹)',title='Seven Islands: 100-year model trajectories')
ax.grid(alpha=.2);ax.legend(ncol=2,fontsize=9,frameon=False)
fig.text(.08,.02,'All models shown on the same 117 plots; shading is a 95% stand-cluster bootstrap CI for the mean.',fontsize=9)
fig.tight_layout(rect=(0,.04,1,1));fig.savefig(O/'seven_islands_all_models_trajectory.png',dpi=300);plt.close(fig)

version=[m for m in models if m.startswith('ACD-v')]
if version:
    d=diff[(diff.stratum=='ALL')&(diff.model_a.isin(version))&(diff.model_b=='FVS-ACD')].set_index('model_a').reindex(version)
    fig,ax=plt.subplots(figsize=(9,5.3))
    y=np.arange(len(d))[::-1]
    for yi,(m,row) in zip(y,d.iterrows()):
        c=styles[m][0]
        ax.plot(row.mean_difference_ft2ac,yi,'o',ms=8,color=c)
        ax.plot([row.ci_low,row.ci_high],[yi,yi],color=c,lw=2.5)
    ax.axvline(0,color='black',lw=.8)
    ax.set_yticks(y,version)
    ax.set(xlabel='Year-100 basal area difference from native FVS-ACD (ft² ac⁻¹)',title='Research ACD arms, paired on the same sampled plots')
    ax.grid(axis='x',alpha=.2)
    fig.text(.12,.02,'Points: paired mean difference. Bars: 95% stand-cluster bootstrap CI. Settings differ by arm.',fontsize=9)
    fig.tight_layout(rect=(0,.04,1,1));fig.savefig(O/'seven_islands_acd_versions_paired.png',dpi=300);plt.close(fig)

    s=strata[(strata.year_offset==100)&(strata.model.isin(version))].copy()
    order=(strata[(strata.year_offset==100)&(strata.model=='FVS-NE')].sort_values('mean_ba_ft2ac').stratum.tolist())
    fig,ax=plt.subplots(figsize=(11,8))
    offsets=np.linspace(-.3,.3,len(version))
    for off,m in zip(offsets,version):
        d=s[s.model==m].set_index('stratum').reindex(order)
        c=styles[m][0]
        yy=np.arange(len(order))+off
        ax.scatter(d.mean_ba_ft2ac,yy,color=c,s=22,label=m)
        for yi,row in zip(yy,d.itertuples()):
            if np.isfinite(row.ci_low_mean_ba):
                ax.plot([row.ci_low_mean_ba,row.ci_high_mean_ba],[yi,yi],color=c,lw=1.2,alpha=.75)
    ax.set_yticks(np.arange(len(order)),order)
    ax.set(xlabel='Mean year-100 live basal area (ft² ac⁻¹)',title='Research ACD arms by Matrix stratum')
    ax.grid(axis='x',alpha=.2);ax.legend(ncol=2,fontsize=8,frameon=False)
    fig.text(.08,.02,'One sampled plot per stand. Bars omitted for strata with fewer than five sampled stands.',fontsize=9)
    fig.tight_layout(rect=(0,.04,1,1));fig.savefig(O/'seven_islands_acd_versions_strata.png',dpi=300);plt.close(fig)

native=['FVS-NE','FVS-ACD','OSM']
s=full_strata[(full_strata.year_offset==100)&(full_strata.model.isin(native))]
order=s[s.model=='FVS-NE'].sort_values('mean_ba_ft2ac').stratum.tolist()
fig,ax=plt.subplots(figsize=(11,8))
for off,m in zip((-.23,0,.23),native):
    d=s[s.model==m].set_index('stratum').reindex(order)
    c=styles[m][0];yy=np.arange(len(order))+off
    ax.scatter(d.mean_ba_ft2ac,yy,color=c,s=27,label=m)
    for yi,row in zip(yy,d.itertuples()):
        if np.isfinite(row.ci_low_mean_ba):
            ax.plot([row.ci_low_mean_ba,row.ci_high_mean_ba],[yi,yi],color=c,lw=1.3,alpha=.8)
ax.set_yticks(np.arange(len(order)),order)
ax.set(xlabel='Mean year-100 live basal area (ft² ac⁻¹)',title='Full eligible panel by Matrix stratum')
ax.grid(axis='x',alpha=.2);ax.legend(ncol=3,fontsize=9,frameon=False)
fig.text(.08,.02,'All 525 eligible plots. Bars: 95% stand-cluster bootstrap CI; omitted for strata with fewer than five stands.',fontsize=9)
fig.tight_layout(rect=(0,.04,1,1));fig.savefig(O/'seven_islands_strata_native_year100.png',dpi=300);plt.close(fig)
