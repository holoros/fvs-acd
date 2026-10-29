# Release notes revision g against revision f: content inventory diff (27 October 2026)

Revision g (md5 bb36f16a, 8,269 words) was built from revision f (md5 08414cbc, 7,481 words) by `build_rn_20261027g.py` with
`cfg_rn_g.json`, every replacement asserted to match once. An independent number check of the new text against the PREREG48,
PREREG49, 14.3 PREREG2 and Howland source files found every value matching and four wordings to fix; all four were fixed before
this build (point values only for the PREREG48 recomputation, the open question on the PREREG49 top height loss, the PREREG49
summary row naming M3 as the rule 2 trigger, and the QC floor range 9.1 to 33.7 cm).

## Added

- Bottom line: a paragraph on PREREG48 (rule 3, ingrowth track, verified, engine ingrowth entering near 5 cm below QC floors),
  PREREG49 (survival step not adopted, v141LTfi not cleared, median 100 year top height loss 15.6%) and 14.3 PREREG2 (C2 not
  adopted under rule 3, 14.3 keeps the 14.1 T).
- Bottom line: a paragraph on the Howland Research Forest five version projections.
- Current 14.2 candidates, NS: v141LTfi not cleared on the NS grid from measured stand lists (PREREG49).
- Open items: PREREG49 readings appended to the NS survivor mortality item and to the NS top height loss item.
- Reproducibility: the PREREG48 RESULT revision and the PREREG49 registration; the commit note for revision g; the 1.10.0
  publication sentence and its DOI line.
- Summary of studies: rows for PREREG48 and PREREG49.

## Changed

- Title: PREREG16 to PREREG47 becomes PREREG16 to PREREG49. Date line: revision g of October 27, 2026, built on revision f.
- Open items: the PREREG48 item now states its finding instead of "waits on firebreather"; the 14.3 thinning item states the
  PREREG2 outcome instead of "has not run".
- Reproducibility: "this revision f is in the commit after d06c68ed" now names 695b7fec for revision f; the 1.10.0 sentence
  states publication instead of staging.

## Removed

- Open items: "PREREG49 (the NS survival step and an NS grid from measured stand lists) is drafted and registers after five
  server lookups on firebreather." Removed because PREREG49 is now registered and run; its findings are in the bottom line, the
  NS candidate entry, two open items and the summary table.

Nothing else was removed. The unified diff is `2026-10-27_release-notes_r20261026f_to_r20261027g.diff`; the rendered check is
`2026-10-27_fvs-acd-v14.2_release-notes_RENDER-CHECK.pdf` (17 pages, pages 2 and 17 inspected).
