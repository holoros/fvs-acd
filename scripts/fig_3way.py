import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
# MAGPlot NB Canadian CFI (262 pairs), predicted vs observed, percent bias
metrics=["BA","QMD","TPH"]
data={
 "12.5.0 (current production)":[ 1.8, 1.2, -1.1],
 "12.7.0 (new operational)":   [-2.6, 4.2, -6.3],
 "OSM v2.26.1":                [-2.3,-8.9, None],
}
colors={"12.5.0 (current production)":"#1f77b4","12.7.0 (new operational)":"#2ca02c","OSM v2.26.1":"#d62728"}
fig,ax=plt.subplots(figsize=(8.2,4.8),dpi=150)
x=np.arange(len(metrics)); w=0.26
for i,(k,v) in enumerate(data.items()):
    vals=[(np.nan if z is None else z) for z in v]
    bars=ax.bar(x+(i-1)*w, vals, w, label=k, color=colors[k])
    for xi,val in zip(x+(i-1)*w,vals):
        if np.isfinite(val): ax.annotate(f"{val:+.1f}",(xi,val),ha="center",va="bottom" if val>=0 else "top",fontsize=8,
                                          xytext=(0,2 if val>=0 else -2),textcoords="offset points")
ax.axhline(0,color="#333",lw=1); ax.set_xticks(x); ax.set_xticklabels(metrics)
ax.set_ylabel("prediction bias (%)"); ax.set_ylim(-12,8)
ax.set_title("Three-way benchmark on independent Canadian CFI (MAGPlot NB, n=262)\nobserved vs current production, new operational, and OSM",fontsize=11)
ax.legend(fontsize=8.5,loc="lower left"); ax.grid(alpha=0.2,axis="y")
ax.text(0.99,0.02,"OSM TPH not shown (different stem-count definition)",transform=ax.transAxes,ha="right",fontsize=7,color="#777")
fig.tight_layout()
out="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/figures/acadgy_3way_benchmark_magplot.png"
fig.savefig(out); print("WROTE",out)
