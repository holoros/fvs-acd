# Number trace for the second 5 October revision: carry rows of the first revision's trace that still appear, add new numbers. No em dashes.
import csv, os
J = "/home/aaron/jobs"; D = f"{J}/v142notes_20261005b"; NEW = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md"
OLD = f"{J}/v142notes_20261005/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_DATA.csv"; OUT = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_r20261005b_DATA.csv"
assert not os.path.exists(OUT)
txt = open(NEW).read(); rows = list(csv.DictReader(open(OLD, newline="")))
keep = [r for r in rows if r["number_as_written"] in txt]; gone = [r for r in rows if r["number_as_written"] not in txt]
A3 = f"{J}/v142p43/2026-10-05_v142_qc-anchor-0111-provenance_RESULT_addendum3.md"; P37 = f"{J}/v142p37/2026-10-01_v142_qc-height-structure_RESULT.md"
NEWN = [("8.888861", "unrounded QC ratio of mean predicted to mean observed increment", A3, "8.888861"), ("2,472 stands", "QC stands in the diagnostic file", A3, "2,472"),
 ("0.1125", "inverse of the unrounded QC ratio", A3, "0.112500"), ("0.5772", "inverse of the unrounded NB ratio (0.577179)", A3, "0.577179"),
 ("0.018 / 0.162", "QC printed means, ratio 0.111", A3, "0.018 / 0.162"), ("0.135 / 0.233", "NB printed means, ratio 0.579", A3, "0.135 / 0.233"),
 ("1.655", "field tag R below HT/ESI 0.5, fold B", P37, "1.655"), ("0.523", "field tag R at HT/ESI 1 to 1.25, fold B", P37, "0.523"),
 ("c4c2a572", "commit, PREREG43 addendum 2, PREREG44, first 5 October notes", f"{J}/gh_v142/push_v142_p44.json", "c4c2a572")]
add, bad = [], []
for num, mean, src, pat in NEWN:
    L = open(src).read().splitlines(); hit = [i + 1 for i, l in enumerate(L) if pat in l]
    if num not in txt or not hit: bad.append((num, num in txt, bool(hit))); continue
    add.append({"number_as_written": num, "meaning": mean, "source_file": src, "source_line": str(hit[0])})
with open(OUT, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["number_as_written", "meaning", "source_file", "source_line"]); w.writeheader(); w.writerows(keep + add)
print("carried", len(keep), "of", len(rows), "; added", len(add), "; problems", bad); print("gone:", [r["number_as_written"] for r in gone])
