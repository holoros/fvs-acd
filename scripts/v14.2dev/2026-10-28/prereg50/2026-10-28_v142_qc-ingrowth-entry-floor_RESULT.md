# QC ingrowth entry size and scoring floor handling, for 14.3: PREREG50 result

28 October 2026. Plan `plan/2026-10-28_v142_qc-ingrowth-entry-floor_PREREG50.md`, revision 1, md5 6ea850d4a9d0cf058dde4665e8e7b095,
registered on firebreather at 2026-10-28T06:55:09-03:00 before any PREREG50 script ran (`logs/prereg_md5.txt`). Script md5s
were recorded at 07:27:09 before the chain started (`logs/launch_md5s.txt`; runner copy `runner_p50_fb.R` 7bd249b2, task driver
`run_task_p50.sh` c355e851, `p50_g2.R` aa6ab9a4, `p50_split.R` 29965434, `p50_boot.R` fbe2cc73). The assembly script
`p50_assemble.R` (bedeaead) md5 was recorded before it ran (`logs/assemble_md5.txt`). Arms: R0 = frozen qc141 (p19_a0111, results
md5 979101be), read only; G2, E1 and S2 = new runs of the runner copy in `~/jobs/v142p50/home/`. Nothing fitted. No engine file,
coefficient or default changed. L and T of 14.1 were not touched, and GT1 stays a named failure. Informs 14.3 only; 14.2 keeps
QC_AFAC 0.111 and NB_AFAC 0.579. Aggregates only; stand identifiers stay in `*_SERVERONLY` files on firebreather. No coordinates.
No em dashes. Deviations are listed below and in `2026-10-28_v142_qc-ingrowth-entry-floor_DEVIATIONS.md`.

## Outcome

**Rule 3, artifact (HA): the 14.3 track is a benchmark and runner convention (ingrowth threshold matched to the inventory
floor), not an ingrowth coefficient.** Labels: "previously inspected population"; "threshold support unknown". The verdict is
not floor group sensitive. S2 does not overshoot beyond the registered margin on fold B. G7 added no label. The ungated fold A replication reads rule 4 (S2 just past the overshoot bound). The E1 survivor
ratio is 1.0943 (1.0489 to 1.1472), inside 0.90 to 1.10. No outcome changes 14.2. Source:
`assembled/gyr142-p50-verdict_DATA_2026-10-28.txt` and `gyr142-p50-decision_DATA_2026-10-28.csv`.

Decision rule, in order (fold B, all 160 screened stands; D_R0 = 37465 trees ha⁻¹, so 1/3 of D_R0 = 12488):

1. Harness gates G0 to G6: all pass, so a verdict is allowed.
2. Overcorrection: D_E1 = -2720, below 0, but |D_E1| is below 12488. Does not fire.
3. Artifact: E1 meets the bar (X_E1 1.0726, lower limit 0.8700 above 0.5, D_E1 above -12488). S2 meets the bar (X_S2
   1.2964, lower limit 1.0480, D_S2 = -11106 above -12488). **Fires.**
4. to 6. Not reached.
7. Labels: the 153 stand floor group (9.1 to 9.7 cm) also reads rule 3 (X_E1 1.0562, 0.8552 to 1.3932; X_S2 1.2704,
   1.0285 to 1.6665), so no "floor group sensitive" label. L2 found no threshold support, so "threshold support unknown".
   D_S2 is not below -12488, so no "S2 overshoots". G7 found no QC run with the switch.

The S2 margin to the overshoot bound is narrow: D_S2 = -11106 against -12488, so the open loop S2 convention overpredicts
stems by 7.18 points (1.44 to 13.69). Both X values exceed 1. As the plan anticipated, this is partly the survivor excess R0
already carries (S_p 117117 against S_o 107041). Predicted new stems at the floor are 40235 (E1) and 48637 (S2), against 47607
observed.

## Harness gates (`assembled/gyr142-p50-gates_DATA_2026-10-28.csv` and the G files)

| Gate | Value | Threshold | Pass |
|:--|:--|:--|:--|
| G0 R0 reproduces PREREG48 fold B | stems deviation 24.22615 points, D 37465, observed I 47607, predicted I 65.4935 trees ha⁻¹ | equal to the published rounding | yes |
| G1 R0 entry facts, screened fold B (`gyr142-p50-G1`) | minimum ingrowth DBH 5.0 cm, median 5.67 cm (5.6686), 7 of 6042 records at or above the floor, all sizes 51728 trees ha⁻¹ | equal to the published rounding | yes |
| G2 runner copy against frozen qc141 (`gyr142-p50-G2`) | 313 of 313 screened stands identical in `_results` (313 lines), `_pred_t2_tree` (41474), `_t1_split_tree` (30011) and `_pred_yr1_tree` (31206); 19 chunk headers identical | identical text | yes |
| G3 trace and entry DBH (`gyr142-p50-G3`) | E1 and S2: 378 of 378 stands traced; maximum differences of threshold against trace, results and floor all 0; 1461 year 1 ingrowth records each, entry DBH minus floor at most 0 | at or below 1e-9 | yes |
| G4 S2 against E1 year 1 (`gyr142-p50-G4`) | 20 stand sample: maximum relative difference 0 for totals and species shares, 0 species mismatches (all 378 stands: also 0, reported) | at or below 1e-9 | yes |
| G5 RUN_OK (`gyr142-p50-G5`) | E1 378 of 378; S2 378 of 378; no stand hit the host time limit in any arm, so the retry rule ran nothing (`logs/chain.txt`) | 0 failures | yes |
| G6 folds (`gyr142-p50-G6`) | 378 stands; 0 differences between `stand_frame` and `fold_of`, 0 between `fold_of` and the PREREG22 rule | identical | yes |
| G7 prior floor matched QC runs (`logs/lookups_G7.csv`) | 29 files contain `ING_MIN_FROM_SCORE=1`; none names qc_c or qc_fl | label only | no label |

PREREG48 T1 frame check, recomputed (`gyr142-p50-T1-coverage`): 0 failures, worst scaled difference 0, 0 split map failures, all
stands covered (screened 153 fold A, 160 fold B; cut 33 and 32).

## Quantities, screened qc_c fold B (`assembled/gyr142-p50-pools_DATA_2026-10-28.csv`)

Stems are trees ha⁻¹ at or above the stand floor, summed over stands. D is observed minus predicted. Intervals are 95% site
cluster bootstrap limits (B = 1000, seed 20261001, 152 sites, the same draws for every arm).

| Quantity | R0 (frozen qc141) | E1 (engine, threshold at floor) | S2 (open loop at floor) |
|:--|--:|--:|--:|
| Observed stems N_o | 154648 | 154648 | 154648 |
| Predicted stems N_p | 117183 | 157368 | 165754 |
| D | 37465 | -2720 | -11106 |
| Stems deviation, points | 24.226 (18.959 to 29.910) | -1.759 (-8.065 to 3.727) | -7.181 (-13.692 to -1.438) |
| Explained share X | 0 | 1.0726 (0.8700 to 1.4083) | 1.2964 (1.0480 to 1.6915) |
| New stems at the floor, observed I_o / predicted | 47607 / 65.5 | 47607 / 40235 | 47607 / 48637 |
| Survivors S_o / S_p | 107041 / 117117 | 107041 / 117133 | 107041 / 117117 |
| Survivor ratio S_p over S_o | 1.0941 (1.0488 to 1.1471) | 1.0943 (1.0489 to 1.1472) | 1.0941 (as R0) |

S1 bracket (reported, never gated): engine ingrowth at all sizes under R0 sums to 51728 trees ha⁻¹, against 47607 observed new
tags at or above the floor (`gyr142-p50-G1`).

**Floor groups, fold B** (`gyr142-p50-pools`, `gyr142-p50-floorgroup-counts`): 153 stands at 9.1 to 9.7 cm and 7 at 31 to
34 cm, as expected.

| Group | Arm | D | X | I_o / predicted new stems |
|:--|:--|--:|:--|--:|
| 9.1 to 9.7 cm (153) | R0 | 37112 | 0 | 47175 / 65.5 |
| | E1 | -2086 | 1.0562 (0.8552 to 1.3932) | 47175 / 39247 |
| | S2 | -10034 | 1.2704 (1.0285 to 1.6665) | 47175 / 47212 |
| 31 to 34 cm (7) | R0 | 353 | 0 | 432 / 0 |
| | E1 | -634 | 2.797 (1.812 to 9.329) | 432 / 989 |
| | S2 | -1072 | 4.036 (2.781 to 12.653) | 432 / 1424 |

On the 7 high floor stands both conventions overpredict new stems by a wide relative margin (989 and 1424 against 432). This is
the threshold range whose support is unknown (L2). The stands are few and the pooled verdict does not depend on them.

**Reported, not gated, fold B** (`gyr142-p50-rmse`; R2S point formula):

| Arm | QMD %RMSE | BA %RMSE | C1 volume %RMSE | C1 volume ratio p/o |
|:--|--:|--:|--:|--:|
| R0 | 20.57 | 37.32 | 46.76 | 1.115 |
| E1 | 9.42 | 36.72 | 48.47 | 1.211 |

Matching the threshold roughly halves QMD error. It leaves BA error about unchanged and raises C1 volume error and its
overprediction ratio.

## Fold A replication (reported, not gated)

On all 153 screened fold A stands (147 sites), the replication reads **rule 4, not rule 3**:

- **E1** meets the bar: X_E1 1.0853 (0.8405 to 1.5176), D_E1 = -2887.
- **S2** fails the bar on the overshoot clause: D_S2 = -11458 against minus 1/3 of D_R0 = -11284 (D_R0 33852); X_S2 1.3385
  (1.0433 to 1.8574).

The fold A 9.1 to 9.7 cm group (138 stands) reads rule 3. Fold A also has 5 screened stands with floors outside both named
groups (`gyr142-p50-floorgroup-counts`). Fold A therefore agrees with fold B on E1 and puts the open loop S2 convention just
past the overshoot bound.

## Reading

Matching the engine's ingrowth threshold to the inventory floor removes the QC stems deficit. Under E1 the fold B deviation goes
from 24.2 points low to 1.8 points high, with an interval that spans 0. So the PREREG48 deficit is mostly a floor handling
artifact: the scorer counts engine ingrowth that enters near 5 cm, below floors of 9.1 cm and up. It is not evidence of missing
recruitment, though the population was previously inspected and threshold support is unknown. Whether that convention is right for 14.3 is a benchmark choice, and this result does not change 14.2.

Three cautions:

- **The run is not confirmatory.** The population was previously inspected.
- **Threshold support is unknown.** Lookup L2 found no record that the engine's ingrowth equations were fitted at thresholds
  of 9 to 34 cm. At 31 to 34 cm both conventions overpredict severalfold.
- **The open loop S2 convention runs high.** It is 7.2 points high on fold B and crosses the registered overshoot bound on
  fold A. E1, which lets ingrowth compete and grow, is the closer of the two conventions on both folds.

The survivor excess that PREREG48 found (ratio about 1.09) is unchanged under E1. It is now the larger remaining stems error and
is not addressed here.

## Deviations (also in `2026-10-28_v142_qc-ingrowth-entry-floor_DEVIATIONS.md`)

1. A laptop commit pushed a pre red team 2 copy of the plan to the server first. It was caught by md5 before registration and
   kept, unregistered, as `plan/..._PREREG50_PREV_20261028.md`.
2. `p50_boot.R` had a parse error and was fixed before the dry run (old copy in `scripts/_prev/`).
3. The first dry run named its runner outputs `dry_*`, which the `cNNN` reader pattern does not match. The files were renamed
   to `c000_*` with contents unchanged, `dry_p50.sh` was fixed (old copy in `scripts/_prev/`), and only the dry analysis was
   rerun (partial outputs in `dryrun_PREV_20261028/`). All of this happened before the launch md5s were recorded.
4. L2 searched firebreather only; the laptop repository was not searched (as the plan states).
5. The laptop bridge was down from about 08:00 to after 08:18 server time. The chain was detached on firebreather and
   finished unaffected (CHAIN_DONE 08:17:50). Assembly ran after the bridge returned (20:00:47).

## Not done

E2 was not run (choice 5a). qc_rh was not run (choice 4a). No coefficient was fitted or tested. Fold A was not used to choose
anything. No Zenodo staging and no repository push were part of this task.

## Files

Firebreather `~/jobs/v142p50/`:

- `plan/` (registered plan and the unregistered PREV copy)
- `logs/`: prereg_md5, lookups (md5, L2, G7), bundle checks, build, dry run, launch_md5s, chain, g2, split, boot, assemble_md5,
  assemble, result_md5
- `scripts/` (with `_prev/`) and `diffs/` (runner and driver against their sources)
- `out/` (step outputs; `p50-stands_SERVERONLY.csv` stays on the server)
- `assembled/gyr142-p50-*_DATA_2026-10-28.*`
- `home/`: input bundle copy, runner outputs and task logs, all `_SERVERONLY` where they carry stand names; server only

Laptop copy: `.../fvs-acd-v14.2-recs/p50/`.

## Verification note (28 October 2026)

An independent read-only check recomputed every headline value from the output files and found them matching, with the verdict following the registered rule in order. This revision changes wording only (2 fixes). The earlier text is kept beside this file with the suffix _PREV_20261028b.
