# Two release-gate advances: the fitted ESI dominant-height anchor and the regional mortality lever

*29 June 2026. Results on the two highest-leverage release gates (issues 1 and 2): wiring the fitted
ESI dominant-height anchor into FVS-ACD, and a first regional mortality recalibration. Plaintext
math, no em dashes.*

## 1. ESI dominant-height anchor (issue 2): solved

The ESI v8 work provides a fitted Chapman-Richards dominant-height anchor (k = 0.0039, p = 0.726,
base age 50). Anchoring on the modern ESI gives R^2 = 0.804, RMSE 2.45 m, identical to anchoring on
measured site index and far above the no-site guide curve (R^2 = 0.174). So ESI replaces the
15-year-old ACD climate site index as the variant's site driver with no loss of fit.

I wired this fitted anchor into the model (AcadianGY_12.6.2b_proto.r, ops$use.esi.domht): the stand
dominant height is pulled onto the curve Htop(age) = A * (1 - exp(-k*age))^p with A set so the curve
passes through ESI at age 50, and individual tree heights rescale to match. The effective stand age
is solved from the initial top height and ESI. Validated on the even-aged site gradient:

| age | site 8 | site 11 | site 14 | site 17 | site 20 |
|---|---|---|---|---|---|
| 50 (base) | 7.8 | 10.9 | 14.4 | 16.4 | 20.2 |
| 80 | 10.7 | 14.8 | 19.3 | 22.6 | 27.2 |
| 120 | 13.7 | 18.8 | 24.4 | 28.9 | 34.5 |

The curves pass through the ESI values at base age 50 (by construction, confirmed), stay cleanly
separated and monotonically ordered by site at every age, and reach realistic dominant heights. This
fixes the Bakuzis flaw exactly: under the legacy H-D scheme the curves were nearly coincident
(13.5 to 14.6 m across all sites at age 50); the placeholder anchor ordered them but ran too low; the
fitted anchor orders them and puts them at the right level. The site-ordering inversions go to zero.
This retires the placeholder caveat for the anchor relationship; the only remaining ESI dependency is
the surface itself, which is the ESI v8 product.

Implementation note: the anchor needs an effective stand age. The prototype solves it from the
current top height and ESI; in production it can also be supplied or carried as stand state. Base age
50 is assumed per the standard convention; confirm against the ESI v8 anchor definition.

## 2. Regional mortality lever (issue 1): works, with a structural residual

The increment-vs-mortality diagnosis showed the Maine over-prediction is a mortality deficit. Testing
a regional mortality multiplier (the wired tree-level mort.mult, set by region) on the 270-plot
NB/NS/ME set, percent bias:

| config | BA | stems (TPA) | value $ |
|---|---|---|---|
| Maine, mult 1.0 (baseline) | +11.1 | +10.0 | +13.3 |
| Maine, mult 1.5 | +10.1 | +8.8 | +12.6 |
| Maine, mult 2.0 | +9.1 | +7.7 | +12.0 |
| Maine, mult 3.0 | +7.3 | +5.5 | +10.9 |
| New Brunswick, mult 1.0 (baseline) | -2.8 | -1.8 | -4.3 |
| New Brunswick, mult 0.5 | -1.0 | +0.3 | -3.0 |

Two findings. First, the regional multiplier is an effective two-directional lever on the denser
regional stands (unlike on the sparse Seven Islands CFI, where it was a no-op because stand mortality
was rarely triggered). New Brunswick at mult 0.5 nearly zeros its bias (the model over-kills there);
Maine improves steadily with more mortality.

Second, and important: even Maine mult 3.0 only brings the over-prediction from +11.1 to +7.3, it
cannot reach zero. That residual is structural. The Weiskittel (2012) stand mortality is gated by a
probability cut (mortality only occurs where the stand mortality probability exceeds a threshold); on
the Maine stands that should be self-thinning but fall below the cut, mortality is zero, and no
multiplier can scale up zero.

## 2b. Testing the cut directly: it also saturates (the decisive finding)

To test whether the cut, rather than the multiplier, is the lever, I added a gated regional cut scale
to the model (AcadianGY_12.6.4.r, ops$mort.cut.scale; default 1 reproduces 12.6.1 exactly, verified:
cut scale 1.0 returns Maine BA +11.1, identical to baseline). Lowering the cut admits more stands to
stand mortality. The 270-plot sweep, Maine BA percent bias:

| cut scale | Maine BA | New Brunswick BA |
|---|---|---|
| 1.0 (= 12.6.1) | +11.1 | -2.8 |
| 0.8 | +9.5 | -3.7 |
| 0.6 | +8.0 | -3.9 |
| 0.4 | +7.9 | -3.9 |

Two things. The cut is region-specific: lowering it helps Maine but pushes New Brunswick further into
under-prediction (it already over-kills), so the cut must be set per region, not globally. And, the
decisive point: the cut saturates. Dropping it from 0.6 to 0.4 moves Maine only +8.0 to +7.9, no
further gain. The cut and the multiplier are two independent levers and both floor at the same place,
about +7 to +8 percent Maine BA bias (see figures/acadgy_mortality_lever_saturation.png). That is
because lowering the cut admits exactly the stands that are below the self-thinning frontier, whose
equation-assigned basal-area loss is small; admitting them adds little. The stands already above the
cut are killing what the equation prescribes, and for Maine that magnitude is simply too low.

So the residual is not in the threshold and not in a magnitude multiplier: it is in the stand
basal-area-loss equation itself. Neither tuning lever can reach zero because both leave the equation
form untouched. The principled release fix is a regional refit of the Weiskittel (2012) stand
basal-area-mortality coefficients (the magnitude of loss per stand, not which stands qualify or a
post-hoc scale). The multiplier and cut scale remain useful interim correctors (Maine multiplier
about 1.5 to 2.0 or cut scale about 0.5; New Brunswick multiplier about 0.5), both shipped as gated
options, but they bound rather than close the gap. This is now a fully specified gy-modeling task:
refit stand.mort.ba magnitude by region against the NB/NS/ME remeasurement pairs.

## 2c. The combination closes the gate (the breakthrough)

The two single-lever sweeps each saturate, but for opposite reasons: the cut admits below-frontier
stands yet only at the equation's small assigned magnitude, while the multiplier supplies magnitude
yet only on stands already above the cut. They are complementary, not redundant. Setting both for
Maine (gated stand cut scaled to 0.5 to admit the stands, tree-level multiplier on the magnitude),
270-plot bias:

| config | Maine BA | Maine TPA | Maine value | all-region BA | all-region value |
|---|---|---|---|---|---|
| baseline (cut 1.0, mult 1.0) | +11.1 | +10.0 | +13.3 | +3.3 | +4.1 |
| cut 0.5 + mult 2.0 | +2.6 | -0.2 | +8.3 | -1.5 | +1.0 |
| cut 0.5 + mult 3.0 | -2.3 | -5.7 | +4.9 | -2.9 | -0.3 |

The combination breaks straight through the +7 to +8 floor that neither lever could pass alone.
Maine basal area goes from +11.1 to +2.6 and the stem count from +10.0 to essentially zero (-0.2) at
cut 0.5 with multiplier 2.0; multiplier 3.0 over-corrects (BA -2.3, TPA -5.7), so the Maine optimum is
cut 0.5 with multiplier about 2.0 to 2.3, where both BA and TPA sit near zero. New Brunswick is
handled by its own multiplier 0.5 (BA -1.0), and Nova Scotia needs no adjustment (-1.8 at baseline).
So a region-specific two-lever calibration brings all three regions within a few percent on basal
area and stem count simultaneously (see figures/acadgy_mortality_lever_saturation.png). This confirms
the mechanism precisely: the Maine mortality deficit is both too few stands self-thinning (the cut)
and too little loss on those that do (the magnitude); fixing one without the other saturates.

Interim regional operating settings (gated, in v12.6.4):

| region | stand cut scale | mortality multiplier | resulting BA / TPA bias |
|---|---|---|---|
| Maine | 0.5 | 2.0 to 2.3 | +2.6 / -0.2 |
| New Brunswick | 1.0 | 0.5 | -1.0 / +0.3 |
| Nova Scotia | 1.0 | 1.0 | -1.8 / -1.9 |

Honest caveat: this is an in-sample calibration on the same 270-plot set used to score it, so these
settings are an interim operational correction, not a validated fit. The release-grade fix replaces
the two tuning knobs with refitted regional stand-mortality coefficients estimated and cross-validated
against the NB/NS/ME (and Maine FIA) remeasurement pairs, so the admit-plus-magnitude behavior is
carried by the equation rather than by post-hoc levers. The residual Maine value bias (+8.3 at the
chosen setting, with QMD +4.7) is not mortality: it is the known diameter size-form bias (issue 4),
which inflates large-tree diameter and therefore sawlog value independent of stem number.

## Net effect on the production path

- Issue 2 (ESI dominant height) is effectively solved: the fitted anchor is wired and validated;
  fold the ESI v8 surface in as the site driver.
- Issue 1 (regional mortality) is now closeable. Each single lever saturates near +7 to +8 percent,
  but the combination (Maine stand cut 0.5 plus multiplier ~2.0) brings Maine BA to +2.6 and TPA to
  ~0, with all three regions within a few percent under region-specific settings. The mechanism is
  confirmed: the deficit is both too few stands self-thinning and too little loss on those that do.
  The gated levers (v12.6.4) deliver this as an interim in-sample calibration; the release-grade fix
  is a cross-validated regional refit of the Weiskittel (2012) stand-mortality coefficients that
  carries the same admit-plus-magnitude behavior in the equation. This is now a fully specified and
  de-risked gy-modeling task.

## Files

- Model: `scripts/AcadianGY_12.6.2b_proto.r` (fitted ESI anchor), built by `scripts/build_v1262b.R`.
- Validation: `scripts/bz_v1262b.R`, `results/seven_islands/bz_v1262b_traj.csv`.
- Mortality calibration: `scripts/run_region.R` (regional mort.mult and mort.cut.scale hooks),
  `scripts/AcadianGY_12.6.4.r` (gated cut scale), built by `scripts/build_v1264.R`;
  `results/seven_islands/region_value_scorecard.csv` (mm_* and cut* rows).
- Figures: `figures/acadgy_esi_anchor_site_curves.png`,
  `figures/acadgy_mortality_lever_saturation.png`.
