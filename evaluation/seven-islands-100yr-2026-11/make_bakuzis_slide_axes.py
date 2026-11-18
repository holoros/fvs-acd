from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd

B=Path(__file__).resolve().parent;O=B.parent/'outputs'
x=pd.read_csv(O/'bakuzis_matched_trajectory.csv')
order=['FVS-NE','FVS-ACD','OSM','ACD-v12.11.1','ACD-v13.1-base','ACD-v14.0.4-L2','ACD-v14.1-L2L']
colors=['#0072b2','#009e73','#e69f00','#cc79a7','#d55e00','#56b4e9','#134a31']
fig,axs=plt.subplots(2,2,figsize=(14.5,6.8),layout='constrained')
for m,c in zip(order,colors):
 d=x[x.model==m].sort_values('year_offset')
 axs[0,0].plot(d.year_offset,d.mean_ba,color=c,lw=2.4,label=m)
 axs[0,1].plot(d.year_offset,d.mean_tpa,color=c,lw=2.4)
 axs[1,0].plot(d.mean_qmd_in,d.mean_tpa,color=c,lw=2.4)
 axs[1,1].plot(d.mean_tpa,d.mean_ba,color=c,lw=2.4)
for a in axs.flat:a.grid(alpha=.16);a.tick_params(labelsize=11)
axs[0,0].set(xlabel='Years after inventory',ylabel='Basal area (ft²/ac)',title='Basal area over time')
axs[0,1].set(xlabel='Years after inventory',ylabel='Trees/ac',title='Stem density over time')
axs[1,0].set(xlabel='QMD (in)',ylabel='Trees/ac',title='Stem density versus diameter')
axs[1,1].set(xlabel='Trees/ac',ylabel='Basal area (ft²/ac)',title='Basal area versus stem density')
for a in axs.flat:a.xaxis.label.set_size(11);a.yaxis.label.set_size(11);a.title.set_size(13)
fig.legend(*axs[0,0].get_legend_handles_labels(),loc='upper center',ncol=7,fontsize=10,frameon=False,bbox_to_anchor=(.5,1.06))
fig.savefig(O/'seven_islands_slide_bakuzis_axes.png',dpi=240,bbox_inches='tight',facecolor='white')
