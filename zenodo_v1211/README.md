# FVS-ACD v12.11 benchmark

Six Acadian growth and yield model generations against OSM-ACD v2.26.1, with a measured-height coverage census.

Weiskittel, A. and Rice, B. Center for Research on Sustainable Forests, University of Maine.
CC BY 4.0. 4 August 2026.

## What this is

FVS-ACD is an independent Acadian growth and yield model for the mixed spruce, fir and northern hardwood forests
of the Acadian region, implemented in R as a variant of the Forest Vegetation Simulator and scored throughout on
the FIA National Scale Volume and Biomass (NSVB) system. This deposit is the benchmark: the report, the variant
overview GTR, every scorecard behind the reported numbers, and the scripts that produced them.

## What is compared, and on which population

Two populations are reported. They are kept separate throughout because they were never scored as one, and
merging them would imply a continuous series that does not exist.

| Population | n | Models scored | Where |
|---|---|---|---|
| Legacy in-domain (New Brunswick plus ESI-covered Quebec) | 705 | v12.5.0, v12.7.0, v12.7.1, v12.9.x, v12.10.1, OSM v2.26.1 | `scorecard_five_v1210_frozen.csv`, subset `POOLED_indomain` |
| Multi-source all-sites (Maine, New Brunswick, Quebec) | 5,754 | base v12.10.1, candidate v12.11, OSM v2.26.1 | `v1211_allsites_scorecard.csv` |
| Nova Scotia, independent province | 4,504 pairs | base, v12.11, OSM | `bench_ns_scorecard.csv`, `bench_ns_long_scorecard.csv` |

A caution on one file. `five_way_scorecard.csv` looks like the frozen in-domain scorecard and is not: it pools
all 733 New Brunswick and Quebec stands where the in-domain set restricts Quebec to the 350 ESI-covered stands.
On pooled total volume the two give OSM -1.5620% and +1.5610%, a sign difference at nearly identical magnitude
that reads as a transcription error and is not one. The predicted mean is 96.311 m³ ha⁻¹ in both; only the
observed denominator moves when the 28 non-ESI Quebec stands drop out. Quote the report against
`scorecard_five_v1210_frozen.csv`. The all-plots file is deposited for comparison only.

## Headline result

Neither model is a clean overall winner, and the report says so rather than smoothing it into one. v12.11 is the
more consistent performer, leading or tying the equal-per-source mean rank in every scenario tested and never
finishing clearly last on any metric. OSM-ACD v2.26.1 is the more decisive winner where it wins, leading the
strict common-cells pooled percent RMSE in every scenario and sweeping the managed-status and softwood cells.
v12.11's clear wins are its targeted strata: the managed CFRU CTRN and New Brunswick MagPlot sources, the
held-out mature Baxter reserve, Nova Scotia hardwood and mixedwood, the longest independent horizon, and
biological realism, where it passes four of five Bakuzis relations over 160 years against OSM's flags on
Eichhorn and site ordering. The frozen base is a clear third almost everywhere.

Every lever in v12.11 is gated and off by default. With the gates off the model reproduces the frozen v12.10.1
build bit for bit, at a maximum absolute difference of 0.000e+00 on diameter, height and expansion factor.

## Benchmark integrity, and why several conclusions are stated narrowly

The scoring harness applies one NSVB emulator to the observed and the predicted tree list, and it substitutes a
single hard-coded diameter-only height curve wherever a tree lacks a measured height. That substitution fires
almost entirely on the observed side, because the observed list is raw staged heights while the predicted list
is model output, so its error lands in the denominator of the bias ratio and does not cancel.

`height_coverage_census.csv` measures the exposure across all eleven staged sources. Coverage as share of t2
basal area runs from 4.02% at the Penobscot Experimental Forest and 18.45% at Baxter through 32.82% at the
combined New Brunswick and Quebec MagPlot extract and 51.99% at CFRU CTRN, up to effectively 100% at SILC and
the Maine FIA long and subplot sets. The managed sources carrying the central claim are therefore among the most
imputed. The curve runs a few percent tall on softwood and 12% to 33% short on hardwood on every source, so a
pooled check reports it as nearly unbiased while both species groups carry double-digit errors that offset.

Rescores under a fitted group curve are supplied as a validated sensitivity in `htfix_close_v2.csv` and
`htfix_rescore_multi.csv`, with the fitted curve validated against 463 measured Baxter stems in
`baxfix_curve_validation.csv`. Published numbers are retained unchanged. Two results matter for interpretation.
CTRN moves about 0.7 points on all three models with the ordering and margins unchanged, so the imputation did
not manufacture the managed win. QC MagPlot's disclosed +9.46% volume flag reads +0.41% under the fitted curve,
so most of that flag is imputation on the most hardwood-heavy source rather than the management gate
over-correcting. Across every source the pattern is the same: the height treatment moves the models together and
leaves their ordering intact, so the comparisons are durable even where the levels are not.

## Uncertainty

Uncertainty is shown where it exists and withheld where it does not, and the three panels of the graphical
abstract differ deliberately on this point.

Panel A carries the 95% intervals already present in `scorecard_five_v1210_frozen.csv`. They change the reading.
Only v12.5.0 (+9.25%, CI 5.18 to 13.51) and v12.7.0 (-8.28%, CI -11.63 to -4.82) have intervals excluding zero.
The three most recent generations and OSM all overlap zero and all overlap each other, so on pooled total volume
over the legacy in-domain set the apparent ordering among v12.7.1, v12.9.x, v12.10.1 and OSM is not
statistically separable. A star marks each interval that excludes zero.

Panel B carries 95% bootstrap intervals from `allsites_bias_ci.csv`, taken by resampling stands with
replacement, 4,000 replicates, seed 20260804. Bias is a ratio of means, so a normal approximation would be
wrong. Several readings tighten or loosen: CFRU CTRN separates cleanly, with v12.11 at -2.24% (CI -3.27 to
-1.21) not overlapping OSM at -4.81% (CI -5.98 to -3.62), while Baxter's small sample (n = 91) leaves base and
v12.11 both overlapping zero and NB MagPlot leaves v12.11 and OSM overlapping each other. SILC at n = 73 is the
widest cell in the benchmark. Read the intervals before quoting any single-source win.

Panel C has no error bars, and that is deliberate. The coverage census is a complete enumeration of the staged
tree lists, not a sample from a population, so it carries no sampling uncertainty. Drawing intervals there would
invent a quantity that does not exist.

## Files

`00_FVS-ACD_v1211_graphical_abstract.png` is the lead visual and the graphical abstract.

Documents: the benchmark report and the variant overview GTR, each as `.docx` and as markdown source.

Scorecards: the frozen five-way in-domain file, the all-sites and forest-group and maturity scorecards, the
master scorecard by determinant, the overall ranking, the Bakuzis biological-realism relations at both horizons,
and the two Nova Scotia scorecards.

Integrity: the coverage census, the two rescore tables, and the Baxter curve validation.

Uncertainty: `allsites_bias_ci.csv`, the bootstrap intervals behind panel B, produced by `boot_ci_allsites.R`.

Scripts: `height_coverage_census.R` produces the census and rescore tables; `build_graphical_abstract.py`
produces the lead figure. `data_dictionary.csv` describes the columns.

## Restrictions

Aggregates only. No FIA true plot coordinates appear in any file in this deposit, including code and figures;
they remain server-side on the analysis cluster and only fuzzed or aggregated products are released. The staged
per-tree benchmark lists are not deposited, because they carry per-plot records for proprietary provincial and
ownership inventories; the census and rescore tables derived from them are. J.D. Irving per-parcel outputs are
proprietary and are not included. A restricted-data sweep runs as a gate over every staged file before upload,
and its result is recorded in the runbook.

## Known limitations

The v12.11 candidate was not rescored on the legacy 705-stand in-domain set, so the generational trajectory in
panel A of the graphical abstract stops at v12.10.1. Section 7's remaining legacy tables were carried forward
from the v12.10.1 report and their intermediate files were never archived; the frozen in-domain file that
reproduces Table 7 is deposited, and the report states which tables are unreproducible. OSM has no score on two
of the eight Maine, New Brunswick and Quebec sources, which eases its footing in any pooled comparison that
includes them.

## Citation

Cite the concept DOI, which always resolves to the latest version. See `CITATION.cff`.
