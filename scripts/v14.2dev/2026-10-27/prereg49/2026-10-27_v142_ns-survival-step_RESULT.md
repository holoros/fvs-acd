# NS survival over multi year steps and the v141LTfi Bakuzis question: PREREG49 result

27 October 2026. Plan `plan/2026-10-26_v142_ns-survival-step_PREREG49.md`, revision 1, md5 c2188088 (registration line in
`logs/prereg_md5.txt`, 2026-10-26T13:46:48-03:00, before any PREREG49 script). Lookups `~/jobs/v142p49_lookup_20261026/LOOKUPS.md`
md5 63a988c2. Scripts recorded in `logs/launch_md5s.txt` before the chain started (2026-10-26T14:26:58-03:00): `fit_p49.R`
fec74cbf, `chain_p49.sh` b177c670, `select_p49.R` f743519d, `frontier_p49.R` 6d6a5938, `h2_p49.R` d22d9486, `p49_lib.R` 47d0d6a9,
`sf_overlay_p49.R` 46114af4, `parts/p49_edit.py` 0ae9799b; built driver `driver_p49.R` b6658080 and runner `runner_p49_fb.R`
28d533bd equal the expected build md5s (`logs/build_expected_md5s.txt` against `logs/build_md5s.txt`, identical). Assembly
`assemble_s1_p49.R` d90a184a and `assemble_s2_p49.R` f5882915 (`logs/assemble_md5.txt`, recorded before each ran). Fit file md5
91d631cd (`logs/fit_md5.txt`, recorded before any engine run). Chain log `logs/chain.txt`, `CHAIN_DONE` 2026-10-27T02:36:13-03:00;
every launch script and all 260 frozen inputs in `logs/input_md5s.txt` rechecked and matched on 27 October before this RESULT.
Frozen runs read, never rerun. L and T not re-estimated. GT1 stays a named failure. NS_RS reported, never fitted or gated.
Aggregates only; stand identifiers stay on the server (see D6). No coordinates. No em dashes.
**This outcome informs 14.3 only; 14.2 is unchanged** (v141LTfi stays the PREREG26 regional candidate; Maine IMULT 1.0).

## Outcome

**Stage 1: rule 2, not adopted; failing gate M3.** The sf_fr gamma frailty step fitted (theta 3.558), every harness gate passed,
and M1 and M2 moved the long interval survivor ratios into the 0.90 to 1.10 window, but predicted annual survival fell outside
the observed site bootstrap interval in 5 of 11 interval classes (M3). M4 (E3, E6b) and M5 also fail; reported as the trade off.
v141LTfis does not enter stage 2. Source: `assembled/s1/gyr142-p49-s1-verdict_DATA_2026-10-26.txt`
(`outcome=RULE2_NOT_ADOPTED`, `fis_enters_stage2=FALSE`).

**Stage 2: v141LTfi rule 2, not cleared; relations Eichhorn and HT_monotone.** Harness gates G0, G0b, G1, G2 all pass on both
arms. On 36 measured ns_c NS_OP fold B stand lists, v141LTfi adds new flags against v141LT (two Eichhorn SDI units, five
HT_monotone stands), so (A) and (B) both fail. No candidate arm cleared. The v141LTfi median 100 year top height loss against
v141LT is 15.6%, inside 14 to 25%, so the PREREG30 synthetic start reading is not supported. Source:
`assembled/s2/gyr142-p49-s2-verdict_DATA_2026-10-26.txt` (`outcome_v141LTfi=RULE2_NOT_CLEARED`, `combined=no candidate arm cleared`).

### Decision rule, in order

Stage 1 (`assembled/s1/gyr142-p49-s1-gates_DATA_2026-10-26.csv`):

1. Fit stop, H0, TR or K1: none fails. Harness passes.
2. M1, M2 or M3: **M3 fails. Not adopted; gate M3 named.** Rule applies; stage 1 ends here.
3. Reported for the trade off: M4 fails on E3 (ns_long_c) and E6b (ns_fl, ns_long_fl); M5 fails on ns_long_c.
4. Not reached. v141LTfis does not enter stage 2.

Stage 2, v141LTfi against v141LT (`assembled/s2/gyr142-p49-s2-gates_DATA_2026-10-26.csv`,
`assembled/s2/gyr142-p49-s2-outcome-by-arm_DATA_2026-10-26.csv`):

1. G0, G0b, G1, G2: all pass. No harness failure.
2. (A) fails and (B) fails: **not cleared; relations Eichhorn and HT_monotone named.**
3. Not reached. Neither arm cleared, so neither combined statement of the plan applies (no seedling start reading of the PREREG26
   inversion is recorded; see Reading). Median loss 15.6% at 100 years: does not support the PREREG30 synthetic start reading.

## Stage 1: the fit

| Item | Value | Source |
|:--|:--|:--|
| Reproduction of PREREG27 fold A survivor table | 68 of 68 cells, worst 4.88e-15 (threshold 1e-9); fold A keys equal | `fit/gyr142-p49-repro-foldA_DATA_2026-10-26.csv` |
| theta, point estimate | 3.55799 | `fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv` |
| Site cluster bootstrap 95% interval | -0.642 to 9.843 (B = 1000, seed 20261026) | same |
| Nonconverged draws | 2 of 1000 (0.2%; stop at above 5%) | same |
| Draws with theta below 0 | 53 of 1000 | same |
| Newton iterations | 5 | same |
| Frame | 1901 stands, 864 sites, 169545 records, ns_c fold A NS_OP | same |
| Fit stop | not fired (converged, estimate above 0, nonconverged at most 5%) | same; `logs/fit_rc.txt` (0) |

Fold A survivor ratio by interval class, null (v141LTfi) against fitted (`fit/gyr142-p49-sffr-foldA-cells_DATA_2026-10-26.csv`):

| Class | Stands | Null | Fitted |
|:--|--:|--:|--:|
| 5 years or less | 1742 | 0.9982 | 1.0032 |
| 6 to 10 | 83 | 0.9617 | 0.9777 |
| 11 to 15 | 44 | 0.9247 | 0.9606 |
| 16 to 20 | 26 | 0.8741 | 0.9298 |
| 21 to 30 | 6 | 0.7899 | 0.8634 |

The estimate is on the alternative side of the null, so the registered fit stop did not fire, but the bootstrap interval
covers 0 (53 of 1000 draws below 0). The plan's stop rule names only the point estimate; the interval is reported here.

## Stage 1: harness gates

| Gate | Value | Threshold | Pass | Source |
|:--|:--|:--|:--|:--|
| H0 | worst results difference 0 (BA_p), worst per tree 0 (dbh); 100 of 100 stands, 8774 of 8774 tree rows | at or below 1e-9 | yes | `logs/h0_result.csv` |
| TR | worst H 1.53e-16, worst survival 6.0e-15; 2 stands, 3 years, 204 rows, 116 with H above 0 | below 1e-12 | yes | `logs/tr_result.csv` |
| K1 | 0 RUN_OK other than 1 in 17918 stands (ns_c 5731, ns_fl 1319, ns_long_c 8549, ns_long_fl 2319), both arms, after the retry rule | 0 | yes | `out/tables/gyr142-p49-fb-K1_DATA_2026-09-27.csv` |
| Scorer V0 to V2 | V0 max relative 7.68e-15 or less; V1 C1 finite on every scored stand; V2 bounds met; all 24 rows pass | as PREREG22 | yes | `assembled/s1/gyr142-p49-s1-scorer-gates_DATA_2026-10-26.csv` |
| Scorer reproduction | v141LTfi r2 scores 12 of 12 rows and structure 6 of 6 rows equal PREREG22, worst 0 | identical | yes | `assembled/s1/gyr142-p49-s1-reproduction_DATA_2026-10-26.csv` |

## Stage 1: benchmark gates

| Gate | v141LTfis | Reference | Threshold | Pass | Source |
|:--|:--|:--|:--|:--|:--|
| M1, ns_c NS_OP fold B, 16 to 60 years | 0.930 (0.880 to 0.990), 34 stands | v141LTfi 0.868 | 0.90 to 1.10 | yes | `assembled/s1/gyr142-p49-s1-survivors-iv3-foldB_DATA_2026-10-26.csv` |
| M2, ns_long_c NS_OP fold B, 16 to 60 years | 0.993 (0.944 to 1.047), 227 stands | v141LTfi 0.921 | 0.90 to 1.10 | yes | same |
| M3 | 6 of 11 classes inside | | every class with 30 or more trees inside | **no** | `assembled/s1/gyr142-p49-s1-M3-annual-survival_DATA_2026-10-26.csv` |
| M4 H1, abs TOPHT bias % | ns_c -0.139; ns_fl -1.182; ns_long_c 0.461; ns_long_fl -1.284 | v141LT 1.452; 3.775; 2.392; 5.469 | below v141LT | yes | `assembled/s1/gyr142-p49-s1-M4-detail_DATA_2026-10-26.csv` |
| M4 H2, abs(ratio - 1), fold B, 25 cm and over | ns_c 0.2079; ns_long_c 0.1145 | 0.2498; 0.2143 | below 14.1 and PREREG11 | yes | `out/tables/gyr142-p49-h2-gate_DATA_2026-10-26.csv` |
| M4 S1, stems ratio | ns_c B 0.966; ns_long_c 0.963; ns_fl 0.953; ns_long_fl 0.933 | v141LT 0.912; 0.910; 0.841; 0.866 | abs log ratio below v141LT | yes | `assembled/s1/gyr142-p49-s1-M4-detail_DATA_2026-10-26.csv` |
| M4 E3, C1 %RMSE | ns_c 23.86; ns_long_c 23.67 | v141LT 23.68; 22.92 | v141LT minus candidate at or above -0.5 | **no** (ns_long_c -0.754) | same |
| M4 E6b, C1 bias % | ns_fl 4.219; ns_long_fl 4.903 | v141LT -2.280; -4.489 | abs no worse than v141LT | **no** (both) | same |
| M5, C1 %RMSE | ns_c 23.860; ns_long_c 23.670 | v141LTfi 23.826; 23.162 | v141LTfi minus candidate at or above -0.5 | **no** (ns_long_c -0.508) | `assembled/s1/gyr142-p49-s1-M5_DATA_2026-10-26.csv` |

M3 detail, NS_OP fold B, measured t1 trees, annual survival predicted against observed with its 95% site bootstrap interval
(B = 1000, seed 20260930):

| Set | Class | Trees | Stands | Predicted | Observed | Interval | Inside |
|:--|:--|--:|--:|--:|--:|:--|:--|
| ns_c | 5 years or less | 64571 | 1899 | 0.9893 | 0.9892 | 0.9877 to 0.9907 | yes |
| ns_c | 6 to 10 | 3052 | 90 | 0.9905 | 0.9958 | 0.9938 to 0.9976 | no |
| ns_c | 11 to 15 | 1543 | 43 | 0.9907 | 0.9890 | 0.9826 to 0.9946 | yes |
| ns_c | 16 to 20 | 464 | 21 | 0.9933 | 0.9938 | 0.9893 to 0.9981 | yes |
| ns_c | 21 to 30 | 441 | 13 | 0.9922 | 0.9973 | 0.9946 to 0.9998 | no |
| ns_long_c | 5 years or less | 67176 | 1986 | 0.9894 | 0.9921 | 0.9910 to 0.9931 | no |
| ns_long_c | 6 to 10 | 9595 | 269 | 0.9904 | 0.9941 | 0.9922 to 0.9958 | no |
| ns_long_c | 11 to 15 | 5783 | 164 | 0.9907 | 0.9923 | 0.9897 to 0.9946 | yes |
| ns_long_c | 16 to 20 | 3786 | 114 | 0.9919 | 0.9930 | 0.9898 to 0.9959 | yes |
| ns_long_c | 21 to 30 | 3271 | 107 | 0.9926 | 0.9918 | 0.9881 to 0.9950 | yes |
| ns_long_c | 31 to 60 | 134 | 6 | 0.9942 | 1.0000 | 1.0000 to 1.0000 | no |

Every miss is predicted survival below observed. The 31 to 60 year class meets the 30 tree floor but holds 6 stands with no
observed deaths, so its interval is degenerate at 1; M3 fails without it (four other classes miss).

Reported, not gated (`assembled/s1/gyr142-p49-s1-survivors-iv3-foldB_DATA_2026-10-26.csv`, `assembled/s1/gyr142-p49-s1-structure_DATA_2026-10-26.csv`):
16 to 60 year survivor ratio on ns_fl NS_OP 0.916 (v141LTfi 0.832) and ns_long_fl NS_OP 0.912 (0.793); NS_RS 5 year class
1.058 on ns_c and 1.077 on ns_long_c (v141LTfi 1.050 and 1.069), so the switch raises the NS_RS survivor excess slightly. Whole
frame stems ratio rises on every set: ns_c 0.969 (v141LTfi 0.962), ns_fl 0.953 (0.912), ns_long_c 0.963 (0.955), ns_long_fl
0.933 (0.880). C1 bias rises on every set (`assembled/s1/gyr142-p49-s1-scores_DATA_2026-10-26.csv`): ns_c 1.10% (v141LTfi
0.61%), ns_fl 4.22% (0.20%), ns_long_c 0.71% (-0.13%), ns_long_fl 4.90% (-1.95%).

## Stage 2: harness gates

| Gate | Value | Threshold | Pass | Source |
|:--|:--|:--|:--|:--|
| G0 | 3 of 3 stands, 12 columns, worst scaled 0 (BA_p) | at or below 1e-9 | yes | `logs/s2_g0_result.csv` |
| G0b | 4 cells at 6,000 trees ha⁻¹, 404 of 404 rows, 19 columns; whole file identical (1212 rows) to frozen `traj_v141LTfi_BF.csv` md5 b10a03bb | identical | yes | `logs/s2_g0b_result.csv` |
| G1 v141LT | 36 of 36 trajectories, 101 rows, run_ok 1 | all | yes | `assembled/s2/gyr142-p49-s2-gates_DATA_2026-10-26.csv` |
| G1 v141LTfi | 36 of 36 | all | yes | same |
| G2 v141LT | worst scaled age 0 difference 3.49e-15, 36 stands | at or below 1e-6 | yes | same |
| G2 v141LTfi | worst 3.49e-15, 36 stands | at or below 1e-6 | yes | same |

Stand draw (`out/s2/selection_p49_DATA.csv`, `out/s2/bins_p49_DATA.csv`, `logs/select.txt`): 5731 admitted ns_c stands, 3967
NS_OP (1746 sites), fold B pool 2066; ESI quartile edges 17.17, 17.71, 18.20 m; SDI tercile edges 325 and 564; 3 stands in each
of 12 cells, 36 drawn (floor 24). Frontier computed and its md5 (2713dd21) recorded at 01:56:34, before the draw at 01:56:36
(`logs/chain.txt`, `logs/frontier_md5.txt`).

## Stage 2: relations, v141LTfi against v141LT

`assembled/s2/gyr142-p49-s2-ni-by-relation_DATA_2026-10-26.csv`; definitions from PREREG44 `relations()` with the PREREG26
NS thresholds. (A) no new flag on any relation and unit; (B) worst margin not above v141LT's.

| Relation | Flags v141LTfi | Flags v141LT | New flags | Worst margin v141LTfi | Worst margin v141LT | (A) and (B) |
|:--|--:|--:|--:|--:|--:|:--|
| Eichhorn | 2 | 0 | 2 | 0.031 | 0 | **fail** |
| HT_monotone | 12 | 9 | 5 | 2.168 m | 1.924 m | **fail** |
| Reineke | 1 | 2 | 0 | 0.220 | 0.315 | pass |
| SiteOrder_BAPH | 3 | 3 | 0 | 20 | 20 | pass |
| SiteOrder_HT | 3 | 3 | 0 | 20 | 20 | pass |
| SiteOrder_VOL | 3 | 3 | 0 | 20 | 20 | pass |
| Frontier, Magnitude, Sukachev, YieldDensity | 0 | 0 | 0 | 0 | 0 | pass |

New flag units (`assembled/s2/gyr142-p49-s2-outcome-by-arm_DATA_2026-10-26.csv`): Eichhorn S1 and S2 (volume CV at common
top height 0.181 and 0.166 against the 0.15 limit; v141LT 0.116 and 0.117); HT_monotone on cells E1_S3_2, E3_S3_3, E4_S1_3,
E4_S3_1, E4_S3_3 (top height falls by 0.07 to 0.32 m between readings). Reineke was not evaluated on 9 v141LTfi and 13 v141LT
stands (never reached RD 0.5 or too few points after it).

Site ordering on measured lists is flagged on every SDI tercile for both arms: the SiteOrder margin is the number of 5 year
readings (of 20) at which ESI bin means are out of order, and it reaches 20 of 20 on both (`assembled/s2/gyr142-p49-s2-relations-paired_DATA_2026-10-26.csv`).
Basal area ordering is no better under v141LTfi on S1 (17 readings against 12) and S3 (17 against 16); the relation passes (B)
only because (B) compares the worst unit (20 and 20).

## Stage 2: top height loss and NS frontier (reported, not gated)

Per stand top height of v141LTfi over v141LT (`assembled/s2/gyr142-p49-s2-topheight-loss_DATA_2026-10-26.csv`, 36 stands):

| Age | Median ratio | Range | Median loss | Stands losing 14% or more | 25% or more |
|--:|--:|:--|--:|--:|--:|
| 35 | 0.911 | 0.858 to 0.954 | 8.9% | 1 | 0 |
| 100 | 0.844 | 0.750 to 0.926 | 15.6% | 26 | 1 |

NS measured frontier: 99th percentile of measured TOPHT over ESI, 11434 admitted ns_c visits, bound 1.456 (`logs/frontier.txt`,
`out/s2/frontier_p49_DATA.csv` md5 2713dd21). Projected top height over ESI against it
(`assembled/s2/gyr142-p49-s2-frontier-relht_DATA_2026-10-26.csv`):

| Arm | Age | Median | Maximum | Stands above the bound |
|:--|--:|--:|--:|--:|
| v141LT | 35 | 0.941 | 1.242 | 0 |
| v141LT | 100 | 1.314 | 1.751 | 4 |
| v141LTfi | 35 | 0.831 | 1.173 | 0 |
| v141LTfi | 100 | 1.117 | 1.399 | 0 |

## Reading

The frailty step does what PREREG27 asked of it on the long interval survivor ratios (16 to 60 years: 0.868 to 0.930 on ns_c,
0.921 to 0.993 on ns_long_c, fold B), and it improves stems and top height bias on all four NS sets. It does not get annual
survival right by class: on every class it misses, predicted survival is too low, including the 5 year class on ns_long_c and
the 6 to 10 year class on both sets. The sf_fr form leaves year 1 unchanged and raises survival only as the record's hazard accumulates, so it
lifts survival most late in a projection, where the long interval ratios are scored; the M3 table shows observed annual
survival already above predicted at 5 years (ns_long_c) and 6 to 10 years (both sets). The cost is volume: C1 %RMSE on ns_long_c worsens by 0.51 points against v141LTfi and
C1 bias turns positive on the fl sets. The fit interval also covers the null. These points are a reading, not tested results.

On measured stand lists v141LTfi does not reproduce the PREREG26 single cell site inversion as its failure; instead it adds
Eichhorn and top height decline flags that v141LT does not carry, and it keeps a 100 year top height loss of 15.6% (median)
against v141LT, against 8.9% at 35 years. The loss is therefore not a seedling start artifact. Under v141LT, 4 of 36 stands
exceed the NS measured frontier at 100 years and none do under v141LTfi, so part of the loss is v141LT running above the
measured envelope; whether the rest is a v141LTfi deficit is not settled by this design. Site ordering is out of order on
measured lists under both arms, which the narrow ESI range of the drawn stands (bin means 16.7 to 18.6 m) and three stands per
cell may explain; that is an inference, not a tested result.

## Deviations (`DEVIATIONS_PREREG49.md`; previous version kept as `DEVIATIONS_PREREG49_PREV_20261027.md`)

1. D1: the fold A reproduction step reads ns_fl, ns_long_c and ns_long_fl fold A per tree outputs and SITE of frozen results rows
   of both folds to assign folds (the plan says no fold B or ns_long_c file is read, and also requires the 68 cell reproduction,
   which spans all four sets). Fold B rows are dropped after fold assignment; the estimating equation uses ns_c fold A NS_OP only.
2. D2: a third driver edit (the survival switch source line); inert when unset, tested by G0 and G0b.
3. D3: `p31_project()` and `p31_dht()` mapped to driver_p26 equivalents in the declared port table.
4. D4: the PREREG22 bundle copied into `home/` (40 files, md5 identical).
5. D5: two fit script changes after the dry run and before the chain (bootstrap draws start from theta 0; Newton steps leaving
   theta below 0 are halved). Nothing tuned on dry outputs.
6. D6: inherited runner and scorer outputs carry stand identifiers in files not named `*_SERVERONLY`; none leaves the server.
7. D7: this RESULT was written in a later session from the frozen assembled outputs, after rechecking all script and input md5s.

Declared implementation choices are listed in the DEVIATIONS file (H_t definition, H0 subset, TR stands, M3 and M5 frames,
G0 stands, stage 2 pool: bins over both folds, draw from fold B only).

## Not done

v141LTfis was not run in stage 2 (rule 2 of stage 1 fired, as the plan directs). The forms sf_pw, sf_lg and conv were not
fitted (choice 1a). No Zenodo staging or repository push was part of this task.

## Files

`plan/`, `logs/` (prereg_md5, launch_md5s, input_md5s, build, fit, h0, tr, score, h2, select, frontier, s2 task and gate logs,
assemble_md5, assemble_s1, assemble_s2, chain), `scripts/`, `diffs/`, `fit/`, `assembled/s1/`, `assembled/s2/` (the
`*_SERVERONLY` trajectory file stays on the server), `DEVIATIONS_PREREG49.md`, this RESULT.
