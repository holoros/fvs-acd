# Red team r5: v143 PREREG1 draft 5 (rule 4 repair)

17 October 2026. Independent reviewer, read only. Scope: the "Realized T slope" bullet, rule 4, and the gate F text changed for R4-3 and R4-5. Scale check from `acdx_postharvest_by_type_DATA.csv`: the per stand SD of the 14.1 gap, backed out of the plot bootstrap interval, is about 1.94 (heavy) and 2.17 (intermediate) Mg ha⁻¹ yr⁻¹. Class T plus L uplift is 1.16 and 1.81.

## Round 4 disposition

| r4 | Status | Reason |
|:--|:--|:--|
| R4-1 | PARTIAL | Group intercepts remove the mean level term (Σb/ΣΔ) that drove the ratio. The slope is still exposed to A0 error that covaries with D inside a group (R5-1), and "so the slope contrast is not driven by it" claims too much |
| R4-2 | CLOSED | Uninformative, HR favored and unresolved are assigned; k kept must include 1. Precedence gaps remain (R5-4) |
| R4-3 | CLOSED | Gate F closes on 25% only; 15% and 35% are reported and flagged sensitive |
| R4-4 | CLOSED | HR bullet now points to rule 4 and the survivor increment ratio |
| R4-5 | CLOSED | The bound the arms can reach, with missing stands at A0, is reported |

## Points tested and not defects

- Measurement error in obs sits in Y, not in the regressor, so it does not attenuate k. It widens intervals. Under the HR outcome both upper limits must sit below 1, so noise makes "HR favored" harder to reach, not easier. D is exact model output.
- Heteroscedasticity leaves the OLS slope unbiased, and the paired plot bootstrap carries it into the intervals.
- Pass and HR favored cannot both hold: pass needs the k kept interval to include 1, and HR needs its upper limit below 1.

## New findings

**R5-1 SHOULD. A0's proportional error and its nonlinear RF trend load onto k.** Plan: "each group with its own intercept and a common linear RF covariate ... so the slope contrast is not driven by it." T multiplies the diameter increment, so D scales with A0's own predicted increment. If obs moves with predA0 at a slope s below 1, then Y contains (s minus 1) predA0, and k_g picks up (s minus 1) Cov(predA0, D | RF) / Var(D | RF). Under HR this term need not match between groups, because the groups differ in stock and intensity, which is the same gradient R4-1 named. A common linear RF slope also forces one A0 trend on both sides of a threshold that, under A1, is RF itself. The groups share almost no RF range, so the slope comes from a pooled fit, and any curvature leaks into k through the RF and D correlation. **Repair:** within group, fit Y ~ group + group:ns(RF, df 2) + group:predA0 + group:D. Then k is identified from tst and d / Dq variation at a fixed A0 increment. Delete "is not driven by it" or change it to "is not driven by A0's level or linear RF trend".

**R5-2 SHOULD. The D spread floor does not measure informativeness.** Plan: "whose D has a standard deviation below 0.05 Mg ha⁻¹ yr⁻¹ ... is uninformative." With a residual SD near 1.9 and n = 30, a D SD of 0.05 gives a k standard error near 1.9 / (0.05 × √30) ≈ 7. The floor is about 4% of the class uplift, so it will almost never bind, and it applies to raw D even though k is identified from D after the covariates are partialled out. A wide k kept interval also passes "includes 1" easily, so imprecision helps the HG pass. **Repair:** call a group uninformative when the bootstrap 95% interval of its k is wider than 1.0 (it cannot separate 0 from 1). Report the SD of D after the covariates are partialled out.

**R5-3 SHOULD. Stands with D identically 0 enter the groups.** T acts only with a known tst. That leaves 16 heavy (221 minus 205) and 13 intermediate (191 minus 178) stands at D = 0 in every arm, but they can still be "kept" or "threshold ineligible". They act as leverage points that tie the slope to A0's error on stands with unknown tst. **Repair:** restrict both rule 4 groups to stands with a known tst. Report the count dropped.

**R5-4 NOTE. Rule 4 precedence and scope.** (i) The plan does not say whether "HR favored" needs the pattern in both classes, or which outcome wins when heavy and intermediate differ, for example one uninformative and the other HR. **Repair:** apply the outcomes in their listed order, uninformative first, and require HR in both classes. (ii) "includes 1 [swept with the margin]" names no parameter to sweep. **Repair:** make it "k kept interval intersects [1 minus m, 1 plus m]" with m equal to the contrast margin, or drop the bracket. (iii) Say whether "contrast inside ±0.25" refers to the point estimate. Tie the 0.25 to the swept margin.

**R5-5 NOTE. Rule 7 inherits the new "uninformative" outcome.** In the smaller New Hampshire and Vermont set, rule 4 groups below 30 stands would read as "not adopted". The plan treats a missing 14.1 gap there as leaving rule 7 open. **Repair:** state that an uninformative rule 4 in the confirmation set leaves rule 7 open.

No other wording or cross reference errors found in the changed text. Rule numbering and gate references are unchanged and consistent.

Verdict: registrable after SHOULD fixes (R5-1 to R5-3).
