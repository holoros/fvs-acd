# Enhanced five-way scorecard: equivalence testing, forest type, explicit Bakuzis

*2 July 2026. Enhancement of the Acadian FVS-ACD vs OSM scorecard for the 18 August Hennigar meeting:
adds two one-sided equivalence tests (TOST), a by-forest-type cut, and explicit per-model Bakuzis
relations, computed on the operational v12.9.x. Independent in-domain MagPlot NB and QC (n=705, NB 355,
QC 350), all volume and biomass on FIA NSVB. Plaintext math, no em dashes. Aggregates only; coordinates
stayed on Cardinal.*

## Data-integrity correction (important)

The interim five-way scorecard (five_way_scorecard.csv, 1 July) reported OSM with negative modeling
efficiency on every metric. That was a merge-order artifact: the per-model files were combined by index
joins rather than a single keyed merge, which misaligned OSM's per-stand predictions, inflated its RMSE
(for example total volume RMSE 132 vs the true 49), and drove NSE negative. Recomputed from one wide table
keyed by stand (scorecard_clean.R), with a per-model correlation of observed on predicted as an alignment
check (all models cor about 0.85 to 0.87), OSM's NSE is positive (0.70 to 0.75) and it is the most accurate
and precise model on the pooled operational domain. The "OSM is imprecise" framing is withdrawn. This does
not change the recommendation, but it changes the reason: FVS-ACD's advantage over OSM is biological
realism, QMD, transparency, and a climate-ready site driver, not precision.

## Pooled scorecard (in-domain, NSVB, predicted vs observed)

| model | mean abs level bias % | mean NSE | TOST level equiv (of 9) | total vol bias % | QMD bias % |
|---|---|---|---|---|---|
| FVS v12.5.0 | 13.0 | 0.67 | 3 | +18 | -5 |
| FVS v12.7.0 | 7.5 | 0.70 | 3 | +11 | 0 |
| FVS v12.7.1 | 5.2 | 0.68 | 6 | +5 | +1 |
| FVS v12.9.x | 4.4 | 0.71 | 6 | +3 | +1 |
| OSM v2.26.1 | 3.2 | 0.75 | 8 | +2 | +11 |

New Brunswick core (n=355): FVS-ACD v12.9.x matches or slightly beats OSM on the integrators (total volume
-7 vs OSM -8, biomass -4 vs -6, value -7 vs -9). Quebec edge (n=350): OSM better on volume (v12.9.x +11 vs
OSM +10, narrowed from v12.7.0 +24 by the anchor recalibration and composition-aware self-thinning). QMD is
a durable FVS advantage everywhere (about +1 percent vs OSM +11).

## Equivalence testing (TOST, Schuirmann; Robinson and Froese 2004)

Region of equivalence: plus or minus 10 percent of the observed mean for level, plus or minus 25 percent
for increment. Equivalence declared when the 90 percent CI of the mean paired difference lies inside the
region. Pooled level equivalence pass counts (of 9 metrics): OSM 8, v12.9.x 6, v12.7.1 6, v12.7.0 3,
v12.5.0 3. On increment (PAI), no model is broadly equivalent within plus or minus 25 percent, reflecting
that net increment on these mature, slow stands is small and hard to hit; this is the honest signal that
the remaining work is on the increment, not the level.

## By forest type (the bias is composition driven)

Total volume level bias by forest type (percent hardwood basal area at t1; softwood under 25, mixedwood 25
to 75, hardwood over 75):

| forest type | n | v12.5.0 | v12.7.0 | v12.7.1 | v12.9.x | OSM |
|---|---|---|---|---|---|---|
| Softwood | 321 | +8 | +0 | -7 | -7 | -1 |
| Mixedwood | 186 | +16 | +11 | +5 | +3 | -4 |
| Hardwood | 178 | +42 | +36 | +30 | +25 | +15 |

Softwood is near zero for every model and equivalent. Hardwood is the shared frontier: every model
over-predicts (even OSM +15), and v12.9.x roughly halves the incumbent v12.5.0 hardwood bias (+42 to +25).
This is where a regional and composition-aware mortality refit is the substantive next step.

## Explicit Bakuzis relations (seeded 160-yr projections across an ESI gradient)

| relation | v12.5.0 | v12.7.0 | v12.7.1 | v12.9.x | OSM |
|---|---|---|---|---|---|
| Eichhorn (V ~ f height) | pass | pass | pass | pass | pass |
| Reineke slope (target -1.6) | flag | pass (-1.8) | pass (-1.59) | pass (-1.59) | flag |
| Site ordering (no overtaking) | pass | pass | pass | pass | pass |
| Yield-density / plateau | flag | pass (37) | pass (36) | pass (36) | flag |
| Sukachev (size vs density) | flag | pass | pass | pass | pass |

v12.5.0 never self-thins (basal area runs to 65 m2/ha with thousands of stems still alive), failing yield
density, Reineke, and Sukachev. v12.7.1 and v12.9.x pass all five, with a Reineke slope of -1.59 (target
-1.6) and a plateau at the realistic Acadian maximum. OSM does not plateau on the long horizon either
(Seven Islands matched stands climb 32 to 42 m2/ha over 60 years with no self-thinning; carried from the
finalized OSM benchmark, not re-run here). The FVS-ACD self-thinning versions are the only models that are
biologically realistic over a rotation, which is the case for their use in long-horizon carbon and
old-growth work.

## Verdict

On the operational inventory domain OSM and FVS-ACD v12.9.x are close, and the 2018 conclusion that OSM
clearly beat FVS-ACD does not replicate on independent in-domain data scored with a common NSVB volume
system. Choose by use: OSM or v12.7.0 for short-rotation inventory accuracy; v12.9.x for long-horizon
carbon, old growth, and climate work, where biological realism and a validated site driver matter. The
substantive next version is a regional and composition-aware mortality refit (to win both the growing and
mature tails) plus an increment-consistent ESI anchor recalibration.

## Provenance

Cardinal ~/magplot/verify/: scorecard_clean.R (single-merge scorecard + TOST + forest type), scorecard
_enhance.R (first pass, superseded by the clean merge), bakuzis_allmodels.R (per-model trajectories and
relations). Per-stand model results cb_v125_results.csv, cb_v1270_results.csv, cb_v1271cB_results.csv,
cb_v129x_pass2_results.csv (the operational v12.9.x anchor-recalibrated run), and osm_h2h_metrics.csv.
Outputs scorecard_clean_all.csv, bakuzis_relations.csv, bakuzis_traj_allmodels.csv. Figures in figures/
hennigar_*.png. Deck FVS-ACD_Hennigar_Aug2026.pptx; brief 20260702_hennigar_premeeting_brief.md and .docx.
