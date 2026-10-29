# Release notes, fourth 5 October 2026 revision: content inventory diff against the third

Prior `v142notes_20261005c/2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md` (97cbc465, untouched; copied as
`prior_97cbc465.md`). New `2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md` (be315202), built by `build_rn_20261005d.py`
(exact replacements, each asserted once). Sections 12 and 12; study table rows 31 to 32; words 4,908 to 5,304. No em dashes.

## Added

Bottom line: the stress tests confirm PREREG45, and PREREG45b is not adopted. QC section: a paragraph on PREREG45 revision 2
(red team, ST1 to ST4) and a paragraph on PREREG45b (fit, fold B gate, why the NB target is too noisy, NB stays at 0.579). A
PREREG45b row in the study table. Commit a666987c in Reproducibility.

## Changed

Title and scope (to PREREG45b). Date line (fourth revision that day). The QC candidate bullet adds PREREG45b. The open item on
the QC form replaces the pending NB choice with its result. The PREREG45 study table row names revision 2. Version 1.9.0 now
also covers PREREG45b and the stress tests.

## Removed, and why

"An NB arm was chosen but not run, since NB tree numbers are not stable tags and the field tag fit cannot be applied": the
arm was then run at stand level (PREREG45b). "The NB arm needs a stand level fit (PREREG45b, pending Aaron's choice)":
resolved.

## Checks

Number trace 277 rows (262 carried of 262, 15 added, no problems).
