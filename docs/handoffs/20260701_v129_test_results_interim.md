# v12.9 test, interim result: important correction found before building anything into code

*1 July 2026. Ran the test. Found something that changes the plan before writing AcadianGY_12.9.0.r.*

## What was built and run

Sourced AcadianGY_12.7.1.r directly and called its own internal calc_sdi_max() (the published Weiskittel
and Kuehne 2019 equation, already a function of percent hardwood, mean specific gravity, DBH range,
species diversity, elevation, and CSI/ESI) against three data sources: 2555 MagPlot NB+QC stands, 2599
recent Maine FIA stands, ESI v8 extracted at all of them (including a fresh extraction at the FIA plots,
job-run this session). Built 6 ESI spatial clusters (k-means on scaled ESI, lat, lon).

## Correction to the earlier framing

AcadianGY does NOT use a flat constant for max SDI. It already uses the published, composition- and
site-aware Weiskittel-Kuehne (2019) equation. The v12.8 and v12.9 write-ups both slightly overstated how
crude the current ceiling is; the real question is narrower: does an ESI-based spatial cluster factor
improve on this existing continuous equation.

## What the ESI clusters actually showed

The clustering worked mechanically, but ESI v8 coverage is the limiting factor, exactly as flagged in
earlier sessions: 4 of 6 clusters are 100 percent Quebec stands sitting at the ESI-missing default value
(14), because ESI v8 does not cover most of Quebec. Only two clusters have real ESI coverage (mostly Maine,
partly NB and QC). This means an "ESI cluster" factor, as built from currently available ESI, mostly
cannot distinguish NB from QC where it matters most, because QC has almost no real ESI to cluster on.

**Consequence**: jurisdiction (PROV) is a stronger, cleaner signal than the ESI cluster for the exact
problem we are trying to solve. Mean relative density under the CURRENT formula, full sample: NB 0.315, QC
0.442, ME 0.423 (n = 316, 2161, 2481). ESI cluster means range only 0.354 to 0.482, a much smaller spread
that does not cleanly separate NB from QC (both are mixed across several clusters). The composition and
site terms already in the Weiskittel-Kuehne equation are not fully absorbing the NB-vs-QC gap; a plain
region term would separate it better than the ESI cluster does right now.

## The direct self-thinning test came back inconclusive, and that is also informative

Testing whether relative density (observed SDI over the current model's max SDI) predicts observed density
loss over the remeasurement interval gave a near-zero to slightly negative correlation (MagPlot -0.10, FIA
recent +0.06), unlike the CONUS-scale test two messages ago (cor 0.33). Diagnosis: 44 percent of the
Acadian stands in this sample show a net density INCREASE over the interval (ingrowth outweighing
mortality on these short 4 to 15 year growing-stand remeasurements), which swamps the self-thinning signal
that a much larger, more diverse CONUS sample could average out. This is not a bug; it is a real property
of this smaller, growing-stand-heavy Acadian sample, and it means the "does RD predict self-thinning"
test needs denser, more mature stands specifically (or a longer horizon) to be informative here, not the
general remeasurement pairs used for the rest of the benchmark.

## Where this leaves v12.9

Two honest findings, not a validated fix yet:
1. A region-based (PROV) correction to the current SDImax formula has real, well-powered support (n in
   the thousands) and would directly target the known bidirectional bias.
2. An ESI-based spatial cluster, as currently buildable, is a weaker substitute for region given today's
   ESI coverage gaps in Quebec, and the direct self-thinning validation of any correction is underpowered
   on this dataset as designed.

Files (Cardinal): v129_build_dataset.R, v129_build_fia.R, v129_cluster_test.R (all in ~); results
magplot/verify/v129_magplot_sdimax.csv, silc_cfi/v129_fia_sdimax.csv, magplot/verify/v129_combined_sdimax.csv,
magplot/verify/v129_cluster_multipliers.csv. me_plot_esi8.csv (silc_cfi/) is the new recent-FIA ESI
extraction, reusable for other work.
