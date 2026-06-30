# Three-way benchmark: current production (12.5.0), new operational (12.7.0), and OSM

*30 June 2026. Head-to-head on the independent MAGPlot New Brunswick Canadian CFI (262 remeasurement
pairs), each model projected from the same starting inventory to the observed remeasurement interval and
compared to the observed second measurement. ESI v8 site driver for both FVS-ACD versions. Plaintext
math, no em dashes.*

## Result (percent bias vs observed)

| model | basal area | QMD | stems | R2 (BA) |
|---|---|---|---|---|
| AcadianGY 12.5.0 (current production) | +1.8 | +1.2 | -1.1 | 0.877 |
| AcadianGY 12.7.0 (new operational) | -2.6 | +4.2 | -6.3 | 0.868 |
| OSM v2.26.1 | -2.3 | -8.9 | n/a | n/a |

(OSM stems not shown; it applies a different minimum-diameter convention when summarizing, so basal area
and QMD are the clean cross-model metrics.)

## Reading

All three models are excellent and close on this independent Canadian dataset: basal area within plus or
minus 3 percent of observed for every model, and within 4.4 points of each other. The current production
12.5.0 is marginally the tightest here on basal area (+1.8) and stems (-1.1); the new operational 12.7.0
runs slightly low (-2.6 percent basal area) because its expected-value ingrowth and SDImax self-thinning
remove a little more stand basal area than 12.5.0 did; OSM sits between them on basal area (-2.3) but is
the weakest on diameter (QMD -8.9 versus FVS-ACD's +1.2 to +4.2).

The honest message is that 12.7.0 does not beat 12.5.0 on short-interval basal area on independent data,
the two are statistically comparable, both near-unbiased. What 12.7.0 buys is not a short-term accuracy
gain but biological realism and completeness: it fixes the dominant-height site-ordering flaw (Bakuzis
inversions 25 to 0), steepens self-thinning toward Reineke, adds the recruitment term, carries the
validated ESI and its dominant-height anchor, and is validated across the full metric set (basal area,
SDI, QMD, top height, total and merch volume, sawlog, value), all within a few percent all-region. Those
are the properties that matter for long-horizon projection and for the variant standing, which is where
12.5.0 and OSM differ most (the Seven Islands long-horizon run showed FVS-ACD self-thinning while OSM
accumulates, a 35 percent divergence by age 60 with no observed truth at that horizon).

So the three-way reads: at the data-supported intervals all three are accurate and interchangeable on
basal area; 12.7.0 is the version to carry forward because it is the most biologically consistent and
the most completely validated, not because it wins the short-interval bias contest.

## Files

- 12.5.0: `magplot_v125_esi8_results.csv`; 12.7.0: `magplot_v1270_esi8_results.csv`; OSM:
  `magplot_osm_v_obs.csv` (all on Cardinal, ~/magplot/verify).
- Figure: `figures/acadgy_3way_benchmark_magplot.png`.
- Bias-by-attribute diagnostic (12.7.0, SDI/QMD/BA/volume): `figures/acadgy_v1270_bias_by_attribute.png`.
