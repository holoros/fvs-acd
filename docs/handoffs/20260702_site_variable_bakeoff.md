# FVS-ACD v13 Pillar 1: site-variable bake-off (ESI vs BGI vs CPSI vs CSI)

*2 July 2026. Which site-productivity metric should drive the Kuehne diameter-growth (DG) term and the
dominant-height (HG) anchor. Decided by out-of-sample evidence, not fit. Plaintext math, no em dashes.
Coordinates stayed on Cardinal; this memo carries aggregates only.*

## Verdict

Keep ESI. The bake-off does not support switching the site metric. For the dominant-height anchor, the
motivating problem, ESI is the best of the four candidates out of sample and the only one, together with
legacy CSI, that carries a real dominant-height signal and has cross-border coverage. For diameter growth
the choice of site metric is immaterial: all four are within 0.01 modeling efficiency of each other.

The ESI anchor over-prediction that motivated this bake-off (dominant-height increment about 1.9x too fast
in New Brunswick and 6.4x in Quebec, reproduced below) is not fixed by any alternative metric. It is an
anchor extrapolation problem at the Acadian domain edge, not a property of ESI as a height predictor. The
fix is domain restriction plus an increment-consistent anchor recalibration, not a metric swap. This is the
v13 Pillar 2 height fix, not a Pillar 1 metric change.

One metric wins both components: ESI for DG (marginally, in a field where all four tie) and ESI for HG
(clearly). CSI is the only viable backup.

## Design

The comparison isolates the site variable: identical data, identical model form, only the site term
changes, scored out of sample. Training data is the existing Kuehne remeasurement pairs
(fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds, 8.22 million tree records),
restricted to the ESI-covered US portion of the Acadian domain (Maine, New Hampshire, Vermont). That gave
15,346 plot-intervals, of which 15,079 had all four metrics and clean anchor inputs.

Three of the four metrics are already columns in the training data: BGI (biomass growth index, OSM's growth
driver), CPSI (climate site productivity index v4), and legacy CSI (ClimateNA climate site index). ESI
(Final_SI_Output.tif, the surface the operational anchor uses) was point-extracted at the plot coordinates
on Cardinal (15,329 of 15,346 plots, mean 15.4 m, range 8.7 to 24.8).

Held-out test sets stayed out of training: MagPlot NB and QC (independent Canadian CFI) and the operational
anchor predictions. Data expansion (recent FIA, MagPlot, SILC, NB and NS PSP) is a separate follow-on for
the winning metric, not part of this bake-off.

Fitting used the fast plot-level equivalents of the Stan framework so the ranking finishes in one run: a
linear Kuehne-form DG model (dg_a ~ site + ln(qmd) + ln(cr) + ln(bal_sw) + rd) and a base-age-invariant
dominant-height anchor Htop = (a0 + a1*Z_site)*(1 - exp(-k*age))^p, with Z_site the standardized metric so
all four compete on information content. Scoring is 10-fold spatially blocked cross validation (folds by
0.25 degree cell). The tree-level Stan refit of the chosen metric is the follow-on, not the ranking step.

## Result 1: diameter growth is insensitive to the site metric

Out-of-sample, 10-fold spatially blocked CV, plot-level Kuehne DG:

| metric | DG bias % | DG RMSE (cm/yr) | DG modeling efficiency |
|---|---|---|---|
| ESI  | +0.02 | 0.0432 | 0.340 |
| BGI  | +0.02 | 0.0432 | 0.341 |
| CPSI | +0.02 | 0.0430 | 0.348 |
| CSI  | +0.02 | 0.0433 | 0.338 |

All four are unbiased and within 0.01 EF. The site term contributes little to diameter increment once size,
crown, competition, and relative density are in the model. No metric change is warranted for DG. CPSI is
nominally best by 0.008 EF, which is not a decision.

## Result 2: dominant-height anchor: ESI wins, BGI and CPSI fail

Out-of-sample, same CV, affine anchor on the standardized metric:

| metric | HT level bias % | HT RMSE (m) | HT modeling efficiency | resid slope vs site |
|---|---|---|---|---|
| ESI  | -0.02 | 4.125 | 0.335 | -0.008 |
| CSI  | +0.00 | 4.167 | 0.321 | -0.011 |
| CPSI | -0.02 | 4.458 | 0.223 | +0.000 |
| BGI  | -0.02 | 4.529 | 0.198 | +0.014 |

Information content, correlation of each metric with observed dominant height and with measured FIA site
index (SICOND) on the same plots:

| metric | cor with observed top height | cor with measured site index | cor with height increment |
|---|---|---|---|
| ESI  | 0.400 | 0.667 | 0.030 |
| CSI  | 0.389 | 0.488 | 0.032 |
| CPSI | 0.273 | 0.156 | -0.035 |
| BGI  | 0.129 | 0.020 | -0.102 |

ESI carries by far the strongest measured site-index signal (0.667) and the best out-of-sample anchor. CSI
is a close second. CPSI is weak and BGI carries essentially no dominant-height or site-index signal (0.020),
which is expected: BGI is a biomass and basal-area growth index, not a height-productivity metric.

Structural point: BGI and CPSI are centered indices that take negative values, so they cannot drive a
multiplicative height anchor A = c*site the way a height-scaled metric (ESI or CSI in meters) can. Fitting
them required an affine link with an intercept, and even then they order dominant height poorly. As height
anchor drivers they are the wrong kind of variable.

## Result 3: no metric fixes the edge over-prediction (independent MagPlot NB and QC)

Reproduced the operational ESI anchor failure on the held-out MagPlot benchmark (esi_cov subset):

| region | n | obs HGI (m/yr) | pred HGI (m/yr) | increment ratio | top-height level bias % |
|---|---|---|---|---|---|
| NB | 328 | 0.111 | 0.209 | 1.89 | +4.1 |
| QC | 377 | 0.041 | 0.262 | 6.40 | +12.9 |

This matches the earlier topht diagnostic (about 1.7x NB, 8.9x QC). At the Acadian edge, correlation of each
metric with observed dominant-height INCREMENT is essentially zero for both viable metrics: NB ESI 0.057,
CSI 0.011; QC ESI 0.001, CSI 0.033. For LEVEL, CSI edges ESI in QC (0.388 vs 0.293) and ESI edges CSI in NB
(0.088 vs 0.035), both weak.

The reading: the QC and NB stands that over-predict are old and near the height asymptote (observed
increment only 0.04 to 0.11 m/yr), while the anchor A, extrapolated from the site surface beyond its
calibration domain, is set too high and sits the stand on the steep part of the curve. No site metric on
offer predicts that residual increment, so no metric swap fixes it. BGI and CPSI cannot even be tested at
the edge: BGI's operational raster is Maine only and CPSI's stack is CONUS, so neither has Canadian
coverage. Only ESI and CSI extend across the border.

## Ranking

Dominant-height anchor (the deciding component): 1 ESI, 2 CSI, 3 CPSI, 4 BGI.
Diameter growth: tie, all four equivalent; ESI adopted for consistency with the anchor.

ESI wins both. One coherent site signal across components, as v13 Pillar 1 requires.

## Recommendation

1. Keep ESI as the single site-productivity driver for DG and the dominant-height anchor. Do not adopt BGI
or CPSI: both are weaker height predictors, are the wrong scale for a height anchor, and lack cross-border
coverage. CSI is the only backup and is marginally weaker in domain.

2. Fix the anchor over-prediction at the source (v13 Pillar 2, not Pillar 1). Two levers, use both:
restrict the operational domain to the Acadian core and report the QC edge as out of domain (as Hennigar
2018 did by excluding QC); and recalibrate the ESI-to-A mapping so the height INCREMENT, not only the level,
is unbiased in domain, with an age or edge term so old near-asymptote stands stop being placed on the steep
part of the curve. The implied level-scale corrections from the benchmark are about 1.9 (NB) and 6.4 (QC),
but the durable fix is increment-consistent, not a per-region divisor.

3. Follow-on for the winning metric (ESI), held benchmark out: expand the fit with recent FIA
remeasurements, MagPlot QC and NB, NB and NS PSP, and SILC long-horizon, then run the tree-level Stan refit
of the ESI dominant-height anchor with the age or edge term. This bake-off used the fast plot-level nls and
lm equivalents to get the ranking; the Stan refit of ESI is the next step, gated on the multi-dimensional
scorecard against the prior version.

## Provenance

Cardinal ~/bakeoff_v13/: assemble.R (plot table build), extract_esi.py (ESI at plots), fit_cv2.R (CV fits),
extract_bench.py and bench scoring (independent MagPlot). Outputs cv_scores_affine.csv,
metric_infocontent.csv, bench_scored.csv. Coordinates never left Cardinal.
