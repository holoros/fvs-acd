# Release notes, 2 October 2026 revision: content inventory diff against the 1 October draft

Prior version `v142notes/2026-10-01_fvs-acd-v14.2_release-notes_DRAFT.md` (ca15b9b1, untouched). New version
`2026-10-02_fvs-acd-v14.2_release-notes_DRAFT.md` (b996b648), built by `build_rn_20261002.py` and `build_rn_20261002b.py`
(exact replacements, each asserted once); first build kept as `_PREV_20261002` (90bed049). Line diff
`2026-10-02_release-notes_r20261001_to_r20261002b.diff`. Sections 12 and 12; study table rows 23 to 28; words 3,133 to
3,826. No em dashes.

## Added

Study table rows PREREG38 to PREREG42. In the QC section, a paragraph on PREREG38 to PREREG41 (field tag anchor 1.242, the TOPHT
decomposition, the measured height gate and its unverified 10% limit, the matched tree check) and a paragraph on the close out
with 0.111 kept, its known bias, and PREREG19 revision 3. The PREREG42 erratum reading in the PREREG23 and PREREG28 to 33
sentences. The PREREG41 grid in the Bakuzis section. Open items: a Bakuzis QC grid from measured stand lists; confirmation of
the FIA length MQO. Commits 01998dd8, 09c6bfa3, 2693d895 and a03a7702 and the 1.8.0 sentence in Reproducibility.

## Changed

Title and dates (to PREREG42, 2 October). Bottom line: the QC anchor is closed with 0.111 kept instead of open. PREREG19 is cited
at revision 3 instead of revision 2 (text and table). The QC candidate bullet now states the decision and the gates 1.242 passes
and fails. PREREG23 and PREREG37 table rows qualified (erratum, not reopened; refit done). The 1 October notes are named as such
where "these notes" referred to them.

## Removed, and why

Open item "The PREREG36 search ... did not cover the height tag key": resolved by PREREG42. Open item "A revision of the PREREG19
correction note": resolved by revision 3. Open item "A field tag refit of QC_AFAC": done in PREREG38, replaced by the measured
stand list grid item. Clauses "These notes treat the QC height anchor as open", "and the QC anchor awaits a field tag refit"
and "so they bound what those anchors do and say nothing yet about a field tag anchor": superseded by PREREG38 to 42. The trace row
"October 1, 2026" (date of the prior draft) and the PREREG19 revision 2 source row for 11,632 (now traced to PREREG42).

## Checks

Number trace 204 rows, every number present in the draft and found on its source line; an independent check of the first build
(`check_20261002/2026-10-02_release-notes_CHECK_DATA.csv`) found 205 of 205 present, one wrong source line (0.898, fixed to
line 28) and seven wording items (two optional), all applied in revision b.
