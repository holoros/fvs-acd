# The form of the 14.1 thinning release term T beyond the PREREG2 family, for 14.3: pre-registration 3 (revision 1)

**Revision 1, 28 October 2026.** Built from draft 1 (27 October 2026, md5 72c9c7e43af1fa6c0b77b391782df2b5). Aaron
pre-approved every open choice of draft 1 at its recommended option; revision 1 records those answers, the confirmation set
counts of step 1 (counted before this revision was written, without reading any outcome), the implementation readings
that the draft left open, and the response to one red team round (fresh read, self review). The registration line, with
this file's md5 and time, is in `~/v143p3/logs/prereg_md5.txt`. Nothing in steps 2 to 5 has been run. Revision log and red
team table are at the end.

This study re-estimates the shape of T in a **new arm only**. 14.1's L (lambda 1.14863) and 14.1's T stay untouched in
place, no engine file, coefficient or default of 14.1 is edited, and no outcome changes 14.1 [P2 header]. GT1 stays a named
failure of 14.1. Identifiers stay in `*_SERVERONLY` files; coordinates are used on the server only to extract site values;
there are no em dashes. Rates are in Mg ha⁻¹ yr⁻¹ and diameter increments in cm yr⁻¹.

## Sources (every number below cites one of these)

PREREG2 files are read from Cardinal `~/v143p2/` and were copied, unedited, to `~/v143p3/p2ref/` (md5s in
`~/v143p3/logs/p2ref_copy_md5s.txt`). The draft's worktree paths name the same files.

| Tag | File |
|:--|:--|
| P2 | `p2ref/plan/2026-10-26_v143_T-form-reestimation_PREREG2.md` (revision 5, md5 b7562e8b, registered) |
| R2 | `p2ref/plan/2026-10-27_v143_T-form-reestimation_RESULT.md` |
| D2 | `p2ref/plan/2026-10-27_v143-prereg2_DEVIATIONS.md` |
| V1F | `p2ref/out/score4_v1_DATA.csv` |
| LR | `p2ref/out/score4_level_reading_DATA.csv` (same_side FALSE, range 0.217344538014749, reading "form") |
| SUP | `p2ref/out/frame_fitset_support_DATA.csv` |
| S5A | `p2ref/out/score5a_preconditions_DATA.csv` |
| FF2 | `p2ref/out/fit_full_fits_DATA.csv` (C2: alpha 0.54768802, beta 0.062357835, pair 0.5/1) |
| SB | `~/v143p2/sealed_SERVERONLY/nhvt_ph_build_checks_DATA.csv` (aggregate columns only are cited) |
| FST | firebreather `~/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv`, md5 184dc76888580de7c2cfdb7e2ec8580f |
| CF1 | `~/v143p3/out/conf_fb/conf_fia_counts_DATA.csv` (md5 0511b027) and `conf_fia_survivors_DATA.csv` (md5 eef80841), written on firebreather by `v143p3_conf_fia.R` |
| CF2 | `~/v143p3/out/conf_nbqc_counts_DATA.csv` (md5 4073c955), `conf_nbqc_survivors_DATA.csv` (md5 e94b17db), `conf_esi_surfaces_DATA.csv` (md5 8b4c06c9), written by `v143p3_conf_nbqc.py` |
| CP | `~/v143p3/out/conf_pooled_DATA.csv` (md5 c9d9e406961433bc9735019ae1de11ab, logged in `logs/conf_counts_md5.txt` at 2026-10-28T05:57:52-0400) |

## What is known before this plan (previously inspected)

1. **PREREG2 selected C2 and did not adopt it (rule 3).** C2 is exp(−beta tst) times a smoothstep in r = d / Dq from
   0.5 to 1.0, flat above 1.0; full-data alpha 0.5477, beta 0.0624 [R2, FF2]. On mefia_ph_c, C2 fails V1 above r 1.5 at
   0.867 (0.831 to 0.903), against 0.565 under 14.1 [R2, V1F]. It also fails P1-S (0.187 against 0.183), P3 light, N1
   (ctrn_fl bias) and V1-L [R2].
2. **The residual is form, not level.** C2's V1 ratios at r ≥ 0.6 are 1.084, 0.950, 0.934 and 0.867 [V1F]. They do not lie
   on one side of 1, and their range is 0.217 [LR], above PREREG2's 0.10 level reading bound [P2]. Without T (A0) the same
   classes read 1.275, 1.301, 1.299 and 1.198 [V1F]. Read together (an inference from these ratios, not a test), the
   release the data ask for is about level through r 1.5 and smaller above it, while C2 gives its full release above
   r 1.0, so a shape whose release falls at large r is the next family to test. These ratios motivate the forms below,
   which is why mefia_ph_c can no longer gate adoption (choice 1).
3. **The CTRN fit set cannot identify the tail.** 3.8% of CTRN fit records exceed r 1.5 and 1.2% exceed 1.7; the maximum
   is 2.985 [SUP, R2]. On mefia_ph_c, 3,982 of the 9,599 V1 trees are above 1.5 [V1F, sum of n_trees]. C2's CTRN held-out
   class ratios at r ≥ 0.6 are 0.942, 1.033, 0.956 and 0.929 [R2], all inside 0.10, so CTRN alone does not see the defect.
4. **The time form is settled for now.** C3 against C2 at C2's pair: −0.00039 (SE 0.00052), so HL was not supported [R2].
   This plan keeps exp(−beta tst).
5. **The selection was sensitive to response and control.** The basal area increment response and the symmetric control
   each re-selected H0 [R2, stress test].
6. **Removal intensity.** Observed over C2 by removal intensity class is 1.007 (RF up to 0.35), 1.026 (0.35 to 0.65) and
   1.117 (above 0.65) [R2].
7. **The NH and VT set of PREREG2 is previously inspected.** It held 108 stands, 16 heavy, ESI coverage 0.370 [R2, SB,
   S5A]; the ESI v8 raster ends at 71.5 W [D2 item 1]. C2 was scored there once for the report [R2, D2 item 17].
8. **Which sets are inspected.** CTRN (fit set of PREREG2), mefia_ph_c (previously inspected; its class pattern motivates
   this plan), and the 108 NH and VT stands (fact 7).

## Step 1 result: the confirmation set, counted before registration

The five candidate sources of draft 1 were checked under the draft's read restriction (stand counts by harvest class and
source, ESI coverage, survivor tree counts by d / Dq class at v1, status only; no growth, prediction, gap or ratio). Each
script wrote an allowlist of its reads. PREREG1 rule 7 definitions were applied exactly as `v143p2_sealed_build.R`
applies them. New FIA data are visits with v2 in 2025 or later in the firebreather FIADB download of 26 September 2026;
both excluded frames were built from Cardinal FIADB files whose latest visit is 2024, so no new stand can be an excluded
stand, and no identifier moved between hosts (gate H7 by construction). As a check of the builder copy, the same script
on the same download, restricted to v2 at or before 2024, returns 827 Maine stands with 221 heavy, the mefia_ph_c frame's
own counts [CF1; R2 decomposition table, 221 heavy stands; P2, 827 stands].

| Source | Qualifying stands | Heavy (rule 7) | ESI coverage | Note |
|:--|:--:|:--:|:--:|:--|
| 1 Maine FIA, v2 after the mefia_ph_c frame | 31 | 10 | 1.000 | 9 are "same plots, new interval" [CF1] |
| 2 New Hampshire FIA, visits after the PREREG2 set | 6 | 0 | 0.667 (4 of 6) | [CF1] |
| 3 New Brunswick plots, MAGPlot NB CLI | 111 with a treatment before v1 and none inside | no rule 7 class | 1.000 | no site has a third visit, so no tree-linked removal at v0 [CF2] |
| 3 New Brunswick plots, NB NFI ground plots | 11 | not classed (5 have a third visit) | 1.000 | carried as an upper bound of 5 heavy [CF2, CP] |
| 4 Quebec MAGPlot cut flag | 0 | 0 | n/a | the PREREG19 flag is a cut with treatment_year > Y1 and ≤ Y2, inside the interval, so no flagged stand has its cut before t1 [CF2; FST script `cut_stands()`] |
| 5 ESI surfaces west of 71.5 W | n/a | n/a | n/a | Acadian ESI v8 30 m ends at 71.5 W; continental surfaces exist (NorthAmerica_ESI_v8 at 0.0257°, ESI v7 CONUS 30 m, ESI v8 CONUS 1 km), a complement only [CF2] |

**Pooled under choice 5 (a)** (sources whose checks pass: 1 and 2): 37 stands, **10 heavy**, ESI coverage 0.946, and
**3 gated V1 classes** with 30 or more survivor trees in heavy and intermediate stands (14, 38, 54 and 112 trees in the
classes 0.6 to 0.85, 0.85 to 1.15, 1.15 to 1.5 and above 1.5) [CP]. With the 5 NB NFI stands counted as heavy and
covered, the upper bound is 15 heavy stands [CP]. **The heavy floor (30) is missed under every pooling, so by the
registered rule the confirmation verdict is "open" before any candidate is run there.**

## Hypotheses

- **HS, class shape.** A release whose shape in r rises, then declines above a relative size (forms T1, T2, T4), beats
  the PREREG2 family's best form (C2 refitted, reference T0c) by the selection margin.
- **HV2, source level.** The mid class under prediction is a CTRN against FIA level difference, not shape. Tested only
  by the diagnostic form TL (not adoptable). If TL beats the selected form by the margin, the report routes the question to
  an L or A0 study and adopts nothing.
- **H0.** No shape form beats T0c by the margin; 14.3 keeps 14.1's T and C2 stays the documented best form [R2].

## Fit set (choice 1 (a))

- CTRN T_post records exactly as PREREG2's frame selects them (46,521 records, 17 installations [R2]), read from
  `~/v143p2/work/fitframe_SERVERONLY.rds` (md5 a382ee8e970ff899e84e08127a20d7ce), **plus** the mefia_ph_c V1 survivor
  population of PREREG2's scorer in heavy and intermediate stands (trees with fate "surv" in the frozen A0 decomposition
  `~/v143p2/work/decomp_mefia_ph_c_SERVERONLY.rds`, md5 ab4b52789ce9424e8ea16a6f12f9090e, in the scorer's stand population),
  restricted to stands with a known tst, since T does not act on a stand without one. Each mefia_ph_c record carries
  d1 and e (the scorer's v1 diameter and summed v1 expansion), the observed v2 diameter, the interval, the stand's engine
  Dq and the A0 engine's first annual step increment G1 from the frozen PREREG1 A0 dumps, built by PREREG2's
  `engine_base()` rule [D2 items 4 and 5]. mefia_ph_c moves from "previously inspected validation set" to **fit data**;
  no gate is read on it again except the fit-set class gate, which is a screen.
- PEF stays excluded: it failed the registered 80% link rule at 0.795 [R2].
- **beta is estimated on CTRN only** and fixed for the pooled fit (mefia_ph_c tst is known only to the remeasurement
  interval [P2 reading 4]); alpha and the shape parameters are estimated jointly (implementation in "Fitting").

## Candidate forms (new arm; fixed before any fit)

m_T = 1 + alpha · exp(−beta tst) · g(r), r = d / Dq, Dq and size floor as 14.1 (no floor; Dq over all records [R2]).
sm(r) is PREREG2's smoothstep from r_lo to r_hi, flat at 1 above r_hi [P2]. Every g is at least 0, so m_T ≥ 1.

| Form | g(r) | Free parameters (count) | Role |
|:--|:--|:--|:--|
| T0f | 14.1's T frozen | none | reference (14.1), CV reported |
| T0c | sm(r) | alpha, beta, pair (4) | reference (PREREG2 best, refitted on the new fit set) |
| T1 | sm(r) · max(g_min, 1 − delta · max(0, r − r_d)) | alpha, beta, delta, g_min, pair, r_d (7) | rise, plateau, linear decline |
| T2 | exp(−(ln(r / r_m))² / (2 s²)) | alpha, beta, r_m, s (4) | log normal hump |
| T4 | sm(r) · min(1, (r_d / r)^kappa) | alpha, beta, kappa, pair, r_d (6) | rise, plateau, power decline |
| T3 | c_k by PREREG2 d / Dq class (five classes), c fixed at 1 in 0.85 to 1.15, the other four free in [0, 3] | alpha, beta, four c_k (6) | **diagnostic only**, never selected |
| TL | sm(r), and every mefia_ph_c predicted increment multiplied by (1 + k_FIA) at every r | alpha, beta, pair, k_FIA (5) | **diagnostic only** (HV2), never selected or adopted |

**Grids.** (r_lo, r_hi): r_lo in {0.4, 0.5, 0.6, 0.7}, r_hi in {0.75, 0.85, 1.0, 1.15} (16 pairs) [P2, R2 grid
extension]. r_d in {1.0, 1.15, 1.5} (choice 2 (a)). The grid cell is chosen inside each CV training fold by the fold's
stage B objective, as PREREG2 chose its pair [P2]; each grid value counts as a parameter. A full-data pick on a grid edge
(r_lo 0.4, r_hi 1.15, r_d 1.0 or 1.5) carries an edge flag, and an r_d pick at 1.5 triggers the one step extension
(r_d 1.7) as a stress variant (choice 2 (a)).

**Bounds (registered).** alpha in [0, 2] and beta in [0.005, 1] yr⁻¹ [P2]; kappa in [0, 4] [P2 gamma bound]; delta in
[0, 2], g_min in [0, 1], r_m in [0.3, 3], s in [0.1, 3] (choice 2 (a)); c_k in [0, 3] and k_FIA in [−0.5, 1] (revision 1,
red team item 3 and 4).

**Identification.** Above r 1.7 the CTRN share is 1.2% [SUP]; the tail is carried by mefia_ph_c, and the report states
that the tail estimate is an FIA estimate. A form with more than 5% of bootstrap draws at a bound (within 1e-5) is
ineligible, and parameter pairs with |r| above 0.95 are flagged [P2, D2 item 7].

## Fitting (implementation readings, fixed here)

- **Response and prediction** as PREREG2: interval diameter increment, open loop integration of annual steps,
  d_{k+1} = d_k + G1 · m_T(tst + k, d_k / Dq), yhat = (d_iv − d1) / iv [D2 item 4]; TL multiplies the mefia_ph_c yhat by
  (1 + k_FIA).
- **Objective.** Q = 0.5 · SSE_C / W_C + 0.5 · SSE_F / W_F, with SSE_s = Σ w e (y − yhat)² and W_s = Σ w e over source s
  (w the bootstrap or fold weight), so each source carries half the weight (choice 3 (a)).
- **Two stages, per form and grid cell.** Stage A fits every free parameter of the form on CTRN alone (SSE_C) and keeps
  its beta. Stage B fixes beta at that value and fits the remaining free parameters on Q. The grid cell with the lowest
  stage B Q is taken. For TL, stage A is the C2 fit on CTRN (k_FIA does not act on CTRN).
- **Optimizer** as PREREG2: L-BFGS-B inside the bounds, three registered starts per form plus the full-data estimate in
  bootstrap draws [P2 fitter].

## Selection (fit set only; no confirmation path opened)

1. **CV.** CTRN: leave one installation out (17 folds) [P2]. mefia_ph_c: plots assigned to 10 folds by a seeded random
   permutation of the sorted plot keys (seed 20261027), fold = position modulo 10 (choice 3 (a)). Each of the 27 folds is
   held out once; its training set is every other record of both sources. Per source, CV_s = Σ_f W_f MSE_f / Σ_f W_f over
   that source's folds, with SE_s by the cluster weighted formula of D2 item 6. **Pooled CV = 0.5 CV_C + 0.5 CV_F, SE =
   sqrt(0.25 SE_C² + 0.25 SE_F²)**; paired differences use the same formulas on fold differences.
2. **Fit set class gate.** Held-out observed over predicted (Σ e y / Σ e max(yhat, 0.05)) within 0.10 of 1 in every
   d / Dq class at or above 0.6 with 30 or more records, on CTRN and on mefia_ph_c separately [P2]. On mefia_ph_c this gate
   is not independent of the form list (fact 2); it screens forms, it does not confirm them.
3. **Eligibility.** Passes 2 on both sources, passes the bound check, and beats T0c by more than one SE of the paired
   pooled CV difference.
4. **Tie and parsimony.** Lowest pooled CV among eligible; every eligible form within one SE of the best form's pooled CV
   is tied; fewest parameters, then the order T2, T4, T1 (choice 4 (a)).
5. If none is eligible: H0. T3 and TL are reported beside the result and never change it.

The selection record (form, coefficients, CV table) is written and its md5 logged before any further step.

**Bootstrap.** 2,000 draws, seed 20261020 [P2], clusters resampled within source (CTRN installations, mefia_ph_c plots);
the grid cell is held at the full-data pick and both stages are refitted in each draw.

## Confirmation set (choice 5 (a)) and the 108 NH and VT stands (choice 6 (a))

Registered floors, from PREREG2 rule 7 (b) [P2]: at least 30 heavy stands, ESI coverage at least 0.80, at least 3 gated V1
classes with 30 or more survivor trees. The 108 NH and VT stands and every mefia_ph_c stand interval are excluded; they
would be reported as a replication of PREREG2 only. Step 1 found the pooled set at 10 heavy stands (upper bound 15), so the
confirmation is **open by rule**, recorded before registration. Removal intensity is reported only (choice 7 (a)).

## Execution scope of this registration

Because the confirmation is open by rule, and on Aaron's instruction for this case ("still run the fit and selection
and the screen on mefia_ph_c as registered, and report"), this registration runs:

1. step 1 (done, above);
2. the frame step: the joint fit frame, its map checks, md5 logged before any fit;
3. fit, identifiability, CV, the class gate screen on CTRN and mefia_ph_c, and selection; selection record md5; then the
   fit-level stress test;
4. the reports: removal intensity on the held-out mefia_ph_c predictions of the selected form (and of T0c), T3 and TL.

**Not run in this registration, registered as the next step:** step 4 of draft 1 (the selected form in the engine on
every inspected frame: N0, N1, N2, R1, with the engine harness gates H1, H1b, H4 and the overlay
`AcadianGY_14.3dev_Tshape.r`) and step 5 (confirmation set runs). Rule 4 is therefore reported as "not evaluated".

## Gates in this registration

**Fit-level harness (rule 1):**
- **H2b.** The v143p3 fitter, run in its PREREG2 reproduction mode (C2, CTRN only, one stage, PREREG2's 9 pair grid),
  returns alpha 0.54768802, beta 0.062357835 and pair 0.5/1.0 within 1e-4 [FF2].
- **FM.** CTRN records equal PREREG2's frame (46,521); every mefia_ph_c fit record maps onto an A0 engine tree (|d1 − engine
  d0| ≤ 1e-9, G1 finite); records dropped for a non-finite G1 or an unknown tst are counted.
- **H6.** No outcome is read before the registration md5; the confirmation lookup read only its allowlist (logs above);
  no candidate prediction is made on any confirmation source.
- **H7.** No confirmation stand is in an excluded frame (by the new-data rule of step 1).

**Fit gates:** the class gate and bound check of the selection, as above.

**Reported, not gated:** held-out ratios by class for every form and source; T3's c_k; TL's k_FIA; held-out mefia_ph_c
observed over predicted by removal intensity class (RF up to 0.35, 0.35 to 0.65, above 0.65, from PREREG2's source
`~/v143p1/work/elig_quant_v143_SERVERONLY.csv`); the class below r 0.6.

## Decision rule, in order

1. Any fit-level harness gate fails: no verdict.
2. The fit set selects no form: H0. 14.3 keeps 14.1's T; C2 stays the documented best form.
3. TL beats the selected form by more than one SE of their paired pooled CV difference: not adopted; HV2 reported and
   routed to an L or A0 study.
4. No harm gates (N0, N1, N2, R1): not evaluated in this registration (engine step deferred).
5. The confirmation set misses a registered floor: "open". The form is the documented best form, not adopted.

## Stress test (selected form's choices varied; re-selection exploratory, 200 bootstrap draws each)

(a) mefia_ph_c weighted by its record share instead of half; (b) CTRN only fit (choice 1 (c)); (c) Dq on trees at or above
12.7 cm; (d) the 12.7 cm floor; (e) basal area increment response; (f) r_d extended to 1.7 if the full-data pick is at
r_d 1.5. A headline at the favorable end of its range is flagged [P2]. The symmetric control of PREREG2 is dropped: it has
no registered control for FIA records (red team item 6).

## Execution

Cardinal `~/v143p3/` (new directory), from copies of PREREG2's scripts in `~/v143p3/p2ref/`; `~/v143p2/` is read, never
edited. The chain: scripts written; dry run (fitter on a 5 installation and 50 plot subset with 40 draws into
`~/v143p3/dry/`, so that no full-data selection is seen); script md5s in `logs/launch_md5s.txt`; frame step and its md5;
fit; stress test; assembly script md5 logged before it runs; RESULT and DEVIATIONS.

## Plan gate answers (Aaron, pre-approved, recommended options)

1. Fit set: (a) CTRN plus mefia_ph_c heavy and intermediate survivors; beta from CTRN only; mefia_ph_c never gated again.
2. Grid and bounds: (a) as written, with an edge flag and a one step extension.
3. CV on mefia_ph_c and source weighting: (a) 10 seeded plot folds; sources weighted half each.
4. Parsimony order among tied forms: (a) fewest parameters, then T2, T4, T1.
5. Confirmation set: (a) pool the sources that pass; verdict open unless all floors are met.
6. The 108 inspected NH and VT stands: (a) excluded.
7. Removal intensity: (a) reported only.

## Revision log

| Revision | Date | Change |
|:--|:--|:--|
| draft 1 | 27 Oct 2026 | draft with seven open choices and a self red team (md5 72c9c7e4) |
| 1 | 28 Oct 2026 | choices resolved at the recommended options (Aaron); step 1 counts entered (confirmation open by rule); implementation readings fixed (two stage fit, pooled objective, fold scheme, pooled SE, T1 and T4 as products with sm, T3 normalization, TL bounds); execution scope set to steps 1 to 3 plus reports; harness gates restated as fit-level gates for this scope; stress test list trimmed (symmetric control dropped); red team round 1 answered |

## Response to red team round 1 (28 October 2026, fresh read of the revision 1 text, self review)

| Item | Severity | Finding | Change |
|:--|:--|:--|:--|
| 1 | MUST | Draft T1 wrote "C2 up to r_d, then max(g_min, 1 − delta (r − r_d))", which jumps when r_d is below r_hi (r_d 1.0 with r_hi 1.15) | T1 and T4 written as products with sm(r), continuous for every grid cell |
| 2 | MUST | The draft's pooled CV, its SE and the fold scheme for a joint fit were open; a choice made after seeing CV tables would be a forking path | Fold scheme, per-source CV, pooled CV and pooled SE written out before any fit |
| 3 | MUST | T3 "largest fixed at 1" with c_k in [0, 1] cannot express a release above the fixed class's, and the forms are motivated by exactly that shape | c fixed at 1 in 0.85 to 1.15, the other four in [0, 3]; T3 stays diagnostic |
| 4 | SHOULD | TL's k_FIA had no bound | k_FIA in [−0.5, 1] |
| 5 | SHOULD | The open verdict is known before registration; running the engine no-harm gates for a form that cannot be confirmed spends a large compute budget for a rule 4 or rule 5 outcome that changes nothing adopted | Execution scope stated; rule 4 reported as not evaluated; the engine step registered as the next step |
| 6 | SHOULD | The symmetric control stress variant has no defined control for FIA records | Dropped, with the reason |
| 7 | SHOULD | "beta from CTRN only" was ambiguous for forms whose CTRN fit depends on the grid cell | Stage A runs per grid cell, inside every fold and draw |
| 8 | NOTE | mefia_ph_c stands with unknown tst cannot carry T, so they cannot inform its shape | Restricted to known tst; the count is reported |
| 9 | NOTE | The step 1 lookup on firebreather printed 6 frame rows of FST, with stand keys and observed volumes, before this revision (a 14.2 arm, no PREREG3 prediction) | Logged in DEVIATIONS; the Quebec source qualifies 0 stands by the flag's definition, so no read entered a count |
| 10 | NOTE | The ESI surface table's resolution column is labelled res_m but holds degrees | Read as degrees here; logged in DEVIATIONS |
