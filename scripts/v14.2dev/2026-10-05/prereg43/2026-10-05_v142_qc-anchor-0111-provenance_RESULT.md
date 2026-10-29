# Provenance of the shipped 14.1 QC height anchor QC_AFAC 0.111: PREREG43 result

5 October 2026. Pre-registration `plan/2026-10-05_v142_qc-anchor-0111-provenance_PREREG43.md` (revision 1, md5 e3326190,
recorded 12:08:22 before the search) and addendum 1 (6bb3203e, recorded before Cardinal was read). Records only: no engine
run, no score, nothing changed. No coordinates. No em dashes.

## Verdict

**Not found. No record on firebreather, or in the parts of Cardinal that could be reached, estimates 0.111; it appears only as
a fixed operations setting.** Two independent searchers over 42,671 firebreather files found the same 61 SET lines (61 of 61
identical) and no line that fits or derives 0.111. The earliest dated SET is the 10 July 2026 v12.10.1 freeze recipe in the
fvs-acd repository mirror (`docs/handoffs/20260710_v12101_FREEZE_and_run_recipe.md`, line 22, `export NB_AFAC=0.579
QC_AFAC=0.111`, md5 478c67fa), which feeds `bench_parity.R` on Cardinal; that script reads QC_AFAC from the environment with a
default of 1. The repository VERSION_HISTORY places 0.111 in the AcadianGY 12.9.2 operations recipe behind the frozen v12.10.1,
and one GTR draft line calls the pre-freeze value the "development afac". No file states the data, the tag pairing or the
method behind it, so the pairing verdict is not found rather than row index or field tag.

## What the searches found

| Item | Searcher A | Searcher B |
|:--|:--:|:--:|
| Files scanned (firebreather) | 42,671 | 42,671 |
| SET lines | 61 | 61 (identical) |
| FIT lines estimating 0.111 | 0 | 0 |
| Fits that use 0.111 as a reference arm | PREREG19 grid, PREREG23, PREREG28 (classed FIT of a replacement) | same scripts, classed USE |

The only fits that touch 0.111 are the 14.2 refits, which estimate replacement values with 0.111 as the reference arm; PREREG23
and PREREG28 read the run frames (row index, init md5 6fb1ff68) and no fit reads the field tag frames (521d6468). The 14.1
model file (AcadianGY_14.1.r, 0bf27dde) and the v141 coefficient bundle (c8f02f58) do not contain the value; the runner
(`runner_p28_fb.R`, 0a2b2742) reads it from the environment. Every 14.2 job inherits it from `v142htf/home/run_task.sh` (26
September 2026) or `v142p14/scripts/p14_common.R`.

On Cardinal (addendum 1): `~/magplot/verify/bench_parity.R` and its variants read QC_AFAC from the environment (USE);
`~/magplot/verify/v1211_source_manifest.txt` (21 July 2026, fe61979c) records the run setting `NB_AFAC=0.579 QC_AFAC=0.111`
(SET); `~/fit_v130_esi_anchor_cofit*.R` also mention it (their repository mirror copies pass 0.111 through while fitting another coefficient; the Cardinal copies were not read); `~/repos/fvs-acd` on Cardinal is
not a git repository, so no commit history was available.

## Not reached

The Cardinal link dropped on most commands longer than a few seconds, and the addendum's 20 command limit was reached before
`~/scripts`, `~/_scripts`, `~/fvsacd_bak30` and the freeze archives (`~/fvs-freeze-archive_20260805`, `_20260806`) were read.
The fvs-acd git history (not on firebreather), the laptop, binary files and files over 5 MB were outside the search set. A
12.9.2 era calibration of the QC anchor, if one exists, would be in one of those places.

## Consequence

The close out note should describe 0.111 as an operations setting of undocumented origin, carried unchanged from the v12.9.2
recipe through the v12.10.1 freeze into 14.1, not as a value fitted on QC tag pairs. That does not change the 14.2 decision.
The remaining step, if Aaron wants it, is a read of the unreached Cardinal folders and the GitHub history of `holoros/fvs-acd`
for the 12.9.2 commit.

## Files

Firebreather `~/jobs/v142p43/`: `plan/` (plan, addendum 1), `logs/`, `search_a/` (hits 83e3cfa9, findings 3812a778),
`search_b/` (hits fb500bfe, findings fe412e55), this RESULT.
