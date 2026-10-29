# Red team r4: v143 PREREG1 draft 4

17 October 2026. Independent final round reviewer, repo read only. Checked against draft 4, draft 3, r3, the change log and `acdx_postharvest_by_type_DATA.csv`. Arithmetic rechecked: tol = 0.25 rec_obs gives 0.346, 0.515, 0.632, 0.713; heavy 1.391 minus 0.346 = 1.045; 0.346 minus 0.229 (L2 heavy gap) = 0.117. Per tree outputs exist for frozen runs (`TREE_OUT` in the sbatch), so the survivor ratio and placebo assembly need no rerun. Probe counts unverified, internally consistent.

## Round 3 disposition

| r3 | Status | Reason |
|:--|:--|:--|
| R3-1 | PARTIAL | Rule 4 now uses obs, but R is confounded by A0's own residual, which varies with removal intensity (R4-1) |
| R3-2 | CLOSED | Both classes; exact bound from per stand min and max; count of stands where T lowers the change; swept tol |
| R3-3 | CLOSED | Missing stands withheld, count matched in the non-missing pool, 200 draws, assembled without runs |
| R3-4 | CLOSED | Ratio of sums, 30 tree cells, decided above 1.15, HG, HR and neither readings, swept margin |
| R3-5 | PARTIAL | Most repaired; one stale reference remains (R4-4) |

## Gate F check

The bound is right. Classes do not overlap and each stand's prediction is either predA0 or pred141, so every class mean an arm can reach lies in [mean(min_i), mean(max_i)]. The smallest absolute gap is 0 if that interval contains mean(obs), and otherwise the distance to the nearer end. The interval covers every subset, including ones no arm can choose (for example T on "missing" stands). So if gate F fails, no rule can pass P1 or P2, and closing the study is valid: the condition is necessary, not sufficient. When gate F passes, rule 3 still judges A1 to A3. 14.1 is above tol in both classes, so a failure can only mean A0 overshoots, and the "L limited" label is right.

## New findings

**R4-1 MUST. Rule 4 does not separate HG from HR.** Plan: "R = sum(obs minus predA0) / sum(pred141 minus predA0)", and a rule 4 failure is reported as "HR favored". Write obs_i minus predA0_i = k_g Δ_i + b_i + e_i. Here b_i is A0's structural error without T, mostly the L component. Then R_g = k_g + Σb/ΣΔ. HR sets k equal in both groups, but the contrast still moves by the difference in Σb/ΣΔ.

Each arm sorts stands on removal intensity: RF directly, and RD_res and DQR through it. The withheld group is the more intense removals, with fewer residual trees, a lower stock and so a smaller ΣΔ. The L family's error does move with intensity. In the CSV, the 14.0.4 L2 gap is +0.229 heavy, -0.398 intermediate, -1.436 light and -0.636 low volume. If that gradient also runs inside a class, R_withheld minus R_kept comes out below 0 under HR, and the small ΣΔ in the withheld group magnifies it. A random placebo does not carry the intensity gradient, so it cannot remove this term.

**Repair:** estimate k_g as the within group slope of (obs minus predA0) on Δ_i. Give each group its own intercept and add an RF covariate (A0's residual trend). Test k_withheld minus k_kept. Also report the contrast for a placebo stratified by RF decile, for A2 and A3. Register that a failure of rule 4 alone does not establish HR (see R4-2).

**R4-2 SHOULD. Rule 4 has outcomes the plan does not assign.** Plan: "Otherwise not adopted ... (HR favored)"; "a group whose denominator has a 95% lower limit at or below 0 is uninformative". Three cases are open:
1. If a group is uninformative, nothing says what rule 4 then returns.
2. "Otherwise" also covers R_withheld above R_kept, and an interval that is merely wide. Neither is the HR pattern of both R below 1 and equal.
3. Nothing is required of R_kept. A contrast of 0.3 kept against 0 withheld passes, although HG predicts R_kept near 1.

**Repair:** make an uninformative group give "not adopted, uninformative". Reserve "HR favored" for both R lower limits below 1 with the contrast inside ±0.25. Add "R_kept interval includes 1" to the HG pass, swept with the margin.

**R4-3 NOTE. Gate F's sweep can contradict its closure.** Plan: "Gate F is also evaluated at the swept tol of 15% and 35%." The plan does not say whether a failure at 25% that passes at 35% closes the study. **Repair:** close on 25% only, and label the result sensitive under the existing sweep rule.

**R4-4 NOTE. Stale cross reference.** "Two readings", HR bullet: "(see the realized multiplier diagnostic)". That diagnostic is now the "survivor increment ratio", and the decisive HG/HR test is the realized T share (rule 4). **Repair:** point to rule 4 and the survivor increment ratio.

**R4-5 NOTE. The gate F bound is looser than any arm can reach.** Every arm withholds T from "ineligible, missing" stands, yet the interval lets T act there. This is conservative for closure and needs no change. Reporting the arm attainable bound as well, with min_i = max_i = predA0_i on missing stands, would show how much room the arms really have.

**Constraints.** No violation found. L and T are fixed from the rds, with the CAP gate. Frozen 14.1, L2 and 13.1h outputs are read, and the placebos and gate F are assembled from them without reruns. The NH and VT runs are new data, not reruns. GT1 stays a named failure. RF_MAX and RD_MIN are eligibility constants, not T estimates. Rule numbering 1 to 7 and the gate references (E0, TR, P1 to P5, N1, N2, rule 7's list) are consistent.

Verdict: not registrable. R4-1 has to be fixed because rule 4 is the plan's only HG/HR separator. R4-2 to R4-5 are cheap.
