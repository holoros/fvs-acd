# The form of the 14.1 thinning release term T beyond the PREREG2 family, for 14.3: result of pre-registration 3

Run on 28 October 2026 on Cardinal in `~/v143p3/` (steps 1 to 3) and on firebreather in `~/jobs/v143p3/` (step 1, FIA
counts). It follows the registered plan `2026-10-28_v143_T-form-class-shape_PREREG3.md` (revision 1, md5
20364c4b065615317ea7feccb87f5919, registered 2026-10-28T06:00:59-0400 in `logs/prereg_md5.txt`, before any frame, fit or
outcome read).

Every number below is copied from a server file under `~/v143p3/out/` or `~/v143p3/logs/`, named at each point (copies
in this folder's `out/` and `logs/`). The selection record is `out/fit3_selection_record.txt` (md5 7a6b3374, logged in
`logs/selection_md5.txt` at 2026-10-28T08:07:59-0400). Diameter increments are in cm yr⁻¹; CV values are expansion
weighted mean squared errors of interval diameter increment, (cm yr⁻¹)².

Standing rules: 14.1 is unchanged by any outcome here; L and T of 14.1 were not re-estimated in place (new arm only); no
engine file, coefficient or default of 14.1 was edited; GT1 stays a named failure of 14.1. Deviations are listed at the
end and in `2026-10-28_v143-prereg3_DEVIATIONS.md`.

## Verdict

**Open (rule 5). T4 is the documented best form of this family; it is not adopted. 14.3 keeps 14.1's T.**

The fit set (CTRN plus mefia_ph_c survivors) selects **T4**, a release that rises with relative size and then declines
as a power of r: m_T = 1 + alpha · exp(−beta tst) · sm(r; 0.4, 1.15) · min(1, (1.0 / r)^kappa), with alpha 0.69456,
beta 0.062403 yr⁻¹ and kappa 1.5974 (`out/fit3_full_fits_DATA.csv`). It carries the labels "grid edge" and "tail
estimated from FIA" (`out/fit3_selection_record.txt`). TL does not beat it (rule 3 not met). The no harm gates were not
evaluated in this registration (rule 4, engine step deferred by the registered scope). The confirmation set misses the
heavy floor (10 heavy stands against 30), so the verdict is open by rule, as counted before registration
(`out/conf_pooled_DATA.csv`).

The margin is thin: T4 beats T0c (C2 refitted) by 0.000481 in pooled CV against an SE of 0.000415, about 1.2 SE
(`out/fit3_cv_paired_DATA.csv`), and every stress variant re-selects H0 (below), so the selection is not robust to the
analyst choices tested.

## Decision rule, in order

| Rule | Test | Value (source) | Outcome |
|:--|:--|:--|:--|
| 1 | Fit-level harness: H2b, FM, H6, H7 | H2b: alpha 0.547688023, beta 0.0623578355 against PREREG2's 0.54768802 and 0.062357835, differences 3.4e-9 and 4.9e-10, pair 0.5/1.0 (`out/fit3_p2repro_h2b_DATA.csv`). FM: CTRN 46,521 records; mefia_ph_c 8,971 records, 0 unmapped, max \|d1 − D0\| 0 (`out/frame3_support_DATA.csv`, `out/frame3_map_check_DATA.csv`). H6: allowlists `out/conf_fb/conf_fia_allowlist_reads.log`, `out/conf_nbqc_allowlist_reads.log`; no candidate prediction on any confirmation source. H7: by the new-data rule (v2 in 2025 or later) | pass |
| 2 | The fit set selects no form | selected T4 (best eligible T4; tied set T4) (`out/fit3_selection_record.txt`) | not met |
| 3 | TL beats the selected form by more than one SE | TL minus T4: +0.000867 (SE 0.000298), TL worse (`out/fit3_hv2_DATA.csv`) | not met |
| 4 | No harm gates N0, N1, N2, R1 | not evaluated (engine step deferred, registered scope) | not evaluated |
| 5 | Confirmation set meets every floor | heavy 10 (floor 30; upper bound 15), ESI coverage 0.946 (floor 0.80), gated classes 3 (floor 3) (`out/conf_pooled_DATA.csv`) | floor missed: **open** |

## Step 1: confirmation set (counted before registration)

Sources: `out/conf_fb/conf_fia_counts_DATA.csv`, `out/conf_nbqc_counts_DATA.csv`, `out/conf_esi_surfaces_DATA.csv`,
`out/conf_pooled_DATA.csv` (md5s in `logs/conf_counts_md5.txt`, logged 2026-10-28T05:57:52-0400).

| Source | Stands | Heavy | ESI coverage |
|:--|:--:|:--:|:--:|
| 1 Maine FIA, v2 in 2025 | 31 (9 "same plots, new interval") | 10 | 1.000 |
| 2 New Hampshire FIA, v2 in 2025 | 6 | 0 | 0.667 |
| 3 NB MAGPlot CLI | 111 with a treatment before v1 | no rule 7 class (no third visit) | 1.000 |
| 3 NB NFI ground plots | 11 (5 with a third visit) | not classed; upper bound 5 | 1.000 |
| 4 Quebec cut flag | 0 (the flag marks a cut inside the interval) | 0 | n/a |
| 5 ESI surfaces west of 71.5 W | complement only | n/a | n/a |

Pooled sources 1 and 2: 37 stands, 10 heavy, ESI coverage 0.946, survivor trees in heavy and intermediate stands of 17,
14, 38, 54 and 112 in the five d / Dq classes, so 3 gated classes. The builder copy, run on the same FIADB download for
v2 at or before 2024, returns 827 Maine stands with 221 heavy, mefia_ph_c's own counts.

## Step 2: the joint fit frame

Sources: `out/frame3_counts_DATA.csv`, `out/frame3_support_DATA.csv` (frame md5 8f1db5a7, `logs/step2_md5.txt`).

- CTRN: 46,521 records, 17 installations; 3.8% of records above r 1.5, 1.2% above 1.7, maximum r 2.985.
- mefia_ph_c: the scorer's survivors number 22,784; in heavy and intermediate stands 9,599 (412 stands); with a known
  tst 8,971 records, 383 stands, 375 plots, tst 1 to 5 yr. 41.4% of these records lie above r 1.5 and 32.0% above 1.7;
  maximum r 7.79.
- mefia_ph_c plot folds hold 772 to 971 records each (`out/frame3_fia_folds_DATA.csv`).

## Step 3: fit, CV, class gate screen and selection

Sources: `out/fit3_full_fits_DATA.csv`, `out/fit3_cv_DATA.csv`, `out/fit3_cv_paired_DATA.csv`,
`out/fit3_class_gate_summary_DATA.csv`, `out/fit3_bootstrap_bounds_DATA.csv`, `out/fit3_selection_DATA.csv`.

| Form | Full-data coefficients (grid cell) | Pooled CV (SE) | CV CTRN | CV FIA | Paired diff vs T0c (SE) | Class gate CTRN / FIA | Bound share ok | Eligible |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| T0f (14.1) | r5 frozen | 0.11130 (0.00618) | 0.15292 | 0.06968 | +0.01390 (0.00074) | fail / fail | n/a | reference |
| T0c (C2 refitted) | alpha 0.47049, beta 0.064302 (0.4/1.0) | 0.09740 (0.00602) | 0.15138 | 0.04342 | 0 | pass / fail | n/a | reference |
| T1 | alpha 0.66140, beta 0.063153, delta 0.84712, g_min 0.24126 (0.4/1.15, r_d 1.0) | 0.09707 (0.00577) | 0.15119 | 0.04295 | −0.000332 (0.000412) | pass / pass | no (g_min 7.25% at a bound) | no |
| T2 | alpha 0.56633, beta 0.061247, r_m 1.08685, s 0.36533 | 0.09709 (0.00577) | 0.15134 | 0.04284 | −0.000311 (0.000413) | pass / pass | yes | no (margin) |
| **T4** | alpha 0.69456, beta 0.062403, kappa 1.5974 (0.4/1.15, r_d 1.0) | **0.09692 (0.00577)** | 0.15097 | 0.04287 | **−0.000481 (0.000415)** | pass / pass | yes | **yes** |
| T3 (diagnostic) | alpha 0.57470, beta 0.060515, c 0.292, 0.488, 1, 0.778, 0.448 | 0.09706 (0.00577) | 0.15165 | 0.04247 | −0.000343 (0.000398) | fail / pass | reported | never |
| TL (diagnostic) | alpha 0.49500, beta 0.064302, k_FIA −0.0375 (0.4/1.0) | 0.09779 (0.00589) | 0.15208 | 0.04350 | +0.000386 (0.000205) | fail / fail | reported | never |

- **Selection.** Only T4 is eligible: it passes the class gate on both sources and the bound check, and beats T0c by
  more than one SE. The tied set is T4 alone.
- **T4 parameter intervals** (2,000 installation and plot clustered draws, grid cell held): alpha 0.391 to 1.065, beta
  0.0185 to 0.1489 (0.5% of draws at a bound), kappa 0.547 to 2.678 (0.15% at a bound). No parameter pair has |r| above
  0.95; the largest is alpha with kappa, 0.684 (`out/fit3_bootstrap_cor_DATA.csv`).
- **Grid edge.** T4's cell sits on the registered grid edge in r_lo (0.4), r_hi (1.15) and r_d (1.0) (`out/fit3_edge_DATA.csv`).
  The registered extension is triggered only by an r_d pick at 1.5, so it did not run. The next best T4 cell (0.5/1.0, r_d 1.15) is
  higher in objective by about 2.1e-5 (`out/fit3_grid_objective_DATA.csv`).
- **Shape.** With r_d 1.0 below r_hi 1.15, T4's release rises from r 0.4, and above r 1.0 it is multiplied by
  (1.0 / r)^1.597. At r 2 that factor is about 0.33.

**Held-out observed over predicted by d / Dq class, at r ≥ 0.6** (`out/fit3_class_gate_DATA.csv`; the class below 0.6
is reported, not gated):

| Source, class | T4 | T0c | T0f (14.1) |
|:--|:--:|:--:|:--:|
| CTRN 0.6 to 0.85 | 0.919 | 0.915 | 0.994 |
| CTRN 0.85 to 1.15 | 1.010 | 1.077 | 1.147 |
| CTRN 1.15 to 1.5 | 1.000 | 1.003 | 0.951 |
| CTRN above 1.5 | 1.075 | 0.977 | 0.771 |
| mefia_ph_c 0.6 to 0.85 | 1.031 | 1.053 | 1.129 |
| mefia_ph_c 0.85 to 1.15 | 0.912 | 0.962 | 0.999 |
| mefia_ph_c 1.15 to 1.5 | 0.983 | 0.956 | 0.854 |
| mefia_ph_c above 1.5 | 1.008 | 0.866 | 0.497 |
| CTRN below 0.6 (reported) | 0.678 | 0.675 | 0.661 |
| mefia_ph_c below 0.6 (reported) | 1.221 | 1.223 | 1.195 |

On mefia_ph_c this screen is in sample in the sense of the plan (mefia_ph_c is fit data and shaped the form list); it is
not a confirmation. T0c's held-out mefia_ph_c ratio above r 1.5 (0.866) is close to PREREG2's C2 V1 value there (0.867, a
different computation with different coefficients), and T4 closes it (1.008) while keeping every gated class within 0.10.

**Removal intensity (reported only;** held-out mefia_ph_c, `out/fit3_fia_by_rf_DATA.csv`**):** observed over T4 is
0.830 (RF up to 0.35, 584 trees), 1.006 (0.35 to 0.65, 4,966) and 1.120 (above 0.65, 3,421). T0c reads 0.816, 0.987 and
1.106. The removal intensity gradient remains under every form.

**HV2 (TL).** TL's k_FIA is −0.0375, and TL is worse than T4 by 0.000867 (SE 0.000298); the mid-class pattern is not
read as a CTRN against FIA level difference.

## Stress test (exploratory re-selection, 200 draws each)

Sources: `out/fit3_<variant>_selection_record.txt`, `out/fit3_<variant>_selection_DATA.csv`,
`out/fit3_<variant>_class_gate_DATA.csv`, `out/fit3_<variant>_full_fits_DATA.csv`. The primary is not changed by any row.

| Variant | Re-selection | T4 against T0c, diff (SE) | Why T4 is not eligible |
|:--|:--|:--:|:--|
| (a) mefia_ph_c weighted by record share | H0 | −0.000390 (0.000487) | mefia_ph_c class 0.85 to 1.15 at 0.894; margin |
| (b) CTRN only fit | H0 | −0.000653 (0.000269) | mefia_ph_c class 0.85 to 1.15 at 0.891 (beats T0c, fails the screen) |
| (c) Dq on trees at or above 12.7 cm | H0 | −0.000184 (0.000200) | 4 classes fail; kappa at a bound in 43.5% of draws; margin |
| (d) 12.7 cm floor | H0 | −0.000482 (0.000616) | 4 classes fail; kappa at a bound in 8.0% of draws; margin |
| (e) basal area increment response | H0, not informative | n/a | the optimizer stayed at its start values (DEVIATIONS item 10) |
| (f) r_d extended to 1.7 | not run | n/a | not triggered (r_d pick 1.0) |

Every variant re-selects H0, so **the selection of T4 is not robust to the analyst choices tested**: weighting
mefia_ph_c by its record share, fitting on CTRN only, or changing the Dq or size floor definition each removes it, in (a) and (b)
through the mefia_ph_c class 0.85 to 1.15 falling just outside 0.90, and in (c) and (d) through four classes failing the screen. The primary's headline sits at the favorable end of
this range, and is flagged as such.

## What this means for 14.3

A release that rises to about r 1.0 and then falls as roughly r^−1.6 fits the pooled CTRN and post-harvest FIA survivor
data better than the PREREG2 family's best form under the registered primary choices, and it is the only eligible form (T1 and T2 also pass the class screen on both sources but fail the bound check and the margin). The gain over C2 refitted is about 1.2 SE of the paired pooled CV difference, a
modest improvement, and every stress variant re-selects H0. The tail behaviour above r 1.5 is an FIA estimate (41% of
mefia_ph_c fit records lie there, against 3.8% of CTRN's).
mefia_ph_c is now fit data, so it can no longer test the form. The confirmation is open for structural reasons: only 10
new heavy post-harvest stands exist in the available FIA, NB and Quebec sources. 14.3 keeps 14.1's T; T4 is the
documented best form, pending the engine no-harm gates and a confirmation set that meets the floors (for example the
next Maine FIA remeasurement cycle).

## Not run

- Step 4 of draft 1: T4 in the engine on every inspected frame (N0, N1, N2, R1), with the engine harness gates H1, H1b
  and H4 and a new overlay. Rule 4 is therefore not evaluated.
- Step 5: the confirmation runs (open by rule).
- The r_d 1.7 extension (not triggered) and the symmetric control variant (dropped in revision 1).

## Deviations (full list in the DEVIATIONS file)

1. Six rows of a firebreather 14.2 table, with Quebec stand keys and volumes, printed to the transcript before
   registration; not used.
2. A credential string from unrelated scripts was printed to the session transcript; rotation recommended.
3. The `res_m` column of the ESI surface table holds degrees.
4. The 5 NB NFI stands with a third visit were not classed; carried as an upper bound.
5. Step 1 survivor counts are FIADB-status approximations.
6. The fitter was edited (parallel full fits) after the first dry run; the earlier copy is kept and the edit was dry run.
7. A temporary inventory directory was created in home, then moved into `~/v143p3`.
8. The frame script was dry run on real inputs, as in PREREG2.
9. The laptop bridge was down from about 06:55 to about 19:00 EDT; no job was affected, and the stress variants and the
   assembly were submitted after the selection md5.
10. The basal area increment stress variant is not informative: its optimizer stayed at the start values (objective
    of order 1e-6 in its units), so its H0 says nothing about the forms.

## Verification note (28 October 2026)

An independent read-only check recomputed every headline value from the output files and found them matching, with the verdict following the registered rule in order. This revision changes wording only (2 fixes). The earlier text is kept beside this file with the suffix _PREV_20261028b.
