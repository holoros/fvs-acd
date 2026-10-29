# Pass 17 addendum: extract corrected SILC_L (full137) survivor-tree growth from the raw
# "SILC CFI.accdb" Access database Aaron supplied, matching real TREE_ID (a persistent tag
# across CFI_TreeInit_<YEAR> tables, 1981-2002), replacing the broken per-visit TREE reindex
# in build_silc_bench.R. Validated: species mismatch on TREE_ID-matched survivor pairs is 17.4
# percent (1462 pairs across 123 of 137 stands), well below the 48.9 percent seen under the
# reindex bug, though higher than ME_FIA_L/BAXTER's ~2 percent after their own fixes; disclosed
# as a residual caveat in the pass 17 addendum handoff, not treated as fully clean.
#
# EXPF convention note: this script reuses EXPF_HA = 12.3553 to match the value already present
# in bench_silc_l_tree_init_full137.csv (and BAXTER's fixed-plot convention), NOT the raw
# CFI_StandInit_<year>.INV_PLOT_SIZE = 10 field, which would imply EXPF_HA = 24.7105 instead.
# This discrepancy was noticed but not resolved; flagged as a separate, unrelated open item for
# a future pass rather than silently picking a convention. Changing it would alter every SILC_L
# growth rate in the pipeline, not just the survivor-matching fix this script targets.
#
# Requires: pip install --target=/tmp/pylib access_parser (pure-Python .accdb reader; the
# sandbox has no ODBC driver and no root to install mdbtools).
# Aaron Weiskittel, CRSF. Written 14 Aug 2026.

from access_parser import AccessParser
import pandas as pd

EXPF_HA = 12.3553  # see EXPF convention note above
IN_CM = 2.54

db = AccessParser("SILC CFI.accdb")
years = [1981, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1994, 1995,
         1996, 1997, 1999, 2000, 2001, 2002]  # 1982 excluded: zero rows in the source table
tabs = {}
for y in years:
    t = db.parse_table(f"CFI_TreeInit_{y}")
    d = pd.DataFrame({k: list(t[k]) for k in ["TREE_ID", "PLOT_ID", "DIAMETER", "SPECIES", "HISTORY"]})
    d = d[d["HISTORY"] == 1].copy()  # live trees only (HISTORY==6 is cut/removed)
    d["PLOT_ID"] = d["PLOT_ID"].astype(int)
    tabs[y] = d

pr = pd.read_csv("bench_silc_l_pairs_full137.csv")
pr["PLOTID"] = pr["STAND"].str.replace("^SILC", "", regex=True).str.split("_").str[0].astype(int)
pr["Y1"] = pr["STAND"].str.split("_").str[1].astype(int)
pr["Y2"] = pr["STAND"].str.split("_").str[2].astype(int)

results = []
sp_mismatch_total = 0
pairs_total = 0
for _, row in pr.iterrows():
    plotid, y1, y2, stand = row["PLOTID"], row["Y1"], row["Y2"], row["STAND"]
    t1 = tabs[y1][tabs[y1]["PLOT_ID"] == plotid][["TREE_ID", "DIAMETER", "SPECIES"]]
    t2 = tabs[y2][tabs[y2]["PLOT_ID"] == plotid][["TREE_ID", "DIAMETER", "SPECIES"]]
    if len(t1) == 0 or len(t2) == 0:
        results.append(dict(STAND=stand, n_pairs=0, dsf=0.0, dsl=0.0, n_sp_mismatch=0))
        continue
    mt = t1.merge(t2, on="TREE_ID", suffixes=("_1", "_2"))
    if len(mt) == 0:
        results.append(dict(STAND=stand, n_pairs=0, dsf=0.0, dsl=0.0, n_sp_mismatch=0))
        continue
    mt["D1cm"] = mt["DIAMETER_1"] * IN_CM
    mt["D2cm"] = mt["DIAMETER_2"] * IN_CM
    mt["dba"] = EXPF_HA * 0.00007854 * (mt["D2cm"] ** 2 - mt["D1cm"] ** 2)
    n_mismatch = int((mt["SPECIES_1"] != mt["SPECIES_2"]).sum())
    sp_mismatch_total += n_mismatch
    pairs_total += len(mt)
    dsl = mt.loc[mt["D1cm"] >= 12.7, "dba"].sum()
    results.append(dict(STAND=stand, n_pairs=len(mt), dsf=mt["dba"].sum(), dsl=dsl, n_sp_mismatch=n_mismatch))

res = pd.DataFrame(results)
print("stands with >=1 corrected survivor pair:", (res["n_pairs"] > 0).sum(), "of", len(res))
print("total corrected survivor pairs:", res["n_pairs"].sum())
print("species mismatch on corrected pairs: %.2f%%" % (100 * sp_mismatch_total / max(pairs_total, 1)))
res.to_csv("p17_silc_corrected_survivor_sums.csv", index=False)
