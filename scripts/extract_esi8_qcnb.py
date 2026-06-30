from osgeo import gdal
import csv, math
gdal.UseExceptions()
R="/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_30m.tif"
ds=gdal.Open(R); b=ds.GetRasterBand(1); gt=ds.GetGeoTransform(); inv=gdal.InvGeoTransform(gt); nx,ny=ds.RasterXSize,ds.RasterYSize
seen={}
for r in csv.DictReader(open("/users/PUOM0008/crsfaaron/magplot/verify/magp_qcnb_pairs.csv")):
  sid=r["SITE"]
  if sid in seen: continue
  try: lon=float(r["lon"]); lat=float(r["lat"])
  except: seen[sid]=""; continue
  px=int(inv[0]+inv[1]*lon+inv[2]*lat); py=int(inv[3]+inv[4]*lon+inv[5]*lat); v=""
  if 0<=px<nx and 0<=py<ny:
    a=b.ReadAsArray(px,py,1,1)
    if a is not None:
      val=float(a[0,0])
      if math.isfinite(val) and 2<val<60: v=round(val,2)
  seen[sid]=v
with open("/users/PUOM0008/crsfaaron/magplot/verify/magp_qcnb_site_esi8.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["SITE","esi8"]); [w.writerow([k,v]) for k,v in seen.items()]
vals=[v for v in seen.values() if v!=""]
print("sites",len(seen),"esi8_ok",len(vals),"mean",round(sum(vals)/len(vals),2) if vals else "NA","range",(round(min(vals),2),round(max(vals),2)) if vals else "NA")
print("DONE_ESI")
