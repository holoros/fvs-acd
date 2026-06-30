from osgeo import gdal
import csv, math
gdal.UseExceptions()
R="/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_30m.tif"
ds=gdal.Open(R); b=ds.GetRasterBand(1); gt=ds.GetGeoTransform(); inv=gdal.InvGeoTransform(gt); nx,ny=ds.RasterXSize,ds.RasterYSize
out=[]; ok=0; na=0
for r in csv.DictReader(open("/users/PUOM0008/crsfaaron/magplot/magp_sites_nb_ns.csv")):
  try: lon=float(r["longitude"]); lat=float(r["latitude"])
  except: out.append((r["magp_site_id"],"")); na+=1; continue
  px=int(inv[0]+inv[1]*lon+inv[2]*lat); py=int(inv[3]+inv[4]*lon+inv[5]*lat); v=""
  if 0<=px<nx and 0<=py<ny:
    a=b.ReadAsArray(px,py,1,1)
    if a is not None:
      val=float(a[0,0])
      if math.isfinite(val) and 2<val<60: v=round(val,2); ok+=1
      else: na+=1
    else: na+=1
  else: na+=1
  out.append((r["magp_site_id"],v))
with open("/users/PUOM0008/crsfaaron/magplot/verify/magp_site_esi8.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["SITE","esi8"]); w.writerows(out)
vals=[o[1] for o in out if o[1]!=""]
print("sites",len(out),"esi8_ok",ok,"na",na,"mean",round(sum(vals)/len(vals),2),"range",round(min(vals),2),round(max(vals),2))
