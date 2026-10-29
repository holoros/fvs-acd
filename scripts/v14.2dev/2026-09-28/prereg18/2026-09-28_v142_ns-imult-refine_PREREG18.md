# NS ingrowth multiplier refined between 1.5 and 2.25 on a held out volume criterion: pre-registration 18

28 September 2026, revision 1, written before any run or score of the new arms and before any fold level volume score of
any arm. It follows PREREG17 (`2026-09-27_v142_ns-ingrowth-multiplier-C1_PREREG17.md`, revision 2, md5 b9dbd707) and its
RESULT. Nothing is fitted except the choice of one scalar from a fixed grid. L and T stay at run 14868899. GT1 stays a named
failure. No em dashes.

## What was already seen, stated openly

This design is not blind to the grid. PREREG17 selected m* = 2.5 by the absolute log pooled stems ratio on ns_c fold A and
failed E3 (ns_long_c d_rmse -0.61) and E6b (ns_fl C1 bias +2.46 against 14.1's -2.28). **After the held out output was
seen, IMULT 1.5 and 2.0 were found to pass every PREREG17 gate** (post hoc table in the PREREG17 RESULT). That observation
is what motivates this track, and it is the reason 1.5 and 2.0 cannot be adopted on PREREG17 evidence. The following
PREREG17 numbers were in view when this document was written:

| Quantity (PREREG17 tables) | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 |
|:--|:--:|:--:|:--:|:--:|:--:|
| ns_c all stands, C1 volume bias, percent | +0.26 | +0.62 | +0.98 | +1.33 | +1.67 |
| ns_c fold A, stems ratio | 0.943 | 0.965 | 0.986 | 1.007 | 1.028 |
| ns_c fold A, basal area ratio | 0.979 | 0.987 | 0.994 | 1.002 | 1.009 |
| ns_long_c, C1 bias | -0.56 | -0.11 | +0.33 | +0.75 | +1.17 |
| ns_fl, C1 bias | -0.96 | +0.24 | +1.38 | +2.46 | +3.51 |
| ns_long_fl, C1 bias | -3.79 | -2.00 | -0.35 | +1.16 | +2.59 |

14.1 (v141LT) reads ns_c C1 -0.37 percent. Fold level C1 volume (fold A or fold B) has not been computed for any arm.

**Expected outcome, stated now.** On ns_c all stands, C1 volume rises monotonically with IMULT and is already above 1 at
1.0. If fold A behaves like all stands, the volume criterion below will choose 1.5, the lower edge, and the Edge gate will
fail. The two alternatives fail the same way in the other direction: fold A basal area and fold A stems both cross 1 near
2.5, so either would be expected to choose 2.25. On the PREREG17 evidence, every single frame criterion on ns_c is monotone
across [1.5, 2.25]. The tension is between frames: consecutive ns_c volume asks for little extra ingrowth, while the long
frame stems and volume ask for 2 to 2.5. The criterion is chosen for what the gates judge, not to produce an interior
point, and the Edge gate is kept as written. An Edge failure at 1.5 is therefore an informative, pre-stated outcome (rule
2a), not a surprise.

## Arms

All arms are v141LT with `ingrowth.min.dbh` set per stand to the scoring threshold (PREREG9, `ING_MIN_FROM_SCORE=1`), the
flat ingrowth multiplier IMULT as below, and no height correction (`HTFIX_B` unset).

| Arm | IMULT | Where it lives | Status |
|:--|:--:|:--|:--|
| v141LTig_m15 | 1.5 | Cardinal `recs/ingthr/out/` (array 14922031), scored in `recs/p17/` | Exists, frozen |
| v141LTig_m175 | 1.75 | Firebreather `~/jobs/v142p18/` | New, NS four |
| v141LTig_m20 | 2.0 | Cardinal, same as 1.5 | Exists, frozen |
| v141LTig_m225 | 2.25 | Firebreather `~/jobs/v142p18/` | New, NS four |
| v141LT | (2.5, no matching) | Cardinal bench141 | Reference, read from PREREG16 `tables_r1` (scores md5 a3ed3b76, stands md5 d600f398) |

The grid is fixed at {1.5, 1.75, 2.0, 2.25} and is not extended after results are seen. Frozen runs are read, not rerun.

**Harness.** `~/jobs/v142p17/home` is copied to `~/jobs/v142p18/home` without its `out*`, `logs`, `tables` and retry
directories. Runner `runner_htfix_fb.R` md5 4e6a2997, unchanged. The task driver `run_task_p18.sh` is `run_task_p17.sh`
(md5 b1eb7e04) with only the arm case changed (v141LTig_m175 sets IMULT 1.75, v141LTig_m225 sets 2.25; the G0 task is
removed). The taskmap is the 36 bench141 NS chunks of the PREREG17 3.0 arm, written once per arm (72 tasks). **G0 is cited,
not rerun**: PREREG17 established that this exact bundle on firebreather reproduces Cardinal to 6.27e-15 on 150 stands. The
driver md5 checks every model, coefficient and runner file at each task, and the frames are checked by md5 against the
PREREG17 copy before launch; if any differs, the run stops and G0 is repeated under a new revision.

**Launch.** At most 4 model tasks at once (firebreather is shared with three sibling tracks and another session). A new
task starts only when fewer than 4 of this track's tasks run and the 1 minute load average is at or below 14. Order: ns_c
(both arms), then ns_long_fl, ns_fl, ns_long_c. PREREG17 timing (37 tasks, 8 at a time, about 1.6 h per task at load 16)
implies roughly a day of wall time; the run is left to finish unattended and is read by a later session. Wall time is not a
result.

## Host time limit retry rule (revision 2 of PREREG17, adopted up front)

The runner caps each stand at 60 s elapsed and records a stand that exceeds it as RUN_OK 0 with FAIL_REASON "reached elapsed
time limit". After the main run, every such stand is rerun alone, **selected by STAND name** through `STAND_KEEP_FILE`
(never by pairs row, after the PREREG17 BADROW failure), with the same environment, into `out_retry_a<k>/`, up to three
attempts. The driver checks that the stand returned is the stand requested and renames the output `_BADSTAND` otherwise.
The retried stand replaces the original row in place (row order unchanged, so the site bootstrap draws still align) in the
results and in the per tree lists. K1 counts failures after retry; a stand still timed out after three attempts, or a
failure for any other reason, counts against K1.

## Selection rule, fixed now

Fit data: ns_c, fold A sites only (PREREG11 fold: md5 of SITE, first hex digit even is A). C1 is the PREREG16 convention,
himp heights on both sides, taken from the scorer's per stand table (V_oh observed, V_ph predicted; scorer
`2026-09-27_v142_volconv_score.R`, md5 019df238). For each grid value the loss is

  loss(m) = | log( sum V_ph / sum V_oh ) |, summed over the scored stands of ns_c fold A.

m* is the grid value with the smallest loss. **Tie rule:** if the two smallest losses differ by less than 0.0005, m* is the
smaller IMULT of the two (the smaller departure from 14.1 and from the Maine value 1.0). Provenance: 0.0005 is under a third
of the smallest ns_c C1 ratio change per 0.25 IMULT step in PREREG17 (0.0018). No fold B, ns_long_c, ns_fl or ns_long_fl
output is used to choose m*. Why volume and not basal area: every volume gate judges C1 volume, and PREREG17 showed that
stems at 1 is not the volume optimum; basal area was considered and not chosen because it is a component of the same
tension, not the quantity gated.

## Gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| K1 failures | RUN_OK other than 1 at m*, NS four, after retry | 0 | H2; PREREG17 K1 |
| S1 stems (held out) | Pooled stems ratio at m* against v141LT on ns_c fold B, ns_long_c, ns_fl, ns_long_fl | Absolute log ratio smaller than under v141LT in all four | PREREG7, PREREG9 J2, PREREG10 K2, PREREG17 |
| E3 (C1) | Consecutive TOTVOL %RMSE, m* against v141LT, ns_c and ns_long_c | d_rmse = %RMSE(v141LT) minus %RMSE(m*) at or above -0.5 | E3 with reference 14.1; PREREG16 convention; PREREG17 |
| E6b (C1) | First to last TOTVOL absolute bias, ns_fl and ns_long_fl | No worse than v141LT | E6b with reference 14.1; PREREG16; PREREG17 |
| Edge | m* interior to the grid | m* not 1.5 and not 2.25 | This design |
| VB volume (held out) | C1 at m* on ns_c fold B: (a) pooled volume ratio, 95 percent site cluster interval; (b) %RMSE against v141LT on fold B | (a) interval contains 1; (b) fold B d_rmse at or above -0.5 | (a) the site cluster interval reading of benchmark volume ratios (PREREG16); (b) E3 threshold carried to fold B |

The fold B interval uses the benchmark draws (`siteidx_ns_c.rds`, md5 b26edb9d) with the fold B stand rows of the weight
matrix, as the scorer does for its screened population. As a hard check, the fold script must reproduce the scorer's all
stands C1 ratio and interval for every arm to 1e-9 before any fold value is used. Every v141LT value is read from PREREG16
`tables_r1` at scoring time, never typed in [F9].

## Reported, not gated

- The selection loss for all four grid points on fold A, fold B and ns_long_c, and the fold A losses under basal area,
  stems and the larger of the stems and volume losses, so the reader sees where each criterion lands.
- C0 beside C1 for every row (C2 needs the pass 28 tag frames, which exist only on Cardinal; the new arms are C0 and C1).
- Basal area, QMD and stems ratios and TOPHT bias for all grid points and the NS four.

## Decision rule, stated now

Evaluated in order; exactly one outcome applies.

1. **K1 fails at m*:** no verdict. The failure is repaired under a new revision.
2. **Edge fails:** not adopted. 2a, m* = 1.5: the held out consecutive volume criterion asks for no more ingrowth than 1.5,
   as the PREREG17 all stands values predicted; a flat NS multiplier cannot be placed inside the window the long frame gates
   accept from consecutive held out data, and the next step is an interval length dependent term (ingrowth or survival over
   long intervals), not a flat scalar. 2b, m* = 2.25: the grid does not bracket the volume optimum, contrary to PREREG17's
   monotone ns_c values; the scoring is audited before any reading, and extension needs a new pre-registration.
3. **Edge passes and S1, E3, E6b and VB all pass:** threshold matching with IMULT m* on NS becomes the 14.2 candidate NS
   configuration, a regional usage setting beside the NB and QC anchors, not adopted into a release before a Bakuzis NS grid
   under its own pre-registration. Maine stays at 1.0; 14.1 is unchanged.
4. **Edge passes and only VB fails:** not adopted; m* fits the gated frames but not unseen consecutive sites.
5. **Edge passes and only S1 fails:** not adopted; stems at m* are not better than 14.1 on the named held out set.
6. **Edge passes and only E6b fails:** not adopted; the sign of the failing bias says which frame bounds IMULT (ns_fl
   overshoot bounds it from above, ns_long_fl deficit from below).
7. **Edge passes and only E3 fails:** not adopted; long frame gains cost consecutive accuracy.
8. **Edge passes and two or more of S1, E3, E6b, VB fail:** not adopted; each failing gate is reported and none is read
   beyond its own test.

## Caveats stated now

Fold A and fold B share no sites, but ns_long_c and ns_long_fl share plots with ns_c, so only ns_c fold B is held out in
the strict sense. The new arms run on a different host and R build (4.5.1 against 4.5.2) than 1.5 and 2.0; the cited G0 is
what licenses mixing them. The scorer's output file names carry its fixed date stamp; the wrapper renames them to the run
date without changing content.

## Constraints

New directories only (`~/jobs/v142p18/` on firebreather). Cardinal is read only, for the frozen 1.5 and 2.0 per stand
tables and the PREREG16 references. No coordinates are read into or written to any output. L and T are not touched.
Nothing is sent outside.
