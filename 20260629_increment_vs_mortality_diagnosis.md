# What drives the regional BA bias: a mortality deficit, not a growth excess

*29 June 2026. Decomposes the Acadian regional basal-area bias into its growth and mortality parts
by comparing predicted and observed periodic diameter increment on 15,020 matched DBHout tree pairs
(Maine, New Brunswick, Nova Scotia). This is a direct test of the earlier inference that the
long-horizon over-prediction is a growth (increment) problem. It overturns that inference. Bias,
MAE, and RMSE are reported (not R^2), per the modeling philosophy. Plaintext math, no em dashes.*

## The question

Earlier work concluded the persistent Maine long-horizon basal-area over-prediction (+11 to +18
percent) was a growth-side increment issue, inferred indirectly because the exposed mortality and
ingrowth knobs were no-ops and only added mortality (MORTCAL) fixed it. This memo tests that
directly: does AcadianGY over-predict tree diameter increment where it over-predicts stand basal
area? Method: project each matched DBHout interval its full remeasurement length, match surviving
trees by identity, and compare predicted to observed annual diameter increment (cm/yr), decomposed
by region, species group, DBH class, and relative density.

## Result: the increment does not over-predict where BA over-predicts

Overall the diameter increment is essentially unbiased (predicted 0.183, observed 0.183 cm/yr,
n = 15,020; MAE 0.109, RMSE 0.147). The signal is in the strata.

By region:

| region | n | obs dDBH | pred dDBH | bias | bias % | MAE | RMSE |
|---|---|---|---|---|---|---|---|
| Maine | 1849 | 0.241 | 0.206 | -0.035 | -14.5% | 0.134 | 0.184 |
| New Brunswick | 9051 | 0.153 | 0.164 | +0.011 | +7.2% | 0.097 | 0.125 |
| Nova Scotia | 4120 | 0.221 | 0.214 | -0.007 | -3.2% | 0.124 | 0.171 |

The regional pattern is the opposite of the basal-area pattern. On the same plots, stand basal area
over-predicts most in Maine (+11 percent) and under-predicts in New Brunswick (-2.8 percent). But
the per-tree diameter increment under-predicts in Maine (-14.5 percent) and over-predicts in New
Brunswick (+7.2 percent). The effect holds for both hardwood and softwood within each region (Maine
hardwood -16.0, softwood -13.6; New Brunswick hardwood +7.8, softwood +6.8), so it is a regional
effect, not a species-parameter effect.

## The inference: a regional mortality deficit

Stand basal-area change is survivor growth minus mortality. If Maine basal area over-predicts while
Maine trees grow too slowly, the only way to reconcile the two is that too few stems die: basal area
accumulates from excess survivors despite slow individual growth. The Maine over-prediction is
therefore a regional mortality deficit, not a growth excess. The mirror image holds in New
Brunswick: trees grow too fast there yet basal area under-predicts, which points to too much
mortality (the regional parameters over-kill). The regional basal-area bias gradient is driven by
the regional stand-mortality parameters (Weiskittel et al. 2012, fit by region ME/NB/NS), not by the
diameter increment.

This corrects the earlier framing. The earlier reports called the long-horizon over-prediction a
growth-side increment problem; that was an indirect inference and it is wrong. Direct decomposition
shows the increment is conservative in Maine. It also explains, properly, why MORTCAL worked: MORTCAL
adds mortality, and the disease was insufficient mortality, so it was treating the right thing. The
principled fix is to recalibrate the regional stand-mortality parameters (Maine mortality is too low,
New Brunswick too high), of which MORTCAL is a crude size-dependent surrogate.

## Separately: the increment has a size-form bias and a high-density bias

These are real but distinct from the regional BA bias:

| DBH class | bias % | | relative density | bias % |
|---|---|---|---|---|
| < 10 cm | +14.3 | | < 0.4 | -5.5 |
| 10 to 20 cm | -2.0 | | 0.4 to 0.6 | +4.7 |
| 20 to 30 cm | -4.5 | | 0.6 to 0.8 | +9.5 |
| 30+ cm | -13.0 | | 0.8+ | -19.1 |

The increment over-grows small trees (+14 percent under 10 cm) and under-grows large trees (-13
percent at 30+ cm): the size response of the Kuehne et al. (2022) dDBH function is too flat across
the diameter range. And it under-predicts strongly at high relative density (-19 percent at RD
0.8+), meaning the density and competition (BAL) terms over-suppress growth in the densest stands.
In Maine the under-prediction is present at all densities and is most severe at high density (-46
percent at RD 0.8+).

## Recommendations (in leverage order)

1. Regional mortality recalibration is the fix for the regional BA bias. Refit or re-weight the
   Weiskittel et al. (2012) stand-mortality parameters by region; Maine needs more mortality, New
   Brunswick less. This is the principled replacement for MORTCAL and the direct cause of the
   operational over-prediction. Validate with this same predicted-vs-observed decomposition plus the
   regional BA bias.
2. The diameter-increment size-form bias (over-grow small, under-grow large) is a separate, smaller
   refit of the dDBH equation's size response; worth doing but it is not the regional BA driver.
3. The high-density growth under-prediction (-19 percent at RD 0.8+) interacts with the
   self-thinning frontier work; the density and BAL terms are over-suppressing growth in dense
   stands. Check this against the SDImax-ceiling self-thinning so the two density mechanisms are not
   double-counting.

## Corroboration from stem counts

The mortality-deficit inference is independently corroborated by the regional stem-count bias from
the volume-and-value validation. On the same regional data, Maine over-predicts stems per acre by
+10 percent (the model carries too many live trees, that is, too few die), New Brunswick is about
right (-1.8 percent), and Nova Scotia over-predicts (+6.7 percent). A stem-count over-prediction is
exactly a mortality deficit. So three independent lines agree: Maine under-grows diameter (-14.5
percent), over-predicts stems (+10 percent), and over-predicts basal area (+11 percent). The only
configuration consistent with all three is too little mortality in Maine. That converts the
inference into a corroborated conclusion.

## Caveat

This decomposes survivor growth and corroborates with stem counts; a direct predicted-vs-observed
survival-probability decomposition by region would be the final confirmation. The next step is a parallel
predicted-vs-observed mortality (survival probability) decomposition by region to confirm the Maine
mortality deficit directly. The remeasurement intervals are mostly 5 years.

## Files

- Script: `scripts/ddbh_diag.R`
- Results: `results/seven_islands/ddbh_diag_trees.csv` (15,020 trees),
  `ddbh_diag_by_region.csv`, `ddbh_diag_by_rd.csv`
