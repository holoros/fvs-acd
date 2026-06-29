from osgeo import gdal
import csv, sys
gdal.UseExceptions()
R="/users/PUOM0008/crsfaaron/SiteIndex/Final_SI_Output.tif"
ds=gdal.Open(R); b=ds.GetRasterBand(1); gt=ds.GetGeoTransform()
nx,ny=ds.RasterXSize,ds.RasterYSize; nodata=b.GetNoDataValue()
arr=b.ReadAsArray()  # full read (Float32, 15000x7932 ~ 475MB ok)
inv=gdal.InvGeoTransform(gt)
out=[]; nna=0
with open("/users/PUOM0008/crsfaaron/silc_cfi/pid_coords.csv") as f:
  rd=csv.DictReader(f)
  for r in rd:
    lon=float(r["long"]); lat=float(r["lat"])
    px=int(inv[0]+inv[1]*lon+inv[2]*lat); py=int(inv[3]+inv[4]*lon+inv[5]*lat)
    if 0<=px<nx and 0<=py<ny:
      v=float(arr[py,px])
      if nodata is not None and v==nodata: v=""; nna+=1
    else: v=""; nna+=1
    out.append((r["pid"],r["region"],r["legacy_csi"],v))
with open("/users/PUOM0008/crsfaaron/silc_cfi/pid_esi.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["pid","region","legacy_csi","esi"]); w.writerows(out)
vals=[float(o[3]) for o in out if o[3]!=""]
print("extracted",len(out),"esi_ok",len(vals),"na",nna)
print("esi mean %.2f range %.2f-%.2f"%(sum(vals)/len(vals),min(vals),max(vals)))
