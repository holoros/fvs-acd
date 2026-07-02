from osgeo import gdal, osr
import csv, math
gdal.UseExceptions()
def opener(path):
    ds=gdal.Open(path); b=ds.GetRasterBand(1); gt=ds.GetGeoTransform(); inv=gdal.InvGeoTransform(gt)
    srs=osr.SpatialReference(); srs.ImportFromWkt(ds.GetProjection())
    return ds,b,inv,srs
esi_ds,esi_b,esi_inv,esi_srs=opener("/users/PUOM0008/crsfaaron/SiteIndex/Final_SI_Output.tif")
csi_ds,csi_b,csi_inv,csi_srs=opener("/users/PUOM0008/crsfaaron/SiteIndex/ClimateNA_SI_m.tif")
wgs=osr.SpatialReference(); wgs.ImportFromEPSG(4326); wgs.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
esi_srs.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER); csi_srs.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
t_esi=osr.CoordinateTransformation(wgs,esi_srs); t_csi=osr.CoordinateTransformation(wgs,csi_srs)
def samp(b,inv,srs,t,lon,lat):
    x,y,_=t.TransformPoint(lon,lat); px=int(inv[0]+inv[1]*x+inv[2]*y); py=int(inv[3]+inv[4]*x+inv[5]*y)
    if 0<=px<b.XSize and 0<=py<b.YSize:
        a=b.ReadAsArray(px,py,1,1)
        if a is not None:
            v=float(a[0,0])
            if math.isfinite(v) and 2<v<80: return round(v,3)
    return ""
rows=[]
with open("/users/PUOM0008/crsfaaron/magplot/verify/cb_v1270_results.csv") as f:
    for r in csv.DictReader(f):
        try: lon=float(r["lon"]); lat=float(r["lat"])
        except: continue
        rows.append((r["STAND"],r["PROV"],r.get("esi_cov",""),r["TOPHT_t1"],r["TOPHT_o"],r["TOPHT_p"],r["iv"],
                     samp(esi_b,esi_inv,esi_srs,t_esi,lon,lat), samp(csi_b,csi_inv,csi_srs,t_csi,lon,lat)))
with open("/users/PUOM0008/crsfaaron/bakeoff_v13/bench_metrics.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["STAND","PROV","esi_cov","TOPHT_t1","TOPHT_o","TOPHT_p","iv","esi_finalsi","csi_legacy"]); w.writerows(rows)
ne=[x for x in rows if x[7]!=""]; nc=[x for x in rows if x[8]!=""]
print("stands",len(rows),"esi_ok",len(ne),"csi_ok",len(nc))
