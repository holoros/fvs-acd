# Number trace for the third 5 October revision: carry rows of the second revision's trace that still appear, add new numbers. No em dashes.
import csv, os
J = "/home/aaron/jobs"; D = f"{J}/v142notes_20261005c"; NEW = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md"
OLD = f"{J}/v142notes_20261005b/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_r20261005b_DATA.csv"; OUT = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_r20261005c_DATA.csv"
assert not os.path.exists(OUT)
txt = open(NEW).read(); rows = list(csv.DictReader(open(OLD, newline=""))); keep = [r for r in rows if r["number_as_written"] in txt]; gone = [r for r in rows if r["number_as_written"] not in txt]
R = f"{J}/v142p45/2026-10-05_v142_qc-relht-increment_RESULT.md"; ZP = f"{J}/gh_v142/zen_publish_180.log"; P45 = f"{J}/gh_v142/push_v142_p45.json"
NEWN = [("0.9595", "fit a", R, "0.9595"), ("-1.1239", "fit b", R, "-1.1239"), ("1.97", "m at r 0.25", R, "1.97"), ("0.74", "m at r 1.125", R, "0.74"), ("698", "fold A field tag survivors", R, "698"),
 ("1.003 (0.897 to 1.143)", "fold B pooled ratio qc_rh", R, "1.003 (0.897 to 1.143)"), ("-0.014", "25 cm and over class bias", R, "-0.014"), ("+0.030", "worst relht bin bias", R, "+0.030"),
 ("+14.14%", "TOPHT bias qc_rh", R, "+14.14%"), ("0.980", "dominant cohort level qc_rh", R, "0.980"), ("1.163", "median HT/ESI at 50 years", R, "1.163"), ("1.309", "median HT/ESI at 100 years", R, "1.309"),
 ("1.175", "measured frontier bound", R, "1.175"), ("32 of 36", "stands over the bound", R, "32 of 36"), ("9 stands against 36", "HT monotone flags", R, "9 stands against 36"),
 ("10.5281/zenodo.23168366", "1.8.0 version DOI", ZP, "10.5281/zenodo.23168366"), ("7bbe6615", "commit, addendum 3, PREREG45 draft, second notes", P45, "7bbe6615")]
add, bad = [], []
for num, mean, src, pat in NEWN:
    L = open(src).read().splitlines(); hit = [i + 1 for i, l in enumerate(L) if pat in l]
    if num not in txt or not hit: bad.append((num, num in txt, bool(hit))); continue
    add.append({"number_as_written": num, "meaning": mean, "source_file": src, "source_line": str(hit[0])})
with open(OUT, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["number_as_written", "meaning", "source_file", "source_line"]); w.writeheader(); w.writerows(keep + add)
print("carried", len(keep), "of", len(rows), "; added", len(add), "; problems", bad); print("gone:", [r["number_as_written"] for r in gone])
