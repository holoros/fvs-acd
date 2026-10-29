#!/usr/bin/env python3
# v143p3_conf_pool.py
# 14.3 pre-registration 3, step 1 close: pools the confirmation set lookup counts (sources 1 to 5) under draft choice 5 (a)
# and checks the registered floors (PREREG2 rule 7 (b)): at least 30 heavy stands, ESI coverage at least 0.80, at least
# 3 gated V1 classes (d / Dq at or above 0.6) with 30 or more survivor trees in heavy and intermediate stands.
# Pooling rule (fixed here before pooling): a source passes its checks when it gives a PREREG1 rule 7 harvest class
# (tree-linked v0 removal), a tst and an ESI v8 value for its stands. Sources 1 and 2 pass; source 3 (NB) does not
# (the NB CLI sites have at most two visits, so no rule 7 class; the 5 NB NFI ground plot stands with a third visit were
# not classed by the lookup and are carried as an upper bound of 5 heavy stands in a sensitivity row); source 4 has no
# qualifying stand by the flag's definition; source 5 is a complement (raster extents only).
# Inputs are the aggregate files written by v143p3_conf_fia.R (firebreather) and v143p3_conf_nbqc.py (Cardinal).
# Writes out/conf_pooled_DATA.csv and logs its md5 in logs/conf_counts_md5.txt. No identifiers. No em dashes.
import csv, os, sys, hashlib, datetime
R = "/users/PUOM0008/crsfaaron/v143p3"
fo = os.path.join(R, "out/conf_pooled_DATA.csv")
if os.path.exists(fo): sys.exit("refusing to overwrite " + fo)
cnt = list(csv.DictReader(open(os.path.join(R, "out/conf_fb/conf_fia_counts_DATA.csv"))))
sv = list(csv.DictReader(open(os.path.join(R, "out/conf_fb/conf_fia_survivors_DATA.csv"))))
new = [r for r in cnt if r["new_v2_2025_or_later"] == "TRUE"]
st = sum(int(r["triples"]) for r in new); hv = sum(int(r["heavy"]) for r in new); ec = sum(int(r["esi_covered"]) for r in new)
cls = {}
for r in sv: cls[r["rcl"]] = cls.get(r["rcl"], 0) + int(r["survivor_trees"])
gated = sum(1 for k, n in cls.items() if k != "[0,0.6)" and n >= 30)
rows = []
def add(label, stands, heavy, esi_cov, ngated):
    rows.append(dict(pool=label, stands=stands, heavy_stands=heavy, esi_coverage=round(esi_cov, 6), gated_v1_classes_30=ngated,
                     floor_heavy_30=heavy >= 30, floor_esi_080=esi_cov >= 0.80, floor_classes_3=ngated >= 3,
                     all_floors_met=(heavy >= 30 and esi_cov >= 0.80 and ngated >= 3)))
add("sources 1 and 2 (passing sources, choice 5 a)", st, hv, ec / st, gated)
add("sensitivity: plus the 5 NB NFI ground plot stands counted as heavy and ESI covered (upper bound)", st + 5, hv + 5, (ec + 5) / (st + 5), gated)
for k in ["[0,0.6)", "[0.6,0.85)", "[0.85,1.15)", "[1.15,1.5)", "[1.5,Inf)"]:
    rows.append(dict(pool="survivor trees, sources 1 and 2, heavy and intermediate, class " + k, stands="", heavy_stands="", esi_coverage="",
                     gated_v1_classes_30=cls.get(k, 0), floor_heavy_30="", floor_esi_080="", floor_classes_3="", all_floors_met=""))
with open(fo, "w", newline="") as h:
    w = csv.DictWriter(h, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
m = hashlib.md5(open(fo, "rb").read()).hexdigest()
ins = ["out/conf_fb/conf_fia_counts_DATA.csv", "out/conf_fb/conf_fia_survivors_DATA.csv", "out/conf_nbqc_counts_DATA.csv", "out/conf_nbqc_survivors_DATA.csv", "out/conf_esi_surfaces_DATA.csv"]
with open(os.path.join(R, "logs/conf_counts_md5.txt"), "a") as h:
    t = datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
    for f in ins: h.write("%s  %s  input, logged %s\n" % (hashlib.md5(open(os.path.join(R, f), "rb").read()).hexdigest(), f, t))
    h.write("%s  out/conf_pooled_DATA.csv  confirmation set counts written %s (before any plan registration, fit or outcome read)\n" % (m, t))
for r in rows: print(r)
print(m + "  conf_pooled_DATA.csv"); print("CONF_POOL_DONE")
