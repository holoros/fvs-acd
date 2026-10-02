# Revision b of the 2 October release notes: apply the adversarial check fixes (check_20261002). The first build is kept as
# _PREV_20261002. Exact replacements, each asserted once. Also fixes two number trace rows. No em dashes.
import os, shutil, hashlib, csv
D = "/home/aaron/jobs/v142notes_20261002"; F = f"{D}/2026-10-02_fvs-acd-v14.2_release-notes_DRAFT.md"; P = f"{D}/2026-10-02_fvs-acd-v14.2_release-notes_DRAFT_PREV_20261002.md"
T = f"{D}/2026-10-02_fvs-acd-v14.2_release-notes_NUMBER-TRACE_DATA.csv"; TP = f"{D}/2026-10-02_fvs-acd-v14.2_release-notes_NUMBER-TRACE_PREV_20261002_DATA.csv"
assert hashlib.md5(open(F, "rb").read()).hexdigest() == "90bed049788d3437fc2e8b625d8ed80f"; assert not os.path.exists(P) and not os.path.exists(TP)
shutil.copy2(F, P); shutil.copy2(T, TP)
s = open(F).read()
def one(a, b):
    global s
    assert s.count(a) == 1, (s.count(a), a[:80]); s = s.replace(a, b)
one("a field tag anchor (1.242) corrects QC height growth on the benchmark but does not clear",
    "a field tag anchor (1.242) corrects QC height increment on the benchmark and passes a top height gate on measured heights whose 10% limit is still to be confirmed, but it fails the published TOPHT gate and does not clear")
one("These notes use revision 2 of that RESULT, which withdraws its C2 numbers.",
    "These notes use revision 3 of that RESULT, which keeps the revision 2 text, withdraws its C2 numbers and corrects the attribution of its tag match counts (PREREG42).")
one("the 25 cm and over class is better than 0.111 by 0.108 m yr⁻¹ and every gate as PREREG23 coded it passes.",
    "the 25 cm and over class is better than 0.111 by 0.108 m yr⁻¹ and every gate as PREREG23 coded it passes. Under the stricter PREREG38 window (pooled ratio 0.90 to 1.10) 1.061 sits just outside at 0.898, so it was not reopened.")
one("and PREREG41 confirmed the reading on the same trees on both sides (+1.50% and -8.82%).",
    "and PREREG41 found the reading robust to tree selection on the same trees on both sides (+1.50% and -8.82%), both readings conditional on the unconfirmed limit.")
one("but the rule was fixed before the grid was run and is not waived.",
    "but the rule was fixed before the grid was run and is not waived. This verdict does not depend on the PREREG40 limit.")
one("the field tag anchor 1.242 passes the benchmark height gates (PREREG38, PREREG40) but not the Bakuzis QC grid (PREREG41),",
    "the field tag anchor 1.242 passes the PREREG38 height increment gates and the PREREG40 measured top height gate (limit unverified), but fails the PREREG38 published TOPHT gate and does not clear the Bakuzis QC grid (PREREG41),")
one("| Not adopted; under field tags every gate passes (PREREG42 erratum) |", "| Not adopted; under field tags every gate passes (PREREG42 erratum), not reopened |")
one("| Row index artifact; field tag refit is a new track |", "| Row index artifact; field tag refit is a new track (done, PREREG38) |")
open(F, "w").write(s)
rows = list(csv.DictReader(open(TP, newline=""))); n = 0
for r in rows:
    if r["number_as_written"] == "0.898" and r["source_file"].endswith("qc-anchor-fieldtag-refit_RESULT.md"): r["source_line"] = "28"; n += 1
    if r["number_as_written"] == "11,632" and "RESULT_r2" in r["source_file"]:
        r["source_file"] = "/home/aaron/jobs/v142p42/2026-10-02_v142_rowindex-erratum_RESULT.md"; r["meaning"] = "row index tag matches, 378 RUN_OK qc_c stands (corrected attribution)"; n += 1
rows = [r for i, r in enumerate(rows) if not (r["number_as_written"] == "11,632" and any(q["number_as_written"] == "11,632" and q["source_file"] == r["source_file"] for q in rows[:i]))]
L42 = open("/home/aaron/jobs/v142p42/2026-10-02_v142_rowindex-erratum_RESULT.md").read().splitlines()
for r in rows:
    if r["number_as_written"] == "11,632" and r["source_file"].endswith("rowindex-erratum_RESULT.md"): r["source_line"] = str([i + 1 for i, l in enumerate(L42) if "11,632" in l][0])
with open(T, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["number_as_written", "meaning", "source_file", "source_line"]); w.writeheader(); w.writerows(rows)
txt = open(F).read(); miss = [r["number_as_written"] for r in rows if r["number_as_written"] not in txt]
print("trace rows", len(rows), "fixed", n, "missing from draft", miss, "words", len(txt.split())); print("BUILD_RN_B_DONE")
