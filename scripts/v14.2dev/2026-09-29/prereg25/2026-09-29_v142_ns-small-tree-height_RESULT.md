# NS small tree height increment below 12.7 cm is a plot program effect, not a size effect: PREREG25 result

29 September 2026. Pre-registration: `2026-09-29_v142_ns-small-tree-height_PREREG25.md` (revision 1, md5 2f7f4a15,
in `prereg/` beside this file and in `~/jobs/v142p25/prereg/`). No engine arm was run. The confirmation script
`2026-09-29_v142_p25_confirm_rev2.R` read the PREREG20 tag matched survivor keys for all four NS sets and the frozen
v141LTf per tree predictions, reproduced the step 1 fold A table to 4.88e-15 and the PREREG20 H2 below 12.7 cm cells to
5.55e-16, then scored the three gates on fold B. Chain `chain_p25_rev2.sh`, CHAIN_DONE 29 September 08:12 server time.
L and T unchanged; GT1 stays a named failure. No em dashes.

## Verdict

**Rule 2: the diagnostic finding is confirmed on held out sites. No small tree size multiplier enters 14.2.** C1, C2 and
C3 pass on both ns_c and ns_long_c fold B. The deficit below 7.5 cm that PREREG20 left open belongs to the NS_RS plot
population, which v141LTf under predicts by about 40 percent at every size, and is observed below 9.1 cm only because
NS_RS is the one NS program that measures trees that small. 14.1 is unchanged.

| Gate, fold B | ns_c | ns_long_c | Pass |
|:--|:--|:--|:--:|
| C1 NS_RS deficit at all sizes (ratio below 0.80, upper limit below 1) | below 7.5: 0.507 (0.467 to 0.551); 7.5 to 12.7: 0.629 (0.591 to 0.677); 12.7 and over: 0.601 (0.564 to 0.636) | 0.543 (0.506 to 0.581); 0.659 (0.624 to 0.699); 0.652 (0.616 to 0.687) | Yes |
| C2 no small tree deficit in NS_OP (share below 7.5 cm under 0.01; 7.5 to 12.7 ratio at or above 0.95) | share 0.0000 of 18,100; ratio 1.121 | share 0.0000 of 22,501; ratio 1.195 | Yes |
| C3 no size gradient within NS_RS (abs difference below 0.20) | 0.094 | 0.109 | Yes |

## What the held out data show

The fold B pattern is the fold A pattern to the second decimal. NS_RS ratios on ns_c are 0.51, 0.63 and 0.60 by class
(fold A 0.51, 0.61, 0.60); NS_OP ratios are 1.12 and 1.09 (fold A 1.14 and 1.11). The same holds on the fl sets, reported
and not gated: ns_fl NS_RS 0.49, 0.63, 0.59 and ns_long_fl 0.51, 0.62, 0.61 on fold B, against NS_OP 1.11 to 1.29. NS_RS
observed annual height increment is 0.21 to 0.28 m per year in every class and set; predicted is 0.13 to 0.17. NS_OP
observed is 0.09 to 0.13 with predicted 0.12 to 0.15.

![NS_RS and NS_OP ratios by diameter class, fold A and fold B](assembled/gyr142-p25-program-class_2026-09-29.png)

**Figure 1.** Pooled predicted over observed annual height increment by t1 diameter class and plot program on ns_c and
ns_long_c, fold A (circles) and fold B (triangles), with 95 percent site cluster intervals (1,000 draws, seed 20260929).
NS_OP has no trees below 7.5 cm.

Two supporting tables. By species (30 trees or more, `confirm-rs-species`), every NS_RS group is under predicted on fold
B: balsam fir 0.45, black spruce 0.49, red spruce 0.79, white spruce 0.74, red pine 0.71, Norway spruce 0.34, tamarack
0.43 (ns_c); the only exception anywhere is white pine on ns_long_c (1.08 on 55 trees). Red spruce is the least under
predicted of the large groups in every set and fold, at 0.74 to 0.84. By t1 height class (`confirm-h1class`), NS_RS trees
below 1.8 m sit at 0.51 to 0.82, no worse than the 0.46 to 0.47 of the 1.8 to 3.5 m classes, so trees near breast height
are not the driver; the few dozen NS_OP trees below 3.5 m are mostly over predicted (1.05 to 2.3).

The rejected candidate, applied offline to fold B (`confirm-S1-offline`, c1 = 0.155378 from the fold A fit): it moves the
NS_RS below 7.5 cm ratio from 0.51 to 0.78 on ns_c (0.49 to 0.81 ns_fl, 0.54 to 0.87 ns_long_c, 0.51 to 0.89 ns_long_fl)
and leaves 7.5 cm and over untouched by construction. It would therefore have passed a naive below 7.5 cm gate while
leaving the same population 37 to 40 percent under predicted at 7.5 to 12.7 cm and at 12.7 cm and over. That is the
outcome the diagnosis predicted and the reason no engine arm was run.

## Side result, stated for the record

Pooled fold A classes mix the two programs, so PREREG20's H2 target and its 25 cm and over form were calibrated to that
mix. NS_OP alone runs 1.09 to 1.12 (ns_c) and 1.18 to 1.20 (ns_long_c) at 7.5 cm and over under v141LTf on fold B, which
is over prediction, while NS_RS is under predicted by 40 percent. Rule 2 names the next step: a pre-registration on what
distinguishes the NS_RS stands (stand age, density, treatment history; SRC_TST is UNKNOWN for all NS sets) and on whether
the PREREG20 form should be refit on NS_OP alone. Nothing here changes the PREREG20 verdict, which stands on E6b.

## Re-derivation [F9]

The confirmation script's own reproduction gates are the re-derivation for this track: before any fold B value was
computed it rebuilt the step 1 fold A program by class table (4.88e-15) and the eight PREREG20 H2 below 12.7 cm cells
(5.55e-16) from the keys and frozen predictions, and either failure would have stopped it with no verdict. The gate
values in the table above were read from `assembled/gyr142-p25-gates` and checked by hand against the
`confirm-program-class` rows this session. No separate re-derivation script was written because no new engine output
exists to re-derive; the arithmetic is a ratio of sums over a fixed key.

## Deviations

1. **Confirmation script revised once before any ratio was computed.** Revision 1 stopped on ns_long_c with a STAND
   prefix assertion (`^NS__NS_(RS|OP)_`) that did not accept the `NS_LONG__` prefix; revision 2 widens the pattern to
   `^NS(_LONG)?__NS_(RS|OP)_` and changes nothing else (`scripts/confirm_rev2_vs_rev1.diff`, `chain_rev2_vs_rev1.diff`).
   The failed run is kept in `logs/confirm_rev1_failed.txt` and `assembled_rev1_empty_failed/`.
2. **No engine arm, no retry, no G0.** The pre-registration's "Design changes from the brief" section states this; the
   PREREG20 bundle copy made before the diagnosis was removed unused.
3. **RESULT written from the assembly on firebreather.** The previous session's `p25/` folder did not reach the laptop;
   `assembled/` was downloaded again from `~/jobs/v142p25/assembled/` (seven files, md5 verified) and this RESULT was
   written from that copy.

## Files

`p25/assembled/` beside this file (gates, program by class, species, height class, S1 offline, verdict, Figure 1);
firebreather `~/jobs/v142p25/` holds `prereg/`, `scripts/` (diag, fit, confirm rev1 and rev2, both chains, diffs), `fit/`
(the five step 1 tables and the 1,000 draw bootstrap) and `logs/`. Scripts go to GitHub under
`scripts/v14.2dev/2026-09-29/prereg25/` on `v142-refinement-20260926`.
