# QC ingrowth entry size and scoring floor handling, for 14.3: preregistration 50

**DRAFT, not registered.** 27 October 2026, draft 1. Written after the PREREG48 RESULT and its verification addendum, and
before any PREREG50 script, join, engine run or table exists. Nothing is fitted and no engine coefficient changes. The
outcome **informs 14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579** [P48R header]. L and T are not refitted. GT1
stays a named failure. Frozen runs are read, never rerun. Stand identifiers stay in `*_SERVERONLY` files. No coordinates.
No em dashes. Open choices are listed at the end, recommended option first; each is marked in the text where it applies.

## Sources (every number below cites one of these)

| Tag | File |
|:--|:--|
| P48R | `scripts/v14.2dev/2026-10-26/rec_b/v142p48/2026-10-26_v142_qc-stems-deficit_RESULT.md` (worktree of `holoros/fvs-acd`, branch `v142-autopilot-20261026`, commit 4014cde), body tables |
| P48V | the same file, section "Verification addendum (26 October 2026, revision r1)"; recomputation scripts in firebreather `~/jobs/v142p48_verify_20261026/` (`verify.R`, `verify2.R`, `verify3.R`; console output only, no output files) |
| P48D | `.../v142p48/2026-10-26_v142_qc-stems-deficit_DEVIATIONS.md` |
| P48F | firebreather `~/jobs/v142p48/assembled/gyr142-p48-floor_DATA_2026-10-26.csv` and `gyr142-p48-framecheck_DATA_2026-10-26.csv` |
| P48I | firebreather `~/jobs/v142p48/assembled/gyr142-p48-input-md5_DATA_2026-10-26.csv` |
| P48DR | `scripts/v14.2dev/2026-10-11/drafts/2026-10-11_v142_qc-stems-deficit_PREREG48_DRAFT.md` |
| RUN | firebreather `~/jobs/v142p19/home/runner_htfix_fb.R`, md5 4e6a29971922b1f7a0397cc91ff56f84 (line 274: `ingrowth.min.dbh=5.0`; line 433: `ING_MIN_FROM_SCORE`, commented "PREREG9: ingrowth threshold = scoring threshold") |
| TASK | firebreather `~/jobs/v142p19/scripts/run_task_p19.sh`, md5 ac029e4e6eeb1d71f1784b423c8575fc (line 34 unsets `ING_MIN_FROM_SCORE` for the QC arms) |
| P26S | firebreather `~/jobs/v142p26/scripts/run_p26.sh` (lines 5, 7, 20: the NS v141LTfi and v141LTi arms export `ING_MIN_FROM_SCORE=1`) |
| ENG | firebreather `~/jobs/v142p19/home/AcadianGY_13.1.r`, md5 5894df6013c701d09e7ba67ba6c2f090 (lines 2808 to 2822: `min.dbh.ingrowth` enters the ingrowth occurrence link and the ingrowth count link; line 2857: it enters the species composition link; line 2911: entry DBH is `ops$ingrowth.entry.dbh` when set, otherwise `min.dbh.ingrowth`). The 14.1 overlay `v14_1_20260923/AcadianGY_14.1.r` (md5 0bf27dde81240e6bdf59c9a90f0051bd) contains no ingrowth code (0 matches for "ingrowth") |
| FST | firebreather `~/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv`, md5 184dc76888580de7c2cfdb7e2ec8580f |
| LK | `scripts/v14.2dev/2026-10-26/rec_b/v142p49_lookup_20261026/LOOKUPS.md`, lines 46 to 50 (fold rule) |
| RN | `scripts/v14.2dev/2026-10-27/release-notes/2026-10-27_fvs-acd-v14.2_release-notes_DRAFT.md`, "Open items" |

## What is known before this plan (previously inspected)

All of this was read before PREREG50 was written, on both folds of screened qc_c, so every PREREG48 quantity is
**previously inspected** here and none of it can serve as a confirmatory test.

1. Every QC anchor arm runs about 24 points low on stems. On screened qc_c fold B the qc141 stems deviation is 24.226
   points (18.959 to 29.910), with observed stems 154648 and predicted 117183 trees ha⁻¹ summed over 160 stands, so
   D = 37465 [P48R]. The release notes carry it as an open item [RN].
2. PREREG48 placed the whole deficit in stems that cross the scoring floor between visits: observed new tags at or above
   the floor sum to 47607 trees ha⁻¹, against 65.493 engine ingrowth trees at or above the floor (qc141); the survivor
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

| Arm | Kind | What changes | Status |
|:--|:--|:--|:--|
| R0 | reference | frozen qc141 (p19_a0111, results md5 979101be [P48I]) scored as PREREG48 | reproduction |
| S1 | scorer convention | predicted new stems = all engine ingrowth records at any size; observed = new tags at or above the floor | **bracket only**: its value (51728 against 47607) is already known [P48V], so it is reported, never gated |
| S2 | scorer convention, explicit floor crossing model | predicted new stems at the floor = the engine's own ingrowth equations [ENG] evaluated with `min.dbh.ingrowth` set to the stand floor, open loop from the t1 stand state held over the interval (annual rate times interval); added to frozen qc141 survivors at the floor | new [choice 1] |
| E1 | engine run, convention | qc141 settings exactly [TASK], except `ING_MIN_FROM_SCORE=1` exported, so ingrowth is predicted past the stand floor and enters at it [RUN line 433, ENG line 2911] | new |
| E2 | engine run, convention | entry DBH set to the floor through `ops$ingrowth.entry.dbh` while the threshold stays 5.0 cm (rate of 5 cm recruits placed at the floor); needs a runner edit to expose the option | not run unless choice 5 says so |

S2 and E1 use the same fitted equations at the same threshold; S2 holds stand state open loop, E1 lets the ingrowth
compete and grow. Gate G4 checks that S2 computes the engine's equations exactly; whether the two then agree on the
deficit is an outcome, handled by decision rule 4, and only agreement licenses reading S2 as a scorer convention a 14.3
benchmark could adopt.

**Support limit.** Whether the ingrowth equations were fitted over thresholds near 9 to 34 cm is not known from the files
read. Lookup L2 looks for the fit data's threshold range. If it is not found, every S2 and E1 result carries
"threshold support unknown", and stands with floors of 31 to 34 cm are reported apart under choice 2.

## Population and folds

Screened qc_c (PREREG19 cut flag FALSE), RUN_OK 1, field tag frames `v142p14/in/pass28qc` [P48I]. FST holds 313 screened
and 65 cut qc_c stands (both folds; arm p19_a0111) [FST]. Folds by the PREREG11 rule: md5 of the SITE string (digest,
serialize = FALSE), first hex digit even is fold A, odd is fold B [LK]. **Fold B is gated; fold A is a replication,
reported and not gated**, as in PREREG48 [P48DR]. Nothing in this plan is tuned, so fold A is not used to choose anything.
Both folds' PREREG48 quantities are previously inspected; S2 and E1 quantities exist on neither fold.

Pairing uses the MAGPlot field tags only; any join keyed on the run frame TREE column stops the script (PREREG36, PREREG37,
as carried by [P48DR]). Pooling is sums over stands, as PREREG48 [P48D].

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | R0 reproduces PREREG48 fold B: stems deviation 24.22615, D 37465, observed I 47607, predicted I 65.4935 | equal to the published rounding | [P48R], [P48V] |
| G1 | R0 reproduces the entry facts: minimum ingrowth DBH 5.0 cm, median 5.67, 7 of 6042 records at or above the floor, all size sum 51728 | equal to the published rounding | [P48V] |
| G2 | the PREREG50 runner copy with `ING_MIN_FROM_SCORE` unset reproduces frozen qc141 results and tree files byte for byte on every screened qc_c stand | identical | E0 practice of PREREG2 (14.3 PREREG2, gate E0) |
| G3 | E1 trace: on every stand the logged `ops$ingrowth.min.dbh` equals `SCORE_MINDBH_USED`, and in the year 1 capture every ingrowth record added in year 1 has DBH equal to it | difference at or below 1e-9 | [RUN line 433], [ENG line 2911]; tolerance [choice, no record] |
| G4 | S2 reimplementation: the year 1 ingrowth per hectare and species shares computed by the S2 scorer equal those the E1 engine produces for the same stand state, on a 20 stand sample, read from E1's year 1 tree capture (the runner's `TREE_OUT` year 1 snapshot [RUN]) | relative difference at or below 1e-9 | [choice, no record] |
| G5 | K1: RUN_OK 1 on every E1 stand | 0 failures | K1 practice of PREREG2 and PREREG49 |
| G6 | fold assignment equals `fold_of` and the PREREG22 rule script | identical | [LK], [P48D] |
| G7 | no QC result with `ING_MIN_FROM_SCORE=1` exists on firebreather before E1 (search of `~/jobs/*/scripts` and run logs, logged) | none found, or each found run listed and the verdict labeled "floor matched QC run previously seen" | fact 7 |

Any failure of G0 to G6 is a harness failure. G7 changes a label, not the verdict.

## Quantities (fold B, per arm)

- D_arm = observed minus predicted stems at or above the stand floor, trees ha⁻¹ summed over stands, as PREREG48.
- Explained share X_arm = (D_R0 minus D_arm) over D_R0, with a 95% site cluster bootstrap interval (B = 1000, seed
  20261001, the PREREG48 construction [P48D]).
- Survivor ratio S_p over S_o for E1 (E1 changes competition, so survivors can move). Because R0 already keeps 10076
  more survivors than observed (117117 against 107041 [P48R]), X_arm can exceed 1 without any overshoot in new stems;
  predicted and observed new stems at the floor are therefore reported beside X.
- Predicted against observed new stems at or above the floor, by floor group: 9.1 to 9.7 cm (153 stands: 101, 22, 11,
  11, 5 and 3 at 9.1 to 9.7 cm [P48F]) and 31 to 34 cm (the other 7 [P48V]).
- Reported, not gated, for E1 against R0: QMD, BA and C1 volume %RMSE on screened fold B.

## Decision rule, in order

1. Any of G0 to G6 fails: no verdict; the failing gate is named.
2. **Overcorrection (HO).** D_E1 below 0 with |D_E1| at or above 1/3 of D_R0 [choice 3, no record]: floor handling
   overshoots; the 14.3 track is the floor matched ingrowth rate on QC. This rule comes before rule 3 so that an
   overshoot is never read as an artifact.
3. **Artifact.** X_E1 and X_S2 both at or above 2/3, with bootstrap lower limits above 0.5 [choice 3; values carried from
   PREREG48 choice 2a, which has no record provenance [P48DR]]: the deficit is read as floor handling. The 14.3 track is a
   benchmark and runner convention (ingrowth threshold matched to the inventory floor), not an ingrowth coefficient.
4. **Convention dependent.** Exactly one of X_E1 and X_S2 meets rule 3: the 14.3 track is floor handling, labeled
   "open loop and closed loop disagree", with both values reported.
5. **Real shortfall (HR).** X_E1 and X_S2 both below 1/3 with bootstrap upper limits below 0.5 [choice 3, no record]:
   the 14.3 track is ingrowth rate or small tree growth; the report states that the QC frames cannot separate them
   (fact 4).
6. Otherwise: mixed; no track named; shares and intervals reported.
7. **Labels.** Every verdict carries "previously inspected population" (fact list above). A verdict that changes when the
   seven stands with floors of 31 to 34 cm are dropped is labeled "floor group sensitive". If L2 finds no threshold
   support, "threshold support unknown". If E1 moves the survivor ratio outside 0.90 to 1.10 (PREREG14 window, as read by
   PREREG27 and PREREG48 [P48DR]), that is reported beside the verdict.

**No outcome changes 14.2.** An artifact verdict does not by itself change the QC scorer: whether the QC scoring floor
should be revisited stays an open item for 14.3 [RN].

## What informs 14.3 only

- Which convention a 14.3 QC benchmark uses for the ingrowth threshold (5.0 cm or the inventory floor).
- Whether a 14.3 QC ingrowth study is needed at all, and if so whether it targets rate (HR, HO) or entry handling (HA).
- Whether the S2 scorer is a usable convention for sets whose t1 lists are floor censored (other sets are named in the
  report, not scored here).

## Execution

New directory `~/jobs/v142p50/` on firebreather (it does not exist on 27 October 2026). This plan's md5 is recorded in
`logs/prereg_md5.txt` before any script runs.

1. **Lookups (read only), each written into `logs/lookups.md` with path and md5 before any arm runs:** L1 the
   runner, model and task files named in Sources, copied into `~/jobs/v142p50/home/` and md5 checked against them; L2 the
   threshold range in the ingrowth equations' fit data, if any record of it is on firebreather or in the repository; L3 the
   G7 search.
2. Scripts, dry run on a 20 stand subset of fold A (no fold B output is written in the dry run), then script md5s to
   `logs/launch_md5s.txt`.
3. R0, G0, G1, G6; G2 on the runner copy.
4. E1 on all screened qc_c stands (both folds), then G3, G5; S2 scorer, G4.
5. Bootstrap and assembly as a separate step, its md5 recorded before it runs.

Chain detached (`setsid nohup`). At most 2 R processes, none started at load 12 or above (PREREG48 execution rule
[P48DR]). Inputs are read only; nothing is overwritten. Aggregates only leave the server. Deviations are logged in the
RESULT and a DEVIATIONS file.

## Open choices (recommended option first)

1. **Scorer arm S2.**
   (a) The engine's own ingrowth equations at the floor threshold, open loop, as written above.
   (b) A growth based floor crossing model from an external sub-floor stock (a set with trees measured below 9 cm); none
   exists on the QC frames [P48F], so this needs a source named first.
   (c) No scorer arm; E1 only.
2. **Primary population.**
   (a) All 160 screened fold B stands, for continuity with G0, with the floor groups 9.1 to 9.7 and 31 to 34 cm reported
   apart and the "floor group sensitive" label.
   (b) Stands with floors below 12 cm only [cut point: choice, no record], the high floor stands reported.
3. **Thresholds for rules 2 to 5.**
   (a) Carry PREREG48 choice 2a: 2/3 with lower limit above 0.5 (rules 3 and 4); mirror values 1/3 and 0.5 for rules 2
   and 5. None has record provenance.
   (b) 1/2 with lower limit above 0.25 [no record].
4. **Second height arm.**
   (a) qc141 only; the PREREG48 AR gate already passed at 0.32 points against 2.0 [P48R], so a second arm adds cost, not
   information.
   (b) E1 also on qc_rh, with AR within 2.0 points (PREREG38 B2, as applied in PREREG45 [P48DR]).
5. **Arm E2 (entry size only).**
   (a) Not run; named as a limit, since it places 5 cm rate recruits at the floor and has no record basis.
   (b) Run as a bracket after a logged runner edit exposing `ops$ingrowth.entry.dbh`, reported only.

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
