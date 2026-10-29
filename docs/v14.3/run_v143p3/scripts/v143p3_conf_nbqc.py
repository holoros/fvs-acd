#!/usr/bin/env python3
# v143p3_conf_nbqc.py
# 14.3 pre-registration 3 (draft 1, md5 72c9c7e4), step 1: confirmation set lookup, candidate sources 3, 4 and 5 (Cardinal).
#   Source 3: New Brunswick permanent plots with a recorded harvest and a later remeasurement. The NB plot data on the
#             host is the MAGPlot NB CLI extract (LSOG/nb_magplot/20260618Weiskittel_1037_1/MAGPlot_NB/NB_CLI/CLI_AllHolders,
#             holders include restricted JDI and Acadian plots) and the NB NFI ground plots beside it.
#             Rule fixed here before any count: a stand is a site with visits v1 < v2 and a treatment of any type dated in
#             [1900, y1 - 1] (tst = y1 - year of the latest such treatment) and none dated in [y1, y2]. PREREG1 rule 7's
#             harvest class needs a pre-harvest visit v0 with tree-linked removal; a site with fewer than three visits
#             therefore has no rule 7 class and counts as 0 heavy stands. treatment_pct availability is reported only.
#   Source 4: Quebec MAGPlot stands carrying the PREREG19 cut flag. The flag is defined in firebreather
#             jobs/v142p19/scripts/2026-09-27_v142_volconv_score.R, cut_stands(): a C-type treatment with
#             treatment_year > Y1 and <= Y2, that is a cut inside the interval. No flagged stand therefore has its
#             cut before t1; this source qualifies 0 stands by the flag's definition (recorded, no data read).
#   Source 5: ESI surfaces west of 71.5 W: extent of each candidate raster (gdalinfo), no plot read.
# READ RESTRICTION as the draft's step 2: counts by source and class, ESI coverage, survivor counts by d / Dq class at
# v1 (status only). Coordinates are piped to gdallocationinfo in memory, never written or printed. No identifiers are
# written or printed. No em dashes.
import csv, collections, subprocess, json, os, sys, math, hashlib, datetime
OUT = "/users/PUOM0008/crsfaaron/v143p3/out"
fo = [os.path.join(OUT, x) for x in ("conf_nbqc_counts_DATA.csv", "conf_nbqc_survivors_DATA.csv", "conf_esi_surfaces_DATA.csv", "conf_nbqc_allowlist_reads.log")]
for f in fo:
    if os.path.exists(f): sys.exit("refusing to overwrite " + f)
AL = []
def al(s): AL.append(datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z") + "  " + s)
RAST = "/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_30m.tif"
NB = "/users/PUOM0008/crsfaaron/LSOG/nb_magplot/20260618Weiskittel_1037_1/MAGPlot_NB"
RELB = [0, 0.6, 0.85, 1.15, 1.5, float("inf")]
LAB = ["[0,0.6)", "[0.6,0.85)", "[0.85,1.15)", "[1.15,1.5)", "[1.5,Inf)"]
def rcl(x):
    for i in range(5):
        if RELB[i] <= x < RELB[i + 1]: return LAB[i]
def rd(p): return csv.DictReader(open(p, encoding="utf-8-sig"))
def esi_at(lonlat):
    if not lonlat: return []
    inp = "".join("%.6f %.6f\n" % (lo, la) for lo, la in lonlat)
    out = subprocess.run(["gdallocationinfo", "-wgs84", "-valonly", RAST], input=inp, capture_output=True, text=True).stdout.splitlines()
    if len(out) != len(lonlat): sys.exit("gdallocationinfo count mismatch")
    v = []
    for s in out:
        try: v.append(float(s))
        except ValueError: v.append(float("nan"))
    return v
rows, svrows = [], []
for sub in ("NB_CLI/CLI_AllHolders", "NFI_GP/NB"):
    d = os.path.join(NB, sub)
    al(sub + "/magp_tree_header.csv: site, plot_type_id, meas_num, meas_year")
    vis = collections.defaultdict(dict)
    for r in rd(os.path.join(d, "magp_tree_header.csv")):
        try: vis[r["magp_site_id"]][r["meas_num"]] = int(r["meas_year"])
        except ValueError: pass
    al(sub + "/magp_treatment.csv: site, treatment_type, treatment_year, treatment_pct")
    trt = collections.defaultdict(list)
    for r in rd(os.path.join(d, "magp_treatment.csv")):
        try: y = int(float(r["treatment_year"]))
        except ValueError: y = -1
        trt[r["magp_site_id"]].append((r["treatment_type"], y, r["treatment_pct"]))
    nvis = collections.Counter(len(set(v.values())) for v in vis.values())
    qual = {}
    for s, v in vis.items():
        ys = sorted(set(v.values()))
        if len(ys) < 2: continue
        y1, y2 = ys[-2], ys[-1]
        before = [t for t in trt.get(s, []) if 1900 <= t[1] <= y1 - 1]
        inside = [t for t in trt.get(s, []) if y1 <= t[1] <= y2]
        if before and not inside:
            last = max(before, key=lambda t: t[1])
            mn = {y: m for m, y in v.items()}
            qual[s] = dict(y1=y1, y2=y2, tst=y1 - last[1], ttype=last[0], pct=last[2], m1=mn[y1], m2=mn[y2], three=len(ys) >= 3)
    # ESI coverage, coordinates in memory only
    al(sub + "/magp_sites.csv: latitude, longitude of qualifying sites, in memory, piped to gdallocationinfo (value above 2 covered)")
    ll = {}
    for r in rd(os.path.join(d, "magp_sites.csv")):
        if r["magp_site_id"] in qual:
            try: ll[r["magp_site_id"]] = (float(r["longitude"]), float(r["latitude"]))
            except ValueError: pass
    ks = list(ll); vals = esi_at([ll[k] for k in ks]); cov = {k: (not math.isnan(x)) and x > 2 for k, x in zip(ks, vals)}
    del ll, vals
    # survivors at v1, status only: tree live (L) at v1 and at v2 on the same plot type and tree number, dbh at v1 >= 5 cm
    al(sub + "/magp_trees.csv: site, plot_type_id, tree_num, meas_num, dbh (v1 only), stem_ha (v1 only), tree_status")
    t1, st2 = {}, {}
    for r in rd(os.path.join(d, "magp_trees.csv")):
        s = r["magp_site_id"]
        if s not in qual: continue
        q = qual[s]; k = (s, r["plot_type_id"], r["tree_num"])
        if r["meas_num"] == q["m1"] and r["tree_status"] == "L":
            try: t1[k] = (float(r["dbh"]), float(r["stem_ha"]))
            except ValueError: pass
        elif r["meas_num"] == q["m2"]:
            st2[k] = r["tree_status"]
    dq = collections.defaultdict(lambda: [0.0, 0.0])
    for (s, _, _), (dbh, w) in t1.items():
        if dbh > 0 and w > 0: dq[s][0] += w * dbh * dbh; dq[s][1] += w
    sv = collections.Counter(); sve = collections.Counter()
    for k, (dbh, w) in t1.items():
        s = k[0]
        if st2.get(k) == "L" and dbh >= 5 and dq[s][1] > 0:
            c = rcl(dbh / math.sqrt(dq[s][0] / dq[s][1])); sv[c] += 1
            if cov.get(s): sve[c] += 1
    del t1, st2
    tt = collections.Counter(q["ttype"] for q in qual.values())
    rows.append(dict(source="3 New Brunswick plots (" + sub.split("/")[0] + ")", sites=len(vis),
                     sites_2plus_visits=sum(n for k, n in nvis.items() if k >= 2), sites_3plus_visits=sum(n for k, n in nvis.items() if k >= 3),
                     stands_treatment_before_v1_none_inside=len(qual), with_v0_for_rule7_class=sum(q["three"] for q in qual.values()),
                     heavy_rule7=0, treatment_types=";".join("%s:%d" % kv for kv in sorted(tt.items())),
                     treatment_pct_recorded=sum(1 for q in qual.values() if q["pct"] not in ("", "NA")),
                     tst_min=min([q["tst"] for q in qual.values()], default=""), tst_max=max([q["tst"] for q in qual.values()], default=""),
                     esi_covered=sum(1 for k in qual if cov.get(k)), esi_coverage=(sum(1 for k in qual if cov.get(k)) / len(qual)) if qual else ""))
    for c in LAB: svrows.append(dict(source=rows[-1]["source"], rcl=c, survivor_trees=sv[c], survivor_trees_esi=sve[c]))
rows.append(dict(source="4 Quebec MAGPlot PREREG19 cut flag (cut inside the interval by the flag's definition)", sites="", sites_2plus_visits="",
                 sites_3plus_visits="", stands_treatment_before_v1_none_inside=0, with_v0_for_rule7_class=0, heavy_rule7=0,
                 treatment_types="cut flag: 65 qc_c and 11 qc_fl stands [FST]; none with the cut before t1", treatment_pct_recorded="", tst_min="",
                 tst_max="", esi_covered="", esi_coverage=""))
# source 5: raster extents
al("gdalinfo -json of candidate ESI rasters (extent only)")
cands = ["/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_30m.tif",
         "/fs/scratch/PUOM0008/crsfaaron/canada/magplot/acadian/NorthAmerica_ESI_v8.tif",
         "/fs/scratch/PUOM0008/crsfaaron/canada/magplot/na_surface/NorthAmerica_ESI.tif",
         "/fs/scratch/PUOM0008/crsfaaron/na30/conus_recovered/ESI_v7_CONUS_30m.tif",
         "/fs/scratch/PUOM0008/crsfaaron/cspi_v7/v8/render/esi_v8_conus_1km.tif"]
er = []
for p in cands:
    try:
        j = json.loads(subprocess.run(["gdalinfo", "-json", p], capture_output=True, text=True).stdout)
        w = j.get("wgs84Extent", {}).get("coordinates", [[]])[0]
        xs = [c[0] for c in w]; ys = [c[1] for c in w]
        er.append(dict(raster=os.path.basename(p), dir=os.path.dirname(p).replace("/fs/scratch/PUOM0008/crsfaaron", "scratch"),
                       res_m=abs(j["geoTransform"][1]) if "geoTransform" in j else "", lon_min=min(xs) if xs else "", lon_max=max(xs) if xs else "",
                       lat_min=min(ys) if ys else "", lat_max=max(ys) if ys else "", reaches_west_of_71_5W=(min(xs) < -71.5) if xs else ""))
    except Exception as e:
        er.append(dict(raster=os.path.basename(p), dir="", res_m="", lon_min="", lon_max="", lat_min="", lat_max="", reaches_west_of_71_5W="error " + type(e).__name__))
def wr(f, rr):
    with open(f, "w", newline="") as h:
        w = csv.DictWriter(h, fieldnames=list(rr[0].keys())); w.writeheader(); w.writerows(rr)
wr(fo[0], rows); wr(fo[1], svrows); wr(fo[2], er)
open(fo[3], "w").write("\n".join(AL) + "\n")
for r in rows: print(r)
for r in svrows: print(r)
for r in er: print(r)
for f in fo: print(hashlib.md5(open(f, "rb").read()).hexdigest() + "  " + os.path.basename(f))
print("CONF_NBQC_DONE")
