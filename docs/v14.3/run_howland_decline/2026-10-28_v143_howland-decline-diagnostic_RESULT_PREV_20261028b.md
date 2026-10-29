# Howland decline diagnostic, for 14.3: RESULT

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine. 28 October 2026. OSC Cardinal, `~/howland_decline_20261028/`. Nothing here changes any release; no engine file, coefficient or default of 14.1 was edited, L and T were not re-estimated, and the three diagnostic arms are not candidates for adoption.

## Registration and runs

The plan `2026-10-28_v143_howland-decline-diagnostic_PREREG.md` (md5 370f67e227bc7d4a754f156a32061952) was registered at 2026-10-28T05:58:27-04:00 (`logs/prereg_md5.txt`), after a red team re-read recorded in its section 9 and before any outcome of this study was read. Script md5s were recorded at 05:59:29 (`logs/launch_md5s.txt`), and the array (OSC job 15945900, 60 tasks, 6 arms by 10 chunks) and the first assembly (15945902) were submitted at the same time. The first assembly failed on a coding error before it read any outcome; the corrected assembly r1 (md5 622d8dc1d42e8d1b148737068441d93e, recorded 06:08:24) ran as job 15946069. Both are listed in `2026-10-28_v143_howland-decline-diagnostic_DEVIATIONS.md`. All 60 tasks completed and all 279 stand rows (93 plots by ESI 12, 15 and 18 m) ran in all six arms (`agg/hd_runok_DATA.csv`).

## Decision rule, in the registered order

| Step | Gate | Value | Outcome | Source |
|:--|:--|:--|:--|:--|
| 1 | H1, byte identity of seven output kinds for 10 chunks of v141L (frozen job 15795712), v141off and v131h (frozen job 15888501) | 210 of 210 files md5 identical | PASS | `agg/hd_harness_H1_DATA.csv` |
| 1 | H2, flux closure, tolerance 1e-6 Mg ha⁻¹ [choice, no record] | largest identity residual 1.14e-12, largest difference from trajectory BIOMASS 1.02e-12 over 3,069 snapshots per arm, continuity 0, no duplicated tree identifiers | PASS | `agg/hd_closure_H2_DATA.csv` |
| 2 | G0, an observed remeasurement exists | 0 of 93 plots with more than one measurement year; t2 tree list equals t1 except YEAR = 2075 | NOT SCOREABLE for 14.1, 14.0.4 L2 and 13.1h | `agg/hd_hindcast_G0_DATA.csv` |
| 3 | Q1, largest share of the 14.1 minus 13.1h net difference at ESI 15, threshold 0.5 [choice, no record] | mortality, share 1.477 (95% interval 1.344 to 1.660) | decline attributed to mortality | `agg/hd_contrasts_yr50_DATA.csv` |
| 3 | Q3, share of the 14.1 decline removed at ESI 15, threshold 0.5 [choice, no record] | linked mortality off 2.545 (1.690 to 5.635); basal area increment constraint off 0.319 (0.179 to 0.804) | decline attributed to the linked mortality lever | `agg/hd_switch_attribution_DATA.csv` |

The harness reproduces the frozen runs exactly, so the reference arms of this study are the frozen projections, and the flux block changed no output.

## Q2, hindcast: not scoreable

There is no observed Howland remeasurement to score against. `howland_tree_t2.csv` is written by the frozen input builder as a copy of the initial tree list with the year set to 2075, and every one of the 93 DigiSylva 2.0 Howland plots was measured in a single year (2024, 2025 or 2026). The 12 DBH columns from 2010 to 2026 are complete for every row, never decrease (share 1.0) and give the 60 snags a diameter in 2010, so they are a reconstruction with no mortality or ingrowth, not repeat measurements. As registered, no bias, equivalence, mortality or ingrowth score was computed for any version. The cross-version benchmark tolerances that would have applied (bias with a 95% stand bootstrap interval; equivalence regions of ±25% of the observed mean for the intercept and 1 ± 0.25 for the slope on 90% intervals) are stated in `docs/benchmarks/2026-10-16_cross-version/README.md` and `2026-10-16_acdx_analyze_r1.R`. A Howland hindcast needs a second field measurement of the same tagged trees.

## Q1, where the biomass goes

Survivor growth, mortality and ingrowth are computed each year from the engine tree lists with the runner's own NSVB aboveground dry biomass on stems of 5 cm and larger, so they add up exactly to the change in the runner's biomass. Cumulative to year 50 at ESI 15, with 95% plot bootstrap intervals (`agg/hd_components_cumulative_DATA.csv`):

| Version | Survivor growth (Mg ha⁻¹) | Mortality (Mg ha⁻¹) | Ingrowth (Mg ha⁻¹) | Net change (Mg ha⁻¹) |
|:--|:--:|:--:|:--:|:--:|
| 13.1h | 127.57 (123.39 to 131.88) | 112.77 (104.49 to 121.18) | 0.06 (0.05 to 0.08) | +14.86 (7.31 to 22.51) |
| 14.0.4 L2 | 131.24 (127.04 to 135.76) | 153.88 (144.74 to 163.38) | 2.98 (2.69 to 3.28) | −19.67 (−28.10 to −11.16) |
| 14.1 (L on) | 138.91 (134.58 to 143.33) | 156.59 (147.38 to 166.07) | 2.87 (2.58 to 3.16) | −14.81 (−23.28 to −6.34) |

The three versions grow nearly the same biomass on survivors. They differ in how mortality is spread over time (`agg/hd_components_annual_DATA.csv`, ESI 15). 13.1h kills 35.20 Mg ha⁻¹ (28.89 to 41.74) in the first year and then 1.55 Mg ha⁻¹ yr⁻¹ at year 10 and 1.41 at year 50. 14.1 kills 3.42 Mg ha⁻¹ yr⁻¹ (3.13 to 3.72) in year 1, 3.46 at year 10, 3.17 at year 25 and 2.63 at year 50, slightly more than its survivor growth in every year after the first (3.38 Mg ha⁻¹ yr⁻¹ in year 2, 3.17 at year 10, 2.75 at year 25, 2.16 at year 50). The first year growth of 5.00 Mg ha⁻¹ includes the step from imputed to engine heights. Ingrowth is small in every version, at most 0.09 Mg ha⁻¹ yr⁻¹.

Against 13.1h on the same runner, the 14.1 net change at year 50 is lower by 29.67 Mg ha⁻¹ (25.31 to 33.86). Mortality contributes −43.82 (−46.98 to −40.70), survivor growth +11.34 (8.50 to 14.27) and ingrowth +2.80 (2.52 to 3.10), so mortality carries 1.477 of the difference and the other two offset part of it (`agg/hd_contrasts_yr50_DATA.csv`). The same holds at ESI 12 (1.464) and 18 (1.504), and for 14.0.4 L2 against 13.1h (1.191 at ESI 15). These shares say why 14.1 differs from 13.1h, not why 14.1 loses biomass in an absolute sense. The L term adds 7.67 Mg ha⁻¹ (7.11 to 8.24) of survivor growth to 14.0.4 L2 by year 50 and costs 2.71 Mg ha⁻¹ (2.41 to 3.00) of extra mortality, for a net gain of 4.86 Mg ha⁻¹ (4.55 to 5.17), which is the 2.7 point difference between −11.0% and −8.3%.

## Q3, which switch removes the decline

Biomass change by year 50 at ESI 15 (`agg/hd_trajectory_endpoints_DATA.csv`, `agg/hd_switch_attribution_DATA.csv`):

| Arm | Change by yr 50 (%) | BA at yr 50 (m² ha⁻¹) | Plots losing biomass (of 93) | Share of the 14.1 decline removed |
|:--|:--:|:--:|:--:|:--:|
| 14.1 (L on), reference | −8.31 (−12.37 to −3.79) | 31.18 | 59 | |
| linked mortality off (LINKED=0) | +12.84 (7.92 to 17.92) | 38.74 | 26 | 2.545 (1.690 to 5.635) |
| linked mode L1 | +86.78 (81.09 to 93.68) | 62.57 | 0 | 11.444 (7.563 to 25.613) |
| BA increment constraint off (NOCON) | −5.66 (−10.06 to −0.81) | 32.13 | 54 | 0.319 (0.179 to 0.804) |

Under the registered rule the decline is attributed to the linked mortality lever. Turning it off replaces it with the 13.1 base mortality and SDImax self-thinning, which brings back an early loss (−15.84% at year 5, interval −18.58 to −12.84; figure panel b) followed by recovery to +12.8%. Lifting the diameter growth constraint removes about a third of the decline and leaves 54 of 93 plots losing biomass. The L1 arm shows where the lever's mortality comes from at Howland. With the floor hazard applied only where top height does not increase, first year mortality falls from 3.42 to 0.33 Mg ha⁻¹ and cumulative mortality to year 50 from 156.59 to 24.56 Mg ha⁻¹, so the L2 floor applied as a minimum everywhere supplies most of the 14.1 mortality on these stands. L1 is not a fix, though: it carries basal area to 62.57 m² ha⁻¹ with no plot losing biomass, which is beyond any plausible ceiling. ESI 12 and 18 show the same ordering (shares 1.907 and 3.544 for linked mortality off, 0.235 and 0.448 for the constraint off).

## Descriptive context: repeat ALS

The 23 October README statement that repeat ALS shows Howland gaining about 1 Mg C ha⁻¹ yr⁻¹ from 2012 to 2025 gives no source. The source located on Cardinal is the ORNL DAAC 2490 version 2 maps (Wei, Hayes, Sandilands, Owen, Zhao, Ma and Weiskittel 2026, Aboveground Biomass Maps for Howland Research Forest, Maine, 2012 to 2025, doi:10.3334/ORNLDAAC/2490) as reproduced in `HRF_v2maps/repro_out/summary.json`. That file gives map means of 77.28 Mg C ha⁻¹ in 2012 and 92.21 in 2025, an endpoint rate of 1.148 Mg C ha⁻¹ yr⁻¹ and a trend rate of 0.903 (`agg/hd_context_als_DATA.csv`). I could not confirm that this file is what the README cited. With a carbon fraction of 0.5 [choice, no record], mean net change over projection years 1 to 13 at ESI 15 is −0.042 Mg C ha⁻¹ yr⁻¹ (−0.167 to 0.088) for 14.1, −0.086 (−0.207 to 0.040) for 14.0.4 L2 and −0.803 (−1.067 to −0.535) for 13.1h. These numbers are context only. The periods do not overlap, the maps are wall to wall and mix leaf on and leaf off sensors, and the engine biomass is NSVB, not the Jenkins based field AGB the maps were trained on.

## Figure

`fig/2026-10-28_howland-decline_fig.png` and `.pdf`. Panel a shows cumulative survivor growth, mortality (as a loss), ingrowth and net change over 50 yr for 13.1h, 14.0.4 L2 and 14.1 at ESI 15. Panel b shows biomass change from year 0 for 14.1 and the three diagnostic arms. Bands are 95% plot bootstrap intervals (B = 2000, seed 20261028, paired draws). The hindcast panel in the brief cannot be drawn without observations, so it was replaced by panel b, as registered.

## What this means for 14.3

At Howland the 14.x decline comes from mortality, not from growth. The linked lever's L2 floor removes about 3 Mg ha⁻¹ yr⁻¹ year after year in stands of 41.5 m² ha⁻¹, and survivor growth cannot keep up with it. The diameter growth constraint accounts for about a third of the loss. A 14.3 change should look at the floor hazard's domain or level in dense unmanaged stands, consistent with the cross-version benchmark's call to condition senescence on forest type. Neither diagnostic switch is acceptable as is, since linked off brings back the 13.1 first cycle shock and L1 removes almost all mortality. Testing any of this against Howland needs a field remeasurement.

## Limits

The ALS source could not be confirmed. NOCON is taken to disable the constraint on the strength of the runner's own label and code, and was not verified inside the engine. Shares above 1 mean the other components offset part of the difference. Only ESI 15 was ruled on.

## Files

Server: `~/howland_decline_20261028/` holds the registration, scripts, `logs/` (the per task logs are named `_SERVERONLY` because they carry stand names), `out/` (per stand outputs, server only), `agg/` (12 identifier free CSVs, screened for identifiers and em dashes by the assembly) and `fig/`. Laptop copy: `CRSF-Cowork/outputs/2026-10/fvs-acd-v143/howland_decline/`. No plot or stand identifiers or coordinates appear in any file that left the server.
