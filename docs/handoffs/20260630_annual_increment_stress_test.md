# Stress test: annualized increment assessment (the honest growth-model metric)

*30 June 2026. Re-assessing FVS-ACD on the annual increment rather than the end-state level, normalized
by projection interval. A growth model predicts the change, not the level; the starting stand (shared by
predicted and observed) dominates the level, so the level bias understates the model error. Plaintext
math, no em dashes.*

## Why the level bias flatters the model

The regional remeasurement stands are mature and dense (mean basal area about 20 m2/ha) and grow slowly
in net terms (observed mean annual basal-area increment 0.074 m2/ha/yr, growth nearly offset by
mortality). Over a typical 5 to 7 year interval the net change is only about 0.4 m2/ha, tiny against the
starting 20. So even a model that doubles the predicted growth moves the end-state level by only a couple
percent. The +2.0 percent level bias is real and fine for stand-level projection over an inventory cycle,
but it is not the growth-model error.

## Annual basal-area increment (m2/ha/yr), predicted vs observed

| model | increment bias | percent of observed increment | RMSE |
|---|---|---|---|
| observed mean | 0.074 | - | - |
| 12.5.0 (production) | +0.288 | +387 | 1.077 |
| 12.7.0 (operational) | +0.079 | +106 | 1.037 |
| OSM v2.26.1 | +0.930 | +1249 | 1.633 |

Annual total-volume increment tells the same story: observed 0.70 m3/ha/yr; 12.5.0 +2.03 (+290 percent),
12.7.0 +0.51 (+72 percent).

## Reading

Two messages. First, the honest growth-model error: 12.7.0 over-predicts the net annual increment by
about a factor of two (the mortality deficit, diameter growth is fine, too many stems survive so basal
area accumulates faster than observed). This is much larger than the +2 percent level bias suggested,
and it is the same regional stand-mortality signal the project has tracked throughout, now quantified at
the increment level for the first time. Second, and decisive for the production choice: 12.7.0 is clearly
the best of the three on the increment, bias +0.079 versus 12.5.0's +0.288 and OSM's +0.930, and the
lowest RMSE. OSM over-predicts the increment by more than twelve-fold because it does not self-thin these
dense stands at all.

Annualizing removed the projection-length dependence: the 12.7.0 increment bias is stable across interval
classes (+0.081 at 0 to 5 years, +0.060 at 5 to 8 years), confirming the interval normalization is the
right basis. By region the increment bias is +0.180 in Maine, -0.061 in New Brunswick, +0.142 in Nova
Scotia, the Maine over-prediction is the localized hot spot, consistent with the spatial maps.

The RMSE (about 1.04 m2/ha/yr) is large relative to the bias because the per-plot net increment is noisy
(individual stands gain or lose basal area depending on mortality events); the bias is the systematic
signal and the ranking across models is clear and robust.

## Maps

The annual-increment maps (absolute units, no ratio skew) discriminate the models cleanly:
`acadgy_annual_rmse_3way.png` (RMSE, OSM clearly highest) and `acadgy_annual_bias_3way.png` (signed
bias, 12.7.0 balanced, 12.5.0 moderate over, OSM uniformly over). These supersede the level-based maps,
which were dominated by the shared starting stand and by the percent-ratio skew.

## Implication for the production path

12.7.0 remains the right operational version: best of the three at both level and increment, biologically
consistent, near-unbiased at the stand level over inventory cycles. But the annual-increment stress test
sharpens the priority: the next-version regional stand-mortality refit matters more than the +2 percent
level bias implied, because the model over-predicts the net annual increment by about two-fold. The
interim mortality levers (the gated cut scale and multiplier in 12.6.4) are the lever to test against the
increment, not just the level; that is the recommended next refinement before any deposit.

## Files

- `scripts/annual_increment_stress.R`; per-plot `results/seven_islands/region_annual_increment.csv`.
- `scripts/annual_maps.R`; figures `acadgy_annual_rmse_3way.png`, `acadgy_annual_bias_3way.png`.
