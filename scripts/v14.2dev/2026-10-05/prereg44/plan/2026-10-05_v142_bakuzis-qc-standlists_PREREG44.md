# Bakuzis QC grid from measured stand lists, 1.242 against 0.111: pre-registration 44

5 October 2026, revision 1. Written before any PREREG44 stand has been drawn or projected. It registers the 5 October draft
(md5 7ddb42e1) with Aaron's choices of the same day: the two relation changes are accepted, and the outcome **informs 14.3
only and cannot reopen the 14.2 QC decision** (14.2 keeps QC_AFAC 0.111). Nothing is fitted. L and T are not re-estimated.
GT1 stays a named failure. No coordinates. No em dashes.

## Question

PREREG31 and PREREG41 started every trajectory from a seedling cohort, where ingrowth drives stems from 1,000 to about 2,800
ha⁻¹ before any self thinning, so Reineke failed in every trajectory of both arms. PREREG44 asks whether p38_fit (QC_AFAC
1.242 for every tree) is non inferior to qc141 (0.111, 14.1 as shipped) on the long run law like relations when each
projection starts from a measured qc_c t1 stand list.

## Driver change, reviewed before registration

`scripts/driver_p44.R` (md5 7d5da479) is built by `build_driver_p44.sh` from the PREREG31 driver (md5 467fb518) with two
edits, each asserted to match exactly once: the mode check admits `slgrid` beside `g0` and `grid`, and a new `slgrid` branch
(`parts/slgrid_branch.R`) is inserted before the g0 branch. Diff: 32 lines added (5 of them header), 2 replaced, none
otherwise removed (`diffs/driver_p31.R_to_driver_p44.R.diff`). The slgrid branch builds each starting list exactly as mode
g0 does (the t1 trees, dht.mult from the runner line 425 expression) and records with the mode grid recorder. Wrapper
`scripts/run_p44.sh` (md5 ea23c093) is the PREREG41 wrapper (md5 d7fd3101) with job paths, log tag and driver changed and
`P44_STANDS` exported; its environment block, including both arm settings, is unchanged (diff in `diffs/`). One cosmetic
defect is recorded: the wrapper's added comment sits above the shebang line; the wrapper is always invoked as `bash
run_p44.sh`, so it has no effect.

## Starting states, fixed now

`scripts/select_p44.R`. Admitted qc_c stands (esi8 finite and above 2; the script stops unless there are 378, the PREREG31
count), screened (PREREG19 cut flag FALSE for p19_a0111) and RUN_OK 1 in frozen p19_a0111 (md5 979101be); fold from the
first hex digit of md5(SITE) as in PREREG23. ESI bins: quartiles of site level esi8 over admitted qc_c. SDI bins: terciles of
t1 SDI (trees 4 cm and over, SDI = TPH (QMD/25)^1.605, the runner's metrics form) over admitted screened RUN_OK stands of both
folds. Draw: fold B only, `set.seed(20261005)`, three stands per cell sampled from the cell's stands sorted by STAND, all of
them if fewer than three. 12 cells, up to 36 stands, two arms. If fewer than 24 stands are drawn the run stops as a harness
failure. Stand identifiers stay in `*_SERVERONLY` files. Species mix, elevation, management state and years since thinning
(UNKNOWN) are each stand's own. 100 annual steps, read every five years. Scoring threshold for the 9.1 cm metrics as PREREG31.

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | driver_p44 mode g0, qc141, the three PREREG31 G0 stands, every `_p` column and ING_p against frozen p19_a0111 | worst scaled difference at or below 1e-9 | PREREG31 G0, `g0_cmp_p31.R` (md5 b0e9ed57) |
| G0b | driver_p44 mode grid, qc141 cell MX_E19.8_N6000, 100 years, against the frozen PREREG31 dry trajectory | identical, every numeric column | PREREG31 G2 file `dry/dry_qc141_MX_E19.8_N6000.csv` |
| G1 | every stand list trajectory runs 100 years with 101 rows, run_ok 1 | all, both arms | PREREG31 G1 |
| G2 | age 0 stems (all sizes) and basal area at 4 cm equal the measured t1 list | worst scaled difference at or below 1e-6, every stand and arm | tree_init md5 6fb1ff68 |

G0 and G0b are the identity gates that the existing modes are unchanged by the driver edit.

## Relations

The PREREG31 rules and QC thresholds (`thresholds_p31_DATA_2026-09-30.csv`: frontier log10 TPH = 5.0914 - 1.4690 log10 QMD,
BA 51.73 m² ha⁻¹ and SDI 1,178 at the 99.9th percentile), with the two registered changes and the mapping that a stand list
design forces:

- **Reineke** (stand): change 1. Points from the first five year point at which relative density RD = TPH_s over the frontier
  TPH at QMD_s reaches 0.5, onward, with QMD advancing more than 0.5 cm per step; slope of log TPH on log QMD inside (-2.2,
  -1.2). A stand that never reaches RD 0.5, or has fewer than three qualifying points, is reported as not evaluated and is
  not flagged (it cannot follow a self thinning line).
- **Frontier, Magnitude, HT monotone** (stand): unchanged.
- **Site ordering** HT, VOL, BA (SDI bin): change 2. Inversions among the four ESI bin means at ages 5 to 100.
- **Eichhorn** (SDI bin): mean CV of VOL across the ESI bin mean trajectories at 8 matched top heights, below 0.15.
- **Sukachev** (ESI bin): mean cohort stems lost since age 0 strictly increasing across SDI bins at ages 50 and 100.
- **Yield density** (ESI bin): CV of SDI bin mean VOL at 100 below 0.15 and below the CV at 30.

The last three are the PREREG31 relations with N0 replaced by the SDI bin and the mix by the observed mix; this is a mapping,
not a rule change. Reported, not gated: site ordering of growth since age 0 (ESI bin means of HT and VOL gain), height,
stems and volume ratios at 50 and 100 years, and carried dht.mult.

## Decision rule, in order

p38_fit is non inferior if (A) on no relation and unit does it flag where qc141 passes, and (B) on every relation where it
flags, its worst margin is not larger than qc141's (tolerance 1e-9). Exactly one:

1. G0, G0b, G1 or G2 fails: harness failure, no verdict.
2. (A) or (B) fails: not cleared; 1.242 is not supported on long run grounds for 14.3, failing relations named.
3. Both hold: cleared; 1.242 is a 14.3 QC candidate on long run grounds, still subject to the 14.3 benchmark gates.

**Neither outcome changes 14.2.**

## Expectation, stated now

Reineke is evaluated on few stands, since most measured QC stands sit below RD 0.5 at t1. Site ordering on bin means may
invert in both arms because real stands differ in more than ESI; under the non inferiority rule that affects both arms alike.

## Execution

`scripts/chain_p44.sh`, detached on firebreather: G0, G0b, then six tasks (two arms by three SDI bins), at most two R model
processes, none started at a load average of 12 or above, then `scripts/assemble_p44.R`. A dry assembly on synthetic
trajectories (`make_fake_p44.R`, no model run) is allowed before the chain. Script md5s are recorded in `logs/launch_md5s.txt`
before the chain starts. New directory only (`~/jobs/v142p44/`); frozen runs are read, never rerun; nothing is overwritten.
