<!--
Ready-to-insert section: observed-on-predicted regression and the Robinson &
Froese (2004) region of equivalence. Frozen basis (frozen_subsidiary_W.rds,
n = 705). House style: pipe tables, no em dashes, superscript units. Numbers
read from data/equivalence_frozen.csv; region documented in
data/equivalence_frozen_REGION.txt. Do NOT hand-edit numbers here.
-->

## Observed-on-predicted regression and the region of equivalence

### Methods note

For each model, metric and stratum we fit the ordinary least squares regression
of observed on predicted,

```
observed = a + b x predicted
```

and report the slope b, the intercept a, and R². A slope of one and an
intercept of zero mark a model that tracks the 1:1 line. We test that jointly
with a Robinson and Froese (2004) style equivalence test, using two one-sided
tests (TOST) at alpha = 0.05, which is equivalent to checking that the 90%
confidence interval of each parameter falls entirely inside a stated region of
equivalence.

Region choice (documented in data/equivalence_frozen_REGION.txt):

- **Intercept region:** a is equivalent to zero if its 90% confidence interval
  lies within plus or minus 25% of the mean observed value for that metric and
  stratum (region half-width = 0.25 x mean observed). A proportional region is
  used because the nine metrics span very different units and magnitudes, from
  basal area in m² ha⁻¹ to stand value in $ ha⁻¹.
- **Slope region:** b is equivalent to one if its 90% confidence interval lies
  within 1 plus or minus 0.25, that is the interval [0.75, 1.25].
- **Overall:** equivalent only if both the intercept and the slope pass. This
  is the joint flag that the model is statistically indistinguishable from a 1:1
  line within the region we are willing to treat as practically equivalent.

Because observed is regressed on predicted, a slope above one means the model
under-predicts the high end and a slope below one means it over-predicts it.

### Results: pooled equivalence, key metrics

Observed-on-predicted regression and equivalence flags, POOLED in-domain set
(n = 705). TRUE means the parameter's 90% interval lies inside its region of
equivalence.

| Metric | Model | Slope b | Intercept a | R² | Slope equiv | Intercept equiv | Overall |
|:--|:--|:--:|:--:|:--:|:--:|:--:|:--:|
| BA | v12.5.0 | 0.93 | 0.72 | 0.73 | TRUE | TRUE | TRUE |
| BA | v12.7.0 | 1.21 | -0.81 | 0.71 | FALSE | TRUE | FALSE |
| BA | v12.9.x | 1.14 | -0.42 | 0.68 | TRUE | TRUE | TRUE |
| BA | v12.10.1 | 1.14 | -0.42 | 0.68 | TRUE | TRUE | TRUE |
| BA | OSM | 0.98 | 0.79 | 0.74 | TRUE | TRUE | TRUE |
| TOTVOL | v12.5.0 | 0.83 | 8.45 | 0.74 | TRUE | TRUE | TRUE |
| TOTVOL | v12.7.0 | 1.04 | 4.02 | 0.75 | TRUE | TRUE | TRUE |
| TOTVOL | v12.9.x | 0.99 | 5.08 | 0.71 | TRUE | TRUE | TRUE |
| TOTVOL | v12.10.1 | 0.99 | 5.08 | 0.71 | TRUE | TRUE | TRUE |
| TOTVOL | OSM | 0.95 | 2.96 | 0.75 | TRUE | TRUE | TRUE |
| VALUE | v12.5.0 | 0.81 | 419.6 | 0.73 | TRUE | TRUE | TRUE |
| VALUE | v12.7.0 | 1.01 | 230.2 | 0.74 | TRUE | TRUE | TRUE |
| VALUE | v12.9.x | 0.95 | 303.0 | 0.71 | TRUE | TRUE | TRUE |
| VALUE | v12.10.1 | 0.95 | 303.0 | 0.71 | TRUE | TRUE | TRUE |
| VALUE | OSM | 0.93 | 177.5 | 0.74 | TRUE | TRUE | TRUE |

Across all nine metrics on the pooled set, four of the five models pass the
joint equivalence test on every metric (9 of 9). The single exception is
v12.7.0 basal area, where the slope of 1.21 sits just outside the [0.75, 1.25]
region once its confidence interval is included, so basal area is flagged not
equivalent for that build; its intercept still passes and its volume and value
slopes are essentially one.

Where mean bias is low the slope sits near one, as expected. Total volume slopes
run 0.83 to 1.04 and value slopes 0.81 to 1.01, and every volume and value cell
passes overall equivalence for all five models. The operational build v12.10.1
has TOTVOL slope 0.99 and VALUE slope 0.95, both equivalent to one.

### Figure

- **Figure 10** is the observed-versus-predicted equivalence plot, faceted with
  metrics (TOTVOL, VALUE, BA) as rows and the five models as columns. Each panel
  shows the per-stand cloud coloured by forest type, the 1:1 line, the OLS fit,
  and the shaded region of equivalence, and is annotated with the slope b and the
  joint verdict.

### Interpretation

The equivalence test confirms what %RMSE and bias together imply: on total
volume and stand value, the outputs that matter most for management, every model
tracks the 1:1 line within a region we are willing to treat as practically
equivalent, and the operational build does so with slopes near one and no
systematic tilt. The one flag, v12.7.0 basal area, is a slope that runs slightly
steep rather than a location error, consistent with that build's known basal
area behaviour. Equivalence is a stricter and more transparent claim than a low
p-value on a difference test: it states the size of the departure we would
tolerate up front and then shows the models fall inside it.
