import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import csv, numpy as np
base="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/results/seven_islands/"
def fnum(x):
    try: return float(x)
    except: return float("nan")
def load(f):
    d={}
    for r in csv.DictReader(open(base+f)):
        d[r["pid"]]={k:(r[k] if k in("region","pid") else fnum(r[k])) for k in r}
    return d
P=load("region_pred_fullmetric.csv"); O=load("region_obs_fullmetric.csv")
pids=[p for p in P if p in O]
reg=np.array([P[p]["region"] for p in pids])
attrs=[("BA","basal area (m2/ha)"),("SDI","stand density index"),("QMD","QMD (cm)"),("totvol","total volume (m3/ha)")]
fig,axes=plt.subplots(2,2,figsize=(10,7.5),dpi=150)
colors={"ME":"#1f77b4","NB":"#ff7f0e","NS":"#2ca02c"}
for ax,(a,lab) in zip(axes.ravel(),attrs):
    ov=np.array([O[p][a] for p in pids]); pv=np.array([P[p][a] for p in pids])
    ok=(ov>0)&np.isfinite(ov)&np.isfinite(pv); ov,pv,rg=ov[ok],pv[ok],reg[ok]
    bias=100*(pv-ov)/ov
    # plot-level points (light), then binned mean overall + per region
    ax.axhline(0,color="#444",lw=1)
    ax.scatter(ov,bias,s=7,c="#bbb",alpha=0.4,linewidths=0)
    # quantile bins overall
    qs=np.quantile(ov,np.linspace(0,1,8)); cen=[]; mb=[]
    for i in range(len(qs)-1):
        m=(ov>=qs[i])&(ov<=qs[i+1])
        if m.sum()>=5: cen.append(np.median(ov[m])); mb.append(np.mean(bias[m]))
    ax.plot(cen,mb,"o-",color="#222",lw=2.2,ms=6,label="all",zorder=5)
    for r in ["ME","NB","NS"]:
        mr=rg==r
        if mr.sum()<20: continue
        ovr,br=ov[mr],bias[mr]; qr=np.quantile(ovr,np.linspace(0,1,5)); c=[]; b=[]
        for i in range(len(qr)-1):
            mm=(ovr>=qr[i])&(ovr<=qr[i+1])
            if mm.sum()>=4: c.append(np.median(ovr[mm])); b.append(np.mean(br[mm]))
        ax.plot(c,b,"-",color=colors[r],lw=1.4,alpha=0.8,label=r)
    ax.set_xlabel("observed "+lab); ax.set_ylabel("prediction bias (%)")
    ax.set_title(a,fontsize=10); ax.grid(alpha=0.2); ax.set_ylim(-40,50)
axes[0,0].legend(fontsize=8,loc="upper right",ncol=2)
fig.suptitle("AcadianGY 12.7.0 (ESI v8): prediction bias by stand attribute (682 NB/NS/ME plots)",fontsize=12)
fig.tight_layout(rect=[0,0,1,0.97])
out="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/figures/acadgy_v1270_bias_by_attribute.png"
fig.savefig(out); print("WROTE",out)
