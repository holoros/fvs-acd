# The PREREG20 NS height form paired with the PREREG18 ingrowth setting: pre-registration 22

29 September 2026, revision 1. Written while the PREREG18 chain is still running (62 of 72 tasks done at 07:32 server time)
and before any PREREG18 output has been read. It follows PREREG20 (`2026-09-28_v142_ns-height-form-25cm_PREREG20.md`, md5
ea5e37cd) and its RESULT, and PREREG18 (`2026-09-28_v142_ns-imult-refine_PREREG18.md`, md5 c78b477c). Nothing is fitted.
L and T stay at run 14868899. GT1 stays a named failure. No em dashes.

## Why

PREREG20 closed on rule 6: the two segment NS height increment multiplier m(D) = exp(-b1 (min(D, 25) - 12.7)+ - b2 (D -
25)+), b1 = 0.034416, b2 = 0.005072, passed G0, CTL, K1, H1, H2 and E3, and failed E6b narrowly (C1 first to last bias
ns_fl -2.28 to -2.36 percent, ns_long_fl -4.49 to -4.51). Its rule 6 says the height form is right, the long frame volume
deficit is still carried by stems (PREREG17), and the next step pairs the form with the ingrowth setting PREREG18 selects.
This is that step. The question is only whether the pair passes the gates each part was held to.

## What is fixed now, before PREREG18 closes

**The ingrowth arm is PREREG18's m* as output by its selection rule, whatever PREREG18's verdict.** m* is read by script
(`p22_mstar.sh`) from one PREREG18 file, the assembly's `assembled/gyr142-p18-verdict_DATA_2026-09-28.txt` (line
`m_star=`), after `CHAIN_DONE` appears in `~/jobs/v142p18/logs_chain.txt`. An Edge failure (PREREG18 rule 2a or 2b) or any
gate failure at m* does not change the arm: m* is used as the conservative or edge value it is. **PREREG22 does not launch,
and says so in its chain log, if** PREREG18 ends with K1 failure at m* (its rule 1), if the file or its `m_star` line is
absent, if the file predates the PREREG18 chain start, if m* is not in {1.5, 1.75, 2.0, 2.25}, or if the PREREG18 chain
process ends without `CHAIN_DONE`. No other PREREG18 output is read before launch.

## What was already seen, stated openly

The PREREG17 numbers at IMULT 1.5 and 2.0 under 14.1 heights (C1 bias ns_fl +0.24 and +1.38, ns_long_fl -2.00 and -0.35;
d_rmse ns_c -0.16 and -0.23, ns_long_c -0.26 and -0.43) and the whole PREREG20 result were in view. No 1.75 or 2.25 value
and no PREREG18 selection, fold volume, gate or verdict was seen.

## Arms and harness

| Column | What | Sets | Rows |
|:--|:--|:--|:--|
| g0_off | Both parts off: no height correction, no threshold matching, IMULT at the bench141 value 2.5 | ns_c | admitted rows 1 to 100 (chunk 1) |
| ctl_memat | Height part on (b1, b2 as above); the NS ingrowth setting is never set for Maine | memat_c | admitted rows 1003 to 1152 (chunk 2) |
| v141LTfi | PREREG20 height form plus threshold matching (`ING_MIN_FROM_SCORE=1`) with IMULT m* | NS four | the 36 chunks of the PREREG20 v141LTf taskmap |

The v141LTfi rows are the PREREG20 taskmap `~/jobs/v142p20/home/work/p20_taskmap_DATA_2026-09-28.csv` with the arm name
changed and nothing else (checked: 36 rows, same chunks). Bundle `~/jobs/v142p22/home`, a copy of the PREREG20 bundle
(model, coefficient and frame files md5 identical over 34 files). **Runner reused unedited:** `runner_p20_fb.R` (md5
65392afb) already reads the height form from `HTFIX_B1` and `HTFIX_B2` and the ingrowth setting from `ING_MIN_FROM_SCORE` and
`IMULT`, so only the environment file changes (`p22_env.sh`, diff against `p20_env.sh` recorded). The environment refuses
v141LTfi on a non NS set and refuses an IMULT outside the PREREG18 grid. At most 2 tasks at once, and none starts while
the 1 minute load is above 14. Wall time is not a result.

**Retry rule, up front.** The runner caps a stand at 60 s. Every stand whose FAIL_REASON is the time limit is rerun alone,
selected by STAND name through `STAND_KEEP_FILE` (never by pairs row), up to three attempts; the driver checks that the
stand returned is the stand requested and renames the output `_BADSTAND` otherwise. Retried stands replace the originals in
place. K1 counts failures after retry.

## Gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | g0_off against frozen Cardinal v141LT ns_c chunk 1, every predicted column and RUN_OK | Worst scaled difference at or below 1e-9 | PREREG20 G0 |
| CTL | ctl_memat against frozen Cardinal v141LT memat_c chunk 2 | At or below 1e-9 | PREREG20 CTL |
| K1 | RUN_OK other than 1, v141LTfi, NS four, after retry | 0 | PREREG20 K1 |
| H1 | TOPHT absolute bias, v141LTfi against v141LT | Smaller on all four NS sets | PREREG20 H1 |
| H2 | Annual height increment ratio, trees 25 cm and over, fold B, ns_c and ns_long_c | Absolute deviation from 1 smaller than both 14.1 and PREREG11 v141LTh | PREREG20 H2 |
| S1 | Pooled stems ratio, v141LTfi against v141LT, on ns_c fold B, ns_long_c, ns_fl, ns_long_fl | Absolute log ratio smaller than under v141LT in all four | PREREG18 S1 |
| E3 (C1) | Consecutive TOTVOL %RMSE, ns_c and ns_long_c | d_rmse = %RMSE(v141LT) minus %RMSE(v141LTfi) at or above -0.5 | E3, PREREG16 to 20 |
| E6b (C1) | First to last TOTVOL absolute bias, ns_fl and ns_long_fl | No worse than v141LT | E6b, PREREG16 to 20 |

Every v141LT reference is read, never typed in [F9]: C0 and C1 from PREREG16 `tables_r1`
(`~/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv`, md5 a3ed3b76), stems, basal area, QMD and
TOPHT from the PREREG17 Cardinal structure table (`gyr142-p17-cardinal-structure_DATA_2026-09-27.csv`, md5 732b553f); the
assembly checks both md5 values and stops on a mismatch. H2 first reproduces the PREREG11 H2 table (md5 a89bcfd5) for
v141LT and v141LTh to 1e-9 before any v141LTfi value is used, and carries a site cluster interval (B = 1,000, seed
20260928). Scorer `2026-09-27_v142_volconv_score.R` (md5 019df238), copied unedited from `~/jobs/v142p19/scripts`.

## Reported, not gated

- Each single component beside the pair, on the NS four and ns_c fold B: PREREG20 v141LTf (read from `~/jobs/v142p20/tables`)
  and the PREREG18 m* arm (PREREG17 Cardinal tables if m* is 1.5 or 2.0, PREREG18 firebreather tables if 1.75 or 2.25),
  read only after m* is fixed. Stems, basal area, QMD, TOPHT, C0, C1 with interval and C1 %RMSE, and the same gates applied
  to each component.
- Additivity: joint change from 14.1 against the sum of the two single changes, and the difference (interaction).
- The full H2 size class table for 14.1, PREREG11, PREREG20 and the pair.

## Decision rule, in order

Evaluated in order; exactly one outcome applies.

0. PREREG18 gives no m* or fails K1 at m*: PREREG22 does not launch; no result is written.
1. G0, CTL or K1 fails: harness failure, no verdict on the pair; repaired under a new revision.
2. Every gate passes: the PREREG20 height form with threshold matching at IMULT m* on NS is the 14.2 candidate NS
   configuration, a regional usage setting beside the NB and QC anchors, not adopted into a release before a Bakuzis NS grid
   under its own pre-registration. The PREREG18 verdict is reported beside it, unchanged. Maine and 14.1 are unchanged.
3. H2 fails: pairing with ingrowth undoes the large tree height fix; not adopted.
4. H1 fails with H2 passing: not adopted.
5. S1 fails: stems under the pair are not better than 14.1 on a named held out set; not adopted.
6. E3 fails: the pair costs consecutive accuracy; not adopted.
7. Only E6b fails: not adopted; the sign of each failing bias says which frame bounds IMULT (overshoot on ns_fl from above,
   deficit on ns_long_fl from below), and a flat NS scalar is not enough, as PREREG18 rule 2a anticipates.

Where several gates fail, the first applicable rule is the outcome and every failing gate is reported.

**Expectation, stated now.** Height gates are expected to pass as in PREREG20, since ingrowth trees are excluded from the
tag matched H2 set. E6b is expected to pass if m* is 1.5 or 2.0, because the height form moved C1 by under 0.1 points in
PREREG20; E3 on ns_long_c is the gate at risk if m* is 2.25.

## Caveats

Fold A and fold B share no sites, but ns_long_c and ns_long_fl share plots with ns_c, so only ns_c fold B is held out in the
strict sense. m* was chosen on ns_c fold A volume under 14.1 heights; it is not re-chosen under the new height form. If m*
is 1.5 or 2.0, the component arm ran on Cardinal (R 4.5.2) and the pair on firebreather (R 4.5.1); the cited PREREG17 G0 and
this G0 are what license the comparison. The Maine control tests the height part only; the ingrowth setting is NS only by
construction. The scorer's tables carry its fixed 2026-09-27 stamp.

## Constraints

New directories only (`~/jobs/v142p22/`). Frozen runs are read, not rerun. Cardinal is not touched. No coordinates are read
into or written to any output. L and T are not re-estimated. Nothing is sent outside.
