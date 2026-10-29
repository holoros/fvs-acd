# The form of the 14.1 thinning release term T, for 14.3: result of pre-registration 2

This run was done on 27 October 2026 on Cardinal in `~/v143p2/`. It follows the registered plan `2026-10-26_v143_T-form-reestimation_PREREG2.md` (revision 5, md5 b7562e8b). The plan md5 was checked before any work.

Every number below is copied from one of these sources:
- a server file under `~/v143p2/out/`, named at each point (copies are in this folder's `out/`);
- the selection record `out/fit_selection_record.txt` (md5 14e49e5b, logged in `logs/selection_md5.txt` at 06:35:12);
- the run logs.

Units: gaps and rates are in Mg ha-1 yr-1. Survivor ratios are observed over predicted diameter increment, with the predicted increment floored at 0.05 cm yr-1.

Standing rules: 14.1 is unchanged by any outcome here. L was not re-estimated. GT1 stays a named failure of 14.1. The deviations are listed at the end and in `2026-10-27_v143-prereg2_DEVIATIONS.md`.

## Verdict

**Not adopted: rule 3.** The fit set selected **C2**: exponential decay in years since thinning, times a smoothstep in d / Dq from r_lo 0.5 to r_hi 1.0, flat above 1.0. On mefia_ph_c, a previously inspected set, C2 fails the V1 survivor gate in the class above d / Dq 1.5. Observed over predicted there is 0.867, outside 0.90 to 1.10 (`score4_v1_DATA.csv`).

C2 also fails these gates:
- P1-S (heavy survivor growth);
- P3 (light stands);
- N1 (ctrn_fl bias);
- V1-L (light and low-volume stands).

It passes these gates:
- P1-NW, P2, P5;
- N0, N2, R1 (`score4_decision_DATA.csv`).

The level reading does not apply, because V1's residual changes sign across classes (range 0.217). So the defect is read as form, not level (`score4_level_reading_DATA.csv`). Under the decision rule, 14.3 keeps 14.1's T.

The sealed New Hampshire and Vermont confirmation is **open**, not confirmed and not failed. Two registered open conditions hold: ESI coverage is 0.370 (below 0.80), and there are 16 heavy stands (below the 30-stand floor). The candidate was still scored there once, for the report, after the stage (a) md5 was logged (see below).

Labels carried: "threshold pair on a grid edge" (C2 at 0.5 and 1.0) and "previously inspected" (mefia_ph_c).

## Harness gates (rule 1): all pass

- **E0** (overlay sourced and off): reproduces frozen 14.1 byte for byte on all 19 Phase D sets and mefia_ph_c (every results and tree-list file). The 20 thinned grid trajectories match in every value (`gates_e0h1_DATA.csv`).
- **H1** (C0f with the overlay on): the same, on every one of those frames and on the grid (`gates_e0h1_DATA.csv`).
- **H2** (r5 mode): alpha 0.3710903 and beta 0.08220498, against 0.37109 and 0.08220; differences 3.1e-7 and 5.0e-6 (`fit_h2_DATA.csv`).
- **H3:** the fit-frame r equals the r the engine passes to `.acd_v141_mT` on the 500-record sample, maximum difference 4.9e-15 (`gates_h3_DATA.csv`).
- **H4:** for all 8 forms, traced m_T equals the formula; maximum difference 0, and 2.2e-16 for C3. tst advances by one per step from the TST file. C3 equals 1 at tst 0 (`gates_tr_DATA.csv`).
- **H5:** C4's 24 traced records above its cap of 1.5 are flat in r. No traced CTRN record exceeded 2.9848, so for C0f, C0r, C1 and C6 the cap is enforced by the overlay's own check (`gates_tr_DATA.csv`).
- **H6:** reads are listed in `logs/h6_allowlist_reads.log`. No candidate run touched mefia_ph_c or the sealed set before the selection md5. All candidate engine runs (SEL, SELN1, trC*, gSEL) started at 17:59 or later; the selection was written at 06:35.
- **K1:** RUN_OK is 1 for every stand in every arm. **CAP:** "CAP ok" appears in all 155 arm logs (`gates_k1_DATA.csv`).
- **Decomposition identity:** S + M + I + R - W equals the gap in every class:
  - A0 and 14.1 on mefia_ph_c: maximum stand residual 2.3e-13 (`decomp_identity_DATA.csv`);
  - SEL on mefia_ph_c (`score4_identity_SEL_DATA.csv`);
  - A0, 14.1 and SEL on the sealed set (`score5c_identity_DATA.csv`).

## Step 2: frame, PEF, decomposition, G-F

Step 2 outputs were md5-recorded before any fit (`logs/step2_md5.txt`, 06:24:57).

**Fit set.**
- CTRN: 46,521 T_post records, 119 locations, 17 installations. Every record maps exactly onto the A0 engine trees, and tst equals the engine TST file for all 46,521 (`frame_engine_map_check`, `frame_ctrn_tst_check`).
- The r5 reconfirmation of 14.1 above d / Dq 1.5 gives 0.775 (0.660 to 0.861) (`frame_r5_dq_reconfirm`).
- Fit-set support: 3.8% of records exceed d / Dq 1.5 and 1.2% exceed 1.7. The maximum is 2.985 (`frame_fitset_support`).

**PEF link test: fails, so PEF is excluded.** 0.795 of end-visit post-thinning live records link to a start-visit tag, against the 0.80 rule. The reading of the rule was fixed in the script header before any count.
- Readings that were reported but decide nothing: 0.814 at DBH 12.7 cm or more, and 0.983 forward.
- Linked PEF tags keep their species in only 52% of cases (CTRN: 100%). So the pef_c frame tags are not tree identities under any reading (`frame_pef_link_test`).
- The fit therefore uses CTRN only, and PEF is not a CV fold.

**14.1 size floor.** None: T applies to every tree record, and Dq covers all records (`frame_size_floor_14_1`). The 12.7 cm floor is therefore a stress variant.

**mefia_l_c.** It holds observed survivor increments through the chained FIADB linkage: 24,507 linked survivors, 65% of t1 trees (`frame_mefia_l_c_check`). The secondary control was fitted as a stress variant; see below.

**Heavy decomposition on mefia_ph_c** (221 heavy stands, frozen A0 and 14.1; `decomp_summary_DATA.csv`):

| | Gap | S | M | I | R | W | S_obs | P1-S |
|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| A0 | 0.317 | -0.245 | 0.408 | -0.529 | 0.035 | -0.648 | 1.832 | -0.245 (tol 0.183, fails) |
| 14.1 | 1.391 | 0.761 | 0.450 | -0.503 | 0.035 | -0.648 | 1.832 | 0.761 (fails) |

- Implied release: 0.245 (0.127 to 0.367).
- P1-NW bounds: 0.908 (A0 gap + release + 0.25 x observed rate) and 1.391 (14.1's heavy gap).

**G-F**, the only sealed quantity read before selection:
- A0's heavy gap is -0.463 (-1.055 to 0.140) on 16 stands, with tol25 0.480.
- This is within tolerance at 25% and 35%, and closes at 15% (`gf_sealed_A0_heavy_gap_DATA.csv`).
- With 16 stands, under the 30-stand floor, it is weak evidence.

## Step 3: fit and selection (fit set only)

Source: `fit_selection_record.txt`, `fit_*_DATA.csv`.

| Form | Full-data coefficients | LOIO CV MSE (SE) | Paired diff vs C0r (SE) | Class gate | Bound share OK | Eligible |
|:--|:--|:--:|:--:|:--:|:--:|:--:|
| C0f (reference) | r5 frozen | 0.15292 (0.01211) | -0.00118 (0.00100) | fails | n/a | n/a |
| C0r (reference) | alpha 0.2953, beta 0.0700 | 0.15411 (0.01280) | 0 | fails | yes | n/a |
| C1 | alpha 0.4565, beta 0.0713, gamma 0.592 | 0.15317 | -0.00094 (0.00174) | fails | yes | no |
| C2 | alpha 0.5477, beta 0.0624, pair 0.5/1.0 | 0.15167 (0.01137) | -0.00244 (0.00200) | passes | yes | **yes** |
| C3 | alpha 0.5399, tau 3.418, pair 0.5/1.0 | 0.15139 (0.01128) | -0.00272 (0.00232) | passes | yes | yes |
| C4 | alpha 0.4541, beta 0.0698, gamma 0.697 | 0.15313 | -0.00098 (0.00174) | fails | yes | no |
| C5 | alpha 0.4819, beta 0.0763 | 0.15347 | -0.00064 (0.00200) | fails | yes | no |
| C6 | alpha 0.3096 | 0.15395 | -0.00016 (0.00009) | fails | yes | no |

- **Selection.** C3 had the lowest CV among eligible forms. C2 lies within one fold SE of it, so they are tied. With equal parameter counts (4 each), the registered order picks C2.
- **HL** (C3 vs C2 at C2's pair): -0.00039 (SE 0.00052). Not supported.
- **C2 held-out class ratios:** 0.942, 1.033, 0.956 and 0.929 for the classes from 0.6 upward. The class below 0.6 is 0.697, reported and not gated (`fit_class_gate_DATA.csv`).
- **C2 parameter intervals:** alpha 0.299 to 0.844; beta 0.0190 to 0.145, with 0.4% of draws at a bound. No parameter pair is correlated above |0.95| (`fit_bootstrap_bounds`, `fit_bootstrap_cor`).
- **Grid edge.** The full-data pair for C2 and C3 sits on the grid edge. The registered extension (r_lo 0.4, r_hi 1.15) still picks 0.5/1.0 and still selects C2 (`fit_gridext_threshold_pairs`, `fit_gridext_selection_record.txt`).

## Step 4: C2 on every frame except the sealed set

Sources: `score4_*_DATA.csv`. All mefia_ph_c results carry the "previously inspected" label.

**V1, survivors in heavy and intermediate stands, observed over predicted (paired plot bootstrap 95%):**

| d / Dq | Trees | C2 | 14.1 | A0 | Gated | Pass |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| below 0.6 | 1,626 | 1.215 (1.143 to 1.286) | 1.176 | 1.217 | no | n/a |
| 0.6 to 0.85 | 949 | 1.084 (1.011 to 1.159) | 1.145 | 1.275 | yes | yes |
| 0.85 to 1.15 | 1,224 | 0.950 (0.886 to 1.019) | 1.064 | 1.301 | yes | yes |
| 1.15 to 1.5 | 1,818 | 0.934 (0.874 to 0.991) | 0.918 | 1.299 | yes | yes |
| above 1.5 | 3,982 | 0.867 (0.831 to 0.903) | 0.565 | 1.198 | yes | **no** |

C2 removes most of 14.1's overshoot above 1.5, raising the ratio from 0.565 to 0.867, but it still overpredicts there by more than the 0.10 margin. C5's ratio below 0.6 is not available, because C5 was not run in the engine.

**Other gates, at tol 25%:**
- **V1-L** (light and low volume, worsening against 14.1): fails at 0.6 to 0.85 (upper limit 0.052) and at 0.85 to 1.15 (0.111) (`score4_v1l_DATA.csv`).
- **P1-S:** fails. 0.187 against a tolerance of 0.183; without the class below 0.6, 0.193 against 0.180. 14.1 gives 0.761 and A0 gives -0.245 (`score4_p1s`).
- **P1-NW:** passes. The heavy gap of 0.800 is below both bounds, 0.908 and 1.391 (`score4_p1nw`).
- **P1** (reported): 0.800 (0.543 to 1.058), against tol 0.346; 14.1 1.391, A0 0.317.
- **P2:** passes. Intermediate gap 0.499 against 0.515 (14.1: 1.408).
- **P3:** light fails. The gap is -0.565, but the worsening upper limit of 0.996 exceeds 0.5 x tol (0.316). Low volume passes at 0.089.
- **P5:** passes, AGB bias 1.82%.
- **Tolerance sensitivity.** P2 fails at 15% and passes at 35%. P1 and light P3 fail at all three tolerances. The verdict does not change, because V1 fails first (`score4_pgates_DATA.csv`).
- **Heavy label:** "heavy AGB gap carried, attributed to I; total heavy gap 0.800". The components are I -0.500, M 0.430, R 0.035 (`score4_attribution`).
- **N0:** passes. All 16 sets with no known tst are byte-identical to frozen 14.1 (`score4_n0`).
- **N1** (leave-one-installation-out arm SELN1):
  - ctrn_c TOTVOL %RMSE 16.664 against 16.659: passes.
  - pef_c 16.547 against 16.887: passes. Split at tst 17: 13.742 against 14.979 up to 17, and 16.949 against 17.045 above 17.
  - ctrn_fl absolute bias 16.061 against 15.888: **fails** (`score4_n1`).
- **N2:** no new relation flag against 14.1's thinned grid (`score4_n2`).
- **R1:** passes. The largest excess of C2's thinned over unthinned 100 and 200 yr gross volume ratio over 14.1's is 0.0146, against 0.02, across 40 cell-ages. The harness copy reproduces the frozen thinned grid in all 20 cells (`score4_r1`, `score4_grid_harness_copy_check`).
- **R2** (reported): observed over C2 by removal intensity class is 1.007 (RF up to 0.35), 1.026 (0.35 to 0.65) and 1.117 (above 0.65) (`score4_r2_by_rf_DATA.csv`). The C3 second-thinning trace does not apply, because C3 was not selected.

## Step 5: sealed New Hampshire and Vermont set

Order followed: (a) after the selection md5, A0 and 14.1 were run, and the decomposition and open conditions were computed and md5-logged (`logs/step5_md5.txt`); (c) C2 was then run and scored once.

**Set composition:**
- 108 stands: 40 with ESI and 68 with the CSI fallback.
- Heavy stands: 16 (7 ESI, 9 CSI).
- On the 41 triples that have both inputs, ESI averages 18.73 and CSI 14.75 (cor 0.77). The fallback gives systematically lower site input.
- Source: `sealed/nhvt_ph_build_checks_DATA.csv`.

**Open conditions** (`score5a_preconditions_DATA.csv`):

| Subset | Stands | Heavy | ESI coverage | 14.1 P1-S (0.10 S_obs) | Open because |
|:--|:--:|:--:|:--:|:--:|:--|
| Overall | 108 | 16 | 0.370 | 0.342 (0.206), an overshoot | ESI coverage below 0.80; heavy stands below 30 |
| ESI | 40 | 7 | 1.000 | 0.464 (0.183) | heavy stands below 30 |
| CSI fallback | 68 | 9 | 0 | 0.248 (0.224) | ESI coverage; heavy stands below 30 |

All three subsets have 4 gated V1 classes with 30 or more trees.

**C2 scored once** (`score5c_*_DATA.csv`). The verdict is **open**. The gates that would fail are V1, V1-L, P2/P3 and P5.

| Gate | Overall | ESI | CSI fallback |
|:--|:--:|:--:|:--:|
| P1-S (tol) | -0.084 (0.206), pass | -0.082 (0.183), pass | -0.086 (0.224), pass |
| P1-NW: heavy gap vs bounds | -0.034 vs 0.505 and 0.430, pass | 0.207 vs 0.668 and 0.794, pass | -0.222 vs 0.380 and 0.147, pass |
| P1 heavy gap (reported) | -0.034 (-0.785 to 0.682) | 0.207 | -0.222 |
| P2 intermediate gap | -0.724, fail | -0.770, fail | -0.693, fail |
| P3 light gap | -2.257, fail | -1.288, fail | -2.617, fail |
| P5 AGB bias % | -6.67, fail | -4.15, pass | -7.83, fail |
| V1 above 1.5 | 0.982 (14.1 0.658) | 0.915 | 1.052 |
| V1 failing classes | 0.6 to 0.85 (1.352) | 0.6 to 0.85 (1.184) | 0.6 to 0.85 (1.604); 1.15 to 1.5 (1.109) |
| V1-L failing classes | 0.6 to 0.85 and 0.85 to 1.15 | the same | the same |

In the class above d / Dq 1.5, C2 brings survivors close to 1 on the sealed set too (0.982, against 14.1's 0.658). Below that class it underpredicts, most strongly on CSI-fallback stands.

With 7 to 16 heavy stands per subset, every heavy quantity here is weak evidence. The ESI against CSI split carries the scale difference of the two site inputs.

## Stress test (fit-level re-selection, exploratory)

Sources: `fit_<variant>_selection_record.txt`.

| Variant | Re-selection |
|:--|:--|
| Basal area increment response | H0 (no form beats C0r) |
| Symmetric control (CTRN unthinned) | H0 |
| Cap of 1.5 on r | C2 (tied with C3) |
| Dq on trees at or above 12.7 cm | C3 |
| 12.7 cm size floor | C5 (tied set C5, C2, C3) |
| Grid extended one step | C2 (pair unchanged) |

- **PEF excluded** is the primary itself, since PEF failed its link test.
- **Total P1 gated instead of P1-S:** C2's P1 of 0.800 also fails at all tolerances.
- The selection is sensitive to the response and the control: two variants give H0. This does not change the verdict, which fails at rule 3 anyway.
- Engine-level gates were not re-run under the variants.

## What this means for 14.3

A release that saturates above d / Dq 1.0 (C2) fits CTRN better than 14.1's (d / Dq)^2. It is the only shape family, with C3, that passes the fit-set class gate. On post-harvest FIA it cuts 14.1's overshoot of large residual trees by about two thirds: the ratio above 1.5 moves from 0.565 to 0.867 on mefia_ph_c and from 0.658 to 0.982 on the sealed set. It also cuts the heavy gap from 1.391 to 0.800.

It still overpredicts the largest relative sizes on mefia_ph_c, and it underpredicts mid-size survivors in light stands. 14.3 therefore keeps 14.1's T, and C2 is the documented best form.

The sealed confirmation is open for structural reasons: low ESI coverage and few heavy stands. Most of the remaining excess at d / Dq above 1.5 sits outside the CTRN support, where fewer than 1% of fit records lie, so behavior there is a prior choice.

## Deviations (full list in the DEVIATIONS file)

1. **CSI fallback (your decision).** Source: ClimateNA_SI_m.tif, entered directly in metres. Used for 68 of 108 sealed stands.
2. **PEF link-rule reading** fixed before the count; PEF was excluded.
3. **Dry runs used real inputs** for the frame scripts.
4. **Bridge outage.** The run spanned an outage of the laptop bridge, from about 06:34 to 17:46 EDT. No job was affected: the fit ended normally at 06:35, and all arrays completed.
5. **Step 4 SELN1 omitted at first.** The first step 4 task map left out the SELN1 arm. score4's first run stopped with no output. SELN1 was added, score4 was revised so that N0 skips the sealed directory, and the md5 was re-recorded before the run that counts.
6. **score5 parse failure.** score5's first stage (a) run stopped on a parse error, with no output, and was fixed before any sealed score.
7. **long200 not run.** The 200 yr long200 mefia_l_c frame was not run for H1 or N0. No stand there has a known tst, so T never acts.
8. **Closed-loop check not scored.** The closed-loop fit-set check of C2 (SEL on ctrn_c) was run but not scored.
9. **Step 5 run after a rule 3 stop.** Step 5 was run for the report even though step 4 stopped at rule 3.
