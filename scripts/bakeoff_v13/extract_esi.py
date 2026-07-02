from osgeo import gdal
import csv, math
gdal.UseExceptions()
R="/users/PUOM0008/crsfaaron/SiteIndex/Final_SI_Output.tif"
ds=gdal.Open(R); b=ds.GetRasterBand(1); gt=ds.GetGeoTransform(); inv=gdal.InvGeoTransform(gt)
nx,ny=ds.RasterXSize,ds.RasterYSize
out=[]; ok=0; na=0
with open("/users/PUOM0008/crsfaaron/bakeoff_v13/ne_plot_coords.csv") as f:
  rdr=csv.DictReader(f)
  for r in rdr:
    try: lon=float(r["LON"]); lat=float(r["LAT"])
    except: out.append((r["rid"],"")); continue
    px=int(inv[0]+inv[1]*lon+inv[2]*lat); py=int(inv[3]+inv[4]*lon+inv[5]*lat); v=""
    if 0<=px<nx and 0<=py<ny:
      a=b.ReadAsArray(px,py,1,1)
      if a is not None:
        val=float(a[0,0])
        if math.isfinite(val) and 2<val<80: v=round(val,3); ok+=1
        else: na+=1
      else: na+=1
    else: na+=1
    out.append((r["rid"],v))
with open("/users/PUOM0008/crsfaaron/bakeoff_v13/ne_plot_esi.csv","w",newline="") as f:
  w=csv.writer(f); w.writerow(["rid","esi"]); w.writerows(out)
vals=[o[1] for o in out if o[1]!=""]
print("plots",len(out),"esi_ok",ok,"na",na,"mean",round(sum(vals)/len(vals),2) if vals else None,
      "range",(min(vals),max(vals)) if vals else None)
