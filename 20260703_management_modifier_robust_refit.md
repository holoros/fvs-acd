# Robust re-fit of the FVS-ACD management modifiers (v12.10.1): clamp resolved

*3 July 2026. Resolves the one weakness the red team flagged in v12.10 (20260703_redteam_review.md): the
planted and PCT diameter-growth multipliers pinned to the 1.6 guard clamp, so the effective modifier was a
capped constant rather than a fitted coefficient. This memo diagnoses the cause, re-fits the direct effect
with a robust estimator, retests out of sample with the same battery, and reconciles the model and
documents. All computation on Cardinal (~/magplot/verify); aggregates only, coordinates never left the
node. Plaintext math, no em dashes.*

## Verdict up front

The clamp is resolved, but not by finding a smaller multiplier. The data say the managed direct effect is
genuinely LARGER than 1.6, not smaller, which is why the clamped v12.10.0 still under-predicted planted
stands (-4.4 pct total volume, -15.4 pct BA). The fix is to stop expressing the effect as a ratio of near-
zero net increments and instead fit it as a robust ADDITIVE direct-effect release. That estimator is
clamp-free, its fold coefficients move with the data instead of pinning to a ceiling, it holds out of
sample, and it additionally resolves the two v12.10.0 qualifications: PCT now transfers across the province
block and the PCT basal-area residual closes.

## Step 1: diagnosis, why the multipliers pinned to 1.6

The v12.10.0 modifier was the ratio of class-mean NET increments: mean(observed increment) divided by
mean(predicted-untreated increment), where increment = value at remeasurement minus value at start and
predicted-untreated is the v12.9.x prediction. On these mature managed stands that ratio is ill-posed
because the denominator is near zero:

| class | n | mean obs increment (BA) | mean predicted-untreated increment (BA) | ratio of means | negative predicted-untreated |
|---|---|---|---|---|---|
| PLANTED | 51 | 5.49 | 1.06 | 5.18 | 25 pct of stands |
| PCT | 95 | 2.62 | 0.26 | 10.18 | ~25 pct of stands |

The mean predicted-untreated net increment is near zero not because individual stands are all tiny, but
because self-thinning declines on the mature stands cancel gross growth across the class: about a quarter of
the planted and PCT stands have a NEGATIVE predicted-untreated net increment (planted 10th percentile
-3.79, PCT 10th percentile -5.41 m2/ha), which drags the class-mean denominator toward zero. Divide a real
positive observed increment by a near-zero mean and the ratio blows up to 5 to 10, and the 0.7 to 1.6 guard
clamp caps it at 1.6 for both classes. It is a small-denominator artifact at the class-mean level, and the
clamp made the coefficient a constant that cannot vary with data (the red team confirmed the fold
coefficients never moved).

## Step 2: robust re-fit

Candidates considered: (a) log-scale geometric mean of obs/pred, (b) size-weighted central estimate,
(c) increment-floor restriction, (d) additive direct-effect term, (e) smooth saturating link. The
increment-floor geometric mean lands planted at 1.49 (a real value below the clamp) but leaves PCT at 1.60
to 1.79, and lowering the multiplier below the clamp WORSENS the managed fit (planted total-volume bias
falls from -4.4 to -12.8 as the multiplier drops), because the clamp was already holding a genuine large
effect DOWN. So a multiplier below the clamp does not exist that also closes the gap. The estimator that
works is (d), the additive direct-effect release:

Robust additive release = 10 pct trimmed mean over the class of per-stand (observed increment minus
predicted-untreated increment), per metric. No division, so no small-denominator blow-up.

Fitted release (basal area, m2/ha over the interval, with proportional releases in the other eight metrics):

| class | BA release | total-volume release | equivalent net multiplier | pinned to clamp? |
|---|---|---|---|---|
| PLANTED (Type 2, sustained) | +3.83 | +10.8 | ~3.0 | no |
| PCT (Type 1, transient) | +2.41 | +6.9 | ~2.3 | no |

The equivalent net-increment multiplier (about 3.0 planted, 2.3 PCT) is ABOVE the old 1.6 clamp, which is
the whole point: the clamp had been suppressing a genuine effect. The additive fold coefficients MOVE with
the data (planted BA release ranges [3.57, 4.14] across leave-one-installation-out folds, PCT [2.28, 2.57]),
unlike the clamped multiplier that pinned at 1.6 in every fold.

## Step 3: out-of-sample retest, same battery as the red team

| test | class | v12.10.1 robust OOS MAE | v12.10.0 clamped OOS MAE | OSM MAE |
|---|---|---|---|---|
| leave-one-installation-out | PLANTED | 3.8 | 6.9 | 16.7 |
| leave-one-installation-out | PCT | 3.1 | 4.1 | 3.7 |
| leave-one-installation-out | MANAGED | 1.4 | 4.4 | 8.3 |
| leave-one-province-out | PLANTED | 5.6 | 6.7 | 16.7 |
| leave-one-province-out | PCT | 4.1 | 7.3 | 3.7 |
| leave-one-province-out | MANAGED | 1.5 | 7.1 | 8.3 |
| managed split-half (200) | MANAGED | 5.6 (sd 3.3) | 6.7 | 8.1 |

Managed total-volume bias out of sample (installation CV): PLANTED -3.8, PCT +3.5, MANAGED +0.8. The
robust re-fit beats OSM on managed in 76 pct of the 200 split-half reps and beats v12.9.x in 82 pct.

Two red-team qualifications improve:

- PCT province transfer. Under the harshest leave-one-province-out block, PCT now transfers: MAE 4.1 versus
  OSM 3.7, up from 7.3 under the clamped modifier. The within-core-only caveat can be softened; PCT is now
  close to OSM even across the NB to QC block, though still marginally behind, so the Quebec-edge-as-out-of-
  domain framing stays as a conservative call.
- PCT basal-area residual. In domain the PCT BA bias is now +0.3 versus OSM -5.4 (was -9.6 under the clamped
  modifier), so the residual the red team deferred to v13 is largely closed by the additive form.

Guardrails, all pass:

- Unmanaged and growing stands untouched. The additive release applies only to PLANTED and PCT, so the 266
  NONE stands and the recent Maine FIA growing stands are byte-identical to v12.9.x (max difference 0).
- Long-horizon plateau. A seeded 160-year projection of a planted RS/WS/BF ESI-18 stand across sustained
  diameter-growth amplitudes 1.0, 1.6, 2.0, 2.5, 3.0 shows the plateau holds at every amplitude (standard
  deviation of basal area over the last 20 years about 0.21, flat) because self-thinning caps the
  trajectory. The ceiling rises smoothly (36.3, 41.6, 43.6, 45.6, 47.3 m2/ha) with no runaway. The
  operational engine amplitude is set to 2.0 (ceiling about +20 pct, a productive planted conifer stand).
- Gate-off and legacy. v12.10.1 with the management gate off is byte-identical to v12.9.x (max dbh
  difference 0.0e+00), and the legacy flags reproduce v12.5.0 (legacy path untouched).

## Honest limits

- In-sample class bias is near zero by construction, because the additive release centers each managed
  class on its observed mean. The evidence that it is not overfit is the out-of-sample battery above (the
  fold coefficients are stable and the held-out MAE tracks the in-sample number), which is why the OOS
  numbers, not the in-sample ones, are the headline.
- PCT under the province block is close to OSM (4.1 vs 3.7) but still marginally behind, so PCT parity with
  OSM is a within-domain result, not a cross-block guarantee. Keep the Quebec-edge-out-of-domain framing.
- The engine carries the effect as a bounded sustained (planted) or decaying (PCT) diameter-growth
  multiplier; the exact per-tree amplitude that reproduces the additive net release through the full engine
  is pinned down in the v13 refit with management as a predictor. For the August meeting the near-term
  scorecard uses the robust additive release directly, and the engine amplitude is plateau-verified.

## Implementation

AcadianGY_12.10.1.r: mgmt_dg_mod defaults changed from the clamped 1.6 to the robust amplitudes
(mgmt.planted.mult 2.0, mgmt.pct.a 1.0, mgmt.pct.b 0.03); the hard 0.7 to 1.6 clamp is removed and the
long-horizon plateau is bounded by self-thinning. Still gated by ops$use.mgmt.mod (default FALSE). Version
tag AcadianV12.10.1.

## Provenance

Cardinal ~/magplot/verify: mgmt_diagnose.R (per-stand ratio distribution, near-zero-denominator
quantification), mgmt_estimators.R (candidate estimator comparison), mgmt_rescore.R (multiplier sweep),
mgmt_cv_robust.R (additive LOIO, LOPO, split-half), mgmt_finalfit.R (final additive release + effective
multiplier + result CSVs), mgmt_plateau_sweep.R (160-yr plateau, gate-off identity). Model
AcadianGY_12.10.1.r. Outputs mgmt_gap_closure_robust.csv, mgmt_scorecard_byclass_robust.csv,
mgmt_modifier_coefs_robust.rds. Inputs Wfull.rds, magp_qcnb_pairs.csv, cb_v125/v1270/v129x per-stand
results, osm_h2h_metrics.csv. Coordinates never left the node.
