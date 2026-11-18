from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd

O=Path(__file__).resolve().parent.parent/'outputs'
x=pd.read_csv(O/'matched_overall_uncertainty.csv')
order=['FVS-NE','FVS-ACD','OSM','ACD-v12.11.1','ACD-v13.1-base','ACD-v14.0.4-L2','ACD-v14.1-L2L']
color=['#0072b2','#009e73','#e69f00','#cc79a7','#d55e00','#56b4e9','#134a31']
fig,ax=plt.subplots(figsize=(14.5,6.6),layout='constrained')
for m,c in zip(order,color):
 d=x[x.model==m].sort_values('year_offset')
 ax.plot(d.year_offset,d.mean_ba_ft2ac,color=c,ls='--' if m.startswith('ACD-') else '-',lw=2.8,label=m.replace('ACD-v','v'))
 ax.fill_between(d.year_offset,d.ci_low_mean_ba,d.ci_high_mean_ba,color=c,alpha=.11)
ax.set(xlabel='Years after inventory',ylabel='Mean live basal area (ft²/ac)',ylim=(80,245),xlim=(0,100))
ax.grid(alpha=.17);ax.tick_params(labelsize=12)
ax.xaxis.label.set_size(13);ax.yaxis.label.set_size(13)
fig.legend(*ax.get_legend_handles_labels(),loc='upper center',ncol=7,fontsize=10.5,frameon=False,bbox_to_anchor=(.5,1.06))
fig.savefig(O/'seven_islands_slide_trajectory.png',dpi=240,bbox_inches='tight',facecolor='white')
