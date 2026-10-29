# FVS-ACD v13.1 CONUS subplot-grain fitset build

Date: 2026-07-22. Author track: subplot-assembly subagent. Scope: DATA ASSEMBLY ONLY (no MCMC, no model fit). All figures below are aggregates; no plot, subplot, or tree coordinates appear in any output. LAT and LON are explicitly dropped in the assembly and a runtime guard asserts their absence from the fitset.

## Purpose

Build `v131sp_fitset.rds`, the FIA subplot-grain analogue of the whole-plot fitset `~/v13_kickoff/v131_fitset.rds`, so the v13.1 hierarchical recruitment and mortality submodels can be fit at subplot grain with the full re-nested (subplot within plot within region/eco/fortype) structure. A prior subagent established that the shipped `~/magplot/verify/multisrc/bench_mefia_subp_*` CSVs cannot supply responses (no persistent tree key; the positional TREE index is renumbered per snapshot) and that ME-only data collapses region and mgmt to single values, so a CONUS assembly from the remeasurement pairs is required.

## Source

Single source, the same CONUS remeasurement pair table the whole-plot fitset was built from:

`/users/PUOM0008/crsfaaron/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds`

8,221,649 tree-pair rows, 172 columns. The table is keyed to plot, condition, and subplot: it carries `PLT_CN_cond1`, `CONDID_cond1`, `SUBP`, `INVYR1`, `INVYR2`, a positional `TREE` index, both t1 and t2 tree status and diameter, condition-level stand attributes, and EPA ecoregion codes. It also carries `LAT`/`LON`, which are dropped at read.

## Definitional parity with the whole-plot assembly

The design columns are constructed with definitions mirrored exactly from the whole-plot mortality assembly `~/_scripts/v131_hier.R` (which writes `v131_fitset.rds`), cross-checked against `~/v13_kickoff/v131_growth_assembly_fit.R`, with the recruit flag taken from `~/v131_mort_ingrowth_refit_v5.R`. Column names were confirmed by printing `names()` first and resolved through the same `pick()` candidate-list logic as the whole-plot code (resolved to `STATECD`, `STDORGCD_cond1`, `TRTCD1_cond1`, `FORTYPCD`, `EPA_L1_CODE`/`EPA_L2_CODE`/`EPA_L3_CODE`, `CONDPROP_UNADJ_cond1`).

Mirrored identically:

- `rd`: `sdi_additive1 / SDImax_brms` (TPA-weighted mean of each) when both finite and `SDImax_brms > 0`, else `rd_add`. Filtered to `0 < rd < 2`.
- `ln_qmd`: `log(QMD1)` (TPA-weighted), `qmd > 0`.
- `ba`: `BA1` (TPA-weighted). These stand attributes are condition-level and constant within a condition, so the TPA-weighted mean equals the condition value; the weighted-mean form is kept for exact parity.
- `region`: `as.character(STATECD)`, falling back to `EPA_L1_CODE` when state is missing.
- `eco`: `EPA_L3_CODE`, falling back to `EPA_L2_CODE`, then `EPA_L1_CODE`. Because the pair table already carries the EPA level 1/2/3 codes, eco is assigned by direct column read; no server-side spatial ecoregion join was needed. This is the same eco construction the whole-plot fit uses.
- `fortype`: `as.character(FORTYPCD)`, `"unk"` when missing.
- `mgmt`: `planted` if `STDORGCD_cond1 == 1`; else `treated` if `TRTCD1_cond1 > 0` or `years_since_trt` in [0, 40); else `none`.
- `recent` (holdout flag): `INVYR2 >= quantile(INVYR2, 0.9)` computed within region, so the most recent inventory decile per region is held out. The fit uses `recent == 0`.
- `log_years`: `log(YEARS)`, the exposure offset, with the same `1 <= YEARS <= 20` interval filter.
- Row filters mirrored: `TREESTATUS1 == 1`, `TREESTATUS2 in {1,2}`, `TPA1 > 0`, `DBH1 >= 2.54` cm for the mortality tree set; stand-level `trials > 0`, `0 <= deaths <= trials`, finite `ba`, `qmd > 0`.

The one deliberate, task-mandated departure from the whole-plot file is the response construction (see below): the whole-plot mortality response is TPA-expanded (`trials = sum(TPA1)`, `deaths = sum(TPA1*died)`, stored as fractional expansions), whereas the subplot response is a raw stem count. The design columns are identical.

## Subplot aggregation

Unit is the FIA subplot (`SUBP`, 4 per plot), following the fia-subplot-hex convention: subplot as the analysis unit rather than plot or condition, subplot-level treatment rather than plot-level EXPNS, and subplots nested within plot so a plot-level group can be carried for a `(1|plot)` random effect.

- `subplot_key = paste(PLT_CN_cond1, CONDID_cond1, SUBP, INVYR1, INVYR2)`: the whole-plot condition key with `SUBP` added.
- `plot_id = paste(PLT_CN_cond1, INVYR1, INVYR2)`: the plot-remeasurement id carried for the `(1|plot)` group.

Tree records are aggregated to the subplot. No plot-level EXPNS and no per-hectare expansion is applied; the responses are raw stem counts on the subplot, with the interval carried as a `log_years` offset. The pair table carries condition-level `CONDPROP_UNADJ_cond1` (retained in the fitset as `condprop`) but no subplot-level `SUBPCOND_PROP`, and because the responses are counts rather than per-area estimates, no condition-proportion area expansion is applied; this is consistent with the task instruction to keep counts and to avoid plot-level EXPNS.

## Response construction (subplot grain)

- Mortality: `trials` = count of live-at-t1 stems on the subplot (rows passing the mortality tree filter, i.e. `TREESTATUS1 == 1`, `DBH1 >= 2.54` cm, known t2 fate); `deaths` = count of those that were dead by t2 (`TREESTATUS2 == 2`). Both are integers. Subplot-intervals with no live t1 tree do not appear (they contribute no rows to the mortality set). Exposure carried as `log_years`.
- Recruitment: `recruit_count` = integer count of t2 trees crossing the 2.54 cm DBH threshold with no qualifying t1 record, using the refit_v5 recruit flag (live at t2 and `DBH2 >= 2.54`, and not (present and `DBH1 >= 2.54` at t1)). Counted from the full pair table, then joined to the mortality subplot set by `subplot_key`; subplots with a live t1 overstory but no recruits get 0. Kept as a count with the `log_years` offset; not expanded to per hectare.

The recruitment universe is therefore the set of subplots that carry a live t1 overstory and valid design covariates, the same join logic the whole-plot ingrowth used (ingrowth joined to the survivor set by stand key), one level finer.

## Holdout

`recent` holds out the most recent inventory decile per region (`INVYR2 >= region-wise 90th percentile`), and the fit uses `recent == 0`, matching the whole-plot design. The ME, NB, and QC MagPlot benchmark units are out of the FIA CONUS pair table by construction (MagPlot is not FIA; NB and QC are Canadian), so they are not in this table at all; the recent-FIA benchmark decile is what the `recent` flag removes. The fitset stores the full set with the `recent` flag (rather than pre-filtering to `recent == 0` as the whole-plot file does), so the held-out units remain available for benchmark evaluation while the fit still selects `recent == 0` identically.

## eco assignment

eco is assigned directly from the EPA ecoregion codes already present in the pair table: `EPA_L3_CODE`, falling back to `EPA_L2_CODE`, then `EPA_L1_CODE`. No spatial join was performed because the join has already been baked into the source table. This reproduces the whole-plot eco definition exactly.

## Design summary (validated on a 3% plot subsample)

The full assembly is memory-bound: `readRDS` of the full 172-column pair object peaks at about 18.6 GB before any column subsetting, which is intrinsic to the monolithic RDS read (columns cannot be selected without full deserialization). It therefore runs as a SLURM batch job (`~/v131sp_assembly.sbatch`, `--mem=48G`), not on the login node. The pipeline itself was validated end to end on a 3% plot subsample (nesting preserved by sampling whole plots), which produced a clean design matrix:

| metric | 3% subsample value | note |
|---|---|---|
| subplots (all) | 24,966 | scales to roughly 0.8 M at full CONUS |
| subplots (fit, recent==0) | 21,638 | |
| subplots (heldout, recent==1) | 3,328 | |
| plots (1 | plot group levels) | 7,186 | |
| region levels | 48 | matches whole-plot (48) |
| eco levels | 84 | matches whole-plot (84) |
| region:eco levels | 249 | |
| fortype levels | 130 | grows toward whole-plot 150 at full |
| planted / treated / none | 2,518 / 1,896 / 20,552 | |
| recruitment zero fraction (fit) | 0.9075 | |
| recruitment var/mean (fit) | 1.611 | overdispersed vs Poisson |
| recruitment mean (fit) | 0.123 recruits/subplot-interval | |
| mortality deaths (fit) | 13,659 | |
| mortality trials (fit) | 150,668 | |
| mortality rate (fit) | 0.0907 | |

Group-level coverage (region 48, eco 84, region:eco 249, fortype 130 at 3%) confirms the re-nested structure is fully populated at subplot grain, matching the whole-plot region/eco counts, with plot available as a distinct fifth grouping level for `(1|plot)`.

Note on the recruitment zero fraction. At true CONUS FIA subplot grain the zero fraction is about 0.91 with var/mean about 1.61, not the 0.36 / 2.1 a prior subagent reported from the ME bench CSVs (the source the task itself flagged as unusable). The subplot/microplot footprint is small, so a recruit crossing 2.54 cm on any given subplot-interval is genuinely rare and the count is zero most of the time. The overdispersion (var/mean 1.61 > 1) is consistent with a negative binomial, and an NB with a mean near 0.12 naturally produces a very high zero share, so the single-NB choice is defensible; but the modeler should confirm single NB versus a zero-inflated or hurdle NB against the real 0.91 zero fraction rather than the 0.36 figure. This is a likelihood decision for the fit step and does not change the assembly, which keeps the integer count response.

## Fitset schema

`v131sp_fitset.rds` columns (no coordinates):

`subplot_key, plot_id, YEARS, trials, deaths, ba, qmd, sdi_add, sdimax, rd_row, yst, condprop, STATE, ORG, TRT, FOR, L1, L2, L3, INVYR2, rd, ln_qmd, log_years, planted, treated, mgmt, region, eco, fortype, recent, recruit_count`

## Files

- `~/v13_subplot/v131sp_assembly.R`: the data.table assembly (validated).
- `~/v131sp_assembly.sbatch`: SLURM wrapper (account puom0008, 4 cpus, 48 GB, 40 min). Ready for the main thread to submit; produces `v131sp_fitset.rds`, `v131sp_designsummary.csv`, and `v131sp_designmatrix_bymgmt.csv` in `~/v13_subplot/`.
- `~/v13_subplot/v131sp_designsummary_DRYRUN.csv`: the 3% validated preview summary above.

## Run status

Needs a batch submit. The pipeline is validated on the subsample; the full CONUS run is memory-bound (~18.6 GB peak from the RDS read) and left as `~/v131sp_assembly.sbatch` for the main thread to submit, per the task rule. Nothing in `~/v13_kickoff/` was touched (job 12526556 continues writing there); all writes went to `~/v13_subplot/` with the `v131sp_` prefix.
