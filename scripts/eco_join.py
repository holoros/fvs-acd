from osgeo import ogr, osr
import csv
ogr.UseExceptions()

SHP = "/users/PUOM0008/crsfaaron/SiteIndex/NA_Eco_L3_WGS84.shp"
ds = ogr.Open(SHP)
lyr = ds.GetLayer(0)
srs_eco = lyr.GetSpatialRef()
srs_wgs84 = osr.SpatialReference(); srs_wgs84.ImportFromEPSG(4326)
srs_wgs84.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
if srs_eco: srs_eco.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
xform = osr.CoordinateTransformation(srs_wgs84, srs_eco) if srs_eco else None

defn = lyr.GetLayerDefn()
fields = [defn.GetFieldDefn(i).GetName() for i in range(defn.GetFieldCount())]
codefield = [f for f in fields if f.upper() in ("NA_L3CODE","L3CODE","US_L3CODE")][0]
namefield = [f for f in fields if f.upper() in ("NA_L3NAME","L3NAME")][0]
print("code field:", codefield, "name field:", namefield, "n features:", lyr.GetFeatureCount())

feats = []
for feat in lyr:
    geom = feat.GetGeometryRef().Clone()
    minx, maxx, miny, maxy = geom.GetEnvelope()
    feats.append((geom, minx, maxx, miny, maxy, feat.GetField(codefield), feat.GetField(namefield)))
print("loaded", len(feats), "polygons")

def find_eco(lon, lat):
    x, y = lon, lat
    if xform:
        pt = ogr.Geometry(ogr.wkbPoint); pt.AddPoint(lon, lat); pt.Transform(xform)
        x, y = pt.GetX(), pt.GetY()
    else:
        pt = ogr.Geometry(ogr.wkbPoint); pt.AddPoint(x, y)
    for geom, minx, maxx, miny, maxy, code, name in feats:
        if minx <= x <= maxx and miny <= y <= maxy:
            if geom.Contains(pt):
                return code, name
    return None, None

def process(infile, lonfield, latfield, idfields, outfile):
    rows = list(csv.DictReader(open(infile)))
    out = []
    ok = 0
    for i, r in enumerate(rows):
        try:
            lon = float(r[lonfield]); lat = float(r[latfield])
        except (ValueError, KeyError):
            out.append([r.get(f,"") for f in idfields] + ["", ""]); continue
        code, name = find_eco(lon, lat)
        if code: ok += 1
        out.append([r.get(f,"") for f in idfields] + [code or "", name or ""])
        if (i+1) % 1000 == 0: print("  ...", i+1, "/", len(rows))
    with open(outfile, "w", newline="") as f:
        w = csv.writer(f); w.writerow(idfields + ["eco","eco_name"]); w.writerows(out)
    print(infile, "-> ", outfile, ": n=", len(rows), "assigned=", ok)

process("/users/PUOM0008/crsfaaron/magplot/magp_sites_nb_ns.csv", "longitude", "latitude",
        ["magp_site_id"], "/users/PUOM0008/crsfaaron/magplot/verify/magp_site_ecol3.csv")
process("/users/PUOM0008/crsfaaron/fia_data/ME_PLOT.csv", "LON", "LAT",
        ["CN"], "/users/PUOM0008/crsfaaron/silc_cfi/me_plot_ecol3.csv")
print("DONE_ECO_JOIN")
