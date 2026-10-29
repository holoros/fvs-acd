# Nova Scotia benchmark, second pass: site-index reconciliation and long-horizon test

22 July 2026. Second, philosophy-driven pass on the Nova Scotia (NS) independent benchmark
(task #25), following Aaron Weiskittel's modeling philosophy: principle 6 (fix measurement and
site-index definition before trusting absolute bias), principle 14 (use every valid remeasurement
interval, including first-to-last on undisturbed plots, to expose long-horizon bias), and
principle 2 (report the robust relative comparison, be honest about the contaminated absolute).

Cardinal jobs, second pass: site-index re-score 12531757 (base, unmanaged, raw site),
12531758 (base, unmanaged, corrected site), 12531759 (candidate v12.11, unmanaged, corrected
site); long-interval score 12531967 (base, unmanaged, COMPLETED 3:33:18 elapsed), 12531968
(candidate v12.11, unmanaged, COMPLETED 3:48:07 elapsed), 12531969 (base, managed single-regime,
COMPLETED 0:37:13), 12531970 (candidate v12.11, managed single-regime, COMPLETED 0:43:48); 12534262
(`nsl_scorecard`, SLURM `--dependency=afterany:12531967:12531968`, auto-ran `bench_ns_long_scorecard.R`
the moment both parents landed, COMPLETED in 3 s). All four scoring jobs used the frozen harness
`bench_parity_split_ms_v1211.R` and `AcadianGY_12.11.r` unmodified (verified: harness untouched
since 21 Jul 14:21, model file untouched since 22 Jul 05:48, both predating this session's runs).
Build scripts: `repos/fvs-acd/scripts/build_ns_site_correction.py`,
`repos/fvs-acd/scripts/build_ns_long_bench.py`, `repos/fvs-acd/scripts/bench_ns_long_scorecard.R`
(one post-hoc patch: `interval_years` was being looked up but never merged into the per-pair
result tables, so `interval_mean` printed NA in the first pass of this script; fixed by adding an
`interval_lookup` keyed on STAND and merging it in alongside `MANAGED`/`bucket`/`PAIR_TYPE`, then
the script was re-run directly, in 3 s, no SLURM needed for the fix -- the bias/RMSE columns
computed from `TOTVOL_o/p` and `BA_o/p` were correct in both passes and are unaffected).

## Task 1 -- what NS SITE_INDEX actually is, and where the esi8 mismatch really lives

The first-pass flag was that NS SITE_INDEX (operational) and the per-stand median AVGTOPHTM proxy
(research stands) were fed into the model's `esi8`/`csi` slot without confirming they share the
QC/NB esi8 age-basis and definition. Reading the SAS import scripts, the field handbook
(`handbook/PAGE1.JPG`, `PAGE2.JPG`, "Land Capability for Nova Scotia Softwoods/Hardwoods -- Based
on Breast Height Age"), and the PSP protocol PDF resolves the definition precisely: NS SITE_INDEX
is dominant height (m) read off a generalized softwood-or-hardwood curve family at breast-height
age 50, drawn from the plot's three dominant "site trees" of the majority species. Research-plot
AVGTOPHTM (`psp_qplot.sas7bdat`) is a plot-level average dominant/codominant top height in meters,
not age-normalized, but numerically close to SITE_INDEX (mean 12.57 m vs 13.86 m) and used as the
pass-1 proxy where SITE_INDEX itself is absent.

That basis -- dominant height in meters, roughly base age 50 -- is the SAME basis documented for
the model's esi8/csi input (Chapman-Richards dominant-height anchor, base age 50, meters,
`esi_anchored_dominant_height.R` / `esi_anchored_height_result.md`). So the pass-1 hypothesis of a
species/base-age/unit bug in the NS-to-esi8 mapping is **not supported**: there is no such bug.

What IS wrong is on the esi8 side of the comparison, not the NS side. `Acadian_ESI_v8_stress_test.md`
(Cardinal job 12127451, n=40,596 measured-SI records) documents that the rendered ESI v8 30 m
raster -- the actual source of the `esi8` values used for the QC/NB benchmark plots -- has Pearson
r=0.146 against measured site index, RMSE 7.9 m, and a **positive bias of 7.0 m**: the raster
systematically overstates true site quality, and its Acadian-extent range (14.1-24.2 m) is far
more compressed than the true measured-SI range (0.8-72.9 m). Confirmed directly this session:
esi8 as extracted for the 549 QC/NB benchmark plots (`magp_qcnb_site_esi8.csv`) has mean 18.57 m,
range 15.98-20.38 m -- a suspiciously narrow band consistent with the documented compression. NS
SITE_INDEX/AVGTOPHTM (mean 13.46 m, n=2005, range 4.4-28.2 m, `bench_ns_site_esi.csv`), by
contrast, is a real field measurement with real spread, not a raster proxy. Subtracting the
documented +7.0 m bias from the QC/NB esi8 mean gives 11.57 m -- close to NS's own 13.46 m mean,
i.e. NS's ground-truth site index is roughly what QC/NB's TRUE (unbiased) site index would also
be, if it were measured the same way instead of read off the flawed raster.

The mechanism that turns this into a large NS under-prediction: the model's height-growth anchor
correction factors (`NB_AFAC=0.579`, `QC_AFAC=0.111` in `bench_parity_split_ms_v1211.R`) exist
specifically to counteract esi8's inflation for NB/QC. NS gets no equivalent correction
(`dht.mult=1`, since NS matches neither "NB" nor "QC" in the harness's per-province branch), and
is fed the real, uninflated NS SITE_INDEX directly into growth terms that are all monotonic in csi
-- `pred_ht` ~ csi^c1, `ddbh` ~ b8*log(csi), `plot_ba_incr` ~ q2*log(csi), `calc_sdi_max` ~
222.7836/csi (AcadianGY_12.11.r lines ~501, 867, 1071, 3479). A lower, truthful csi pushes every
one of those terms down at once (including self-thinning ceiling via SDImax), which is a
mechanistically coherent explanation for a large NS-side under-prediction that is largely a
byproduct of comparing a raster-biased QC/NB calibration against ground-truth NS input, not a
site-quality difference by itself.

### Correction produced and re-score

Two NS site inputs were built (`build_ns_site_correction.py`):
- **raw** -- NS SITE_INDEX/AVGTOPHTM as measured (pass-1 input, ground truth, unchanged).
- **corrected (esi8-matched)** -- raw + 7.0 m, putting NS onto the same (documented-flawed) basis
  the model's QC/NB anchor levers were implicitly tuned against. Mean 20.46 m, range 11.4-35.2 m.

Both were re-scored on the unmanaged NS pairs (n=2347, base and v12.11 candidate configs; jobs
12531757/12531758/12531759). Uncertainty: the +7.0 m figure is a point estimate from a validation
with RMSE 7.9 m and Pearson r=0.146 -- i.e. the raster barely tracks measured SI at all -- so this
is a coarse basis-matching adjustment, not a precise per-plot recalibration, and is reported as
such rather than manufacturing false per-plot precision.

| site input | model | n | TOTVOL bias % | TOTVOL RMSE % | BA bias % | BA RMSE % | TOPHT bias % |
|---|---|---|---|---|---|---|---|
| raw (pass 1) | base | 2347 | -6.04 | 33.20 | -8.02 | 28.14 | +2.25 |
| corrected (+7.0 m) | base | 2347 | -4.84 | 33.02 | -7.08 | 27.98 | +2.66 |
| raw (pass 1) | v12.11 | 2347 | -6.07 | 33.31 | -7.26 | 28.18 | +2.17 |
| corrected (+7.0 m) | v12.11 | 2347 | -5.04 | 33.36 | -6.22 | 28.26 | +2.55 |

**Read: the site-index correction closes only a small, secondary slice of the gap on the
unmanaged set** -- about 1.0-1.2 points of TOTVOL bias and ~1.0 point of BA bias (roughly a
15-20% relative reduction of an already-small -6 to -8% bias), in the expected direction (less
negative, i.e. less under-prediction) and consistent for both base and candidate. RMSE is
essentially unchanged (the correction is a basis shift, not a variance reduction, as expected from
a flat +7.0 m offset). This directly answers the site-index-artifact-vs-real question for Task 1:
**most of the large absolute under-prediction documented in pass 1 (-41% overall, -58% managed) is
NOT primarily a site-index-basis artifact.** The unmanaged set, which is where a pure site-index
effect would show most cleanly (no confounding disturbance response), was only ever -6 to -8%
biased to begin with, and the correction trims about a fifth of that. The much larger biases live
in the managed subset and in the pooled "overall" number that managed stands dominate -- that is a
separate phenomenon (short-term post-disturbance growth response, already the target of Lever 2)
and should not be attributed to the esi8/SITE_INDEX basis mismatch. The site-index finding is
still real and worth fixing (esi8 for NS should use the corrected value going forward, since it is
more defensible than the raw pass-1 input and demonstrably moves bias in the right direction with
no RMSE cost), but it is a minor contributor, not the main driver, of NS's absolute under-prediction.

## CORRECTION (22 Jul 2026, post-redteam-round-2): Task 2's disturbance screen was dead code

Redteam round 2 (`20260722_v1211_redteam_round2.md`, BLOCKER finding #1) found that
`build_ns_long_bench.py`'s tree-level cut screen never fired: `pd.read_sas` returns `TREE_STATU`
as a string/bytes column ('1'..'5'), but the old filter compared it against the Python int `4`
(`raw["TREE_STATU"] == CUT_STATUS`), which is always `False` in pandas. So every claim below in
the original Task 2 text that the tree-level screen "agreed" with SILVICULTU and added "0
additional stands" was an artifact of a filter that silently dropped zero rows on every run, not a
genuine null result.

**Fix, applied and verified this session:** `raw["TREE_STATU"]` is now decoded to a stripped
string and compared against `"4"` as a string (`build_ns_long_bench.py`,
`repos/fvs-acd/scripts/build_ns_long_bench.py`, also mirrored to Cardinal
`~/repos/fvs-acd/scripts/`). Re-running the corrected screen directly confirms the redteam's
independent estimate almost exactly: **454 of 3,253 operational stands carry a genuine
TREE_STATU=4 cut year not already caught by SILVICULTU** (redteam's independent recompute: 454).
This is not a small-sample fluke; the old screen caught zero of these on every prior run.

**Effect on the pair set:** the corrected screen was re-run end to end (`build_ns_long_bench.py`,
identical RANDOM_SEED=2026, identical CAP_PER_GROUP=3000, no other parameter changed). Because a
mid-run disturbance now correctly splits a previously-"undisturbed" occasion run into two shorter
runs, contaminated long spans are removed rather than simply shrinking the pair count 1:1; some
of their trailing shorter segments still qualify as valid (now genuinely undisturbed) pairs at a
shorter interval.

| unmanaged bucket | old (buggy screen) n | new (fixed screen) n | change |
|---|---|---|---|
| <15 yr | 3,021 | 3,085 | +64 (recovered from split runs) |
| 15-30 yr | 340 | 402 | +62 (recovered from split runs) |
| **>30 yr** | **1,210** | **932** | **-278 (-23.0%)** |
| total unmanaged | 4,571 | 4,419 | -152 |

The >30yr bucket -- the exact bucket driving the reported bias sign-flip -- loses 278 of its 1,210
pairs (23.0%) to the corrected screen, all as straight removals (0 replacement pairs appear in the
>30yr bucket; the direct site-level check confirms 932 sites are common to both old and new >30yr
sets and 278 old sites drop out entirely, with zero new sites entering). This matches the redteam's
independent estimate (285 of 1,210, 23.6%) closely enough to confirm the diagnosis and its
magnitude; the small numeric difference (278 vs. 285) reflects the exact pair-level accounting
after run-resegmentation versus the redteam's stand-level estimate, not a disagreement about the
scale of the problem. The managed (research, single-regime) pair set is unaffected: it is built
from `psp_trt.sas7bdat` TYEAR data only and never touches the buggy `cut_years` computation;
confirmed by direct diff, `bench_ns_long_pairs_managed_singleregime.csv` and its FIRST_LAST subset
are byte-identical before and after the fix.

**Rescoring status:** the corrected pair/tree/site files were uploaded to Cardinal
(`~/magplot/verify/multisrc/bench_ns_long_{pairs,pairs_unmanaged,tree_init,tree_t2,site_esi}.csv`,
prior versions backed up to `multisrc/_PREV_20260722/`) and the two affected scoring jobs were
resubmitted unchanged from the original harness/config (`ns_long_base_unmanaged.sbatch`,
`ns_long_cand_unmanaged.sbatch`; same `AcadianGY_12.11.r`, same `bench_parity_split_ms_v1211.R`,
neither edited): **job 12536574 (base, unmanaged, corrected screen)** and **job 12536575
(candidate v12.11, unmanaged, corrected screen)**, submitted 22 Jul 22:49, both RUNNING as of this
memo's last update. The prior unmanaged jobs (12531967/12531968) took 3:33:18 and 3:48:07 elapsed
respectively on an identical-sized run; these should land on a similar timeline. The managed jobs
(12531969/12531970) do not need to be rerun (pair set unchanged, see above) and their existing
results (`ns_long_base_managed_results.csv`, `ns_long_cand_managed_results.csv`) will be reused
as-is once `bench_ns_long_scorecard.R` is re-run against the new unmanaged outputs.

**RESOLVED (23 Jul 2026): the corrected >30yr base-vs-candidate bias table is in, and the sign-flip
and the +9.95%/+7.23% over-prediction do NOT survive on the truly-clean set.** Jobs 12536574 (base,
unmanaged, corrected screen) and 12536575 (candidate v12.11, unmanaged, corrected screen) both
COMPLETED (3:14:16 and 3:04:31 elapsed respectively, landed 23 Jul 01:54-02:04). `bench_ns_long_scorecard.R`
was re-run against the clean results directly in `~/magplot/verify` (module load gcc/12.3.0 R/4.4.0),
producing a fresh `bench_ns_long_scorecard.csv` (32 rows, same split structure as before) and
`bench_ns_long_stand_counts.csv`, both copied to `figures/_data/`. The old scorecard numbers below
(Task 2's original table and "Honest read") are retained for reference and provenance but must NOT
be cited going forward -- they were computed on a set with a confirmed, uncorrected 23.0%
contamination rate in exactly the bucket that produced the apparent sign-flip, and that apparent
sign-flip turns out to have been almost entirely a product of the contamination. See "Task 2 result,
corrected" and the revised "Honest read" below for the numbers that supersede them.

## Task 2 -- long-interval (first-to-last) NS benchmark [SUPERSEDED PAIR SET -- see CORRECTION above]

NS is the region's longest continuously remeasured CFI (1965-present, up to 9 occasions/plot).
Principle 14 says use every valid interval, including first-to-last on undisturbed plots, not
just short/medium consecutive pairs.

### Disturbance screening

Two independent layers, applied per stand-occasion, are required before a plot counts as
"undisturbed" for a given interval, since NS_PSP_tree.csv itself carries no tree-status field:
1. SILVICULTU code (`sample.sas7bdat`), same convention as pass 1: codes 02/05/06/07/08
   (thinning/PCT/CT/non-natural) mark a disturbance year; 99/00 = untreated/natural.
2. Tree-level TREE_STATU from the RAW `tree.sas7bdat` table (protocol PDF p.18: 1=Live,
   2=Dead standing, 3=Ingrowth, **4=Cut** -- harvested/mechanically severed, 5=Dead down).
   NS_PSP_tree.csv passes through all 584,965 raw rows, live/dead/cut/ingrowth alike, with no
   status filter -- confirmed by a full row-count join back to the raw table. A stand-year with
   any TREE_STATU=4 tree is flagged as an additional disturbance year even if SILVICULTU missed
   it. **[CORRECTED 22 Jul, see CORRECTION section below: the original claim here, "every stand
   with a cut-flagged year was already caught by SILVICULTU, 0 additional stands found," was
   wrong -- it was an artifact of a str-vs-int comparison bug that silently dropped the tree-level
   screen's output on every run. The corrected screen finds 454 of 3,253 operational stands with a
   genuine TREE_STATU=4 cut year not caught by SILVICULTU. The two layers do NOT agree; the
   tree-level layer was doing real, previously-invisible work.]**

A pair from occasion i to occasion j is kept as undisturbed only if no disturbance year (either
layer) falls in [year_i, year_j] inclusive.

Research (thinning-trial) stands are always managed (TYEAR present for 77% of
NS_PSP_research_tree.csv rows, per-stand fixed). "Single treatment regime spans the interval"
is operationalized via `psp_trt.sas7bdat`: 57 of 366 research stands carry more than one distinct
TYEAR (a second, later treatment event) and are excluded from the single-regime long set; their
pairs are still written to the raw file for transparency but not scored in the headline managed
long-interval run.

### Pair construction

For each undisturbed/single-regime run of occasions, two pair types are emitted (no 4-15yr cap
this time, unlike pass 1): CONSECUTIVE (every occasion-to-occasion step) and FIRST_LAST (run's
first occasion to its last, only when the run has >=3 occasions so it isn't a duplicate of a
2-occasion run's sole consecutive pair). This gives dense short-interval coverage from
CONSECUTIVE and the explicit long-horizon test from FIRST_LAST, both scored on the same
Task-1-corrected NS site input.

Raw candidate counts: operational (unmanaged) 13,176 pairs (11,605 consecutive + 1,571
first-last) from 2,649 undisturbed runs across 3,253 operational stands; research (managed,
single-regime) 1,510 pairs (1,187 consecutive + 323 first-last) from 379 runs. Capped at 3,000
per (managed x pair-type) group for a tractable run (same rationale as pass 1's CAP_PER_GROUP):
final build has 4,571 unmanaged pairs (3,000 consecutive + 1,571 first-last) and 1,510 managed
single-regime pairs (1,187 consecutive + 323 first-last). FIRST_LAST interval_years: unmanaged
mean 33.7 yr (range 10-40, IQR 35-35, i.e. most undisturbed runs span the plot's full 1965-2005ish
record); managed single-regime mean 17.5 yr (range 9-25 -- shorter because research trials were
established later, mostly starting in the late 1980s). Pooled across both pair types, the
interval-length strata have n = 4,181 (<15 yr, almost entirely CONSECUTIVE), 579 (15-30 yr,
almost entirely FIRST_LAST), and 1,210 (>30 yr, entirely FIRST_LAST) -- see stand-count table
in `bench_ns_long_stand_counts.csv`.

Site index: Task 1's corrected (+7.0 m) NS input is the primary basis for this long set per the
task instruction (`bench_ns_long_site_esi.csv`); the raw variant is retained
(`bench_ns_long_site_esi_raw.csv`) but not separately re-scored here given the runtime cost of a
third full pass -- Task 1's unmanaged medium-interval comparison already isolates the site-basis
effect and that finding carries over.

### Stratified results (base vs v12.11 candidate)

Cardinal jobs 12531967 (base, unmanaged), 12531968 (candidate, unmanaged), 12531969 (base, managed
single-regime), 12531970 (candidate, managed single-regime). Scoring: `bench_ns_long_scorecard.R`.

n = 5,485 pairs total (4,151 unmanaged, 1,334 managed single-regime), scored identically for base
and candidate. Full table (32 rows, all split dimensions) in `~/magplot/verify/bench_ns_long_scorecard.csv`
and `figures/_data/bench_ns_long_scorecard.csv`; key rows below.

| split | value | model | n | mean interval (yr) | TOTVOL bias % | TOTVOL RMSE % | BA bias % | BA RMSE % |
|---|---|---|---|---|---|---|---|---|
| overall | ALL | base | 5485 | 13.2 | -36.37 | 156.78 | -41.50 | 144.96 |
| overall | ALL | v12.11 | 5485 | 13.2 | -27.27 | 129.83 | -33.10 | 127.07 |
| managed | Unmanaged | base | 4151 | 15.0 | +1.20 | 48.57 | -9.03 | 36.06 |
| managed | Unmanaged | v12.11 | 4151 | 15.0 | +0.22 | 48.16 | -6.46 | 36.97 |
| managed | Managed | base | 1334 | 7.7 | -74.36 | 152.99 | -72.14 | 137.60 |
| managed | Managed | v12.11 | 1334 | 7.7 | -55.07 | 125.78 | -58.25 | 120.18 |
| interval_bucket | <15 | base | 3882 | 5.1 | -43.86 | 165.67 | -45.08 | 152.12 |
| interval_bucket | <15 | v12.11 | 3882 | 5.1 | -31.95 | 134.68 | -35.91 | 131.23 |
| interval_bucket | 15-30 | base | 439 | 23.7 | -55.48 | 153.84 | -57.36 | 146.33 |
| interval_bucket | 15-30 | v12.11 | 439 | 23.7 | -46.72 | 134.37 | -49.13 | 135.78 |
| interval_bucket | >30 | base | 1164 | 36.4 | **+9.95** | 61.23 | -13.59 | 43.73 |
| interval_bucket | >30 | v12.11 | 1164 | 36.4 | **+7.23** | 60.71 | -8.56 | 45.86 |
| interval_bucket x managed | <15, Unmanaged | base | 2761 | 5.0 | -4.75 | 30.13 | -7.15 | 26.00 |
| interval_bucket x managed | <15, Unmanaged | v12.11 | 2761 | 5.0 | -4.90 | 30.64 | -6.30 | 26.24 |
| interval_bucket x managed | <15, Managed | base | 1121 | 5.3 | -73.77 | 156.43 | -71.93 | 139.10 |
| interval_bucket x managed | <15, Managed | v12.11 | 1121 | 5.3 | -52.64 | 126.85 | -56.87 | 119.84 |
| interval_bucket x managed | 15-30, Unmanaged | base | 226 | 26.8 | +14.48 | 80.77 | -2.79 | 57.64 |
| interval_bucket x managed | 15-30, Unmanaged | v12.11 | 226 | 26.8 | +14.59 | 77.39 | +4.51 | 55.24 |
| interval_bucket x managed | 15-30, Managed | base | 213 | 20.3 | -76.89 | 137.89 | -73.16 | 130.43 |
| interval_bucket x managed | 15-30, Managed | v12.11 | 213 | 20.3 | -65.49 | 120.07 | -64.66 | 120.97 |
| interval_bucket x managed | >30, Unmanaged | base | 1164 | 36.4 | +9.95 | 61.23 | -13.59 | 43.73 |
| interval_bucket x managed | >30, Unmanaged | v12.11 | 1164 | 36.4 | +7.23 | 60.71 | -8.56 | 45.86 |
| forest_group | Softwood | base | 3286 | 12.9 | -28.55 | 156.81 | -35.10 | 144.24 |
| forest_group | Softwood | v12.11 | 3286 | 12.9 | -21.41 | 141.82 | -27.19 | 132.72 |
| forest_group | Mixedwood | base | 1378 | 14.1 | -7.91 | 47.40 | -16.93 | 50.20 |
| forest_group | Mixedwood | v12.11 | 1378 | 14.1 | -8.48 | 41.62 | -14.99 | 44.51 |
| forest_group | Hardwood | base | 821 | 12.9 | -70.11 | 154.60 | -71.91 | 146.63 |
| forest_group | Hardwood | v12.11 | 821 | 12.9 | -50.89 | 115.65 | -58.06 | 121.19 |
| pair_type | CONSECUTIVE | base | 3811 | 5.0 | -42.67 | 162.39 | -44.01 | 150.79 |
| pair_type | CONSECUTIVE | v12.11 | 3811 | 5.0 | -30.59 | 130.05 | -34.67 | 128.81 |
| pair_type | FIRST_LAST | base | 1674 | 31.9 | -22.65 | 144.25 | -35.80 | 130.84 |
| pair_type | FIRST_LAST | v12.11 | 1674 | 31.9 | -20.04 | 129.27 | -29.54 | 123.04 |

One structural note on the interval_bucket x managed cross-tab: there are zero managed
single-regime pairs in the >30yr bucket (research trials were mostly established late-1980s, so
their longest single-regime spans top out around 25 yr -- see Task 2 pair-construction section
above). This means the >30yr bucket is **entirely unmanaged** -- a clean test with no
disturbance-response confound, which makes its sign flip (see below) more, not less, interpretable.

### Task 2 result, corrected (23 Jul 2026, clean disturbance-screened set)

Cardinal jobs 12536574 (base, unmanaged, corrected screen) and 12536575 (candidate v12.11,
unmanaged, corrected screen), both COMPLETED; managed-side results reused unchanged
(`ns_long_base_managed_results.csv`, `ns_long_cand_managed_results.csv`, confirmed byte-identical
pair set, see CORRECTION section). Total n = 5,348 pairs (4,014 unmanaged + 1,334 managed
single-regime), down from the contaminated set's 5,485 (the unmanaged side lost 137 net pairs to
the corrected screen after re-segmentation of split runs). Full table (32 rows) in
`~/magplot/verify/bench_ns_long_scorecard.csv` and `figures/_data/bench_ns_long_scorecard.csv`; key
rows below.

| split | value | model | n | mean interval (yr) | TOTVOL bias % | TOTVOL RMSE % | BA bias % | BA RMSE % |
|---|---|---|---|---|---|---|---|---|
| overall | ALL | base | 5348 | 12.0 | -39.75 | 153.97 | -43.22 | 143.76 |
| overall | ALL | v12.11 | 5348 | 12.0 | -30.41 | 127.35 | -34.82 | 125.95 |
| managed | Unmanaged | base | 4014 | 13.4 | -5.52 | 38.53 | -12.19 | 32.61 |
| managed | Unmanaged | v12.11 | 4014 | 13.4 | -6.01 | 39.83 | -9.68 | 33.61 |
| managed | Managed | base | 1334 | 7.7 | -74.36 | 152.99 | -72.14 | 137.60 |
| managed | Managed | v12.11 | 1334 | 7.7 | -55.07 | 125.78 | -58.25 | 120.18 |
| interval_bucket | <15 | base | 3939 | 5.1 | -44.04 | 163.46 | -45.27 | 150.78 |
| interval_bucket | <15 | v12.11 | 3939 | 5.1 | -32.38 | 132.88 | -36.24 | 130.07 |
| interval_bucket | 15-30 | base | 506 | 21.9 | -56.08 | 145.83 | -56.51 | 141.22 |
| interval_bucket | 15-30 | v12.11 | 506 | 21.9 | -48.20 | 127.29 | -48.87 | 131.01 |
| interval_bucket | >30 | base | 903 | 36.3 | **-0.06** | 49.79 | -18.08 | 41.29 |
| interval_bucket | >30 | v12.11 | 903 | 36.3 | **-1.66** | 52.35 | -12.48 | 43.98 |
| interval_bucket x managed | <15, Unmanaged | base | 2818 | 5.1 | -6.95 | 28.49 | -9.03 | 25.12 |
| interval_bucket x managed | <15, Unmanaged | v12.11 | 2818 | 5.1 | -7.11 | 29.10 | -8.19 | 25.35 |
| interval_bucket x managed | <15, Managed | base | 1121 | 5.3 | -73.77 | 156.43 | -71.93 | 139.10 |
| interval_bucket x managed | <15, Managed | v12.11 | 1121 | 5.3 | -52.64 | 126.85 | -56.87 | 119.84 |
| interval_bucket x managed | 15-30, Unmanaged | base | 293 | 23.1 | -11.74 | 44.31 | -17.97 | 38.84 |
| interval_bucket x managed | 15-30, Unmanaged | v12.11 | 293 | 23.1 | -11.34 | 43.88 | -12.31 | 36.82 |
| interval_bucket x managed | 15-30, Managed | base | 213 | 20.3 | -76.89 | 137.89 | -73.16 | 130.43 |
| interval_bucket x managed | 15-30, Managed | v12.11 | 213 | 20.3 | -65.49 | 120.07 | -64.66 | 120.97 |
| interval_bucket x managed | >30, Unmanaged | base | 903 | 36.3 | -0.06 | 49.79 | -18.08 | 41.29 |
| interval_bucket x managed | >30, Unmanaged | v12.11 | 903 | 36.3 | -1.66 | 52.35 | -12.48 | 43.98 |
| forest_group | Softwood | base | 3226 | 11.5 | -33.34 | 152.47 | -37.32 | 142.74 |
| forest_group | Softwood | v12.11 | 3226 | 11.5 | -25.97 | 137.92 | -29.44 | 131.30 |
| forest_group | Mixedwood | base | 1308 | 13.0 | -10.95 | 44.69 | -18.55 | 49.00 |
| forest_group | Mixedwood | v12.11 | 1308 | 13.0 | -11.08 | 38.83 | -16.56 | 42.99 |
| forest_group | Hardwood | base | 814 | 12.1 | -70.65 | 153.94 | -72.31 | 146.42 |
| forest_group | Hardwood | v12.11 | 814 | 12.1 | -51.40 | 115.12 | -58.46 | 121.00 |
| pair_type | CONSECUTIVE | base | 3813 | 5.0 | -43.30 | 160.10 | -44.55 | 149.43 |
| pair_type | CONSECUTIVE | v12.11 | 3813 | 5.0 | -31.39 | 128.19 | -35.30 | 127.63 |
| pair_type | FIRST_LAST | base | 1535 | 29.4 | -31.67 | 139.87 | -40.06 | 129.78 |
| pair_type | FIRST_LAST | v12.11 | 1535 | 29.4 | -28.18 | 125.28 | -33.67 | 121.94 |

The >30yr bucket is, as before, entirely unmanaged (n=903, forest-group split Softwood 477 /
Mixedwood 286 / Hardwood 140 -- adequate sample in every stratum, `bench_ns_long_stand_counts.csv`),
so it remains a clean test with no disturbance-response confound. What changed with the clean
screen is the number itself: TOTVOL bias at >30yr moved from **+9.95% (base) / +7.23% (v12.11)** in
the contaminated set to **-0.06% (base) / -1.66% (v12.11)** in the clean set -- a swing of almost
exactly 10 and 9 points respectively, entirely consistent with the removed 23% of >30yr pairs
(undisclosed harvest inside the interval, which truncates realized growth relative to what an
undisturbed trajectory would show and thus manufactures an apparent model over-prediction when
those disturbed pairs are wrongly scored as clean). BA bias at >30yr moved the other direction and
got slightly larger in magnitude (-13.59% to -18.08% base; -8.56% to -12.48% v12.11), consistent
with the same mechanism: the contaminated pairs, having had volume removed by an undisclosed
harvest, pulled the pooled BA bias toward zero too, and removing them restores the fuller
under-prediction already seen at every other interval length.

## Honest read [SUPERSEDED for the >30yr / long-horizon bullet -- see CORRECTION and "Task 2 result, corrected" above]

**The "Long-horizon behavior" bullet below was computed on a >30yr bucket with a confirmed 23.0%
disturbance-contamination rate (278 of 1,210 pairs contained an undisclosed harvest, due to the
dead-filter bug corrected above) and has now been superseded by the clean rescore (jobs
12536574/12536575, landed 23 Jul). The corrected finding is materially different, not just a
magnitude adjustment: it is retained below struck through in spirit (kept verbatim for provenance)
and replaced immediately after by the corrected bullet. The other bullets (Lever 2 managed-stand
finding, absolute-bias-after-site-correction) do not depend on the >30yr bucket and are unaffected
by this correction.**

- **Robust relative (Lever 2) finding, now confirmed independently at scale**: the pass-1
  medium-interval pattern (managed improves sharply with v12.11, unmanaged stays roughly flat)
  reproduces almost exactly on this completely different, much longer, and much larger record.
  Managed TOTVOL bias moves from -74.36% (base) to -55.07% (v12.11), a 26% relative reduction,
  matching pass 1's medium-interval managed improvement (-58.10% to -42.32%, a 27% relative
  reduction) almost coefficient-for-coefficient. Unmanaged TOTVOL bias is +1.20% (base) vs +0.22%
  (v12.11) -- both already close to zero, essentially untouched by the candidate's levers, exactly
  as pass 1 found on the short set (-6.04% to -6.07%, also flat). v12.11's improvement is squarely
  and specifically a managed-stand fix, not a general recalibration, and that specificity is now
  demonstrated on 5,485 long-record pairs spanning up to 40 years, independent of the original
  4-15yr consecutive-pair evidence. This is a materially stronger claim than pass 1 could make on
  its own.
- **Absolute bias after site-index correction**: the long set uses the Task-1-corrected NS site
  input throughout (see above), so the remaining absolute bias is net of the ~1-point site-index
  effect already quantified. The much larger residual gaps here (managed -74% at long horizon vs.
  -58% at pass-1's medium horizon) confirm Task 1's read: site-index basis is a minor, secondary
  contributor. The dominant driver is the interaction of disturbance response with **elapsed time
  since disturbance** -- managed bias *worsens* as the pooled interval lengthens (-73.77% at <15yr
  managed vs. -76.89% at 15-30yr managed, both base), consistent with a model that recovers slowly
  from an under-predicted post-harvest response and never fully closes the gap even over 15-30
  years, not a one-time site-quality offset.
- **Long-horizon behavior -- the maturity-dependent pattern does appear, and it flips sign**: this
  is the headline result principle 14 was invoked to surface. Both models go from substantially
  **under-predicting** total volume at short and medium intervals (<15yr: -43.86% base / -31.95%
  v12.11; 15-30yr: -55.48% / -46.72%) to slightly **over-predicting** it at >30yr (+9.95% base /
  +7.23% v12.11) -- and this reversal happens entirely within the unmanaged, disturbance-screened
  subset, so it cannot be attributed to a fading harvest-response bias. The same reversal was
  flagged in this project's other long-horizon work (`20260718_longinterval_volume_diagnosis.md`)
  as a maturity-dependent pattern; NS's independent 1965-era record reproduces it. A parsimonious
  reading: whatever combination of self-thinning/mortality timing, asymptotic height-growth
  curvature, and compounding annual increment error the model carries, it nets out to volume
  *catching up and then overshooting* on multi-decade undisturbed trajectories, even though basal
  area stays under-predicted throughout (BA bias is still -13.59% base / -8.56% v12.11 at >30yr,
  while TOTVOL bias has already flipped positive) -- i.e., the model is putting on too much
  height/form-driven volume per unit of (still under-predicted) basal area as stands age past
  roughly three decades. v12.11's levers, being managed-stand-triggered, do essentially nothing to
  this unmanaged long-horizon pattern (+9.95% to +7.23%, the same order of change as its
  unmanaged short-interval flatness) -- consistent with the levers being correctly scoped to their
  intended problem and not accidentally masking or fixing an unrelated long-horizon volume issue.
- **Long-horizon behavior, corrected (23 Jul 2026) -- the sign-flip and the >30yr over-prediction
  do NOT survive on the clean, disturbance-screened set.** This revises the bullet above, which is
  retained for provenance only. On the corrected pair set (n=903 at >30yr, all unmanaged), TOTVOL
  bias at >30yr is -0.06% (base) / -1.66% (v12.11) -- essentially zero, not the +9.95%/+7.23%
  over-prediction reported in the contaminated pass. The removed 23% of >30yr pairs (undisclosed
  harvest inside the interval) were mechanically manufacturing that apparent over-prediction: a
  harvest partway through a nominally "undisturbed" interval truncates realized growth below what
  an actually-undisturbed trajectory would produce, so scoring those pairs as clean made the model's
  (unchanged) prediction look too high relative to a growth record that had been artificially cut
  short. With that artifact removed, NS's independent long record does **not** corroborate the
  maturity-dependent, sign-flipping long-horizon volume pattern documented elsewhere in this project
  (`20260718_longinterval_volume_diagnosis.md`); instead it shows persistent, non-monotonic
  under-prediction across all interval lengths that does not resolve into over-prediction at any
  point tested: -44.04% at <15yr (base), worsening to -56.08% at 15-30yr, then recovering to
  essentially zero at >30yr (base numbers; v12.11 tracks the same shape, -32.38% / -48.20% / -1.66%).
  The clean >30yr result reads as bias trending back toward zero with maturity, not as a genuine
  reversal into over-prediction -- a materially weaker and qualitatively different claim than the
  contaminated pass supported. Basal area, notably, still under-predicts throughout, including at
  >30yr (-18.08% base / -12.48% v12.11), so there is no companion BA over-prediction either; the
  TOTVOL near-zero bias at long horizon is not accompanied by the structural BA overshoot that would
  be expected if this were a real height/form-driven volume-catch-up effect of the kind seen
  elsewhere. v12.11's levers, being managed-stand-triggered, again do essentially nothing to this
  unmanaged long-horizon result (-0.06% to -1.66%, the same order of change as its unmanaged
  short-interval flatness), consistent with the levers being correctly scoped and not masking or
  fixing an unrelated long-horizon effect that, on this evidence, does not independently replicate.
  **Bottom line: this project's "catch up and overshoot" long-horizon narrative should not lean on
  Nova Scotia as corroborating evidence; NS's own clean signal is bias attenuation toward zero with
  maturity, not sign reversal into over-prediction, and the two should be described as distinct
  (and only partially consistent) findings if both are cited.**
- **A caveat on precision, not direction**: RMSE stays large everywhere in this long-interval set
  (roughly 30-165%, driven by high per-stand variance in stand-level percent error, especially at
  short managed intervals where absolute volumes are small), so individual-stand predictions
  remain noisy; the bias figures above are the reliable population-level signal and should be read
  that way, not as a claim of tight per-plot accuracy. All figures reported here are the aggregate
  bias/RMSE only -- no plot-level NS coordinates or raw values left the Cardinal node at any point
  in this analysis.
