# FVS-ACD v13.1: stress test and red-team review (interim, mortality still fitting)

*22 July 2026. Stress test and adversarial review of what v13.1 has so far: the converged ingrowth
posterior and the re-nested mortality design (job 12526556 still running). Empirical checks run on
Cardinal against ~/v13_kickoff. Aggregates only; proprietary records stayed on the node. No em dashes.*

## Stress test results

### 1. Re-nest design is empirically well posed
The nested `region:eco` term the mortality repair is now fitting has 299 nonempty cells (eco codes repeat
across regions, so nesting expands 84 marginal eco levels into 299 region-by-eco combos). Median cell
n = 205; only 12.4 percent of cells have n < 10 and 9 cells have n < 3. With non-centered
parameterization, region-mean shrinkage, and the boundary-avoiding gamma(2,4) sd prior, this term should
be identified and should not reproduce the zero-boundary funnel that the free crossed eco produced. Mild
watch: the 9 cells with n < 3 contribute little and are shrunk toward their region mean, as intended.

### 2. Ingrowth overdispersion is extreme
The negbinomial shape posterior is 0.042 (95 percent interval 0.041 to 0.042), so variance is about
mu + 24*mu^2. The response is heavily zero-inflated (72.4 percent zeros) and very heavy-tailed (response
mean 1705, median 0, max about 430,000; the response is expanded recruits per hectare, not a raw tree
count). The single negbinomial is being stretched hard to cover both the zero mass and the tail.

### 3. Ingrowth is well calibrated in the middle, inflated in the tails
Observed vs fitted recruitment count by QMD class, stratified subsample:

| QMD class (cm) | obs mean | fit mean | fit/obs |
|---|---|---|---|
| < 10 | 6930 | 11098 | 1.60 |
| 10 to 15 | 1048 | 1203 | 1.15 |
| 15 to 20 | 284 | 314 | 1.10 |
| 20 to 25 | 103 | 111 | 1.08 |
| > 25 | 20 | 53 | 2.69 |

The middle of the QMD gradient is well calibrated. Both tails are over-predicted, the low-QMD developing
end at 1.60 and the high-QMD mature end at 2.69 (low absolute). Part of the tail overshoot is the
posterior-mean-of-a-shape-0.042-NB artifact, but the pattern is real.

## Red-team review

1. The ingrowth model that was built to close the developing-end UNDER-prediction actually
   OVER-predicts recruitment at the low-QMD developing end within its own CONUS fit set (1.60). This does
   not contradict the v12.11 finding, it sharpens it: the fit set is CONUS stand-level, while the gap is
   at the Maine FIA subplot (about 0.017 ha) grain. The mismatch is evidence that the developing-end
   subplot under-prediction is primarily a GRAIN and PATCHINESS problem, not a stand-level recruitment
   rate that is simply too low. A better stand-level rate alone will not close the subplot gap and could
   overshoot the whole-plot. This raises the priority of the task 3 subplot refit and lowers the odds
   that a recalibrated stand rate is sufficient.

2. Modeling expanded recruits-per-hectare as a single negbinomial with shape 0.042 is a specification
   risk. With 72 percent zeros, a hurdle or zero-inflated negbinomial (a recruitment-presence model plus
   a conditional-intensity model) is the more honest structure and would likely fix the tail inflation.
   Flag this as a candidate change for the subplot refit rather than carrying the single NB forward
   unquestioned.

3. Correction to my own last-turn framing. I called the ingrowth posterior "the principled replacement
   for the flat 2.5x." Soften that: it is the principled stand-level recruitment COMPONENT (correct
   density and composition direction, QMD down, BA up), but on this evidence it does not by itself close
   the ME subplot developing gap and must be paired with the subplot refit. Do not lead with a
   recruitment-fixed claim, consistent with the v12.11 red-team reframe 2.

4. Diagnosis reinforcement. The `gamma_lpdf: Random variable is 0` exceptions in the v5 .err are the eco
   sd hitting the zero-density boundary of its gamma(2,3) prior, the same funnel the convergence numbers
   showed. Removing the free crossed eco sd in mortality removes that boundary-hitting term directly, so
   the re-nest addresses the mechanism, not just the symptom. The identical warning was transient and
   harmless in the ingrowth fit, which converged.

5. The re-nest is well justified but not yet proven. The sparsity check supports identifiability; only
   the harvested convergence of job 12526556 confirms the funnel is gone. Confidence is high, not
   certain. If region:eco still shows a boundary sd or E-BFMI trouble, the fallback is to drop eco from
   mortality entirely (region plus fortype were both well identified).

## Not yet testable
Gate-off byte-identity, the maturity gradient, the all-sites ME/NB/QC comparison, Bakuzis, and the
long-horizon plateau all require the converged mortality posterior wired into the stand equations, which
waits on job 12526556.

## Outlined next steps
1. Harvest job 12526556 (auto-check scheduled 07:30, 23 July). Confirm mortality Rhat < 1.01, healthy
   ESS, and an identified region:eco sd. Finish the task-2 mortality-posterior comparison to the v12.11
   management-gated lever (fmin 0.13, k 12.4, RD0 0.38).
2. Subplot-grain refit (task 3) against ~/magplot/verify/multisrc/bench_mefia_subp_* (2858 units). Fit
   recruitment and mortality at subplot scale. Decide hurdle or zero-inflated NB for recruitment given
   the 72 percent zeros and shape 0.042 (recommend testing the hurdle form here).
3. Address the two managed flags (task 4): QC volume over-correction from the management gate, SILC BA
   widening. The hierarchical mortality structure replaces the hand-tuned management gate that caused the
   QC over-correction.
4. Translate posteriors to v13.1 stand equations, wire gated, prove gate-off byte-identity against frozen
   v12.10.1, then run the full v12.11 validation battery (maturity gradient with Baxter held out,
   all-sites vs base and OSM v2.26.1, Bakuzis five relations, 160-year plateau, red-team pass).
5. Route deliverables through the same report, GTR, and deck.
