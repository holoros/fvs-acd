# FVS-ACD (Acadian variant of the Forest Vegetation Simulator), v12.10.1

Frozen August 2026 operational release. Weiskittel and Rice 2026, University of Maine, Center for Research on Sustainable Forests. Licensed CC BY 4.0. Concept DOI: [to be minted].

## What FVS-ACD is

FVS-ACD is an independent Acadian growth and yield model for the mixed spruce, fir, and northern hardwood forests of the Acadian region (Maine, New Hampshire, Vermont, New Brunswick, and the Acadian ecoregions of Quebec). It is an Acadian variant of the Forest Vegetation Simulator lineage, implemented in R and maintained by Ben Rice for use in FVS. The model projects stand development on the shared FIA National Scale Volume and Biomass (NSVB) system, so its volume, biomass, and value outputs are directly comparable to the Forest Inventory and Analysis reference. It couples a two-segment relative-density mortality function with density-released ingrowth, a composition- and ecoregion-aware Bayesian (brms) maximum stand density index surface, and an Ecological Site Index (ESI) consistent dominant-height anchor recalibration. The design goal is a transparent, biologically realistic, climate-ready projection system rather than a single-metric best fit.

## What v12.10.1 contains

Version 12.10.1 is the v12.9.x base plus the Chapter 11 direct-effect management modifiers, gated off by default. With the management gate off (`ops$use.mgmt.mod = FALSE`), the run reproduces the v12.9.x growth and yield. With the gate on, the model applies a clamp-free additive release: planted stands receive a sustained Type 2 diameter-growth release and precommercial-thinned (PCT) stands a decaying Type 1 release, fitted as a 10 percent trimmed mean of per-stand observed minus predicted-untreated increment (planted +3.8 and PCT +2.4 m² ha⁻¹ basal area, proportional releases in the other eight NSVB metrics). Mortality is deliberately not given a multiplicative management modifier; management as a hierarchical predictor is a later (v13.2) item. No equation or coefficient changed between the frozen v12.10.1 R source and the Cardinal source; the only edit to the R file is a comment-only frozen-baseline header.

## The honest benchmark position

On the operational inventory domain and on the pooled evaluation cell, OSM v2.26.1 slightly leads: OSM carries the lower pooled mean absolute level bias (about 3.2 versus 5.0 percent), the higher mean modeling efficiency (about 0.75 versus 0.71), and one more TOST level equivalence (8 of 9 versus 7 of 9). FVS-ACD's edge is not pooled precision. It is biological realism, being the only entrant that plateaus at a realistic maximum density and passes all five Bakuzis relations; durable long-horizon self-thinning behavior; a durable quadratic mean diameter advantage (about +1 to +2 percent versus OSM +11 percent); a validated, climate-ready ESI site driver; and full transparency in R. Inside the operational domain the near-parity on volume is honest but rests on an offsetting bias signature: basal area about -9.2 percent, top height about +4.16 percent, and total volume about -1.63 percent by cancellation. The one disclosed limit that remains is ingrowth: recruitment across the tag threshold is under-predicted, about 45 percent of observed in New Brunswick and about 59 percent in Quebec, though it responds in the correct direction to density and management. The reason v12.10.1 exists is the management cell, where the additive release beats OSM cleanly out of sample (managed mean absolute bias about 1.3 versus 8.3).

## File manifest

| File | Description |
|:---|:---|
| `00_FVS-ACD_v12101_graphical_abstract.png` | Lead visual: five-way scorecard heatmap and the offsetting bias signature. |
| `AcadianGY_12.10.1.r` | Frozen v12.10.1 model source (R), comment-only frozen header, md5 027ad5e5532b801718f8ad0b22bada9d. |
| `FVS-ACD_v12.10.1_benchmark_report_FINAL_20260710.md` | Full independent benchmark report: five-way scorecard, operational-domain rescoring, equivalence tests, Bakuzis relations, management-modifier scorecard, OSM comparison. |
| `20260629_FVS-ACD_variant_overview_GTR_draft.md` | Variant overview general technical report (GTR) draft. |
| `fig1_scorecard_heatmap.png` | Scorecard heatmap. |
| `fig2_accuracy_by_forest_type.png` | Accuracy by forest type. |
| `fig3_bakuzis_relations.png` | Bakuzis law-like relations. |
| `fig4_selfthinning_trajectory.png` | Long-horizon self-thinning trajectory. |
| `fig5_offsetting_bias.png` | Offsetting bias signature. |
| `fig6_managed_oos_bias.png` | Managed, out-of-sample bias. |
| `five_way_scorecard.csv` | Aggregate five-way scorecard (stratum by model by metric); see `data_dictionary.csv`. |
| `data_dictionary.csv` | Column definitions for `five_way_scorecard.csv`. |
| `CITATION.cff` | Citation metadata. |

## How to run it

The model is a single R source. Source it in an R session with the FVS-ACD dependencies loaded, then call the projection with the operational ops list. The frozen configuration uses `use.ingrowth = TRUE` (minimum DBH 5.0), `use.sdimort = TRUE` (two-segment onset/break/beta), `use.brms.sdimax = TRUE` with the per-stand map, and `use.esi.anchor.recal = TRUE` with the region ESI anchor coefficients, plus per-province dominant-height afac (New Brunswick 0.579, Quebec 0.111). The Chapter 11 management modifiers are gated by `ops$use.mgmt.mod`, default `FALSE`; set it `TRUE` only to apply the planted and PCT diameter-growth releases to managed stands. The base scorecard in this deposit was produced from this exact source with the management gate off.

## Data restrictions

This deposit contains only shareable artifacts: the frozen R model source, the benchmark report, the GTR draft, the six summary figures, and the aggregate five-way scorecard. It does not contain any per-stand results, plot-level records, FIA true plot coordinates, or proprietary provincial per-stand data. FIA true coordinates are restricted and never leave the compute server; only fuzzed or aggregated values may be released. Proprietary provincial and industry inventory data are shared only as aggregates and only under their respective agreements. All computation ran on the University of Maine OSC Cardinal cluster; only aggregates appear in this record.
