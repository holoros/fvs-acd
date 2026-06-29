# Seven Islands CFI stress test of the AcadianGY site driver

*28 June 2026. Stress test of the ESI site-driver swap on the Seven Islands (SILC) CFI
remeasurement data, run through the existing CFI projection harness with AcadianGY 12.3.9.
Goal: confirm alignment and quantify what the site input actually buys on real growth data.
Plaintext math, no rebuild.*

## What was run

- Harness: the existing `run_acadiangy_on_cfi` machinery (species mapping, unit conversions,
  per-pair projection), AcadianGY 12.3.9, scored against observed CFI remeasurement.
- Pairs: 24 short pairs (silc_cfi_pair_summary) and 65 routine long-horizon pairs
  (silc_cfi_longhorizon_pairs_v16, 5 to 15 yr, establishment pairs excluded).
- Site inputs compared, per plot: flat CSI = 12 (current harness baseline), legacy ClimateNA
  site index, and modern ESI. Legacy CSI and ESI were extracted at the plot coordinates from
  the ClimateNA SI and ESI surfaces.
- Coordinates: from the SILC FIADB PLOT table (LAT_APPROX, LON_APPROX). These are GNIS
  township centroids with a stated 10 km uncertainty, so site values vary by township, not by
  individual plot. Both surfaces covered every plot (0 missing).

## Alignment audit

- Species: every CFI species maps to an AcadianGY code through the harness crosswalks
  (cfi_to_agy, then SPCD_to_AGY), with unmatched species defaulting to OH or OS. Aligned.
- Units: DBH inches to cm, height feet to m, expansion factor per acre to per ha, with metrics
  converted back to imperial for scoring. Aligned.
- Site index: the harness hardcodes CSI = 12 for every plot. Extracted Seven Islands site index
  is higher: legacy ClimateNA SI mean 14.15 m (range 13.4 to 14.5), ESI mean 14.72 m (range
  12.6 to 16.0). The flat 12 under-sites Seven Islands by about 2 to 3 m. This is a real
  alignment gap independent of the ESI question and should be fixed by feeding per-plot site
  index into the harness.

## Result: the site input is a weak lever here

Projecting all routine long-horizon pairs and scoring basal area against observed:

| config        | 5 to 7 yr | 8 to 11 yr | 12 to 15 yr | all (n=65) |
|---------------|-----------|------------|-------------|------------|
| flat CSI 12   | -11.3%    | +17.6%     | +15.8%      | +11.1%     |
| legacy CSI    | -11.2%    | +18.1%     | +16.4%      | +11.5%     |
| ESI           | -11.1%    | +18.3%     | +16.7%      | +11.7%     |

BA R2 by horizon (flat 12): 0.83 at 5 to 7 yr, then -0.22 and -0.13 at the longer horizons.

Reading:

1. The three site inputs differ by under 1 percentage point at every horizon. Moving site index
   across the full plausible range (12 to 16) shifts projected BA by less than 1 pp. The site
   driver is a weak lever on Seven Islands stand projection. ESI in particular is essentially
   identical to legacy CSI here, partly because the township-centroid coordinates compress
   ESI's spatial variation.
2. The bias is strongly horizon dependent: AcadianGY under-predicts BA at short horizons
   (-11% at 5 to 7 yr) and over-predicts at longer horizons (+16 to +18% at 8 to 15 yr), netting
   +11% overall. The model under-grows early and over-grows late.
3. That +11% overall over-prediction matches the +11% seen independently on Maine FIA. Two
   independent datasets, same sign and magnitude. The over-prediction is real and is
   equation-driven, not site-driven: changing the site input does not move it.
4. Bakuzis ordering holds: projected BA is monotone non-decreasing in site index (higher site
   gives more growth), so the swap preserves correct biological ordering.

## What this means for the ESI swap

- The swap is safe. On real CFI growth it does not destabilize projections and keeps correct
  site ordering. It is a site-fidelity improvement (ESI tracks measured site index far better
  than legacy CSI) rather than a fix for the model's growth bias.
- The dominant issue on both Seven Islands and FIA is the equation-level long-horizon BA
  over-prediction (+11 to +18%). That is the province of the mortality / growth calibration
  work already underway (the AGY 12.5.0 MORTCAL and MORTCAL-V variants), not the site input.
- The clearest concrete fix surfaced here is operational alignment: stop using flat CSI = 12 in
  the CFI harness and feed per-plot site index. That is a one-line change and it is correct
  regardless of which site surface is chosen.

## On the ACD_2030_CSI suggestion

Some collaborators suggest using ACD_2030_CSI values (a Climate Site Index built on 2030-period
climate normals) rather than the current normal. That surface is not present in the Seven Islands
data or the SiteIndex rasters on Cardinal, so it needs to be pointed to or generated from the
ClimateNA 2030 normals before it can be extracted at the plots. The stress test already bounds
its impact: because the site lever is weak here (a 4 unit site change moves BA under 1 pp), a
shift from the current normal to a 2030 normal CSI, which would raise site values modestly in
this region, cannot change the Seven Islands conclusions by more than about 1 pp. It is worth
adopting for input fidelity and consistency, but it does not alter the finding that the bias is
equation-driven. Point me to the ACD_2030_CSI surface and I will add it as a fourth config and
report the exact numbers.

## Caveats

- Plot coordinates are GNIS township centroids (10 km uncertainty), so ESI varies by township,
  not by plot. True plot coordinates would widen ESI's spread and could increase any ESI
  advantage. The weak-lever conclusion would likely hold, but the ESI vs legacy contrast is
  conservative under coarse coordinates.
- Short horizons are sparse (n=12 at 5 to 7 yr); the long-horizon bins (n=32 and n=21) carry the
  by-horizon signal.

## Climate-period CSI panel (added 28 June)

The ACD climate-projection site index surfaces (AcadianSIm 2030, 2060, 2090) were extracted at
the plots and run as additional configs. BA bias over all horizons:

| site input | mean site (m) | BA bias (all) |
|---|---|---|
| flat CSI 12 | 12.0 | +11.1% |
| legacy CSI | 14.2 | +11.5% |
| ESI | 15.0 | +11.7% |
| CSI 2060 | 17.5 | +12.1% |
| CSI 2030 | 20.7 | +12.7% |
| CSI 2090 (= 2030 file) | 20.7 | +12.7% |

The future-climate surfaces give higher site index (about 17 to 21 m vs 14 m historical) and
raise projected growth monotonically, increasing the over-prediction from +11.1% to +12.7%. The
lever stays weak: a +73% jump in site index moves BA bias only +1.6 pp. This answers the
ACD_2030_CSI suggestion concretely: adopting a 2030-normal CSI is defensible for input fidelity
but slightly worsens, rather than fixes, the bias, because the bias is equation-driven.

Data-quality flag: AcadianSIm_2030.tif and AcadianSIm_2090.tif are byte-identical (same md5), so
the 2090 surface is a mislabeled duplicate of 2030. Regenerate or relabel before any 2090 use.
The values (about 20 m for 2030, 17.5 for 2060) are also well above the historical 14 m; worth a
units / definition check on the AcadianSIm surfaces.

## Files

- Scripts: `scripts/seven_islands/extract_silc_si.R`, `stress_cfi_site.R`, `stress_cfi_horizon.R`,
  `stress_cfi_climate.R`.
- Results: `results/seven_islands/silc_cfi_horizon_scorecard.csv`, `silc_cfi_site_sensitivity.csv`,
  `silc_cfi_climate_panel.csv`, `silc_plot_si2.csv`, `silc_plot_coords.csv`.
