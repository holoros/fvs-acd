#!/usr/bin/env python3
# Observed ingrowth and mortality rates from MagPlot QC+NB, by tree-ID matching across consecutive
# measurements (the rigorous way). Ingrowth = a tree present and >= tag limit at meas k+1 that was
# absent (or below tag) at meas k. Mortality = present at k, absent at k+1. Rates in stems/ha/yr.
# Restricted to the benchmark's sampled plots for consistency with the comprehensive benchmark.
import csv, sys
from collections import defaultdict
MP="/users/PUOM0008/crsfaaron/magplot"; V=MP+"/verify"
# plots in the benchmark + their province
prov={};
for r in csv.DictReader(open(V+"/magp_qcnb_pairs.csv")): prov[r["STAND"]]=r["PROV"]
plots=set(prov)
# header: plot_id -> {meas_num:(year)}
hdr=defaultdict(dict)
for r in csv.DictReader(open(MP+"/magp_tree_header.csv")):
    if r["plot_id"] in plots and r["meas_year"]:
        try: hdr[r["plot_id"]][int(r["meas_num"])]=(int(r["meas_year"]), float(r["taglimit_dbh"]) if r["taglimit_dbh"] else 0)
        except: pass
# stream trees: (plot,meas) -> {tree_id: (dbh, stem_ha, live)}
TT=defaultdict(dict)
LIVE={"LS","L","LF"}
n=0
with open(MP+"/magp_trees.csv",newline="") as f:
    rd=csv.reader(f); h=next(rd)
    for row in rd:
        n+=1
        if n%4000000==0: print("scanned",n,flush=True)
        pid=row[22]
        if pid not in hdr: continue
        try: mnum=int(row[3]); dbh=float(row[12]); stem=float(row[16])
        except: continue
        tid=row[4]; status=row[20]
        TT[(pid,mnum)][tid]=(dbh,stem,status in LIVE)
# per plot consecutive pairs
agg=defaultdict(lambda:[0.0,0.0,0.0,0])  # prov -> [ingrowth_sph_yr, mort_sph_yr, surv_sph, n_pairs]
for pid,ms in hdr.items():
    mm=sorted(ms)
    for i in range(len(mm)-1):
        m1,m2=mm[i],mm[i+1]
        if (pid,m1) not in TT or (pid,m2) not in TT: continue
        y1,tag1=hdr[pid][m1]; y2,tag2=hdr[pid][m2]; iv=y2-y1
        if iv<4 or iv>15: continue
        a=TT[(pid,m1)]; b=TT[(pid,m2)]
        ingr=mort=0.0
        for tid,(d,s,lv) in b.items():
            if lv and d>=max(7,tag2):
                if tid not in a or not a[tid][2] or a[tid][0]<max(7,tag2): ingr+=s
        for tid,(d,s,lv) in a.items():
            if lv and (tid not in b or not b[tid][2]): mort+=s
        pv=prov[pid]; g=agg[pv]; g[0]+=ingr/iv; g[1]+=mort/iv; g[3]+=1
print("=== Observed MagPlot ingrowth and mortality (stems/ha/yr), by province ===")
for pv in ("NB","QC"):
    g=agg[pv]
    if g[3]<5: continue
    print(f"  {pv} n_pairs={g[3]:4d}  ingrowth {g[0]/g[3]:6.1f}  mortality {g[1]/g[3]:6.1f} stems/ha/yr")
print("DONE_INGROWTH")
