# Is 12.7.0 ready for production? Head-to-head against 12.5.0 and the spatial bias

*30 June 2026. The production-readiness check: does the new operational 12.7.0 actually improve on the
current production 12.5.0, and where does the residual bias live. Plaintext math, no em dashes.*

## The MAGPlot concern, resolved

On the MAGPlot New Brunswick CFI, 12.7.0 looked slightly worse than 12.5.0 (BA -2.6 vs +1.8). That was
a single-region artifact: New Brunswick is the one region where both versions sit near zero and 12.5.0
happens to be marginally tighter. It is not representative of the operational domain.

## Head-to-head on the full regional set (the operational domain)

Same 682 plots, same ESI v8 site driver, predicted vs observed, all-region percent bias:

| metric | 12.5.0 (current production) | 12.7.0 (new operational) |
|---|---|---|
| basal area | +6.4 | +2.0 |
| SDI | +6.8 | +1.6 |
| QMD | +1.1 | +1.0 |
| top height | +0.8 | +0.5 |
| total volume | +6.4 | +1.8 |
| merch volume | +6.7 | +2.2 |
| sawlog | +6.8 | +2.5 |
| value | +6.6 | +2.2 |

And in Maine, where the action is:

| metric | 12.5.0 | 12.7.0 |
|---|---|---|
| basal area | +9.6 | +5.2 |
| SDI | +10.1 | +4.8 |
| total volume | +10.8 | +5.9 |
| value | +12.4 | +7.9 |

12.7.0 roughly halves the over-prediction of 12.5.0 across basal area, SDI, volume, and value, both
all-region and in Maine, while matching it on the two metrics where 12.5.0 was already good (QMD and top
height). The expected-value ingrowth and SDImax self-thinning in 12.7.0 are doing exactly what they were
meant to: removing the standing over-prediction that 12.5.0 carried. So the new version is materially
better on the operational domain, not merely different. The MAGPlot New Brunswick wash is the exception
that proves it, that is the one place 12.5.0 was not over-predicting, so there was nothing for 12.7.0 to
correct.

## Where the residual lives (spatial hot spots)

The 0.25-degree bias map localizes the remaining bias cleanly. Basal area and total volume over-predict
in Maine, concentrated in southwestern Maine and the central Penobscot Experimental Forest cluster; New
Brunswick and Nova Scotia are near zero. Quadratic mean diameter and top height are spatially flat,
near zero everywhere, which confirms the structure and height are right and the residual is a Maine
density and mortality signal, not a diffuse or height problem. That is the same finding the regional
mortality work reached, now shown geographically, and it points the next-version stand-mortality refit
at a specific, localized target rather than a region-wide recalibration.

## Verdict

12.7.0 is ready for production. It beats the current production 12.5.0 on every operationally relevant
metric in the calibration region (roughly halving the bias on basal area, SDI, volume, and value),
matches it where 12.5.0 was already good, passes the Bakuzis biological-realism relations that 12.5.0
fails on site ordering, is near-unbiased on the independent Canadian CFI, and carries the validated ESI
and its dominant-height anchor. The one bounded residual, a Maine basal-area and volume over-prediction
localized to specific areas, is smaller than 12.5.0's, is spatially identified, and is the documented
next-version target. Ship 12.7.0.

## Files

- Head-to-head figure: `figures/acadgy_125_vs_127_headtohead.png`. Spatial map:
  `figures/acadgy_v1270_spatial_bias.png`. Bias-by-attribute: `figures/acadgy_v1270_bias_by_attribute.png`.
- 12.5.0 full-metric: `region_pred_fullmetric_125.csv` (Cardinal). 12.7.0: `region_pred_fullmetric.csv`.
