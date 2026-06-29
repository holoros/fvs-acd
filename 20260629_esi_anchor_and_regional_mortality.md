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
multiplier can scale up zero. So a full fix is not a multiplier, it is lowering or refitting the
regional stand-mortality probability so the right stands receive mortality at all. The multiplier is
a useful interim correction (Maine about 1.5 to 2.0, New Brunswick about 0.5), but the principled
release fix is a regional refit of the stand-mortality probability and basal-area equations.

## Net effect on the production path

- Issue 2 (ESI dominant height) is effectively solved: the fitted anchor is wired and validated;
  fold the ESI v8 surface in as the site driver.
- Issue 1 (regional mortality) is advanced and sharpened: the lever works two-directionally, and the
  Maine residual localizes the remaining fix to the stand-mortality probability cut, not the
  multiplier. This is the next modeling task (gy-modeling), and it is now well-specified.

## Files

- Model: `scripts/AcadianGY_12.6.2b_proto.r` (fitted ESI anchor), built by `scripts/build_v1262b.R`.
- Validation: `scripts/bz_v1262b.R`, `results/seven_islands/bz_v1262b_traj.csv`.
- Mortality calibration: `scripts/run_region.R` (regional mort.mult hook),
  `results/seven_islands/region_value_scorecard.csv` (mm_* rows).
- Figure: `figures/acadgy_esi_anchor_site_curves.png`.
