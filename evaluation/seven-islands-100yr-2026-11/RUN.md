# Seven Islands plot projections, 17 November 2026

## Scope

Project every plot with live trees in the two spreadsheets dated 17 November 2026 for 100 years with no treatment. Output at 0, 5, ..., 100 years. The source contains 536 plots on 119 stands and 3,728 live tree records; 525 plots have live trees. The 11 plots without live trees are recorded in each model's error file because these tree-list runs have no valid starting state for them.

## Models and code

- OSM Acadian 2.26.1, `OSM.ConsoleApp` MD5 `6ae5235b50019dd80fa253ed284b27c9`.
- Native FVS-NE, executable MD5 `ba9d0fa463c3bcc8d2e7e57d84310965`.
- Native FVS-ACD, executable MD5 `33805f7ec566b6fe2f48722a209581dc`.
- GitHub source refreshed 17 November: `advanced-forestry-systems/fvs-modern` main `d0ff5bc35bc4ae6fe8204d6c4125c8c62f7b66ab`; `holoros/fvs-acd` evaluation branch `7b6f016e76e8a4fde2bf478ee01488df0e1c578d`. The newest changes add inventory species-resolution and FVS driver guards in fvs-modern and comparator-completion checks in fvs-acd. These updates do not change the existing firebreather executables or the tagged AcadianGY research source used in these runs. The executables are identified by their own MD5 values; the GitHub source hashes are provenance for reviewed code, not a claim that these executables were rebuilt from those commits.

## Input and run choices

- A single plot is a single model stand. Initial trees are the live rows in `TreeInit` with the matching `PLOT_ID`.
- OSM Acadian rejects DBH under 1 cm. Thirteen such records on seven plots are excluded from all three model inputs, keeping the compared starting tree lists identical. Their contribution to starting basal area is small, but their removal changes starting tree density on those seven plots.
- The supplied 20 ft²/ac basal area factor applies at DBH 4.6 inches and above. Trees below 4.6 inches use a 1/500 acre subplot. FVS receives the raw tree count and those sampling fields; OSM receives expanded stems per hectare. The year 0 basal area and tree density are checked against the same independent calculation for each model.
- FVS receives plot elevation and stand climate site index from `PlotDetails` (meters converted to feet), with site species 12. Other stand defaults in the script are age 60, region 9, state 23, county 21, flat aspect and slope 5. FVS-ACD here means the native executable, not the AcadianGY 14.2 bridge model.
- OSM receives the median BGI of the five nearest records in the current regional BGI lookup and the input species remap in the script. OSM writes no merchantable volume here. It runs 105 years in five year cycles to expose the year 100 output because the last cycle is not written.
- The model comparison is descriptive long horizon behavior. No observed year 100 outcomes are available for accuracy claims. Current climate site inputs are held constant; no harvest, disturbance overlay, or climate change scenario is applied.

## Files and access

Restricted run directory on firebreather: `~/restricted/seven_islands_100yr_20261117/`. Code copies are under `~/jobs/seven_islands_100yr_20261117/`.
`results/fvs_ne.csv`, `results/fvs_acd.csv`, and `results/osm.csv` hold plot trajectories; `results/plot_model_trajectory.csv` combines them. Corresponding `_errors.csv` files list exclusions and failures. `results/meta.json` records input and executable checksums. `results/qc.json`, `results/aggregate_trajectory.csv`, and `results/aggregate_differences.csv` are produced after the model runs.

The per plot files and coordinates remain on firebreather. Only aggregate summaries are copied to the local deliverable folder. Zenodo: not applicable to this exploratory model comparison.

## Final harmonization and research arms

The first native runs used the spreadsheets' raw species labels. A red-team check showed that standardizing CE to WC (cedar) and WB to PB (paper birch) changed some individual native trajectories. The native FVS-NE and FVS-ACD runs were therefore repeated for all 536 source plots using those standardized identities. The validated files `results/fvs_ne.csv` and `results/fvs_acd.csv` now contain the standardized runs; `results/fvs_ne_rawcodes.csv` and `results/fvs_acd_rawcodes.csv` retain the originals as a restricted audit trail. OSM already mapped cedar to WC and handled white birch as WB internally. The research ACD runner maps CE to WC and WB to PB. All final aggregate products were regenerated after this correction.

The additional research source arms are AcadianGY v12.11.1, v13.1 base, v14.0.4 L2, and v14.1 L2L. Their source MD5 values are `127cffc33ec35607e3b138a7acf12384`, `5894df6013c701d09e7ba67ba6c2f090`, `61f95d99f896e8e513930d6e33a7391a`, and `0bf27dde81240e6bdf59c9a90f0051bd`, respectively. The v14 coefficient bundle MD5 is `4740de88af8231677d828dec8e5b753c`; the v14.1 option coefficient bundle MD5 is `c8f02f5841e98b93cb532b6fa9b1fc51`. Research tags `archive-2026-11-02` and `research-14.1` were retrieved from `holoros/fvs-acd`.

These four arms use one plot per each of the 117 eligible stands, sampled deterministically with seed 20261117. The v12 arm applies its archived candidate density and ingrowth levers with unmanaged status assumed. The v13.1 **base** arm has hierarchical ingrowth and mortality off; the historical hierarchical posterior files were unavailable, and the user selected this base arm. v14.0.4 uses linked mortality L2 and its BA refit; v14.1 adds the L diameter growth option with thinning recency off because no thinning dates were supplied. They are annual R model runs recorded every five years. Configuration changes accompany version changes, so their contrasts are descriptive configured-arm differences.

Final validation produced 525 complete native plots and 117 complete plots per research arm, each with 21 time points, no plot failures beyond the 11 input plots with no live trees, no duplicates, and no negative or nonfinite basal area. Research-arm year-zero BA differs from the native starting state by at most 0.0000475 ft²/ac and TPA by at most 0.000785. `results/qc.json` and `results/version_qc.json` hold the checks. The stand-cluster bootstrap uses 2,000 draws and seed 20261117; intervals for strata with fewer than five stands are withheld. Sampling intervals are conditional on the input and model settings, not predictive uncertainty.

The final plot-level research files are `results/acd_v12_11_1.csv`, `results/acd_v13_1_base.csv`, `results/acd_v14_0_4_L2.csv`, and `results/acd_v14_1_L2L.csv`. Aggregate-only summaries are `results/overall_uncertainty.csv`, `results/matched_overall_uncertainty.csv`, `results/strata_uncertainty.csv`, `results/matched_strata_uncertainty.csv`, `results/year100_paired_differences.csv`, `results/stress_flags.csv`, and `results/sensitivity_summary.csv`. The primary comparative figure uses the same 117 plots for every arm. No observed century-scale outcomes are available to validate forecast accuracy.

## Reproduction commands

Execution host: firebreather (private server alias). R 4.5.1, `data.table` 1.18.6.1, `dplyr` 1.2.1, and `purrr` 1.2.2. Python used pandas and NumPy in the existing project virtual environment. The remote directory contains `plots.csv`, `trees.csv`, the version source and coefficient files, and `version_sample_plots.csv`; those restricted inputs are not in the repository. The native executable paths and OSM BGI lookup path are in `run_seven_islands_100yr.py` and are pinned by MD5 above.

```bash
python run_seven_islands_100yr.py --models FVS-NE,FVS-ACD,OSM
python rerun_native_standardized.py FVS-NE
python rerun_native_standardized.py FVS-ACD
python promote_native_standardized.py
Rscript --vanilla run_acd_versions_100yr.R v12.11.1 0 1 2
Rscript --vanilla run_acd_versions_100yr.R v12.11.1 0 2 2
# Repeat both shards for v13.1-base, v14.0.4-L2, and v14.1-L2L.
python qc_seven_islands_100yr.py
python combine_acd_versions_100yr.py
python stress_seven_islands_100yr.py
python sensitivity_seven_islands_100yr.py
```

The eight research ACD shards were run in parallel and then combined. The species-audit correction required one complete restart. Execution time is host-load dependent; no elapsed-time claim is used as a quality gate. Only aggregate summaries leave the restricted directory. The run is exploratory, so no Zenodo deposition is planned.

## Modified Bakuzis assessment

The biological consistency check uses all seven configured arms. Its common-property pass reads the validated five-year basal-area, tree-density, and quadratic-mean-diameter paths for every eligible plot (`bakuzis_common_axes.py`). The Reineke screen uses 0.10 cm/year QMD gain, or 0.5 cm for a five-year output step, and reports evaluated, not-evaluated, and flagged trajectories separately. The observed year-zero BA and SDI 99th and 99.9th percentiles are reference screens, not biological maxima.

Top height was then extracted from a repeat run of native FVS and OSM (`run_native_bakuzis_height.py`) and from annual AcadianGY runs sampled every five years (`run_acd_bakuzis_height.R`). The latter has the same model inputs and configuration as `run_acd_versions_100yr.R` and adds top-height extraction. `bakuzis_full_axes.py` checks that all repeat research-arm BA, TPA, and QMD values match the original outputs before using the height paths. It uses top-50-trees-per-hectare height for the research arms and the reported top-height summary for native models. The volume axis is a **common proxy** equal to basal area in m²/ha times top height in m times 0.40. It is not reported timber volume or independent total volume production, so Eichhorn's production relation cannot receive a pass from these data.

`make_bakuzis_figures.py`, `make_bakuzis_matrices.py`, and `make_bakuzis_slide_axes.py` generate aggregate figures. Seven modified lower-triangular matrices plot the same 117-plot matched sample by climate-site-index tercile; class means across heterogeneous starting stands are descriptive site-ordering screens, not controlled site-effect tests. Plot-level repeat outputs and coordinates stay on firebreather. Only aggregate diagnostic tables and figures are shared.

All four research height reruns completed with 117 plots and zero run errors. The repeated BA, TPA, and QMD paths match the validated originals exactly (maximum absolute difference 0 for each variable). All 525 native plots have 21 finite heights. In each research arm, 114 of 117 plots have 21 finite heights; three have a missing year-zero height but finite height at all later five-year outputs. Those baselines were not imputed. `bakuzis_full_axes.py` records height completeness and uses available finite intervals. The Reineke screen is unaffected by the height gaps.

Run `bakuzis_common_axes.py` first, followed by the native and research height runners and then `bakuzis_full_axes.py`; the latter verifies rerun equality before writing aggregate height, site, and proxy-volume tables. Copy only the aggregate `bakuzis_*.csv` summaries and audit JSON to the local deliverable folder, then run `make_bakuzis_matrices.py`, `make_bakuzis_full_slide.py`, `build_bakuzis_memo.py`, and `render_bakuzis_memo.py` there. The outputs include a relation table with Reineke evaluated/not-evaluated counts, a separate assessment memo, and seven matrix figures. The assessment is a falsification screen, not a century-scale accuracy validation.
