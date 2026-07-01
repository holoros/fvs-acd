#!/usr/bin/env python3
# OSM-ACD on the identical in-domain MagPlot pairs (NB plus ESI-covered QC), writing all OSM I/O to
# local /tmp to avoid the NFS stale-file-handle that blocked the earlier attempt. Dumps OSM's predicted
# tree list at each stand's remeasurement interval so the SAME NSVB emulator and metric definitions used
# for FVS-ACD can score it (apples to apples). Outputs osm_h2h_treelist.csv and osm_h2h_meta.csv.
import sqlite3, subprocess, csv, math, os, shutil, time
from pathlib import Path
from collections import defaultdict
OSM=Path.home()/"OSM/v2.26.1/OSMv2.26.1_Linux64/OSM.ConsoleApp"
V=Path.home()/"magplot/verify"
W=Path("/tmp/osm_h2h");
shutil.rmtree(W, ignore_errors=True)
W.mkdir(parents=True, exist_ok=True)
REMAP={"PB":"WB","TA":"TL","PC":"PR"}; UNMAP={"WB":"PB","TL":"TA"}   # PR stays PR (maps to AGY PC only if needed)
agy={"AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB"}
sw={"WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC"}
def himp(s,d): return 1.3+27*(1-math.exp(-0.030*d)) if s in sw else 1.3+25*(1-math.exp(-0.028*d))
# in-domain pairs
esi={}
for r in csv.DictReader(open(V/"magp_qcnb_site_esi8.csv")):
    try: esi[r["SITE"]]=float(r["esi8"])
    except: esi[r["SITE"]]=0.0
prs={}
for r in csv.DictReader(open(V/"magp_qcnb_pairs.csv")):
    indom = (r["PROV"]=="NB") or (esi.get(r["SITE"],0)>2)
    if indom: prs[r["STAND"]]=r
ti=defaultdict(list)
for r in csv.DictReader(open(V/"magp_qcnb_tree_init.csv")):
    if r["STAND"] in prs:
        try: ti[r["STAND"]].append((str(r["SP"]).upper(), float(r["DBH"]), (float(r["HT"]) if r["HT"] not in("","NA") else 0.0), float(r["EXPF"])))
        except: pass
stands=sorted(ti)
sidmap={s:i+1 for i,s in enumerate(stands)}
zone={s:("NB" if prs[s]["PROV"]=="NB" else "ME") for s in stands}
sq=W/"m.sqlite"; con=sqlite3.connect(str(sq)); cur=con.cursor()
cur.execute("CREATE TABLE OSM_StandList (SurveyID INT, Plots INT, Zone TEXT, Management TEXT, BGI INT, PoorSite SMALLINT)")
cur.execute("CREATE TABLE OSM_TreeList (SurveyID INT, Species TEXT, DBH REAL, HT REAL, Stems REAL)")
for s in stands: cur.execute("INSERT INTO OSM_StandList VALUES (?,?,?,?,?,?)",(sidmap[s],1,zone[s],"None",3902,0))
nt=0
for s in stands:
    for (sp,d,ht,n) in ti[s]:
        if d<=0: continue
        if not(ht>0): ht=max(1.9,himp(sp,d))
        o=sp if sp in agy else ("OS" if sp in sw else "OH"); o=REMAP.get(o,o)
        cur.execute("INSERT INTO OSM_TreeList (SurveyID,Species,DBH,HT,Stems) VALUES (?,?,?,?,?)",(sidmap[s],o,d,ht,n)); nt+=1
con.commit(); con.close()
stand_csv=W/"m_StandList.csv"; tree_csv=W/"m_TreeList.csv"
lines=["SIMULATION"," YEARS 16"," YPC 1","",f"INPUTS.SOURCE \"{sq}\"","","OUTPUTS"," Messages FALSE",
 " StandSummary.ConsoleOn FALSE",f" StandSummary.FilePath \"{stand_csv}\""," TreeList.ConsoleOn FALSE",
 f" TreeList.FilePath \"{tree_csv}\"","","SIMULATION.Scenario BASE"]+[f"SIMULATE {sidmap[s]}" for s in stands]
(W/"m.osmc").write_text("\n".join(lines)+"\n")
print("built",len(stands),"stands",nt,"trees; running OSM...",flush=True)
rr=subprocess.run([str(OSM),str(W/"m.osmc")],capture_output=True,text=True,timeout=6000)
print("OSM rc",rr.returncode,(rr.stdout[-200:] if rr.returncode else ""),flush=True)
time.sleep(3); os.sync()
# DIAGNOSTIC: dump TreeList header and a sample
with open(tree_csv) as fh:
    diag=[next(fh) for _ in range(4)]
print("TREELIST_HEADER:", diag[0].rstrip(), flush=True)
for i,l in enumerate(diag[1:],1): print(f"TREELIST_ROW{i}:", l.rstrip(), flush=True)
# parse TreeList (local disk); OSM has no Period column, use Age (years, YPC 1). Select live trees
# (Stems>0) at Age == the stand's remeasurement interval.
hdr=None; tl=defaultdict(lambda: defaultdict(list))
for row in csv.reader(open(tree_csv)):
    if not row: continue
    low=[c.strip().lower() for c in row]
    if hdr is None and "surveyid" in low and "stems" in low:
        hdr={c.strip().lower():i for i,c in enumerate(row)}
        agecol=hdr.get("age", hdr.get("cycle")); continue
    if hdr is None: continue
    try:
        sid=int(float(row[hdr["surveyid"]])); per=int(float(row[agecol]))
        sp=row[hdr["species"]].upper(); d=float(row[hdr["dbh"]]); h=float(row[hdr["ht"]]); n=float(row[hdr["stems"]])
    except: continue
    if n<=0 or d<=0: continue
    tl[sid][per].append((UNMAP.get(sp,sp),d,h,n))
inv={v:k for k,v in sidmap.items()}
with open(V/"osm_h2h_treelist.csv","w",newline="") as f, open(V/"osm_h2h_meta.csv","w",newline="") as g:
    w=csv.writer(f); w.writerow(["STAND","SP","DBH","HT","EXPF"])
    m=csv.writer(g); m.writerow(["STAND","PROV","iv","matched"])
    for s in stands:
        sid=sidmap[s]; iv=int(round(float(prs[s]["interval_years"]))); per=min(iv,16)
        rows=tl.get(sid,{}).get(per) or tl.get(sid,{}).get(max(tl[sid]) if sid in tl and tl[sid] else 0)
        matched=1 if rows else 0
        m.writerow([s,prs[s]["PROV"],iv,matched])
        if rows:
            for (sp,d,h,n) in rows: w.writerow([s,sp,round(d,2),round(h,3),round(n,4)])
print("wrote osm_h2h_treelist.csv and osm_h2h_meta.csv; matched",sum(1 for s in stands if tl.get(sidmap[s])),"stands")
print("DONE_OSM_H2H")
