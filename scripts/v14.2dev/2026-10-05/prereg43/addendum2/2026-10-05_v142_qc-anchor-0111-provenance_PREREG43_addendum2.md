# PREREG43 addendum 2: GitHub history of holoros/fvs-acd and the Cardinal folders not reached

5 October 2026. Recorded before any of the sources below is read. Aaron asked (5 October, "all of the above") that both
remaining places be searched and that 0.111 stay described as an operations setting of undocumented origin if neither
holds its calibration. Same question, same classes (SET, USE, FIT, FIT of a replacement), same verdict scale as PREREG43
revision 1 (md5 e3326190) and addendum 1 (md5 6bb3203e). Records only: no engine run, no score, nothing changed. No
coordinates. No em dashes.

## Sources, in this order

1. GitHub, `holoros/fvs-acd`, read through the REST API from firebreather with the existing read token
   (`~/.gh-holoros/token`), nothing written to the repository: (a) the commit list of every branch up to and including
   10 July 2026 (the date of the earliest SET found by revision 1); (b) for each such commit, the changed file names and
   patch lines that contain `QC_AFAC`, `qc_afac`, `AFAC`, `afac` or `0.111`; (c) the code search API for `0.111` and
   `QC_AFAC` on the default branch. A FIT is a commit line that estimates, optimises, solves for or tabulates a QC height
   multiplier against data.
2. Cardinal, the four folders not reached by addendum 1: `~/scripts`, `~/_scripts`, `~/fvsacd_bak30`, and the freeze
   archives `~/fvs-freeze-archive_20260805` and `~/fvs-freeze-archive_20260806`. Text files under 5 MB only, read with
   `grep -rIl` then `grep -n` on the files listed; each command kept to a few seconds (one folder, or one archive listing,
   per command). Limit: 30 Cardinal commands; on reaching it the search stops and the folders not read are named.

## Stop rule and verdict

The search stops at the first FIT that estimates 0.111 itself (the value, or a value that rounds to it, from QC data),
which is then read in full and recorded with path, date, md5 and the data and method it uses. Otherwise every source above
is read. Verdict: FOUND (with the record), or NOT FOUND (0.111 stays an operations setting of undocumented origin, carried
from the 12.9.2 recipe). Either way the 14.2 QC decision is unchanged (PREREG43 consequence).

## Outputs

`~/jobs/v142p43/search_c/` (GitHub) and `~/jobs/v142p43/search_d/` (Cardinal): hit tables and a findings note each; then
`2026-10-05_v142_qc-anchor-0111-provenance_RESULT_addendum2.md` beside the revision 1 RESULT, which is not edited.
