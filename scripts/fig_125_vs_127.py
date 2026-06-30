import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
mets=["BA","SDI","QMD","top ht","tot vol","merch vol","sawlog","value"]
v125_all=[6.4,6.8,1.1,0.8,6.4,6.7,6.8,6.6]
v127_all=[2.0,1.6,1.0,0.5,1.8,2.2,2.5,2.2]
v125_me=[9.6,10.1,4.0,1.5,10.8,10.8,11.8,12.4]
v127_me=[5.2,4.8,3.6,1.2,5.9,6.3,7.3,7.9]
fig,axes=plt.subplots(1,2,figsize=(12,4.8),dpi=150)
for ax,(a,b,ttl) in zip(axes,[(v125_all,v127_all,"All region (682 plots)"),(v125_me,v127_me,"Maine (201 plots)")]):
    x=np.arange(len(mets)); w=0.38
    ax.bar(x-w/2,a,w,label="12.5.0 current production",color="#1f77b4")
    ax.bar(x+w/2,b,w,label="12.7.0 new operational",color="#2ca02c")
    for xi,val in zip(x-w/2,a): ax.annotate(f"{val:.1f}",(xi,val),ha="center",va="bottom",fontsize=7,xytext=(0,1),textcoords="offset points")
    for xi,val in zip(x+w/2,b): ax.annotate(f"{val:.1f}",(xi,val),ha="center",va="bottom",fontsize=7,xytext=(0,1),textcoords="offset points",color="#1a7a1a")
    ax.axhline(0,color="#333",lw=1); ax.set_xticks(x); ax.set_xticklabels(mets,rotation=30,ha="right",fontsize=8)
    ax.set_ylabel("prediction bias (%)"); ax.set_title(ttl,fontsize=11); ax.grid(alpha=0.2,axis="y")
axes[0].legend(fontsize=9,loc="upper right")
fig.suptitle("Production head-to-head, predicted vs observed, regional remeasurement set (ESI v8)\n12.7.0 roughly halves the over-prediction of 12.5.0 across structure, volume, and value",fontsize=12)
fig.tight_layout(rect=[0,0,1,0.95])
out="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/figures/acadgy_125_vs_127_headtohead.png"
fig.savefig(out); print("WROTE",out)
