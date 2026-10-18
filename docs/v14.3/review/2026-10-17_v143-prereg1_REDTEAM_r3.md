# Red team r3: v143 PREREG1 draft 3

17 October 2026. Independent reviewer, repo read only. Checked against draft 3, r2, the change log, `AcadianGY_14.1.r` (origin/engines-14.1-20260924) and `acdx_postharvest_by_type_DATA.csv`. Arithmetic rechecked: L2 heavy gap 0.229 (1.391 minus 1.162), so 0.117 = 0.346 minus 0.229; light L2 gap minus 1.436 gives the 0.977. Probe counts unverified, internally consistent.

## Round 2 disposition

| r2 | Status | Reason |
|:--|:--|:--|
| R2-1 | CLOSED | Apv, N1 against 14.1 and Apv, missing reported apart, pef_c count in TH |
| R2-2 | PARTIAL | Heavy only; P2 has the same trap; bound rests on an unstated assumption (R3-2) |
| R2-3 | PARTIAL | Placebo added but cannot separate HG from HR (R3-1) |
| R2-4 | PARTIAL | Restated as a ratio, but the statistic is not well defined (R3-4) |
| R2-5 | CLOSED | Died trees excluded, stress run, counters reported |
| R2-6 | CLOSED | Minimum 4 retained, 0.95 to 1.05 share, 1.05 variant |
| R2-7 | CLOSED | Intersection with the 119, bias direction, less restrictive variant, GT6 analogy |
| R2-8 | CLOSED | Gap within tol plus 0.5 tol worsening limit |
| R2-9 | CLOSED | P4 reported only (but see R3-5) |
| R2-10 | CLOSED | Order alone |
| R2-11 | CLOSED | Borrowed label, seed, P5 point |
| R2-12 | CLOSED | NH and VT replacement check; 14.1 must show the gap |

## New findings

**R3-1 MUST. The placebo comparison never uses the observations.** Plan: "the paired 95% upper limit of abs(gap arm) minus abs(gap placebo) is below 0"; "Two registered devices separate them". Evidence: the gap is rec_pred minus rec_obs over the same stands (`acdx_postharvest_by_type_DATA.csv` columns rec_obs, rec_pred, gap). Arm and placebo score the same stands, so rec_obs cancels. Arm minus placebo equals minus (1/n) times (sum of Δ over arm-withheld stands minus sum over placebo-withheld stands), with Δ = pred141 minus predA0 per stand. While both gaps stay positive, as heavy must unless the cut overshoots, an arm beats its placebo whenever it withholds T from stands where T's *predicted* effect is larger: short tst, wide residual d/Dq spread, or cap hits. That holds under HR as well as HG, so rule 4 tests correlation with Δ, not the rule's merit. Matching the placebo on tst or Δ does not fix this, because any class-mean contrast between arms on the same stands is model only. **Repair:** replace or supplement rule 4 with a stand-level test that uses obs. Per stand, take the realized T share r = (obs minus predA0) / Δ. Compare the Δ-weighted mean r of arm-withheld and arm-eligible stands within class, with a paired plot bootstrap. HG predicts withheld below eligible by a registered margin. HR predicts both below 1 and no difference. Keep the placebo as a reported null for this contrast.

**R3-2 MUST. Gate F covers heavy only, and its bound assumes Δ ≥ 0 per stand.** Plan: "The heavy gap can fall at most to A0's." The equality "each stand's result equals its 14.1 or its A0 result" is exact. T is switched per stand (`ops$use.thin.v141`, `ops$stand.tst`, L134 to 147), the engine has no random draws, and E0 and TR check the overlay. But "at most to A0's" also needs Δ_i ≥ 0 for every heavy stand. m_T ≥ 1 per tree (L68 to 71), yet AGB change also passes through density-dependent mortality, so the sign per stand is not shown. Intermediate (L2 gap minus 0.398, 14.1 plus 1.408, tol 0.515) has the same feasibility limit: if A0's intermediate gap exceeds 0.515, every arm fails P2, and rule 3 books that as an eligibility failure. That is the R2-2 defect for P2. **Repair:** run gate F on heavy and intermediate. Compute the exact attainable minimum from A0 and 14.1 alone, A0 gap minus the mean of negative Δ_i, and report the count of negative Δ_i. Evaluate gate F at each swept tol (15%, 35%).

**R3-3 SHOULD. The placebo pool and share are not pinned.** Plan: "at random among stands with a known tst and no missing quantity, at that arm's eligible share in each class". The arm also withholds T from every "ineligible, missing" stand. Heavy removals leaving fewer than 4 retained trees fall here. The placebo's handling of those stands is not stated, and neither is whether the share's denominator includes them. If missing stands keep T under the placebo, the arm wins from the data rule. One seeded draw also leaves out assignment variance. **Repair:** withhold T from missing stands in every placebo, as in Apv. Match the eligible *count* within the non-missing pool per class. Use at least 200 draws, or redraw inside each bootstrap resample.

**R3-4 SHOULD. The realized multiplier is not computable as written.** Plan: "observed diameter increment over A0's predicted increment, divided by 14.1's m_T for that tree". m_T changes every year over v1 to v2, because tst advances and Dq is recomputed at each call (L143 to 146), so no single m_T exists per tree. A0 increments near zero and negative observed increments make tree ratios unstable. There is no summary statistic, interval, cell floor or decisive cell set (5 d/Dq × tst × DQR × 2 classes), and no reading for "neither". **Repair:** per cell, use the ratio of sums Σobs / Σpred141 (equivalently obs relative to A0 scaled by the realized 14.1 to A0 ratio), with a paired plot bootstrap interval and 30 trees per cell (PREREG45, here applied as written). Decide on cells above 1.15 pooled over tst, register "near 1" as within 0.10, and add a "neither" outcome.

**R3-5 NOTE. Cross references.** Rule 7 "must pass P1 to P5" names the removed P4. The heading "Benchmark gates on mefia_ph_c (rules 3 and 5)" holds N1 (ctrn_c, ctrn_fl, pef_c) and N2 (grid). The "[F4]" tag after the TH sentence points at round 1's rule 2 finding, not the md5 step. "Two registered devices separate them" overstates what rule 4 can do (R3-1).

**Constraints.** No violation found. L and T are fixed from the rds, with CAP asserted. Frozen 14.1, L2 and 13.1h outputs are read and rescored, not rerun. GT1 stays named. RF_MAX and RD_MIN are new eligibility constants, not L or T estimates.

Verdict: not registrable. Fix R3-1 and R3-2 before thresholds are computed; R3-3 to R3-5 are cheap.
