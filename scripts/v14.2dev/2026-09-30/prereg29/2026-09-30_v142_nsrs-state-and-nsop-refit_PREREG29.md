# What distinguishes NS_RS stands, and the PREREG20 height form refit on NS_OP alone: pre-registration 29

30 September 2026, revision 1. Written after the step 1 description and the NS_OP refit on fold A and before any fold B
tree, ratio or stand state was read. It follows PREREG25 (`~/jobs/v142p25/prereg/`, rule 2: the NS_RS deficit is a plot
program effect). L and T stay at run 14868899 and are not re-estimated. GT1 stays a named failure. No engine run is made
under this document. No em dashes.

## Step 1 diagnosis (fold A only, fixed now)

Data: NS frames (v142p22 copy), the PREREG20 tag matched survivor key (md5 98fb8b7e for ns_c), frozen v141LTf per tree
predictions and results; fold B stands dropped on read. Ratio is predicted over observed annual height increment. Site
cluster bootstrap B = 1,000 (seed 20260930; the refit keeps the PREREG20 seed). Scripts `scripts/2026-09-30_v142_p29_step1.R` (rev2) and `_step1b.R`; tables in `step1/`,
`step1b/`. The PREREG25 fold A program by class table reproduces to 4.9e-15 over 30 cells, and the pooled PREREG20 fit
reproduces to 6.9e-18 (point) and 5.2e-17 (bootstrap limits).

**Fields.** The pairs file has 43 columns. None carries stand age. Treatment is carried only by MANAGED (set by the rule
`ns_programme_RS1_OP0`, so it is the program itself), MANAGED_OLDFLAG (1 on every non missing NS_RS stand; 1 on 385 of
1,602 NS_OP stands in ns_c), TRT_AT_Y1 (0 everywhere), NSL_SINGLE_REGIME (0 on 106 of 819 NS_RS stands, never on NS_OP)
and the churn flags. SRC_TST is absent. The results carry BA, SDI, QMD and top height at t1 and esi8, but no relative
density; SDI is used.

**Program contrast, ns_c fold A (870 NS_RS and 1,912 NS_OP stands, medians).** NS_RS stands are denser and smaller:
1,765 against 800 trees per ha counting every measured tree, QMD 12.7 against 16.6 cm, SDI 568 against 444,
BA 21.6 against 19.2 m2 per ha; top height is equal (13.0 against 12.8 m). Their plots are 100 to 455 m2 (median 202)
against a fixed 400 m2, the frame diameter floor is 0.2 to 11.7 cm against 9.1 cm observed, and heights are measured on 38
percent of t1 trees against all of them. Composition is bimodal (softwood BA share quartiles 0, 0.995, 1.0) with sugar
maple at 19 percent of BA against 4 percent. ESI comes from the old harness for every NS_RS stand (median 13.7 m, 10th to
90th percentile 6.8 to 18.6) and from the 30 m layer for most NS_OP stands (17.7 m, 16.6 to 18.7). Median Y1 is 1989
against 1983; intervals are 5 years. ns_long_c has the same contrasts.

**Within NS_RS, the ratio rises with stand development.** ns_c, stand level quartiles (Q1 to Q4, 95% interval of Q4
minus Q1): BA 0.42, 0.57, 0.66, 0.79 (0.28 to 0.45); SDI 0.42 to 0.79; top height 0.44, 0.57, 0.73, 0.71; trees 9.1 cm
and over per ha 0.43 to 0.76; QMD 0.45 to 0.67; ESI 0.51, 0.49, 0.72, 0.69. Year, interval and fir share are flat. ns_long_c repeats it (BA 0.45 to 0.80, top height 0.45 to 0.79), and the gradient holds on NS_RS trees of
9.1 cm and over (BA 0.49 to 0.75). NS_OP has a weaker gradient in ns_c (BA 1.08 to 1.25, top height 0.97 to 1.30) and no monotone
one in ns_long_c (1.11 to 1.36, every Q4 minus Q1 interval spans 0). The best NS_RS quartile of any listed variable is 0.80.

**Overlap.** 40 percent of NS_RS stands have QMD below the NS_OP 2.5th percentile and 43 percent have more trees per ha
than the NS_OP 97.5th percentile: NS_RS does sample young dense stands that NS_OP never samples, partly because NS_OP
does not measure below 9.1 cm. On trees of 9.1 cm and over the state spaces do overlap: every NS_RS tree in ns_c falls in
a coarsened cell (tertiles of QMD and trees per ha at the 9.1 cm floor, top height and ESI, by size class) that also holds
NS_OP trees. At matched state NS_RS is 0.61 (0.58 to 0.65) and NS_OP 1.04 (0.86 to 1.25), a difference of -0.43 (-0.64 to
-0.25); matching on BA and top height quintiles gives -0.41 (-0.57 to -0.29); without ESI -0.44. ns_long_c: -0.57, -0.62
and -0.53.

**ESI is not the driver, and the frames disagree.** For all 788 NS_RS sites present in both sets, the old harness ESI in
ns_long_c is exactly 7.0 m higher than in ns_c (correlation 1; the same holds for NS_OP old harness sites). A 7 m higher
ESI moves the NS_RS ratio only from 0.61 to 0.64. This is a frame defect reported for repair; it is not acted on here.

**Finding.** A development gradient exists inside NS_RS, but no production state variable removes the deficit and the
matched program offset is -0.41 to -0.62. The step 2(b) condition (a state variable that explains the deficit and is not
confounded with program) is not met. What separates the programs lies outside the production state vector (plot size,
diameter floor, height subsampling, composition, a treatment flag set on every NS_RS stand), so (b) is pre-registered as
a held out check of this negative finding.

**NS_OP refit (step 2(a)).** Same form, same sufficient statistic least squares on the v141LT increment, same bootstrap,
ns_c fold A NS_OP only (40,667 trees, 830 sites): b1 0.048863 (0.038549 to 0.060079), b2 0 (0 to 0.010429; 77 percent of
draws at 0), SSE 2160.00 against 2202.10 for the identity. Pooled PREREG20: b1 0.034416 (0.026235 to 0.042693), b2
0.005072. The multiplier is 0.700 at 20 cm and 0.548 from 25 cm on (pooled 0.778, 0.655, 0.607 at 40 cm). In sample, NS_OP 12.7 to 25 cm moves from 1.137 (pooled, offline) to 1.076 and 25 cm and over from 1.103
to 0.952; NS_RS moves from 0.625 to 0.588 and 0.512 to 0.436. The form cannot touch NS_OP 7.5 to 12.7 cm (1.144), which is
below the knot. An NS_RS only fit sits at b1 = b2 = 0 (reported only).

## Held out gates

Script `scripts/2026-09-30_v142_p29_confirm.R` runs only when this file's md5 is passed to it. It reproduces, to 1e-9,
the PREREG25 fold A program by class table, the PREREG20 H2 below 12.7 cm cells (8) and the step 1 in sample refit table,
and stops with no verdict on any failure. b1 and b2 are read from their fit files with md5 (F9). Both forms are applied
offline to the frozen v141LT increments, the way PREREG25 applied S1. Classes at t1: below 7.5, 7.5 to 12.7, 12.7 to 25,
25 and over, and 12.7 and over. Bootstrap by set, fold, program and class.

**(a) Materiality**, fixed now: M1, NS_OP b1 or b2 outside the pooled 95% interval (fold A; met, b1 0.0489 against an
upper limit of 0.0427); M2, on ns_c fold B the NS_OP ratio at 12.7 to 25 or 25 and over moves by more than 0.05. Material
if M1 or M2.

| Gate, fold B | Test | Threshold |
|:--|:--|:--|
| A1 | NS_OP, ns_c and ns_long_c, 12.7 to 25 and 25 and over | Refit closer to 1 than pooled, and within 0.90 to 1.10 |
| A2 | All programs, ns_c and ns_long_c, 12.7 and over | abs(refit - 1) at most abs(pooled - 1) + 0.02 |
| A3 | NS_OP, ns_fl and ns_long_fl, 12.7 and over | abs(refit - 1) at most abs(pooled - 1) + 0.02 |

Reported, not gated: NS_RS by class, fold A, the engine adjusted version (refit over pooled times the v141LTf increment).

**(b) Negative finding.** Fold B stand state is computed the same way; cut points are the fold B tertiles and quintiles.

| Gate, fold B, ns_c and ns_long_c | Test | Threshold |
|:--|:--|:--|
| B1 program offset at matched state | NS_RS minus NS_OP, both step 1b matchings | Below -0.25, upper 95% limit below 0 |
| B2 no state removes the deficit | NS_RS by quartile of BA, SDI, top height, QMD, trees 9.1 cm and over, ESI | Every quartile below 0.90, upper limit below 1 |

## Decision rule, in order

1. A reproduction check fails: harness failure, no verdict.
2. (a) not material (M1 and M2 false): the pooled PREREG20 form stays. Material and A1 to A3 pass: (a) pass; the next step
   is a pre-registered, not launched, engine arm v141LTfo (NS_OP b1, b2 in place of the pooled values, IMULT 1.5 as in
   PREREG22), with the PREREG22 gate set. Material and any of A1 to A3 fails: (a) fail; the pooled form stays.
3. (b) B1 and B2 pass: not material; no stand state term; the deficit stays a program effect, and the NS_RS population is
   named as outside the 14.2 NS height calibration. B1 fails: the negative finding fails; a state term is reopened under a
   new pre-registration. B1 passes, B2 fails: partial; a state term is considered only jointly with a program term.

14.1 is unchanged under every outcome.

## Constraints and deviations

New directory only. v141LT NS results are not on firebreather; t1 state comes from the v141LTf results (same inputs).
Step 1 rev0 and rev1 stopped partway (a column type; an empty bootstrap cell) and are kept as `step1_rev0_failed` and
`step1_rev1_failed`. Only ns_c fold B is held out in the strict sense; ns_long_c shares plots with ns_c. No coordinates.
Nothing is sent outside.
