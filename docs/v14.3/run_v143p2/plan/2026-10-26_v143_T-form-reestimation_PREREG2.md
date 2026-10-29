# The form of the 14.1 thinning release term T, for 14.3: pre-registration 2 (revision 5, registered)

Drafted 19 October 2026 on autopilot after pre-registration 1 (registered revision 1, md5 7f3e67c2; RESULT `2026-10-19_v143_thin-partial-removal_PREREG1_RESULT_REVIEW.md`). Revision 1 answered the first plan red team (7 MUST, 12 SHOULD, 7 NOTE); revision 2 answered the second (4 MUST, 7 SHOULD, 4 NOTE); revision 3 answered the third (1 MUST, 5 SHOULD, 4 NOTE); revision 4 applies the fourth round (converged: 0 MUST, 2 SHOULD, 3 NOTE). Response tables are at the end. Revision 5 (26 October 2026) records the plan gate: Aaron's instruction "resolve all open items and recommendations on autopilot" took the default of each open choice (section "Plan gate answers"). Revision 5 changes nothing else; the registration line, with its md5 and time, is in `logs/prereg_md5.txt`. Nothing in it has been run. Since revision 4, PREREG46 and the PREREG47 reading (26 October) ran on the QC height path only; neither touches T, its fit set or its validation sets, so no hypothesis or gate here changes.

Unlike PREREG1, this study **re-estimates T**. L stays at 14.1's lambda (1.14863), and GT1 stays a named failure of 14.1. No outcome changes 14.1. Identifiers stay in `*_SERVERONLY` files, no coordinates are used, and there are no em dashes. Rates are in Mg ha⁻¹ yr⁻¹ and diameter increments in cm yr⁻¹. "L only" and "A0" name the same prediction (14.1 with T off).

## What is known before any fit (exploratory, from 19 October)

All of these come from read-only exploratory runs, which are not registered. The mefia_ph_c rows were read before the candidate forms were written, so mefia_ph_c is a **previously inspected** set in this study, not a held-out one.

| Source | d / Dq class | Observed over 14.1 | Observed over A0 (L only) |
|:--|:--:|:--:|:--:|
| CTRN T fit set (46,521 records, 119 locations, 17 installations; installation bootstrap) | below 0.6 | 0.652 (0.469 to 0.982) | 0.692 |
| | 0.6 to 0.85 | 0.983 (0.783 to 1.274) | 1.121 |
| | 0.85 to 1.15 | 1.132 (0.935 to 1.329) | 1.420 |
| | 1.15 to 1.5 | 0.943 (0.819 to 1.072) | 1.332 |
| | above 1.5 | 0.775 (0.668 to 0.862) | 1.314 |
| mefia_ph_c survivors, heavy and intermediate (8,971 trees with known tst; plot bootstrap) | below 0.6 | 1.180 | 1.224 |
| | 0.6 to 0.85 | 1.149 | 1.289 |
| | 0.85 to 1.15 | 1.038 | 1.287 |
| | 1.15 to 1.5 | 0.900 | 1.296 |
| | above 1.5 | 0.545 (0.521 to 0.569) | 1.197 |

The CTRN in-sample 0.775 above d / Dq 1.5 is to be reconfirmed in the frame step with the r5 frame's own Dq and weights (step 2 below).

Four readings follow, and they set the hypotheses:

1. **On CTRN the release varies far less with relative size above d / Dq 0.85 than T assumes** (1.31 to 1.42 over A0, a spread of 0.11), while T's (d / Dq)² shape inflates the top classes. 14.1 overshoots there in sample (0.775), so part of the defect is in the fitted form, not only in extrapolation. Only 3.4% of CTRN fit records exceed 1.5 (99th percentile 1.70), against 41% of post-harvest FIA survivors.
2. **On CTRN the smallest class is short of A0 itself** (0.692). T can only raise predictions, so no T can repair it. It is an L or A0 issue and lies outside this study.
3. **On FIA, observed over A0 is flat across every class, including below 0.6** (1.20 to 1.30). That is the signature of a size-independent level difference (A0, L, or region), not of a release that starts at a threshold. The hypothesis set must be able to say so.
4. **The FIA release may build over time.** The realized share of T rises from 0.61 at tst 1 to 1.08 at tst 4. The intervals overlap, FIA tst is known only to the remeasurement interval, and harvest-year error can mimic a lag, so this is weak evidence.

## Hypotheses

- **HF, form.** A release that does not grow with relative size above a threshold (C2, C3) fits CTRN better than 14.1's T.
- **HL, lag.** A rise-then-decay time response (C3) fits better than exponential decay from tst 1, by the CV margin in the selection rule.
- **HV, level or rate.** A size-independent release (C5) or 14.1's form with only alpha refitted (C6) wins. Then the problem is level or rate, not form, and the report says so. On CTRN alone C6 should return alpha near 0.371 (H2), so C6 differs from C0 only if PEF moves alpha; C6 is not a test of the FIA attenuation on its own.
- **Registered reading of the level question on mefia_ph_c.** If the selected candidate's V1 ratios at r ≥ 0.6 all lie on the same side of 1 and their range across classes is under 0.10, the residual is read as level, not form, and reported as an L or A0 question for a later study.
- **H0.** No candidate beats C0 (14.1's T, frozen or refitted) by the selection margin. 14.3 then keeps 14.1's T and documents the overshoot as a known limit.

## Candidate forms (fixed before any fit)

The release multiplier is m_T = 1 + alpha · f(tst) · g(r), with r = d / Dq. The size floor and the Dq definition are those 14.1 uses (verified in step 2, SHOULD S1 and S6). If 14.1 applies T to every tree, so does every candidate, and the 12.7 cm floor becomes a stress variant.

| Candidate | f(tst) | g(r) | Free parameters | Provenance |
|:--|:--|:--|:--|:--|
| C0f | exp(-beta tst) | min(r, 2.9848)² | none (14.1 r5 coefficients frozen) | 14.1 |
| C0r | exp(-beta tst) | min(r, 2.9848)² | alpha, beta (refitted on the new frame) | 14.1 |
| C1 | exp(-beta tst) | min(r, 2.9848)^gamma | alpha, beta, gamma | GT1 |
| C2 | exp(-beta tst) | smoothstep from r_lo to r_hi, 1 above | alpha, beta, plus r_lo, r_hi from the grid | CTRN fact 1 |
| C3 | (tst / tau) exp(1 - tst / tau) | as C2 | alpha, tau, plus r_lo, r_hi from the grid | FIA motivated |
| C4 | exp(-beta tst) | min(r, 1.5)^gamma | alpha, beta, gamma | FIA motivated |
| C5 | exp(-beta tst) | 1 | alpha, beta | red team M7 |
| C6 | exp(-0.08220 tst) | min(r, 2.9848)² | alpha | HR attenuation |

**Thresholds of C2 and C3.** r_lo and r_hi come from the registered grid r_lo ∈ {0.5, 0.6, 0.7}, r_hi ∈ {0.75, 0.85, 1.0} (all 9 pairs). Inside each CV training fold the pair is chosen by inner fit error, so the CV score includes threshold selection. The full-data model takes the pair with the lowest full-data fit error, and that pair is held fixed across bootstrap draws, so parameter intervals are conditional on it (stated in the report). A pick at a grid edge (r_lo 0.5 or r_hi 1.0) is flagged, and the grid is extended one step (0.4 or 1.15) as a registered stress variant. Thresholds count as two parameters in the parsimony order. The 19 October values (0.6, 0.85) have no special status.

**FIA motivated candidates.** C3 and C4 were written after reading mefia_ph_c. They stay in, and if either is selected the verdict carries that label.

**Parameter bounds (registered).** alpha in [0, 2]; beta in [0.005, 1] yr⁻¹; gamma in [0, 4]; tau in [0.5, 10] yr. C3 has no cap; C2 and C5 need none; C4's cap is 1.5. CAP is redefined per candidate accordingly.

**Interval integration.** CTRN and PEF intervals average 2.4 yr (up to 5). Predicted increment over an interval is the sum of annual steps, each with its own tst and m_T. Integration is **open loop**: Dq, competition and site terms stay at their observed interval-start values, and only tst and the tree's own diameter advance. Closed-loop re-projection (2,000 draws × 8 candidates × 9 pairs × 18 folds) is out of reach on Cardinal and is run once, for the selected candidate on the full-data fit, as a reported check. No annualized midpoint m_T is used.

**Limit on identification.** Above r 1.7 the fit set holds under 1% of records. Behavior there under every candidate is a prior choice, not an estimate, and the report says so. C3 ties rise and decay to one tau, so it cannot express a fast rise with slow decay; that is accepted to keep the parameter count down.

## Data

- **Fit set.** CTRN T_post records exactly as the frozen r5 T frame selects them (46,521 records; renamed from "C2 r5 frame" to avoid colliding with candidate C2), plus PEF post-thinning records if PEF passes the link test. PEF is decided in step 2, before any fit.
  - PEF records are rebuilt from GYDB tags at the location level, with interval records linked as in PREREG1's TH step.
  - **Link test.** PEF joins if at least 80% of post-thinning live tree records at tst 1 to 17 link to a pre-visit record. Otherwise it is excluded and the reason is logged.
  - **PEF clustering.** PEF is one installation in every CV fold and bootstrap, whatever its compartment count.
  - **tst range.** Probes find PEF tst from 2 to 46. Records at tst above 17 are excluded from the fit (CTRN support) and reported.
  - **Cut type.** PEF cuts are largely selection and diameter limit. The share by cut type is reported, and "PEF excluded" is a stress variant.
- **Previously inspected set.** mefia_ph_c (827 stands, 781 plots). It is scored once with the selected candidate, but because its survivor ratios shaped the candidate list, every gate on it is labeled "previously inspected".
- **Sealed confirmatory set.** The New Hampshire and Vermont post-harvest FIA set, built in step 2 with PREREG1 rule 7's definitions. Only one quantity is read from it before selection: A0's P1 heavy gap (gate G-F). No survivor ratio, no candidate prediction and no class table is computed on it until the selection record's md5 is written. Scripts that touch it before then read only the A0 P1 path.
- **No harm sets.** The 19 Phase D sets, the 20 cell Bakuzis grid and the 200 yr mefia_l_c frame.

## Control for a general growth shortfall

**Primary: no control, in fit or validation.** Both the fit (CTRN) and every validation gate use the raw observed over predicted ratio. This is symmetric and avoids double counting L, whose lambda was fitted to the unmanaged shortfall.

**Secondary, reported only: a symmetric control.** Fit with CTRN unthinned plot ratios as the control, and validate with mefia_l_c unthinned survivor ratios as the control. It is used only if step 2 confirms that mefia_l_c holds observed remeasured survivor increments (it is described as a 200 yr projection frame; if it does not, the secondary is dropped and the reason logged).
- Same trees and weights as the primary: live at both visits, at or above the size floor, expansion weighted.
- A class with fewer than 30 control trees uses the pooled control over all classes.
- The two plot sets are disjoint, so the control ratio is resampled independently of the treated ratio within each bootstrap draw.
- The control describes L's residual error on unmanaged stands, not the release.

## Fit and selection (CTRN and PEF only; no mefia_ph_c or sealed path is opened)

**Fitting.** Weighted least squares on interval diameter increment (cm yr⁻¹), predicted by integrating the engine's annual steps. Weights are expansion factors, with the predicted increment floored at 0.05 cm yr⁻¹ in any ratio summary. Parameter intervals come from an installation clustered bootstrap (2,000 draws, seed 20261020).

**Identifiability checks (before selection).**
- A candidate with more than 5% of bootstrap draws at a registered bound is **ineligible**.
- Profile likelihood for each parameter, and the parameter correlation matrix, are reported. A pair with |r| above 0.95 is flagged in the report.

**Cross validation.** Leave one installation out (17 CTRN installations, plus PEF as one more). The metric is the expansion weighted mean squared error of interval diameter increment on held-out trees. The SE of each candidate's CV error, and of every paired difference between candidates, is computed across folds.

**Fit-set class gate.** On held-out predictions, observed over predicted must lie within 0.10 of 1 in every fit-set d / Dq class at or above 0.6 that holds 30 or more records. The class below 0.6 is reported for every candidate and is not gated, because T cannot lower predictions (reading 2).

**Selection.**
C0f and C0r are references, never in the candidate set.

1. Eligible candidates pass the class gate and the bound check, and beat C0r by more than one SE of the paired CV difference. If none does, the result is H0 on the fit set. C0f's CV error is reported but is not the reference, because its frozen coefficients were fitted on every held-out installation and its LOIO error is optimistic.
2. Take the lowest CV error among eligible candidates. Every eligible candidate within one fold SE of that best candidate's CV error is tied.
3. Among the tied, pick the fewest parameters (counting r_lo and r_hi), then the order C6, C5, C2, C1, C4, C3.
4. **HL criterion.** C3 counts as support for HL only if it beats C2 by more than one SE of their paired difference, with both fitted at the same threshold pair (C2's full-data pair), whether or not C3 is selected. That pair was chosen on all folds, so a small amount of information leaks into this one comparison; it is symmetric between C2 and C3 and is accepted.

The selection record (candidate, coefficients, CV table) is written and its md5 recorded before any candidate prediction on mefia_ph_c or the sealed set.

## Heavy stand AGB: P1-S primary, P1 reported (formerly gate F2)

PREREG1 found A0's heavy gap at 0.317 against a tolerance of 0.346, so the headroom is 0.029, while survivors grow about 1.2 times A0. Any release consistent with survivor growth exceeds that headroom, so total P1 cannot be met by a correct T. This is registered as decided: **P1-S is the primary heavy gate, and total P1 is reported.**

**Decomposition (step 2, on frozen A0 outputs, heavy stands; intermediate reported).** The gap is the v1 to v2 change, predicted minus observed, in Mg ha⁻¹ yr⁻¹, with Δt the stand's interval in years. The engine predicts mortality by shrinking expansion weights, not by killing trees, and predicts no removal. Each component is computed independently from tree records:
- **S, survivor growth.** Over trees observed live at both visits: S_pred = Σ expf_v1 · (AGB(d_pred,v2) − AGB(d_v1)) / Δt, with weights held at v1; S_obs is the same with d_obs,v2. S = S_pred − S_obs.
- **M, mortality.** M_pred = [Σ over all v1 trees (expf_v1 − expf_pred,v2) · AGB(d_pred,v2) − Σ over trees observed dead or removed expf_v1 · (AGB(d_pred,v2) − AGB(d_v1))] / Δt, that is, the weight-decrement loss net of the growth the engine still credits to trees that did not survive. M_obs = Σ over trees observed dead at v2 and not removed expf_v1 · AGB(d_v1) / Δt. M = M_obs − M_pred.
- **I, ingrowth.** I = I_pred − I_obs, the AGB at v2 of trees crossing the size floor, expansion weighted, over Δt.
- **R, removal.** Trees removed between v1 and v2 (later cuts or disturbance, by the PREREG1 removal codes applied to the v1 to v2 interval). The engine predicts no removal, so R = R_obs = Σ expf_v1 · AGB(d_v1) / Δt over those trees.

**Population, weights and AGB.** The decomposition uses exactly the PREREG1 gap scorer's population and functions: "all v1 trees", S and I use the scorer's 5 cm AGB floor (not T's floor); AGB(·) is the scorer's NSVB call with the scorer's height source; and S_obs uses the weights the scorer uses for observed survivors. If the scorer uses v2 weights (for example where a tree crosses the microplot to subplot boundary), a weight-change term W_obs = Σ (expf_v2 − expf_v1) · AGB(d_obs,v2) / Δt is added to the observed side and reported as its own component. I_pred is engine-carried stems below 5 cm at v1 crossing 5 cm by v2, at expf_pred,v2, plus any engine ingrowth records. Step 2 confirms these against the scorer code before the decomposition is computed.

Because M_pred nets out growth the engine credits to trees that did not survive, the M component also carries growth credit on trees removed between v1 and v2; the attribution label says so. P1-S covers all survivors, including trees below r 0.6 that V1 does not gate, so it partly re-imports the small-tree level shortfall; the report gives P1-S with and without that class.

With predicted change S_pred − M_pred + I_pred and observed change S_obs − M_obs − R_obs + I_obs, the gap is S + M + I + R by construction of the definitions, but each term is computed from its own tree subset, so the check below catches subset or weight errors.

**Identity check.** S + M + I + R must equal the A0 heavy gap within 1e-6 Mg ha⁻¹ yr⁻¹. No component is a residual, so a failure is an accounting error, and it is a **harness failure (rule 1)**, not a fallback.

**P1-S.** P1-S = mean over heavy stands of S, Mg ha⁻¹ yr⁻¹. It passes if |P1-S| ≤ 0.10 × the mean of S_obs over heavy stands, matching V1's tolerance. Under A0 it is near −20% of S_obs (survivors underpredicted), so A0 fails it; a correct T moves it toward 0. The factor is not swept with the P tolerances.

**Heavy no-worse gate (P1-NW).** On any set, the candidate's total heavy gap must be no larger than that set's A0 gap plus its implied release plus 25% of its observed heavy rate, and no larger than 14.1's heavy gap on that set. The implied release is S_obs − S_pred(A0), the AGB change a release matching survivor growth would add. On mefia_ph_c the bounds are about 0.9 to 1.0 and 1.391, so P1-NW is a loose guard against gross overshoot, not a test of fit.

**Label.** Any adoption carries "heavy AGB gap carried, attributed to <the component among M, I, R with the largest absolute value>", with the total heavy gap stated.

All of this uses frozen A0 outputs and observed values only, and is recorded with its md5 before selection.

## Gates on mefia_ph_c (previously inspected; one candidate, read once)

| Gate | Test | Threshold |
|:--|:--|:--|
| V1 survivor ratio | observed over predicted, survivors in heavy and intermediate stands, pooled species, every d / Dq class at or above 0.6 with 30 or more trees | point estimate within 0.10 of 1 in each class; paired plot bootstrap 95% interval reported, and reported paired against 14.1 |
| V1-L | the same ratio in light and low volume stands, classes at or above 0.6 with 30 or more trees | paired bootstrap 95% upper limit of worsening against 14.1 (increase in distance from 1) at most 0.05 in every class |
| P1-S | as defined above | within 10% of observed survivor growth |
| P1-NW | as defined above | no worse than both bounds |
| P1 | total heavy gap, tol 25% | reported |
| P2, P3 | as PREREG1, tol 25% | as PREREG1 |
| P5 | AGB bias over 827 stands | within ±5% |
| N0 | every set with no known tst equals 14.1 exactly (E0b style) | identical |
| N1 | ctrn_c and pef_c %RMSE, ctrn_fl absolute bias, against 14.1, by leave one installation out prediction; pef_c split at tst 17 | %RMSE no worse by more than 0.5 points; bias no larger |
| N2 | 20 cell thinned Bakuzis grid, against 14.1's own violations as the baseline | no new violation |
| R1 realism | 100 and 200 yr cumulative gross production of each thinned grid cell over its unthinned twin (same cell, no thinning), against 14.1's ratio for the same cell | no cell's ratio exceeds 14.1's by more than 0.02; 14.1's ratios reported |
| R2 realism | residual tree response by removal intensity, and a second thinning inside tau under C3 | reported (the grid has one thinning regime, so intensity cannot be gated) |
| G-F | A0 P1 heavy gap on the sealed New Hampshire and Vermont set | reported; settles PREREG1 gate F |

**Reported splits (not gated).** V1 by softwood and hardwood (no candidate has a species term, so a gate there would test something no candidate can express); V1 by FORTYPGRP with 30 or more trees; V1 split into in-support cells (r and RF inside the CTRN range) and out-of-support cells; V1 by tst year. The decay form is validated only on CTRN and PEF, because FIA tst runs only 1 to 5.

**The class below d / Dq 0.6** is reported, not gated, in V1 and V1-L, for the reason given on the fit set (reading 2): CTRN is short of A0 there while FIA is 1.22 over it, and T cannot reconcile both. The report states the selected candidate's ratio there next to C2's and C5's. Under C2, trees below r_lo get no release; the literature often reports strong relative release of suppressed trees, and this is named as a limit if C2 or C3 is selected.

## Harness gates

PREREG1's E0, CAP, TR, K1 and TH carry over with the new overlay `AcadianGY_14.3dev_Tform.r`, sourced after 14.1. It replaces only `.acd_v141_mT` and is the identity when off. New gates:

- **H1.** C0f with the overlay on reproduces 14.1 byte for byte on every frame.
- **H2.** The fitter in "r5 mode" (r5's response, weights, annualization and frame, CTRN only) reproduces alpha 0.37109 and beta 0.08220 within 1e-4. This validates the code. The fitter then switches to the registered objective, and C0r is reported under both.
- **H3.** r in the fit frame matches the r the engine passes to `.acd_v141_mT` on a 500 record sample, to 1e-12.
- **H4.** TR trace per candidate form, including C3 near tst 0.
- **H5.** CAP checked against each candidate's own cap.
- **H6.** No candidate prediction on mefia_ph_c or the sealed set appears in the logs before the selection record md5. Step 2 has an allowlist of reads, each logged: frozen A0 and frozen 14.1 outputs and observed values on mefia_ph_c (decomposition, P1-S baseline, P1-NW bounds), and the build plus A0 P1 heavy gap on the sealed set. No step 3 script imports either path.

## Decision rule, in order

1. Any harness gate fails: no verdict.
2. The fit set selects no candidate (none eligible, or the pick does not beat C0r): H0, and 14.3 keeps 14.1's T.
3. V1 fails in any gated class: not adopted, and the failing classes are named. The level reading applies only here, when V1 fails.
4. P1-S, P1-NW, P2, P3 or P5 fails: not adopted, and the failing gate is named. If V1 passes and P1-S fails, the report attributes the gap with the decomposition.
5. N0, N1, N2, R1 or V1-L fails: not adopted, and the trade-off is reported.
6. All pass: a 14.3 candidate, labeled "passes on a previously inspected set", with "FIA motivated" if C3 or C4, and with the heavy AGB label.
7. **Confirmation on the sealed set.** The sealed set is excluded from step 4. Step 5 runs in this order, each stage md5 logged:
   - (a) after the selection md5: A0 and 14.1 on the sealed set; the sealed decomposition with its identity check, S_obs, the implied release, and P1-NW's set-specific bounds;
   - (b) the "open" conditions: the result is "open", not "not confirmed", if 14.1's P1-S there is not an overshoot (P1-S of 14.1 not above +0.10 × S_obs), if ESI coverage is below 80%, if fewer than 30 heavy stands qualify, or if fewer than 3 V1 classes have 30 or more trees;
   - (c) the candidate is run and scored once on V1, V1-L, P1-S, P1-NW, P2, P3 and P5 (P2, P3, P5 at 25%). Adoption needs all of them. Any failure returns "not confirmed".

**Sensitivity labels.** The P gates are also read at 15% and 35%. A verdict that changes at either is labeled "tolerance sensitive".

## Stress test (registered alternatives, selected form held fixed)

Each variant holds the selected form fixed and reports the gates again. A full re-selection under each variant is reported separately, labeled exploratory, and does not change the verdict.

- PEF excluded from the fit.
- Fitting on basal area increment instead of diameter increment.
- The symmetric control applied (the secondary).
- A cap of 1.5 on r in every candidate.
- Dq computed on trees at or above 12.7 cm.
- The 12.7 cm size floor applied (if 14.1 has none).
- The threshold grid extended one step at an edge, if the full-data pick sits on one.
- Total P1 gated instead of P1-S (shows what the PREREG1 gate would have said).

A headline quoted at the favorable end of its range is flagged. Selection by minimum CV among eight candidates carries winner's curse; the one SE rule and the C0 margin are the registered mitigation.

## Execution

Cardinal, `~/v143p2/` (a new directory). Firebreather replaces Cardinal if Aaron names it. The chain:

1. scripts, red team, dry run on synthetic stands, launch md5s;
2. frame step: fit set, PEF link test, H3 trace, size-floor check, the r5 Dq reconfirmation, the mefia_l_c check, the sealed set build, G-F, and the mefia_ph_c heavy decomposition with its identity check. Its md5 is recorded before any fit;
3. fit, identifiability, CV and selection, ending with the selection record md5;
4. one engine run of the selected candidate on every frame except the sealed set, then scoring and assembly;
5. confirmation on the sealed set.

## Plan gate answers (26 October 2026)

1. **PEF.** Joins on the 80% link rule (the default); otherwise excluded with the reason logged.
2. **Control.** No control as primary (the default); the symmetric control is the reported secondary.
3. **Sealed set.** Built now for G-F under the read restriction above (the default).

The choices of revision 4 were the defaults listed there; revision 5 adopts them without change.

## Response to plan red team 1

| Item | Change |
|:--|:--|
| M1 | Class gate scored on held-out fits at r ≥ 0.6 only; below 0.6 reported and named an L or A0 issue |
| M2 | mefia_ph_c relabeled previously inspected; New Hampshire and Vermont made the sealed set; r_lo and r_hi chosen by in-fold CV; C3 and C4 labeled FIA motivated |
| M3 | Heavy gap decomposition and implied release; P1-S gating (made unconditional in revision 2) |
| M4 | No control as primary in both fit and validation; symmetric control as secondary with independent resampling and pooled fallback |
| M5 | Leave one installation out CV, named metric, one SE rule, must beat C0f and C0r (superseded in revision 2: C0r only) |
| M6 | Registered bounds, bound flag makes a candidate ineligible, profile and correlation report, interval integration, prior statement above r 1.7 |
| M7 | C5 and C6 added, HV hypothesis registered |
| S1 | H3 trace |
| S2 | H1, H2, H4, H5, H6 |
| S3 | N1 by held-out installation, pef_c split at tst 17 |
| S4 | 80% link rule, PEF one cluster, tst above 17 excluded, cut type reported |
| S5 | HL margin, sealed-set gates, point estimate rule, tolerance label, bound flag, V1 pass with P fail attribution |
| S6 | Floor matched to 14.1, floor as stress variant |
| S7 | R1 realism gate |
| S8 | Support split and tst caveat |
| S9 | V1 gated by species group, FORTYPGRP reported (superseded in revision 2: pooled gate, species reported) |
| S10 | Grid named, variants hold the form fixed |
| S11 | V1-L |
| S12 | Folded into F2 and G-F (superseded in revision 2: F2 registered as decided, P1-S primary) |
| N1 | Frame renamed |
| N2 | Clause dropped from HF |
| N3 | Noted in reading 4 |
| N4 | Header note; in-sample reconfirmation in step 2 |
| N5 | Sealed set read restriction |
| N6 | Weights and floor named |
| N7 | Noted under limits |

## Response to plan red team 2

| Item | Change |
|:--|:--|
| MUST-A | V1 and V1-L gated only at r ≥ 0.6; class below 0.6 reported with C2 and C5; V1-L given a 0.05 paired upper-limit margin; level reading registered under the hypotheses |
| MUST-B | H6 scoped to candidate predictions, with a logged allowlist of step 2 reads |
| MUST-C | H2 run in r5 mode, then the registered objective; C0r reported under both |
| MUST-D | F2 registered as decided: P1-S primary, P1 reported; S, M, I, R defined with an identity check; P1-S tolerance on observed survivor growth; P1-NW no-worse gate; heavy AGB label |
| SHOULD-1 | C6 limit stated under HV |
| SHOULD-2 | 9 pairs; in-fold and full-data choice rules; intervals conditional on the pair; edge flag and extension variant |
| SHOULD-3 | V1 gated pooled, species reported |
| SHOULD-4 | Sealed rule 7 gets V1-L, P2, P3, P5, P1-NW, the "open" conditions, and sealed decomposition after the selection md5 |
| SHOULD-5 | Tautological clause dropped; R1 against 14.1 per cell with a defined unthinned twin; intensity response reported only |
| SHOULD-6 | C0r is the CV reference; C0f reported |
| SHOULD-7 | Open-loop integration specified; closed loop run once as a check |
| NOTE L57 | Redundant label dropped |
| NOTE L36 | HL comparison at a common threshold pair |
| NOTE L162 | Re-selection labeled exploratory |
| NOTE L28 | Wording changed |

## Response to plan red team 3

| Item | Change |
|:--|:--|
| MUST-E | S, M, I, R defined from tree records in the engine's weight-based representation, v1 to v2 removal defined, every component computed independently; identity failure is a harness failure |
| SHOULD-1 | P1-S tolerance set to 0.10 of S_obs (A0 fails it), not swept |
| SHOULD-2 | P1-NW written with set-specific terms; implied release added to the sealed pre-scoring quantities; looseness stated |
| SHOULD-3 | Sealed set excluded from step 4; 14.1 run before the candidate; "open" condition on 14.1's P1-S overshoot; floor of 3 gated V1 classes |
| SHOULD-4 | Level reading only when V1 fails |
| SHOULD-5 | C0r margin moved into eligibility before the tie break; tie SE named; references outside the candidate set |
| NOTE L105 | HL leak stated and accepted |
| NOTE L125 | Largest absolute value |
| NOTE L209-226 | Stale rows marked superseded |
| NOTE L134 | 30-tree floor stated for V1-L |

## Response to plan red team 4 (converged)

| Item | Change |
|:--|:--|
| SHOULD-1 | Decomposition pinned to the scorer's 5 cm floor, NSVB call, height source and survivor weights; weight-change term if the scorer uses v2 weights; I_pred written out; step 2 confirms against scorer code |
| SHOULD-2 | Frozen 14.1 outputs added to the H6 allowlist |
| NOTE P1-S scope | P1-S reported with and without the class below 0.6 |
| NOTE M label | Growth credit on removed trees named in the attribution |
