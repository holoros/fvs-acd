# A QC height increment multiplier with a zero in relative height, for 14.3: pre-registration 46

11 October 2026, revision 1. Opened on Aaron's choice of 11 October (register PREREG46), from the recommendation of the
PREREG45 RESULT revision 2 (md5 0caf5dd6): a form with a zero or an asymptote in r, fitted with the increment integrated
over the remeasurement interval rather than at t1, relative per bin and upper interval gates in the benchmark, and gate C
reported with the engine offset removed. Written before any PREREG46 fit, engine run or projection. The outcome **informs
14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579**. NB is parked (no tree paired NB height sample; PREREG45b).
L and T are not re-estimated. GT1 stays a named failure. Stand identifiers stay in `*_SERVERONLY` files. No coordinates.
No em dashes.

## Why a new form

PREREG45 (qc_rh, m = exp(a + b r), r = HT/ESI) passed every harness and benchmark gate on fold B field tags and failed gate
C: m is positive at every r (0.61 at r 1.3), so the median drawn stand reached HT/ESI 1.309 at 100 years against the
measured frontier 1.175, and was still gaining about 1 m per 20 years. Two further faults are addressed here: the fit
used p0 at t1 while the observed increment averages over an interval in which r rises (engine fold A ratio 0.950 against
1.000 by construction), and the benchmark bias gate was lenient in the 1 to 1.25 bin, where a bias of +0.030 m yr⁻¹ is a
ratio near 1.4.

## Arms (two, each with two free parameters)

Both arms set every QC tree's dht.mult to m(r), r = current height over stand ESI (csi_site, or CSI_DEFAULT when csi_site
is not above 2), reassigned at the start and after every annual step for every live tree, ingrowth included, with the
PREREG45 fill rule (trees with no height take the expf weighted mean m of the stand's trees with a height; a stand with no
measured height takes m at r = 0.815, QC_RH_RFILL). NB, NS and ME are untouched.

| Arm | m(r) | Zero | Fixed constant and provenance |
|:--|:--|:--|:--|
| qc_lz | max(0, a + b r) | free, r0 = -a/b | none |
| qc_ez | exp(a + b r) max(0, 1 - r / RMAX) | fixed at RMAX | RMAX = 1.285, the maximum measured TOPHT/esi8 over the 756 admitted qc_c visits (`frontier_p45_DATA.csv`, md5 63826d67) |

qc_lz lets the data place the zero; qc_ez keeps the PREREG45 shape below the frontier and closes it at the largest
relative height ever measured. [F4] RMAX and the gate C bound come from the same file but are different statistics
(maximum against 99th percentile), so qc_ez can still fail gate C; the shared source is reported.

## Fit (fold A only, frozen before any engine run)

`scripts/fit_p46.R` rebuilds the PREREG37 fold A field tag survivor set with the logic of `fit_p45.R` (md5 07959f2a), and
stops unless it reproduces the PREREG37 pooled R 1.2418873575799 on 698 trees to 1e-12 and the PREREG45 a and b to 1e-9
[F9]. The predicted increment for a tag is integrated over its interval: starting at H1, annual steps h(t + 1) = h(t) +
p0(h(t)) m(h(t) / csi), with p0 from the same dht equation and species terms as `fit_p45.R`, crown ratio and CCF held at
their t1 values [ASSUMPTION: the engine updates both; holding them is the conservative simplification and is reported],
the engine cap rule (no increment in a step where h + p0 exceeds max_height), whole years for floor(iv) steps and a
fractional final step of length iv - floor(iv). pbar = (h(iv) - H1) / iv. Estimating equations sum (1, r1)(obs - pbar) =
0, solved by Newton with a central difference Jacobian (step 1e-6), started for qc_lz at the line through the PREREG45 m at r 0.25 and 1.125 (a
2.3236, b -1.4103) and for qc_ez at the PREREG45 a and b (0.9595, -1.1239). Site cluster bootstrap B = 1000 with the PREREG37 seed and weights. a and b used rounded to four decimals.
No fold B file is read. Reported: a, b, intervals, r0 for qc_lz, m at r 0.25, 0.625, 0.875, 1.125, the fold A per bin
ratio obs over pbar, the count of fold A tags with r1 at or above r0 (qc_lz) or RMAX (qc_ez), and nonconverged draws.
Fit stops (rule 1): Newton does not converge at the point estimate, b is not negative, or more than 5 percent of draws do
not converge.

## Driver change, reviewed before any run

One edit, applied by `scripts/build_p46.sh` to `runner_p45_fb.R` (e85b3612) into `runner_p46_fb.R` and to `driver_p45.R`
(06465636) into `driver_p46.R`: the `m <- exp(QC_RH_A + QC_RH_B * x$ht / cs)` line inside `htfx_rh` and the fill constant
become a form switch on QC_RH_FORM (exp, lz, ez; exp is the PREREG45 line unchanged) with QC_RH_RMAX for ez, plus an
optional trace hook (QC_RH_TRACE, a file path; when unset no file is written and nothing else changes). The edit is
asserted to match exactly once in each file; diffs go to `diffs/`. Wrappers are PREREG45 copies with job root, runner or
driver and md5, arm case and log tags changed; path rewrites exclude the fit md5 path, which is set explicitly.

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | driver_p46 mode g0, qc141 (RH unset), PREREG31 G0 stands, against frozen p19_a0111 | worst scaled difference at or below 1e-9 | PREREG31, 44, 45 |
| G0b | driver_p46 mode grid, qc141 cell MX_E19.8_N6000, 100 years, against the frozen PREREG31 dry trajectory | identical | PREREG44, 45 |
| G0x | driver_p46 arm qc_rh (form exp, PREREG45 a and b) on the PREREG44 S1 list against frozen PREREG45 `traj_qc_rh_S1.csv` | worst scaled difference at or below 1e-9 | new; shows the switch leaves PREREG45 unchanged |
| H0 | runner_p46 arms qc_lz0 (a = 1, b = 0) and qc_ez0 (a = b = 0, RMAX = Inf), so m = 1, PREREG33 G0 subset (tasks 21 to 24 pattern) against frozen p19_a1000 | worst scaled difference at or below 1e-9, results and per tree | PREREG38, 45 |
| TR | trace gate, ST1 design: driver_p46 with QC_RH_TRACE, each arm, 2 stands of the S1 list, 3 years; recompute every traced m from ht/cs, the fitted rounded a and b, the form and the fill rule | worst absolute difference below 1e-12; every ingrowth row carries m(r) (none equal 1 unless m(r) is 1); trees with r at or above the zero carry m = 0 | PREREG45 ST1, now registered |
| K1 | RUN_OK other than 1 after the PREREG38 retry rule | 0 | PREREG23 |
| G1, G2 | long run: 101 rows, run_ok 1; age 0 stems and BA equal the t1 list | all; 1e-6 | PREREG44 |

## Benchmark gates (screened qc_c fold B; height on field tags, PREREG38 assembly pass 2), per arm

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H1 level | pooled annual height increment ratio | 0.90 to 1.10 | PREREG14 |
| H classes | mean bias by t1 DBH class | absolute at or below 0.04 m yr⁻¹, no class worse than qc141 by more than M_CLS | PREREG45 |
| H relht | mean bias by t1 HT/ESI bin (below 0.5, 0.5 to 0.75, 0.75 to 1, 1 to 1.25; bins of 30 or more trees) | absolute at or below 0.04 m yr⁻¹ | PREREG45 |
| H relbin | pooled ratio pred over obs in each of those bins | 0.80 to 1.25 | new: the 1 to 1.25 bin observed increment is about 0.075 m yr⁻¹, so 0.04 alone admits a ratio near 1.5 |
| H upper | site bootstrap 95% interval of the per bin ratio | upper limit at or below 1.50 and lower limit at or above 0.67 in every bin | new; bounds the extrapolating tail |
| TOPHT | published TOPHT bias; dominant cohort t2 level | as PREREG45 (at most frozen p23_a1061; dominant within qc141 + M_DOM) | PREREG38 |
| V2, B1, B2 | C1 %RMSE; BA and stems | as PREREG38 against qc141 | PREREG23 |

Reported, not gated: engine fold A pooled ratio (the integrated fit should bring it near 1; PREREG45 gave 0.950), and the
same tables for qc_rh (frozen PREREG45) and p38_fit.

## Long run (PREREG44 stand list grid)

The same 36 drawn stands (`v142p44/plan/stands_S{1,2,3}_SERVERONLY.csv`, read, not redrawn), 100 annual steps, arms qc_lz
and qc_ez; qc141, p38_fit and qc_rh trajectories are the frozen PREREG44 and PREREG45 outputs, read. Relations, margins and
non inferiority exactly as PREREG44 and PREREG45.

Gate C, per arm, both parts required:

1. Offset removed (primary): with the per stand engine offset of ST2 (`st2_offset.R`, md5 567fa63d: qc141 HT(1) - HT(0)
   minus qc141's mean annual gain over years 1 to 100) subtracted from HT at 100 years, the median HT/ESI over the 36
   stands is at or below 1.175 and at most 3 stands exceed 1.175.
2. Raw ceiling: the raw median HT/ESI at 100 years is at or below 1.285 (the measured maximum).

Reported, not gated: raw gate C as PREREG45, top height at 100 years, the gain over years 80 to 100 (mean and median), the
year the median crosses 1.175, and the same for the frozen arms.

## Decision rule, per arm, in order

1. Fit stop, G0, G0b, G0x, H0, TR, K1, G1 or G2 fails: harness failure, no verdict for that arm.
2. H1 level, H classes, H relht, H relbin or H upper fails: not adopted, failing gate named; the long run is still run and
   reported.
3. TOPHT, V2, B1 or B2 fails: not adopted, trade off reported.
4. Gate C (either part) fails, or the arm is not non inferior to qc141 under the PREREG44 rule (A) and (B): not cleared on
   long run grounds.
5. All pass: the arm is a 14.3 QC height increment candidate, a regional setting, subject to confirmation on new data.

If both arms reach rule 5, the candidate is the arm with the smaller worst absolute per bin bias on fold B; at equal values
to three decimals, qc_lz (no fixed constant). Every failing gate is reported. **No outcome changes 14.2.**

## Execution

New directory `~/jobs/v142p46/` on firebreather; frozen runs are read, never rerun; nothing is overwritten. Chain detached
(`setsid nohup`, no sleep in the launching call): fit and its md5, build, G0, G0b, G0x, TR, benchmark tasks (qc_lz 1 to
20, qc_ez 1 to 20, qc_lz0 and qc_ez0 on the G0 subset; at most 2 R processes, none started at load 12 or above), PREREG38
retry rule, scoring r2, the 36 stand long run (six tasks), then assembly as a separate step with its md5 recorded before
it runs. Script md5s are recorded in `logs/launch_md5s.txt` before the chain starts. Deviations are logged in the RESULT.
