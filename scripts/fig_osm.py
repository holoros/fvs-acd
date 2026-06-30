import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, csv
rows=list(csv.DictReader(open("/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/results/seven_islands/fvsacd_vs_osm_matched.csv")))
age=[float(r["Age"]) for r in rows]
fa=[float(r["BA_fa"]) for r in rows]; osm=[float(r["BA_osm"]) for r in rows]
fig,ax=plt.subplots(figsize=(7.2,4.6),dpi=150)
ax.plot(age,fa,"o-",color="#1f77b4",lw=2.2,ms=7,label="FVS-ACD (production)")
ax.plot(age,osm,"s--",color="#d62728",lw=2.2,ms=7,label="OSM v2.26.1")
ax.fill_between(age,fa,osm,color="#999",alpha=0.12)
ax.annotate("starts agree\n(31.4 vs 31.9)",(0,31.6),textcoords="offset points",xytext=(18,-28),fontsize=8,color="#333",arrowprops=dict(arrowstyle="->",color="#888"))
ax.annotate("-35% by age 60",(60,34.9),textcoords="offset points",xytext=(-95,2),fontsize=9,color="#b22222")
ax.set_xlabel("projection year"); ax.set_ylabel("basal area (m2/ha)")
ax.set_title("FVS-ACD vs OSM on the same 11 Seven Islands stands\nIdentical start, then FVS-ACD self-thins while OSM accumulates",fontsize=11)
ax.grid(alpha=0.25); ax.legend(loc="lower right",fontsize=9); ax.set_ylim(20,46)
fig.tight_layout()
out="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/figures/acadgy_vs_osm_matched.png"
fig.savefig(out); print("WROTE",out)
