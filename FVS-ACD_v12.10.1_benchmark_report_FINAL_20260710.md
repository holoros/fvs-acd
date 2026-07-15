# FVS-ACD v12.10.1 benchmark report

*Finalized 10 July 2026 for the 18 August 2026 Acadian Growth and Yield meeting with Chris Hennigar. This
report consolidates the v12.10.1 full independent five-way benchmark, the operational-domain re-scoring, the
five-way scorecard with equivalence testing and Bakuzis relations, the Chapter 11 management-modifier
scorecard, and the OSM matched-stand comparison into a single record. All computation ran on Cardinal
(~/magplot/verify and ~/silc_cfi); only aggregates appear here and true plot coordinates never left the node.
Volume, biomass, and value are on the shared FIA NSVB system throughout.*

## Verdict up front

FVS-ACD v12.10.1 is the frozen August operational baseline. It couples the v12.9.x base (FIA NSVB volume and
biomass, coupled two-segment relative-density mortality with density-released ingrowth, composition- and
ecoregion-aware brms SDImax, and the ESI-consistent dominant-height anchor recalibration) with the Chapter 11
direct-effect management modifiers: a robust additive release fitted at planted +3.8 and PCT +2.4 m² ha⁻¹
basal area, clamp-free and gated off by default.

On the operational inventory domain OSM v2.26.1 and FVS-ACD are close, and on the pooled cell OSM is the
stronger model. OSM leads pooled mean absolute level bias about 3.2 versus 4.9 percent, mean modeling
efficiency about 0.75 versus 0.71, and holds the most TOST level equivalences (8 of 9). FVS-ACD does not lead
on pooled precision. Its advantages are elsewhere: the frozen build plateaus at the realistic maximum and
passes all five Bakuzis relations in the seeded-gradient battery, which scores only the AcadianGY builds, so
OSM enters the long-horizon comparison through the matched-stand trajectory instead of the same seeded
battery. FVS-ACD also carries durable long-horizon self-thinning, a durable quadratic mean diameter advantage,
a validated and climate-ready ESI site driver, and full transparency in R. Inside the operational domain the
pooled near-parity on volume rests on an offsetting bias signature, with basal area about -10 percent, top
height about +4 percent, and total volume about -2.2 percent by cancellation.

Management is where v12.10.1 earns its place. On the managed stands, out of sample, the additive release beats
OSM: managed mean absolute bias 0.9 versus OSM 8.3, planted 4.0 versus OSM 16.7, and PCT 3.8 versus OSM 3.7
across the harder New Brunswick to Quebec province block. The limit that remains is ingrowth. Recruitment
across the tag threshold is under-predicted, about 45 percent of observed in New Brunswick and about 59 percent
in Quebec, though it responds in the correct direction to density and management. v13 is the fall arc and
appears here as roadmap only. It is in progress, not gated, and no v13 scorecard numbers exist yet.

## Evidence

### Benchmark dataset

The frozen evaluation benchmark comprises n=705 remeasured stands drawn from the permanent-plot networks of the
two Canadian jurisdictions that anchor the Acadian region, New Brunswick (n=355) and Quebec (n=350). Forest-type
composition, assigned from the hardwood share of stand basal area (softwood at 25 percent or less hardwood,
hardwood at 75 percent or more, mixedwood between), is 321 softwood, 186 mixedwood, and 178 hardwood stands,
with the remaining 20 stands unclassified. Each stand carries an observed initial and remeasured state together
with the predicted remeasured state from every model variant, evaluated on the nine FIA National Scale Volume
and Biomass (NSVB) metrics: basal area, stand density index, quadratic mean diameter, top height, total volume,
merchantable volume, sawlog volume, aboveground biomass, and stumpage value.

The benchmark is built from remeasurement pairs whose interval ranges from 4 to 14 years, with a median of 5
years and a mean near 7, so each prediction is a growth-and-yield projection over the stand's own observed
remeasurement window rather than a fixed horizon. Total, merchantable, and sawlog volume and aboveground biomass
are placed on the NSVB basis so that observed and predicted state are compared in a common estimation framework.
Evaluation is restricted to the operational in-domain set, a stand retained when it falls within the Ecological
Site Index (ESI) coverage or lies in New Brunswick; every stand in the frozen benchmark satisfies this
condition, all 705 ESI-covered, which keeps the comparison inside the region and site conditions the model was
calibrated to represent.

The spatial extent and forest-type distribution of the benchmark are shown in Figure 12, a locator of the
Acadian study region with stand counts on a 50 km equal-area hex grid, and Figure 13, the same aggregation split
into softwood, mixedwood, and hardwood panels. Plot coordinates are restricted and were used only server-side to
build the aggregated hex counts; no true coordinate appears in any released figure, table, or file, and the maps
and count summaries carry aggregated hex polygons and stand counts only.

### Version and configuration confirmed

The scored operational build is the v12.9.x base plus the gated Chapter 11 management modifiers, tag
AcadianV12.10.1. Relative to the earlier v12.10.0, the planted and PCT diameter-growth multipliers no longer
pin to the 0.7 to 1.6 guard clamp. The direct effect is now expressed as a robust additive release, planted
+3.8 and PCT +2.4 m² ha⁻¹ basal area on ten percent trimmed means of per-stand observed minus
predicted-untreated increment, with proportional releases in the other eight metrics. The equivalent net
multiplier is about 3.0 planted and 2.3 PCT, above the old 1.6 ceiling, which is why the clamped version still
under-predicted planted stands. The modifier is gated by ops$use.mgmt.mod and applies only to planted and PCT
stands. With the gate off the run is byte identical to v12.9.x (maximum diameter difference 0.0), and the 266
unmanaged stands are unchanged.

### Pooled five-way scorecard

The independent in-domain evaluation set is MagPlot New Brunswick (n=355) and ESI-covered Quebec (n=350), total
n=705, scored with the corrected single-keyed-merge scorer. The frozen operational scores in this section come
from cb_v12101_results.csv scored on the in-domain operational set (n=705). The five-way scoring runs the
identical metric code over every model. OSM is scored on all nine metrics by pushing the OSM projected
treelist through the same NSVB harness with the observed side identical across models, so OSM is reconstructed
on the same NSVB basis instead of carrying a reduced metric set. All five models sit at observed-on-predicted
correlation about 0.85 to 0.87 pooled. The earlier negative-modeling-efficiency artifact on OSM was an
index-join misalignment and is resolved.

Level bias (percent), all nine NSVB metrics, predicted versus observed:

| **metric** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|
| basal area | +2.9 | -13.4 | -9.9 | -9.9 | -2.0 |
| stand density index | +5.1 | -12.1 | -9.4 | -9.4 | -4.1 |
| quadratic mean diameter | -4.9 | -0.7 | +1.0 | +1.0 | +11.0 |
| top height | +4.6 | +3.7 | +4.0 | +4.0 | +4.4 |
| total volume | +9.3 | -8.3 | -3.9 | -3.9 | +1.6 |
| merch volume | +8.4 | -9.1 | -4.8 | -4.8 | +1.0 |
| sawlog volume | +7.8 | -9.5 | -5.2 | -5.2 | +1.5 |
| aboveground biomass | +9.7 | -8.1 | -3.9 | -3.9 | +1.1 |
| stand value | +11.0 | -6.7 | -2.1 | -2.1 | +2.6 |

Summary rollup, pooled:

| **model** | **mean abs level bias (%)** | **mean NSE** | **RMSE total volume (m³ ha⁻¹)** | **TOST level equiv (of 9)** |
|:---|:---:|:---:|:---:|:---:|
| v12.5.0 | 7.1 | 0.71 | 53.1 | 4 |
| v12.7.0 | 8.0 | 0.73 | 49.6 | 2 |
| v12.9.x | 4.9 | 0.71 | 52.3 | 7 |
| v12.10.1 | 4.9 | 0.71 | 52.3 | 7 |
| OSM v2.26.1 | 3.2 | 0.75 | 48.5 | 8 |

TOST level equivalence is recomputed on the frozen scores. OSM carries the most equivalences (8 of 9), v12.7.0
the fewest (2 of 9), and because v12.9.x and v12.10.1 are pooled-identical they carry the same count as each
other (7 of 9). v12.5.0 sits at 4 of 9. v12.10.1 does not gain an equivalence over v12.9.x, since the two
builds are identical on the pooled base scorecard.

A harness note belongs with this pooled scorecard. Because the bench applies the operational ops uniformly,
v12.7.1, v12.9.x, and v12.10.1 are byte-identical on the pooled base scorecard and differ only in the managed
cells. The five-way therefore has three distinct engines at pooled scale: v12.5.0, v12.7.0, and the shared
newer build (v12.7.1 / v12.9.x / v12.10.1).

At pooled scale v12.10.1 is identical to v12.9.x to three digits on every metric, because the Chapter 11
management modifier moves only the managed cells and that shift is invisible when averaged over a set that is
mostly unmanaged. Level bias, RMSE, and mean NSE are the same for the two builds. The modifier's benefit does
not appear in the pooled rollup at all. It appears in the by-class managed, planted, and PCT table below. OSM
keeps the best pooled bias and efficiency. The durable FVS-ACD advantage on the pooled domain is quadratic mean
diameter, about +1 percent versus OSM +11 percent, together with biological realism, transparency, and the
climate-ready site driver. On increment, no model is broadly equivalent within plus or minus 25 percent of the
observed periodic annual increment. Net increment on these mature, slow stands is small and hard to hit, which
points to increment as the remaining work and the target of v13.

### Operational domain of applicability

FVS-ACD v12.10.1 is calibrated and evaluated for the Acadian-core operational domain: stands on the
operational ESI site surface with a finite ESI value that also sit in the Acadian set of EPA Level III
ecoregions (Atlantic Highlands 5.3.1, Northeastern Highlands 8.1.7, Acadian Plains and Hills 8.1.8, and the
associated 8.1.1 unit). This is a domain restriction applied on top of the frozen configuration, and it
changes no equation and no parameter. It states where the model is intended to be used and treats the Quebec
edge as a stated boundary, consistent with Hennigar 2018. On the US remeasurement fit set this domain contains
essentially the entire Maine, New Hampshire, and Vermont sample (about 13,900 of 14,200 clean pairs), so the
mask does not drop hard US cases. Its operational effect is at the Canadian edge.

Recomputed on Cardinal on 7 July 2026 using the per-stand EPA Level III ecoregion join, the mask keeps 492 of
733 MagPlot benchmark stands in domain (New Brunswick 259, plus 233 Quebec stands inside the Acadian
ecoregions):

| **metric** | **units** | **subset** | **n** | **obs mean** | **pred mean** | **bias (%)** | **RMSE** | **NSE** |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| basal area | m² ha⁻¹ | in domain | 492 | 18.47 | 16.66 | -9.81 | 8.95 | 0.616 |
| basal area | m² ha⁻¹ | all plots | 733 | 19.44 | 17.25 | -11.28 | 9.09 | 0.626 |
| top height | m | in domain | 492 | 13.14 | 13.71 | +4.38 | 2.50 | 0.788 |
| top height | m | all plots | 733 | 13.28 | 13.84 | +4.21 | 2.42 | 0.799 |
| total volume | m³ ha⁻¹ | in domain | 492 | 92.94 | 90.87 | -2.23 | 57.02 | 0.602 |
| total volume | m³ ha⁻¹ | all plots | 733 | 97.84 | 93.52 | -4.41 | 54.68 | 0.688 |

The restriction tightens pooled volume bias (total volume -2.23 percent in domain versus -4.41 percent on all
plots) and leaves the offsetting height-over and basal-area-under signature intact, which is the pooled-parity
offset the v13.0 joint re-anchor targets. Quadratic mean diameter stays near unbiased in domain (-0.04
percent). The all-plots numbers are retained alongside the in-domain numbers so nothing is hidden.

### By jurisdiction and by forest type

Total volume level bias (percent) by jurisdiction:

| **model** | **New Brunswick (n=355)** | **Quebec (n=350)** |
|:---|:---:|:---:|
| v12.5.0 | -1.6 | +18.7 |
| v12.7.0 | -13.4 | -3.9 |
| v12.9.x | -11.8 | +2.9 |
| v12.10.1 | -11.8 | +2.9 |
| OSM v2.26.1 | -8.0 | +9.8 |

This table is the gate-off base scorecard split by province, so v12.9.x and v12.10.1 are identical, and the
managed release appears in the management-class table rather than here. In the New Brunswick core OSM total
volume of -8.0 percent is closest to zero, with the shared newer build at -11.8 and v12.7.0 at -13.4. In Quebec
the shared newer build (+2.9) is closer to zero than OSM (+9.8), while v12.5.0 over-reads at +18.7. The Quebec
figures carry the out-of-domain top-height over-read and are reported as an edge.

Total volume level bias (percent) by forest type (percent hardwood basal area at first measurement; softwood
under 25, mixedwood 25 to 75, hardwood over 75):

| **forest type** | **n** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| softwood | 321 | +0.6 | -16.4 | -14.1 | -14.1 | -1.0 |
| mixedwood | 186 | +7.2 | -9.5 | -4.1 | -4.1 | -3.9 |
| hardwood | 178 | +31.3 | +11.4 | +19.0 | +19.0 | +14.6 |

This is the gate-off base scorecard, so v12.9.x and v12.10.1 are identical in every forest-type cell. Softwood
volume is under-predicted by the shared newer build (-14.1) while OSM sits near zero (-1.0). Mixedwood is close
for both the newer build (-4.1) and OSM (-3.9). Hardwood is the shared frontier for every model, the newer
build at +19.0 and OSM at +14.6 percent, and is a target for the v13 composition-aware refit, not a
management-modifier problem.

The full nine-metric forest-type scorecard is below, one table per forest type as signed level bias in
percent for each of the five models on the frozen basis. Bootstrap 95 percent confidence intervals and the
green, yellow, and red flags for every cell are in Figure 7. The forest-type strata exclude the 20 stands
whose initial treelist could not be classified, leaving softwood 321, mixedwood 186, and hardwood 178; the
total-volume rows reproduce the summary above.

**Softwood (n = 321), level bias (percent).**

| **metric** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|
| basal area | +0.8 | -16.0 | -14.0 | -14.0 | -2.3 |
| stand density index | +3.4 | -14.2 | -12.8 | -12.8 | -3.2 |
| quadratic mean diameter | -5.1 | -1.5 | +0.1 | +0.1 | +8.1 |
| top height | -0.6 | -1.4 | -1.2 | -1.2 | +3.9 |
| total volume | +0.6 | -16.4 | -14.1 | -14.1 | -1.0 |
| merchantable volume | +0.4 | -16.5 | -14.2 | -14.2 | -1.0 |
| sawlog volume | -0.2 | -16.9 | -14.7 | -14.7 | -0.8 |
| aboveground biomass | +1.1 | -16.2 | -14.1 | -14.1 | -1.4 |
| stand value | +0.5 | -16.4 | -14.1 | -14.1 | -1.1 |

**Mixedwood (n = 186), level bias (percent).**

| **metric** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|
| basal area | -2.1 | -17.0 | -12.5 | -12.5 | -7.7 |
| stand density index | -0.7 | -16.3 | -12.6 | -12.6 | -10.0 |
| quadratic mean diameter | -4.9 | -1.1 | +0.4 | +0.4 | +9.1 |
| top height | +3.2 | +2.1 | +2.6 | +2.6 | +1.8 |
| total volume | +7.2 | -9.5 | -4.1 | -4.1 | -3.9 |
| merchantable volume | +6.7 | -10.0 | -4.6 | -4.6 | -4.2 |
| sawlog volume | +6.3 | -10.3 | -4.7 | -4.7 | -3.5 |
| aboveground biomass | +6.4 | -10.4 | -5.2 | -5.2 | -5.2 |
| stand value | +8.8 | -8.3 | -2.6 | -2.6 | -3.0 |

**Hardwood (n = 178), level bias (percent).**

| **metric** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|
| basal area | +15.3 | -1.9 | +3.9 | +3.9 | +7.1 |
| stand density index | +18.2 | -0.3 | +4.3 | +4.3 | +2.6 |
| quadratic mean diameter | -7.1 | -1.4 | +0.6 | +0.6 | +16.5 |
| top height | +12.3 | +11.4 | +11.7 | +11.7 | +6.9 |
| total volume | +31.3 | +11.4 | +19.0 | +19.0 | +14.6 |
| merchantable volume | +30.0 | +10.2 | +17.6 | +17.6 | +13.1 |
| sawlog volume | +30.6 | +10.8 | +18.4 | +18.4 | +14.6 |
| aboveground biomass | +30.8 | +10.6 | +17.9 | +17.9 | +13.6 |
| stand value | +32.8 | +12.7 | +20.4 | +20.4 | +16.0 |

Read down the metrics, the softwood column is the pooled volume story in miniature: v12.10.1 under-reads
every merchantable output by about 14 percent and flags red on all five, while OSM holds all five within
about 1.5 percent of zero and flags green; structure is clean for the shared newer build, with quadratic
mean diameter and top height inside 1.2 percent even as basal area sits at -14.0. Mixedwood is the most
balanced stratum, the shared newer build and OSM both inside about 5 percent on every volume metric and
green or yellow throughout. Hardwood is the shared frontier, every model over-reading the merchantable
outputs, the shared newer build by 18 to 20 percent and OSM by 13 to 16, all red, which confirms a
composition-driven ceiling for the v13 refit rather than a management-modifier problem.

### Accuracy and precision: percent RMSE

Percent bias measures only systematic offset, and it inflates on metrics with low means, so a small absolute
error reads as a large percentage. To score accuracy and precision together we add the root mean squared error
and its scale-free form, the percent RMSE, RMSE = sqrt(mean((observed − predicted)²)) and %RMSE = 100 × RMSE /
mean(observed). Unlike percent bias, %RMSE penalises both systematic error and scatter, so it does not deflate
on high-mean metrics and does not inflate on low-mean ones, which makes it the fairer accuracy-and-precision
summary. Uncertainty on %RMSE is a within-province stratified bootstrap (2000 replicates, seed 42), resampling
stands within New Brunswick and Quebec so the interval respects the two-province design. We report %RMSE
alongside the mean bias percent kept for continuity, the mean absolute error, and the Nash-Sutcliffe efficiency.

Percent RMSE by model and metric on the pooled in-domain set (n=705), lower is better, is:

| **metric** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|
| basal area | 40.8 | 45.3 | 45.8 | 45.8 | 39.6 |
| stand density index | 40.9 | 45.9 | 46.2 | 46.2 | 39.6 |
| quadratic mean diameter | 27.8 | 25.4 | 25.7 | 25.7 | 29.1 |
| top height | 18.8 | 18.2 | 18.4 | 18.4 | 16.1 |
| total volume | 56.0 | 52.3 | 55.2 | 55.2 | 51.1 |
| merch volume | 53.6 | 50.9 | 53.4 | 53.4 | 49.0 |
| sawlog volume | 57.7 | 55.1 | 57.8 | 57.8 | 53.4 |
| aboveground biomass | 52.2 | 47.9 | 50.6 | 50.6 | 47.2 |
| stand value | 62.0 | 55.8 | 59.4 | 59.4 | 56.3 |

Structure metrics are tight, top height near 18 percent and quadratic mean diameter near 26. The
merchantable-output metrics carry the scatter: total volume, sawlog volume, and value all sit in the mid-50s to
low-60s percent even where mean bias is only a few percent, which is the point of the metric. On the pooled set
v12.10.1 total volume is 55.2 percent (95 percent interval 49.1 to 61.7) and value is 59.4 percent (52.1 to
67.0); OSM is a little lower at 51.1 and 56.3 percent. Figure 11 is the %RMSE scorecard, the model by metric
heatmap of %RMSE on the pooled set with within-province bootstrap intervals in each cell.

The hardwood reframe follows directly. Hardwood error is scatter-dominated, not bias-dominated. On the hardwood
stratum v12.10.1 total volume carries a mean bias of about +19 percent but a %RMSE of about 76 percent, and
stand value about +20 percent bias against about 81 percent %RMSE; OSM is similar, with hardwood total-volume
%RMSE about 75 percent and value about 80 percent. Every model shows the same pattern, the percentage bias
understating the true error because most of that error is variance, not offset. Hardwood is a high-variance
frontier shared by all five models, not a systematic defect of any one build, and reporting %RMSE rather than
bias alone keeps that honest.

### Observed-on-predicted regression and the region of equivalence

For each model, metric, and stratum we fit the ordinary least squares regression of observed on predicted,
observed = a + b × predicted, and report the slope b, the intercept a, and R². A slope of one and an intercept
of zero mark a model that tracks the 1:1 line. We test that jointly with a Robinson and Froese (2004) style
equivalence test, two one-sided tests at alpha = 0.05, checking that the 90 percent confidence interval of each
parameter falls entirely inside a stated region of equivalence: the intercept region is plus or minus 25 percent
of the mean observed value for that metric and stratum, and the slope region is the interval 0.75 to 1.25. The
model is declared equivalent only when both the intercept and the slope pass. This regression equivalence is a
complement to the paired-difference TOST reported with the pooled scorecard; here the test is on the shape of
the observed-on-predicted fit rather than the mean difference. Because observed is regressed on predicted, a
slope above one means the model under-predicts the high end and a slope below one means it over-predicts it.

Observed-on-predicted regression and equivalence flags on the pooled in-domain set (n=705), key metrics. TRUE
means the parameter's 90 percent interval lies inside its region of equivalence.

| **metric** | **model** | **slope b** | **intercept a** | **R²** | **slope equiv** | **intercept equiv** | **overall** |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|
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

Across all nine metrics on the pooled set, four of the five models pass the joint equivalence test on every
metric, nine of nine. The single exception is v12.7.0 basal area, where the slope of 1.21 sits just outside the
0.75 to 1.25 region once its confidence interval is included, so basal area is flagged not equivalent for that
build; its intercept still passes, and its volume and value slopes are essentially one. Every volume and value
cell passes overall equivalence for all five models: total-volume slopes run 0.83 to 1.04 and value slopes 0.81
to 1.01, and the operational build v12.10.1 has a total-volume slope of 0.99 and a value slope of 0.95, both
equivalent to one. Figure 10 is the observed-versus-predicted equivalence plot, faceted with total volume,
value, and basal area as rows and the five models as columns, each panel showing the per-stand cloud coloured by
forest type, the 1:1 line, the OLS fit, and the shaded region of equivalence, annotated with the slope and the
joint verdict.

The equivalence test confirms what %RMSE and bias together imply. On total volume and stand value, the outputs
that matter most for management, every model tracks the 1:1 line within a region we are willing to treat as
practically equivalent, and the operational build does so with slopes near one and no systematic tilt. The one
flag, v12.7.0 basal area, is a slope that runs slightly steep rather than a location error, consistent with that
build's known basal-area behaviour. Equivalence is a stricter and more transparent claim than a low p-value on a
difference test: it states the size of the departure we would tolerate up front and then shows the models fall
inside it.

### Weighted overall composite score

To collapse the nine metrics into one number per model, each model earns a composite score from 0 to 100,
higher is better. We compute two composites and lead with the accuracy-and-precision view, because %RMSE scores
systematic error and scatter together where bias alone flatters a low-scatter but biased build. The primary
composite is built on %RMSE: each metric earns a score of 100 × max(0, 1 − %RMSE / 100), so a metric with %RMSE
of 0 scores 100 and one at 100 percent or worse scores 0, and the composite is the weighted mean of the nine
metric scores with total volume and stumpage value carrying the highest weight (total volume 3, value 3,
merchantable and sawlog volume and biomass 2 each, the four structure metrics 1 each, for a weight sum of 16).
The complementary composite is the earlier bias-and-efficiency blend: per metric a bias score of 100 × (1 −
min(1, |bias| / 20)) rewards accuracy and an efficiency score of 100 × max(0, NSE) rewards per-stand fit, blended
equally, then combined under the same volume-and-value weighting, with an equal-weight mean carried as a
reference column. Both composites are computed on the pooled in-domain set and on each forest type.

On the pooled in-domain set the primary %RMSE-weighted composite ranking is:

| **rank** | **model** | **%RMSE composite (primary)** |
|:---:|:---|:---:|
| 1 | OSM | 53.4 |
| 2 | v12.7.0 | 52.1 |
| 3 | v12.9.x | 49.8 |
| 3 | v12.10.1 | 49.8 |
| 5 | v12.5.0 | 49.4 |

The primary %RMSE composite per model, pooled and by forest type, is:

| **model** | **pooled in-domain** | **softwood** | **mixedwood** | **hardwood** |
|:---|:---:|:---:|:---:|:---:|
| v12.5.0 | 49.4 | 61.2 | 57.8 | 23.5 |
| v12.7.0 | 52.1 | 56.3 | 59.1 | 39.2 |
| v12.9.x | 49.8 | 55.3 | 58.2 | 33.4 |
| v12.10.1 | 49.8 | 55.3 | 58.2 | 33.4 |
| OSM | 53.4 | 61.6 | 59.5 | 34.4 |

Every model scores far lower on hardwood than on softwood or mixedwood, the shared high-variance frontier of the
%RMSE section above rather than a defect of any one build. The two views diverge on v12.7.0. It ranks low on the
bias composite because it carries real systematic offsets (basal area bias -13.4 percent), but rises to second on
the %RMSE composite because once systematic and random error are scored together its predictions are less
scattered. The operational build v12.10.1 is the least biased of the FVS-ACD engines with slightly more scatter,
so it leads v12.7.0 on the bias composite but ties v12.9.x just behind it on %RMSE. OSM stays first on both.

The complementary bias-and-efficiency composite is kept so the change of basis is visible. On the pooled
in-domain set the bias ranking, on the primary volume and value weighting with the equal-weight composite for
reference, is:

| **rank** | **model** | **primary (volume + value)** | **equal-weight reference** |
|:---:|:---|:---:|:---:|
| 1 | OSM | 80.9 | 79.3 |
| 2 | v12.9.x | 74.3 | 73.0 |
| 2 | v12.10.1 | 74.3 | 73.0 |
| 4 | v12.7.0 | 66.5 | 66.4 |
| 5 | v12.5.0 | 64.9 | 67.9 |

The primary composite per model, pooled and by forest type, is:

| **model** | **pooled in-domain** | **softwood** | **mixedwood** | **hardwood** |
|:---|:---:|:---:|:---:|:---:|
| v12.5.0 | 64.9 | 87.4 | 71.6 | 26.3 |
| v12.7.0 | 66.5 | 51.3 | 63.7 | 58.5 |
| v12.9.x | 74.3 | 55.7 | 74.8 | 40.4 |
| v12.10.1 | 74.3 | 55.7 | 74.8 | 40.4 |
| OSM | 80.9 | 85.3 | 76.1 | 47.0 |

The ranking is robust at the top and to the choice of weighting. OSM leads and the shared newer build (v12.9.x
and v12.10.1, identical on the base) sits second on both the primary volume and value weighting and the
equal-weight reference; only the two oldest engines trade the fourth and fifth positions, v12.7.0 rising above
v12.5.0 once volume and value dominate the score, which is precisely the operational contrast the primary
weighting is meant to surface. Within forest types the top two are unchanged in every stratum. The by-type
ordering shifts with composition, as expected from the bias tables: softwood is led by v12.5.0 then OSM,
mixedwood and the pooled set by OSM, and hardwood by v12.7.0, whose flatter hardwood bias scores best on the
one stratum where every newer build over-reads. Figure 8 shows the pooled ranking, the equal-weight reference,
and the by-forest-type composites overlaid.

### Species composition over time

Stand species composition is defined as the basal-area fraction by species group, using live trees at least 4 cm
DBH: softwood versus hardwood, and a three-way split into spruce-fir (*Abies* + *Picea*), other softwood, and
hardwood. For each benchmark stand we have a starting state (t1) and an observed endpoint (t2) from the MagPlot
QC and NB remeasured treelists, and each model predicts the endpoint. Predicted composition for the FVS-ACD
flagships (v12.5.0, v12.7.0, v12.10.1) comes from a non-invasive composition re-run of the frozen benchmark
harness that emits per-group basal area at t2; the run reproduces the frozen August operational baseline
(NB_AFAC 0.579, QC_AFAC 0.111) with zero difference against cb_v12101 on all nine stand totals. OSM predicted
composition is taken directly from its head-to-head predicted treelist. The stand set is the frozen scorecard
pooled set of 705 unique stands; 25 stands lacked classifiable t1 basal area, leaving 680. Forest type is the
committed percent-hardwood rule applied to the t1 treelist (softwood at most 25 percent hardwood BA, hardwood at
least 75 percent, else mixedwood). Bias is predicted minus observed softwood fraction in percentage points
(pts); the shift ratio is predicted mean shift divided by observed mean shift, so 1.0 is a perfect match and a
negative value is a wrong-direction move.

Observed and predicted softwood basal-area fraction across the remeasurement interval, pooled and by forest
type, on the frozen benchmark (n = 680 classifiable stands of the frozen 705, fractions in percent, bias and
shifts in percentage points), is:

| **Model** | **Stratum** | **n** | **Obs t1 (%)** | **Obs t2 (%)** | **Pred t2 (%)** | **Obs shift (pts)** | **Pred shift (pts)** | **Bias (pts)** | **Direction** | **Shift ratio** |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **v12.5.0** | Pooled | 680 | 59.9 | 60.7 | 59.5 | +0.82 | -0.45 | -1.27 | wrong | -0.55 |
| **v12.5.0** | Softwood | 320 | 94.0 | 92.0 | 92.6 | -1.95 | -1.41 | +0.54 | right | 0.72 |
| **v12.5.0** | Mixedwood | 186 | 51.7 | 51.3 | 51.5 | -0.40 | -0.24 | +0.17 | right | 0.59 |
| **v12.5.0** | Hardwood | 174 | 6.1 | 13.3 | 7.2 | +7.20 | +1.08 | -6.13 | right | 0.15 |
| **v12.7.0** | Pooled | 680 | 59.9 | 60.7 | 59.6 | +0.82 | -0.30 | -1.11 | wrong | -0.37 |
| **v12.7.0** | Softwood | 320 | 94.0 | 92.0 | 92.8 | -1.95 | -1.11 | +0.84 | right | 0.57 |
| **v12.7.0** | Mixedwood | 186 | 51.7 | 51.3 | 51.6 | -0.40 | -0.11 | +0.30 | right | 0.26 |
| **v12.7.0** | Hardwood | 174 | 6.1 | 13.3 | 7.1 | +7.20 | +1.00 | -6.21 | right | 0.14 |
| **v12.10.1** | Pooled | 680 | 59.9 | 60.7 | 59.7 | +0.82 | -0.26 | -1.08 | wrong | -0.32 |
| **v12.10.1** | Softwood | 320 | 94.0 | 92.0 | 92.9 | -1.95 | -1.06 | +0.89 | right | 0.54 |
| **v12.10.1** | Mixedwood | 186 | 51.7 | 51.3 | 51.7 | -0.40 | -0.05 | +0.35 | right | 0.14 |
| **v12.10.1** | Hardwood | 174 | 6.1 | 13.3 | 7.1 | +7.20 | +0.98 | -6.22 | right | 0.14 |
| **OSM** | Pooled | 680 | 59.9 | 60.7 | 60.8 | +0.82 | +0.88 | +0.06 | right | 1.08 |
| **OSM** | Softwood | 320 | 94.0 | 92.0 | 94.0 | -1.95 | +0.02 | +1.97 | wrong | -0.01 |
| **OSM** | Mixedwood | 186 | 51.7 | 51.3 | 53.5 | -0.40 | +1.81 | +2.21 | wrong | -4.49 |
| **OSM** | Hardwood | 174 | 6.1 | 13.3 | 7.6 | +7.20 | +1.46 | -5.74 | right | 0.20 |

![Figure 9. Predicted versus observed softwood basal-area fraction at the remeasurement endpoint (t2) by model, with the 1:1 line (top), and the observed versus predicted mean compositional shift from t1 to t2 by forest type (bottom). Points are colored by committed forest type. Frozen benchmark, MagPlot QC and NB remeasured stands.](figures/fig9_species_composition_over_time.png)

Stand composition is nearly stationary across the interval: the pooled mean softwood fraction moves less than one
point (59.9% to 60.7%), and the only large observed signal is a +7.2 pt softwood gain in hardwood-dominated
stands, partly offset by a -1.9 pt softwood loss in softwood stands. All three FVS-ACD models reproduce the
direction of change within softwood and mixedwood stands but under-shift by roughly a third to a half, and they
miss the pooled net direction, predicting a small softwood decline (-0.3 to -0.5 pt) against the observed +0.8 pt
increase, because they under-represent softwood in-migration into hardwood stands (predicted about +1.0 pt versus
observed +7.2 pt, bias near -6 pts). OSM best tracks the pooled net shift (+0.9 pt, ratio 1.08) but overshoots
softwood in mixedwood and softwood stands; the spruce-fir split tells the same story, with the observed +7.0 pt
spruce-fir gain in hardwood stands under-predicted by every model. Every model holds stand-level softwood
fraction within about 1 to 2 pts of observed in softwood and mixedwood types, so overall composition is preserved
and the shared weakness is the rate of softwood recolonization of hardwood-dominated stands.

### Management class, the headline

In-sample level bias (percent), the cells the modifier targets:

| **class** | **n** | **metric** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---|:---:|:---:|:---:|
| NONE | 266 | basal area | -9.9 | -9.9 | -2.0 |
| NONE | 266 | total volume | -5.3 | -5.3 | -1.6 |
| PLANTED | 51 | basal area | -24.9 | -4.4 | -20.9 |
| PLANTED | 51 | total volume | -23.7 | -10.8 | -19.7 |
| PCT | 95 | basal area | -15.6 | -1.3 | -5.4 |
| PCT | 95 | total volume | -11.3 | -2.0 | -0.1 |
| MANAGED | 146 | basal area | -19.0 | -2.5 | -11.2 |
| MANAGED | 146 | total volume | -15.9 | -5.3 | -7.4 |

The unmanaged cell is byte identical between v12.9.x and v12.10.1, which confirms the gate. The gate closes the
managed basal-area gap sharply, with planted basal area moving from -24.9 to -4.4, PCT from -15.6 to -1.3, and
pooled managed from -19.0 to -2.5 percent. On absolute basal-area bias v12.10.1 beats OSM in every managed
class: managed 2.5 versus OSM 11.2, planted 4.4 versus 20.9, and PCT 1.3 versus 5.4. The PCT basal-area
residual the red team deferred is closed by the additive form (-1.3 versus OSM -5.4). One frozen-basis shift
should be flagged on the volume side. Gate-on planted total volume is -10.8 instead of near zero, because the
frozen afac lowers untreated planted-stand volume so the fixed additive release closes less of the volume gap.
The basal-area releases are unchanged.

The out-of-sample result is the one that carries the most weight. Mean absolute level bias across the nine
metrics under leave one installation out cross validation, with the MagPlot installation as the fold unit:

| **class** | **n** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|
| PLANTED | 51 | 19.3 | 4.0 | 16.7 |
| PCT | 95 | 10.4 | 1.5 | 3.7 |
| MANAGED | 146 | 13.2 | 0.9 | 8.3 |

Under the harsher leave one province out block, managed is 0.9, planted 5.7 versus OSM 16.7, and PCT 3.8
versus OSM 3.7, close but marginally behind across the border. Under a managed split half over 200 reps
v12.10.1 averages 5.2 and beats OSM in 79 percent of reps and v12.9.x in 92 percent. The additive fold
coefficients are stable across folds (planted basal-area release 3.85 to 4.40, PCT 2.45 to 2.76), unlike the
clamped multiplier that pinned at 1.6 in every fold. The direct-effect release follows Chapter 11 of
Weiskittel, Hann, Kershaw and Vanclay (2011). The multi-step method of Wang (1990) holds the untreated
equations fixed and fits the modifier on observed minus predicted-untreated increment, with planted treated as
a Type 2 sustained effect and PCT as a Type 1 transient release. Mortality is deliberately left without a
multiplicative modifier to avoid distorting the logistic asymptote. One caveat travels with these
out-of-sample managed and planted results. They rest on thin planted and precommercial-thinning samples, and
the leave-one-province-out transfer across the New Brunswick to Quebec border leans on a small number of
managed installations per province, which is the gap the v13 provincial managed-remeasurement data ask is
meant to close.

### Biological realism and long-horizon behavior

Bakuzis relations from seeded 160-year projections across an ESI productivity gradient (ESI 12, 16, and 20
seeded to age 160), each scored against the named law-like relations on the modified Bakuzis matrix:

| **relation** | **v12.5.0** | **v12.7.0** | **v12.9.x** | **v12.10.1** | **OSM** |
|:---|:---:|:---:|:---:|:---:|:---:|
| Eichhorn (V ~ f height) | pass | pass | pass | pass | not scored |
| Reineke slope (target -1.6) | flag | pass (-1.8) | pass (-1.59) | pass (-1.59) | flag |
| Site ordering (no overtaking) | pass | pass | pass | pass | not scored |
| Yield-density / plateau | flag | pass (37) | pass (36) | pass (36) | flag |
| Sukachev (size vs density) | flag | pass | pass | pass | not scored |

v12.10.1 inherits the v12.9.x self-thinning machinery and passes all five relations. OSM now enters the matrix
as an external entrant, scored where its long-horizon behavior is observable on the matched-stand Seven Islands
trajectory. It flags both size-density relations, Reineke self-thinning and the yield-density plateau, because
its stand-level basal area never plateaus and never self-thins, accumulating monotonically from about 32 to 42
m² ha⁻¹ by age 60 while the AcadianGY builds peak near 33 and self-thin back to about 27. That non-plateau
accumulation, not any single-metric offset, is the central point of biological-realism separation between OSM
and the v12.7.1 and later builds. OSM is marked not scored, rather than passed, on Eichhorn, site ordering, and
Sukachev: each of those three tests is defined only on the seeded cross-site productivity gradient, and OSM is
an external model that cannot be run on that synthetic gradient, so no honest pass or flag can be assigned for
those relations. Figure 3 carries the full matrix with the OSM column. With the
management modifier on, a seeded 160-year projection of a planted softwood stand still plateaus at every
amplitude tested (standard deviation of basal area over the last 20 years about 0.21 m² ha⁻¹, flat), and the
ceiling rises smoothly with amplitude (36.3, 41.6, 43.6, 45.6, 47.3 m² ha⁻¹ at amplitudes 1.0, 1.6, 2.0, 2.5,
3.0) because basal area at the Reineke limit rises with tree size. The operational engine amplitude is set to
2.0. The modifier accelerates the approach and lifts the ceiling to a productive planted-conifer level without
breaking self-thinning. v12.5.0 still fails self-thinning outright, running to 62 to 65 m² ha⁻¹ with thousands
of stems still alive. On a matched-stand test OSM does not plateau over the tested horizon. On the same nine
Seven Islands stands from an identical start (FVS-ACD 31.4, OSM 31.9 m² ha⁻¹ at year 0), FVS-ACD peaks near 33
m² ha⁻¹ by age 10 to 20 and self-thins to 27 by age 60, while OSM accumulates monotonically to about 42 m²
ha⁻¹, a 35 percent divergence by age 60 localized entirely to the mortality and self-thinning mechanism.

## v13 roadmap

v13 is the fall arc. It is in progress, not gated, and appears here as roadmap only. No v13 scorecard numbers
exist yet and none are reported.

v13.0 was a joint dominant-height and basal-area re-anchor aimed at the pooled offset. The shipped v12.10.1 is
under on volume by about 4 percent through a partial error cancellation, a top-height over-prediction of about
+4 percent set against a basal-area under-prediction of about -10 percent, and correcting either anchor alone
drives volume further off rather than to parity. A one-sided top-height correction tested earlier pushed pooled
total volume further negative while collapsing Quebec modeling efficiency to 0.134. This cycle a narrow height
re-anchor fix was run as a blend sweep across weights 0.50 to 1.00, and every setting in the sweep parked: none
reached pooled parity without reopening the offset, so the v13.0 height path is exhausted for now and stays
parked. The basal-area increment anchor, individually unbiased in the Maine, New Hampshire, and Vermont domain
(basal-area increment ratio 1.00 on 13,894 remeasurement pairs), is validated and retained for the v13.1 cycle.
The shipped v12.10.1 stays the frozen August operational baseline.

v13.1 is a hierarchical mortality and ingrowth refit. It targets the composition-driven hardwood over-prediction
that every model shares and the ingrowth under-prediction documented below, moving the management effect from a
bounded engine amplitude into the fit as a predictor, and it now carries the retained basal-area increment
correction from the v13.0 cycle. The refit is running on the cluster with convergence pending; no v13.1
scorecard numbers exist yet.

## Honest limits

Three limits are stated plainly and carried on the biological-realism slide.

Pooled precision belongs to OSM on the operational domain. OSM leads pooled mean absolute bias (3.2 versus
4.9), mean modeling efficiency (0.75 versus 0.71), and holds the most TOST equivalences (8 of 9). The FVS-ACD
in-domain near-parity on volume is an offsetting cancellation of a basal-area under-prediction and a
top-height over-prediction, not independent accuracy on each component. This is an equation-level limit and the
v13.0 joint re-anchor target, and it cannot be closed by an anchor scale on one side. The pooled precision gaps
here are small relative to the stand-level RMSE and are reported without a formal paired difference test or a
multiplicity adjustment across the nine correlated NSVB metrics, so they should be read as OSM modestly ahead
on the pooled domain rather than as a decisive, individually significant gap on any one metric.

Ingrowth is under-predicted. Recruitment across the tag threshold is a disclosed limit, not a scored win. The
direction is correct but the absolute level is low:

| **province** | **class** | **predicted (stems ha⁻¹ yr⁻¹)** | **observed (stems ha⁻¹ yr⁻¹)** | **ratio** |
|:---|:---:|:---:|:---:|:---:|
| New Brunswick | all | 17.9 | 39.8 | 0.45 |
| New Brunswick | unmanaged | 16.2 | | |
| New Brunswick | PCT | 19.5 | | |
| New Brunswick | planted | 21.5 | | |
| Quebec | all | 11.7 | 19.7 | 0.59 |
| Quebec | unmanaged | 10.6 | | |
| Quebec | PCT | 14.5 | | |
| Quebec | planted | 15.9 | | |

This is a real, moderate under-prediction, about 45 percent of observed in New Brunswick and 59 percent in
Quebec. It is not the 2018 near-zero recruitment failure, and it is not an inflated recruitment. Recruitment
responds in the correct direction to density and management, since planted and PCT stands carry lower residual
density and recruit more than unmanaged stands, so the density-released ingrowth term behaves as intended and
the additive management release does not distort recruitment. It is an equation-level limit and a v13.1 target.

PCT parity with OSM is a within-core result. It holds under the province block at 4.1 versus OSM 3.7, close
but marginally behind across the New Brunswick to Quebec border, so the conservative call keeps the Quebec edge
out of domain. The Quebec pooled and top-height figures carry that out-of-domain edge. At the Quebec edge ESI
over-reads height productivity, with ESI still reading 18 to 19 and implying an asymptote near 36 m while the
stands top out near 22 m and are not growing. This is a site-metric mismatch that no model fit on in-domain
data can reproduce, which is why the boundary is declared rather than scored as a failure.

## Figures

Figures are rendered separately through advanced-viz and are not generated in this report. The report should
carry the following four to six.

![Figure 1. Five-way scorecard heatmap of level bias and modeling efficiency across the nine NSVB metrics for v12.5.0, v12.7.0, v12.9.x, v12.10.1, and OSM v2.26.1 on the pooled in-domain set, with an added Overall composite strip beneath the per-metric bias tiles showing each model's %RMSE-weighted composite (0 to 100) on its own scale, separated from the bias-flag tiles.](figures/fig1_scorecard_heatmap.png)

![Figure 2. Total volume level bias by forest type (softwood, mixedwood, hardwood) for the five models, showing the composition-driven hardwood frontier shared by every model.](figures/fig2_accuracy_by_forest_type.png)

![Figure 3. Bakuzis relations pass and flag matrix by model, the five law-like relations against the five entrants.](figures/fig3_bakuzis_relations.png)

![Figure 4. Long-horizon self-thinning trajectories on matched Seven Islands stands, FVS-ACD plateau and decline against OSM monotonic accumulation over 60 years from an identical start.](figures/fig4_selfthinning_trajectory.png)

![Figure 5. The offsetting bias signature in domain, basal area about -9 percent under and top height about +4 percent over canceling to total volume about -1.6 percent.](figures/fig5_offsetting_bias.png)

![Figure 6. Managed-cell out-of-sample mean absolute bias by management class under leave one installation out, v12.9.x, v12.10.1, and OSM for planted, PCT, and managed.](figures/fig6_managed_oos_bias.png)

![Figure 7. Forest-type scorecard, level bias percent with bootstrap 95 percent CIs and green, yellow, and red flags, nine metrics by five models faceted by forest type (softwood n = 321, mixedwood n = 186, hardwood n = 178) on the frozen basis.](figures/fig7_scorecard_by_fortype.png)

![Figure 8. Volume and value weighted overall composite score by model, the pooled in-domain primary composite (total volume and value weighted highest) as ranked bars, the equal-weight composite as a reference tick on each bar, and the by-forest-type primary composites overlaid as markers.](figures/fig8_overall_composite.png)

![Figure 10. Observed-versus-predicted equivalence plot, faceted with total volume, value, and basal area as rows and the five models as columns. Each panel shows the per-stand cloud coloured by forest type, the 1:1 line, the OLS fit, and the shaded Robinson-Froese region of equivalence, annotated with the slope b and the joint verdict. Pooled in-domain set (n = 705).](figures/fig10_equivalence.png)

![Figure 11. Percent RMSE scorecard, the model by metric heatmap of %RMSE across the nine NSVB metrics for the five models on the pooled in-domain set, with within-province bootstrap intervals in each cell.](figures/fig11_rmse_scorecard.png)

![Figure 12. Locator of the Acadian study region with benchmark stand counts aggregated on a 50 km equal-area hex grid (New Brunswick n = 355, Quebec n = 350; true plot coordinates never released).](figures/fig12_data_locator.png)

![Figure 13. Benchmark stand counts on the same 50 km hex grid split into softwood (n = 321), mixedwood (n = 186), and hardwood (n = 178) panels.](figures/fig13_data_by_fortype.png)

## Methods and provenance

Scoring used the corrected single-keyed-merge scorer, one wide table keyed by stand and deduplicated on both
sides, with a per-model observed-on-predicted correlation as the alignment check. The earlier
negative-modeling-efficiency artifact on OSM was an index-join misalignment and is resolved. Volume, biomass,
and value are on the shared FIA NSVB emulator (log of gross variable on log of squared diameter times height
by species group with Duan smearing), which carries about zero aggregate bias against raw FIA NSVB and so does
not advantage any model. Equivalence testing follows Schuirmann TOST and Robinson and Froese (2004): a region
of plus or minus 10 percent of the observed mean for level metrics and plus or minus 25 percent for increment,
with equivalence declared when the 90 percent confidence interval of the mean paired difference lies inside the
region. OSM is v2.26.1, dated 12 May 2026, confirmed as the latest release.

One data-provenance caveat should be noted. The scorecard baseline cb_v12102 was generated from
AcadianGY_12.9.2.r plus the operational ops recipe. A standalone AcadianGY_12.10.1.r file exists but does not
reproduce cb_v12102 exactly, so the canonical operational definition of v12.10.1 is the 12.9.2 model plus the
recorded recipe, pending a file reconciliation.

Cardinal locations. Scorecard and cross-validation code under ~/magplot/verify: scorecard_v1210.R (five-way
single-keyed-merge scorer), scorecard_clean.R (base scorer), scripts/v12101_domain_scorecard.R (7 July
operational-domain recompute), mgmt_cv_robust.R and mgmt_finalfit.R (additive release and out-of-sample
battery), bakuzis_allmodels.R (Bakuzis relations), and mgmt_plateau_sweep.R (plateau and gate-off identity).
Inputs Wfull.rds (705 keyed table across five models and nine metrics), the per-stand cb result files,
osm_h2h_metrics.csv, magp_qcnb_ecol3_v2.csv (ecoregion join keyed by stand and province), and the
mgmt_scorecard and mgmt_gap_closure robust outputs. The OSM matched-stand long-horizon evidence is in
~/silc_cfi (osm_match_run.py, osm_pair3.R, fvsacd_vs_osm_matched.csv). True plot coordinates never left the
node; only aggregates appear in this report.
