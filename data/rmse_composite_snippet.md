<!--
Ready-to-insert section: %RMSE accuracy-and-precision scorecard and the
%RMSE-weighted composite. Frozen basis (frozen_subsidiary_W.rds, n = 705).
House style: pipe tables, no em dashes, superscript units. Numbers are read
from data/scorecard_rmse_frozen.csv and data/composite_rmse_frozen.csv.
Do NOT hand-edit numbers here; regenerate from the frozen tables.
-->

## Accuracy and precision: percent RMSE

### Methods note

Percent bias measures only systematic offset and it inflates on metrics with
low means, so a small absolute error reads as a large percentage. To score
accuracy and precision together we add the root mean squared error and its
scale-free form, the percent RMSE:

```
RMSE   = sqrt( mean( (observed - predicted)^2 ) )
%RMSE  = 100 x RMSE / mean(observed)
```

Unlike percent bias, %RMSE penalises both systematic error and scatter, so it
does not deflate on high-mean metrics and does not inflate on low-mean ones.
Uncertainty on %RMSE is a within-province stratified bootstrap (2000 replicates,
seed 42), resampling stands within New Brunswick and Quebec so the interval
respects the two-province design. We report %RMSE alongside the mean bias
percent (kept for continuity), the mean absolute error, and the Nash-Sutcliffe
efficiency (NSE).

### Results: percent RMSE on the operational in-domain set

Percent RMSE by model and metric, POOLED in-domain set (n = 705). Lower is
better; values are read from the frozen scorecard. Units are carried by each
metric (BA m² ha⁻¹, TOPHT m, TOTVOL, MERCHVOL, SAWVOL and BIOMASS m³ ha⁻¹ or
Mg ha⁻¹, VALUE $ ha⁻¹) but %RMSE is dimensionless.

| Metric | v12.5.0 | v12.7.0 | v12.9.x | v12.10.1 | OSM |
|:--|:--:|:--:|:--:|:--:|:--:|
| Basal area (BA) | 40.8 | 45.3 | 45.8 | 45.8 | 39.6 |
| Stand density index (SDI) | 40.9 | 45.9 | 46.2 | 46.2 | 39.6 |
| Quadratic mean diameter (QMD) | 27.8 | 25.4 | 25.7 | 25.7 | 29.1 |
| Top height (TOPHT) | 18.8 | 18.2 | 18.4 | 18.4 | 16.1 |
| Total volume (TOTVOL) | 56.0 | 52.3 | 55.2 | 55.2 | 51.1 |
| Merch volume (MERCHVOL) | 53.6 | 50.9 | 53.4 | 53.4 | 49.0 |
| Sawlog volume (SAWVOL) | 57.7 | 55.1 | 57.8 | 57.8 | 53.4 |
| Aboveground biomass (BIOMASS) | 52.2 | 47.9 | 50.6 | 50.6 | 47.2 |
| Stand value (VALUE) | 62.0 | 55.8 | 59.4 | 59.4 | 56.3 |

Structure metrics are tight (TOPHT near 18%, QMD near 26%). The
merchantable-output metrics carry the scatter: TOTVOL, SAWVOL and VALUE all sit
in the mid-50s to low-60s percent even where mean bias is only a few percent,
which is the point of the metric. On the pooled set v12.10.1 TOTVOL is 55.2%
(95% interval 49.1 to 61.7) and VALUE is 59.4% (52.1 to 67.0); OSM is a little
lower at 51.1% and 56.3%.

### %RMSE-weighted composite

We rebuild the overall composite on %RMSE rather than bias. Each metric earns a
0 to 100 score,

```
metric_score = 100 x max(0, 1 - %RMSE / CAP),   CAP = 100
```

so a metric with %RMSE of 0 scores 100 and one at 100% or worse scores 0
(formula documented in data/composite_rmse_frozen_FORMULA.txt). The PRIMARY
composite is the weighted mean of the nine metric scores with volume and value
carrying the highest weight: TOTVOL 3, VALUE 3, MERCHVOL 2, SAWVOL 2, BIOMASS 2,
BA 1, SDI 1, QMD 1, TOPHT 1 (weights sum to 16). We keep the prior bias-and-NSE
composite as a labeled reference column so the change of basis is visible in one
table.

Overall composite on the pooled in-domain set, %RMSE basis (primary) with the
prior bias basis carried alongside. Higher is better.

| Model | %RMSE composite | %RMSE rank | Bias composite | Bias rank |
|:--|:--:|:--:|:--:|:--:|
| OSM | 53.4 | 1 | 79.3 | 1 |
| v12.7.0 | 52.1 | 2 | 66.4 | 5 |
| v12.9.x | 49.8 | 3 | 73.0 | 2 |
| v12.10.1 | 49.8 | 3 | 73.0 | 2 |
| v12.5.0 | 49.4 | 5 | 67.9 | 4 |

The ranking changes when the basis moves from bias to %RMSE. OSM stays first on
both. The largest move is v12.7.0, which is last on the bias composite (it
carries real systematic offsets, for example BA bias -13.4%) but second on the
%RMSE composite, because once systematic and random error are scored together
its scatter is competitive. The operational build v12.10.1 ties v12.9.x at 49.8
(rank 3); on the bias composite the same pair ranked second. In short, the
bias-only view flatters low-scatter-but-biased builds and the %RMSE view rewards
the model that is simultaneously unbiased and precise.

By forest type, PRIMARY %RMSE composite (higher is better):

| Model | POOLED | Softwood | Mixedwood | Hardwood |
|:--|:--:|:--:|:--:|:--:|
| v12.5.0 | 49.4 | 61.2 | 57.8 | 23.5 |
| v12.7.0 | 52.1 | 56.3 | 59.1 | 39.2 |
| v12.9.x | 49.8 | 55.3 | 58.2 | 33.4 |
| v12.10.1 | 49.8 | 55.3 | 58.2 | 33.4 |
| OSM | 53.4 | 61.6 | 59.5 | 34.4 |

Every model scores far lower on hardwood than on softwood or mixedwood, a shared
frontier rather than a defect of any one build (see the hardwood note below).

### Figures

- **Figure 1** now carries an Overall composite strip beneath the per-metric
  bias tiles, showing each model's PRIMARY %RMSE-weighted composite (0 to 100)
  on its own green scale, clearly separated from the bias-flag tiles.
- **Figure 11** is the %RMSE scorecard: the model by metric heatmap of %RMSE on
  the pooled set, with within-province bootstrap intervals in each cell.

### Interpretation: the hardwood reframe

Hardwood error is scatter-dominated, not bias-dominated. On the hardwood
stratum v12.10.1 total volume carries a mean bias of about +19% but a %RMSE of
about 76%; stand value is about +20% bias against about 81% %RMSE. OSM is
similar, with hardwood TOTVOL %RMSE of about 75% and VALUE about 80%. Every
model shows the same pattern: the percentage bias understates the true error
because most of that error is variance, not offset. Hardwood is a high-variance
frontier shared by all five models, and reporting %RMSE rather than bias alone
keeps that honest.
