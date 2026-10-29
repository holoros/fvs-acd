# Bakuzis QC grid for the 14.2 QC height anchor candidate p28b_small: pre-registration 31

30 September 2026, revision 1. Written before any PREREG31 grid trajectory has been run. It follows PREREG28b
(`~/jobs/v142p28b/plan/2026-09-30_v142_qc-anchor-small-only_PREREG28b.md`, md5 8934d0b5; RESULT md5 66f4a1c1), which closed
on its rule 6 and made adoption into a release conditional on a Bakuzis QC grid under its own pre-registration. The method is
PREREG26 (`~/jobs/v142p26/plan/2026-09-30_v142_bakuzis-ns-v141LTfi_PREREG26.md`, revision 2, md5 291bb1ec). Nothing is
fitted. L and T are not re-estimated. GT1 stays a named failure. No em dashes.

## Question

p28b_small sets the QC height increment multiplier dht.mult to QC_AFAC_SMALL 1.265 for trees below 25 cm t1 DBH and to
QC_AFAC_LARGE 0.111 (the shipped 14.1 value) at and above, knot 25 cm. It passed every PREREG28b benchmark gate on one
remeasurement interval. PREREG31 asks only whether p28b_small is non inferior to 14.1 (arm qc141, QC_AFAC 0.111 for every
tree through the same runner) on the long run law like relations.

## What was seen already, stated openly

PREREG28b on screened qc_c fold B: H0 0 (cited from PREREG28 p28_g0), K1 0 of 378; pooled height increment ratio 0.883
(0.742 to 1.113) against 0.086 at 0.111; bias below 12.7 cm -0.084 m/yr (-0.254 at 0.111), 12.7 to 25 cm +0.011 (-0.161),
25 cm and over -0.021 (-0.021); published TOPHT bias +11.97 percent against +6.29 at 0.111 (limit +14.63); dominant cohort
0.986 (0.922); C1 %RMSE 46.91 (46.76); BA 0.40 and stems 24.52 points (0.17, 24.23). The PREREG26 method and its NS result
(rule 2 on site ordering of BA by one inversion) were read in full.

Before this line, and only these: (1) the qc_c frame summaries in `explore/` (ESI percentiles, species shares, scoring
thresholds, elevation, management state); (2) the threshold re-derivation below (`scripts/thresholds_p31.R`, no model run);
(3) G0 (below; passed); (4) one smoke of one cell for 3 years, p28b_small MX ESI 19.8 N0 6,000
(`dry/smoke3_p28b_small_MX_E19.8_N6000.csv`). The smoke shows how the runner carries dht.mult (next section). A first
smoke attempt stopped on a relative path before any projection (`logs/dry_smoke_attempt1_relative_path_error.log`).

## How the runner assigns dht.mult over time, pre-registered

Runner line 425 builds the initial tree list with `dht.mult = ifelse(it$DBH < QC_AFAC_KNOT, QC_AFAC_SMALL, QC_AFAC_LARGE)`
for QC when any of the three QC_AFAC_* variables is set, else QC_AFAC. It is evaluated once, from the DBH at the start of
the run. dht.mult is one of the model's returned tree variables (`make_ops` rtn.vars), so each tree carries its initial
value through every annual step; `bf()` sets any missing multiplier to 1, and `htfx()` (line 413) acts only on NS with
HTFIX_B set. So in a 100 year projection: every seeded tree (DBH 2 to 5 cm, all below 25 cm) keeps 1.265 under p28b_small
and 0.111 under qc141 for 100 years, including after it crosses 25 cm; every ingrowth recruit enters at 1 in both arms. The
smoke confirms both (cohort EXPF weighted mean dht.mult 1.265 at years 0 to 3; recruits 1). **The grid is therefore a test of
the anchor as the runner implements it**, not of a size dependent anchor reassigned by current DBH. The runner has no
environment switch that reassigns dht.mult by current DBH (line 425 is the only QC_AFAC use; `htfx` is NS only), so the
reported reassignment arm is not added; doing so would need a new hook, which is outside this plan. The driver records per
year the cohort and recruit mean dht.mult and the stems of cohort trees at 25 cm and over, reported, not gated.

## Driver and environment

`scripts/driver_p31.R` (md5 467fb518) is a 7 line header, then lines 1 to 419 of `runner_p28_fb.R` (md5 0a2b2742) byte for
byte, then `parts/p31_block.R`, which replaces runner lines 420 to 486 exactly as PREREG26 replaced its runner's loop: the per
stand setup and per year loop move into a function without the PHASE D hooks. The QC dht.mult expression is cut from runner
line 425 by `build_driver_p31.sh` and inserted verbatim. Diff: `diffs/runner_p28_fb.R_to_driver_p31.R.diff`. Environment:
`scripts/run_p31.sh`, the PREREG28b `run_task_p28b.sh` block verbatim (bench141 v141LT: IMULT 2.5, no height form, no
threshold matching, NB_AFAC 0.579, SRC_TST UNKNOWN, model file md5 checks) with only the job paths, the arm case and the
driver changed; diff `diffs/run_task_p28b.sh_to_run_p31.sh.diff`. HOME is the PREREG28b bundle, read only; counters go to
`logs/`.

## Synthetic QC stand

Taken from the 378 admitted qc_c stands (esi8 finite and above 2, the runner's INDOMAIN rule): PROV QC, managed (MGD_USE 1;
all 378 admitted stands carry MANAGED 1), years since thinning UNKNOWN (SRC_TST, as the benchmark), elevation 385 m (the
median; range 23 to 1,087). Scoring threshold 9.1 cm, the modal SCORE_MINDBH_OBS (232 of 378). Ingrowth threshold is the
runner's 5.0 cm in both arms (no threshold matching, as PREREG28b). Metrics at 4 cm (every relation) and 9.1 cm (frontier,
magnitude, stems report), as PREREG26.

## Grid

ESI 17.3, 18.5, 19.1 and 19.8 m: the 5th, 33.3rd, 66.7th and 95th percentiles of admitted qc_c plot level ESI (17.28,
18.48, 19.07, 19.81), rounded to 0.1 m. The QC ESI range is narrow (10th to 90th percentile 17.34 to 19.52), so the grid
spans 2.5 m and site ordering is a stringent test. N0 1,500, 3,000 and 6,000. Mixes: BF (pure balsam fir, the dominant
species on 144 of 378 stands and 80 percent or more of BA on 38), SM (pure sugar maple, dominant on 50, 80 percent or more
on 22), and MX, the qc_c t1 mix by basal area share over species with at least 4 percent of BA (91.6 percent of all BA),
largest remainder rounding to 40 records: BF 15, SM 5, PB 4, WS 3, RM 3, QA 3, BS 3, YB 2, WC 2. 36 cells, two arms, 72
trajectories, 100 annual steps each, read at five years. One DBH draw, uniform 2 to 5 cm, seed 20260930 (the PREREG26 draw),
shared by every cell and arm; heights imputed by the model.

| Arm | Setting | Role |
|:--|:--|:--|
| qc141 | QC_AFAC 0.111, no QC_AFAC_SMALL, LARGE or KNOT | reference (14.1) |
| p28b_small | QC_AFAC_SMALL 1.265, QC_AFAC_LARGE 0.111, QC_AFAC_KNOT 25 | candidate |

## Harness gates

| Gate | Test | Threshold |
|:--|:--|:--|
| G0 | qc141 through `driver_p31.R` (mode g0) on the first three RUN_OK stands of frozen p19_a0111 qc_c (`~/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv`, md5 979101be), every `_p` column and ING_p | worst scaled difference at or below 1e-9 |
| G0c | The step aware checker (md5 297e2ef3) rerun on the stored v1402 `traj_v1402_L1_s5` reproduces the stored report (md5 7a04368c) | identical below the header path line |
| G1 | Every trajectory runs 100 years with 101 rows, run_ok 1 | 72 of 72 |
| G2 | The dry cell (qc141, MX ESI 19.8 N0 6,000, run alone first) equals the same cell in the grid | identical |

G0 was run before this line: worst scaled difference 0 over 3 stands and 12 columns (`dry/g0_dry_check.csv`); the chain
records it again into `logs/g0_result.csv` from the same output, without a model rerun.

## Relations (unit, test, margin, provenance)

PREREG26 rules unchanged, on the five year points (21, ages 0 to 100):

- **Reineke** (trajectory): slope of log TPH on log QMD over points whose QMD advances more than 0.5 cm per step; pass inside
  (-2.2, -1.2). Margin: distance outside the band. Checker rule.
- **Frontier** (trajectory, 9.1 cm): no point above the QC tau 0.99 frontier re-derived from qc_c t1 (378 stands, trees 9.1
  cm and over, quantreg): log10 TPH = 5.0914 - 1.4690 log10 QMD. Margin: largest log10 exceedance.
- **Eichhorn** (mix by N0, across ESI): mean CV of VOL across ESI at 8 matched top heights below 0.15. Margin: CV - 0.15. The
  observed QC CV cannot be derived: no 2 m top height bin holds 20 stands in each ESI tercile (0 bins); stated, not used.
- **Site ordering** HT, VOL, BA (mix by N0): no age 5 to 100 at which a lower ESI exceeds a higher one. Margin: inversions.
- **Sukachev** (mix by ESI): cohort stems lost strictly increasing in N0 at ages 50 and 100. Margin: violations of 4.
- **Yield density** (mix by ESI): CV of VOL across N0 at 100 below 0.15 and below the CV at 30. Margin: max(CV100 - 0.15,
  CV100 - CV30).
- **Magnitude** (trajectory, 9.1 cm): BA and SDI never above the qc_c t1 99.9th percentiles, BA 51.73 m2/ha and SDI 1,178.
  Margin: largest ratio minus 1.
- **HT monotone** (trajectory): top height never falls more than 0.01 m between points. Margin: largest fall.

VOL is NSVB total volume from the runner's `metrics()`. The step aware checker also runs on each arm and mix as a cross check.

## Decision rule, in order

p28b_small is non inferior (NI) if (A) on no relation and unit does it flag where qc141 passes, and (B) on every relation it
flags anywhere, its worst margin is not larger than qc141's worst margin on that relation (tolerance 1e-9). Exactly one:

1. G0, G0c, G1 or G2 fails: harness failure, no verdict.
2. NI fails: not cleared; the relation and unit are named.
3. NI passes: cleared for release consideration as a QC regional setting.

14.1 is unchanged either way.

## Reported, not gated

Top height at ages 50 and 100 by ESI, mix and N0, ratio p28b_small to qc141; stems (4 and 9.1 cm) and volume at 100, ratio.
The PREREG26 realism test applied to every QC ESI level (all above 15 m): implausibly low if the ratio is below 0.90 or
candidate top height at 50 is below 0.85 ESI (same test on qc141). Because the candidate raises height, the mirror is also
reported: ratio above 1/0.90 or top height at 50 above 1.15 ESI. The dht.mult table. The per unit table for every relation.

**Expectation.** The whole seeded cohort runs at 1.265 against 0.111, an elevenfold height increment multiplier for 100 years,
while recruits run at 1 in both arms. Top height should be much higher under p28b_small, with the reference's top height
possibly set by recruits rather than the cohort. The relations at risk for the candidate are magnitude, frontier and site
ordering of HT; the mirror realism test is likely to report high top height. None of this is gated beyond the NI rule.

## Caveats

The multiplier is fixed from the initial DBH (above), so the grid does not test a reassigned size dependent anchor. The
synthetic start (2 to 5 cm cohort, recruits at 5 cm) is not a stand the benchmark scored. The ESI span is narrow. The small
tree value was fitted on fold A (PREREG28) and is reused. GT1 stays a named failure; L and T are not re-estimated.

## Constraints

New directory `~/jobs/v142p31/` only; PREREG28b, PREREG26 and PREREG19 files are read, never written. Model files and the
runner are unedited. Frozen runs are not rerun. At most 2 R model processes, none started while the 1 minute load average is
12 or above, through a chain started with setsid nohup. No coordinates. Nothing sent outside.
