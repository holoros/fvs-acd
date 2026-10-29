# PREREG46 run, 26 October 2026: deviations and stage log

Plan: `plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md`, revision 1, md5 eb4b753d, checked on the laptop copy and on
firebreather before any step. Host firebreather (R 4.5.1), job root `~/jobs/v142p46/`. No em dashes.

## Deviations

| No. | What | Why | Effect on the reading |
|:--|:--|:--|:--|
| D0 | Registration was on the laptop copy (11 October), not on the server | firebreather was unreachable at registration; stated in the registration line | none; the server copy matches eb4b753d |
| D1 | `fit_p46_lz.R` (md5 6b76695c) replaces `fit_p46.R` (4c78db35) for the run | the first chain (attempt 1, 09:07 to 09:11) stopped at rule 1 on qc_ez, "b not negative", and fit_p46.R writes its output only at the end, so the finished qc_lz fit was lost. The plan applies rule 1 per arm; Aaron chose to continue qc_lz only | qc_lz is fitted exactly as registered (same seed, bootstrap matrix and start; the red team confirmed no RNG change). qc_ez is fitted at the point estimate only and its stop recorded in `fit/gyr142-p46-qczero-ez-fitstop_DATA_2026-10-26.csv` (md5 in `logs/fit_ez_stop_md5.txt`); it reproduces attempt 1 |
| D2 | `chain_p46_lz.sh` (md5 8849e38d) replaces `chain_p46.sh` (86de6c6b) | same | runs only qc_lz and qc_lz0 tasks (ids 1 to 20, 41 to 44), TR and the long run for qc_lz; scoring through `run_score_p46_lz.sh`, derived in the chain from the built `run_score_p46.sh` with the qc_ez join and plan rows removed (diff in `diffs/`). Every gate and threshold is unchanged |
| D3 | `assemble_p46_lz.R` (md5 5d593fca; revision 1, c214d860, failed its dry run on a palette line that commented out the theme definition, fixed in revision 2 and kept in `scripts/PREV/`) replaces `assemble_p46.R` (ecf2ebe4) | same | CANDS is qc_lz; qc_ez is reported as RULE1_HARNESS_FAILURE from the md5 pinned stop record; the tie rule is not reached; output folders may be redirected only for the dry run. Rule order, gates and thresholds unchanged |
| D4 | launch md5s in `logs/launch_md5s_lz.txt`, which carries every line of the original `logs/launch_md5s.txt` plus the derived scripts | the original record is kept unchanged with the attempt 1 logs in `logs/attempt1_20261026/` | none |
| D5 | qc_ez reported, not run | rule 1 | the plan's comparison of two zero forms reduces to one form; the qc_ez stop itself is a result: with the zero fixed at RMAX 1.285, the fold A estimating equations push b positive (a 0.4303, b 0.9219), so exp(a + b r) rises with r to offset the taper |

Red team reviews: `review/2026-10-26_p46-lz-scripts_REDTEAM.md` (fit and chain: one must fix, a comment line check that would have
stopped the chain after the build, fixed before launch; should fixes 4 and 5 applied) and
`review/2026-10-26_p46-lz-assemble_REDTEAM.md` (no must fix; should fixes 1, 2, 3, 5 and 6 applied).

## Stage log

| Time (firebreather, ADT) | Step |
|:--|:--|
| 09:07:39 to 09:11:57 | attempt 1 (chain_p46.sh): fit stops at rule 1, form ez, "b not negative"; nothing written; logs in `logs/attempt1_20261026/` |
| 09:23:12 | attempt 2 (chain_p46_lz.sh) starts; launch md5s checked |
| 09:27:21 | fit (qc_lz full, qc_ez point estimate and stop record); fit md5 7e3881f9, stop record e999098f |
| 09:27:22 | build (bundle md5s equal PREREG38) |
| 09:27:42, 09:28:39, 09:37:56 | G0, G0b, G0x compared (all pass) |
| 09:38:06 | TR for qc_lz (pass) |
| 10:02:36 | benchmark: 24 tasks, all exit 0; retries none needed |
| 10:02:43 | scoring (run_score_p46_lz.sh) |
| 10:22:45 | long run grid, three stand lists; CHAIN_DONE |
| 10:23 to 10:25 | dry assembly r1 fails on the figure palette line; fixed (r2) |
| 10:26:39 | dry assembly r2 complete; assembler md5 5d593fca recorded |
| 10:27 | assembly; tables equal the dry run byte for byte |
| 10:29:32 | PREREG47 launch md5s recorded (reading r1) |

