# Release notes, 5 October 2026 revision, built on the 2 October draft (b996b648) by exact replacements, each asserted to
# occur once. PREREG44 text is read from p44.json (filled from the PREREG44 RESULT). No em dashes.
import json, sys
src, out = sys.argv[1], sys.argv[2]; P = json.load(open(sys.argv[3]))
t = open(src).read()
def R(a, b):
    global t
    assert t.count(a) == 1, ("not once", a[:80], t.count(a)); t = t.replace(a, b)
R("release notes for PREREG16 to PREREG42", "release notes for PREREG16 to PREREG44")
R("Draft of October 2, 2026,", "Draft of October 5, 2026,")
R("From September 27 to October 2, 2026, the 14.2 refinement work ran the preregistered studies PREREG16 to PREREG42 (with PREREG28b)",
  "From September 27 to October 5, 2026, the 14.2 refinement work ran the preregistered studies PREREG16 to PREREG44 (with PREREG28b)")
R("passes a top height gate on measured heights whose 10% limit is still to be confirmed, but",
  "passes a top height gate on measured heights against the 10% FIA measurement quality objective for tree length, but")
R("are corrected by an erratum (PREREG42).",
  "are corrected by an erratum (PREREG42). The origin of 0.111 is now traced: no record fits it, and it was set by hand from a July 2026 stand level top height diagnostic (PREREG43). " + P["bottom"])
R("PREREG40 rebuilt the top height gate on measured heights against a 10% ceiling taken from the FIA field measurement tolerance for tree length, a value still to be confirmed:",
  "PREREG40 rebuilt the top height gate on measured heights against a 10% ceiling, the FIA field guide measurement quality objective for tree length (confirmed October 5, 2026):")
R(" (+1.50% and -8.82%), both readings conditional on the unconfirmed limit. The ceiling is loose,",
  " (+1.50% and -8.82%). The ceiling is loose,")
R("field tags give 10,226 (2,299).",
  "field tags give 10,226 (2,299).\n\n"
  "PREREG43 and its addendum 2 traced where 0.111 came from. Two independent searches of 42,671 files on the analysis host, the reachable Cardinal folders and the `holoros/fvs-acd` history up to July 10, 2026 (63 commits) found no record that fits 0.111. The repository VERSION_HISTORY places it in the AcadianGY 12.9.2 operations recipe. A July 2 diagnostic on v12.7.0 output (`topht_recal_diag.R`, commit a259273d) printed the Quebec ratio of mean predicted to mean observed stand top height increment as 8.89, and a July 4 v12.10.1 stress test note (commit 4af1b2da) set the Quebec increment scale to the observed over predicted ratio, 0.111, without a computation. The printed ratio implies 0.112, and the small gap is unexplained because the unrounded diagnostic output was not read. 0.111 is therefore an operations setting from a stand level top height correction, carried unchanged through the v12.10.1 freeze into 14.1, and not a value fitted on QC tag pairs. The 14.2 decision does not change.")
R("This verdict does not depend on the PREREG40 limit.", "This verdict does not depend on the PREREG40 limit.\n\n" + P["bakuzis"])
R("passes the PREREG38 height increment gates and the PREREG40 measured top height gate (limit unverified), but fails the PREREG38 published TOPHT gate and does not clear the Bakuzis QC grid (PREREG41), and the track is closed (PREREG42 close out note).",
  "passes the PREREG38 height increment gates and the PREREG40 measured top height gate, but fails the PREREG38 published TOPHT gate and does not clear the seedling start Bakuzis QC grid (PREREG41), and the track is closed (PREREG42 close out note). " + P["candidate"])
R("- A Bakuzis QC grid started from measured qc_c stand lists rather than a seedling cohort, to test the field tag anchor 1.242 where the benchmark supports it (PREREG41).\n", P["open_grid"])
R("- Confirmation of the FIA field guide measurement quality objective for tree length (10%) used as the PREREG40 top height ceiling.\n",
  "- The unrounded Quebec increment ratio behind 0.111 (`topht_recal_diag.csv` on Cardinal), which would settle the 0.111 against 0.112 gap (PREREG43 addendum 2).\n")
R("and a03a7702 (PREREG42, the erratum, the PREREG19 revision 3 and the QC close out note); this revision of the notes is added in the commit after a03a7702.",
  "a03a7702 (PREREG42, the erratum, the PREREG19 revision 3 and the QC close out note), " + P["commit_rn1002"] + " (the 2 October notes), 599c16a4 (PREREG43 and the PREREG44 draft) and " + P["commit_p44"] + " (PREREG43 addendum 2, PREREG44 and this revision of the notes).")
R("Version 1.8.0, which adds PREREG38 to PREREG42 and this revision, receives its DOI when published.",
  "Version 1.8.0, which adds PREREG38 to PREREG44 and this revision, receives its DOI when published.")
R("| PREREG42 | Erratum for the row index height gates, PREREG19 revision 3, QC close out | PREREG23 Rule 3 to Rule 6, others unchanged; 0.111 kept | 11,632 (1,569) row index against 10,226 (2,299) field tags | 2026-10-02_v142_rowindex-erratum_RESULT.md |",
  "| PREREG42 | Erratum for the row index height gates, PREREG19 revision 3, QC close out | PREREG23 Rule 3 to Rule 6, others unchanged; 0.111 kept | 11,632 (1,569) row index against 10,226 (2,299) field tags | 2026-10-02_v142_rowindex-erratum_RESULT.md |\n"
  "| PREREG43 | Where the shipped QC anchor 0.111 came from (records only, with addendum 2) | No fit found; set by hand as the inverse of a stand level increment ratio | printed ratio 8.89, inverse 0.112 | 2026-10-05_v142_qc-anchor-0111-provenance_RESULT.md and _RESULT_addendum2.md |\n" + P["row"])
R("| 1.242 within the 10% ceiling (limit to be confirmed) |", "| 1.242 within the 10% ceiling (FIA length MQO, confirmed October 5) |")
assert "—" not in t
open(out, "w").write(t); print("words", len(t.split()))
