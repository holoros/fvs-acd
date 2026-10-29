# QC height anchor reassigned from current DBH every annual step: pre-registration 33

1 October 2026, revision 1. Written before any PREREG33 model output (benchmark, G0 or grid) exists. It follows PREREG28b
(`~/jobs/v142p28b/plan/2026-09-30_v142_qc-anchor-small-only_PREREG28b.md`, md5 8934d0b5; result: rule 6, every benchmark
gate passed) and PREREG31 (`~/jobs/v142p31/plan/2026-09-30_v142_bakuzis-qc-p28b_PREREG31.md`, md5 3461fc75; result: rule 2,
not non inferior to qc141). Nothing is fitted; 1.265, 0.111 and the 25 cm knot are the PREREG28 and PREREG28b values. L and
T stay at the 14.1 values and are not re-estimated. GT1 stays a named failure. No em dashes.

## Question

PREREG31 found that `runner_p28_fb.R` sets dht.mult once per tree from its starting DBH (line 425) and carries it, so every
seeded grid tree kept 1.265 for 100 years and every recruit entered at 1. PREREG33 asks whether reassigning the QC anchor
from current DBH every annual step (below 25 cm 1.265, at and above 0.111, recomputed each year; recruits follow the same
rule from entry) (a) keeps the PREREG28b benchmark gates on screened qc_c fold B and (b) passes the PREREG31 non
inferiority test against qc141 on the Bakuzis QC grid.

## What was already seen, stated openly

The PREREG28b result and gate table (pooled height increment ratio 0.883; class biases -0.084, +0.011, -0.021 m/yr; TOPHT
+11.97 percent against the +14.63 limit; dominant cohort 0.986; C1 %RMSE 46.91; BA 0.40 and stems 24.52 points) and the
PREREG31 result in full (4 new site ordering flags; Reineke worst 1.496 against 1.266; BA ordering 14 against 13; VOL
ordering 1 against 0; p28b_small top height 13.9 to 18.5 m at 50; up to 86 percent of cohort stems 25 cm and over by 100).
Before this line, and only these: the runner and model code reads below; a parse check and a unit test of the new function
on a five row toy table (no model run); the dry runs of the two assemblies on frozen stand ins only (benchmark: p33_dyn
stood in by frozen p23_a1250, `dry/bench_assembled/`; grid: qc141 and p28b_small trajectories of PREREG31 relabelled,
`dry/grid_assembled/`, which reproduced the PREREG31 NI outcome, 4 new flags); a dry render of the figure script on those.
No p33 arm has been run on any stand or cell.

## Where dht.mult acts and the engine change

dht.mult is a per tree column of the tree list. In the model it acts in one place, `calc_dht` of `AcadianGY_13.1.r` (line
1878, `dht = dht * dht.thin.mod * dht.sbw.mod * dht.hw.mod * dht.mult`); the 14.0.4 and 14.1 overlays and
`model_b0b1b2.r` do not define `calc_dht` and never name dht.mult. It is a returned tree variable (`make_ops` rtn.vars),
so the runner's list carries it from step to step, and `bf()` sets a missing value (a new recruit) to 1. The PHASE D hooks
do not read it. Reassignment therefore needs only the runner wrapper; no model file is edited.

`home/runner_p33_fb.R` (md5 e3301b78) is `runner_p28_fb.R` (md5 0a2b2742) with one 14 line block after the PREREG11 HTFIX
line (the switch `QC_AFAC_DYNAMIC`, default "0", and the function `qcdyn()`) and two calls in the per year loop: `qcdyn()`
on the list at the start of each annual step, and on the list each step returns after `bf()` and `htfx()` (so recruits are
set on entry). Diff: `diffs/runner_p28_fb.R_to_runner_p33_fb.R.diff`. Values:

| QC_AFAC_DYNAMIC | Effect for QC stands |
|:--|:--|
| 0 (default, unset) | `qcdyn()` returns its input untouched: the runner is runner_p28_fb.R in behavior |
| 1 | every tree with finite DBH, seeded or recruit: QC_AFAC_SMALL below QC_AFAC_KNOT, QC_AFAC_LARGE at and above, every step |
| 2 (harness only) | as 1 for seeded trees (tree id at or below n_init); recruits keep the 1 that `bf()` gives, as the static runner |

Value 2 exists because value 1 with a flat 0.111 is not an identity by construction: it gives recruits 0.111 where the
frozen runner gives them 1. G0b therefore uses value 2, and value 1 at flat 0.111 is run on the same subset and reported
(G0b1) so the recruit effect is visible. The grid driver `scripts/driver_p33.R` (md5 6b63cfee) is built by the PREREG31
method (`scripts/build_driver_p33.sh`): a header, lines 1 to 433 of the new runner byte for byte, and the PREREG31 block
with the same two `qcdyn()` calls added (`diffs/driver_p31.R_to_driver_p33.R.diff`, `diffs/p31_block.R_to_p33_block.R.diff`).

## Arms

| Arm | Setting | Where | Role |
|:--|:--|:--|:--|
| p33_dyn | QC_AFAC_SMALL 1.265, QC_AFAC_LARGE 0.111, KNOT 25, QC_AFAC_DYNAMIC 1 | benchmark tasks 1 to 20; grid | candidate |
| p33_g0a | PREREG28b settings, QC_AFAC_DYNAMIC unset | benchmark tasks 21 to 24 | G0a |
| p33_g0b | SMALL = LARGE = 0.111, KNOT 25, QC_AFAC_DYNAMIC 2 | benchmark tasks 25 to 28 | G0b |
| p33_g0b1 | SMALL = LARGE = 0.111, KNOT 25, QC_AFAC_DYNAMIC 1 | benchmark tasks 29 to 32 | reported |
| qc141 | QC_AFAC 0.111, QC_AFAC_DYNAMIC unset, through driver_p33.R | grid | reference |
| p33_g0d | as p33_g0b, through driver_p33.R g0 mode | three real stands | G0d |

Benchmark taskmap `home/work/p33_taskmap_DATA_2026-10-01.csv`: rows 1 to 20 are the PREREG28b rows (qc_c 19 chunks of 20
admitted stands, qc_fl 1) with the arm renamed; rows 21 to 32 are qc_c chunks 1, 10 and 19 (rows 1 to 20, 181 to 200, 361
to 378) and qc_fl for the three G0 arms. **The G0 tests use this stated subset** (58 qc_c stands and all qc_fl), because
running two further full arms would double the run time.

## Harness and bundle

Bundle `home/`: the PREREG28b home without out*, logs and tables; its md5 list (47 files) is identical to the PREREG28b
list (`logs/bundle_check.txt`). Task driver, launcher, retry and scoring scripts are PREREG28b copies with the taskmap, arm
case, QC_AFAC_DYNAMIC, runner, job root and arm list changed, and the load test made strict (no start while the load is 12
or above); every diff is in `diffs/`. Scorer `2026-09-27_v142_volconv_score.R` (md5 019df238) and height key helper (md5
59196106) unedited. Grid wrapper `scripts/run_p33.sh` is PREREG31 `run_p31.sh` with paths, arm case, runner and driver
changed. At most 2 R model processes at once; one chain, `scripts/chain_p33.sh`, started with setsid nohup, stops at the
first failure and checks every md5 in `logs/launch_md5s.txt` first. **Retry rule:** every stand whose FAIL_REASON is the
host time limit is rerun alone by STAND name through STAND_KEEP_FILE, up to three attempts, for every benchmark arm.

## Harness gates

| Gate | Test | Threshold |
|:--|:--|:--|
| G0a | p33_g0a against frozen p28b_small, qc_c subset and qc_fl: every _p column, ING_p, RUN_OK and per tree t2 ht, dbh, expf, ing (the PREREG28 H0 test, `scripts/g0_cmp_p33.R`) | worst scaled difference at or below 1e-9 |
| G0b | p33_g0b against frozen p19_a0111, same subset and test | at or below 1e-9 |
| K1 | RUN_OK other than 1 for p33_dyn after retry | 0 |
| G0 | qc141 through driver_p33.R g0 mode, three stands, against frozen p19_a0111 (PREREG31 G0, `g0_cmp_p31.R` unedited) | at or below 1e-9 |
| G0d | p33_g0d through driver_p33.R g0 mode, same stands and test | at or below 1e-9 |
| G0c | step aware checker reproduces the stored v1402 report (PREREG31 G0c) | identical |
| G1 | every grid trajectory 100 years, 101 rows, run_ok 1 | 72 of 72 |
| G2 | the qc141 grid through driver_p33.R equals the PREREG31 qc141 trajectories, every cell and year | identical (tolerance 0) |

**H0 is cited from G0a**, which applies the PREREG28 H0 test to the switch 0 path, and from G0b. G2 replaces the PREREG31
dry cell test (it contains that cell) and also shows that switch 0 leaves the long run unchanged.

## Benchmark gates (screened qc_c fold B), identical to PREREG28b

| Gate | Test | Threshold |
|:--|:--|:--|
| H_inc pooled | pooled annual height increment ratio | absolute deviation from 1 smaller than at 0.111 |
| H_inc classes | mean bias by t1 class (below 12.7, 12.7 to 25, 25 and over) | no class worse in absolute value than at 0.111 by more than 0.03 m/yr |
| TOPHT | published TOPHT bias; dominant cohort t2 level | no worse than at 1.061; dominant cohort deviation no worse than at 0.111 plus 0.02 |
| V2 | C1 %RMSE | %RMSE(0.111) minus %RMSE(arm) at or above -0.5 |
| B1, B2 | basal area, stems ratio | absolute deviation no worse than 0.111 by more than 1.0 and 2.0 points |

Assembly `scripts/2026-10-01_v142_p33_assemble_bench.R` (md5 ae24ea5e) is the PREREG28b assembly (revision 2, md5
90e6c5bc) with arm names, roots and output names changed, H0 read from `logs/g0_result.csv`, the verdict text set to the
order below, and two added hard stops: the p28b_small height and stand rows must reproduce the PREREG28b assembled tables at
1e-9 [F9] (`diffs/p28b_assemble_to_p33_assemble_bench.diff`). Margins are parsed from the PREREG23 assembly; the PREREG19
and PREREG23 frozen reproductions are kept. Reference p19_a0111, TOPHT comparator p23_a1061, p28b_small reported.

## Grid gates, identical to PREREG31

Synthetic QC stand, ESI 17.3, 18.5, 19.1, 19.8 m, N0 1,500, 3,000, 6,000, mixes BF, SM, MX (cell files copied, md5
identical), 100 annual steps, one DBH draw (seed 20260930), relations Reineke, Frontier, Eichhorn, Site ordering HT, VOL,
BA, Sukachev, Yield density, Magnitude and HT monotone on five year points, thresholds from the PREREG31 file (copied, md5
fa5a852a). NI: (A) no relation and unit flags for p33_dyn where qc141 passes, and (B) on every relation p33_dyn flags,
its worst margin is not larger than qc141's (tolerance 1e-9). Assembly `scripts/assemble_p33_grid.R` (md5 c63b2932) is
PREREG31 `assemble_p31.R` with the candidate, root, thresholds path, output names and outcome labels changed, G0d added
and G2 as above.

## Decision rule, in order

1. G0a, G0b, K1, G0, G0d, G0c, G1 or G2 fails: harness failure, no verdict.
2. A benchmark gate fails: not adopted; the gate (and class) named.
3. Benchmark passes and NI fails: not cleared; the relation and unit named.
4. Both pass: the dynamic anchor is the 14.2 QC candidate cleared for release consideration as a QC regional setting.

Both parts run to completion whatever the benchmark shows. 14.1 is unchanged in every case.

## Expectation, stated now

Benchmark: over one remeasurement interval few trees cross 25 cm, so p33_dyn should sit close to p28b_small; the 12.7 to 25
cm class bias and TOPHT may fall slightly (trees that cross lose growth for the rest of the interval) and recruits gain a
little (1.265 against 1). All benchmark gates are expected to pass. Grid: seeded trees grow under 1.265 until they reach 25
cm, then under 0.111, so top height should rise like p28b_small early and then flatten once the dominant cohort passes 25
cm; the reference qc141 stays as in PREREG31. The relations at risk are site ordering of HT (the flattening is reached at
different ages by site), HT monotone and Reineke; whether BA and VOL ordering improve is open.

## Reported, not gated

G0b1 (recruit effect at flat 0.111); qc_fl gates; the PREREG31 realism table and dht.mult table for p33_dyn; top height,
stems and volume ratios to qc141; p28b_small (PREREG31 out/) in the grid figure.

## Caveats

The switch acts in the runner wrapper. The 25 cm knot and 1.265 were chosen for a one interval anchor on fold A and are
reused, not refit. The G0 tests cover a stated subset. The grid start (2 to 5 cm cohort, recruits at 5 cm) is not a
benchmark stand. The QC ESI span is narrow (2.5 m).

## Constraints

New directory `~/jobs/v142p33/` only; PREREG19, 23, 28b and 31 files are read, never written. Model files unedited. Frozen
runs are not rerun in place. No coordinates. Nothing is sent outside.
