#!/usr/bin/env python3
# OSM-ACD on the identical MagPlot QC+NB pairs, scored on merch volume increment with the SAME
# FF volume function used for AcadianGY, for an independent re-derivation of the 2018 OSM vs FVS
# comparison. Builds OSM sqlite from magp_qcnb_tree_init, runs each stand to its interval, parses
# the OSM TreeList output, computes FF merch volume on OSM's predicted tree list and on observed t2.
import sqlite3, subprocess, csv, math, statistics as st
from pathlib import Path
from collections import defaultdict
OSM=Path.home()/"OSM/v2.26.1/OSMv2.26.1_Linux64/OSM.ConsoleApp"
V=Path.home()/"magplot/verify"; W=V/"osm_qcnb"; W.mkdir(exist_ok=True)
REMAP={"PB":"WB","TA":"TL","PC":"PR"}
agy={"AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB"}
sw={"WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS"}
FF=0.45; MERCH=9.1
def himp(s,d): return 1.3+27*(1-math.exp(-0.030*d)) if s in sw else 1.3+25*(1-math.exp(-0.028*d))
def volsum(rows):  # rows: list of (sp,dbh,ht,stems)
    v=0.0
    for sp,d,ht,n in rows:
        if d<MERCH: continue
        h=ht if (ht and ht>0) else himp(sp,d)
        v+=math.pi*(d/200)**2*h*FF*n
    return v
ti=list(csv.DictReader(open(V/"magp_qcnb_tree_init.csv")))
prs={r["STAND"]:r for r in csv.DictReader(open(V/"magp_qcnb_pairs.csv"))}
t2=defaultdict(list)
for r in csv.DictReader(open(V/"magp_qcnb_tree_t2.csv")):
    try:
        d=float(r["DBH"]); h=float(r["HT"]) if r["HT"] not in("","NA") else 0
        t2[r["STAND"]].append((str(r["SP"]).upper(),d,h,float(r["EXPF"])))
    except: pass
stands=sorted(set(r["STAND"] for r in ti) & set(prs))
sidmap={s:i+1 for i,s in enumerate(stands)}
zone={s:("NB" if prs[s]["PROV"]=="NB" else "ME") for s in stands}
sq=W/"m.sqlite"
if sq.exists(): sq.unlink()
con=sqlite3.connect(str(sq)); cur=con.cursor()
cur.execute("CREATE TABLE OSM_StandList (SurveyID INT, Plots INT, Zone TEXT, Management TEXT, BGI INT, PoorSite SMALLINT)")
cur.execute("CREATE TABLE OSM_TreeList (SurveyID INT, Species TEXT, DBH REAL, HT REAL, Stems REAL)")
for s in stands: cur.execute("INSERT INTO OSM_StandList VALUES (?,?,?,?,?,?)",(sidmap[s],1,zone[s],"None",3902,0))
n=0
for r in ti:
  if r["STAND"] not in sidmap: continue
  try: d=float(r["DBH"])
  except: continue
  if d<=0: continue
  try: ht=float(r["HT"])
  except: ht=0
  if not(ht>0): ht=max(1.9,himp(str(r["SP"]).upper(),d))
  sp=str(r["SP"]).upper(); sp=sp if sp in agy else ("OS" if sp in sw else "OH"); sp=REMAP.get(sp,sp)
  cur.execute("INSERT INTO OSM_TreeList (SurveyID,Species,DBH,HT,Stems) VALUES (?,?,?,?,?)",(sidmap[r["STAND"]],sp,d,ht,float(r["EXPF"]))); n+=1
con.commit(); con.close()
stand_csv=W/"m_StandList.csv"; tree_csv=W/"m_TreeList.csv"
lines=["SIMULATION"," YEARS 16"," YPC 1","",f"INPUTS.SOURCE \"{sq}\"","","OUTPUTS"," Messages FALSE"," StandSummary.ConsoleOn FALSE",f" StandSummary.FilePath \"{stand_csv}\""," TreeList.ConsoleOn FALSE",f" TreeList.FilePath \"{tree_csv}\"","","SIMULATION.Scenario BASE"]+[f"SIMULATE {sidmap[s]}" for s in stands]
(W/"m.osmc").write_text("\n".join(lines)+"\n")
print("built",len(stands),"stands",n,"trees; running OSM...",flush=True)
rr=subprocess.run([str(OSM),str(W/"m.osmc")],capture_output=True,text=True,timeout=3000)
print("OSM rc",rr.returncode, rr.stdout[-300:] if rr.returncode else "")
# parse TreeList: detect columns
tl=defaultdict(lambda: defaultdict(list))   # sid -> period -> [(sp,dbh,ht,stems)]
hdr=None
for row in csv.reader(open(tree_csv)):
  if not row: continue
  if hdr is None and any(c.lower() in ("surveyid","dbh","species") for c in [x.lower() for x in row]):
    hdr={c.strip().lower():i for i,c in enumerate(row)}; continue
  if hdr is None: continue
  try:
    sid=int(float(row[hdr.get("surveyid",0)])); per=int(float(row[hdr.get("period",1)]))
    sp=row[hdr.get("species",2)]; d=float(row[hdr.get("dbh",3)]); h=float(row[hdr.get("ht",4)]); nst=float(row[hdr.get("stems",5)])
  except: continue
  tl[sid][per].append((sp,d,h,nst))
inv={v:k for k,v in sidmap.items()}
out=[]
for s in stands:
  sid=sidmap[s]; iv=int(round(float(prs[s]["interval_years"]))); per=min(iv,16)
  if sid not in tl or per not in tl[sid]: continue
  vp=volsum(tl[sid][per]);
  rows0=tl[sid].get(0) or tl[sid][min(tl[sid])]
  v1=volsum(rows0); v2o=volsum(t2[s]) if s in t2 else None
  bap=sum(math.pi*(d/200)**2*nst for (_,d,_,nst) in tl[sid][per] if d>=4)
  if v2o is None: continue
  out.append((s,prs[s]["PROV"],iv,v1,v2o,vp,float(prs[s]["BA_t2_obs"]),bap))
with open(V/"magp_qcnb_osm_results.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["STAND","PROV","iv","V1","V2o","V2p","BA2o","BA2p"]); w.writerows(out)
for pv in ("NB","QC"):
  s=[o for o in out if o[1]==pv]
  if len(s)<5: continue
  dvo=[(o[4]-o[3])/o[2] for o in s]; dvp=[(o[5]-o[3])/o[2] for o in s]
  bias=st.mean([p-o for p,o in zip(dvp,dvo)])
  rmse=(sum((p-o)**2 for p,o in zip(dvp,dvo))/len(s))**0.5
  babias=100*(st.mean([o[7] for o in s])/st.mean([o[6] for o in s])-1)
  print(f"  OSM {pv} n={len(s)} volInc obs {st.mean(dvo):+.2f} pred {st.mean(dvp):+.2f} bias {bias:+.2f} RMSE {rmse:.2f} | BA level bias {babias:+.1f}%")
print("DONE_OSM")
