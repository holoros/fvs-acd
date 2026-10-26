# Release notes revision f (October 26, 2026): content inventory diff against revision e

Prior `scripts/v14.2dev/2026-10-16/release-notes/2026-10-16_fvs-acd-v14.2_release-notes_DRAFT.md` (e1f7b8e9, untouched, read from commit c9ad8277). New `2026-10-26_fvs-acd-v14.2_release-notes_DRAFT.md` (08414cbc), built by `build_rn_20261026f.py` with exact replacements, each asserted once; the unified diff is `2026-10-26_release-notes_r20261016e_to_r20261026f.diff`. Sections stay at 13, study table rows go from 33 to 35 and words from 6,697 to 7,481. Every section and sentence of revision e is carried forward except the three superseded statements listed under Removed. No em dash appears.

## Added

| Where | What |
|:--|:--|
| Bottom line | A fourth paragraph on PREREG46 (no candidate) and the PREREG47 reading (every arm read not credible on the long run); the sentence that the 14.2 arms reproduce 14.1 on the Maine frames |
| QC height anchor family | A PREREG46 paragraph (qc_ez fit stop, qc_lz fit, gates, long run) |
| Bakuzis grids | A PREREG47 paragraph (thresholds including the negative MG_LO, every arm's failing gate, site ordering) |
| Current 14.2 candidates | One sentence on PREREG46 and PREREG47 under QC |
| Open items | The PREREG46 and PREREG47 outcome and what the next QC study needs; PREREG48 registered; PREREG49 waiting on lookups; 14.3 PREREG1 outcome and PREREG2 registration |
| Reproducibility | Commits c9ad8277 and d06c68ed; the 1.9.0 DOI and its metadata date; 1.10.0 staged; the PREREG47 threshold, PREREG46 assembly and PREREG48 registration md5s; a 1.9.0 DOI line |
| Summary of studies | Rows for PREREG46 and PREREG47 |

## Changed

| Where | From | To | Why |
|:--|:--|:--|:--|
| Title | "PREREG16 to PREREG45b" | "PREREG16 to PREREG47" | Scope |
| Date line | revision e of October 16 | revision f of October 26, built on e | New revision |
| Cross-version section and its study row | p38_fit and qc_rh not run | run October 26, identical to 14.1 | They ran |

## Removed, and why

| Statement | Why |
|:--|:--|
| p38_fit and qc_rh "were not run ... firebreather unreachable" (bottom line and cross-version section) | Superseded: they ran and equal 14.1 |
| PREREG46 and PREREG47 "registered but not yet run" (bottom line, open items, reproducibility) | Superseded: they ran |
| Open item for the unrun p38_fit and qc_rh arms | Resolved |

## Checks

Every number in an added or changed line was checked by an independent reviewer against the PREREG46 and PREREG47 RESULTs and tables, the acdx arm identity record, the registration logs and the session handoff: no contradiction; four wording overstatements corrected before this build. c9ad8277 was read from `git ls-remote` on OSC Cardinal.
