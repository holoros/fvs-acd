# A flatter NS height increment correction for trees 25 cm and over: pre-registration 20

28 September 2026, revision 1. Written after the step 1 fit on ns_c fold A and before any gated run or score of the new
arm. It follows PREREG11 (`2026-09-26_v142_ns-height-growth_PREREG11.md`) and its RESULT, PREREG16 (C1 volume convention)
and PREREG17. L and T stay at run 14868899. GT1 stays a named failure. No em dashes.

## Why

PREREG11 multiplied predicted NS height increment by m(D) = exp(-b (D - 12.7)+), b = 0.0309. It fixed TOPHT bias but failed
H2: on ns_c fold B trees 25 cm and over, the ratio of predicted to observed annual height increment went from 1.25 under
14.1 to 0.70, an overcorrection. The step 1 diagnosis (ns_c fold A tag matched survivors, 47,865 trees on 1,130 sites;
`fit/gyr142-p20-diag-dbhclass-foldA_DATA_2026-09-28.csv`) shows why. The multiplier the data ask for (observed over 14.1
predicted) falls smoothly from about 0.88 at 13.6 cm to 0.75 at 23.6 cm, then stays roughly flat at 0.56 to 0.68 from 26 to
44 cm; only the class above 45 cm (160 trees) drops to 0.39. ns_long_c fold A shows the same shape. A single exponential is
too weak just above 12.7 cm and too steep beyond 30 cm.

## Form and fitted parameters (fold A only, fixed now)

m(D) = exp( -b1 (min(D, 25) - 12.7)+ - b2 (D - 25)+ ), with 0 <= b2 <= b1, D in cm at the start of the growth step,
applied to NS stands only through `dht.mult` (identity in the frozen configuration), exactly where PREREG11 applied its
form. m is continuous at 25 cm, equals 1 at and below 12.7 cm, is bounded in (0, 1] and declines monotonically, so
height increment stays non negative and decreases smoothly with size.

Fitted by least squares on ns_c fold A (fold A: first hex digit of md5(SITE) even), 1,000 draw site cluster bootstrap
(`fit/gyr142-p20-fit-params_DATA_2026-09-28.csv`):

| Form | b1 (95% interval) | b2 (95% interval) | SSE |
|:--|:--:|:--:|:--:|
| **Two segment (adopted for the arm)** | **0.03442 (0.02623 to 0.04269)** | **0.00507 (0.00000 to 0.02148)** | 2444.93 |
| Plateau (b2 = 0) | 0.03531 (0.02755 to 0.04386) | 0 | 2444.99 |
| Single (PREREG11 form, refit) | 0.02962 (0.02269 to 0.03753) | = b1 | 2445.91 |

The arm uses b1 = 0.034416 and b2 = 0.005072 (`fit/p20_params.env`). The two segment and plateau fits are nearly
identical; the two segment form was named as the planned form before the fit and is kept. In 21 percent of bootstrap draws
b2 reached 0 and in 1 percent it reached b1, so the plateau is inside the uncertainty and the single form almost never
is. Implied m: 0.66 at 25 cm, 0.64 at 30 cm, 0.61 at 40 cm, 0.58 at 50 cm (PREREG11, b = 0.0309: 0.59, 0.50, 0.37, 0.27 at 30,
35, 45 and 55 cm). In sample on fold A, the 25 cm and over ratio moves from 1.58 (14.1) to 1.01.

**Pre flight.** Form: a two segment log linear multiplier with a hinge, the least parameterized form that matches the
class pattern. Extrapolation: fold A holds trees to 97 cm, but the 99th percentile is 37.8 cm and only 349 trees exceed
40 cm, so the b2 segment beyond 40 cm is weakly identified; it is bounded by b2 <= b1 and cannot fall faster than PREREG11.
Uncertainty: bootstrap intervals above; the verdict is judged on held out data. Realism: m is continuous, monotone and
positive. Known limit: fold A shows a near step at 25 cm (0.75 to 0.60) that a continuous form can only average.
Separately, trees below 7.5 cm are under predicted by about half; that is out of scope and left open.

## Arms and harness

| Column | What | Sets | Rows |
|:--|:--|:--|:--|
| g0_off | Runner copy, correction switched off, v141LT environment | ns_c | admitted rows 1 to 100 (chunk 1) |
| ctl_memat | Correction on, arm parameters | memat_c | admitted rows 1003 to 1152 (chunk 2) |
| v141LTf | Correction on, arm parameters | NS four | the 36 bench141 chunks used by PREREG17 |

Base: v141LT, 14.1 as shipped, IMULT at the bench141 value and no ingrowth threshold matching. This keeps the result
independent of the NS ingrowth track (PREREG18). Bundle `~/jobs/v142p20/home`, a copy of the validated PREREG17 bundle with
the memat_c frames and TST file added. Runner `runner_p20_fb.R` (md5 65392afb) is the frozen `runner_htfix_fb.R`
(4e6a2997, unedited) with lines 410 to 419 replaced (diff `runner_p20_vs_htfix.diff`, md5 2304fa3b); it refuses the PREREG11
switch `HTFIX_B` and requires 0 <= HTFIX_B2 <= HTFIX_B1. At most 4 tasks at once, and none starts while the 1 minute load is
above 14. Wall time is not a result.

**Retry rule, up front.** The runner caps a stand at 60 s. Every stand whose FAIL_REASON is the time limit is rerun alone,
selected by stand name through `STAND_KEEP_FILE` (never by pairs row), up to three attempts; the driver checks that the stand
returned is the stand requested. Retried stands replace the originals in place. K1 counts failures after retry.

## Gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | g0_off against frozen Cardinal v141LT ns_c chunk 1, every predicted column and RUN_OK | Worst scaled difference at or below 1e-9 | PREREG11 and PREREG17 G0 |
| CTL | ctl_memat against frozen Cardinal v141LT memat_c chunk 2 | At or below 1e-9 (the correction must not touch Maine) | Construction |
| K1 | RUN_OK other than 1, v141LTf, NS four, after retry | 0 | H2 |
| H1 | TOPHT absolute bias, v141LTf against v141LT | Smaller on all four NS sets | PREREG11 H1 |
| H2 | Annual height increment ratio, trees 25 cm and over, fold B, ns_c and ns_long_c | Absolute deviation from 1 smaller than both 14.1 and PREREG11 v141LTh | PREREG11 H2 |
| E3 (C1) | Consecutive TOTVOL %RMSE, ns_c and ns_long_c | d_rmse = %RMSE(v141LT) minus %RMSE(v141LTf) at or above -0.5 | E3, PREREG16, PREREG17 |
| E6b (C1) | First to last TOTVOL absolute bias, ns_fl and ns_long_fl | No worse than v141LT | E6b, PREREG16, PREREG17 |

H2 reproduces the PREREG11 H2 table (Cardinal `recs/htfix/score/h2/gyr142-htfix-h2h3_DATA_2026-09-26.csv`, md5 a89bcfd5)
for v141LT and v141LTh to 1e-9 before any v141LTf value is read; a failure stops the script. Every v141LT reference is
read from PREREG16 `tables_r1` and the PREREG17 Cardinal structure table, never typed in. H2 carries a site cluster
bootstrap interval (B = 1,000, seed 20260928), reported beside the gate.

## Reported, not gated

The full size class table (below 12.7, 12.7 to 25, 25 and over) by set and fold; C0 beside C1; basal area, QMD and stems;
the memat_c control output. Expectation, stated now: because C1 removes height from volume, E3 and E6b register only the
indirect effect of height on diameter growth and mortality, and are expected to move little from v141LT.

## Decision rule, in order

1. G0, CTL or K1 fails: harness failure, no verdict on the form; repaired under a new revision.
2. Every gate passes: the two segment form is the candidate 14.2 NS height calibration, not adopted into a release before
   a Bakuzis NS grid under its own pre-registration. 14.1 is unchanged.
3. H2 fails: the form is still wrong for large trees; not adopted.
4. H1 fails with H2 passing: not adopted.
5. E3 fails: not adopted.
6. Height gates pass and E6b fails: the height form is right but the long frame volume is still carried by the stem deficit
   (PREREG17); not adopted alone, and the next step pairs it with the ingrowth setting that PREREG18 selects.

## Caveats

Fold A and fold B share no sites, but ns_long_c shares plots with ns_c, so only ns_c fold B is held out in the strict
sense. Fold B large trees differ from fold A (14.1 ratio 1.25 against 1.58), so a fold A fit can overshoot on fold B; that
is exactly what H2 tests. The step 1 key was extracted on the Cardinal login node, a read of frozen outputs into a new
directory `recs/p20/key/`.

## Constraints

New directories only (`~/jobs/v142p20/`, Cardinal `recs/p20/`). Frozen runs are read, not rerun. No coordinates. Nothing is
sent outside.
