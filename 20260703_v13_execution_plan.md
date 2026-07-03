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

v13.1 hierarchical mortality, ingrowth, and management (task 73). The centerpiece; depends on the design
matrix, not on v13.0. A Bayesian hierarchical refit (brms or Stan) of mortality, ingrowth, and the
management effect together, with region, ecoregion, forest-type, and management random effects and the brms
SDImax asymptote. This replaces the capped 1.6 modifier with a pooled management effect that transfers
across provinces (fixing the PCT leave-one-province-out failure the red team found) and separates the NB
growing and QC mature tails by construction rather than by a single relative-density knob. First step:
assemble the managed and unmanaged remeasurement design matrix (FIA TRTCD and STDORGCD, MagPlot management
group, NB and NS PSP treatment histories) with the grouping factors and a clean fit-versus-test split.

v13.2 increment refit and prediction intervals (task 74). Depends on v13.0 (shared site term) and the
expanded data. Refit or recalibrate the Kuehne diameter and height growth with the ESI term, enforce
growth-yield compatibility, and propagate parameter and residual uncertainty into per-prediction credible
intervals, the scorecard dimension v12 fails. First step: quantify current increment residual structure
versus ESI, size, and density to decide refit versus recalibration.

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
