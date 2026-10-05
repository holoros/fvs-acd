# Number trace for the fourth 5 October revision: carry rows of the third revision's trace that still appear, add new numbers. No em dashes.
import csv, os
J = "/home/aaron/jobs"; D = f"{J}/v142notes_20261005d"; NEW = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md"
OLD = f"{J}/v142notes_20261005c/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_r20261005c_DATA.csv"; OUT = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_r20261005d_DATA.csv"
assert not os.path.exists(OUT)
txt = open(NEW).read(); rows = list(csv.DictReader(open(OLD, newline=""))); keep = [r for r in rows if r["number_as_written"] in txt]; gone = [r for r in rows if r["number_as_written"] not in txt]
R2 = f"{J}/v142p45/2026-10-05_v142_qc-relht-increment_RESULT.md"; RB = f"{J}/v142p45b/2026-10-05_v142_nb-relht-increment-standlevel_RESULT.md"; P = f"{J}/gh_v142/push_v142_p45run.json"
NEWN = [("7.8e-15", "ST1 worst difference", R2, "7.8e-15"), ("1.205", "ST2 median offset removed", R2, "1.205"), ("24 of 36", "ST2 stands over", R2, "24 of 36"),
 ("1.239", "ST3 low b median", R2, "1.239"), ("1.378", "ST3 high b median", R2, "1.378"), ("1.9 m", "engine first year jump (1.90 m median)", R2, "1.90 m"),
 ("58 trees", "fold A trees at r 1 or more", R2, "58 trees"), ("-2.19", "NB fit b", RB, "-2.1924"), ("-11.0 to 1.06", "NB b interval", RB, "-11.0 to 1.06"),
 ("0.556 (0.403 to 0.835)", "NB fold B pooled ratio", RB, "0.556 (0.403 to 0.835)"), ("0.281", "nb141 pooled ratio", RB, "0.281"), ("+1.04%", "nb141 TOPHT bias", RB, "+1.04%"),
 ("a factor of 1.7", "fold A against fold B observed increment", RB, "factor of 1.7"), ("70 fold A stands", "NB fit population", RB, "70 stands"), ("a666987c", "commit, PREREG45 and third notes", P, "a666987c")]
add, bad = [], []
for num, mean, src, pat in NEWN:
    L = open(src).read().splitlines(); hit = [i + 1 for i, l in enumerate(L) if pat in l]
    if num not in txt or not hit: bad.append((num, num in txt, bool(hit))); continue
    add.append({"number_as_written": num, "meaning": mean, "source_file": src, "source_line": str(hit[0])})
with open(OUT, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["number_as_written", "meaning", "source_file", "source_line"]); w.writeheader(); w.writerows(keep + add)
print("carried", len(keep), "of", len(rows), "; added", len(add), "; problems", bad); print("gone:", [r["number_as_written"] for r in gone])
