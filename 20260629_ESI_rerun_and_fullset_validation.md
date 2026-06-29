# Validated-ESI rerun and full-set regional validation: results and two corrections

*29 June 2026. Rerun of the regional validation with the validated modern ESI surface
(`Final_SI_Output.tif`) wired in as the site driver, plus a full-set (every plot) run that corrects
two numbers the earlier subsampled runs had wrong. Plaintext math, no em dashes.*

## What was done

Per the decision to use the validated ESI column as the site driver, ESI was extracted from
`Final_SI_Output.tif` (WGS84, single band) at the regional plot coordinates from `DBHout.csv`
(coordinates stayed on Cardinal throughout, via the gdalz GDAL 3.12 environment) and merged into
`region_manifest_esi.csv`, with the legacy climate site index retained as `csi_legacy`. The model was
then rerun under the production configuration (12.6.4 with sdimort, expected-value ingrowth, no
mortcal) three ways: ESI vs legacy on identical plots (the controlled contrast), and on the full
682-plot set rather than a 90-per-region subsample.

## Correction 1: ESI and legacy give the same regional volume and value

On the full 682-plot set, the validated ESI and the legacy climate site index produce essentially
identical regional bias:

| config | n | BA % | TPA % | QMD % | sawlog % | pulp % | value % |
|---|---|---|---|---|---|---|---|
| ESI (esi_full) | 682 | +1.4 | +1.6 | +0.8 | +1.7 | +1.4 | +1.5 |
| legacy (leg_full) | 682 | +1.4 | +1.7 | +0.8 | +1.9 | +1.4 | +1.6 |

The two are within 0.3 points everywhere. A controlled 270-plot contrast on identical plots gave the
same answer (Maine BA +4.9 under both). So swapping the 15-year-old climate site index for the
validated modern ESI does not change the regional volume or value calibration. This is consistent with
the earlier Maine FIA finding that site is a weak basal-area lever in this model. The value of the ESI
is not in regional volume and value bias; it is in dominant height (the fitted anchor gives R^2 0.804
versus 0.174 for the no-site guide curve) and in biological realism (it fixes the Bakuzis site
ordering). The earlier impression that ESI sharply reduced Maine bias was an artifact of comparing two
different random plot subsamples, not the site index; the controlled test removes that confound.

## Correction 2: the full-set bias is well-calibrated; the +11 percent Maine figure was a subsample

The full-set production bias is small in every region:

| region | n | BA % | TPA % | QMD % | value % |
|---|---|---|---|---|---|
| all | 682 | +1.4 | +1.6 | +0.8 | +1.5 |
| Maine | 201 | +4.9 | +2.6 | +3.0 | +7.6 |
| New Brunswick | 247 | -1.7 | -0.8 | 0.0 | -3.3 |
| Nova Scotia | 234 | +3.0 | +4.6 | -0.4 | +2.3 |

The all-region production bias is +1.4 percent basal area and +1.5 percent value: a well-calibrated
model. Maine is the largest regional residual at +4.9 percent BA and +7.6 percent value. This is
materially smaller than the +11.1 percent Maine BA that the earlier 90-per-region subsample showed and
that drove the entire mortality-lever investigation. The +11.1 was an unrepresentative high-bias draw;
the honest, stable figure on all 201 Maine intervals is +4.9 percent. Regional bias estimated from a
90-per-region draw carries enough sampling variability (+4.9 to +11.1 across draws) that single-draw
numbers should not be over-read; the full-set numbers above are the ones to quote.

## What this does to the mortality story

The mortality mechanism finding still stands: the stand-mortality cut and the tree-level multiplier are
complementary (the cut admits below-frontier stands, the multiplier supplies magnitude), and each alone
saturates. But the specific interim setting (Maine cut 0.5 with multiplier 2.0) was calibrated to the
+11.1 subsample and therefore over-corrects on the representative full set: applied under ESI it drove
Maine to -2.5 percent BA and the all-region value to -3.9 percent. So that aggressive setting is
withdrawn. On the full set Maine needs only a mild nudge (multiplier about 1.3 to 1.5) or none, and the
principled fix remains a cross-validated regional refit of the Weiskittel (2012) stand-mortality
coefficients, but its priority is lower than the +11 figure implied: the operational over-prediction is
about +5 percent, not +11. The larger part of the Maine value residual (+7.6 percent value against
+4.9 percent BA, with QMD +3.0) is the diameter size-form bias (the standing issue 4), which inflates
large-tree diameter and therefore sawlog value; that is now the higher-leverage remaining item.

## Net

- Site driver: the validated ESI is adopted as the production site driver. It matches the legacy
  climate SI on volume and value and wins on dominant height and biological realism. The AcadianSIm
  climate surfaces are a separate future-climate product and are not the driver (see the data-quality
  note; the 2090 file is a duplicate of 2030).
- Headline validation (full set, 682 plots): all-region BA +1.4 percent, value +1.5 percent; Maine
  +4.9 / +7.6; NB -1.7 / -3.3; NS +3.0 / +2.3.
- Remaining release work, reprioritized: (1) diameter size-form refit (drives the Maine value
  residual), (2) regional stand-mortality coefficient refit (now a modest +5 percent target, not +11),
  (3) finalize ESI v8 surface adoption and the dominant-height anchor in the production code.

## Files

- ESI extraction: `scripts/esi_coords.R` (coords, on Cardinal), `scripts/extract_esi.py` (gdalz),
  `scripts/esi_manifest.R` (merge). Manifests `region_manifest_esi.csv`, `region_manifest_leg.csv`
  (Cardinal). Scorecard rows esi_full, leg_full, esi_prod, leg_prod, esi_cal in
  `results/seven_islands/region_value_scorecard.csv`.
- Render bug: `20260629_ESI_raster_data_quality_note.md`.
