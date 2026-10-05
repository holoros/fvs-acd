# A relative height multiplier for the QC height increment: PREREG45 result

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
| H0 | qc_rh0 (a = b = 0) against frozen p19_a1000: worst 0 on results and per tree, 77 stands; the new branch is exact |
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

The relative height term does what PREREG37 said it should on the data: it removes the size and relative height structure
in the increment error on held out field tags and lands the pooled ratio at 1.003. The long run failure is a form failure,
not a fit failure: exp(a + b r) is positive at every r (0.61 at r = 1.3), so the increment slows but never stops, and top
height passes the measured frontier by year 50 and is still gaining about 1 m per 20 years at 100. A form with a zero or an
asymptote (the knot at r = 1 that Aaron did not pick, or an exp(a + b r) - c term) is the evident next arm. Caveat on gate C
[F4]: the 1.175 bound is the 99th percentile of measured stand visits, and few measured QC stands are as old as a t1 stand
plus 100 years, so the bound is conservative for the oldest horizon; at 50 years qc_rh is already at 1.163.

## Deviations

None from the registered plan. Assembly ran once; the first assembly of the benchmark part was dry run into a scratch
folder outside the job before the long run finished (stopped at the missing trajectories, nothing kept), to catch code
faults; the registered assembly was then run once on the frozen script.

## Files

`fit/`, `assembled/gyr142-p45-*_DATA_2026-10-05.*` (gates, gates for every arm, height table, stands summary, H0, K1,
reproduction, relations, non inferiority, credibility, five year trajectories without stand identifiers, verdict),
`figs/gyr142-p45-relht-longrun_2026-10-05.png` and its data, `logs/`, `diffs/`, `scripts/`, `plan/`. Stand lists and
annual trajectories stay in `out/` and `v142p44/plan/` (SERVERONLY).
