# Number trace for the 5 October release notes revision: carry forward the 2 October trace rows whose number still appears,
# report those that no longer appear, and add a row for every new number with the first source line that contains it. No em dashes.
import csv, os
J = "/home/aaron/jobs"; D = f"{J}/v142notes_20261005"; NEW = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md"
OLD = f"{D}/2026-10-02_fvs-acd-v14.2_release-notes_NUMBER-TRACE_DATA.csv"; OUT = f"{D}/2026-10-05_fvs-acd-v14.2_release-notes_NUMBER-TRACE_DATA.csv"
assert not os.path.exists(OUT)
txt = open(NEW).read(); rows = list(csv.DictReader(open(OLD, newline="")))
keep = [r for r in rows if r["number_as_written"] in txt]; gone = [r for r in rows if r["number_as_written"] not in txt]
R43 = f"{J}/v142p43/2026-10-05_v142_qc-anchor-0111-provenance_RESULT.md"; A2 = f"{J}/v142p43/2026-10-05_v142_qc-anchor-0111-provenance_RESULT_addendum2.md"
EV = f"{J}/v142p43/search_c/evidence_4af1b2da_20260704_v12101_stress_and_parity.md"; R44 = f"{J}/v142p44/2026-10-05_v142_bakuzis-qc-standlists_RESULT.md"; G = f"{J}/gh_v142"
NEWN = [("October 5, 2026", "date of PREREG43 addendum 2, PREREG44 and this revision", R44, "5 October 2026"),
 ("PREREG44", "latest study", R44, "PREREG44"), ("PREREG43", "provenance of 0.111", R43, "PREREG43"),
 ("42,671", "files searched on the analysis host", R43, "42,671"), ("63 commits", "fvs-acd commits to 10 July", A2, "63 commits"),
 ("July 10, 2026", "search horizon, date of earliest SET in revision 1", A2, "10 Jul"), ("July 2", "date of topht_recal_diag.R commit", A2, "2 July 2026"),
 ("July 4", "date of the stress test note setting 0.111", A2, "4 July 2026"), ("8.89", "printed QC predicted over observed increment ratio", EV, "8.89"),
 ("0.112", "rounded inverse of 8.89", A2, "0.112"), ("a259273d", "commit adding topht_recal_diag.R", A2, "a259273d"), ("4af1b2da", "commit of the 4 July note", A2, "4af1b2da"),
 ("v12.7.0", "scorecard the diagnostic read", A2, "v12.7.0"), ("36 fold B", "stands in the PREREG44 grid", R44, "36 fold B"),
 ("1.101", "PREREG44 Reineke worst margin, 1.242", R44, "1.101"), ("0.768", "PREREG44 Reineke worst margin, 0.111", R44, "0.768"),
 ("4.87 m", "largest top height fall, 1.242", R44, "4.87 m"), ("1.04 m", "largest top height fall, 0.111", R44, "1.04 m"),
 ("14.49 m", "mean measured t1 top height", R44, "14.49"), ("17.29 m", "mean top height at 100 years, 0.111", R44, "17.29"),
 ("0.92 of ESI", "top height over ESI at 100 years, 0.111", R44, "| 0.92 |"), ("28.01 m", "mean top height at 100 years, 1.242", R44, "28.01"),
 ("1.50 of ESI", "top height over ESI at 100 years, 1.242", R44, "| 1.50 |"), ("1.5 times ESI", "same, open item wording", R44, "| 1.50 |"),
 ("c818b99c", "commit, 2 October notes", f"{G}/push_v142_rn20261002.json", "c818b99c"), ("599c16a4", "commit, PREREG43 and PREREG44 draft", f"{G}/push_v142_p43.json", "599c16a4")]
add, bad = [], []
for num, mean, src, pat in NEWN:
    L = open(src).read().splitlines(); hit = [i + 1 for i, l in enumerate(L) if pat in l]
    if num not in txt or not hit: bad.append((num, num in txt, bool(hit))); continue
    add.append({"number_as_written": num, "meaning": mean, "source_file": src, "source_line": str(hit[0])})
with open(OUT, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["number_as_written", "meaning", "source_file", "source_line"]); w.writeheader(); w.writerows(keep + add)
print("carried", len(keep), "of", len(rows), "; added", len(add), "; problems", bad)
print("no longer in the draft:", [r["number_as_written"] + " (" + r["meaning"][:60] + ")" for r in gone])
