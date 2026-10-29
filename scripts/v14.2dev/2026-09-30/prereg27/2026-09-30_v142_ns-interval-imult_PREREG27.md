# The NS long interval stem deficit is survivor loss, not ingrowth: pre-registration 27

30 September 2026, revision 1. Written after the step 1 diagnosis on fold A of all four NS sets and before any fold B
survivor or recruit value was read. It follows PREREG18 (closed on rule 2a, m* = 1.5 at the lower edge) and PREREG22 (the
14.2 candidate `v141LTfi`: PREREG20 height form, threshold matching, IMULT 1.5). L and T stay at run 14868899 and are not
re-estimated. GT1 stays a named failure. No em dashes.

## Why

PREREG18 rule 2a named the next step as "an interval length dependent term (ingrowth or survival over long intervals), not
a flat scalar". The brief for this track was to fit IMULT(iv) on fold A and gate it as an arm `v141LTfiv`, and, if the
diagnosis said survival rather than ingrowth, to pre-register the finding and its held out confirmation instead (the
PREREG25 pattern). The diagnosis says survival. This document pre-registers that finding and its confirmation; no engine
arm is run.

## Step 1 diagnosis (fold A only, fixed now)

Frozen inputs only: per stand C1 volume at IMULT 1.0, 1.5, 2.0, 2.5 (PREREG17 Cardinal), 1.75, 2.25 (PREREG18) and 3.0
(PREREG17 firebreather); per stand stems (BA over the QMD tree basal area, PREREG9 J2) for 1.75, 2.25, 3.0 and v141LTfi;
per tree runner lists of the same arms. Interval classes: 5 years or less, 6 to 10, 11 to 15, 16 to 20, 21 to 30, 31 to 60
(the NS intervals are almost all multiples of 5). Scripts `2026-09-30_v142_p27_diag.R`, `_decomp.R`, `_diag2.R` and
`p27_lib.R`; tables in `fit/`.

**(a) The optima do not rise with interval inside a frame.** The pooled stems ratio is linear in IMULT (the fold A line
through 1.75, 2.25, 3.0 reproduces the Cardinal ns_c fold A values at 1.0 to 2.5 within 0.0012). IMULT setting stems to 1,
by class: ns_c 2.46 (5 yr), 1.59 (6 to 10), 1.81 (11 to 15), 1.65 (16 to 20); ns_long_c 2.78, 1.95, 1.67, 1.47, 2.23. The
C1 volume optimum inside ns_c is 1.72 at 5 years and below the grid at every longer class, where C1 is already over at
IMULT 1.0 (1.04, 1.08, 1.18, 1.36); ns_long_c is the same (1.01 to 1.29 at IMULT 1.0 beyond 5 years). In the first to last
frames the stems optimum is 2.3 to 3.1 in every class and volume is under at 10 to 20 years (ns_long_fl C1 0.79 to 0.86 at
IMULT 3.0) and over beyond 30 years. A power law IMULT(iv) = m5 (iv / 5)^g fitted to any of this would need g below 0 on
the consecutive frames and above 0 on the first to last frames; one sign cannot serve both.

**(b) Survivors carry the long interval deficit.** Stems at the score threshold split into survivors (a t1 tree at or above
the threshold alive at t2, tag matched by STAND, PLOT, TREE for the observed side) and recruits (all else at t2). The split
reproduces the results file stems exactly (ratio 1.000 on every arm and set) and the t1 stems to 4e-15. Under v141LTfi,
survivor ratio (predicted over observed) by class, site cluster 95 percent interval:

| Set, fold A | 5 yr | 6 to 10 | 11 to 15 | 16 to 20 | 21 to 30 | 31 to 60 |
|:--|:--:|:--:|:--:|:--:|:--:|:--:|
| ns_c | 1.031 (1.016, 1.048) | 0.997 | 0.918 | 0.874 (0.830, 0.929) | 0.790 | |
| ns_long_c | 1.020 (1.008, 1.033) | 0.950 | 0.938 | 0.924 | 0.833 (0.791, 0.890) | 0.835 |
| ns_fl | | 1.001 | 0.985 | 0.916 | 0.840 (0.811, 0.873) | 0.711 |
| ns_long_fl | | 1.105 | 0.984 | 0.938 | 0.839 | 0.758 (0.740, 0.778) |

Predicted annual survival is flat at 0.987 to 0.990 in every class; observed annual survival rises from 0.981 to 0.983 at
5 years to 0.995 to 0.998 beyond 20. The survivor ratio moves by 0.002 or less across IMULT 1.75, 2.25 and 3.0, so no
ingrowth setting touches it. Recruits go the other way inside the consecutive frames: ratio 0.61 to 0.62 at 5 years, 1.10 to
1.37 at 11 to 20 years, up to 3 at 21 to 30. Beyond 20 years the survivor term is minus 10 to 21 percent of observed
stems in every set while the recruit term is minus 4 to plus 54 percent.

**(c) Interval length, not frame or stand state.** The survivor gradient holds inside ns_c and inside ns_long_c, in both
programs (NS_OP ns_c 0.998, 0.962, 0.925, 0.874, 0.790), within the same plots (plots with both a 5 year and a longer
interval: ns_c 0.999, 0.971, 0.860 for 5, 6 to 15, 16 to 60 years; ns_long_c 0.985, 0.944, 0.886), and in every t1 QMD and
t1 stems tercile (16 to 60 years 0.77 to 0.97). The short interval recruit deficit is a program effect: NS_RS recruit ratio
0.45 (ns_c) and 0.52 (ns_long_c) at 5 years against 0.97 and 0.98 for NS_OP, the plot population PREREG25 already isolated.

**Finding.** The long interval stem deficit is survivor loss that grows with interval length at a flat predicted annual
survival, and recruits are over, not under, predicted at long consecutive intervals. An interval dependent ingrowth
multiplier would add stems where recruits are already high, and would move C1 volume further over on the consecutive
frames. No ingrowth arm is proposed. The flat NS IMULT 1.5 of v141LTfi is left as it is.

## Confirmation on held out data

No engine run. Script `2026-09-30_v142_p27_confirm.R` reads the fold B stands of all four NS sets under v141LTfi (PREREG22,
frozen) through `p27_lib.R`, only after this file's md5 is passed to it (`P27_PREREG_MD5`). It first recomputes the fold A
survivor and recruit table (`fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv`, every survivor and recruit ratio) and
reproduces it to 1e-9; a failure stops it with no verdict. Intervals: site cluster bootstrap within set and class, B = 1,000,
seed 20260930. Classes pooled for the gates: 5 years or less; 16 to 60 years (consecutive sets); 21 to 60 years (first to
last sets). The thresholds below are fixed here; the script carries them as constants and runs only on this md5.

| Gate | Test on fold B | Threshold |
|:--|:--|:--|
| D1 long interval survivor deficit | Survivor ratio at 16 to 60 years, ns_c and ns_long_c each | Below 0.93 and upper 95% limit below 1 |
| D2 none at short intervals | Survivor ratio at 5 years, ns_c and ns_long_c each | At or above 0.98 |
| D3 survivors carry it | At 16 to 60 years, survivor term and recruit term as percent of observed stems, ns_c and ns_long_c each | Survivor term below -3 and below the recruit term |
| D4 within plot | Plots with both a 5 year and a 16 to 60 year interval: survivor ratio at 16 to 60 minus at 5 years, ns_c and ns_long_c each | Below -0.05 |
| D5 first to last frames | Survivor ratio at 21 to 60 years, ns_fl and ns_long_fl each | Below 0.90 and upper 95% limit below 1 |

Only ns_c fold B is held out in the strict sense; ns_long_c and the fl sets share plots with ns_c. Reported, not gated: the
full fold B table by class and program; annual observed and predicted survival; recruit ratio at 5 years by program (the
NS_RS contrast); the same table under IMULT 1.75 on ns_c fold B, to show survivors do not move with IMULT.

## Decision rule, in order

1. The reproduction check fails: harness failure, no verdict; repaired under a new revision.
2. D1 to D5 pass: the finding is confirmed. No interval dependent ingrowth term enters 14.2, and v141LTfi keeps flat IMULT
   1.5. The survival component is named for a later track: the NS survivor mortality of the linked three stage model
   (14.1 L) accumulates at a constant annual rate over multi year steps, 0.988 to 0.989, while observed survival of
   remeasured trees rises with interval length to 0.995 or more. Whether that is a model rate that is too high for the
   stands measured at long intervals, or a remeasurement convention in the long interval NS records, is the question for
   that track; L and T are not refit here.
3. D1 and D3 pass, D2 or D4 fails: the long interval survivor deficit is confirmed, but its interval dependence is not
   separated from plot or stand state; the later track starts from stand state, not interval.
4. D1 or D3 fails: the fold A pattern does not hold on held out sites; nothing is concluded and nothing is adopted.
5. Only D5 fails: confirmed on the consecutive frames only; the first to last frames are reported as a separate question.

Where several gates fail the first applicable rule is the outcome and every failing gate is reported. 14.1 and the 14.2
candidate are unchanged under every outcome.

## Design changes from the brief

The arm v141LTfiv, its taskmap by interval class, the chain `chain_p27.sh` with retries, and the gates K1, S1, E3, E6b, VB and
H1 are not run, because there is no ingrowth form to gate: the diagnosis points the deficit at survival, which the brief
says to confirm, not to fit. The retry rule has nothing to act on. No bundle copy was made.

## Constraints

New directory only (`~/jobs/v142p27/`). Frozen runs are read, not rerun. No coordinates; SITE is used only as an integer
index and a fold. Nothing is sent outside.
