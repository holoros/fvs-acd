# Number trace for the 2 October release notes revision: carry forward the 1 October trace rows whose number still appears in the
# draft, report those that no longer appear, and add a row for every new number with the first source line that contains it.
# No em dashes.
import csv, os
J = "/home/aaron/jobs"; NEW = f"{J}/v142notes_20261002/2026-10-02_fvs-acd-v14.2_release-notes_DRAFT.md"
OLD = f"{J}/v142notes/2026-10-01_fvs-acd-v14.2_release-notes_NUMBER-TRACE_DATA.csv"; OUT = f"{J}/v142notes_20261002/2026-10-02_fvs-acd-v14.2_release-notes_NUMBER-TRACE_DATA.csv"
assert not os.path.exists(OUT)
txt = open(NEW).read()
rows = list(csv.DictReader(open(OLD, newline="")))
keep = [r for r in rows if r["number_as_written"] in txt]; gone = [r for r in rows if r["number_as_written"] not in txt]
R38 = f"{J}/v142p38/2026-10-01_v142_qc-anchor-fieldtag-refit_RESULT.md"; R39 = f"{J}/v142p39/2026-10-02_v142_topht-gate-decomposition_RESULT.md"
R40 = f"{J}/v142p40/2026-10-02_v142_topht-measured-gate_RESULT.md"; R41 = f"{J}/v142p41/2026-10-02_v142_bakuzis-qc-p38fit_RESULT.md"
R42 = f"{J}/v142p42/2026-10-02_v142_rowindex-erratum_RESULT.md"; ER = f"{J}/v142p42/2026-10-02_v142_rowindex-gates_ERRATUM.md"; CO = f"{J}/v142p42/2026-10-02_v142_qc-anchor_CLOSEOUT.md"
G = f"{J}/gh_v142"
NEWN = [("October 2, 2026", "date of PREREG40 to 42 and of this revision", R42, "2 October 2026"),
 ("PREREG42", "latest study", R42, "PREREG42"),
 ("1.242", "field tag single QC anchor, fold A fit", R38, "1.242"),
 ("1.053", "fold B pooled predicted over observed height increment at 1.242", R38, "1.053"),
 ("0.093", "same at 0.111", R38, "0.093"),
 ("0.04", "class bias bound at 1.242, m yr-1", R38, "0.04 m"),
 ("0.994", "dominant cohort t2 level at 1.242", R38, "0.994"),
 ("0.898", "dominant cohort t2 level at 0.111", R38, "0.898"),
 ("+16.21%", "published TOPHT bias at 1.242", R38, "+16.21"),
 ("+14.63%", "TOPHT limit, frozen 1.061 arm", R38, "+14.63"),
 ("60.6%", "share of observed TOPHT heights from himp", R39, "60.6"),
 ("0.892", "himp over measured height, measured trees of the TOPHT set", R39, "0.892"),
 ("9.29", "points carried by the observed height step at 1.242", R39, "9.29"),
 ("16.78", "TOPHT minus dominant cohort gap at 1.242", R39, "16.78"),
 ("10%", "PREREG40 ceiling, FIA length MQO, unverified", R40, "10 percent"),
 ("+1.60%", "B_M at 1.242", R40, "+1.60"),
 ("-0.05 to 3.25", "B_M interval at 1.242", R40, "-0.05 to 3.25"),
 ("-8.45%", "B_M at 0.111", R40, "-8.45"),
 ("+1.50%", "matched tree B_MM at 1.242", R41, "+1.50"),
 ("-8.82%", "matched tree B_MM at 0.111", R41, "-8.82"),
 ("1.490", "PREREG41 Reineke worst margin, 1.242", R41, "1.490"),
 ("1,000", "seeded stems ha-1 at N0 1,000 start of ingrowth rise", R41, "1,000"),
 ("2,800", "stems ha-1 after ingrowth", R41, "2,800"),
 ("2.5 m", "span of QC ESI levels", R41, "2.5 m"),
 ("0.108", "PREREG23 25 cm class better than 0.111 under field tags, m yr-1", ER, "0.108"),
 ("0.90", "dominant cohort t2 level at 0.111, rounded", CO, "0.90 of measured"),
 ("8 to 9%", "measured top height deficit at 0.111", CO, "8 to 9 percent"),
 ("11,632", "row index tag matches, 378 RUN_OK qc_c stands", R42, "11,632"),
 ("1,569", "same species with measured t2 height, row index", R42, "1,569"),
 ("378", "qc_c stands with RUN_OK 1", R42, "378"),
 ("10,226", "field tag matches", R42, "10,226"),
 ("2,299", "same species with measured t2 height, field tags", R42, "2,299"),
 ("01998dd8", "commit, PREREG38 and 39", f"{G}/push_v142_p38p39.log", "01998dd8"),
 ("09c6bfa3", "commit, PREREG40", f"{G}/push_v142_p40.log", "09c6bfa3"),
 ("2693d895", "commit, PREREG41", f"{G}/push_v142_p41.log", "2693d895"),
 ("a03a7702", "commit, PREREG42", f"{G}/push_v142_p42.log", "a03a7702")]
add, bad = [], []
for num, mean, src, pat in NEWN:
    L = open(src).read().splitlines(); hit = [i + 1 for i, l in enumerate(L) if pat in l]
    if num not in txt or not hit: bad.append((num, num in txt, bool(hit))); continue
    add.append({"number_as_written": num, "meaning": mean, "source_file": src, "source_line": str(hit[0])})
with open(OUT, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["number_as_written", "meaning", "source_file", "source_line"]); w.writeheader(); w.writerows(keep + add)
print("carried", len(keep), "of", len(rows), "; added", len(add), "; problems", bad)
print("no longer in the draft:", [r["number_as_written"] + " (" + r["meaning"][:60] + ")" for r in gone])
