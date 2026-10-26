# Absolute Bakuzis gates for QC on the measured stand list grid, for 14.3: PREREG47 result (reading r1)

26 October 2026. Plan: revision 5, `plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r5.md`, md5 d93f3035 (revisions 1 to 4
kept: 7f64d22c, 6a77fa5f, 21a36a30, 4fa7aea1), registered 15 October 2026 before thresholds_p47.R ran, before any reading and
before any PREREG46 long run output existed. Host firebreather, `~/jobs/v142p47/`. Thresholds written by thresholds_p47.R
(md5 ce7b6d2f) at 09:06 on 26 October, file md5 e9609cfb (`logs/thresholds_md5.txt`); launch md5s recorded at 10:29
(`logs/launch_md5s.txt`); assembly assemble_p47.R (md5 02257096). The reading informs 14.3 only and reopens no 14.2 verdict.
No em dashes.

## Thresholds (computed once, before the reading)

From the frozen p19_a0111 qc_c observed columns (md5 979101be), 378 admitted stands:

- F_HT, the 99th percentile of the measured t1 to t2 top height decrease among the 114 stands with a decrease: 9.52 m.
- S_HT, ceiling(36 x 111 / 378), from the share of stands whose measured top height falls by more than 0.01 m: 11 stands.
- MG_LO, the 25th percentile of measured annual top height increment: **-0.025 m yr⁻¹** (median 0.078; intervals 4 to 14 years,
  median 11).

Reported, not gated (PREREG40 variant M, measured heights only): F_HT_M 11.23 m, S_HT_M 10 stands over 346 stands; himp fills
66% of published top tree heights at t1 and 58% at t2.

**MG_LO came out negative, so gates MG and MGN can fail only an arm whose median early top height falls.** That is how the
registered procedure resolves on these data. The 15 October implementation notes called MG_LO lenient; the measured intervals are 4 to 14 years (median
11). The plan is read as registered, and the leniency is named here. The large F_HT has
the same root: 30% of admitted qc_c stands show a measured top height decrease between visits, mostly from himp filled heights
and top tree turnover.

## Arms read

| Arm | Source | Label |
|:--|:--|:--|
| qc141 (14.1, QC_AFAC 0.111) | frozen PREREG44 | post hoc, reported beside its registered verdict |
| p38_fit (QC_AFAC 1.242) | frozen PREREG44 | post hoc |
| qc_rh (PREREG45) | frozen PREREG45 | post hoc |
| qc_lz (PREREG46) | run 26 October, trajectory files written 10:12 to 10:23 | **blind** (created after PREREG47 registration) |
| qc_ez (PREREG46) | not run (PREREG46 rule 1 fit stop) | not read |

Reading with four arms through P47_ARMS is the one deviation: qc_ez has no trajectories.

## Verdict

**Every arm read is not credible on the long run (rule 2).** qc141 stalls and the three alternatives overshoot, so the measured
grid brackets 14.1 and its three QC height candidates from both sides.

| Gate | qc141 | p38_fit | qc_rh | qc_lz |
|:--|:--|:--|:--|:--|
| C offset removed (median HT/ESI at 100 yr, stands over 1.175) | 0.837, 0 | 1.418, 31 | 1.205, 24 | 1.182, 19 |
| C raw ceiling (raw median against 1.285) | 0.916 pass | 1.515 fail | 1.309 fail | 1.28514 fail |
| CL floor 0.815 | pass | pass | pass | pass |
| MG median early rate (m yr⁻¹) against MG_LO -0.025 | 0.009 pass | 0.156 pass | 0.114 pass | 0.115 pass |
| MGN count (at least 23 of 36) | 35 | 36 | 36 | 36 |
| **LG** late growth, stands gaining in every 20 yr window after year 21 (at least 27) | **7 fail** | 30 | 34 | 34 |
| LGR window medians, m per 20 yr (flag under 0.5) | -0.04, 0.05, 0.03, 0.05 (flag) | 2.58, 2.40, 2.04, 1.39 | 1.67, 1.54, 1.25, 0.99 | 1.56, 1.43, 1.08, 0.73 |
| HM top height monotone (worst fall, stands over 0.01 m) | 1.04 m, 36: fail | 4.87 m, 11 | 0.92 m, 9 | 0.96 m, 8 |
| SO strict site ordering of HT gain (inverted cells of 6) | 3: fail | 6: fail | 6: fail | 6: fail |
| F, M, S, YD structural | pass | pass | pass | pass |
| Outcome | rule 2 (LG) | rule 2 (C) | rule 2 (C) | rule 2 (C) |

Reported, not gated: Eichhorn below 0.15 for qc141 and p38_fit; YD 0.15 fails for qc141 and p38_fit.

## Reading

14.1 as shipped holds QC top height nearly flat after its first decades: 7 of 36 stands keep gaining through every late window,
the late window medians are within 5 cm of zero, and every stand has some top height fall. Each of the three alternative QC
height paths fixes that and overshoots the measured frontier instead. qc_lz comes closest: 34 of 36 stands keep growing, its late
gains shrink from 1.56 to 0.73 m per window, and its offset removed median is 1.182, against the 1.175 bound. Strict site ordering
fails in every arm, qc141 included. The ESI bins span about 2.7 m (per the 15 October implementation notes, not recomputed here), so
ties and small inversions are expected even for a correct model. The gate as registered (tolerance 0) still separates qc141 (3 of 6 cells inverted) from the three alternatives (6 of 6).

For 14.3, on gates C and LG the measured grid brackets the arms: qc141 too flat, qc_lz the least tall of the three
alternatives; no arm passes, so the bracket is an inference to test, not a result. A form that keeps
qc_lz's fold B behaviour below r 1 and decelerates harder near the frontier is the target. Gate H relbin of PREREG46 shows qc_lz
overpredicting the held out fold B increment in the 1 to 1.25 bin (ratio 1.341, interval 0.888 to 2.680 on 62 trees), and the
fit itself rests on 54 fold A trees in that bin, so the next step needs either more data near the frontier or a shape constraint
chosen from outside the tag set. Both need a new pre-registration.

## Files

`plan/` (five revisions and the thresholds file), `logs/` (registration, thresholds md5, launch md5s, assembly log),
`assembled/gyr142-p47-*_DATA_2026-10-11.csv` (gates, gates-all, decision, credibility, relations, harness, arm inputs, 5 yr
trajectories) and the verdict text, `figs/`. Aggregates only. The DATA date stamp is the plan's constant.
