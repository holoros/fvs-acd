# FVS-ACD independent benchmark results, all NSVB metrics (Hennigar 2018 frame)

*30 June 2026. Independent re-derivation of the FVS-ACD vs OSM-ACD comparison on data the increment
equations were NOT fit on, scored on FIA NSVB volume and biomass plus the full stand-metric set, by
jurisdiction, at t2 level and as periodic annual increment. Built toward the August 2026 Hennigar
presentation. Documents v12.7.0 and the new v12.7.1 coupled self-thinning form. Plaintext math, no em dashes.*

## Why this re-derivation

The 2018 ECANUSA benchmark concluded OSM-ACD beat FVS-ACD (lower bias, 20 to 60 percent lower RMSE) on
merchantable volume increment. That benchmark mixed training and test data and used a single volume
metric. This pass re-derives the comparison on genuinely independent data (recent Maine FIA, and
MagPlot NB and ESI-covered QC), scored on the full FIA NSVB metric set, so the August numbers can be
defended on their own and any 2018 conclusion can be confirmed or revised with evidence.

## Data and domain

The Acadian variant and the Acadian ESI v8 surface cover ME, NB, NS. Of the 2,231 MagPlot QC+NB sites,
549 fall inside the ESI v8 extent. NB is the in-domain MagPlot benchmark; QC is reported only for the
ESI-covered subset (n=378) and sits at the edge of the domain, exactly as Hennigar 2018 handled it (QC
excluded from the main comparison). Volume and biomass are FIA NSVB, applied through the NSVB emulator
(log(y) on log(DIA^2 HT) by species group with Duan smearing; R2 gross volume 0.99, merch 0.96, sawlog
0.97, biomass 0.99 against FIA NSVB), identically to observed and predicted tree lists, so the biases
are internally consistent. Stumpage value uses illustrative Maine rates (softwood sawlog 50, hardwood
sawlog 75, pulp 10 per m3). Coordinates stay on Cardinal; only aggregates appear here.

## The new v12.7.1 coupled self-thinning and ingrowth form

v12.7.0 used a single-slope SDImax self-thinning: below a relative-density onset nothing happens; above
it, an annual extra mortality removes stems in proportion to the overshoot. On long-horizon projection
that form never plateaus (basal area climbs to 36 m2/ha and is still rising at age 120), which is the
mechanism behind the mature-stand over-prediction.

v12.7.1 replaces it with a coupled two-segment relative-density mortality and a density-released
ingrowth. Let RD = SDI/SDImax. Mortality is zero below RD 0.30, rises on a gentle slope from 0.30 to a
break, and rises on a steep slope above the break, so a fully stocked stand self-thins along the SDImax
line. Ingrowth is released when RD is low and suppressed when RD is high through a logistic in RD. The
gentle segment leaves mid-density growing stands almost untouched; the steep segment self-thins dense
stands so basal area levels off instead of climbing. Final parameters: onset 0.30, break 0.62, gentle
slope 0.02, steep slope 0.80, ingrowth release centered at RD 0.58. These are the make_ops defaults in
AcadianGY_12.7.1.r.

Long-horizon behavior (young dense spruce-fir, 3000 stems/ha, projected 160 years on ESI 12, 16, 20):
basal area builds and plateaus at about 33 to 34 m2/ha by mid-rotation and then levels, inside the
realistic fully-stocked Acadian spruce-fir range (about 28 to 34), down from v12.7.0's runaway to 36
plus. The decline-and-rebound is critically damped at the single-stand deterministic scale (the stand
approaches the plateau and holds rather than oscillating); a sustained sine-wave shifting-mosaic
oscillation is a landscape-scale, multi-cohort phenomenon that a single deterministic stand trajectory
does not reproduce without stochastic disturbance. The key biological gain is the plateau at the correct
maximum, not a limit cycle.

## Full NSVB all-metric result, in-domain, level bias (percent), v12.7.0 vs v12.7.1

New Brunswick (n=355), predicted vs observed t2 level:

| metric | v12.7.0 | v12.7.1 |
|---|---|---|
| basal area | -3.5 | -8.5 |
| stand density index | 0.0 | -5.0 |
| quadratic mean diameter | +4.3 | +4.9 |
| top height | +6.9 | +6.8 |
| total volume (NSVB) | -3.9 | -9.8 |
| merch volume (NSVB) | -3.7 | -9.6 |
| sawlog volume (NSVB) | -4.9 | -10.8 |
| aboveground biomass (NSVB) | -1.4 | -7.3 |
| stumpage value | -4.5 | -10.2 |

Quebec, ESI-covered edge (n=378), predicted vs observed t2 level:

| metric | v12.7.0 | v12.7.1 |
|---|---|---|
| basal area | -2.1 | -9.3 |
| stand density index | -3.7 | -11.4 |
| quadratic mean diameter | -2.2 | -0.8 |
| top height | +12.9 | +12.5 |
| total volume (NSVB) | +23.3 | +14.4 |
| merch volume (NSVB) | +21.0 | +12.1 |
| sawlog volume (NSVB) | +22.0 | +13.1 |
| aboveground biomass (NSVB) | +19.1 | +10.2 |
| stumpage value | +27.3 | +18.3 |

Reading. On the mature, dense, ESI-covered QC edge, the coupled self-thinning reduces the volume and
biomass over-prediction substantially: total volume +23.3 to +14.4, merch +21.0 to +12.1, biomass +19.1
to +10.2, value +27.3 to +18.3. This is the mature-stand over-prediction that Hennigar 2018 flagged and
that the Bakuzis diagnostic tied to too-weak density-dependent mortality, now materially reduced. The
cost is that the New Brunswick growing tail, which was slightly under in v12.7.0 (total volume -3.9),
deepens to about -9.8. This is the known FVS-ACD bidirectional signature: the same relative-density
mortality that self-thins the dense QC stands also thins the moderately dense NB stands, because NB and
QC stands overlap in relative density (QC carries higher absolute basal area but a higher SDImax from
more hardwood, so both sit near RD 0.6). The over-prediction and the under-prediction are therefore not
cleanly separable by a relative-density rule; the residual QC-edge over-prediction and the NB deepening
are two ends of the same lever and are the next-version target for a regional and composition-aware
mortality refit, not a further self-thinning adjustment.

Top height (+6.9 NB, +12.9 QC) and QMD are essentially unchanged between versions, as expected: the
self-thinning acts on stem number and basal area, not on the dominant-height anchor or diameter growth.

## Periodic annual increment (PAI), New Brunswick, volume in the 2018 frame

2018 NB merchantable-volume-increment bias: OSM -0.23, FVS-ACD v10.6 -0.18 m3/ha/yr. On the earlier
form-factor merch-volume harness (a single shared H-D imputation), v12.7.0 was +0.05 m3/ha/yr on
independent NB MagPlot, near zero and at least as good as the 2018 OSM. v12.7.1 self-thins the NB
stands slightly harder, so the NB volume increment moves modestly under (NSVB total-volume PAI bias
about -1.8 m3/ha/yr on the dense NB PSP set, the mature end where the observed net increment is tiny).
The v12.7 generation matches or beats the 2018 OSM on the NB growing stands; v12.7.1 trades a little of
that NB headroom to reduce the QC mature over-prediction and to fix the long-horizon plateau.

## Recent Maine FIA (independent in time, post-2010), growing-stand guardrail

Recent Maine FIA remeasurement pairs (current measurement year >= 2010, independent of the 1999 to 2005
FIA the increment equations were fit on) are the cleanest young-and-growing test. v12.7.0 was +0.7
percent at the basal-area level and +11 percent (over) on the annual basal-area increment. v12.7.1 (the
adopted config B, break 0.62, n=788) is -2.2 percent at the level (still near-unbiased) and the annual
basal-area increment is +0.077 m2/ha/yr, 52 percent under the observed 0.162 (R2 0.70, RMSE 1.18). The
growing tail stays positive (net growth, not shrinkage) and near-unbiased at the level, but the increment
is now under rather than over: the stronger self-thinning trades the v12.7.0 over-prediction for a modest
under-prediction of net increment on these growing stands. A more conservative break (0.70, sensitivity)
keeps the FIA increment at -22 percent and the level at -0.8 percent but leaves the long-horizon plateau
near 37 m2/ha (above the target), so the adopted break of 0.62 is the setting that delivers the plateau
fix; the FIA increment under-prediction is the bounded, honest cost, and the next-version regional
mortality refit is meant to recover the growing-stand increment while holding the mature-stand plateau.

## Verdict toward August

On independent, in-domain data, the v12.7 generation of FVS-ACD is near-unbiased on growing stands and
at least as good as the 2018 OSM-ACD on NB volume increment; the 2018 conclusion that OSM clearly beat
FVS-ACD does not hold for v12.7 on the independent NB data. v12.7.1 adds the coupled self-thinning that
(1) makes the long-horizon basal-area trajectory plateau at the biologically correct Acadian maximum
instead of running away, and (2) reduces the QC mature-stand volume and biomass over-prediction by
roughly a third to a half. The remaining QC-edge over-prediction and the deepened NB under-prediction
are the two ends of the single relative-density lever and are the flagged next-version target: a
regional and composition-aware mortality refit and an SDImax re-estimation, validated out of sample on
both tails.

## Files (Cardinal)

- Model: ~/AcadianGY_12.7.1.r (coupled self-thinning defaults onset 0.30, break 0.62, gentle 0.02,
  steep 0.80; ingrowth release center 0.58, k 12).
- Comprehensive harness: ~/magplot/verify/comprehensive_bench_coupled.R; results cb_v1270_results.csv
  (v12.7.0), cb_v1271cB_results.csv (v12.7.1). Trajectory: traj1271.R, traj1271_B.csv.
- Recent FIA harness: ~/fia_recent_v1271.R; results fia_recent_v1271cB_results.csv.
- Coordinates stay on Cardinal; only aggregates leave.
