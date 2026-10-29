# The form of the 14.1 thinning release term T beyond the PREREG2 family, for 14.3: pre-registration 3

**DRAFT, not registered.** 27 October 2026, draft 1. Written after the 14.3 PREREG2 RESULT and DEVIATIONS, and before
any PREREG3 script, frame, fit or engine run exists. This study re-estimates the shape of T in a **new arm only**. 14.1's
L (lambda 1.14863) and 14.1's T stay untouched in place, and no outcome changes 14.1 [P2 header]. GT1 stays a named
failure of 14.1. Identifiers stay in `*_SERVERONLY` files, no coordinates are used, and there are no em dashes. Rates are
in Mg ha⁻¹ yr⁻¹ and diameter increments in cm yr⁻¹. Open choices are listed at the end, recommended option first.

## Sources (every number below cites one of these)

All paths are in the worktree `~/fvsacd_fetch_20261026/wt_autopilot` on Cardinal (`holoros/fvs-acd`, branch
`v142-autopilot-20261026`, commit 4014cde).

| Tag | File |
|:--|:--|
| P2 | `docs/v14.3/2026-10-26_v143_T-form-reestimation_PREREG2.md` (revision 5, registered) |
| R2 | `docs/v14.3/run_v143p2/2026-10-27_v143_T-form-reestimation_RESULT.md` |
| D2 | `docs/v14.3/run_v143p2/2026-10-27_v143-prereg2_DEVIATIONS.md` |
| V1F | `docs/v14.3/run_v143p2/out/score4_v1_DATA.csv` |
| LR | `docs/v14.3/run_v143p2/out/score4_level_reading_DATA.csv` (same_side FALSE, range 0.217344538014749, reading "form") |
| SUP | `docs/v14.3/run_v143p2/out/frame_fitset_support_DATA.csv` |
| S5A | `docs/v14.3/run_v143p2/out/score5a_preconditions_DATA.csv` |
| SB | `docs/v14.3/run_v143p2/sealed_SERVERONLY/nhvt_ph_build_checks_DATA.csv` (aggregate columns only are cited) |
| FST | firebreather `~/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv`, md5 184dc76888580de7c2cfdb7e2ec8580f |
| RN | `scripts/v14.2dev/2026-10-27/release-notes/2026-10-27_fvs-acd-v14.2_release-notes_DRAFT.md`, "Open items" |

## What is known before this plan (previously inspected)

1. **PREREG2 selected C2 and did not adopt it (rule 3).** C2 is exp(−beta tst) times a smoothstep in r = d / Dq from
   0.5 to 1.0, flat above 1.0; full-data alpha 0.5477, beta 0.0624 [R2]. On mefia_ph_c, C2 fails V1 above r 1.5 at 0.867
   (0.831 to 0.903), against 0.565 under 14.1 [R2, V1F]. It also fails P1-S (0.187 against 0.183), P3 light, N1
   (ctrn_fl bias) and V1-L [R2].
2. **The residual is form, not level.** C2's V1 ratios at r ≥ 0.6 are 1.084, 0.950, 0.934 and 0.867 [V1F]. They do not lie
   on one side of 1, and their range is 0.217 [LR], above PREREG2's 0.10 level reading bound [P2]. C2 under predicts the
   0.6 to 0.85 class and over predicts from 0.85 up, most above 1.5. Without T (A0) the same classes read 1.275, 1.301,
   1.299 and 1.198 [V1F]. Read together (an inference from these ratios, not a test), the release the data ask for is about level
   through r 1.5 and smaller above it, while C2 gives its full release above r 1.0, so a shape whose release falls at
   large r is the next family to test. These ratios also motivate the forms below, which is why mefia_ph_c can no
   longer gate adoption (choice 1).
3. **The CTRN fit set cannot identify the tail.** 3.8% of CTRN fit records exceed r 1.5 and 1.2% exceed 1.7; the maximum
   is 2.985 [SUP, R2]. PREREG2 found 41% of post-harvest FIA survivors above 1.5 [P2 reading 1]; on mefia_ph_c, 3,982 of
   the 9,599 V1 trees are above 1.5 [V1F, sum of n_trees]. C2's CTRN held-out class ratios at r ≥ 0.6 are 0.942, 1.033,
   0.956 and 0.929 [R2], all inside 0.10, so CTRN alone does not see the defect.
4. **The time form is settled for now.** C3 against C2 at C2's pair: −0.00039 (SE 0.00052), so HL was not supported [R2].
   This plan keeps exp(−beta tst).
5. **The selection was sensitive to response and control.** The basal area increment response and the symmetric control
   each re-selected H0 [R2, stress test].
6. **Removal intensity.** Observed over C2 by removal intensity class is 1.007 (RF up to 0.35), 1.026 (0.35 to 0.65) and
   1.117 (above 0.65) [R2, R2 by RF].
7. **The sealed NH and VT set was open and is no longer sealed.** It held 108 stands, 16 heavy, ESI coverage 0.370, with
   68 of 108 on the climate site index fallback [R2, SB, S5A]; the ESI v8 raster ends at 71.5 W [D2 item 1]. Both
   registered open conditions held (ESI coverage below 0.80, heavy stands below 30) [S5A]. C2 was then scored there once
   for the report (V1 above 1.5: 0.982; failing class 0.6 to 0.85 at 1.352) [R2, D2 item 17]. Those 108 stands are
   **previously inspected** for this study.
8. **Which sets are inspected.** CTRN (fit set of PREREG2), mefia_ph_c (previously inspected in PREREG2, and its class
   pattern motivates this plan), and the NH and VT set (fact 7). No set with post-harvest survivor growth is unread.

## Hypotheses

- **HS, class shape.** A release whose shape in r rises, then declines above a relative size (forms T1, T2, T4), beats
  the PREREG2 family's best form (C2 refitted, reference T0c) by the selection margin, and passes V1 on an unread
  confirmation set.
- **HV2, source level.** The mid class under prediction is a CTRN against FIA level difference, not shape. Tested only
  by the diagnostic form TL (not adoptable, since it would act on L's domain). If TL beats every shape form by the
  selection margin, the report routes the question to an L or A0 study and adopts nothing.
- **H0.** No shape form beats T0c by the margin; 14.3 keeps 14.1's T and C2 stays the documented best form [R2].

## Fit set [choice 1]

- **Recommended:** CTRN T_post records exactly as PREREG2's frame selects them (46,521 records, 17 installations [R2])
  **plus** mefia_ph_c survivors in heavy and intermediate stands. mefia_ph_c then moves from "previously inspected
  validation set" to **fit data**, and no gate is ever read on it again; only the new confirmation set gates adoption.
  This is the only option that puts records above r 1.5 into the fit (fact 3).
- PEF stays excluded: it failed the registered 80% link rule at 0.795 [R2].
- mefia_ph_c tst is known only to the remeasurement interval [P2 reading 4], so beta is estimated on CTRN only and fixed
  for the mefia_ph_c likelihood; alpha and the shape parameters are estimated jointly [choice 1, no record].

## Candidate forms (new arm; fixed before any fit)

m_T = 1 + alpha · exp(−beta tst) · g(r), r = d / Dq, Dq and size floor as 14.1 (no floor; Dq over all records [R2]).
Every g is at least 0, so m_T never falls below 1, as in PREREG2 [P2].

| Form | g(r) | Free parameters | Role |
|:--|:--|:--|:--|
| T0f | 14.1's T frozen | none | reference (14.1) |
| T0c | C2: smoothstep r_lo to r_hi, flat above | alpha, beta, pair | reference (PREREG2 best, refitted on the new fit set) |
| T1 | C2 up to r_d, then max(g_min, 1 − delta (r − r_d)) | alpha, beta, delta, g_min, pair, r_d | rise, plateau, linear decline |
| T2 | exp(−(ln(r / r_m))² / (2 s²)) | alpha, beta, r_m, s | log normal hump |
| T4 | C2 times min(1, (r_d / r)^kappa) | alpha, beta, kappa, pair, r_d | rise, plateau, power decline |
| T3 | one level c_k in [0, 1] per PREREG2 d / Dq class (five classes), the largest fixed at 1 so that alpha carries the level | alpha, beta, four free c_k | **diagnostic only**: the saturated shape, to show how much shape is left; never selected |
| TL | C2, with the whole predicted increment of every FIA record multiplied by (1 + k_FIA), at every r including below r_lo | alpha, beta, pair, k_FIA | **diagnostic only** (HV2): acts outside T, so it is never selected or adopted |

**Grids.** (r_lo, r_hi) from PREREG2's grid plus its registered extension: r_lo in {0.4, 0.5, 0.6, 0.7}, r_hi in
{0.75, 0.85, 1.0, 1.15} [P2, R2 grid extension]. r_d in {1.0, 1.15, 1.5} [choice 2, no record]. Pairs and r_d are chosen
inside each CV training fold by inner fit error, as PREREG2 chose its pair [P2]; each grid value counts as a parameter.

**Bounds (registered).** alpha in [0, 2] and beta in [0.005, 1] yr⁻¹ [P2]; kappa in [0, 4] (PREREG2's gamma bound [P2]);
delta in [0, 2], g_min in [0, 1], r_m in [0.3, 3], s in [0.1, 3] [choice 2, no record].

**Identification.** Above r 1.7 the CTRN share is 1.2% [SUP]; with choice 1 (a) the tail is carried by mefia_ph_c, and
the report states that the tail estimate is an FIA estimate. A form with more than 5% of bootstrap draws at a bound is
ineligible, and parameter pairs with |r| above 0.95 are flagged [P2].

## Selection (fit set only; no confirmation path opened)

PREREG2's procedure, with the changes forced by the new fit set:

1. **CV.** CTRN: leave one installation out (17 folds) [P2]. mefia_ph_c: plots grouped into 10 folds by a seeded random
   draw (seed 20261027) [choice 3, no record]. Metric: expansion weighted MSE of interval diameter increment, pooled
   across both sources with each source weighted to half [choice 3, no record]; SE by the cluster weighted formula of
   D2 item 6.
2. **Fit set class gate.** Held-out observed over predicted within 0.10 of 1 in every d / Dq class at or above 0.6 with
   30 or more records, on CTRN and on mefia_ph_c separately [P2 class gate and V1 margin]. On mefia_ph_c this gate is not
   independent of the form list (fact 2); it screens forms, it does not confirm them.
3. **Eligibility.** Passes 2, passes the bound check, and beats T0c by more than one SE of the paired CV difference.
4. **Tie and parsimony.** Lowest CV among eligible; all within one fold SE tied; fewest parameters, then the order T2, T4,
   T1 [choice 4, no record].
5. If none is eligible: H0. T3 and TL are reported beside the result and never change it.

The selection record (form, coefficients, CV table) is written and its md5 logged before any candidate prediction on the
confirmation set.

## Confirmation set (the fix for PREREG2's open sealed set) [choice 5]

**Registered floors, all from PREREG2 rule 7 (b) [P2]:** at least 30 heavy stands, ESI coverage at least 0.80, and at
least 3 gated V1 classes with 30 or more survivor trees. A confirmation set that misses any floor makes the verdict
"open" before any candidate is run there.

**Exclusions.** The 108 NH and VT stands scored in PREREG2 (fact 7) and every mefia_ph_c stand interval are excluded
[choice 6]. A later remeasurement interval of a plot in either set counts as new data but carries the label "same plots,
new interval" in the verdict.

**Candidate sources, to be checked in step 2 (none is asserted to qualify):**
1. Maine post-harvest FIA remeasurements whose v2 visit postdates the mefia_ph_c frame. Check: the year range of
   mefia_ph_c and the latest Maine FIADB evaluation on the host; heavy count under PREREG1 rule 7; ESI v8 coverage
   (checked against the raster's extent [D2 item 1], not assumed).
2. New Hampshire plots east of 71.5 W from FIA visits later than the PREREG2 set. Check the same three counts; they
   would be new visits, not the inspected 108.
3. New Brunswick permanent sample plots with a recorded harvest and a later remeasurement. Check: harvest coding, a way
   to date the harvest (tst), removal intensity, and ESI v8 coverage in New Brunswick.
4. Quebec MAGPlot stands carrying the PREREG19 cut flag: FST lists 65 cut qc_c stands and 11 cut qc_fl stands [FST].
   Check whether the cut precedes t1 (only those are post-harvest residual stands; a cut inside the interval is not),
   whether tst and removal intensity are recoverable, and ESI coverage in Quebec.
5. An ESI surface west of 71.5 W. This would raise ESI coverage on NH and VT stands but not the heavy count, so it is a
   complement to sources 1 to 4, not a fix on its own.

**Read restriction (as PREREG2's sealed set [P2]).** Before the selection md5, step 2 may read only: stand counts by
harvest class and source, ESI coverage, and survivor tree counts by d / Dq class at v1 (status only, no growth). No A0,
14.1 or candidate prediction, no gap and no survivor ratio is computed on it before the selection md5. Each read is
logged in an allowlist, as PREREG2 gate H6 [P2].

## Gates

**On the confirmation set, read once, in the PREREG2 step 5 order [P2]:** (a) A0 and 14.1 runs and the decomposition with
its identity check; (b) the open conditions above, plus "open" if 14.1's P1-S there is not an overshoot [P2 rule 7 (b)];
(c) the selected form, run and scored once.

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| V1 | survivors in heavy and intermediate stands, every class at r ≥ 0.6 with 30 or more trees | point estimate within 0.10 of 1 | [P2] |
| V1-L | light and low volume, worsening against 14.1 | paired 95% upper limit at most 0.05 | [P2] |
| P1-S | heavy survivor growth, mean over heavy stands of S | absolute value at most 0.10 times the mean of S_obs | [P2] |
| P1-NW | total heavy gap | no worse than both set-specific bounds | [P2] |
| P2, P3 | intermediate and light gaps | tol 25%, as PREREG1 | [P2] |
| P5 | AGB bias | within ±5% | [P2] |
| Labels | P gates also read at 15% and 35% | "tolerance sensitive" if the verdict changes | [P2] |

**No harm, on the inspected sets (step 4):** N0 (sets with no known tst equal 14.1 exactly), N1 (ctrn_c and pef_c %RMSE no
worse by more than 0.5 points; ctrn_fl absolute bias no larger), N2 (no new Bakuzis relation flag on the 20 cell thinned
grid), R1 (no cell's thinned over unthinned 100 and 200 yr gross production ratio above 14.1's by more than 0.02), all as
PREREG2 [P2]. C2 failed N1 on ctrn_fl bias (16.061 against 15.888) [R2]; a shape form must clear it.

**Reported, not gated:** V1 on mefia_ph_c (in sample under choice 1 (a)); V1 by removal intensity class (fact 6); the
class below r 0.6, which T cannot lower [P2 reading 2].

## Harness gates

PREREG2's E0, CAP, TR, K1, TH and H2 to H6 carry over [P2], with a new overlay `AcadianGY_14.3dev_Tshape.r`, sourced
after 14.1, which replaces only `.acd_v141_mT` when switched on and is the identity when off.

- **H1.** Overlay off, and T0f with the overlay on, reproduce frozen 14.1 byte for byte on every frame [P2 H1].
- **H1b.** The new overlay set to C2 with PREREG2's full-data coefficients (alpha 0.5477, beta 0.0624, pair 0.5 and 1.0
  [R2]) reproduces PREREG2's SEL outputs on mefia_ph_c (run under the PREREG2 overlay) byte for byte, and so its V1 above
  r 1.5 of 0.867 [V1F] [tolerance: exact equality, choice, no record]. This is a harness check of the new overlay only,
  and reads no new quantity.
- **H4.** TR trace per form, including the T1 and T4 kinks at r_d and T2 at small r [P2 H4].
- **H6.** No candidate prediction on the confirmation set before the selection md5; an allowlist of step 2 reads [P2 H6].
- **H7.** The confirmation set build log shows no stand from the excluded lists (fact 7, mefia_ph_c), checked on
  server-only keys.

## Decision rule, in order

1. Any harness gate fails: no verdict.
2. The fit set selects no form: H0. 14.3 keeps 14.1's T; C2 stays the documented best form.
3. TL beats the selected form by more than one SE of their paired CV difference: not adopted; HV2 reported and routed to
   an L or A0 study.
4. Any no harm gate (N0, N1, N2, R1) fails: not adopted; the trade off is reported.
5. The confirmation set misses a registered floor: "open". The form is the documented best form, not adopted.
6. On the confirmation set, V1 fails in any gated class: "not confirmed", failing classes named.
7. P1-S, P1-NW, P2, P3, P5 or V1-L fails there: "not confirmed", failing gate named; the heavy decomposition attributes
   the gap.
8. All pass: a 14.3 candidate, labeled "tail estimated from FIA" under choice 1 (a), with any edge or tolerance label.

## Stress test (selected form held fixed; re-selection exploratory)

Basal area increment response; the symmetric control (fact 5); CTRN only fit (choice 1 (c)); Dq on trees at or above
12.7 cm; the 12.7 cm floor; mefia_ph_c weighted as its record share instead of half; r_d grid extended one step if the
pick sits on an edge. A headline at the favorable end of its range is flagged [P2].

## Execution

Cardinal, `~/v143p3/` (a new directory), as PREREG2 ran on Cardinal [R2]; firebreather if Aaron names it. This plan's md5
is logged before any script runs. The chain:

1. scripts, red team, dry run (fitter on a 5 installation subset with 40 draws so that no full-data selection is seen, as
   D2 item 3), launch md5s;
2. frame step: the joint fit frame, the source checks of the confirmation set and its build under the read restriction,
   H7, its md5 logged before any fit;
3. fit, identifiability, CV and selection; selection record md5;
4. the selected form on every inspected frame (no harm gates), scoring;
5. confirmation set, stages (a) to (c).

## Open choices (recommended option first)

1. **Fit set.**
   (a) CTRN plus mefia_ph_c heavy and intermediate survivors; beta from CTRN only; mefia_ph_c never gated again.
   (b) CTRN only, with the tail above r 1.5 fixed by a registered prior (for example g at 1.5 and above set from
   PREREG2's mefia_ph_c ratios), stated as a prior choice.
   (c) CTRN only, free. Not recommended: fact 3 says it cannot see the defect.
2. **Grid and bounds for the new parameters** (r_d, delta, g_min, r_m, s).
   (a) As written, with an edge flag and a one step extension as PREREG2 [P2].
   (b) A wider r_d grid {0.85, 1.0, 1.15, 1.5, 1.7}.
3. **CV on mefia_ph_c and source weighting.**
   (a) 10 seeded plot folds; the two sources weighted to half each.
   (b) Plot folds with sources weighted by record count.
4. **Parsimony order among tied forms.**
   (a) T2 (4 parameters, no grid), T4, T1.
   (b) Fewest parameters only, ties broken by CV.
5. **Confirmation set.**
   (a) Pool whichever of sources 1 to 4 pass their checks, and register the step 5 run only if the pooled build meets all
   three floors; otherwise the verdict is "open" before step 5.
   (b) Use one source alone only if it meets the floors by itself.
   (c) Wait for the next Maine FIA remeasurement cycle.
6. **The 108 inspected NH and VT stands.**
   (a) Excluded from confirmation; reported as a replication of PREREG2.
   (b) Included, with the verdict labeled "partly previously inspected".
7. **Removal intensity.**
   (a) Reported only (fact 6), not a candidate term.
   (b) Add a form with alpha varying by removal intensity class, as a fourth eligible form.

## Response to draft red team 1 (27 October 2026, self review in a fresh read)

| Item | Change |
|:--|:--|
| Circularity: the forms are written from mefia_ph_c's class pattern | mefia_ph_c moved to the fit set under choice 1 (a) and never gated; its fit set class gate labeled a screen, not a confirmation |
| Circularity: the NH and VT set was scored under C2 | The 108 stands excluded from confirmation (choice 6); later intervals of the same plots labeled |
| TL could not express a level difference below r_lo | TL redefined as a whole increment multiplier on FIA records, outside T, diagnostic only |
| H1b read as a new fit | H1b fixed to PREREG2's C2 coefficients under the new overlay; harness only |
| P1-S threshold wording | Written as PREREG2 defines it (absolute mean S at most 0.10 times mean S_obs) |
| The "release level through 1.5" sentence read as a finding | Labeled an inference from the A0 ratios |
| Unsourced geography of the ESI edge | Replaced by a check against the raster extent |
| Stress variant and choice labels | CTRN only stress variant points to choice 1 (c); removal intensity form counted correctly |
