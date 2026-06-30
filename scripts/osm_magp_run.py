import sqlite3, subprocess, csv, math
from pathlib import Path
OSM=Path.home()/"OSM/v2.26.1/OSMv2.26.1_Linux64/OSM.ConsoleApp"
W=Path.home()/"magplot/verify/osm_magp"; W.mkdir(exist_ok=True)
REMAP={"PB":"WB","TA":"TL","PC":"PR"}
agy={"AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB"}
ti=list(csv.DictReader(open(Path.home()/"magplot/verify/magplot_tree_init.csv")))
prs=list(csv.DictReader(open(Path.home()/"magplot/verify/magplot_pairs.csv")))
stands=sorted(set(r["STAND"] for r in ti))
sidmap={s:i+1 for i,s in enumerate(stands)}
sq=W/"m.sqlite"
if sq.exists(): sq.unlink()
con=sqlite3.connect(str(sq)); cur=con.cursor()
cur.execute("CREATE TABLE OSM_StandList (SurveyID INT, Plots INT, Zone TEXT, Management TEXT, BGI INT, PoorSite SMALLINT)")
cur.execute("CREATE TABLE OSM_TreeList (SurveyID INT, Species TEXT, DBH REAL, HT REAL, Stems REAL)")
for s in stands: cur.execute("INSERT INTO OSM_StandList VALUES (?,?,?,?,?,?)",(sidmap[s],1,"ME","None",3902,0))
n=0
for r in ti:
  try: d=float(r["DBH"])
  except: d=0
  if d<=0: continue
  try: ht=float(r["HT"])
  except: ht=0
  if not(ht>0): ht=max(1.9,1.3+25*(1-math.exp(-0.04*d)))
  sp=str(r["SP"]).upper(); sp=sp if sp in agy else "OH"; sp=REMAP.get(sp,sp)
  cur.execute("INSERT INTO OSM_TreeList (SurveyID,Species,DBH,HT,Stems) VALUES (?,?,?,?,?)",(sidmap[r["STAND"]],sp,d,ht,float(r["EXPF"]))); n+=1
con.commit(); con.close()
stand_csv=W/"m_StandList.csv"
lines=["SIMULATION"," YEARS 20"," YPC 1","",f"INPUTS.SOURCE \"{sq}\"","","OUTPUTS"," Messages FALSE"," StandSummary.ConsoleOn FALSE",f" StandSummary.FilePath \"{stand_csv}\"",f" TreeList.FilePath \"{W}/m_TreeList.csv\"","","SIMULATION.Scenario BASE"]+[f"SIMULATE {sidmap[s]}" for s in stands]
(W/"m.osmc").write_text("\n".join(lines)+"\n")
print("built",len(stands),"stands",n,"trees; running OSM...")
r=subprocess.run([str(OSM),str(W/"m.osmc")],capture_output=True,text=True,timeout=1200)
print("OSM rc",r.returncode)
# parse OSM standlist: SurveyID,Period,...,QMD(10),BA(13)
osm={}
for row in csv.reader(open(stand_csv)):
  if row[0]=="Scenario" or len(row)<14: continue
  try: sid=int(row[1]); per=int(row[2]); ba=float(row[12]); qmd=float(row[9])
  except: continue
  osm[(sid,per)]=(ba,qmd)
inv={v:k for k,v in sidmap.items()}
# compare at each stand interval to observed
out=[]
for p in prs:
  s=p["STAND"]; sid=sidmap.get(s); iv=int(round(float(p["interval_years"])))
  if sid is None: continue
  key=(sid,min(iv,20))
  if key not in osm: continue
  ba_o,qmd_o=osm[key]
  out.append((s,iv,float(p["BA_t2_obs"]),ba_o,float(p["QMD_t2_obs"]),qmd_o))
with open(Path.home()/"magplot/verify/magplot_osm_v_obs.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["STAND","interval","BA_obs","BA_osm","QMD_obs","QMD_osm"]); w.writerows(out)
import statistics as st
bo=[o[2] for o in out]; bp=[o[3] for o in out]
print("n",len(out),"BA obs %.1f osm %.1f bias %+.1f%%"%(st.mean(bo),st.mean(bp),100*(st.mean(bp)/st.mean(bo)-1)))
qo=[o[4] for o in out]; qp=[o[5] for o in out]
print("QMD obs %.1f osm %.1f bias %+.1f%%"%(st.mean(qo),st.mean(qp),100*(st.mean(qp)/st.mean(qo)-1)))
