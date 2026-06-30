import sqlite3, subprocess, csv, math
from pathlib import Path
OSM=Path.home()/"OSM/v2.26.1/OSMv2.26.1_Linux64/OSM.ConsoleApp"
W=Path.home()/"silc_cfi/osm_match"; W.mkdir(exist_ok=True)
REMAP={"PB":"WB","TA":"TL","PC":"PR"}
agy={"AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB"}
rows=list(csv.DictReader(open(Path.home()/"silc_cfi/silc_osm_trees.csv")))
sids=sorted(set(int(r["SurveyID"]) for r in rows))
sq=W/"m.sqlite"
if sq.exists(): sq.unlink()
con=sqlite3.connect(str(sq)); cur=con.cursor()
cur.execute("CREATE TABLE OSM_StandList (SurveyID INT, Plots INT, Zone TEXT, Management TEXT, BGI INT, PoorSite SMALLINT)")
cur.execute("CREATE TABLE OSM_TreeList (SurveyID INT, Species TEXT, DBH REAL, HT REAL, Stems REAL)")
for s in sids: cur.execute("INSERT INTO OSM_StandList VALUES (?,?,?,?,?,?)",(s,1,"ME","None",3902,0))
n=0
for r in rows:
  try: d=float(r["DBH"])
  except: d=0
  if d<=0: continue
  try: ht=float(r["HT"])
  except: ht=0
  if not (ht>0): ht=max(1.9,1.3+25*(1-math.exp(-0.04*d)))
  sp=str(r["Species"]).upper(); sp=sp if sp in agy else "OH"; sp=REMAP.get(sp,sp)
  cur.execute("INSERT INTO OSM_TreeList (SurveyID,Species,DBH,HT,Stems) VALUES (?,?,?,?,?)",(int(r["SurveyID"]),sp,d,ht,float(r["Stems"]))); n+=1
con.commit(); con.close()
stand_csv=W/"m_StandList.csv"; tree_csv=W/"m_TreeList.csv"
lines=["SIMULATION"," YEARS 80"," YPC 1","",f"INPUTS.SOURCE \"{sq}\"","","OUTPUTS"," Messages FALSE"," StandSummary.ConsoleOn FALSE",f" StandSummary.FilePath \"{stand_csv}\"",f" TreeList.FilePath \"{tree_csv}\"","","SIMULATION.Scenario BASE"]+[f"SIMULATE {s}" for s in sids]
(W/"m.osmc").write_text("\n".join(lines)+"\n")
print("built",len(sids),"stands",n,"trees; running OSM 80yr...")
r=subprocess.run([str(OSM),str(W/"m.osmc")],capture_output=True,text=True,timeout=900)
print("OSM rc",r.returncode,(r.stdout[-200:] if r.stdout else ""),(r.stderr[-300:] if r.stderr else ""))
print("standlist exists:",stand_csv.exists(), stand_csv.stat().st_size if stand_csv.exists() else 0)
