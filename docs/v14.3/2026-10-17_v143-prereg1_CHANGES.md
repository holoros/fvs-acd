# v143 PREREG1: draft 1 to draft 2 changes (17 October 2026)

Draft 1 backup: `2026-10-17_v143_thin-partial-removal_PREREG1_DRAFT_PREV_20261017.md` (1,690 words). Draft 2: 2,373 words, md5 525e4551.

## Content inventory diff

**Added**
- A "What is known before any run" table, from Cardinal probes 15612299 and 15612657 (counts only). It shows the share of stands with a known tst by class, which sets carry a known tst (ctrn_c, ctrn_fl, pef_c), the PEF tst range of 2 to 46 years (227 stands beyond the 17 year support), that CTRN and PEF carry no treatment type, and that 30 CTRN locations in 9 of 17 installations have a pre-thinning visit.
- The HG and HR readings, each with a predicted pattern and the consequence if HR holds.
- A single definition of eligibility across all frames: trees at least 12.7 cm DBH, pre-visit diameters, and a removed/retained split by tree link, with the source and lag for each frame.
- A support check in the TH step.
- A CAP harness gate.
- T share diagnostic S.
- Survivor increment test by d/Dq class, independent of the classifier.
- The ±15/35% sweep.
- Reporting by forest type.
- The pef_c split at tst 17.
- The rule 6 builder diff, ESI coverage check and minimum n.
- The execution host, Cardinal.

**Changed**
- T estimation set: corrected to CTRN only. BAXTER is removed from E0b and N1, and pef_c is added to N1.
- E0b now rests on per-set counts of known tst.
- A3 threshold: DQR_MIN is now the definitional 1. It is no longer an estimated minimum.
- A1 and A2 thresholds now come from the 30 CTRN locations that have a pre visit, labeled as partial support.
- Decision rule 2: the S lower limit must be above 0.5. A0 is barred from candidacy.
- P3: now a paired no-harm test on light and low volume.
- P4: now a paired-difference test.
- P5: provenance relabeled as borrowed.
- A1 purpose: corrected to basal area, not FCCL merchantable volume.
- Candidate order: now A3, A1, A2.
- Cap source: corrected to V141_RELCAP.

**Removed**
- The claim "fitted on CTRN and BAXTER". It was wrong.
- The [UNKNOWN] on the share of stands with a known tst. Resolved by the probe.
- The interval-overlap form of P4. It was not a paired test.
- The estimation-set minimum for DQR. CTRN carries no treatment record that would support it, and the definitional bound needs no fit.

## Finding dispositions

| Finding | Severity | Disposition |
|:--|:--|:--|
| F1 quantities not computable consistently | MUST | Fixed: one definition (12.7 cm floor, pre-visit diameters, tree link) with source and lag per frame |
| F2 T set is CTRN only; E0b premise | MUST | Fixed: CTRN only; E0b from TST files; pef_c (1,193 known) moved to N1 |
| F3 known tst share unknown | MUST | Fixed: 762 of 827 known, 1 to 5 yr; per class counts registered |
| F4 rule 2 non sequitur | MUST | Fixed: S statistic with paired bootstrap; A0 barred |
| F5 noisy point gates, P4 not paired | SHOULD | Fixed: P3 and P4 paired; P1 and P2 report intervals |
| F6 A1 restates classifier | SHOULD | Fixed: survivor increment diagnostic; FCCL-bound variants non-evidential |
| F7 heavy not singled out | SHOULD | Fixed: HG and HR registered; the intermediate implication stated |
| F8 ±25% provenance | SHOULD | Fixed: sweep at 15 and 35%; P5 labeled borrowed |
| F9 N1 near tautological; grid support | SHOULD | Fixed: support check before any arm output; pef_c is the informative N1 set |
| F10 rule 6 builder | SHOULD | Fixed: builder diff, ESI coverage of at least 80%, 30 per class, P1 to P5 |
| F11 extrapolation domain | SHOULD | Fixed: forest type reporting; tst support stated per frame |
| F12 cap source | NOTE | Fixed: CAP gate |
| F13 low volume ungated | NOTE | Fixed: added to P3 |
| F14 A1 purpose | NOTE | Fixed |
| F15 host unnamed | NOTE | Fixed: Cardinal |

## Not done

Red team rounds 2 and later, and the adjudicator, were not run. The worker that wrote draft 2 could not launch subagents, so draft 2 has had no independent review.

# Draft 2 to draft 3 (17 October 2026, afternoon)

Draft 2 backup: `2026-10-17_v143_thin-partial-removal_PREREG1_DRAFT_PREV_20261017b.md` (md5 525e4551, 2,373 words). Draft 3: md5 be127f5e, about 3,030 words. Driven by round 2 (`review/2026-10-17_v143-prereg1_REDTEAM_r2.md`, verdict not registrable).

**Added**
- Gate F (rule 2): A0 is read before any eligibility arm; if its heavy gap exceeds tol, the study closes as "L limited" (R2-2). The bound is stated: P1 is passable only if L adds at most 0.117 Mg ha⁻¹ yr⁻¹ over 14.0.4 L2 in heavy stands.
- Arm Apv, the null for the data rule; N1 is scored against both 14.1 and Apv; "ineligible, missing" is reported apart from "ineligible, threshold"; the pef_c missing pre visit count is tabulated in the TH step (R2-1).
- Placebo arms at each arm's per class eligible share, seed 20261017, and rule 4 requiring a candidate to beat its placebo in heavy and intermediate (R2-3).
- The realized multiplier diagnostic, with the HG and HR predictions restated as a ratio difference and a 0.10 margin, swept (R2-4).
- A minimum of 4 retained trees, swept at 2 and 8; the DQR 0.95 to 1.05 share; the 1.05 stress variant (R2-6).
- The engine counters by class and arm (R2-5).
- The direction of the subset bias in RF_MAX and RD_MIN, the intersection with the 119 fit locations, and a less restrictive variant (R2-7).
- The minimum of 30 eligible and 30 ineligible stands per gated class, labeled as borrowed from a tree floor, and an "uninformative" verdict (R2-11, round 1 F3).
- The bootstrap seed; P5 marked as a point test (R2-11).
- The rule 7 replacement validation for New Hampshire and Vermont, and the requirement that 14.1 show the heavy gap there (R2-12).

**Changed**
- Dead trees from other causes are excluded from both parts as the primary rule; the draft 2 sentence calling them removed under r1 was wrong (R2-5).
- P3 now requires the absolute gap within tol and the paired worsening limit at or below 0.5 tol (R2-8).
- Provenance of A1 and A2 is now "by analogy with GT6" (R2-7).
- The HR prediction in "Two readings" (R2-4).
- The rules are renumbered 1 to 7.

**Removed**
- Gate P4. It is now reported only, because a P1 pass implies it (R2-9).
- The S threshold of 0.5 as a decision rule. S is reported (R2-2).
- The 0.05 tie break. The order A3, A1, A2 alone decides (R2-10).
- The sentence "If HR holds, no eligibility arm can pass P1 to P3". It was false for A1 and A2 (R2-3).

# Draft 3 to draft 4 (17 October 2026, afternoon)

Draft 3 backup: `_PREV_20261017c` (md5 be127f5e). Draft 4: md5 1409b9bf, 3,336 words. Driven by round 3 (`review/2026-10-17_v143-prereg1_REDTEAM_r3.md`, verdict: not registrable).

**Changed**
- Rule 4 replaces the placebo gap contrast, which cancels the observations (R3-1), with the realized T share. R = sum(obs minus predA0) / sum(pred141 minus predA0), compared between withheld and kept stands with a paired plot bootstrap and a minus 0.25 margin, which is swept.
- Gate F covers heavy and intermediate. It now uses the exact attainable minimum gap from the per stand min and max of the A0 and 14.1 predictions, counts stands where T lowers the prediction, and is evaluated at the swept tol (R3-2).
- Placebo arms: 200 draws; they withhold T from missing stands; they are matched on eligible count within the non-missing pool per class; they are assembled from the A0 and 14.1 runs and reported as a null (R3-3).
- The realized multiplier diagnostic becomes a survivor increment ratio of sums, with cells of 30 trees, decided on cells above 1.15 d / Dq, with HG, HR and "neither" readings (R3-4).
- Rule 7 names P1, P2, P3, P5 and rule 4. The heading now covers the N gates. The stray [F4] tag is removed. The "two devices" sentence is corrected (R3-5).

# Draft 4 to draft 5 (17 October 2026, afternoon)

Draft 4 backup: `_PREV_20261017d` (md5 1409b9bf). Draft 5 is driven by round 4 (`review/2026-10-17_v143-prereg1_REDTEAM_r4.md`, verdict: not registrable). Round 4 was the last round under the convergence cap, so the repairs below have not been red teamed. The plan stage ends NOT CONVERGED on R4-1 until a reviewer confirms the repair.

**Changed**
- Rule 4 (R4-1). The ratio R is replaced by the realized T slope k: Y = obs minus predA0 is regressed on D = pred141 minus predA0 within each group, with its own intercept and a common RF covariate. This stops A0's intensity graded error from driving the contrast. The k kept interval must include 1. A placebo stratified by RF decile is reported for A2 and A3, and the plan states that a rule 4 failure alone does not establish HR.
- Rule 4 outcomes (R4-2) are now: uninformative, HR favored (both k below 1 and the contrast within ±0.25), or unresolved.
- Gate F (R4-3, R4-5) closes on the 25% tol only and is reported at 15% and 35%. The bound the arms can actually reach is reported beside it.
- The stale reference in the HR bullet is fixed (R4-4).

# Draft 5 to draft 6 (17 October 2026, evening)

Draft 5 backup: `_PREV_20261017e` (md5 108399b9). Aaron chose option 1 at the plan gate: one more targeted round on rule 4. Round 5 (`review/2026-10-17_v143-prereg1_REDTEAM_r5.md`) found the plan registrable after three should fixes, which are applied here. Plan stage: CONVERGED on design. Registration still waits on re-verifying the Cardinal probe counts.

**Changed**
- R5-1. The rule 4 fit is now Y ~ group + group:ns(RF, df 2) + group:predA0 + group:D. Each group gets its own RF spline and its own A0 proportional term. The "not driven by it" claim is narrowed, and the residual limit is named.
- R5-2. The D spread floor is replaced by an informativeness rule: a group is uninformative if its k interval is wider than 1.0. The partialled SD of D is reported.
- R5-3. Rule 4 groups are restricted to stands with a known tst, and the count dropped is reported.
- R5-4. Outcomes are applied in order, uninformative first. HR favored needs the pattern in both classes. The k kept condition is now an interval intersecting [1 - m, 1 + m]. The contrast is a point estimate.
- R5-5. An uninformative rule 4 in the confirmation set leaves rule 7 open.
