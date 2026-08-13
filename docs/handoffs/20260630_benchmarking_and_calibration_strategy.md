# FVS-ACD benchmarking and calibration strategy: independent data, the mortality gap, Bakuzis-first

*30 June 2026. Synthesis at a decision point: whether the stand-level constraint is working, what
independent data to benchmark on, and how to calibrate. Plaintext math, no em dashes.*

## 1. Is the stand-level constraint working? Yes for growth; the gap is mortality.

Decomposing the observed annual basal-area dynamics on the full remeasurement record (41,661 plot
intervals): observed gross basal-area growth is about 0.58 m2/ha/yr (0.77 in Maine), but the observed
net change is only about 0.074 m2/ha/yr. The difference is mortality, about 0.5 m2/ha/yr, which removes
roughly 85 percent of gross growth. These are dynamic-equilibrium stands.

The model's gross growth matches observed (the Chen stand-level basal-area-increment cap is doing its
job, holding summed tree diameter growth to the right stand-level total). But to land at a net of +0.15
m2/ha/yr it is removing only about 0.43 m2/ha/yr of mortality, against the observed 0.5. So mortality is
under-applied by roughly 15 percent, and that deficit is exactly the net over-prediction. The
stand-level growth constraint strategy works; the one component to fix is mortality (and, equivalently,
where the basal-area trajectory plateaus, the asymptote in the Chen logistic, tied to maximum SDI).

This is consistent across every diagnostic: diameter growth is fine or slightly low, basal area and
volume over-accumulate because too few stems die. It is one component, not a structural failure.

## 2. Benchmark on independent data, not the training database

The honest point: the regional pool I had been benchmarking on (FIA 1999 to 2005, NB and NS PSP, PEF) is
largely the data the Kuehne (2022) increment and Chen (2025) stand-level equations were fit on. That is
not an independent test, and it is also a small sample (we used 682 of 18,534 available plots). We have
much better, genuinely independent options:

| dataset | scope | independence |
|---|---|---|
| MAGPlot Quebec | 12,892 sites | large, untouched |
| MAGPlot New Brunswick | 7,609 sites (used 262 pairs) | barely tapped |
| Recent Maine FIA | buildable from ME_PLOT / ME_TREE (post-2005 remeasures) | independent in time |
| SILC Seven Islands, long-horizon | 8 long-interval pairs | independent, long-horizon |

Recommendation: retire the training-data regional benchmark as the headline and rebuild the benchmark
on these independent sets, MAGPlot (Quebec plus New Brunswick) and recent Maine FIA for breadth, the
Seven Islands long-horizon pairs for the multi-decade check. The MAGPlot New Brunswick result we already
have (basal area -2.6 percent, R2 0.87) is the right kind of number; it just needs to be scaled up
across Quebec and recent FIA so the bias estimate is representative rather than a 682-plot draw (which is
why the Maine bias wandered from +4.9 to +11.1 across draws).

## 3. Calibrate to long-term Bakuzis, validate short-term on independent data

The over-prediction lives on mature, near-equilibrium stands, and it is about where the basal-area
trajectory plateaus (the asymptote, set by maximum SDI) and the mortality that holds it there. Those are
long-term properties. The right way to fix them, and the stated preference, is to calibrate against the
long-term, law-like Bakuzis relations, the asymptotic yield-density and Reineke self-thinning and
Eichhorn, so the trajectory plateaus at the biologically correct maximum, rather than tuning mortality
to minimize a short-term remeasurement residual (which risks gaming a few-year prediction at the cost of
the rotation-scale behavior).

Concretely, the next refinement is a maximum-SDI and stand-mortality calibration whose target is the
long-term Bakuzis matrix (the stands must self-thin to the right maximum density and basal area), with
the independent short-term data (MAGPlot, recent FIA) used as an out-of-sample check, not as the fitting
objective. The Chen (2025) comparison supports this: the stand-level approaches are largely unbiased and
the architecture is sound; the asymptote and mortality are the one place to refine.

## 4. The balancing act, stated plainly

Short-term remeasurement accuracy and long-term biological realism are both required and can trade off.
The position here: anchor the calibration on the long-term Bakuzis behavior (the model must self-thin to
the correct maximum density and plateau where real Acadian stands plateau), and treat the independent
short-term datasets (MAGPlot Quebec and New Brunswick, recent Maine FIA) as the validation that the
calibration did not break short-horizon accuracy. Do not tune mortality to the short-term increment in
isolation.

## Recommended next steps

1. Build the independent-data benchmark: MAGPlot Quebec and New Brunswick remeasurement pairs and recent
   Maine FIA pairs, scored on the annual increment (the honest growth-model metric), plus the Seven
   Islands long-horizon pairs.
2. Diagnose the basal-area asymptote: compare where observed mature stands plateau against the model's
   maximum SDI and the Chen logistic asymptote, by forest type.
3. Refit maximum SDI and stand mortality with the long-term Bakuzis matrix as the calibration target,
   validated out of sample on the independent benchmark.
4. Hold the Zenodo deposit until the independent benchmark and the Bakuzis-anchored calibration are done.

## Files
- Decomposition: `scripts/decomp_obs.R`. Annual-increment stress test: `scripts/annual_increment_stress.R`,
  `20260630_annual_increment_stress_test.md`. Chen et al. (2025) MCFNS 17(1):1-13 (stand-level approaches).
