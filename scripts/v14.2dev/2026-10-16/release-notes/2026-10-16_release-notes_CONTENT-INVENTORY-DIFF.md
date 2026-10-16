# Release notes revision e (October 16, 2026): content inventory diff against revision d

Prior `scripts/v14.2dev/2026-10-05/notes_20261005d/2026-10-05_fvs-acd-v14.2_release-notes_DRAFT.md` (be315202, untouched). New `2026-10-16_fvs-acd-v14.2_release-notes_DRAFT.md` (e1f7b8e9), built by `build_rn_20261016e.py` with exact replacements, each asserted once, and the unified diff is `2026-10-16_release-notes_r20261005d_to_r20261016e.diff`. Sections go from 12 to 13, study table rows from 32 to 33 and words from 5,304 to 6,697. Every section and sentence of revision d is carried forward, and no em dash appears.

## Added

| Where | What |
|:--|:--|
| Bottom line | A third paragraph on the October 16 cross-version benchmark (14.1 best ten year model, heavy removal recovery overstated by 1.39 Mg ha⁻¹ yr⁻¹, decline in 64 to 84% of stands in each of the six named forest types), its three implications for 14.3, that p38_fit and qc_rh were not run, and that PREREG46 and PREREG47 revisions 1 to 5 are registered but not run |
| New section "Cross-version benchmark, October 16" | Five paragraphs and Table 2 covering versions and scoring, ten year accuracy, post-harvest recovery by FCCL harvest type, 200 yr behavior against the Maine FIA curves, and the 14.3 implications (thinning response limited to partial removals, senescence conditioned on forest type, diameter growth shortfall) |
| Open items | Six bullets for the PREREG46 runs and PREREG47 reading, the unrun p38_fit and qc_rh arms, and the three 14.3 changes from the benchmark |
| Reproducibility | Commit fc78b2be named for the fourth 5 October revision, the commit after it for this revision, the benchmark job ids (15578311, 15578378, 15578563, 15579011, 15579160), where the scripts sit, that per stand files stay on Cardinal, and the PREREG46 and PREREG47 registration md5s with the note that thresholds_p47.R has not run |
| Summary of studies | One row for the cross-version benchmark |

## Changed

| Where | From | To | Why |
|:--|:--|:--|:--|
| Title | "release notes for PREREG16 to PREREG45b" | adds "and the October 16 cross-version benchmark" | Scope now includes the benchmark |
| Date line | "Draft of October 5, 2026 (fourth revision that day)" | "Draft of October 16, 2026 (revision e, built on the fourth revision of October 5, 2026)" | New revision |
| Reproducibility | "the commit after a666987c (PREREG45 revision 2, the stress tests, PREREG45b and this revision of the notes)" | "fc78b2be (... the fourth 5 October notes) and the commit after fc78b2be (...)" | The commit after a666987c now exists as fc78b2be, and "this revision" would otherwise point at the wrong file |
| Reproducibility | "Version 1.9.0, which adds PREREG45, PREREG45b, the stress tests and this revision, receives its DOI when published." | 1.9.0 covers the fourth 5 October revision, is staged on firebreather with Aaron's approval and unpublished, and the benchmark goes into the version after it | Records the actual state on October 16, 2026 |

## Removed, and why

None.

## Checks

Every number in an added or changed line was matched against the cross-version benchmark CSVs (`docs/benchmarks/2026-10-16_cross-version/data/`), the benchmark memo, revision d itself or the October 15, 2026 session handoff. The only tokens not found there are the five Cardinal job ids, which come from the run folder logs and launchers (for example `acdx_analyze_15579011.out`). Rebuilding from revision d reproduces e1f7b8e9. The p38_fit and qc_rh arms were not run, so no number for them appears.
