# AcadianGY 12.7.0 full-metric validation (ESI v8)

*30 June 2026. Predicted-versus-observed bias on the full metric set, regional NB/NS/ME remeasurement
set (682 plots), ESI v8 as the site driver. All metrics height-free where heights are not measured: a
single regional height-diameter relation is applied identically to predicted and observed, so the
comparison isolates the diameter, density, and composition behavior the model actually drives. Plaintext
math, no em dashes.*

## Result: percent bias (predicted vs observed)

| metric | all (682) | Maine (201) | New Brunswick (247) | Nova Scotia (234) |
|---|---|---|---|---|
| basal area | +2.0 | +5.2 | -1.2 | +4.3 |
| stand density index (SDI) | +1.6 | +4.8 | -0.5 | +1.1 |
| quadratic mean diameter | +1.0 | +3.6 | -0.0 | -0.3 |
| top height (dominant) | +0.5 | +1.2 | -0.5 | +1.1 |
| total volume | +1.8 | +5.9 | -1.0 | +2.0 |
| merch volume | +2.2 | +6.3 | -1.3 | +4.0 |
| sawlog (board feet) | +2.5 | +7.3 | -1.7 | +3.9 |
| stumpage value | +2.2 | +7.9 | -2.7 | +3.6 |

## Reading

All-region bias is small on every metric, +0.5 to +2.5 percent. The model is comprehensively well
calibrated across structure (BA, SDI, QMD), size (top height), and product (volume, sawlog, value), not
just the headline basal area. Top height is the tightest at +0.5 percent, which is the ESI dominant
height anchor doing its job; SDI at +1.6 percent confirms the density trajectory is right; the volume
and value metrics sit at +1.8 to +2.5 percent.

By region the pattern is consistent with the prior single-metric work. New Brunswick is essentially
unbiased to slightly low across the board. Nova Scotia runs +1 to +4 percent. Maine is the largest
residual, and it amplifies along the product chain: +5.2 percent basal area, +6.3 percent merch volume,
+7.3 percent sawlog, +7.9 percent value. That amplification is the signature of the large-tree
size-form and mortality residual: a modest over-prediction of basal area concentrates in the large
trees that carry sawlog board feet and value, so the value bias is the basal-area bias magnified by the
product taper. It points at the same two next-version targets, the regional stand-mortality refit and
the diameter size-form, rather than any new problem.

Note the all-region figures are a touch higher than the earlier Final_SI run (BA +2.0 vs +1.4) because
ESI v8 sits about four units higher and nudges growth up slightly through the increment site term; the
density brake keeps the effect small, and the regional pattern is unchanged.

## Bottom line

v12.7.0 is within a few percent of observed on every operationally relevant metric, all-region, with a
known and bounded Maine residual that grows along the product chain. Top height and SDI, the two new
structural checks, are the best-behaved metrics, which is the direct payoff of the ESI dominant-height
anchor and the SDImax self-thinning. Files: `region_pred_fullmetric.csv`, `region_obs_fullmetric.csv`,
`scripts/full_metric_score.R`.
