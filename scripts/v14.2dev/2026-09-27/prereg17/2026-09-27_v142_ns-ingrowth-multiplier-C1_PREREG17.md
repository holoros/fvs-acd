# NS ingrowth multiplier under threshold matching, scored under C1: pre-registration 17

27 September 2026, revision 1, written before any run or score of these arms. Aaron chose this track after PREREG16. It
builds on PREREG9 (threshold matching), PREREG10 (the IMULT grid, fitted on Maine) and the v141LThi arm of PREREG11
(threshold matching at IMULT 1.0 with the height correction). Nothing is fitted except the choice of one scalar from a
fixed grid. L and T stay at run 14868899. GT1 stays a named failure. No em dashes.

## Why this is the next test

PREREG9 fixed NS stems, QMD and basal area (all within 3 percent of 1 at IMULT 2.5) and failed E6b because volume rose.
PREREG10 chose IMULT 1.0 on the Maine sets, which left NS stems short, and failed E6b by 1.5 to 1.9 points. v141LThi
showed that at IMULT 1.0 the long first to last frame stays short of stems. All three volume verdicts were read under C0,
where observed and predicted volume use different heights, and PREREG16 showed that on NS the C0 over C1 gap is +2.0 to
+6.5 percent and carries the model's own height error (NS model heights run tall). Under C1, 14.1 reads ns_long_fl -4.5
percent, which is the stem deficit seen directly. So two questions were confounded: what NS ingrowth multiplier the
threshold matched submodel needs, and whether a volume gate fails because of stems or because of height. C1 takes height
out of volume. This pre-registration fits the multiplier on NS itself and scores every volume gate under C1.

## Arms

All arms are v141LT with `ingrowth.min.dbh` set per stand to the scoring threshold (PREREG9, `ING_MIN_FROM_SCORE=1`) and
the flat ingrowth multiplier IMULT set as below. No height correction (`HTFIX_B` unset; PREREG11 is not adopted).

| Arm | IMULT | Where it lives | Status |
|:--|:--:|:--|:--|
| v141LTig_m10 | 1.0 | Cardinal `recs/ingthr/out/` (array 14922031) | Exists, frozen, scored here under C1 |
| v141LTig_m15 | 1.5 | Cardinal, same | Exists, frozen |
| v141LTig_m20 | 2.0 | Cardinal, same | Exists, frozen |
| v141LTig | 2.5 | Cardinal `recs/ingthr/out/` (array 14921116) | Exists, frozen |
| v141LTig_m30 | 3.0 | Firebreather `~/jobs/v142p17/` | New, NS chunks only |
| v141LT | (2.5, no matching) | Cardinal bench141 | Reference, C1 scores read from PREREG16 `tables_r1` |

The grid is fixed at {1.0, 1.5, 2.0, 2.5, 3.0}. The 3.0 point exists so that 2.5 is not the edge; PREREG10's NS stems
under C0 were near 1 at 2.5, so the minimum was expected near there. The grid is not extended after results are seen.

**Harness for the new arm.** The firebreather bundle of PREREG11 (`~/jobs/v142htf/home`, runner `runner_htfix_fb.R` md5
4e6a2997) copied into `~/jobs/v142p17/home`, with a new task driver whose environment is the bench141 block verbatim,
`HTFIX_B` unset (the runner then leaves `dht.mult` alone), `ING_MIN_FROM_SCORE=1` and `IMULT=3.0`. Chunking is the
bench141 taskmap for the four NS sets (36 chunks). Tasks run 8 at a time under `setsid nohup`, ordered ns_c first, then
ns_long_fl, ns_fl and ns_long_c.

**Sets.** Gated: the NS four (ns_c, ns_fl, ns_long_c, ns_long_fl). Controls, reported and not gated, on the four
Cardinal arms only: memat_c, medev_c, mefia_l_c, pef_c, ctrn_c and baxter_c (the PREREG10 fit sets) and qc_c
(unscreened and screened). The controls answer whether one multiplier can serve NS and Maine together, or whether NS
needs a regional value, in the way NB and QC already carry regional anchors.

## Selection rule, fixed now

Fit data: ns_c, fold A sites only. Fold is the PREREG11 rule (md5 of SITE, first hex digit even is A). For each grid
value, the loss is the absolute log of the pooled stems ratio, predicted over observed, summed over RUN_OK stands, with
TPH = BA / (pi / 40000 * QMD²) as in PREREG9 J2. The chosen IMULT, m*, is the grid value with the smallest loss. No ns_c
fold B, ns_fl, ns_long_c or ns_long_fl output and no volume is used to choose it.

## Gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 harness | Firebreather IMULT 2.5 on ns_long_fl chunk 5 against Cardinal v141LTig chunk 5, every predicted column | Worst scaled difference at or below 1e-9 | PREREG11 H0 deviation (R 4.5.1 against 4.5.2) |
| K1 failures | RUN_OK other than 1, arm m*, NS four | 0 | H2 |
| S1 stems (held out) | Pooled stems ratio at m* against v141LT on ns_c fold B, ns_long_c, ns_fl and ns_long_fl | Absolute log ratio smaller than under v141LT in all four | PREREG7, PREREG9 J2, PREREG10 K2 |
| E3 (C1) | Consecutive TOTVOL %RMSE under C1, m* against v141LT, ns_c and ns_long_c | d_rmse = %RMSE(v141LT) minus %RMSE(m*) at or above -0.5 | E3 with reference 14.1; PREREG16 convention |
| E6b (C1) | First to last TOTVOL absolute bias under C1, ns_fl and ns_long_fl | No worse than v141LT under C1 | E6b with reference 14.1; PREREG16 convention |
| Edge | m* is interior to the grid | m* not 1.0 and not 3.0 | This design |

Every v141LT reference value is read from PREREG16 `tables_r1` (Cardinal job 14937306) at scoring time, not typed in
[F9]. The volume scorer is `2026-09-27_v142_volconv_score.R` (md5 019df238) through a new plan CSV; its own V0 (C0
reproduced to 1e-6 relative), V1 (coverage) and V2 (0 to 1,500 m³ ha⁻¹) run as hard stops on every row. The site
cluster bootstrap uses the benchmark draws (`score/work/siteidx_<set>.rds`, copied by md5 to firebreather for the
new arm).

## Reported, not gated

- C0 and C2 beside C1 for every row where they exist. C2 needs the pass 28 tag frames, which exist only on Cardinal, so
  the 3.0 arm is reported under C0 and C1 only.
- Basal area, QMD and stems ratios, TOPHT bias (height scored on its own, per PREREG16), all grid points, NS four and
  controls.
- The selection loss curve over the grid, and the same loss on ns_c fold B and on ns_long_c, to show whether the minimum
  moves with the frame.

## Decision rule, stated now

1. **G0 or K1 fails:** stop. No verdict on the multiplier; the harness is repaired under a new revision.
2. **Every gate passes:** threshold matching with IMULT m* on NS becomes the 14.2 candidate NS configuration, as a
   regional usage setting beside the NB and QC anchors. It is not adopted into a release before a Bakuzis NS grid under
   its own pre-registration (the PREREG4 part B pattern). 14.1 is unchanged.
3. **Edge fails (m* is 1.0 or 3.0):** not adopted. Extending the grid needs a new pre-registration.
4. **S1 fails on ns_long_fl only:** the long frame deficit is not an ingrowth rate problem. The next suspect is survival
   over long intervals, not the multiplier.
5. **S1 passes and E6b (C1) fails:** the long frame volume deficit is not carried by stems; the diameter part of volume
   (diameter growth of survivors) is the next suspect.
6. **S1 and E6b pass, E3 fails:** not adopted; the multiplier buys long frame stems at the cost of consecutive accuracy.

## Caveats stated now

Fold A and fold B share no sites, but ns_long_c and ns_long_fl share plots with ns_c, so only ns_c fold B is held out in
the strict sense; the other three are called held out from the fit data, not independent. The 3.0 arm runs on a
different host and R build than the grid points; G0 is what licenses mixing them. Firebreather is shared with another
session's work, so wall time is not a result.

## Constraints

New directories only (`~/jobs/v142p17/` on firebreather; `v142_20260925/recs/p17/` on Cardinal for scoring). Frozen runs
are read, not rerun; G0 writes into the new directory only. No coordinates are read into or written to any output. L and
T are not touched. Nothing is sent outside.

## Amendment, revision 2 (27 September, 17:58 UTC): host time limit retries

**What happened.** The runner caps each stand at 60 s of elapsed time (`setTimeLimit(elapsed = 60)`, runner line 423) and
records a stand that exceeds it as RUN_OK 0 with FAIL_REASON "reached elapsed time limit". Firebreather has run at a load
average near 16 on 8 cores all day because another session's job shares it. G0 as first read failed: 149 of 150 stands
match Cardinal to at most 6.2e-15 on every predicted column, and the one remaining stand (row 668 of the ns_long_fl pairs
file) hit the time limit on firebreather and ran normally on Cardinal. Two stands of the 3.0 arm (ns_long_fl chunks 6 and
7) have hit the same limit so far. A time limit failure is a host failure, not a model failure.

**Rule added.** After the main run, every stand whose FAIL_REASON contains "reached elapsed time limit" is rerun alone
(CHUNK_FROM = CHUNK_TO = its pairs row) with the same environment, into `out_retry_a<k>/`, up to three attempts. The
retried stand replaces the original row in the assembled results and in the per tree lists (the scorer's later directory
rule). G0 is judged after the retry: the retried stand must also match Cardinal within 1e-9. That also tests that a stand
run alone reproduces the same stand run inside its chunk. K1 counts failures after the retry. A failure for any other
reason counts against K1 as before, and a stand still timing out after three attempts counts as a failure.

**Disclosure.** This amendment was written after the first G0 read and after the ns_c part of the 3.0 arm had finished
(ns_c fold A pooled stems at IMULT 3.0: 1.028). It changes only the harness. The grid, the selection rule, the gates and
their thresholds, and the decision rule are unchanged.
