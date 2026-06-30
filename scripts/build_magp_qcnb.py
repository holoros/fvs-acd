#!/usr/bin/env python3
# Build MagPlot QC + NB remeasurement pairs for the Hennigar-frame independent benchmark.
# Streams magp_trees.csv once, filters to QC/NB live trees, builds consecutive-measurement
# pairs per plot, exports pair metadata (with site coords for ESI v8), t1 tree lists, and
# observed t2 tree lists (so merch volume can be computed identically for obs and pred).
# No coordinates are written to any deliverable; coords stay in these Cardinal-only files.
import csv, sys, random
from collections import defaultdict
random.seed(2026)
MP = "/users/PUOM0008/crsfaaron/magplot"
OUT = MP + "/verify"
PROV = {"QC", "NB"}
PER_PROV = 2200          # sample cap per province for tractable model runs

# species_gs (genus.spp) -> AcadianGY 2-letter
SX = {
 "ABIE.BAL":"BF","PICE.MAR":"BS","PICE.GLA":"WS","PICE.RUB":"RS","PINU.BAN":"JP",
 "PINU.STR":"WP","PINU.RES":"RP","THUJ.OCC":"WC","LARI.LAR":"TA","TSUG.CAN":"EH",
 "POPU.TRE":"QA","POPU.BAL":"BP","POPU.GRA":"BT","POPU.DEL":"EC","BETU.PAP":"PB",
 "BETU.ALL":"YB","BETU.POP":"GB","ACER.RUB":"RM","ACER.SAH":"SM","ACER.SPI":"ST",
 "ACER.PEN":"ST","FAGU.GRA":"AB","FRAX.AME":"WA","FRAX.NIG":"BA","FRAX.PEN":"WA",
 "QUER.RUB":"RO","PRUN.PEN":"PR","PRUN.SER":"BC","OSTR.VIR":"HH","CARP.CAR":"HH",
 "TILI.AME":"OH","ULMU.AME":"OH","SORB.AME":"OH","SORB.DEC":"OH","CORY.COR":"OH",
 "SALI.SPP":"OH","ALNU.RUG":"OH","ALNU.INC":"OH","JUGL.CIN":"OH","ACER.SAC":"SM",
}
SOFT_GEN = {"ABIE","PICE","PINU","LARI","TSUG","THUJ","PSEU","JUNI","CHAM"}
def mapsp(gs):
    if gs in SX: return SX[gs]
    gen = gs.split(".")[0]
    return "OS" if gen in SOFT_GEN else "OH"

# 1. sites: province + coords + elev
site = {}
with open(MP+"/magp_sites.csv", newline="") as f:
    r = csv.reader(f); h = next(r)
    for row in r:
        sid, prov, lat, lon, elev = row[0], row[1], row[2], row[3], row[4]
        if prov in PROV and lat and lon:
            try: site[sid] = (prov, float(lat), float(lon), float(elev) if elev else 200.0)
            except: pass
print("QC/NB sites with coords:", len(site), flush=True)

# 2. header: plot_id -> {meas_num: (year, plotsize, taglimit)}
hdr = defaultdict(dict)
with open(MP+"/magp_tree_header.csv", newline="") as f:
    r = csv.reader(f); h = next(r)
    for row in r:
        sid, pid, ptype, mnum, myear = row[0], row[1], row[2], row[3], row[4]
        if sid in site and myear:
            try: hdr[pid][int(mnum)] = (int(myear), float(row[6]) if row[6] else None, sid)
            except: pass
print("plots in QC/NB with header:", len(hdr), flush=True)

# 3. stream trees: per (plot_id, meas_num) live tree list
# cols: 1 site,4 meas_num,12 species_gs,13 dbh,15 height,17 stem_ha,21 status,23 plot_id
TL = defaultdict(list)   # (pid, mnum) -> list of (sp, dbh_cm, ht_m, expf)
LIVE = {"LS","L","LF"}
n=0
with open(MP+"/magp_trees.csv", newline="") as f:
    r = csv.reader(f); h = next(r)
    for row in r:
        n+=1
        if n % 2000000 == 0: print("  trees scanned", n, flush=True)
        sid = row[0]
        if sid not in site: continue
        status = row[20]
        if status not in LIVE: continue
        try:
            dbh = float(row[12]); stem = float(row[16])
        except: continue
        if dbh<=0 or stem<=0: continue
        ht = None
        try:
            hh = float(row[14])
            if hh>0: ht = hh
        except: pass
        pid = row[22]; mnum = row[3]
        if pid not in hdr: continue
        try: mnum=int(mnum)
        except: continue
        TL[(pid,mnum)].append((mapsp(row[11]), dbh, ht, stem))
print("plot-measurements with live trees:", len(TL), flush=True)

# 4. build consecutive pairs per plot
pairs=[]; t1rows=[]; t2rows=[]
bymeas = defaultdict(list)
for (pid,mnum) in TL: bymeas[pid].append(mnum)
cand = defaultdict(list)   # prov -> list of pair dicts (defer sampling)
for pid, ms in bymeas.items():
    ms = sorted(ms)
    for i in range(len(ms)-1):
        m1,m2 = ms[i], ms[i+1]
        if m1 not in hdr[pid] or m2 not in hdr[pid]: continue
        y1 = hdr[pid][m1][0]; y2 = hdr[pid][m2][0]; sid = hdr[pid][m1][2]
        iv = y2-y1
        if iv<4 or iv>15: continue
        l1 = TL[(pid,m1)]; l2 = TL[(pid,m2)]
        if len(l1)<3 or len(l2)<3: continue
        prov,lat,lon,elev = site[sid]
        cand[prov].append((pid,sid,prov,iv,y1,y2,elev,lat,lon,l1,l2))
for prov in cand:
    lst = cand[prov]
    if len(lst)>PER_PROV: lst = random.sample(lst, PER_PROV)
    for (pid,sid,prov,iv,y1,y2,elev,lat,lon,l1,l2) in lst:
        ba1 = sum(3.141592653589793*(d/200)**2*e for (_,d,_,e) in l1)
        tph1= sum(e for (_,_,_,e) in l1)
        ba2 = sum(3.141592653589793*(d/200)**2*e for (_,d,_,e) in l2)
        tph2= sum(e for (_,_,_,e) in l2)
        qmd2= ((ba2/tph2)/(3.141592653589793/40000))**0.5 if tph2>0 else 0
        pairs.append([pid,sid,prov,iv,y1,y2,round(ba1,3),round(tph1,1),round(ba2,3),round(tph2,1),round(qmd2,3),round(elev,0),round(lat,5),round(lon,5)])
        for j,(sp,d,ht,e) in enumerate(l1,1): t1rows.append([pid,1,j,sp,round(d,2),"" if ht is None else round(ht,3),round(e,3),y1])
        for j,(sp,d,ht,e) in enumerate(l2,1): t2rows.append([pid,1,j,sp,round(d,2),"" if ht is None else round(ht,3),round(e,3),y2])

with open(OUT+"/magp_qcnb_pairs.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["STAND","SITE","PROV","interval_years","y1","y2","BA_t1_m2ha","TPH_t1","BA_t2_obs","TPH_t2_obs","QMD_t2_obs","ELEV","lat","lon"]); w.writerows(pairs)
with open(OUT+"/magp_qcnb_tree_init.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"]); w.writerows(t1rows)
with open(OUT+"/magp_qcnb_tree_t2.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"]); w.writerows(t2rows)
from collections import Counter
print("pairs by prov:", dict(Counter(p[2] for p in pairs)), flush=True)
print("total pairs:", len(pairs), "t1 trees:", len(t1rows), "t2 trees:", len(t2rows), flush=True)
print("DONE_BUILD", flush=True)
