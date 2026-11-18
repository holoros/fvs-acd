#!/usr/bin/env python3
"""Draw one modified Bakuzis matrix per model from aggregate site trajectories."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd

B=Path(__file__).resolve().parent
O=B.parent/'outputs'
g=pd.read_csv(O/'bakuzis_site_trajectories.csv')
axes=[('year_offset','Years after inventory'),('mean_qmd','QMD (in)'),('mean_ht','Top height (m)'),('mean_tpa','Trees/ac'),('mean_ba','BA (ft²/ac)'),('mean_proxy_vol','Volume proxy (m³/ha)')]
colors={'low':'#D69500','mid':'#007D5D','high':'#1475A2'}
files=[]
for model,sub in g.groupby('model'):
    fig,axs=plt.subplots(5,5,figsize=(14,13),layout='constrained')
    for ri in range(1,6):
        for ci in range(5):
            ax=axs[ri-1,ci]
            if ci>=ri:
                ax.axis('off');continue
            xkey,xlab=axes[ci];ykey,ylab=axes[ri]
            for site in ['low','mid','high']:
                d=sub[sub.site_class==site].sort_values('year_offset')
                ax.plot(d[xkey],d[ykey],color=colors[site],lw=1.8,label=site)
                ax.scatter(d[xkey].iloc[[0,-1]],d[ykey].iloc[[0,-1]],color=colors[site],s=9)
            ax.grid(alpha=.15)
            ax.tick_params(labelsize=7)
            if ci==0:ax.set_ylabel(ylab,fontsize=9)
            if ri==5:ax.set_xlabel(xlab,fontsize=9)
    fig.suptitle(model+' | modified Bakuzis matrix',fontsize=17,fontweight='bold',color='#124E3A')
    fig.legend(handles=[plt.Line2D([0],[0],color=colors[s],lw=2,label=s.title()+' site') for s in ['low','mid','high']],loc='upper right',ncol=3,bbox_to_anchor=(.97,.96),frameon=False)
    out=O/('seven_islands_bakuzis_matrix_'+model.lower().replace('.','_').replace('-','_')+'.png')
    fig.savefig(out,dpi=240,facecolor='white');plt.close(fig);files.append(str(out))
print('\n'.join(files))
