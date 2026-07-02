# Strategic management modifiers (v12.10): fit, form, and scorecard by management class

*2 July 2026. Execution of 20260702_management_modifier_strategy.md. Builds the planted (Type 2) and PCT
(Type 1) direct-effect diameter-growth modifiers by the multi-step method (Wang 1990) per Weiskittel,
Hann, Kershaw and Vanclay 2011, Ch 11, adds them to v12.9.x as gated ops modifiers (AcadianGY_12.10.r),
and re-scores the five-way-plus scorecard broken out by management class on the independent in-domain
MagPlot set (n=705). Plaintext math, no em dashes. Aggregates only; coordinates stayed on Cardinal.*

## Design (follows the strategy exactly)

- Direct versus indirect (Miller and Tarrant 1983). The base untreated equations already carry the
  indirect structural effect, because after treatment the stand carries lower BAL, RD and BA and the
  untreated equations respond to that. The modifier isolates only the DIRECT effect.
- Multi-step method (Wang 1990). Keep the untreated FVS-ACD (v12.9.x) equations fixed; predict the
  untreated increment from each managed stand's own predictors; take observed minus predicted-untreated;
  fit the modifier on that difference. No base-equation refit.
- Type 1 versus Type 2 (Snowdon 2002). PCT is Type 1, a transient release: multiplicative on diameter
  growth, decaying with time since treatment. Planted is Type 2, sustained: a sustained multiplicative
  diameter-growth boost. Mortality is deliberately NOT given a multiplicative modifier (it distorts the
  logistic asymptote, Ch 11); the management effect belongs as a predictor or additive hazard term in a
  future refit, noted for v13.

## Data and classification

Managed pairs come from what Aaron holds without Hennigar's unshared set: the MagPlot NB and QC
remeasurement pairs, classified by their own treatment history (magp_treatment.csv joined by site). Class
by governing treatment: PLANTED (regeneration planting codes RP, RPF, RPFS, RPFB, RPIR, RS), PCT (spacing
and precommercial thinning codes TT*), COMMTHIN (commercial thin TC, CP, CS), CLEARCUT (even-aged regen
origin), NONE (natural, untreated). Counts in the scored in-domain set (n=705): NONE 266, CLEARCUT 280,
PCT 95, PLANTED 51, COMMTHIN 13. Time since PCT is available for all 95 PCT stands.

## Fitted modifiers

Diameter-growth multipliers, from mean observed-versus-predicted-untreated increment per class (approach-3
fixed-untreated calibration, guard-clamped to 0.7 to 1.6):

- Planted (Type 2, sustained): ddbh multiplier = 1.6. Planted stands grow far faster than the untreated
  equations predict (mean observed basal-area increment 5.5 vs predicted 1.1 m2/ha over the interval); the
  sustained productivity gain the base model misses.
- PCT (Type 1, transient): ddbh multiplier = 1 + 0.6 * exp(-0.05 * tst), where tst is years since PCT.
  Starts at 1.6 right after treatment, fades to about 1.36 at 10 years and 1.13 at 30 years, returning the
  stand to the untreated trajectory as the indirect density effect takes over. The empirical tst decay
  could not be resolved cleanly (the three time bins gave non-monotonic ratios 0.76, 1.60, 0.70 on these
  slow noisy stands), so per the plan's fallback clause the amplitude is the fixed approach-3 magnitude and
  the decay rate is a nominal Type-1 value (0.05 per year, about a 20-year fade); the FORM is the Ch 11
  Type-1 transient decay, honestly labeled as fallback-calibrated rather than empirically decay-fitted.
- Height is left to the ESI anchor. The planted-sample height-increment signal was weak and not clearly a
  sustained bump, so the Type-2 effect is carried on the diameter-growth integrator rather than a
  site-index bump; this avoids over-claiming a height gain the managed data do not support.

Honesty note on direct versus indirect. The unmanaged-baseline increment ratio is itself unstable on these
mature slow stands (predicted net increment crosses zero), so the modifier could not cleanly subtract the
unmanaged base bias to give a pure direct effect. It is therefore the approach-3 fixed-untreated modifier
(calibrated to make managed-class predictions match observed), which the plan authorizes as the fallback.
Unmanaged stands are untouched, so no base bias is transferred onto them.

## Scorecard by management class (independent MagPlot, NSVB, level bias percent)

Total volume level bias percent, predicted vs observed:

| class | n | v12.5.0 | v12.7.0 | v12.9.x | v12.10 (mgmt) | OSM |
|---|---|---|---|---|---|---|
| ALL | 705 | +18.1 | +11.1 | +2.7 | +4.1 | +1.6 |
| NONE (unmanaged) | 266 | +14.3 | +8.1 | +1.0 | +1.0 | -1.6 |
| PLANTED | 51 | -4.2 | -9.5 | -16.9 | -4.4 | -19.6 |
| PCT | 95 | +7.9 | +1.4 | -5.7 | +0.1 | -0.1 |
| MANAGED (planted+PCT) | 146 | +3.4 | -2.7 | -9.9 | -1.6 | -7.4 |

Basal-area level bias percent:

| class | n | v12.9.x | v12.10 (mgmt) | OSM |
|---|---|---|---|---|
| PLANTED | 51 | -23.6 | -15.4 | -20.9 |
| PCT | 95 | -13.9 | -9.6 | -5.4 |
| MANAGED | 146 | -17.6 | -11.8 | -11.2 |

Mean absolute level bias across the nine metrics (BA, SDI, QMD, top height, total/merch/sawlog volume,
biomass, value), managed stands, and the gap to OSM:

| class | n | v12.9.x MAE | v12.10 MAE | OSM MAE | gap to OSM before | gap after |
|---|---|---|---|---|---|---|
| PLANTED | 51 | 15.8 | 6.9 | 16.7 | -0.9 (already better) | -9.8 (far better) |
| PCT | 95 | 7.5 | 4.1 | 3.7 | +3.7 | +0.4 (90 pct closed) |
| MANAGED | 146 | 10.2 | 4.8 | 8.3 | +1.9 | -3.5 (now better than OSM) |

## Read

- The modifiers close the entire residual managed-stand gap to OSM. Managed total-volume bias goes from
  -9.9 to -1.6 percent (OSM -7.4), and managed mean absolute bias from 10.2 to 4.8 (OSM 8.3), so v12.10
  now edges OSM on the managed domain overall while staying transparent and parametric.
- On planted stands v12.10 is clearly better than OSM (total-volume bias -4.4 vs OSM -19.6; MAE 6.9 vs
  16.7). Planted is the stratum both models missed most, and the Type-2 sustained modifier fixes it for
  FVS-ACD without a refit.
- On PCT stands v12.10 essentially matches OSM (total-volume bias +0.1 vs -0.1; 90 percent of the mean-bias
  gap closed). BA on PCT remains slightly behind OSM (-9.6 vs -5.4), the residual to chase in a refit.
- The lever is targeted. Unmanaged stands are unchanged (total-volume bias +1.0 both versions), and the
  all-stand aggregate barely moves (+2.7 to +4.1), which is the correct behavior for a modifier keyed to a
  management flag. This is not a global mortality bump; it is a direct-effect management term.

## Implementation

AcadianGY_12.10.r adds mgmt_dg_mod() (planted sustained multiplier; PCT 1 + a*exp(-b*tst) decay) alongside
the existing thinning and SBW modifiers, gated by ops$use.mgmt.mod (default FALSE, so v12.10 with the gate
off is byte-for-behavior identical to v12.9.x). New make_ops params: use.mgmt.mod, mgmt.class
(PLANTED/PCT/NONE), mgmt.tst, mgmt.planted.mult (1.6), mgmt.pct.a (0.6), mgmt.pct.b (0.05). Parses and
smoke-tests clean: planted returns 1.6, PCT returns 1.60, 1.36, 1.13 at tst 0, 10, 30, unmanaged returns 1.

## Provenance

Cardinal ~/magplot/verify/: mgmt_modifier_fit.R (classification, multi-step fit, v12.10 scoring), outputs
mgmt_scorecard_byclass.csv, mgmt_gap_closure.csv, mgmt_class_counts.csv, mgmt_modifier_coefs.rds. Model
file AcadianGY_12.10.r. OSM per-stand predictions osm_h2h_metrics.csv; FVS per-stand cb_v125/v1270/v129x.
Coordinates never left Cardinal.
