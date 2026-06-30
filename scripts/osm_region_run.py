import sqlite3, subprocess, csv, math
from pathlib import Path
OSM=Path.home()/"OSM/v2.26.1/OSMv2.26.1_Linux64/OSM.ConsoleApp"
W=Path.home()/"silc_cfi/osm_region"; W.mkdir(exist_ok=True)
REMAP={"PB":"WB","TA":"TL","PC":"PR"}
agy={"AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB"}
ti=list(csv.DictReader(open(Path.home()/"silc_cfi/region_input_trees.csv")))
man={r["pid"]:r for r in csv.DictReader(open(Path.home()/"silc_cfi/region_manifest.csv"))}
pids=sorted(set(r["pid"] for r in ti if r["pid"] in man))
sid={p:i+1 for i,p in enumerate(pids)}
sq=W/"r.sqlite"
if sq.exists(): sq.unlink()
con=sqlite3.connect(str(sq)); cur=con.cursor()
cur.execute("CREATE TABLE OSM_StandList (SurveyID INT, Plots INT, Zone TEXT, Management TEXT, BGI INT, PoorSite SMALLINT)")
cur.execute("CREATE TABLE OSM_TreeList (SurveyID INT, Species TEXT, DBH REAL, HT REAL, Stems REAL)")
for p in pids: cur.execute("INSERT INTO OSM_StandList VALUES (?,?,?,?,?,?)",(sid[p],1,"ME","None",3902,0))
n=0
for r in ti:
  if r["pid"] not in sid: continue
  try: d=float(r["dbh_cm"])
  except: d=0
  if d<=0: continue
  ht=max(1.9,1.3+25*(1-math.exp(-0.04*d)))
  sp=str(r["sp"]).upper(); sp=sp if sp in agy else "OH"; sp=REMAP.get(sp,sp)
  cur.execute("INSERT INTO OSM_TreeList (SurveyID,Species,DBH,HT,Stems) VALUES (?,?,?,?,?)",(sid[r["pid"]],sp,d,ht,float(r["expf_tph"]))); n+=1
con.commit(); con.close()
sc=W/"r_StandList.csv"
lines=["SIMULATION"," YEARS 20"," YPC 1","",f"INPUTS.SOURCE \"{sq}\"","","OUTPUTS"," Messages FALSE"," StandSummary.ConsoleOn FALSE",f" StandSummary.FilePath \"{sc}\"",f" TreeList.FilePath \"{W}/r_tl.csv\"","","SIMULATION.Scenario BASE"]+[f"SIMULATE {sid[p]}" for p in pids]
(W/"r.osmc").write_text("\n".join(lines)+"\n")
print("built",len(pids),"stands",n,"trees; running OSM...")
r=subprocess.run([str(OSM),str(W/"r.osmc")],capture_output=True,text=True,timeout=1800)
print("OSM rc",r.returncode)
osm={}
for row in csv.reader(open(sc)):
  if len(row)<14 or row[0]=="Scenario": continue
  try: s=int(row[1]); per=int(row[2]); ba=float(row[12]); qmd=float(row[9])
  except: continue
  osm[(s,per)]=(ba,qmd)
out=[]
for p in pids:
  iv=min(20,int(round(float(man[p]["remper"])))); k=(sid[p],iv)
  if k in osm: out.append((p,man[p]["region"],osm[k][0],osm[k][1]))
with open(Path.home()/"silc_cfi/region_osm_pred.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["pid","region","BA_osm","QMD_osm"]); w.writerows(out)
print("wrote region_osm_pred.csv n",len(out))
