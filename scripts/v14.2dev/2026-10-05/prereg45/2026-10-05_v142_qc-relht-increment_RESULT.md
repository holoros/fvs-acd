# A relative height multiplier for the QC height increment: PREREG45 result (revision 2)

Revision 2, 5 October 2026 evening: adds the independent red team review and four post hoc stress tests (ST1 to ST4), corrects
three statements and the deviations section. The verdict and every registered number are unchanged.

5 October 2026. Pre-registration `plan/2026-10-05_v142_qc-relht-increment_PREREG45.md` (revision 1, md5 d032682d, recorded
14:35 server time before any fit or run, `logs/prereg_md5.txt`). Fit `fit_p45.R` (07959f2a), fit file 24cb959a; runner
`runner_p45_fb.R` (e85b3612) and driver `driver_p45.R` (06465636), each one reviewed replacement of the `htfx` line
(`diffs/`); assembly `assemble_p45.R` (md5 in `logs/assemble_md5.txt`, recorded before it ran). Informs 14.3 only; 14.2
keeps QC_AFAC 0.111. Aggregates only; stand identifiers stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## Verdict

**Rule 4: not cleared on long run grounds. Every harness and benchmark gate passes, including the published TOPHT gate
that 1.242 failed; the 100 year credibility bound and Reineke non inferiority fail.** qc_rh is the first QC arm to pass
every PREREG38 benchmark gate on field tags, and it is not a 14.3 candidate as specified, because the exponential multiplier
never reaches zero and top height keeps rising past the measured frontier.

## Fit (fold A, 698 field tag survivors on 129 sites)

The PREREG37 pooled R reproduced to the 13th decimal (1.2418873575799). m(r) = exp(a + b r), r = HT/ESI.

| Parameter | Estimate | Rounded (used) | 95% site bootstrap |
|:--|--:|--:|:--|
| a | 0.95950 | 0.9595 | 0.599 to 1.309 |
| b | -1.12394 | -1.1239 | -1.658 to -0.638 |

m is 1.97 at r 0.25, 1.29 at 0.625, 0.98 at 0.875 and 0.74 at 1.125. The registered expectation (about 1.5 at 0.25) was
low; the fitted contrast is steeper. Newton converged in 5 iterations, every bootstrap draw converged.

## Harness and reproduction

| Gate | Result |
|:--|:--|
| G0, G0b | pass (driver_p45 with RH unset equals frozen p19_a0111 and the PREREG31 dry trajectory) |
| H0 | qc_rh0 (a = b = 0) against frozen p19_a1000: worst 0 on results and per tree, 77 stands. With a = b = 0 every m is 1, so H0 shows the harness is unchanged but cannot show the branch computes m(r) correctly; ST1 below does |
| K1 | 0 of 397 stands not run |
| G1, G2 | 36 of 36 trajectories with 101 rows; age 0 worst 2.6e-15 |
| Reproduction | field tag counts 698 and 737 equal PREREG37; frozen stand summaries (32 rows, 4.6e-13), frozen height rows (76 rows, 4.9e-15) and frozen PREREG44 relations (328 rows, 4.4e-15) reproduced |

## Benchmark, screened qc_c fold B, field tags (737 trees)

| Gate | qc_rh | qc141 (0.111) | p38_fit (1.242) | Threshold | Pass |
|:--|:--|:--|:--|:--|:--|
| H1 pooled ratio | 1.003 (0.897 to 1.143) | 0.093 | 1.053 | 0.90 to 1.10 | yes |
| DBH class bias, m yr⁻¹ | +0.002, +0.002, -0.014 | -0.190, -0.141, -0.120 | -0.027, +0.022, +0.038 | absolute 0.04 and qc141 + 0.03 | yes |
| HT/ESI bin bias, m yr⁻¹ | -0.010, -0.009, +0.010, +0.030 | | worst 0.098 | absolute 0.04 | yes |
| TOPHT bias; dominant level | +14.14%; 0.980 | +6.29%; 0.898 | +16.21%; 0.994 | at most +14.63% (1.061); dominant within qc141 + 0.02 | yes |
| C1 %RMSE | 46.81 | 46.76 | 46.80 | not worse by 0.5 | yes |
| BA, stems deviation (points) | 0.35, 24.55 | 0.17, 24.23 | | within 1.0 and 2.0 of qc141 | yes |

The relative height bins are below 0.5 (164 trees), 0.5 to 0.75 (269), 0.75 to 1 (242) and 1 to 1.25 (62).

## Long run, 36 measured qc_c fold B stand lists, 100 years

| Arm | HT/ESI at 0 | at 50 | at 100 (median) | Stands over 1.175 | Mean top height at 100 (m) | Gain years 80 to 100 (m) |
|:--|--:|--:|--:|--:|--:|--:|
| qc141 | 0.784 | 0.906 | 0.916 | 0 of 36 | 17.29 | 0.44 |
| qc_rh | 0.784 | 1.163 | 1.309 | 32 of 36 | 24.44 | 0.98 |
| p38_fit | 0.784 | 1.290 | 1.515 | 34 of 36 | 28.01 | 1.17 |

Gate C (median at or below 1.175 and at most 10% of stands over) fails. Non inferiority to qc141 under the PREREG44 rule fails
on Reineke only: 11 flags against 12, 2 of them new, worst margin 1.124 against 0.768. Every other relation holds, and qc_rh
removes most of the top height falls that flag qc141 (HT monotone 9 stands against 36). Eichhorn and yield density flag for
qc141 and not for qc_rh.

## Reading

The relative height term does what PREREG37 said it should on the data: it removes most of the size and relative height
structure in the increment error on held out field tags and lands the pooled ratio at 1.003. The pass is lenient where the
long run is decided: in the 1 to 1.25 bin observed increment is about 0.075 m yr⁻¹, so a bias of +0.030 (upper bound +0.068)
is a ratio near 1.4, and fold A holds only 58 trees at r of 1 or more and 4 at 1.25 or more. The benchmark pass and the long
run fail are therefore consistent: the long run extrapolates the form above the range the fit supports. The gate C failure is a property of the form when
extrapolated: exp(a + b r) is positive at every r (0.61 at r = 1.3), so the increment slows but never stops, and the median
stand passes the measured frontier between years 50 (1.163) and 75 (1.234) and is still gaining about 1 m per 20 years at 100. A form with a zero or an
asymptote (the knot at r = 1 that Aaron did not pick, or an exp(a + b r) - c term) is the evident next arm. Caveat on gate C
[F4]: the 1.175 bound is the 99th percentile of measured stand visits, and few measured QC stands are as old as a t1 stand
plus 100 years, so the bound is conservative for the oldest horizon; at 50 years qc_rh is already at 1.163.

## Red team review and stress tests (post hoc, not registered)

An independent review re-derived every number in this RESULT from the assembled tables (all matched) and confirmed that the
assembly implements every registered gate and the rule order. Its material points, and the stress tests run for them on the
same 36 stand lists (`~/jobs/v142p45st/`, `assembled/st*_DATA_2026-10-05.csv`):

| Test | What it checks | Result |
|:--|:--|:--|
| ST1 | trace of every htfx call (driver copy with a logging hook, 2 stands, 3 years) against exp(a + b ht/csi) and the fill rule | 8 calls, 362 tree rows, worst difference 7.8e-15; 47 of 86 year 0 rows filled; 18 ingrowth rows all carry m(r), none 1 |
| ST2 | gate C with the engine first year height jump removed (qc141 jump minus its mean annual gain, median 1.90 m) | qc_rh median 1.205, 24 of 36 over 1.175; p38_fit 1.418, 31 over; qc141 0.837, 0 over; gate C still fails |
| ST3 | b at the bootstrap limits, a re-solved on fold A | b -1.6576 (a 1.2946): median 1.239, 28 over (offset removed 1.140, 12 over); b -0.6382 (a 0.6449): 1.378, 35 over; both fail gate C and non inferiority (2 new flags each; Reineke, and HT monotone at the upper b) |
| ST4 | ingrowth kept at m = 1 | median 1.309, 31 over (offset removed 1.200, 24 over); the ingrowth multiplier does not drive gate C (non inferiority fails on HT monotone, Reineke and yield density) |

Reineke attribution: the non inferiority failure is two stands. One new flag (margin 1.124) is also flagged under p38_fit
(1.101), the other has margin 0.032; both follow from faster height and diameter growth acting on unchanged mortality, not
from the height form itself. The qc141 reference passes gate C only because its cohort barely grows (benchmark ratio 0.093;
HT monotone flags on 36 of 36 stands), so the comparison is against a reference that is itself not credible. The fit and the
engine also differ on fold A (engine pooled ratio 0.950 against 1.000 by construction), because p0 is a one year increment at
the t1 r while observed increment averages over the interval as r rises. 28 of the 378 benchmark stands and 5 of the 36 long
run stands had no measured t1 height and used the fill rule; RFILL (0.815) and the 1.175 bound were computed over all 378
admitted stands, fold B included. The csi fallback cannot be reached under INDOMAIN=1.

## Deviations

The plan says the chain runs the fit and the build; the fit (with its md5) and the build ran by hand in the two minutes
between registration (14:35:26) and the chain start (14:37:06); `build_p45.sh` (e42510b5) is not in `launch_md5s.txt`.
The assembly was dry run on benchmark outputs into a scratch folder before its md5 was recorded; no edit was made after the
dry run (the recorded md5 is the dry run file's). Stress test faults, fixed and logged: the ST1 and ST4 wrappers first read
the fit md5 from the wrong job folder (an over broad path replace), so ST1 failed and was rerun; the first ST1 check kept only
the first stand and was replaced by `st1_check_r2.R`. The 80 to 100 year gains in the long run table are means (the qc141
median is 0.06 m). Five year trajectories in `assembled/` keep esi to two decimals and n0 per anonymised cell.

## Recommendation for 14.3

A QC height increment form with a zero or an asymptote in r, fitted with the increment integrated over the interval rather
than at t1, with relative per bin gates and upper interval gates in the benchmark, and gate C reported with the engine offset
removed. That is a new pre-registration and Aaron's call.

## Files

`fit/`, `assembled/gyr142-p45-*_DATA_2026-10-05.*` (gates, gates for every arm, height table, stands summary, H0, K1,
reproduction, relations, non inferiority, credibility, five year trajectories without stand identifiers, verdict),
`figs/gyr142-p45-relht-longrun_2026-10-05.png` and its data, `logs/`, `diffs/`, `scripts/`, `plan/`. Stand lists and
annual trajectories stay in `out/` and `v142p44/plan/` (SERVERONLY).
