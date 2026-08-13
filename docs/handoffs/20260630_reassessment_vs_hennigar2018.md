# Re-assessment against the 2018 Hennigar and Weiskittel FVS-ACD vs OSM-ACD benchmark

*30 June 2026. Triggered by re-reading NEFIS_OSMFVS_HennigarWeiskittel (ECANUSA, Fredericton,
19 Oct 2018). Question on the table: do we still need v12.7, and is our benchmark framed right?
Plaintext math, no em dashes.*

## What the 2018 benchmark established

Hennigar and Weiskittel (2018) compared FVS-ACD (v10.6, CSI-calibrated, equations fit 2010 to 2014)
against OSM-ACD (BGI-calibrated, equations fit 2015 to 2018, more managed-stand data). Both are the same
Acadian equation family; the difference is the background calibration and the site driver. The accuracy
test: mean bias and RMSE of predicted minus observed merchantable volume change (m3/ha/yr) from plot
establishment to last measurement, 10,550 plots, 454 stand types, scored by jurisdiction at plot and
stratum level, with IDW spatial bias maps and worst-cases by stand type.

Regional plot-level volume-increment bias (m3/ha/yr) and RMSE:

| jurisdiction | OSM bias | FVS bias | OSM RMSE | FVS RMSE |
|---|---|---|---|---|
| Maine | -0.53 | +0.49 | 4.1 | 5.0 |
| New Brunswick | -0.23 | -0.18 | 3.1 | 4.5 |
| Nova Scotia | +0.12 | +1.78 | 2.4 | 3.4 |

OSM-ACD RMSE was 20 to 60 percent lower than FVS-ACD across all jurisdictions. The stated cause:
FVS-ACD under-predicted both mortality and ingrowth; low mortality drove higher-than-observed volume
increment, worst in Nova Scotia and in mature spruce-fir.

The worst-case tables are bidirectional and are the key diagnostic:
- FVS severely UNDER-predicts young (5 to 15 yr) planted and PCT softwood in NB (ingrowth and early growth
  too low): JPSW plant -5.0, BFIR plant -4.8, BSPR plant -4.1, BFIR PCT -4.2 m3/ha/yr.
- FVS severely OVER-predicts mature-old softwood, especially mature spruce-fir (mortality too low):
  tolerant SWD >300 +7.1, fir 151-300 +7.0, red spruce 151-300 +6.6 m3/ha/yr.
- OSM's bias was relatively minor in most of these same cases.

Priority TO-DOs the authors listed in 2018: integrate explicit management-type modifiers and more managed
data; fix under-estimated large-tree mortality (noted as a simple fix); fix too-infrequent ingrowth
(quick fix); replace CSI with BGI and look beyond it; and improve site productivity mapping for
growth/stocking-limited sites (Atlantic coastal, high elevation, poorly drained), where BOTH models
over-predict increment.

## Verdict: v12.7 is still needed, and this is the production justification

v12.7 is the FVS-ACD modernization that closes the 2018 gap to OSM. It is, line for line, the 2018
priority TO-DO list executed:

| 2018 TO-DO | v12.7 response |
|---|---|
| Replace CSI, improve site mapping | ESI v8 (climate plus terrain), replaces legacy CSI |
| Large-tree mortality under-estimated | SDImax self-thinning + stand-mortality refit |
| Ingrowth too infrequent | expected-value ingrowth |
| Poor-site over-prediction | ESI v8 captures the coastal / high-elevation / poorly-drained gradient |

Without v12.7, FVS-ACD remains the 2018 also-ran: higher bias and 20 to 60 percent higher RMSE than OSM.
With it, the operational case is concrete and externally anchored: v12.7 closes the documented gap. The
2018 OSM numbers (ME -0.53, NB -0.23, NS +0.12 m3/ha/yr volume increment) are the explicit target the
v12.7 benchmark must approach or beat.

## What this changes in the current effort

1. Metric and method are vindicated. Our annual-increment, by-jurisdiction, plot-plus-stratum, IDW-map,
   worst-cases-by-stand-type framing is exactly Hennigar 2018. Rebuild the independent benchmark in that
   exact frame, scored on merchantable volume increment (m3/ha/yr), so results are directly comparable to
   the 2018 table and to OSM.

2. The over-prediction is the known FVS-ACD signature and is bidirectional. Our regional pool is mature-
   stand dominated, so we see only the over-prediction half (mortality deficit). The under-prediction half
   (young managed softwood, ingrowth deficit) is real and would worsen under a global mortality increase.
   This is the decisive argument for Bakuzis-anchored, stand-type-aware calibration over a blanket
   mortality bump. Calibrate the asymptote and self-thinning to the law-like relations; do not tune one
   global mortality knob to the mature-stand residual.

3. ESI v8 is on the 2018 critical path. The poor-site over-prediction hot spots we mapped are the same
   coastal / high-elevation / poorly-drained pattern from 2018; ESI v8 is the site-mapping advance the
   slide called for. Keep ESI v8 central, and report the spatial bias against the poor-site gradient.

## Benchmark target (the bar to clear)

v12.7 merchantable-volume-increment bias by jurisdiction should approach the 2018 OSM column, |bias|
under about 0.5 m3/ha/yr with competitive RMSE, and crucially should NOT re-open the young-managed-softwood
under-prediction. Report both tails (mature over, young under) by stand type, not just the regional mean.

## Next steps (revised to mirror 2018)

1. Independent benchmark on merch volume increment m3/ha/yr, by ME/NB/NS, plot and stratum, on MAGPlot
   (QC + NB), recent Maine FIA, and SILC long-horizon. IDW spatial bias maps and worst-cases by stand
   type x management x initial-volume class, in the Hennigar 2018 layout.
2. Bakuzis-anchored max-SDI and self-thinning calibration; validate that BOTH tails improve (mature over
   down, young under not worsened).
3. Hold Zenodo until the benchmark reproduces the 2018 frame and shows v12.7 at or near the OSM bar.

## Files
- Source: uploads/NEFIS_OSMFVS_HennigarWeiskittel.pdf (ECANUSA 2018).
- Companion: 20260630_benchmarking_and_calibration_strategy.md, 20260630_annual_increment_stress_test.md.
- Recent-FIA independent harness launched: ~/fia_recent_v1270.R on Cardinal (merch BA increment, post-2010).
