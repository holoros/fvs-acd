# A relative height multiplier for the QC height increment, for 14.3: pre-registration 45

5 October 2026, revision 1. Registers the 5 October draft (`2026-10-05_v142_qc-relht-increment_PREREG45_DRAFT.md`, md5
d162d5a0) with Aaron's choices of the same day: open the track, exponential form, the 100 year top height bound from the
measured stand frontier, and NB as a second arm. Written before any PREREG45 fit, engine run or projection. The outcome
**informs 14.3 only; 14.2 keeps QC_AFAC 0.111**. L and T are not re-estimated. GT1 stays a named failure. Stand identifiers
stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## NB arm: not registered here

The PREREG37 estimator pairs MAGPlot field tags, and the field tag frames (`v142p14/in/pass28qc`) hold QC only; PREREG32
found that NB tree numbers are not stable tags. The NB arm therefore cannot receive the same field tag fit. It is deferred
to a separate pre-registration (PREREG45b, stand level) on Aaron's choice; nothing NB is run under PREREG45.

## Form and fit (fold A only, frozen before any engine run)

Arm `qc_rh`: every QC tree's dht.mult is m(r) = exp(a + b r), r = current height over stand ESI (csi_site, or the runner's
CSI_DEFAULT when csi_site is not above 2), reassigned at the start and after every annual step for every live tree,
ingrowth included. Trees with no height at the start (the engine imputes them in step 1) take the expf weighted mean m of
the stand's trees with a height; a stand with no measured height takes m at r = 0.815 (QC_RH_RFILL, the median measured
TOPHT/ESI in `frontier_p45_DATA.csv`). From year 1 every tree has an engine height. NB, NS and ME are untouched.

`scripts/fit_p45.R` (md5 07959f2a) rebuilds the PREREG37 fold A field tag survivor set with the PREREG37 assembly logic,
stops unless it reproduces the PREREG37 pooled R 1.2418873575799 on 698 trees to 1e-12 [F9], and solves sum (1, r)(obs -
p0 m(r)) = 0 by Newton (at b = 0 this is the PREREG37 ratio of sums). Site cluster bootstrap B = 1000, PREREG37 seed and
weights. a and b are used rounded to four decimals. No fold B file is read by the fit; its md5 is recorded before any engine
run. Expectation: b negative, m near 1.5 at r 0.25 and near 0.6 at r 1.125.

## Driver change, reviewed before any run

One edit, applied by `scripts/build_p45.sh` to both the benchmark runner (`runner_p28_fb.R`, 0a2b2742, into
`runner_p45_fb.R`) and the long run driver (`driver_p44.R`, 7d5da479, into `driver_p45.R`): the `htfx` line is replaced by a
block that adds the per year reassignment branch above, active only when QC_RH_A and QC_RH_B are set (both or neither, and
QC_RH_RFILL with them, else stop). With them unset `htfx` is the original function. The edit is asserted to match exactly
once in each file; diffs go to `diffs/`. Wrappers are PREREG38 and PREREG44 copies with job root, runner or driver and md5,
arm case and log tags changed.

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | driver_p45 mode g0, qc141 (RH unset), PREREG31 G0 stands, against frozen p19_a0111 | worst scaled difference at or below 1e-9 | PREREG31 and PREREG44 G0 |
| G0b | driver_p45 mode grid, qc141 cell MX_E19.8_N6000, 100 years, against the frozen PREREG31 dry trajectory | identical | PREREG44 G0b |
| H0 | runner_p45 arm qc_rh0 (a = b = 0, so m = 1 for every tree every year) on the PREREG33 G0 subset (tasks 21 to 24) against frozen p19_a1000 | worst scaled difference at or below 1e-9, results and per tree | PREREG38 H0; tests the new branch |
| K1 | RUN_OK other than 1 for qc_rh after the PREREG38 retry rule | 0 | PREREG23 K1 |
| G1, G2 | long run: 101 rows, run_ok 1; age 0 stems and BA equal the t1 list | all; 1e-6 | PREREG44 |

## Benchmark gates (screened qc_c fold B; height on field tags, PREREG38 assembly pass 2)

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H1 level | pooled annual height increment ratio | 0.90 to 1.10 | PREREG14 window |
| H classes | mean bias by t1 DBH class (below 12.7, 12.7 to 25, 25 and over) | absolute bias at or below 0.04 m yr⁻¹ in every class, and no class worse than qc141 by more than M_CLS | draft; PREREG23 M_CLS |
| H relht | mean bias by t1 HT/ESI bin (below 0.5, 0.5 to 0.75, 0.75 to 1, 1 to 1.25; bins of 30 or more trees) | absolute bias at or below 0.04 m yr⁻¹ | draft, PREREG37 bins |
| TOPHT | published TOPHT bias; dominant cohort t2 level | TOPHT absolute bias no larger than frozen p23_a1061; dominant deviation no larger than qc141 plus M_DOM | PREREG38 |
| V2, B1, B2 | C1 %RMSE; BA and stems ratios | as PREREG38 against qc141 | PREREG23 |

The 0.04 m yr⁻¹ bound is about 25 percent of the mean observed increment (0.19 m yr⁻¹, PREREG37 fold A); it was set in the
draft before any fit and is kept. Frozen p38_fit (1.242) is reported beside qc141.

## Long run (PREREG44 stand list grid)

The same 36 drawn stands (`v142p44/plan/stands_S{1,2,3}_SERVERONLY.csv`, read, not redrawn), 100 annual steps, arm qc_rh
only; qc141 and p38_fit trajectories are the frozen PREREG44 outputs, read. Relations and margins exactly as PREREG44.
Credibility bound (Aaron's choice, measured stand frontier): `frontier_p45_DATA.csv` (md5 63826d67, by `frontier_p45.R`
3c946234): the 99th percentile of measured TOPHT/esi8 over the 378 admitted qc_c stands at t1 and t2 (756 visits) is
**1.175** (median 0.815, maximum 1.285). Gate C: the median over drawn stands of HT at 100 years over ESI is at or below
1.175, and at most 10 percent of stands exceed it. Reported, not gated: the same ratios for qc141 (expected about 0.92) and
p38_fit (expected about 1.50), and top height at 100 years.

## Decision rule, in order

1. G0, G0b, H0, K1, G1 or G2 fails, or the fit reproduction stop fires: harness failure, no verdict.
2. H1 level, H classes or H relht fails: not adopted, failing gate named. The long run is still run and reported.
3. TOPHT, V2, B1 or B2 fails: not adopted, trade off reported.
4. Gate C fails, or qc_rh is not non inferior to qc141 under the PREREG44 rule (A) and (B): not cleared on long run grounds.
5. All pass: qc_rh is the 14.3 QC height increment candidate, a regional setting, subject to a confirmation on new data.

Where several fail, the first applicable rule is the outcome and every failing gate is reported. **Neither outcome changes
14.2.**

## Execution

New directory `~/jobs/v142p45/`; frozen runs are read, never rerun; nothing is overwritten. Chain detached: fit and its
md5, build, G0, G0b, benchmark tasks 1 to 24 (at most 2 R processes, none started at load 12 or above), PREREG38 retry
rule, scoring (r2, C0 and C1), the 36 stand long run (three tasks), assembly. Script md5s are recorded in
`logs/launch_md5s.txt` before the chain starts.
