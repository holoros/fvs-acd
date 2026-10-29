# QC ingrowth entry size and scoring floor handling, for 14.3: preregistration 50

**Revision 1, 28 October 2026.** Built from draft 1 (27 October 2026, md5 5b45519d42d8601cfcec636a7d7c4e89) with every open
choice resolved at the option Aaron pre-approved (recommended option in each case), then red teamed in a fresh read (see the
end). Written before any PREREG50 script, join, engine run or table exists. Nothing is fitted and no engine coefficient,
engine file or default changes. The outcome **informs 14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579** [P48R
header]. L and T of 14.1 are not refitted. GT1 stays a named failure. Frozen runs are read, never rerun in place. Stand and
site identifiers stay in files named `*_SERVERONLY`. No coordinates. No em dashes.

## Revision log

| Revision | Date | Change |
|:--|:--|:--|
| draft 1 | 27 October 2026 | draft with five open choices and one draft red team pass |
| 1 | 28 October 2026 | choice 1a (S2 = engine equations at the floor, open loop); choice 2a (all 160 fold B stands, floor groups reported apart); choice 3a (2/3 with lower limit above 0.5, mirrored 1/3 and 0.5); choice 4a (qc141 only); choice 5a (E2 not run). Execution made concrete: arm names, runner copy edits, file naming, retry rule, dry run, gate formulas, S2 implementation. Fresh read red team 2 and its fixes (last section). |

## Sources (every number below cites one of these)

| Tag | File |
|:--|:--|
| P48R | `scripts/v14.2dev/2026-10-26/rec_b/v142p48/2026-10-26_v142_qc-stems-deficit_RESULT.md` (worktree of `holoros/fvs-acd`, branch `v142-autopilot-20261026`, commit 4014cde), body tables; server copy firebreather `~/jobs/v142p48/2026-10-26_v142_qc-stems-deficit_RESULT.md`, md5 06807ec6d3c781ee2373f2f49008f98e [`~/jobs/v142p48/logs/result_md5.txt`] |
| P48V | the same file, section "Verification addendum (26 October 2026, revision r1)"; recomputation scripts in firebreather `~/jobs/v142p48_verify_20261026/` (`verify.R`, `verify2.R`, `verify3.R`; console output only) |
| P48D | `.../v142p48/2026-10-26_v142_qc-stems-deficit_DEVIATIONS.md` |
| P48F | firebreather `~/jobs/v142p48/assembled/gyr142-p48-floor_DATA_2026-10-26.csv` and `gyr142-p48-framecheck_DATA_2026-10-26.csv` |
| P48I | firebreather `~/jobs/v142p48/assembled/gyr142-p48-input-md5_DATA_2026-10-26.csv` |
| P48S | firebreather `~/jobs/v142p48/scripts/p48_split.R` (md5 b8829fa5d37097e024b3733d2e48d30c) and `p48_boot.R` (md5 8c7a865c7723de443d0c35fa973497aa), the PREREG48 split and bootstrap code that PREREG50 copies |
| P48DR | `scripts/v14.2dev/2026-10-11/drafts/2026-10-11_v142_qc-stems-deficit_PREREG48_DRAFT.md`; registered plan firebreather `~/jobs/v142p48/plan/2026-10-26_v142_qc-stems-deficit_PREREG48.md`, md5 61ab907e7be70cac0e68264586e9ebec |
| RUN | firebreather `~/jobs/v142p19/home/runner_htfix_fb.R`, md5 4e6a29971922b1f7a0397cc91ff56f84 (line 274: `ingrowth.min.dbh=5.0`; line 422: `iv<-max(1,round(p$interval_years))`; line 423: per stand elapsed limit 60 s; line 433: `ING_MIN_FROM_SCORE`, commented "PREREG9: ingrowth threshold = scoring threshold"; line 437: annual loop and the year 1 capture; lines 446 to 467: the `TREE_OUT` tree files `_pred_t2_tree`, `_t1_split_tree`, `_pred_yr1_tree`) |
| TASK | firebreather `~/jobs/v142p19/scripts/run_task_p19.sh`, md5 ac029e4e6eeb1d71f1784b423c8575fc (line 34 unsets `ING_MIN_FROM_SCORE` for the QC arms); taskmap `~/jobs/v142p19/home/work/p19_taskmap_DATA_2026-09-28.csv` (qc_c arm p19_a0111: 19 chunks of 20 pairs rows, rows 1 to 380) |
| RETRY | firebreather `~/jobs/v142p19/home/run_retry_p19.sh` and `retry_timeouts_p19.sh` (PREREG19 rule: a stand that hits the host time limit is rerun alone, by name, up to three attempts; the latest attempt replaces it) |
| P26S | firebreather `~/jobs/v142p26/scripts/run_p26.sh` (lines 5, 7, 20: the NS v141LTfi and v141LTi arms export `ING_MIN_FROM_SCORE=1`) |
| ENG | firebreather `~/jobs/v142p19/home/AcadianGY_13.1.r`, md5 5894df6013c701d09e7ba67ba6c2f090, reached through `AcadianGY_14.0.4.r` line 318 (`source(.acd_v14_base)`) and `magplot/verify/p4e/model_b0b1b2.r` line 5. Lines 2808 to 2822: `min.dbh.ingrowth` enters the ingrowth occurrence link and the ingrowth count link; line 2857: the species composition link; line 2911: entry DBH is `ops$ingrowth.entry.dbh` when set, otherwise `min.dbh.ingrowth`; lines 3979 and 4121: ingrowth is computed from the plot summary of the tree list at the start of the year; line 4290: ingrowth is appended after the annual update. The 14.1 overlay `v14_1_20260923/AcadianGY_14.1.r` (md5 0bf27dde81240e6bdf59c9a90f0051bd) contains no ingrowth code (0 matches for "ingrowth") |
| HK | firebreather `~/jobs/v142p45/scripts/2026-09-29_v142_p23_hkey.R` (PREREG23 helper: `fold_of`, `stand_frame`, `split_map`, `tag_key`, `mapsp`, and `totvol` loaded verbatim from the PREREG16 scorer) |
| R2S | firebreather `~/jobs/v142p45/scripts/2026-10-01_v142_volconv_score_r2.R`, md5 265fc6950ce3f18da751da8b9fd3dbc2 (line 81: percent RMSE point formula; lines 112 to 113: C1 volume is `totvol` with heights set missing, observed from the run frames at t2 and predicted from `_pred_t2_tree`) |
| FST | firebreather `~/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv`, md5 184dc76888580de7c2cfdb7e2ec8580f |
| LK | `scripts/v14.2dev/2026-10-26/rec_b/v142p49_lookup_20261026/LOOKUPS.md`, lines 46 to 50 (fold rule); the rule as code: firebreather `~/jobs/v142p22/scripts/2026-09-27_v142_p17_summ.R` line 9 |
| RN | `scripts/v14.2dev/2026-10-27/release-notes/2026-10-27_fvs-acd-v14.2_release-notes_DRAFT.md`, "Open items" |

## What is known before this plan (previously inspected)

All of this was read before PREREG50 was written, on both folds of screened qc_c, so every PREREG48 quantity is
**previously inspected** here and none of it can serve as a confirmatory test.

1. Every QC anchor arm runs about 24 points low on stems. On screened qc_c fold B the qc141 stems deviation is 24.226
   points (18.959 to 29.910), with observed stems 154648 and predicted 117183 trees ha⁻¹ summed over 160 stands, so
   D = 37465 [P48R]. The release notes carry it as an open item [RN].
2. PREREG48 placed the whole deficit in stems that cross the scoring floor between visits: observed new tags at or above
   the floor sum to 47607 trees ha⁻¹, against 65.493 engine ingrowth trees ha⁻¹ at or above the floor (qc141); the survivor
   ratio S_p over S_o is 1.0941 (1.0488 to 1.1471), so the engine keeps more survivors than the tags show [P48R].
3. The scoring floor (`SCORE_MINDBH_USED`) on screened fold B ranges from 9.1 to 33.7 cm, with 101 of 160 stands at
   9.1 cm [P48R, P48F]. Seven fold B stands have floors of 31 to 34 cm [P48V].
4. The t1 and t2 field frames hold no rows below the floor (0 of 5498 t1 rows and 0 of 6205 t2 rows on fold B) [P48F].
   The engine therefore starts from a floor censored list, predicted upgrowth is 0 by construction, and observed "new
   tags" are recruitment plus upgrowth from unmeasured trees below the floor [P48R, Reading].
5. Engine ingrowth enters at 5.0 cm at minimum, with median t2 DBH 5.67 cm and 95th percentile 7.25 cm (qc141); 7 of 6042
   ingrowth records reach the stand floor (10 in qc_rh). Engine ingrowth at all sizes sums to 51728 trees ha⁻¹ on fold B
   for qc141 and 51488 for qc_rh, near the 47607 observed new tags at or above the floor, though the two are not like for
   like [P48V].
6. The 5.0 cm entry is a runner setting, not a coefficient: the runner sets `ingrowth.min.dbh=5.0` [RUN line 274], and an
   existing switch, `ING_MIN_FROM_SCORE=1`, sets it to the stand's scoring floor [RUN line 433]. The QC arms unset that
   switch [TASK line 34]; the NS candidate arms set it [P26S]. In the engine, `min.dbh.ingrowth` is a covariate of the
   ingrowth occurrence, count and species composition links, and is also the entry DBH unless `ops$ingrowth.entry.dbh`
   is set [ENG]. So moving the threshold to the floor changes the predicted rate through fitted terms, not only the
   entry size.
7. In the task scripts read for this draft, no QC run sets `ING_MIN_FROM_SCORE=1` (`run_task_p19.sh`, and the QC task
   scripts of PREREG23, PREREG28, PREREG33, PREREG38 and PREREG45b unset it). So no QC quantity under a floor matched
   threshold has been seen. This is a reading of those scripts, to be confirmed by lookup L3 (gate G7).
8. Ingrowth in a year is computed from the stand state at the start of that year and appended after the annual update
   [ENG lines 3979, 4121, 4290]. So the ingrowth records of year 1 of a run are the engine's ingrowth equations evaluated
   on the t1 tree list, entering at the threshold in force [ENG line 2911].

## Question and hypotheses

Is the QC stems deficit a **scoring artifact** of floor censored t1 lists plus engine ingrowth entering near 5 cm, or a
**real shortfall** in ingrowth past the floor or in small tree diameter growth?

- **HA, artifact.** When the engine's ingrowth threshold matches the stand's scoring floor, or when the scorer predicts
  floor crossings explicitly, most of D disappears.
- **HR, real shortfall.** With the floor matched, predicted new stems at or above the floor still fall well short of the
  observed new tags. The QC frames cannot then say whether the cause is the ingrowth rate or the growth of trees below
  the floor (fact 4); the report names what data could.
- **HO, overcorrection.** With the floor matched, predicted stems exceed observed by a material margin, which would mean
  the floor matched rate is too high on QC (or the survivor excess of fact 2 now dominates).

## Arms (no engine coefficient changes)

| Arm | Runner column | Kind | What changes | Status |
|:--|:--|:--|:--|:--|
| R0 | frozen p19_a0111 | reference | frozen qc141 (results md5 979101bedafe16c090ce84d1e5e46a07 [P48I]) scored as PREREG48 | reproduction, read only |
| G2 | `g2` | harness | the PREREG50 runner copy with qc141 settings exactly [TASK], `ING_MIN_FROM_SCORE` unset; used only for gate G2 | new run, new directory |
| S1 | none | scorer convention | predicted new stems = all engine ingrowth records at any size; observed = new tags at or above the floor | **bracket only**: its value (51728 against 47607) is already known [P48V], so it is reported, never gated |
| S2 | `s2` | scorer convention, open loop floor crossing | predicted new stems at the floor = the engine's own ingrowth equations [ENG] with `min.dbh.ingrowth` set to the stand floor, evaluated once on the t1 tree list (one annual engine step from t1, fact 8), times the runner interval iv [RUN line 422]; added to frozen qc141 survivors at the floor | new [choice 1a] |
| E1 | `e1` | engine run, convention | qc141 settings exactly [TASK], except `ING_MIN_FROM_SCORE=1` exported, so ingrowth is predicted past the stand floor and enters at it [RUN line 433, ENG line 2911] | new |
| E2 | none | engine run | entry DBH at the floor with the threshold left at 5.0 cm | **not run** [choice 5a]; named as a limit, since it places 5 cm rate recruits at the floor and has no record basis |

S2 and E1 use the same fitted equations at the same threshold; S2 holds stand state open loop (the year 1 rate from the t1
list, held for the interval), E1 lets the ingrowth compete and grow and recomputes the rate every year. Gate G4 checks that
S2 computes the engine's equations exactly; whether the two then agree on the deficit is an outcome, handled by decision
rule 4, and only agreement licenses reading S2 as a scorer convention a 14.3 benchmark could adopt. One height arm only:
qc141 [choice 4a]; the PREREG48 AR gate already passed at 0.32 points against 2.0 [P48R], so qc_rh is not run.

**Runner copy.** `home/runner_p50_fb.R` is a copy of RUN with exactly two edits, each asserted to apply once and kept as a
diff: (a) after line 433, when `P50_TRACE` is set, one line per stand (stand, `ops$ingrowth.min.dbh`, the scoring
threshold, both printed with 17 significant digits) is appended to a `*_SERVERONLY` trace file (gate G3); (b) the annual
loop of line 437 runs one year instead of iv when `P50_ONESTEP=1` (arm S2 only). With `P50_ONESTEP` unset the loop is
unchanged. Gate G2 is what shows the copy, with the trace on, reproduces the frozen run. No engine file, coefficient or
default is touched; the task driver is a copy of TASK with the taskmap, arm case, runner name and md5, and output naming
changed (the qc141 environment block is kept verbatim). Every runner output name carries `_SERVERONLY` because the files
carry stand identifiers.

**S2 per stand.** I_S2 = iv times the sum of EXPF over the S2 year 1 ingrowth records (runner flag ing 1 in
`_pred_yr1_tree`) that are live at or above the floor. Predicted stems for S2 are the frozen qc141 survivors, upgrowth and
residual at the floor (S_p + U_p + R_p of R0, as split by PREREG48 [P48S]) plus I_S2; the frozen qc141 ingrowth at the floor
(I_p of R0) is replaced, not added.

**Support limit.** Whether the ingrowth equations were fitted over thresholds near 9 to 34 cm is not known from the files
read. Lookup L2 looks for the fit data's threshold range on firebreather (including any clone of the repository found
there; the laptop repository is not searched by this run). If it is not found, every S2 and E1 result carries "threshold
support unknown", and stands with floors of 31 to 34 cm are reported apart (choice 2a).

## Population and folds

Screened qc_c (PREREG19 cut flag FALSE), RUN_OK 1, field tag frames `v142p14/in/pass28qc` [P48I]. FST holds 313 screened
and 65 cut qc_c stands (both folds; arm p19_a0111) [FST]. Folds by the PREREG11 rule: md5 of the SITE string (digest,
serialize = FALSE), first hex digit even is fold A, odd is fold B [LK]. **Fold B is gated; fold A is a replication,
reported and not gated**, as in PREREG48 [P48DR]. Nothing in this plan is tuned, so fold A is not used to choose anything.
Both folds' PREREG48 quantities are previously inspected; S2 and E1 quantities exist on neither fold.

**Primary population [choice 2a]:** all 160 screened fold B stands, for continuity with G0. The floor groups 9.1 to 9.7 cm
(153 stands) and 31 to 34 cm (7 stands) are reported apart, and the decision rule is re-evaluated on the 153 stand group
for the "floor group sensitive" label (rule 7).

The engine arms (G2, E1, S2) run every qc_c pairs row the frozen run ran (the 19 chunks of TASK, cut stands included, as
the frozen run did), so G2 can compare like with like; only screened stands enter gates other than G5 and quantities.

Pairing uses the MAGPlot field tags only; any join keyed on the run frame TREE column stops the script (PREREG36, PREREG37,
as carried by [P48DR]; guard copied from [P48S]). Pooling is sums over stands, as PREREG48 [P48D].

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | R0 reproduces PREREG48 fold B: stems deviation 24.22615 points, D 37465, observed I 47607, predicted I 65.4935 trees ha⁻¹ | equal to the published rounding (5, 0, 0 and 4 decimals) | [P48R], [P48V] |
| G1 | R0 reproduces the entry facts on screened fold B: minimum ingrowth DBH 5.0 cm, median 5.67 cm, 7 of 6042 ingrowth records live at or above the floor, all size ingrowth sum 51728 trees ha⁻¹ | equal to the published rounding | [P48V] |
| G2 | the G2 arm reproduces the frozen qc141 chunk outputs byte for byte on every screened qc_c stand (313, both folds): the stand's line in `_results`, and its lines, in order, in `_pred_t2_tree`, `_t1_split_tree` and `_pred_yr1_tree` | identical text | E0 practice of PREREG2 (14.3 PREREG2, gate E0) |
| G3 | E1 trace: on every E1 stand the traced `ops$ingrowth.min.dbh` equals the traced threshold and the results file `SCORE_MINDBH_USED`, and in the E1 and S2 year 1 captures every ingrowth record has DBH equal to the stand floor | absolute difference at or below 1e-9 | [RUN line 433], [ENG line 2911]; tolerance [choice, no record] |
| G4 | S2 reimplementation: year 1 ingrowth trees ha⁻¹ and its species shares from the S2 pass equal those in E1's year 1 capture (`_pred_yr1_tree`, ing 1) for the same stand, on a 20 stand sample of screened qc_c stands drawn with `set.seed(50)` from the sorted stand list | relative difference at or below 1e-9 (both zero counts as equal; a species present in one and absent in the other fails) | [choice, no record] |
| G5 | K1: RUN_OK 1 on every E1 and S2 stand that is RUN_OK 1 in R0 (378 stands), after the PREREG19 retry rule [RETRY] | 0 failures | K1 practice of PREREG2 and PREREG49 |
| G6 | fold assignment from `fold_of` [HK] equals the PREREG22 rule script function [LK, line 9] and the fold carried by `stand_frame` | identical | [LK], [P48D] |
| G7 | no QC result with `ING_MIN_FROM_SCORE=1` exists on firebreather before E1: search of `~/jobs/*/scripts/*` and `~/jobs/*/home/*.sh` (excluding `~/jobs/v142p50`) for files that contain both `ING_MIN_FROM_SCORE=1` and a QC set name (`qc_c`, `qc_fl`), logged with the file list | none found, or each found file listed and the verdict labeled "floor matched QC run previously seen" | fact 7 |

Any failure of G0 to G6 is a harness failure. G7 changes a label, not the verdict. The PREREG48 T1 frame check (t1 stems,
field tag frame against run frame) and the split map check are recomputed and reported, as in PREREG48 [P48S].

## Quantities (fold B, per arm)

- D_arm = observed minus predicted stems at or above the stand floor, trees ha⁻¹ summed over stands, as PREREG48.
- Explained share X_arm = (D_R0 minus D_arm) over D_R0, with a 95% site cluster bootstrap interval (B = 1000, seed
  20261001, the PREREG48 construction [P48S]: site draw count weights over the fold's sorted screened sites, the same draws
  for every arm).
- Survivor ratio S_p over S_o for E1 (E1 changes competition, so survivors can move), split as PREREG48 [P48S]. Because R0
  already keeps 10076 more survivors than observed (117117 against 107041 [P48R]), X_arm can exceed 1 without any
  overshoot in new stems; predicted and observed new stems at the floor are therefore reported beside X.
- Predicted against observed new stems at or above the floor (I_p or I_S2 against I_o), by floor group: 9.1 to 9.7 cm (153
  stands: 101, 22, 11, 11, 5 and 3 at 9.1 to 9.7 cm [P48F]) and 31 to 34 cm (the other 7 [P48V]).
- Reported, not gated, for E1 against R0 on screened fold B: QMD and BA percent RMSE from the runner results columns
  (`QMD_o`, `QMD_p`, `BA_o`, `BA_p`, at the floor) and C1 volume percent RMSE (R2S convention), all with the R2S point
  formula 100 sqrt(mean((p minus o)²)) / mean(o); points only.
- Fold A: D, X and survivor ratio for each arm, reported, not gated.

## Decision rule, in order

An arm (E1 or S2) **meets the artifact bar** when X_arm is at or above 2/3, its bootstrap lower limit is above 0.5, and
D_arm is not below minus 1/3 of D_R0 (no material overshoot) [choice 3a; values carried from PREREG48 choice 2a, which has
no record provenance [P48DR]; the mirrored 1/3 has none either].

1. Any of G0 to G6 fails: no verdict; the failing gate is named; quantities are reported, labeled "harness failed".
2. **Overcorrection (HO).** D_E1 below 0 with |D_E1| at or above 1/3 of D_R0: floor handling overshoots; the 14.3 track is
   the floor matched ingrowth rate on QC. This rule comes before rule 3 so that an overshoot is never read as an artifact.
3. **Artifact.** E1 and S2 both meet the artifact bar: the deficit is read as floor handling. The 14.3 track is a benchmark
   and runner convention (ingrowth threshold matched to the inventory floor), not an ingrowth coefficient.
4. **Convention dependent.** Exactly one of E1 and S2 meets the artifact bar: the 14.3 track is floor handling, labeled
   "open loop and closed loop disagree", with both values reported.
5. **Real shortfall (HR).** X_E1 and X_S2 both below 1/3 with bootstrap upper limits below 0.5: the 14.3 track is
   ingrowth rate or small tree growth; the report states that the QC frames cannot separate them (fact 4).
6. Otherwise: mixed; no track named; shares and intervals reported.
7. **Labels.** Every verdict carries "previously inspected population". Rules 2 to 6 are re-run on the 153 stands with
   floors of 9.1 to 9.7 cm (same bootstrap draws, restricted to those stands); a verdict that changes is labeled "floor
   group sensitive". If L2 finds no threshold support, "threshold support unknown". If D_S2 is below minus 1/3 of D_R0,
   "S2 overshoots". If E1 moves the survivor ratio outside 0.90 to 1.10 (PREREG14 window, as read by PREREG27 and PREREG48
   [P48DR]), that is reported beside the verdict. G7 may add "floor matched QC run previously seen".

**No outcome changes 14.2.** An artifact verdict does not by itself change the QC scorer: whether the QC scoring floor
should be revisited stays an open item for 14.3 [RN].

## What informs 14.3 only

- Which convention a 14.3 QC benchmark uses for the ingrowth threshold (5.0 cm or the inventory floor).
- Whether a 14.3 QC ingrowth study is needed at all, and if so whether it targets rate (HR, HO) or entry handling (HA).
- Whether the S2 scorer is a usable convention for sets whose t1 lists are floor censored (other sets are named in the
  report, not scored here).

## Execution

New directory `~/jobs/v142p50/` on firebreather (it did not exist on 28 October 2026 at 06:38 server time). This plan's md5
is recorded in `logs/prereg_md5.txt` before any script runs. Inputs are read only; nothing is overwritten; every writer
refuses an existing file.

1. **Build and lookups (read only), written into `logs/lookups.md` with path and md5 before any arm runs.** L1: the bundle
   of TASK (`AcadianGY_13.1.r`, `hw_formrisk_split.R`, `hw_sawfrac_smith.R`, `runner_htfix_fb.R`, `magplot/`,
   `v14_0_4_20260917/`, `v14_1_20260923/`) copied from `~/jobs/v142p19/home/` into `~/jobs/v142p50/home/`, its md5 list
   compared file by file with the source, and the RUN, TASK, ENG and 14.1 overlay md5s checked against Sources; the runner
   copy built with the two asserted edits and its diff kept. L2: the threshold range of the ingrowth equations' fit data.
   L3: the G7 search.
2. **Dry run** on 20 screened fold A stands (drawn with `set.seed(20261028)` from the sorted fold A screened stand list):
   the three runner arms by stand file into `home/dry_out/`, then G2 on those 20 stands and the split and bootstrap
   scripts restricted to them, written under `dryrun/` (fold A only; no fold B output is written in the dry run). Dry run
   output checks the scripts and is not interpreted. Then script md5s go to `logs/launch_md5s.txt`.
3. **Chain, detached (`setsid nohup`).** Launcher: the 57 tasks (G2, E1 and S2 arms, 19 chunks each), at most 2 at once,
   none started at a 1 minute load of 12 or above. Then the PREREG19 retry rule for every arm [RETRY], one stand at a time.
   Then G2 (`p50_g2.R`), the split for R0 and E1 with S2, G0, G1, G3 to G6 (`p50_split.R`), and the bootstrap,
   quantities and decision rule (`p50_boot.R`). The chain refuses to start unless the registration line and every launch
   md5 match.
4. **Assembly** as a separate step, its md5 recorded before it runs: identifier free tables copied to `assembled/` and
   the verdict text written.

At most 2 R processes, none started at load 12 or above (PREREG48 execution rule [P48DR]). Aggregates only leave the
server. Deviations are logged in the RESULT and a DEVIATIONS file.

## Resolved choices (draft 1 open choices; Aaron pre-approved the recommended option of each)

1. **Scorer arm S2: (a)** the engine's own ingrowth equations at the floor threshold, open loop, implemented as one annual
   engine step from the t1 list (fact 8). Not taken: (b) a growth based floor crossing model from an external sub-floor
   stock (none on the QC frames [P48F]); (c) no scorer arm.
2. **Primary population: (a)** all 160 screened fold B stands, floor groups reported apart, "floor group sensitive" label.
   Not taken: (b) floors below 12 cm only.
3. **Thresholds: (a)** 2/3 with lower limit above 0.5 (rules 3 and 4), mirrored 1/3 and 0.5 (rules 2 and 5); no record
   provenance. Not taken: (b) 1/2 with lower limit above 0.25.
4. **Second height arm: (a)** qc141 only. Not taken: (b) E1 also on qc_rh.
5. **Arm E2: (a)** not run, named as a limit. Not taken: (b) run as a bracket after a runner edit.

## Response to draft red team 1 (27 October 2026, self review in a fresh read)

| Item | Change |
|:--|:--|
| Circularity: S1 is already known | S1 made a bracket, never gated; every PREREG48 quantity labeled previously inspected |
| Rule order: an overshoot with X above 2/3 would have read as an artifact | Overcorrection moved ahead of the artifact rule |
| X can exceed 1 from the survivor excess alone | Stated, with predicted and observed new stems reported beside X |
| G3 untestable on t2 lists (ingrowth has grown by t2) | G3 reads the year 1 capture |
| G4 and the S2 against E1 agreement were conflated | G4 is an implementation check; agreement is decision rule 4 |
| S2 assumed annual stand states that the frozen outputs may not hold | S2 runs open loop from the t1 state |
| Floor groups traced | 153 stands at 9.1 to 9.7 cm summed from [P48F]; 7 at 31 to 34 cm from [P48V] |
| Step naming | Lookups named L1 to L3, no "step 2" reference left |
