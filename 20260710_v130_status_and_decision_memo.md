# FVS-ACD v13.0 Migration: Status and Decision Memo

**Author:** Aaron Weiskittel
**Date:** 10 July 2026
**Subject:** v13.0 candidate status ahead of the 18 August 2026 Hennigar meeting

## Verdict

The shipped operational model for August stays v12.10.1. It is frozen and it holds. The v13.0 candidate carries two changes on top of that baseline, and they are not in the same place on the runway. The basal-area post-mortality increment correction is validated and ready. The region-specific dominant-height re-anchor is not yet through the gate. My recommendation is to present v13.0 in the Hennigar materials exactly as the v13 roadmap slides already frame it: components validated, joint height and basal-area calibration in active development. Nothing here changes what we ship in August.

## What v12.10.1 delivers

The frozen baseline posts a pooled in-domain bias against the independent FIA NSVB benchmark of -10.07% on basal area, +2.97% on top height, and -3.96% on total volume, with the TOST equivalence and Bakuzis consistency checks passing. That is the model of record and the number set I will stand behind on 18 August.

## What we tested

The v13.0 candidate adds a region-specific dominant-height re-anchor, expressed as `esi.anchor.coef c(intercept, slope)` and applied inside `calc_dht` by dividing predicted height by `ascale = intercept + slope*ESI` clamped to [0.85, 1.35], together with a basal-area post-mortality increment correction. We ran four gate evaluations against the frozen v12.10.1 baseline (`cb_v12101`), each on 733 remeasured MagPlot stands, aggregates only, with FIA true coordinates never leaving the compute node.

The joint configuration, refit height plus the basal-area correction, is the best operating point we have. Pooled basal-area bias improves from -10.07% to roughly -4% (NB) and top height moves to +3.8%. It failed the gate on one test only: PARK's `height_toward0` check, because top height did not move closer to zero than the +2.97% baseline, and that dragged volume and NSE with it.

The three diagnostic runs explain why. The basal-area-only run, operational height with the correction applied, is where the mechanism shows itself: basal area improves to -7.72% but pooled top-height bias blows up to +10.36%. Basal area and dominant height are strongly and positively coupled, so any upward correction to basal area inflates height, and the operational anchor does nothing to absorb it. The height-only isolation run, refit height on uncorrected basal area, also parked, because the refit coefficients are worse than operational height on the multi-year projection. The co-fit run, which iteratively re-fits the height anchor on the basal-area-corrected trajectory, did not converge: pooled in-domain top-height bias stayed frozen near +4.6% across three iterations, and the Quebec anchor saturated the `ascale` clamp ceiling, reaching 1.18 to 1.43 over ESI 17.5 to 20.2, so Quebec height cannot be pulled down any further inside the current clamp.

## What it means

Two coupled reasons keep the height re-anchor from clearing the gate. First, because basal area and height rise together, the height anchor has to be co-fit against the corrected basal-area trajectory rather than fit once and bolted on. Second, the Quebec `ascale` clamp saturates before Quebec height reaches target, so the clamp itself is now the binding constraint. The basal-area correction is not implicated in either failure. It moves pooled basal area toward zero without a sign flip once the per-year step bug is fixed, and it is good in isolation and jointly. It is ready to fold in the moment the height calibration lands.

## Paths under test and the August framing

Three concrete paths are open. We can widen the Quebec clamp and fix the co-fit driver so the anchor can be re-fit on the corrected trajectory. We can adopt a milder partial basal-area target that inflates height less and gives the anchor a shorter distance to travel. Or we freeze development at this point and document it. The basal-area correction folds in cleanly under any of the first two once height passes.

In parallel, the v13.1 track, the hierarchical mortality and ingrowth refit, is still running on the cluster with a convergence check pending, and I will report on it separately.

For 18 August: v12.10.1 is the operational model, and v13.0 is presented as components validated with joint height and basal-area calibration in active development. That is the honest state and it matches the roadmap slides as written.
