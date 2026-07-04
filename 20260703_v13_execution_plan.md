# FVS-ACD v13 execution plan: concrete next steps

*3 July 2026. Turns the v13 roadmap into ordered, actionable work. v12.10 is the operational August version
(competitive with OSM, ahead on planted and on biological realism, honest about the PCT and QC-edge limits).
v13 fixes those limits at the equation level rather than with levers. Plaintext math, no em dashes.*

## What v13 must fix (the honest limits v12 could not close with levers)

1. Top height over-predicts (increment 1.9x too fast NB, 6.4x QC), which inflates volume; a lever only
   corrected the level, not the increment.
2. The management effect is a capped constant (the 1.6 clamp) that does not transfer across provinces for
   PCT; it needs a pooled, generalizable fit.
3. No prediction intervals; v12 reports point predictions only.
4. Climate is not a first-class driver.

## Settled going in (do not relitigate)

Site metric is decided: keep ESI (the bake-off showed BGI and CPSI do not beat it for height and tie for
diameter growth). The self-thinning is the composition and ecoregion aware brms SDImax from v12.9.x. The
independent benchmark on FIA NSVB with the multi-dimensional scorecard (bias, RMSE, EF, TOST equivalence,
Bakuzis) is the standing evaluation, and the MagPlot and recent-FIA test sets stay held out of any fit.

## Sequence, dependencies, and first steps

v13.0 domain and height anchor (task 72). Independent of the others, do first. Formalize the Acadian-core
operational domain as an ESI-coverage and ecoregion mask, and recalibrate the ESI-to-dominant-height-anchor
so the top-height INCREMENT is unbiased, not just the level, base-age invariant. First step: fit dominant-
height increment as a function of ESI, current height, and an age proxy on the ME/NH/VT remeasurement pairs,
and compare to the current A-from-ESI anchor. Payoff: unbiased height removes most of the residual volume
over-prediction at its source, which is the highest single-metric leverage.

v13.1 hierarchical mortality, ingrowth, and management (task 73). REDIRECTED 4 July 2026: management moves
to the growth model and merges with v13.2. The 3 to 4 July runs established that the management effect is a
growth (diameter-increment) release, not a mortality effect. On the growth scale it is cleanly identified
and poolable (planted survivor diameter increment +0.087 cm/yr t 26; brms posterior planted gross basal-area
release +0.125 m2/ha/yr, 95 percent +0.076 to +0.172, probability positive 1.0; partially pooled release
beats a capped constant in 5 of 6 leave-one-region-out regions; hierarchical dAIC over capped 8355). On the
hazard scale the same effect is negligible and unidentified: the glmer reference management terms are
non-significant (treated p 0.16, planted p 0.065), the overnight brms mortality fit did not converge (max
Rhat 3.86, 56 divergences) and both HR intervals span 1, and the region management-slope SD (1.21) dwarfs its
mean (0.25) because the effect is not there. So v13.1 splits: the mortality and ingrowth hierarchical refit
(region, ecoregion, forest-type random effects, brms SDImax asymptote) proceeds without a management hazard
term, and the management release becomes a hierarchical predictor in the v13.2 diameter-growth refit
(region-pooled slope on a managed indicator, forest-type and ecoregion intercepts). This still replaces the
capped 1.6 modifier with a pooled effect that transfers out of region and closes the v12.10.1 open item (the
exact per-tree diameter amplitude), just on the correct scale. Design matrix and both fits are built
(20260704_v131_growthscale_results.md). Remaining: the NB versus QC province transfer needs the provincial
managed remeasurement data (the August ask), which FIA cannot supply.

v13.2 increment refit, management release, and prediction intervals (task 74). Now absorbs the v13.1
management effect. Depends on v13.0 (shared site term) and the expanded data. Refit or recalibrate the Kuehne
diameter and height growth with the ESI term, add management as a hierarchical predictor (region-pooled slope
on a managed indicator with forest-type and ecoregion intercepts, per the 4 July growth-scale result),
enforce growth-yield compatibility, and propagate parameter and residual uncertainty into per-prediction
credible intervals, the scorecard dimension v12 fails. First step: quantify current increment residual
structure versus ESI, size, and density to decide refit versus recalibration, and fold in the growth-scale
management design matrix already built (v131g_fitset.rds on Cardinal).

v13.3 climate scenario, data expansion, and scorecard CI (task 75). Ongoing and partly parallel. Add the
ESI 2030 and time-varying surface as a separate forward scenario mode (never benchmarked on). Expand the
fitting data (full MagPlot, SILC long-horizon, remeasured FIA across ME, NH, VT, and the NB and NS PSPs),
holding the benchmark out. Automate the multi-dimensional scorecard as a standing CI gate so every v13
candidate is scored against v12.10 and OSM automatically and regressions are caught.

## Gating

Each v13 step is adopted only if it beats or holds v12.10 on the multi-dimensional scorecard out of sample
on BOTH tails and passes the Bakuzis relations and the plateau, the same red-team and stress-test discipline
used for v12.10. If a step does not clear that bar, it is documented and parked, not shipped.

## Timing

August is a v12.10 conversation, not v13. v13 is the fall arc. Order of value: v13.0 (height) and v13.1
(hierarchical management and mortality) are the two that matter most and are largely independent, so they
can run in parallel once the design matrices are built. v13.2 and v13.3 follow.

## What to bring back from August

The provincial partners hold the data v13 needs (NB and NS PSP treatment histories, provincial site
surfaces, managed remeasurements). The August meeting is the moment to ask for a harmonized data-sharing
arrangement, which directly unblocks v13.1 and the data expansion in v13.3.
