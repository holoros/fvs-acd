from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

B=Path(__file__).resolve().parent;O=B.parent/'outputs'
x=pd.read_csv(O/'bakuzis_full_axes.csv').query("scope=='matched'")
order=['FVS-NE','FVS-ACD','OSM','ACD-v12.11.1','ACD-v13.1-base','ACD-v14.0.4-L2','ACD-v14.1-L2L']
x=x.set_index('model').reindex(order)
fig,axs=plt.subplots(1,2,figsize=(14.5,6.1),layout='constrained')
colors=['#0072b2','#009e73','#e69f00','#cc79a7','#d55e00','#56b4e9','#134a31']
y=np.arange(len(order))[::-1]
for ax,col,title in [(axs[0],'ht_decrease_1pct','Top-height decline >1%'),(axs[1],'proxy_vol_decrease_1pct','BA × height proxy decline >1%')]:
    v=x[col].to_numpy()
    ax.barh(y,v,color=colors,height=.62)
    ax.set_yticks(y,order,fontsize=12)
    ax.set_xlim(0,117)
    ax.set_xlabel('Plots flagged among 117 matched stands',fontsize=12)
    ax.set_title(title,fontsize=16,color='#124E3A',fontweight='bold')
    ax.grid(axis='x',alpha=.18)
    for yy,n in zip(y,v):ax.text(n+1,yy,str(int(n)),va='center',fontsize=11)
fig.savefig(O/'seven_islands_slide_bakuzis_full.png',dpi=240,facecolor='white')
