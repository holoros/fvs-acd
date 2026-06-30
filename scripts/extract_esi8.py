from osgeo import gdal
import csv, math
gdal.UseExceptions()
R="/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_240m.tif"
ds=gdal.Open(R); b=ds.GetRasterBand(1); gt=ds.GetGeoTransform(); inv=gdal.InvGeoTransform(gt)
nx,ny=ds.RasterXSize,ds.RasterYSize; arr=b.ReadAsArray()
out=[]; nna=0
with open("/users/PUOM0008/crsfaaron/silc_cfi/pid_coords.csv") as f:
  for r in csv.DictReader(f):
    lon=float(r["long"]); lat=float(r["lat"])
    px=int(inv[0]+inv[1]*lon+inv[2]*lat); py=int(inv[3]+inv[4]*lon+inv[5]*lat)
    v=""
    if 0<=px<nx and 0<=py<ny:
      val=float(arr[py,px])
      if math.isfinite(val) and val>0 and val<60: v=round(val,3)
      else: nna+=1
    else: nna+=1
    out.append((r["pid"],r["region"],r["legacy_csi"],v))
with open("/users/PUOM0008/crsfaaron/silc_cfi/pid_esi8.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["pid","region","legacy_csi","esi8"]); w.writerows(out)
vals=[o[3] for o in out if o[3]!=""]
print("extracted",len(out),"esi8_ok",len(vals),"na",nna,"mean",round(sum(vals)/len(vals),2),"range",round(min(vals),2),round(max(vals),2))
