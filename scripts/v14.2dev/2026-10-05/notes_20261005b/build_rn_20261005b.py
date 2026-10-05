# Release notes, second 5 October 2026 revision, built on the first (0aaa6b6b) by exact replacements, each asserted once.
# Adds PREREG43 addendum 3 and the PREREG45 draft. No em dashes.
import sys
src, out = sys.argv[1], sys.argv[2]; t = open(src).read()
def R(a, b):
    global t
    assert t.count(a) == 1, ("not once", a[:80], t.count(a)); t = t.replace(a, b)
R("Draft of October 5, 2026,", "Draft of October 5, 2026 (second revision that day),")
R("set by hand from a July 2026 stand level top height diagnostic (PREREG43).", "set by hand from the rounded console output of a July 2026 stand level top height diagnostic (PREREG43).")
R("The printed ratio implies 0.112, and the small gap is unexplained because the unrounded diagnostic output was not read.",
  "Addendum 3 read the diagnostic's output file: the unrounded ratio is 8.888861 (2,472 stands), whose inverse is 0.1125, and the New Brunswick inverse is 0.5772, not 0.579, so neither shipped value is the inverse of its ratio. Both equal the ratio of the two means as printed to three decimals (0.018 / 0.162 = 0.111 and 0.135 / 0.233 = 0.579), so they were most likely computed by hand from rounded console output; this reading was not preregistered.")
R("- The QC height increment form for 14.3, since from measured stand lists 0.111 stalls top height and 1.242 lets it rise to 1.5 times ESI and still climbing at 100 years (PREREG44).\n",
  "- The QC height increment form for 14.3, since from measured stand lists 0.111 stalls top height and 1.242 lets it rise to 1.5 times ESI and still climbing at 100 years (PREREG44). PREREG37 already shows why: on field tags observed over predicted increment falls from 1.655 below HT/ESI 0.5 to 0.523 at 1 to 1.25, while the coded `dht` has no relative height term. A PREREG45 draft proposes a relative height multiplier and awaits a decision to open 14.3 work.\n")
R("- The unrounded Quebec increment ratio behind 0.111 (`topht_recal_diag.csv` on Cardinal), which would settle the 0.111 against 0.112 gap (PREREG43 addendum 2).\n", "")
R("| printed ratio 8.89, inverse 0.112 | 2026-10-05_v142_qc-anchor-0111-provenance_RESULT.md and _RESULT_addendum2.md |",
  "| ratio 8.888861; 0.111 = 0.018 / 0.162 as printed | 2026-10-05_v142_qc-anchor-0111-provenance_RESULT.md, _RESULT_addendum2.md and _RESULT_addendum3.md |")
R("599c16a4 (PREREG43 and the PREREG44 draft) and the commit after 599c16a4 (PREREG43 addendum 2, PREREG44 and this revision of the notes).",
  "599c16a4 (PREREG43 and the PREREG44 draft), c4c2a572 (PREREG43 addendum 2, PREREG44 and the first 5 October notes) and the commit after c4c2a572 (PREREG43 addendum 3, the PREREG45 draft and this revision of the notes).")
R("| Where the shipped QC anchor 0.111 came from (records only, with addendum 2) | No fit of 0.111 itself; set by hand as the inverse of a stand level increment ratio |",
  "| Where the shipped QC anchor 0.111 came from (records only, with addenda 2 and 3) | No fit of 0.111 itself; set by hand from the rounded printed means of a stand level increment diagnostic |")
assert chr(0x2014) not in t
open(out, "w").write(t); print("words", len(t.split()))
