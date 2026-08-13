# FVS-ACD v12.10.1 full independent five-way benchmark

*3 July 2026. Full independent benchmark of the shipped operational version FVS-ACD v12.10.1 (the robust
additive-release management modifiers, gate on) against v12.5.0, v12.7.0, v12.9.x, and OSM v2.26.1 on the
identical held-out independent data, scored with the corrected single-keyed-merge methodology. Built for the
18 August Acadian Growth and Yield meeting. All computation on Cardinal (~/magplot/verify); aggregates only,
coordinates never left the node. Plaintext math, no em dashes.*

## Verdict up front

v12.10.1 is confirmed as the scored operational version and it reproduces. On the pooled operational domain
it sits between v12.9.x and OSM: mean absolute level bias 5.0 percent across the nine NSVB metrics (v12.9.x
4.4, OSM 3.2), mean modeling efficiency 0.71 (OSM 0.75), and seven of nine TOST level equivalences (v12.9.x
six, OSM eight). The point of v12.10.1 is not the pooled number, which is dominated by unmanaged stands where
v12.10.1 is byte identical to v12.9.x. The point is the managed cell. On the 146 managed stands v12.10.1
closes the gap to OSM and beats it: managed out of sample mean absolute bias 1.3 versus OSM 8.3 and v12.9.x
10.2 (leave one installation out), and planted stands are a clean win over OSM (planted out of sample 4.0
versus OSM 16.7). The clamp red flag from v12.10.0 is gone: the direct effect is a fitted additive release
whose fold coefficients move with the data, not a capped constant. The biological realism (Bakuzis pass on
all five relations, plateau held at every amplitude) carries over from v12.9.x unchanged. The honest limits
are the same two the red team forced: PCT parity with OSM is a within core result that weakens across the
New Brunswick to Quebec province block, and the Quebec edge stays out of domain.

## Version confirmed

The scored build is AcadianGY_12.10.1.r, version tag AcadianV12.10.1. Relative to v12.10.0 the planted and
PCT diameter growth multipliers no longer pin to the old 0.7 to 1.6 guard clamp; the direct effect is
re-expressed as a robust additive direct-effect release (planted +3.83 m2/ha basal area, PCT +2.41, ten
percent trimmed means over the class of per stand observed minus predicted-untreated increment, with
proportional releases in the other eight metrics). The equivalent net multiplier is about 3.0 planted and
2.3 PCT, above the old 1.6 ceiling, which is why the clamped version still under-predicted planted. The
modifier is gated by ops$use.mgmt.mod and applies only to planted and PCT stands; the gate off run is byte
identical to v12.9.x (maximum diameter difference 0.0e+00), and the 266 unmanaged stands are unchanged.

## Data and scoring

Independent in-domain evaluation set: MagPlot New Brunswick (n=355) and ESI-covered Quebec (n=350), total
n=705, plus recent Maine FIA post-2010 remeasurements for the growing-stand cross check. All volume, biomass,
and value on the shared FIA NSVB emulator (per species-group combined variable with Duan smearing; aggregate
bias about 0 percent against raw FIA NSVB, so the emulator does not advantage any model). Scoring uses the
corrected single-keyed-merge scorer (scorecard_v1210.R, extending scorecard_clean.R): one wide table keyed by
stand, deduplicated on both sides, with a per-model observed-on-predicted correlation as the alignment check.
The five-way scoring runs the identical metric code over every model, so v12.10.1 is scored exactly as the
other four. The earlier negative-modeling-efficiency artifact on OSM (an index-join misalignment) is dead;
all five models sit at observed-on-predicted correlation about 0.85 to 0.87 pooled.

## Pooled five-way scorecard (n=705, NSVB)

Level bias (percent), all nine metrics:

| metric | v12.5.0 | v12.7.0 | v12.9.x | v12.10.1 | OSM |
|---|---|---|---|---|---|
| basal area | +4.9 | -1.8 | -8.6 | -7.5 | -2.0 |
| stand density index | +7.1 | -1.0 | -8.1 | -6.8 | -4.1 |
| quadratic mean diameter | -4.7 | -0.1 | +1.2 | +2.0 | +11.0 |
| top height | +10.8 | +10.3 | +9.1 | +9.1 | +4.4 |
| total volume | +18.1 | +11.1 | +2.7 | +4.1 | +1.6 |
| merch volume | +17.2 | +10.1 | +1.7 | +3.1 | +1.0 |
| sawlog volume | +16.6 | +9.7 | +1.5 | +2.8 | +1.5 |
| aboveground biomass | +17.8 | +10.3 | +2.0 | +3.3 | +1.0 |
| stand value | +19.9 | +12.9 | +4.5 | +5.9 | +2.6 |

Modeling efficiency (NSE):

| metric | v12.5.0 | v12.7.0 | v12.9.x | v12.10.1 | OSM |
|---|---|---|---|---|---|
| basal area | 0.72 | 0.71 | 0.67 | 0.67 | 0.74 |
| stand density index | 0.69 | 0.67 | 0.62 | 0.62 | 0.71 |
| quadratic mean diameter | 0.73 | 0.78 | 0.77 | 0.76 | 0.70 |
| top height | 0.74 | 0.74 | 0.76 | 0.76 | 0.85 |
| total volume | 0.64 | 0.69 | 0.72 | 0.72 | 0.75 |
| merch volume | 0.66 | 0.70 | 0.73 | 0.73 | 0.76 |
| sawlog volume | 0.67 | 0.71 | 0.74 | 0.74 | 0.76 |
| aboveground biomass | 0.59 | 0.65 | 0.69 | 0.69 | 0.72 |
| stand value | 0.60 | 0.66 | 0.71 | 0.71 | 0.73 |

Summary rollup, pooled:

| model | mean abs level bias % | mean NSE | RMSE total volume | TOST level equiv (of 9) |
|---|---|---|---|---|
| v12.5.0 | 13.0 | 0.67 | 58.2 | 3 |
| v12.7.0 | 7.5 | 0.70 | 54.5 | 3 |
| v12.9.x | 4.4 | 0.71 | 51.2 | 6 |
| v12.10.1 | 5.0 | 0.71 | 51.2 | 7 |
| OSM v2.26.1 | 3.2 | 0.75 | 48.5 | 8 |

Reading. v12.10.1 tracks v12.9.x on every pooled metric because the modifier touches only managed stands and
the pooled set is mostly unmanaged; the small pooled shifts (basal area -8.6 to -7.5, total volume +2.7 to
+4.1) are the managed cells lifting toward observed. RMSE and NSE are unchanged from v12.9.x to three digits.
v12.10.1 gains one TOST level equivalence over v12.9.x (six to seven) from the same managed correction. OSM
keeps the best pooled bias and efficiency; the FVS-ACD advantage on the pooled domain is QMD (about +1 to +2
percent versus OSM +11), biological realism, transparency, and a climate-ready site driver, not pooled
precision.

## By jurisdiction

Total volume level bias (percent):

| model | New Brunswick (n=355) | Quebec (n=350) |
|---|---|---|
| v12.5.0 | +0.6 | +33.3 |
| v12.7.0 | -4.4 | +24.4 |
| v12.9.x | -6.9 | +11.0 |
| v12.10.1 | -5.5 | +12.4 |
| OSM v2.26.1 | -8.0 | +9.8 |

New Brunswick core: v12.10.1 total volume -5.5 percent is closer to zero than v12.9.x (-6.9) and than OSM
(-8.0), because the managed release lifts the managed NB stands. Quebec edge: v12.10.1 +12.4 is marginally
above v12.9.x +11.0 and OSM +9.8; the Quebec figure carries the out-of-domain top-height over-read and is
reported as an edge, consistent with Hennigar 2018 excluding Quebec.

## By forest type (composition drives the residual)

Total volume level bias (percent):

| forest type | n | v12.5.0 | v12.7.0 | v12.9.x | v12.10.1 | OSM |
|---|---|---|---|---|---|---|
| Softwood | 321 | +8.3 | +0.3 | -7.4 | -5.9 | -1.0 |
| Mixedwood | 186 | +16.2 | +10.7 | +2.6 | +4.1 | -3.9 |
| Hardwood | 178 | +42.4 | +35.5 | +25.3 | +26.2 | +14.6 |

Softwood is near zero for the modern versions. The managed release nudges softwood and mixedwood v12.10.1
totals toward observed relative to v12.9.x (softwood -7.4 to -5.9). Hardwood is the shared frontier for every
model, OSM included (+14.6), and is the target of the v13 composition-aware refit, not a management-modifier
problem.

## By management class (the headline)

In-sample level bias (percent), the cells the modifier targets:

| class | n | metric | v12.9.x | v12.10.1 | OSM |
|---|---|---|---|---|---|
| NONE | 266 | basal area | -8.2 | -8.2 | -2.0 |
| NONE | 266 | total volume | +1.0 | +1.0 | -1.6 |
| PLANTED | 51 | basal area | -23.6 | -3.2 | -20.9 |
| PLANTED | 51 | total volume | -16.9 | -4.0 | -19.6 |
| PCT | 95 | basal area | -13.9 | +0.3 | -5.4 |
| PCT | 95 | total volume | -5.7 | +0.1 | -0.1 |
| MANAGED | 146 | basal area | -17.6 | -1.0 | -11.2 |
| MANAGED | 146 | total volume | -9.9 | +0.7 | -7.4 |

NONE is byte identical between v12.9.x and v12.10.1 (the gate confirmation). Planted and PCT basal area and
volume move from meaningful under-prediction to near zero, and the pooled managed basal area goes from -17.6
to -1.0. The PCT basal-area residual the red team deferred is closed by the additive form (+0.3 versus OSM
-5.4, was -9.6 under the clamp).

Out of sample, the number that matters, mean absolute level bias across the nine metrics under leave one
installation out cross validation (fold unit = MagPlot installation):

| class | n | v12.9.x | v12.10.1 | OSM | gap to OSM closed |
|---|---|---|---|---|---|
| PLANTED | 51 | 15.8 | 4.0 | 16.7 | yes, v12.10.1 clearly ahead |
| PCT | 95 | 7.5 | 3.0 | 3.7 | yes, v12.10.1 ahead in core |
| MANAGED | 146 | 10.2 | 1.3 | 8.3 | yes, gap closed |

Under the harsher leave one province out block: managed 1.5, planted 5.6 (OSM 16.7), PCT 4.1 (OSM 3.7, still
marginally behind across the border). Managed split half (200 reps) 5.6, beating OSM in 76 percent of reps
and v12.9.x in 82 percent. The out of sample managed number reproduces the headline claim (managed about 1.4
versus OSM 8.3), and the additive fold coefficients are stable (planted basal-area release range 3.57 to
4.14, PCT 2.28 to 2.57 across folds), unlike the clamped multiplier that pinned at 1.6 in every fold.

## PAI and equivalence

Pooled periodic annual increment bias, basal area (m2/ha/yr): v12.5.0 +0.12 (over), v12.7.0 -0.06, v12.9.x
-0.22, v12.10.1 -0.19, OSM -0.05. No model is broadly increment equivalent within plus or minus 25 percent
of observed PAI; net increment on these mature slow stands is small and hard to hit, which is the honest
signal that the remaining work is on the increment, addressed by v13. TOST level equivalence (region plus or
minus 10 percent of the observed mean, Robinson and Froese 2004): v12.10.1 seven of nine, one better than
v12.9.x, behind OSM eight.

## Bakuzis relations (seeded 160-year projections across an ESI gradient)

| relation | v12.5.0 | v12.7.0 | v12.9.x | v12.10.1 | OSM |
|---|---|---|---|---|---|
| Eichhorn (V ~ f height) | pass | pass | pass | pass | pass |
| Reineke slope (target -1.6) | flag | pass (-1.8) | pass (-1.59) | pass (-1.59) | flag |
| Site ordering (no overtaking) | pass | pass | pass | pass | pass |
| Yield-density / plateau | flag | pass (37) | pass (36) | pass (36) | flag |
| Sukachev (size vs density) | flag | pass | pass | pass | pass |

v12.10.1 inherits the v12.9.x self-thinning machinery and passes all five relations. With the management
modifier on, a seeded 160-year projection of a planted softwood stand still plateaus at every amplitude
tested (standard deviation of basal area over the last 20 years about 0.21, flat), and the ceiling rises
smoothly with amplitude (36.3, 41.6, 43.6, 45.6, 47.3 m2/ha at amplitudes 1.0, 1.6, 2.0, 2.5, 3.0) because
basal area at the Reineke limit rises with tree size; the operational engine amplitude is set to 2.0. The
modifier accelerates the approach and lifts the ceiling to a productive planted conifer level without
breaking self-thinning. v12.5.0 still fails self-thinning outright; OSM does not plateau over the tested
horizon.

## Reproduction check

The v12.10.1 out of sample managed numbers reproduce this run from mgmt_gap_closure_robust.csv: MANAGED
leave one installation out mean absolute bias 1.33 versus OSM 8.33 and v12.9.x 10.18; PLANTED 3.95 versus OSM
16.69; PCT 3.04 versus OSM 3.73. The in-sample by-class scorecard reproduces to the decimal (planted basal
area -3.2, PCT +0.3, managed -1.0). The five-way pooled and by-cut scorecard was regenerated from Wfull.rds
with the identical single-keyed-merge scorer (scorecard_five_v1210.csv), all five models scored on the same
705 keyed stands.

## Honest limits

PCT parity with OSM is a within-Acadian-core result. Under the province block it holds at 4.1 versus OSM 3.7,
close but marginally behind, so the Quebec-edge-out-of-domain framing stays as the conservative call. The
Quebec pooled and top-height figures carry an out-of-domain edge. The management effect is carried in the
engine as a bounded sustained (planted) or decaying (PCT) diameter-growth amplitude; the exact per-tree
amplitude that reproduces the additive net release through the full engine is what the v13 hierarchical refit
with management as a predictor pins down. For August the near-term scorecard uses the robust additive release
directly and the engine amplitude is plateau verified.

## Provenance

Cardinal ~/magplot/verify: scorecard_v1210.R (five-way single-keyed-merge scorer including v12.10.1),
scorecard_clean.R (base scorer), mgmt_cv_robust.R and mgmt_finalfit.R (additive release and out of sample
battery), bakuzis_allmodels.R (Bakuzis relations), mgmt_plateau_sweep.R (plateau and gate-off identity).
Inputs Wfull.rds (705 keyed table with all five models across nine metrics), cb_v125/v1270/v129x_pass2 per
stand results, osm_h2h_metrics.csv, magp_qcnb_tree_init.csv, mgmt_scorecard_byclass_robust.csv,
mgmt_gap_closure_robust.csv. Model AcadianGY_12.10.1.r. Outputs scorecard_five_v1210.csv (copied to
repos/fvs-acd/results). Coordinates never left the node.
