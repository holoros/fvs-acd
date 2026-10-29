# Release notes, 5 October 2026 revision: content inventory diff against the 2 October draft

Prior version `v142notes_20261002/2026-10-02_fvs-acd-v14.2_release-notes_DRAFT.md` (b996b648, untouched). New version
`2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md` (0aaa6b6b), built by `build_rn_20261005.py` with
`build_rn_20261005_p44text.json` (exact replacements, each asserted once). The first build (124808c6) is kept as
`_PREV_20261005` and was revised after an independent check. Line diff `2026-10-05_release-notes_r20261002_to_r20261005.diff`.
Sections 12 and 12; study table rows 28 to 30; words 3,826 to 4,327. No em dashes.

## Added

A QC section paragraph on PREREG43 and its addendum 2 (no fit of 0.111; set by hand on 4 July 2026 from the inverse of the
8.89 stand level increment ratio printed by `topht_recal_diag.R`, which implies 0.112; carried through the v12.10.1 freeze).
A Bakuzis section paragraph on PREREG44 (measured stand list grid, not cleared, top height 17.29 m against 28.01 m at 100
years). Bottom line sentences on both. A PREREG44 sentence in the QC candidate bullet. Open items: the QC height increment
form for 14.3; the unrounded Quebec ratio on Cardinal. Study table rows PREREG43 and PREREG44. Commits c818b99c and 599c16a4
and the commit after 599c16a4 in Reproducibility. A confirmation record for the FIA length MQO
(`2026-10-05_fia-length-mqo_CONFIRMATION.md`).

## Changed

Title and dates (to PREREG44, 5 October). The 10% FIA tree length MQO is stated as confirmed (bottom line, PREREG40 paragraph,
PREREG40 table row, number trace row). The 1.8.0 sentence now covers PREREG38 to PREREG44. The QC candidate bullet names the
PREREG41 grid as the seedling start grid. The commit list ends with commas instead of a closing "and".

## Removed, and why

Open item "A Bakuzis QC grid started from measured qc_c stand lists": done in PREREG44, replaced by the height increment form
item. Open item "Confirmation of the FIA ... MQO": confirmed by Aaron on 5 October. Clauses "whose 10% limit is still to be
confirmed", "a value still to be confirmed", "both readings conditional on the unconfirmed limit" and "(limit unverified)":
superseded by the confirmation. Trace row "October 2, 2026" (date of the prior draft).

## Checks

Number trace 236 rows (203 carried of 204, 33 added; one, v12.10.1, added by hand after the script looked in the wrong file).
Independent check of the first build: every PREREG43 and PREREG44 number re-derived and correct; three overstatements, one
dropped "and" and missing trace rows were found and fixed in this build. Rendered to PDF (9 pages) and inspected.
