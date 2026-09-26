import csv, time, json
from collections import Counter
from access_parser import AccessParser

SRC = "AcadianGrowthModel_v8.40_SILCcfi_byStrata_noHTdub.mdb"
t0 = time.time()

pairs = []
with open("silc_cfi_longhorizon_pairs_v16.csv") as f:
    r = csv.DictReader(f)
    for row in r:
        pairs.append(row)
plot_key = "PLOT" if "PLOT" in pairs[0] else list(pairs[0].keys())[0]
yprev_key = [k for k in pairs[0].keys() if "YEAR_PREV" in k.upper()][0]
expected = {}
for row in pairs:
    plot = int(float(row[plot_key]))
    yprev = int(float(row[yprev_key]))
    standid = plot*10000 + yprev
    expected[standid] = plot
print(f"[+{time.time()-t0:.1f}s] {len(expected)} expected StandIDs from {len(pairs)} pairs", flush=True)

db = AccessParser(SRC)
print(f"[+{time.time()-t0:.1f}s] catalog loaded", flush=True)
parsed = db.parse_table("FR_Trees_Final")
cols = list(parsed.keys())
nrow = len(parsed[cols[0]])
print(f"[+{time.time()-t0:.1f}s] FR_Trees_Final parsed: {nrow} rows, {len(cols)} cols", flush=True)

hist_counts = Counter(parsed.get("HISTORY", []))
print(f"[+{time.time()-t0:.1f}s] HISTORY value counts (full table, {len(hist_counts)} distinct)", flush=True)

standid_col = parsed["STAND_ID"]
distinct_standid_total = len(set(standid_col))
print(f"[+{time.time()-t0:.1f}s] distinct STAND_ID (full table): {distinct_standid_total}", flush=True)

# Precompute column lists ONCE (bug fix: the previous run called
# parsed.get(key, [None]*nrow) INSIDE the row loop, so Python evaluated the
# [None]*nrow default on every single iteration regardless of whether the key
# was found -- an accidental O(n^2) that never finished. Fixed by building
# each needed column list a single time before the loop.
NA = [None]*nrow
c_year        = parsed["Year"]
c_treenum     = parsed.get("TreeNumber", NA)
c_recnum      = parsed.get("RecordNum", NA)
c_species     = parsed["SPECIES"]
c_diameter    = parsed["DIAMETER"]
c_ht          = parsed["HT"]
c_expf        = parsed["EXPF"]
c_mortexpf    = parsed.get("MortEXPF", NA)
c_mortba      = parsed.get("MortBA", NA)
c_history     = parsed.get("HISTORY", NA)
c_productcode = parsed.get("ProductCode", NA)
c_origdbh     = parsed.get("origDBH", NA)
c_ismetric    = parsed.get("isMetric", NA)

out_cols = ["STAND_ID","PLOT","Year","TreeNumber","RecordNum","SPECIES","DIAMETER","HT",
            "EXPF","MortEXPF","MortBA","HISTORY","ProductCode","origDBH","isMetric"]
matched_standids = set()
out_rows = []
for i in range(nrow):
    try:
        sid = int(standid_col[i])
    except (TypeError, ValueError):
        continue
    plot = expected.get(sid)
    if plot is None:
        continue
    matched_standids.add(sid)
    out_rows.append({
        "STAND_ID": sid, "PLOT": plot, "Year": c_year[i],
        "TreeNumber": c_treenum[i], "RecordNum": c_recnum[i],
        "SPECIES": c_species[i], "DIAMETER": c_diameter[i], "HT": c_ht[i],
        "EXPF": c_expf[i], "MortEXPF": c_mortexpf[i], "MortBA": c_mortba[i],
        "HISTORY": c_history[i], "ProductCode": c_productcode[i],
        "origDBH": c_origdbh[i], "isMetric": c_ismetric[i],
    })

print(f"[+{time.time()-t0:.1f}s] matched {len(out_rows)} rows across {len(matched_standids)} of {len(expected)} expected StandIDs", flush=True)
missing = sorted(set(expected.keys()) - matched_standids)
if missing:
    print(f"[+{time.time()-t0:.1f}s] {len(missing)} expected StandIDs NOT FOUND: {[(s, expected[s]) for s in missing]}", flush=True)

with open("agm_v840_frtrees_filtered.csv","w",newline="") as f:
    w = csv.DictWriter(f, fieldnames=out_cols)
    w.writeheader()
    w.writerows(out_rows)
print(f"[+{time.time()-t0:.1f}s] wrote agm_v840_frtrees_filtered.csv ({len(out_rows)} rows)", flush=True)

hist_matched = Counter(r["HISTORY"] for r in out_rows)
report = {
    "total_rows": nrow, "total_cols": len(cols), "all_cols": cols,
    "history_counts_full_table": {str(k): v for k,v in hist_counts.items()},
    "distinct_standid_total": distinct_standid_total,
    "n_expected_standids": len(expected),
    "n_matched_standids": len(matched_standids),
    "missing_standids": [(s, expected[s]) for s in missing],
    "matched_rows": len(out_rows),
    "history_counts_matched_subset": {str(k): v for k,v in hist_matched.items()},
}
with open("agm_v840_extract_report.json","w") as f:
    json.dump(report, f, indent=2, default=str)
print(f"[+{time.time()-t0:.1f}s] ALL DONE", flush=True)
