# Bakuzis diagnostic and self-thinning recalibration target for AcadianGY 12.7.0

*30 June 2026. Long-horizon Bakuzis diagnostic of v12.7.0 and a self-thinning parameter sweep that pins
the recalibration that fixes the mature-stand over-prediction. Plaintext math, no em dashes.*

## Diagnostic: the basal-area trajectory never plateaus

Projecting a young dense spruce-fir stand (3000 stems/ha, dbh 2 to 5 cm) to 120 years on three ESI
classes with v12.7.0:

| site | BA max | age of BA max | TPH at 120 | QMD at 120 | dom HT at 120 |
|---|---|---|---|---|---|
| ESI 12 | 35.2 | 120 | 996 | 21.2 | 22.3 |
| ESI 16 | 36.1 | 120 | 994 | 21.5 | 23.0 |
| ESI 20 | 36.5 | 120 | 1073 | 20.8 | 23.8 |

The basal area climbs to 35 to 36 m2/ha and is still rising at age 120 (the maximum is at the last age on
every site), and the stand keeps about 1000 stems/ha at age 120. A biologically realistic Acadian
spruce-fir stand plateaus in basal area by roughly age 80 to 100 at a fully-stocked maximum near 28 to 32
m2/ha and self-thins to far fewer, larger stems. So the density-dependent mortality is too weak at high
stocking: the trajectory does not reach the self-thinning line, and on mature and dense stands the model
keeps adding basal area. That is exactly the mechanism behind the short-interval increment over-prediction
on mature stands seen in the benchmark (QC slow stands +0.27 m3/ha/yr, the regional Maine hot spot).

This is the Bakuzis yield-density / self-thinning relation failing on the high-density end: the asymptote
(set by maximum SDI and the SDImort onset and slope) sits too high.

## Recalibration sweep: onset is the dominant lever

Sweeping the SDImort onset (relative density where density-dependent mortality begins) and beta (how
sharply it rises), ESI 16, same young dense stand to 120 yr:

| onset | beta | BA max | age of max | BA at 120 | TPH 120 |
|---|---|---|---|---|---|
| 0.55 (current) | 0.10 (current) | 36.0 | 120 | 36.0 | 1020 |
| 0.45 | 0.10 | 31.4 | 120 | 31.4 | 975 |
| 0.45 | 0.20 | 28.1 | 120 | 28.1 | 961 |
| 0.40 | 0.20 | 25.8 | 27 | 25.8 | 940 |
| 0.45 | 0.30 | 26.9 | 120 | 26.9 | 955 |
| 0.35 | 0.30 | 23.2 | 25 | 22.1 | 907 |

Onset is the dominant lever: lowering it from 0.55 to 0.45 drops the basal-area asymptote from 36 to about
28 to 31 m2/ha; beta sharpens the plateau (higher beta makes the basal area peak mid-rotation and level
rather than climb to age 120).

## Recommended recalibration target

onset 0.45, beta 0.20 (from 0.55, 0.10). This brings the basal-area asymptote to about 28 m2/ha, inside
the realistic fully-stocked Acadian spruce-fir range (28 to 32), down from the current 36, and makes the
trajectory level off instead of climbing indefinitely. It is a targeted change: onset 0.45 still leaves
mid-density growing stands (relative density below 0.45) largely untouched, so the stands that are already
near-unbiased on the independent benchmark (NB MagPlot, recent Maine FIA) should stay near-unbiased, while
the mature, dense, over-predicting stands self-thin sooner. This is the Bakuzis-anchored, stand-type-aware
fix, not a global mortality bump.

## Required validation before adopting (the next step)

Re-run the independent benchmark with onset 0.45, beta 0.20 and confirm BOTH tails:
1. Mature / slow stands (QC in-domain, the regional pool): volume-increment over-prediction drops toward
   zero.
2. Growing stands (NB MagPlot, recent Maine FIA): bias stays near zero, does NOT swing into
   under-prediction.
If the growing-stand tail degrades, back off onset toward 0.50 or trade beta. The acceptance criterion is
both tails near zero on independent data, with the long-horizon basal area plateauing near 28 to 32 m2/ha
(the Bakuzis yield-density maximum).

## Caveats
The sweep uses one pure spruce-fir initial condition on ESI 16; confirm the asymptote target by forest
type (hardwood and mixedwood maxima differ) and across the site gradient before finalizing. The SDImax
brms posterior (earlier in the project) is the external anchor for the per-forest-type maximum.

## Files (Cardinal)
- Trajectory: ~/magplot/verify/traj_v1270.R, traj_v1270.csv. Sweep: traj_sweep.R, traj_sweep.log.
- v12.7.0 model: ~/AcadianGY_12.7.0.r (ops$sdimort.onset, ops$sdimort.beta are the levers).
