# Provenance of QC_AFAC 0.111: PREREG43 addendum 2 result

5 October 2026. Pre-registration `plan/2026-10-05_v142_qc-anchor-0111-provenance_PREREG43_addendum2.md` (md5 64b982de),
recorded before either source was read. Records only: no engine run, no score, nothing changed. No coordinates. The revision 1
RESULT is not edited.

## Verdict

**NOT FOUND. No record estimates 0.111 itself.** The GitHub history does, however, show where the value was meant to come from.
On 4 July 2026 (commit 4af1b2da, `20260704_v12101_stress_and_parity.md`, lines 127 to 135) the QC increment scale is set to
"the observed-over-predicted increment ratio (New Brunswick 0.579, Quebec 0.111)", citing `scripts/topht_recal_diag.R`
(commit a259273d, 2 July 2026, md5 ca33b029). That script is a FIT of a QC height ratio: mean predicted over mean observed top
height increment on the v12.7.0 scorecard (cb_v1270_results.csv) for the Quebec pairs. It prints 8.89 and never the inverse,
and 1/8.89 is 0.1125, which rounds to 0.112, not 0.111. New Brunswick (1/1.73 = 0.578) matches 0.579. So 0.111 is a hand
set inverse of that diagnostic with a small unexplained gap, not an estimate on record. The stop rule was not triggered.

## Counts

| Source | Scanned | SET | USE | FIT | Other |
|:--|--:|--:|--:|--:|--:|
| GitHub holoros/fvs-acd, 11 branches to 10 Jul | 63 commits, 551 file changes | 11 | 13 | 1 (inverse 0.1125) | 19 |
| GitHub code search (0.111, QC_AFAC) | 0 results, index incomplete | 0 | 0 | 0 | 0 |
| Cardinal, 5 folders | 8,905 files, 29 of 30 calls | 0 | 1 | 0 | about 125 files |

The earliest SET moves from 10 July to 4 July 2026. Cardinal adds no SET and no FIT; `~/_scripts/AcadianGY_12.9.2.r`
(0b115f6f) cites topht_recal_diag for the separate ESI anchor coefficients only.

## Not reached

Cardinal `~/magplot/verify/topht_recal_diag.csv` and the diagnostic's console output, which would give the unrounded QC ratio
(outside the pre-registered folders, and computing from it would be a new estimate); 79 non ACD Fortran files containing
0.111 in each freeze archive and 7 out of fold csv files in `~/_scripts` subfolders (listed, not line read); the 0805 tarball
listing; commits after 10 July; the laptop; files over 5 MB (16 skipped).

## Consequence

The close out note should say that 0.111 is an operations setting taken by hand from the inverse of the QC top height
increment ratio in topht_recal_diag.R (v12.7.0 output, 2 July 2026), where the recorded ratio implies 0.1125, and that no fit
of 0.111 itself exists. The 14.2 QC decision is unchanged.

## Files

`search_c/` (hits_DATA d30d19f5, findings 9faf3bdb, search_c.py 5a12e80b), `search_d/` (hits_DATA 27759c63, findings f80e107e).
