# Recommended operational configuration for FVS-ACD (AcadianGY 12.5.0)

*28 June 2026. The best-supported operating configuration of the production AcadianGY 12.5.0 for
Seven Islands and similar Acadian stands, derived from the full site x MORTCAL x ingrowth matrix
and a MORTCAL lambda tuning sweep on the Seven Islands CFI. For Ben Rice. Plaintext math, no em
dashes.*

## The recommendation in one line

Run 12.5.0 with the modern ESI as the site input, the MORTCAL size-dependent mortality correction
ON, and the default ingrowth setting. Tune the MORTCAL strength (lambda) to balance bias across
projection horizons rather than leaving it at full strength.

## Evidence: the production site x MORTCAL matrix

12.5.0 production on 65 routine Seven Islands CFI pairs, basal-area bias:

| site input | MORTCAL off (ALL) | MORTCAL on (ALL) |
|---|---|---|
| CSI 12 (flat) | +11.3% | -1.1% |
| CSI 15 (ESI level) | +11.8% | -0.6% |
| CSI 21 (2030 climate) | +12.7% | +0.2% |

By horizon, the MORTCAL-on column at the ESI level: -17.0% (5 to 7 yr), +5.5% (8 to 11 yr),
+1.0% (12 to 15 yr). Two things are clear. First, MORTCAL is the lever: it converts a +11 to +13%
over-prediction into roughly zero overall at every site level, and it removes the long-horizon
over-prediction (the 8 to 15 yr horizons drop from +16 to +19% to +1 to +6%). Second, the site
input is a weak lever (about 1 pp across the full 12 to 21 m range), so the ESI swap is adopted
for site fidelity and spatial transferability, not to move the Seven Islands bias.

## Evidence: ingrowth is not the lever for merchantable basal area

Sweeping the ingrowth multiplier (1.0, 0.5, 0.0) left the BA bias unchanged (all configs at
+11.3% off, -1.1% on). The reason is structural: new recruits enter below the 11.43 cm (4.5 in)
merchantable diameter and do not reach it within a 15 year projection, so they do not move the
merchantable-BA metric. Ingrowth still matters for stems-per-acre and small-tree density and for
projections beyond 15 years, but it is not the knob for the basal-area over-prediction seen here.
Keep ingrowth at the default for the recommended configuration.

## Tuning: MORTCAL strength (lambda)

Unlike the tree-level `mort.mult` and `ingrowth.mult` knobs (both no-ops in this driver), the
MORTCAL lambda is wired and does move the result. The sweep at the ESI site level, BA bias by
horizon:

| lambda | 5 to 7 yr | 8 to 11 yr | 12 to 15 yr | all | TPA bias (all) | QMD bias (all) |
|---|---|---|---|---|---|---|
| 0.50 | -14.1% | +11.7% | +8.6% | +5.4% | -14.9% | +13.7% |
| 0.70 | -15.3% | +9.1% | +5.7% | +3.0% | -16.3% | +13.4% |
| 0.85 | -16.2% | +7.3% | +3.3% | +1.2% | -17.4% | +13.2% |
| 1.00 | -17.0% | +5.5% | +1.0% | -0.6% | -18.4% | +13.0% |

Lower lambda softens the mortality correction, which raises the long-horizon BA back up and lifts
the overall bias from -0.6% toward +5%. The horizon-balance score (RMS of the three horizon BA
biases) is nearly flat across lambda (10.3 at 1.0, 10.4 at 0.85, 10.8 at 0.7, 11.7 at 0.5), so
lambda trades long-horizon accuracy against the short horizon without ever balancing all three.

The reason is the most important finding of the sweep: the 5 to 7 yr horizon is under-predicted
even with MORTCAL off (-11.1%), so the short-horizon shortfall is a pre-existing early-growth
under-prediction, not a MORTCAL artifact. Lambda cannot fix it because it is not a mortality
problem. Two structural signals sit underneath the balanced BA: stems per acre are under-predicted
by about 18% and mean diameter is over-predicted by about 13%, that is, the model carries too few,
too-large trees, and stronger MORTCAL widens the stem gap. That points the next calibration at the
recruitment and small-tree side (ingrowth and early diameter growth), not at mortality.

## The recommended configuration

Run AcadianGY 12.5.0 with:

- Site input: the modern ESI, per plot, via `make_stand(stand.id, csi = ESI_at_plot, elev,
  region)`. Adopted for site fidelity (ESI tracks measured site index at R^2 0.91 vs 0.52) and
  spatial transferability, not to move the Seven Islands bias.
- Mortality: MORTCAL ON. `ops$use.mortcal = TRUE`, `ops$mortcal.interval = 5`,
  `ops$mortcal.lambda` between 0.85 and 1.0. Lambda 1.0 gives the lowest overall BA bias (-0.6%)
  and the best long-horizon accuracy; lambda 0.85 gives up a little BA accuracy (+1.2% overall)
  for slightly less stem loss. This is the single demonstrated lever for the basal-area
  over-prediction.
- Ingrowth: default (`ops$use.ingrowth = TRUE`). The ingrowth multiplier did not move
  merchantable BA over these horizons.

Important balance note: this configuration optimizes basal area. Underneath the balanced BA, the
model under-predicts stems per acre by about 18% and over-predicts mean diameter by about 13%
(too few, too-large trees), and MORTCAL widens the stem gap. So the recommended configuration is
the best available for basal-area and volume projection, but the stem-count and diameter-distribution
side needs a separate recruitment and early-growth calibration. Do not read the near-zero BA bias
as a fully balanced stand structure.

The exposed ingrowth knobs cannot close the stem gap. An ingrowth-lever sweep at the ESI level
with MORTCAL on tested the ingrowth threshold (0.95 stochastic, 0.5, and 0 expected-value) and a
lower entry DBH (3 cm), and none moved the result: TPA bias stayed at -18.4 to -18.9% and BA at
about -1% across all of them. Combined with the earlier no-ops (tree-level mort.mult and the
ingrowth multiplier), this means none of the ops-level recruitment or mortality knobs, other than
MORTCAL, change the realized projection. And TPA is already under-predicted by about 11% with
MORTCAL off, so the stem shortfall is pre-existing, not a MORTCAL artifact. Closing it therefore
requires a change to the recruitment equation or the early diameter-growth model itself, not a
configuration setting. For the operational recommendation this means: adopt ESI plus MORTCAL for
basal area and volume now, and treat the stem-count and diameter-distribution fix as a model
development task, not a tuning task.

Validated Seven Islands CFI basal-area bias for this configuration (ESI level, MORTCAL on,
full-strength lambda), by horizon:

| horizon | default (MORTCAL off) | recommended (MORTCAL on) |
|---|---|---|
| 5 to 7 yr | -11.1% | -17.0% |
| 8 to 11 yr | +18.3% | +5.5% |
| 12 to 15 yr | +17.0% | +1.0% |
| all | +11.8% | -0.6% |

The recommended configuration cuts the overall over-prediction from about +12% to roughly zero and
removes the long-horizon over-prediction (the 8 to 15 yr horizons drop from +17 to +18% to +1 to
+6%). The one open item is the 5 to 7 yr horizon, where full-strength MORTCAL over-corrects; the
lambda sweep targets exactly that balance.

## How to set it

- 12.5.0 driver: `make_stand(stand.id, csi = ESI_at_plot, elev, region)` for the site input;
  `ops$use.mortcal = TRUE`, `ops$mortcal.interval = 5`, and `ops$mortcal.lambda` at the balancing
  value from the sweep (start at full strength 1.0; lower it only if the sweep shows it rebalances
  the short horizon); ingrowth at default (`ops$use.ingrowth = TRUE`).
- 12.3.x: the ESI patch (`AcadianGY_12.3.10.r`) for the site input, `ops$MORTCAL = TRUE`,
  `ops$MORTCAL_INTERVAL = 5`; the lambda equivalent is the size or interval of the correction.

## Caveats

- The Seven Islands coordinates are 10 km township centroids, so the ESI vs legacy contrast is
  conservative; the recommended config uses ESI for fidelity regardless.
- The lambda tuning is fit to Seven Islands CFI; confirm on a second Acadian dataset (for example
  the broader FIA verification set) before locking the value range-wide.
- This balances basal area by horizon. A full calibration would also check stems-per-acre and
  volume; the lambda sweep table reports TPA and QMD bias alongside BA for that reason.

## Files

- `results/seven_islands/silc_cfi_v125_full.csv` (site x MORTCAL x ingrowth matrix)
- `results/seven_islands/silc_cfi_lambda_sweep.csv` (MORTCAL lambda tuning)
- `figures/acadgy_recommended_config.png` (config comparison)
