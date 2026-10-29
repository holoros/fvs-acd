# Release notes revision h against revision g: content inventory diff (28 October 2026)

Revision h (md5 0bec4e79, 9,225 words) was built from revision g (md5 bb36f16a, 8,269 words) by `build_rn_20261028h.py` with
`cfg_rn_h.json`, the same way revision g was built from f, every replacement asserted to match once and the absence of the em
dash asserted. Every number added is copied from the four RESULT r1 files of October 28, 2026: PREREG50 (md5 e3c62336), 14.3
PREREG3 (1ef7f471), 14.3 PREREG4 (ad9402e0) and the Howland decline diagnostic (178d7d14). Each of those RESULTs is revision r1
after an independent read only verification; its earlier text is kept beside it with the suffix `_PREV_20261028b`.

## Added

- Bottom line: a paragraph on PREREG50 (rule 3, artifact; stems deviation 24.2 points low under frozen 14.1 to 1.8 points high
  under E1; explained share 1.0726; labels "previously inspected population" and "threshold support unknown"; S2 7.18 points
  high; ungated fold A replication reads rule 4; survivor ratio 1.0943 unchanged; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579).
- Bottom line: a paragraph on 14.3 PREREG3 (T4 selected on the fit set, open under rule 5, not adopted, 14.3 keeps the 14.1 T),
  14.3 PREREG4 (rule 1, no verdict, H3 failed at 12 of 19 sets against 15; mortality measure invalid; D1 declining shares and
  overshoot) and the Howland decline diagnostic (hindcast not scoreable; mortality share 1.477; linked mortality off removes
  2.545 with a -15.84% shock at year 5; L2 floor hazard supplies most mortality; ALS source ORNL DAAC 2490 v2, not confirmed).
- Current 14.2 candidates, QC: one sentence that PREREG50 places the stems deficit in floor handling, a benchmark and runner
  convention for 14.3, not an engine candidate.
- Open items: PREREG50 reading appended to the QC stems deficit item; 14.3 PREREG3 reading appended to the thinning item;
  14.3 PREREG4 and Howland diagnostic readings appended to the senescence item.
- Reproducibility: the registrations of PREREG50 (6ea850d4), 14.3 PREREG3 (20364c4b), 14.3 PREREG4 (a15bd92a) and the
  Howland decline diagnostic (370f67e2), and where their records are; the commit note for revision h.
- Summary of studies: a row for PREREG50.

## Changed

- Title: PREREG16 to PREREG49 becomes PREREG16 to PREREG50. Date line: revision h of October 28, 2026, built on revision g.
- Reproducibility: "revision g is in the commit after c2d79edd on the same branch" now names revision g's commit, 5a638f9f, and
  adds that revision h is in the commit after 9a5afb37 on the same branch.

## Removed

- Only the phrase "the commit after c2d79edd", replaced by the commit it referred to (5a638f9f). Nothing else was removed; no
  draft row or other text was superseded in the notes.

## Not added

- Summary table rows for 14.3 PREREG3, PREREG4 and the Howland diagnostic: the table indexes the 14.2 refinement studies, and
  the 14.3 studies are covered by a paragraph in the bottom line and by the open items.
- Zenodo: version 1.10.0 does not contain revision h; no new version is staged or published by this revision.

## Render check

No render check PDF was made for revision h. Revision g's PDF was produced by LibreOffice 24.2 Writer (its PDF metadata), and
LibreOffice is not available on OSC Cardinal (no `soffice` or `libreoffice` on the path and no module). Pandoc is available
there; a pandoc parse of revision h to standalone HTML is recorded in `2026-10-28_release-notes_PANDOC-CHECK.txt` as a syntax
check only, not a rendering.

The unified diff is `2026-10-28_release-notes_r20261027g_to_r20261028h.diff`.
