# NS small tree height increment below 12.7 cm is a plot program effect, not a size effect: pre-registration 25

29 September 2026, revision 1. Written after the step 1 diagnosis and fit on ns_c fold A (ns_long_c fold A as a shape
check) and before any fold B or fl set small tree ratio was read. It follows PREREG20
(`2026-09-28_v142_ns-height-form-25cm_PREREG20.md`, md5 ea5e37cd) and its RESULT (rule 6, not adopted alone). L and T stay
at run 14868899. GT1 stays a named failure. No em dashes.

## Why

The PREREG20 step 1 diagnosis noted that trees below 7.5 cm are under predicted by about half, and PREREG20 left that open.
The brief for this track was to fit a small tree segment, for example m(D) = exp(c1 (7.5 - D)+), equal to 1 at and above
12.7 cm, and to gate it in an engine arm v141LTfs. The same brief said that if the pattern is not a stable size effect, the
diagnostic finding is pre-registered instead of a form. The diagnosis shows it is not a size effect, so this document
pre-registers the finding and a held out confirmation of it, and no engine arm is run.

## Step 1 diagnosis (fold A only, fixed now)

Data: the PREREG20 tag matched survivor key (`p20_htkey_<set>.csv`, md5 98fb8b7e for ns_c) joined to the frozen PREREG20
v141LTf per tree t2 predictions (no retries existed). Ratio is pooled predicted over observed annual height increment, the
PREREG20 H2 definition, with a 1,000 draw site cluster bootstrap (seed 20260929). Scripts `2026-09-29_v142_p25_diag.R`
(md5 cd286367) and `2026-09-29_v142_p25_fit.R` (35845e31); tables in `fit/`.

**The size pattern is a program boundary.** On ns_c fold A (47,865 trees, 1,130 sites) the ratio is 0.45 to 0.53 in every
2.5 cm class below 7.5 cm, then jumps to 0.94 at 7.5 to 10 cm and 1.09 at 10 to 12.7 cm. In 1 cm classes the jump sits
between 8 to 9 cm (0.60) and 9 to 10 cm (1.01), where tree counts rise twelvefold. Every one of the 2,020 fold A trees below
7.5 cm is on an NS_RS plot (STAND prefix); the smallest NS_OP tree is 9.1 cm, the operational PSP minimum. Split by program:

| Program, ns_c fold A | below 7.5 cm | 7.5 to 12.7 cm | 12.7 cm and over |
|:--|:--:|:--:|:--:|
| NS_RS (7,198 trees, 300 sites) | 0.51 | 0.61 | 0.60 |
| NS_OP | no trees | 1.14 | 1.06 to 1.16 by class |

NS_RS trees are under predicted by about 40 percent at every size, including 25 cm and over (0.51, interval 0.43 to 0.66).
Their observed increment is 0.18 to 0.26 m per year against 0.09 to 0.14 for NS_OP trees of the same diameter, while
predicted increments are nearly equal. ns_long_c fold A has the same shape (NS_RS 0.53, 0.63, 0.63; NS_OP 7.5 to 12.7 cm
1.19).

**A size form cannot represent this.** Least squares on the v141LTf increment, ns_c fold A (`fit/gyr142-p25-fit-params`,
`-sse`, `-insample`):

| Form | Parameters (95% interval) | SSE |
|:--|:--|:--:|
| S0 identity (v141LTf) | none | 2444.68 |
| S1 size only, exp(c1 (7.5 - D)+) | c1 0.155 (0.125 to 0.184) | 2421.92 |
| S1b two knot, adds c2 (12.7 - max(D, 7.5))+ | c1 0.131 (0.096 to 0.169), c2 0.023 (0.002 to 0.042) | 2420.41 |
| S2 program only, exp(a RS) | a 0.526 (0.463 to 0.590), m 1.69 | 2377.96 |
| S3 program plus size | a 0.488 (0.427 to 0.554), c1 0.047 (0.011 to 0.084) | 2375.52 |

One program term removes three times the error that the size segment removes (66.7 against 22.8). Adding the size segment
to the program term gains 2.4 more. S1 in sample overshoots the smallest class (1.11 below 2.5 cm), leaves 5 to 7.5 cm at
0.64 and leaves NS_RS trees at 7.5 to 12.7 cm at 0.61, because the form must return to 1 at the knot while the NS_RS
deficit does not. A two knot form that pushes m above 1 up to 12.7 cm worsens NS_OP trees, which are already over predicted
there (7.5 to 10 cm rises from 1.07 to 1.15 and 10 to 12.7 cm from 1.17 to 1.21 under S1b). Within NS_RS a residual
gradient remains: S3 c1 is 0.047 per cm with an interval that excludes 0, worth up to 0.36 on the log scale at the smallest
sizes against 0.49 for the program term, but it lowers SSE by only 2.4 and it exists only inside one program.

**Pre flight.**

- Biology. An increase for small trees would be defensible for suppressed understory trees only if they were the ones
  under predicted. They are not: the NS_RS small trees grow faster than NS_OP trees of any size, which reads as vigorous
  young or treated stands, not suppression. No suppressed understory trees below 9.1 cm are measured in NS_OP at all.
- Extrapolation domain. Below 9.1 cm every observation comes from one plot program. A size multiplier fitted here would
  carry an NS_RS stand condition into every small NS tree the engine projects, including ingrowth and understory trees in
  operational stands, where there are no data to check it.
- Measurement error. Heights are recorded to 0.1 m in both programs. NS_RS measurement looks cleaner, not noisier: 2
  percent of its trees carry whole metre heights at both ends against 27 percent for NS_OP, and negative increments are
  below 1 percent against about 4 to 7 percent. Rounding is symmetric and does not bias a ratio of means. Trees near breast
  height are not the driver: NS_RS trees with t1 height below 1.8 m (74 trees) sit at 0.65, better than the class average.
  Survivor selection is not the driver either, since the deficit is as large at 15 to 25 cm, where mortality is low.
- Species. Every NS_RS species group below 7.5 cm is under predicted (balsam fir 0.41, spruce 0.64, other conifer 0.49,
  other hardwood 0.31; birch has 3 trees), so no single group carries the pattern.

**Finding.** The below 7.5 cm deficit is the NS_RS plot population, under predicted at all sizes, observed through the only
program that measures small trees. It is not a stable size effect, and no size segment is proposed. A side result for the
record: pooled fold A classes mix the two programs, so PREREG20 was calibrated to that mix; NS_OP alone runs 1.06 to 1.16 at
12.7 cm and over under v141LTf.

## Confirmation on held out data

No engine run. Script `2026-09-29_v142_p25_confirm.R` reads the PREREG20 key for all four NS sets and the frozen v141LTf
per tree predictions, only after this file's md5 is passed to it. It first reproduces, to 1e-9, the step 1 fold A program by
class table and the PREREG20 H2 below 12.7 cm cells (8 cells, all sets and folds); either failure stops it with no verdict.
Classes at t1: below 7.5, 7.5 to 12.7, 12.7 cm and over. Site cluster bootstrap within set, fold, program and class,
B = 1,000, seed 20260929.

| Gate | Test on fold B, ns_c and ns_long_c each | Threshold |
|:--|:--|:--|
| C1 NS_RS deficit at all sizes | NS_RS ratio in each of the three classes | Below 0.80, and the upper 95% limit below 1 |
| C2 no small tree deficit in NS_OP | Share of NS_OP trees below 12.7 cm that are below 7.5 cm; NS_OP 7.5 to 12.7 cm ratio | Share below 0.01; ratio at or above 0.95 |
| C3 no size gradient within NS_RS | abs(ratio below 7.5 minus ratio 12.7 and over), NS_RS | Below 0.20 |

Only ns_c fold B is held out in the strict sense; ns_long_c shares plots with ns_c. Reported, not gated: the same table for
fold A and for ns_fl and ns_long_fl; NS_RS ratio by species (30 trees or more); ratio by t1 height class; and the fold A S1
form (c1 = 0.155378) applied offline to fold B, pooled and by program, to show what the rejected candidate would have done.

## Decision rule, in order

1. A reproduction check fails: harness failure, no verdict; repaired under a new revision.
2. C1, C2 and C3 pass: the finding is confirmed. No small tree size multiplier enters 14.2. The next step is a new
   pre-registration on what distinguishes NS_RS stands (stand age, density, treatment history; SRC_TST is UNKNOWN for all NS
   sets), and on whether the PREREG20 form should be refit on NS_OP alone.
3. C1 and C2 pass, C3 fails: the program deficit is confirmed and a size gradient within NS_RS remains; a size term is
   considered only jointly with a program or stand state term, under a new pre-registration.
4. C1 fails: the NS_RS deficit does not hold on held out sites; the fold A pattern is not stable; nothing is adopted.
5. C2 fails: the size question is reopened on NS_OP data.

14.1 is unchanged under every outcome.

## Design changes from the brief

The arm v141LTfs and its gates (G0s zero parameter reproduction on ns_c chunk 1, Maine control, K1, H1, H2, H3, E3, E6b)
are not run, because there is no form to gate. The retry rule (by STAND name, up to three attempts, never by pairs row) has
nothing to act on. The PREREG20 bundle copy made on firebreather before the diagnosis was finished was removed unused.

## Constraints

New directories only (`~/jobs/v142p25/`). Frozen runs are read, not rerun. No coordinates; SITE appears only as an integer
index and a fold. Nothing is sent outside.
