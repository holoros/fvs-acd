# scripts/ index

This folder holds the AcadianGY (FVS-ACD) R engine lineage from 12.3.6 to the model of record 13.1, the scripts that built, patched, fitted, benchmarked, plotted and presented those versions, and seven subfolders (`bakeoff_v13`, `phase2`, `phase3`, `seven_islands`, `tools`, `v14.2dev`, `versions`). This index replaces a reorganization: frozen launchers and md5 records elsewhere cite these exact paths, so no file here may be moved, renamed, edited or deleted. The 14.0.x and 14.1 engine files are not here; they are on branch `engines-14.1-20260924` (PR #9), per `VERSION_HISTORY.md`, and the 13.1 file in this folder is the base every 14.x file sources. `docs/reference/running-14.1.md` describes how the 14.x layers stack.

How to read the tables. Engine status is quoted from `VERSION_HISTORY.md` (shipped, frozen, prototype, variant, draft, superseded waypoint, superseded or parked). Every other description comes from the file's header comment. Where a file has no header comment, the description is read from its first lines of code and marked (code). Anything taken from the filename alone is marked [from name]. For non-engine files, Status is "as found" unless the header states something more (canonical, not executed, R companion and so on). Files that look like scratch, debug or variant copies are labelled as such; the label is descriptive only and is not a judgment that the file can be deleted.

## Engine versions (AcadianGY_*.r)

| File | What it does | Era or version | Status |
|---|---|---|---|
| `AcadianGY_12.3.6.r` | Canonical v12.3.5 plus an in-source, opt-in, size-dependent mortality correction (`ops$MORTCAL`, task #126b), default off | Era 1, 12.3.6, 21 May 2026 | prototype; byte-identical copy also in `versions/` |
| `AcadianGY_12.3.6_uploaded.r` | Same header text as 12.3.6. VERSION_HISTORY calls it a byte-identical upload copy of 12.3.6, with the diff unverified. Checked for this index: its md5 differs from 12.3.6 and its `AcadianVersionTag` reads `AcadianV12.3.5` | Era 1, 21 May 2026 | prototype; upload copy (scratch-looking) |
| `AcadianGY_12.3.7.r` | Header text is still the 12.3.6 MORTCAL candidate block; tag `AcadianV12.3.7` | Era 1, 22 May 2026 | prototype; byte-identical copy in `versions/` |
| `AcadianGY_12.3.7_dbg.r` | Debug build of 12.3.7; same header block, tag `AcadianV12.3.7-dbg` | Era 1, 26 May 2026 | prototype, debug build; debug copy |
| `AcadianGY_12.3.8.r` | Same 12.3.6 header block; `versions/README.md` notes it as the acd_divergence investigation (fvs-modern) | Era 1, 26 May 2026 | prototype; byte-identical copy in `versions/` |
| `AcadianGY_12.3.9.r` | Same 12.3.6 header block; the target of the 12.3.10 ESI patch | Era 1, 28 May 2026 | prototype; byte-identical copy in `versions/` |
| `AcadianGY_12.3.10.r` | Site-driver modernization: site index taken from the unified-target ESI instead of legacy CSI, input change only; `ops$SITE_SOURCE = "CSI_legacy"` reproduces 12.3.9 | Era 1, 28 Jun 2026 | prototype |
| `AcadianGY_12.5.0.r` | Production refactor baseline (make_stand / make_acd_tree / make_ops / AcadianGYOneStand contract, per `versions/README.md`) | Era 2, 6 Jun 2026 | shipped; byte-identical copy in `versions/` |
| `AcadianGY_12.5.0_mortcal.r` | 12.5.0 with the #126b mortality correction ported from 12.3.9, opt-in via `ops$use.mortcal` | Era 2, 8 Jun 2026 | variant, MORTCAL enabled; byte-identical copy in `versions/` |
| `AcadianGY_12.6.0.r` | Site-driver and self-thinning refinements, gated, default on; tag still reads `AcadianV12.5.0` | Era 2, 28 Jun 2026 | shipped |
| `AcadianGY_12.6.1.r` | Ingrowth refinement, volume and value validated across NB/NS/ME; tag reads `AcadianV12.5.0` | Era 2, 28 Jun 2026 | shipped; the README's "production candidate" in late June |
| `AcadianGY_12.6.2_proto.r` | 12.6.1 plus a gated ESI-anchored dominant-height constraint (per `build_v1262proto.R`) | Era 2, 28 Jun 2026 | prototype |
| `AcadianGY_12.6.2b_proto.r` | ESI-anchored dominant height using the fitted Chapman-Richards anchor k = 0.0039, p = 0.726 (per `build_v1262b.R`) | Era 2, 29 Jun 2026 | prototype |
| `AcadianGY_12.6.4.r` | Regional stand-mortality cut scale, the structural fix for the Maine mortality deficit | Era 2, 29 Jun 2026 | shipped |
| `AcadianGY_12.6.5.r` | Interim size-form diameter increment modifier on the Kuehne 2022 base, gated | Era 2, 30 Jun 2026 | shipped |
| `AcadianGY_12.7.0.r` | Integrated operational version: 12.6.5 plus the fitted ESI dominant-height anchor, gated `ops$use.esi.domht`; tag reads `AcadianV12.5.0` | Era 2, 30 Jun 2026 | shipped |
| `AcadianGY_12.7.1.r` | Coupled two-segment self-thinning plus density-released ingrowth | Era 2, 30 Jun 2026 | shipped |
| `AcadianGY_12.9.0.r` | Carries the 12.7.1 header block; tag reads `AcadianV12.7.1` | Era 3, 1 Jul 2026 | shipped |
| `AcadianGY_12.9.2.r` | August 2026 operational finalization: brms SDImax, ESI anchor fix, ingrowth tune. The actual file behind the frozen v12.10.1 base (model plus ops recipe) | Era 3, 2 Jul 2026 | shipped |
| `AcadianGY_12.10.r` | Strategic management modifiers, gated, default off; tag `AcadianV12.10.0` | Era 3, 2 Jul 2026 | shipped |
| `AcadianGY_12.10.1.r` | Frozen operational baseline for the 18 August 2026 meeting: 12.9.x base plus the Chapter 11 management modifiers gated by `ops$use.mgmt.mod` | Era 3, 3 Jul 2026 | **frozen**, the August operational baseline |
| `AcadianGY_12.10.2.r` | 12.10.1 lineage; the 12.11 header records it as byte-identical to frozen 12.10.1 at default ops | Era 3, 4 Jul 2026 | shipped |
| `AcadianGY_12.11.r` | Header: maturity-gradient long-horizon volume correction, three gated levers default off, built off 12.10.2. VERSION_HISTORY: hardwood form/risk fold-in (Ryan Smith 2022 thesis) | Era 5, 22 Jul 2026 | shipped |
| `AcadianGY_13.0.r` | v13.0 joint dominant-height and basal-area re-anchor (built by `build_v130.py` from 12.10.2); tag reads `AcadianV12.10.1` | Era 4, 10 Jul 2026 | superseded / parked, not adopted |
| `AcadianGY_13.0_v2.r` | Second 13.0 iteration; tag reads `AcadianV12.10.1` | Era 4, 11 Jul 2026 | superseded / parked; variant copy |
| `AcadianGY_13.0_wideclamp.r` | Widened ESI-anchor clamp variant of 13.0 | Era 4, 11 Jul 2026 | superseded / parked; variant copy |
| `AcadianGY_13.1proto_hwmod.r` | Hardwood modification prototype on the 12.10.1 lineage; tag reads `AcadianV12.10.1` | Era 6, 15 Jul 2026 | prototype |
| `AcadianGY_13.1_DRAFT.r` | Hierarchical recruitment and mortality, pre-canonical | Era 6, 22 Jul 2026 | draft, pre-canonical |
| `AcadianGY_13.1_PREV_20260725_ingfix.r` | State after the ingrowth code bug fix | Era 6, 25 Jul 2026 | superseded waypoint; PREV copy |
| `AcadianGY_13.1_PREV_20260728_ingnorm.r` | State after the ingrowth normalizer was introduced | Era 6, 28 Jul 2026 | superseded waypoint; PREV copy |
| `AcadianGY_13.1.r` | Hierarchical recruitment and mortality posteriors replace the two v12.11 hand levers; with the new switches off it is byte-identical to frozen 12.10.1 on a 20 yr projection. Header block still says "(DRAFT)". Never edited since; later tuning (ship18 and others) is applied as overlays | Era 6, 13 Aug 2026 | **shipped, current model of record**; base of every 14.x file |

## Build and patch scripts

| File | What it does | Era or version | Status |
|---|---|---|---|
| `acadiangy_12310.patch` | Unified diff from `AcadianGY_12.3.9.r` to `AcadianGY_12.3.10.r` (the ESI site-driver change) | builds 12.3.10 | as found |
| `acadiangy_esi_patch.R` | Site-driver patch instructions: source site index from ESI; target 12.3.9, proposed 12.3.10 | builds 12.3.10 | as found |
| `build_v126.R` | Builds 12.6.0 from 12.5.0_mortcal by four gated refinements, each anchor asserted to hit once | builds 12.6.0 | as found |
| `build_v1261.R` | Builds 12.6.1 from 12.6.0: expected-value ingrowth and ingrowth on by default | builds 12.6.1 | as found |
| `build_v1262proto.R` | Builds 12.6.2_proto from 12.6.1: gated ESI-anchored dominant-height constraint, off by default | builds 12.6.2_proto | as found |
| `build_v1262b.R` | Builds 12.6.2b_proto with the fitted Chapman-Richards anchor (k = 0.0039, p = 0.726, base age 50) | builds 12.6.2b_proto | as found |
| `build_v1264.R` | Adds the gated regional stand-mortality cut scale `ops$mort.cut.scale`; 1.0 reproduces 12.6.1 | builds 12.6.4 | as found |
| `build_v1265.R` | Builds 12.6.5 on 12.6.4: gated interim size-form diameter increment modifier | builds 12.6.5 | as found |
| `build_v1270.R` | Builds 12.7.0: base 12.6.5 plus the fitted ESI dominant-height anchor from 12.6.2b | builds 12.7.0 | as found |
| `build_v130.py` | Transforms 12.10.2 into 13.0 with two regex edits (height anchor swap, BA net-increment anchor) | builds 13.0 | as found |
| `v130_acadiangy_patch_regions.R` | Patch code for the two regions of 12.10.2 that become 13.0 | builds 13.0 | as found |
| `make_run_v126.R` | Derives the `run_v126.R` driver from the v125 driver, adding v12.6 ops flags and ESI passthrough | builds driver for 12.6 | as found |

## Model fitting and calibration

| File | What it does | Era or version | Status |
|---|---|---|---|
| `hierarchical_esi_height.R` | Hierarchical ESI-anchored dominant-height sub-model, Chapman-Richards with ecoregion/species random effects (nlme), 27 June 2026 | site update |  as found |
| `prep_polymorphic.R` | Stage A polymorphic species-specific Chapman-Richards shapes with ESI as site level | site update | as found |
| `sdimax_resummary.R` | Resummarizes brms plot-level SDImax for ME/NH/VT by ecoregion, forest type and CSI/ESI quartile | not stated | as found |
| `nsvb_emulator_fit.R` | Fits an NSVB volume and biomass emulator from FIA ME_TREE outputs, log(D2H) form with Duan smearing | not stated | as found |
| `mgmt_modifier_fit.R` | Strategic management modifiers (Type 1 PCT, Type 2 planted), direct-effect fit; builds v12.10 predictions | 12.10 | as found |
| `mgmt_diagnose.R` | Diagnoses per-stand direct-effect response for planted and PCT stands and the 1.6 clamp | not stated | as found |
| `mgmt_estimators.R` | Compares robust size-aware direct-effect estimators per class | not stated | as found |
| `mgmt_cv_robust.R` | CV battery for robust additive direct-effect release against the clamped multiplier | not stated | as found |
| `mgmt_finalfit.R` | Final robust additive release plus equivalent effective DG multiplier for the engine | not stated | as found |
| `mgmt_rescore.R` | Re-scores v12.10.1 under robust modifier specs | 12.10.1 | as found |
| `mgmt_plateau_sweep.R` | (code) Sources `AcadianGY_12.10.r` and sets a base ops configuration; plateau sweep [from name] | 12.10 | as found |
| `v129_build_dataset.R` | v12.9 exploration: per-stand SDImax table from MagPlot NB+QC and recent Maine FIA, to test an ESI cluster factor | 12.9 | as found |
| `v129_build_fia.R` | (code) Sources 12.7.1 and reads Maine FIA ME_PLOT; builds the FIA side of the v12.9 table [from name] | 12.9 | as found |
| `v129_cluster_test.R` | (code) Combines MagPlot and FIA SDImax tables and k-means clusters on ESI, lat, lon | 12.9 | as found |
| `v130_height_anchor.R` | v13.0 domain mask plus increment-consistent dominant-height anchor, fit on ME/NH/VT pairs | 13.0 | as found |
| `v130_joint_anchor.R` | v13.0 joint re-anchor of dominant-height and BA increment | 13.0 | as found |
| `v131_hier_assembly.R` | v13.1 hierarchical mortality plus pooled management effect, fast glmer go/no-go | 13.1 | as found |
| `v131_hier_fit.R` | (code) glmer cloglog mortality fit on the v13.1 fit set, balanced managed/background sample | 13.1 | as found |
| `v131_loro.R` | (code) Leave-one-region-out glmer mortality comparison, hierarchical against capped | 13.1 | as found |
| `v131_brms_fit.R` | v13.1 full Bayesian hierarchical mortality plus management fit (brms/cmdstanr) | 13.1 | as found |
| `v131_growth_assembly_fit.R` | v13.1 growth-scale hierarchical management fit (lmer go/no-go) | 13.1 | as found |
| `v131_growth_brms.R` | v13.1 growth-scale brms fit on gross survivor BA increment | 13.1 | as found |
| `v131_mort_ingrowth_refit.R` | v13.1 refit: hierarchical mortality plus ingrowth (brms), management dropped from mortality | 13.1 | as found; v2 is `phase3/v131_mort_ingrowth_refit_v2.R` |
| `v131_mort_repair.R` | (code) brms mortality fit on a balanced subsample | 13.1 | as found; first of three repair variants |
| `v131_mort_repair_v2.R` | Mortality brms repair v2, faster sampler settings | 13.1 | variant copy |
| `v131_mort_repair_v3.R` | Mortality brms repair v3, drops the unidentified region management slope | 13.1 | variant copy |

## Validation, benchmark and diagnostic harnesses

| File | What it does | Era or version | Status |
|---|---|---|---|
| `annual_increment_stress.R` | Stress test on annual increment (BA, volume) by region and projection length for 12.5.0, 12.7.0 and OSM | 12.5.0 to 12.7.0 | as found |
| `cardinal_v130_smoke.R` | Smoke test on Cardinal: base model against candidate V130, 10 stands, 10 yr, pass if all finite | 13.0 | as found |
| `comprehensive_bench.R` | Comprehensive independent benchmark on MagPlot QC+NB, all metrics on FIA NSVB, level and PAI | 12.7.0 / 12.7.1 | as found |
| `comprehensive_bench_coupled.R` | Same header as `comprehensive_bench.R`; adds precomputed coefficient vectors | 12.7.0 / 12.7.1 (same header) | variant copy |
| `comprehensive_bench_v129.R` | Same header; model file defaults to 12.7.1 (code) | 12.9 [from name] | variant copy |
| `comprehensive_bench_v129b.R` | Same header | 12.9 [from name] | variant copy |
| `comprehensive_bench_v129c.R` | Same header; reads `v129_ecobucket_fortype.csv` | 12.9 [from name] | variant copy |
| `comprehensive_bench_v129d.R` | Same header; reads `v129_gate3.csv`; parent of `phase2/bench_species_comp_frozen.R` | 12.9 [from name] | variant copy |
| `ddbh_diag.R` | Diameter increment diagnosis of the Maine long-horizon BA over-prediction, by region, species, size, RD | not stated | as found |
| `decomp_obs.R` | Decomposes observed annual BA dynamics into growth, mortality and ingrowth by region | not stated | as found |
| `fia_recent_v1270.R` | Recent (2010 on) Maine FIA independent benchmark of 12.7.0 on annual increment | 12.7.0 | as found |
| `fia_recent_v1271.R` | Same benchmark for 12.7.1 | 12.7.1 | as found |
| `fia_recent_v129.R` | Header still names 12.7.1; model file from `MODEL_FILE` | 12.9 [from name] | variant copy |
| `fia_recent_v129d.R` | Same header as `fia_recent_v129.R` | 12.9 [from name] | variant copy |
| `fia_remeas_stress.R` | Remeasured Maine FIA stress test: site input crossed with MORTCAL, bias by horizon | 12.3.9 | as found |
| `four_way_scorecard.R` | Four-model scorecard (12.5.0, 12.7.0, 12.7.1, OSM 2.26.1), bias, RMSE, NSE, PAI bias | 12.7.x | as found |
| `full_metric_score.R` | Comprehensive metric validation of 12.7.0 (ESI v8) on the NB/NS/ME regional set | 12.7.0 | as found |
| `gsa_v1261.R` | Global sensitivity analysis of 12.6.1, Latin hypercube, 50 yr projection | 12.6.1 | as found |
| `htpred_csi_vs_esi.R` | Legacy CSI against ESI inside the HTPred height equation, no refit, 28 June 2026 | 12.3.10 | as found |
| `magp_qcnb_vol.R` | MagPlot QC+NB benchmark of 12.7.0 in the Hennigar 2018 frame, merch volume increment | 12.7.0 | as found |
| `magplot_v1270.R` | MAGPlot NB validation of 12.7.0 on the new-contract API, BA/TPH/QMD | 12.7.0 | as found |
| `redteam_cv2.R` | Red-team CV v2: corrected SITE join, absolute MAE, LOIO, leave-one-province, managed split-half | not stated | as found |
| `redteam_diag.R` | Diagnoses the Wfull.rds against published management scorecard discrepancy | not stated | as found |
| `redteam_nsvb_traj.R` | Red team: NSVB emulator spot check, planted-modifier plateau, gate-off smoke test | not stated | as found |
| `run_region.R` | Projects NB/NS/ME intervals under a v12.6.x config and scores volume and value | 12.6.x | as found |
| `run_v126.R` | Long-horizon driver; header still titled `run_acadiangy_long_v16_v125.R` (12.5.0, v16 CFI pairs, env parameterized) | 12.5.0 / 12.6 | as found; derived by `make_run_v126.R` |
| `score_headtohead.R` | Head-to-head of 12.7.0, 12.7.1 and OSM on identical MagPlot pairs, FIA NSVB | 12.7.x | as found |
| `score_region.R` | Regional predicted against observed on BA, TPA, QMD, sawlog, pulp, value | not stated | as found |
| `score_v126.R` | Scores v12.6 CFI stress runs by horizon plus the 12.5.0 regression check | 12.6 | as found |
| `scorecard_clean.R` | Clean single-merge scorecard keyed by STAND, TOST and forest type | not stated | as found |
| `scorecard_enhance.R` | Enhanced scorecard: TOST and forest type, five models, v12.9.x final (pass 2) | 12.9.x | as found |
| `scorecard_v1210.R` | Five-way scorecard including v12.10.1 (robust additive release) | 12.10.1 | as found |
| `smoke1210.R` | (code) Sources 12.10.1 and prints management modifier defaults, then a short projection | 12.10.1 | as found |
| `smoke1270.R` | (code) Sources 12.7.0 and runs a 10 yr projection with the ESI dominant-height anchor on | 12.7.0 | as found |
| `topht_recal_diag.R` | ESI-consistent dominant-height anchor recalibration diagnostic (top height over-predicted NB +7, QC +13 percent) | 12.7.0 (code reads `cb_v1270_results.csv`) | as found |
| `v12101_domain_scorecard.R` | v12.10.1 operational-domain re-scoring, a mask on the frozen config, no equation change | 12.10.1 | as found |
| `v130_score_gate.R` | v13.0 scoring and gate against shipped v12.10.1 on the multi-dimensional scorecard | 13.0 | as found; v2 is `phase2/v130_score_gate_v2.R` |
| `v131r_gate.R` | v13.1 gate after the mortality and ingrowth refit; structural refit, not shipped | 13.1 | as found |
| `region_value_scorecard.csv` | (code) Output table: columns config, region, n, BA, TPA, QMD, sawMBF, pulp, value | not stated | data output |

## OSM comparison runners

| File | What it does | Era or version | Status |
|---|---|---|---|
| `osm_headtohead.py` | Runs OSM-ACD on the identical in-domain MagPlot pairs and dumps its tree list for NSVB scoring | not stated | as found |
| `osm_magp_qcnb.py` | OSM-ACD on MagPlot QC+NB, scored on merch volume increment with the same FF volume function | not stated | as found |
| `osm_magp_run.py` | (code) Builds an OSM sqlite stand list from the MagPlot tree list and runs OSM v2.26.1 | not stated | as found |
| `osm_match_run.py` | (code) Runs OSM v2.26.1 on the Seven Islands (silc_cfi) OSM tree list | not stated | as found |
| `osm_region_run.py` | (code) Runs OSM v2.26.1 on the silc_cfi regional input trees and manifest | not stated | as found |
| `run_osm_compare.R` | Projects 12.6.1 from the OSM starting inventories on Seven Islands stands for a head-to-head trajectory | 12.6.1 | as found |

## Bakuzis assessment and long-horizon trajectories

| File | What it does | Era or version | Status |
|---|---|---|---|
| `bakuzis_allmodels.R` | Per-model long-horizon trajectories on an ESI gradient plus explicit Bakuzis relations for v125, v1270, v1271, v129x | 12.5.0 to 12.9.2 | as found |
| `bakuzis_v1261_traj.R` | 12.6.1 Bakuzis trajectories, even-aged stand across a site gradient to 150 yr | 12.6.1 | as found |
| `bz_rd_test.R` | Self-thinning test: do the RD modifiers steepen self-thinning toward Reineke -1.605 | 12.3.9 | as found |
| `bz_v126.R` | Bakuzis Reineke self-thinning test, 120 yr, five configs | 12.6.0 | as found |
| `bz_v1262_domht.R` | Does the ESI dominant-height constraint separate the Bakuzis site curves | 12.6.2 proto | as found |
| `bz_v1262b.R` | Validates the fitted ESI dominant-height anchor across the ESI gradient, 150 yr | 12.6.2b proto | as found |
| `bz_v1270.R` | Bakuzis trajectory for 12.7.0, anchor on, 150 yr, long format for the Bakuzis check scripts | 12.7.0 | as found |
| `traj1271.R` | 160 yr trajectory for 12.7.1 coupled self-thinning, plateau and oscillation | 12.7.1 | as found |
| `traj_sweep.R` | Self-thinning recalibration sweep of `sdimort.onset` and `sdimort.beta` for 12.7.0 | 12.7.0 | as found |
| `traj_v125.R` | Header text is identical to `traj_v1270.R` (names 12.7.0); its opening code sources 12.5.0 | 12.5.0 | variant copy |
| `traj_v1270.R` | Long-horizon trajectories of 12.7.0 across an ESI gradient to 120 yr | 12.7.0 | as found |
| `traj_v129_seeded.R` | Seeded long-horizon trajectories for v12.9 gated self-thinning (fixes the missing set.seed) | 12.9 | as found |

## Figures and maps

| File | What it does | Era or version | Status |
|---|---|---|---|
| `annual_maps.R` | Annual-increment maps, RMSE and signed bias, 12.5.0 / 12.7.0 / OSM, land-masked | 12.5.0 to 12.7.0 | as found |
| `build_data_maps.R` | Data-description maps of the 705 benchmark stands as a 50 km hex count grid; coordinates stay on Cardinal | 705-stand benchmark | as found |
| `capstone_fig.R` | Modernization capstone: verifies handoff numbers against CSVs, then a 4-panel summary figure | modernization capstone | as found |
| `continuous_maps.R` | Interpolated BA bias and RMSE surfaces, 12.5.0 / 12.7.0 / OSM | 12.5.0 to 12.7.0 | as found |
| `continuous_maps2.R` | Refined surfaces: total volume bias and three-way BA bias, land-masked | 12.5.0 to 12.7.0 | variant copy |
| `continuous_maps3.R` | Corrected bias surfaces from separate predicted and observed surfaces | not stated | variant copy |
| `spatial_bias_map.R` | (code) 0.25 degree grid bias map of BA, QMD, top height, total volume to `acadgy_v1270_spatial_bias.png` | 12.7.0 (code) | as found |
| `fig_125_vs_127.py` | (code) Bar chart of hardcoded percent values, 12.5.0 against 12.7.0, all region and Maine | 12.5.0 / 12.7.0 | as found |
| `fig_3way.py` | MAGPlot NB (262 pairs) predicted against observed percent bias for 12.5.0, 12.7.0, OSM | 12.7.0 | as found |
| `fig_bias_by_attr.py` | (code) Loads Seven Islands results and plots by ME/NB/NS; bias by attribute [from name] | not stated | as found |
| `fig_esi_anchor.R` | (code) ESI-anchored dominant-height site curves from `bz_v1262b_traj.csv` | 12.6.2b proto | as found |
| `fig_increment_diag.R` | Diameter increment diagnosis figure: regional, size-form and density bias | not stated | as found |
| `fig_mort_levers.py` | Maine BA bias under regional mortality levers (270-plot NB/NS/ME set) | not stated | as found |
| `fig_osm.R` | FVS-ACD 12.6.1 against OSM long-term trajectory on matched Seven Islands stands | 12.6.1 | as found |
| `fig_osm.py` | (code) Same comparison plotted from `fvsacd_vs_osm_matched.csv` | not stated | duplicate-looking pair of `fig_osm.R` |
| `fig_region.R` | v12.6.1 regional volume and value figure, bias by region and ingrowth config | 12.6.1 | as found |
| `fig_v126.R` | v12.6 summary figure: CFI bias by config and Bakuzis Reineke slope | 12.6 | as found |
| `fig_version_evo.R` | Version-evolution figure, 12.5.0, 12.6.0, 12.6.1 | 12.5.0 to 12.6.1 | as found |
| `hennigar_figs_robust.R` | Regenerates deck figures F2 and F3 with the robust additive re-fit | 12.10.1 | as found |
| `hennigar_figs_v1210.R` | Hennigar August 2026 deck figures, v12.10, ggplot2, 2 July 2026 | 12.10 | as found |
| `make_hennigar_figs.py` | Hennigar deck figures from the clean scorecard, matplotlib | 12.5.0 to 12.9.x | as found |

## Decks, reports and plans

| File | What it does | Era or version | Status |
|---|---|---|---|
| `build_bench_html.py` | Assembles the self-contained FVS-ACD benchmarking HTML with base64 figures | 12.6 (code: output `AcadianGY_v126_benchmarking.html`) | as found |
| `build_deck_v1210.js` | pptxgenjs deck, FVS-ACD against OSM, Hennigar August 2026, v12.10.1 | 12.10.1 | as found |
| `build_hennigar_deck.js` | pptxgenjs deck, FVS-ACD against OSM Acadian re-derivation for the 18 August 2026 Hennigar meeting | not stated | as found |
| `v130_injection_build_spec.md` | Build recipe for injecting the two fitted v13.0 anchors into the model, 8 July 2026 | 13.0 | as found |
| `v130_phase2_height_redirect_plan.md` | Plan to redirect the fitted height re-anchor onto the `esi.anchor.coef` hook, 10 July 2026, planning only | 13.0 Phase 2 | as found |

## HPC launchers (Cardinal SLURM)

| File | What it does | Era or version | Status |
|---|---|---|---|
| `v130_joint.sbatch` | SLURM job, account PUOM0008, runs `v130_joint_anchor.R` | 13.0 | as found |
| `v131_brms.sbatch` | SLURM job in `~/v13_kickoff`, runs `v131_brms_fit.R` then `v131_loro.R` | 13.1 | as found |
| `v131_refit.sbatch` | SLURM job, runs `v131_mort_ingrowth_refit.R` | 13.1 | as found |

## Data preparation and site inputs

| File | What it does | Era or version | Status |
|---|---|---|---|
| `build_magp_qcnb.py` | Builds MagPlot QC and NB remeasurement pairs and tree lists for the Hennigar-frame benchmark | not stated | as found |
| `chk_si2.R` | (code) Summarizes legacy CSI, ESI and 2030/2060/2090 CSI on `silc_plot_si2.csv` | not stated | as found |
| `eco_join.py` | (code) Joins points to the NA Level III ecoregion shapefile | not stated | as found |
| `eco_join_pairs.py` | (code) Reuses `eco_join.py` to join the MagPlot QC/NB pairs to L3 ecoregions | not stated | as found |
| `eco_join_v2.py` | (code) Same opening as `eco_join.py` | not stated | variant copy [from name] |
| `esi8_manifest.R` | (code) Merges ESI v8 into the regional manifest; writes esi8 and legacy manifests | ESI v8 (code) | as found |
| `esi_coords.R` | (code) Builds `pid_coords.csv` from DBHout for NS, NB, ME plots | not stated | as found |
| `esi_manifest.R` | (code) Merges ESI into the regional manifest and compares with legacy CSI | not stated | as found |
| `extract_esi.py` | (code) Samples `Final_SI_Output.tif` at `pid_coords.csv` to `pid_esi.csv` | not stated | as found |
| `extract_esi8.py` | (code) Samples Acadian ESI v8 240 m raster to `pid_esi8.csv` | ESI v8 (code) | as found |
| `extract_esi8_30m.py` | (code) Same, from the 30 m ESI v8 raster | ESI v8 (code) | variant copy |
| `extract_esi8_magp.py` | (code) Samples ESI v8 30 m at MagPlot NB/NS sites | ESI v8 (code) | as found |
| `extract_esi8_qcnb.py` | (code) Samples ESI v8 30 m at MagPlot QC/NB pair sites | ESI v8 (code) | as found |
| `extract_region.R` | Builds NB/NS/ME remeasurement intervals from DBHout: input trees, observed metrics, manifest | not stated | as found |
| `fia_fortype_ecobucket.R` | Forest type group and ecobucket per recent Maine FIA plot | not stated | as found |
| `ingrowth_magp.py` | Observed ingrowth and mortality rates from MagPlot QC+NB by tree-ID matching | not stated | as found |

## Shared functions and utilities

| File | What it does | Era or version | Status |
|---|---|---|---|
| `HTPred_fun.R` | (code) The `HTPred(SPP, DBH, CSI, CCF, BAL)` height function with species coefficients | not stated | as found |
| `value_fns.R` | Shared volume and stumpage-value functions (approximate Maine 2024 prices) for regional scoring | not stated | as found |

## Subfolders

| Folder | What it holds | Era or version | Status |
|---|---|---|---|
| `bakeoff_v13/` | 4 files: ESI/CSI extraction and dominant-height CV fit on ME/NH/VT plots (see table below) | 13.0 [from name] | as found |
| `phase2/` | 50 files: v13.0 Phase 2 (height redirect, BA-only builds, co-fit, gates), the frozen benchmark harness, and the numbered benchmark figures | 13.0 Phase 2; 12.10.1 frozen benchmark | as found; contains the canonical frozen harness |
| `phase3/` | 3 files: v13.1 refit v2, authored 10 July 2026, not executed | 13.1 | not executed, not shipped (per `phase3_changes.md`) |
| `seven_islands/` | 19 files: Seven Islands (SILC) CFI v25 benchmark, Bakuzis guardrail, stress tests and report builders | 12.3.9; 12.11 and 13.1 (v25) | as found |
| `tools/` | 1 file: builds `docs/preregistrations.md` from `v14.2dev/` | 14.2 | as found |
| `v14.2dev/` | 1,294 files in 11 dated folders: the 14.2 refinement record (PREREG13b to PREREG47, release notes) | Era 9, 26 Sep to 16 Oct 2026 | dated record; no engine file (VERSION_HISTORY Era 9) |
| `versions/` | 15 files: historical engine archive v8.1 to 12.5.0_mortcal plus its README | pre-12.3.6 to 12.5.0 | archive; 7 files byte-identical to root copies |

### bakeoff_v13/

| File | What it does | Era or version | Status |
|---|---|---|---|
| `assemble.R` | (code) Reads CONUS remeasurement pairs, keeps states 23, 33, 50, computes annual diameter growth | 13.0 [from name] | as found |
| `extract_bench.py` | (code) Opens the ESI and ClimateNA SI rasters for point sampling | 13.0 [from name] | as found |
| `extract_esi.py` | (code) Samples `Final_SI_Output.tif` at `ne_plot_coords.csv` | 13.0 | as found; same name as root `extract_esi.py`, different input |
| `fit_cv2.R` | (code) Reads the NE plot table and ESI, filters for top height increment; CV fit [from name] | 13.0 | as found |

### phase2/

| File | What it does | Era or version | Status |
|---|---|---|---|
| `FROZEN_HARNESS_README.md` | How to reproduce the frozen August baseline scorecard from `AcadianGY_12.10.1.r`, and the afac bug | 12.10.1 frozen | reference |
| `run_bench_frozen.sh` | Canonical freeze wrapper for `bench_parity.R`; exports the frozen environment | 12.10.1 frozen | canonical |
| `bench_frozen.sbatch` | SLURM wrapper for `run_bench_frozen.sh` (NB_AFAC 0.579, QC_AFAC 0.111); reproduces `cb_v12101_results.csv` | 12.10.1 frozen | canonical |
| `bench_species_comp_frozen.R` | Benchmark of 12.9.2 on MagPlot QC+NB plus a predicted-ingrowth row; built from `comprehensive_bench_v129d.R` | 12.9.2 frozen basis | as found |
| `comp_frozen.sbatch` | Species-composition-over-time harness on the frozen environment, runs `bench_species_comp_frozen.R` | 12.10.1 frozen | as found |
| `comp_frozen_one.sbatch` | Single-model species-composition harness on the frozen canon | 12.10.1 frozen | as found |
| `species_composition_over_time.R` | Does each model reproduce the observed shift in species composition | 12.10.1 frozen | as found |
| `regen_five_way_scorecard.R` | Regenerates the five-way scorecard on the frozen harness, replacing the stale 3 July scorecard | 12.10.1 frozen | as found |
| `scorecard_fortype_composite_frozen.R` | Nine-metric five-way scorecard by forest type plus weighted composite score | 12.10.1 frozen | as found |
| `scorecard_rmse_frozen.R` | Accuracy and precision extension: RMSE, %RMSE, slope, Robinson and Froese region of equivalence | 12.10.1 frozen | as found |
| `osm_bakuzis_score.R` | Scores OSM on all five Bakuzis relations from a 160 yr OSM run | 12.10.1 benchmark | as found |
| `fig1_scorecard_heatmap.R` | Figure 1, five-way scorecard heatmap with CIs and composite strip | 12.10.1 | R companion |
| `fig1_scorecard_heatmap.py` | Figure 1, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig2_accuracy_by_forest_type.R` | Figure 2, total volume bias by forest type | 12.10.1 | R companion |
| `fig2_accuracy_by_forest_type.py` | Figure 2, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig3_bakuzis_relations.R` | Figure 3, Bakuzis pass and flag matrix by model | 12.10.1 | R companion |
| `fig3_bakuzis_relations.py` | Figure 3, matplotlib renderer (OSM scored on all five relations) | 12.10.1 | duplicate-looking R/py pair |
| `fig4_selfthinning_trajectory.R` | Figure 4, self-thinning as a timing difference | 12.10.1 | R companion |
| `fig4_selfthinning_trajectory.py` | Figure 4, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig5_offsetting_bias.R` | Figure 5, offsetting bias signature in domain (n = 492); the PNG was made by the .py | 12.10.1 | R companion |
| `fig5_offsetting_bias.py` | Figure 5, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig6_managed_oos_bias.R` | Figure 6, managed-cell out-of-sample bias by management class (LOIO) | 12.10.1 | R companion |
| `fig6_managed_oos_bias.py` | Figure 6, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig7_scorecard_by_fortype.R` | Figure 7, forest-type scorecard heatmap; shipped PNG rendered by the .py | 12.10.1 | R companion |
| `fig7_scorecard_by_fortype.py` | Figure 7, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig8_overall_composite.R` | Figure 8, weighted overall composite score by model; shipped PNG rendered by the .py | 12.10.1 | R companion |
| `fig8_overall_composite.py` | Figure 8, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig10_equivalence.R` | Figure 10, observed against predicted equivalence plots, n = 705 | 12.10.1 | R companion |
| `fig10_equivalence.py` | Figure 10, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig11_rmse_scorecard.R` | Figure 11, %RMSE scorecard heatmap | 12.10.1 | R companion |
| `fig11_rmse_scorecard.py` | Figure 11, matplotlib renderer | 12.10.1 | duplicate-looking R/py pair |
| `fig14_acadian_range.R` | Figure 14, geographic range of the FVS-ACD variant; no plot points | 12.10.1 | as found |
| `phase2_run_order.md` | Ordered Cardinal commands to produce and gate the v13.0 candidate | 13.0 Phase 2 | as found |
| `v130_BA_overcorrection_diagnosis.md` | Root cause of the v13.0 BA over-correction (a time-step coding bug), 10 July 2026 | 13.0 Phase 2 | as found |
| `fit_v130_esi_anchor.R` | Derives region `esi.anchor.coef` so the `calc_dht` hook reproduces the v13.0 height increment | 13.0 Phase 2 | as found |
| `fit_v130_esi_anchor_cofit.R` | Iterative co-calibration of `esi.anchor.coef` with the BA correction active | 13.0 Phase 2 | as found |
| `fit_v130_esi_anchor_cofit_v2.R` | Same header as the cofit script | 13.0 Phase 2 | variant copy |
| `bench_parity_v130.R` | One-line modification of `bench_parity.R` reading fitted region coefficients | 13.0 Phase 2 | as found |
| `bench_parity_v130.sh` | Phase 2 run recipe: fit coefficients, build BA-only 13.0, run bench; "DO NOT run here" | 13.0 Phase 2 | as found |
| `bench_parity_v130_bagain.sh` | Test C (milder BA): sed-derived runnable bench | 13.0 Phase 2 | as found |
| `build_v130_baonly.py` | Builds 13.0 from frozen 12.10.1 with only the BA net-increment anchor | builds 13.0 (BA-only) | as found |
| `build_v130_baonly_v2.py` | BA-only builder v2, over-correction fix | builds 13.0 (BA-only) | variant copy |
| `patch_ascale_clamp.py` | Makes the `calc_dht` ascale clamp band environment driven for the co-fit | 13.0 Phase 2 | as found |
| `run_v130_baonly_adopt.sh` | BA-only conservative adoption candidate (cb_v130ba); height re-anchor deferred | 13.0 Phase 2 | as found |
| `v130_baonly_adopt.sbatch` | SLURM wrapper for `run_v130_baonly_adopt.sh`; builds `AcadianGY_13.0_baonly.r` from 12.10.2 | 13.0 Phase 2 | as found |
| `v130_blendsweep.sbatch` | "Narrow fix": blends Test B height re-anchor toward identity and sweeps the weight | 13.0 Phase 2 | as found |
| `v130_cofit.sbatch` | Co-calibration of `esi.anchor.coef` with BA correction active, then bench and gate | 13.0 Phase 2 | as found |
| `v130_cofit_v2.sbatch` | Test B: widen the QC ascale clamp and rerun the hardened co-fit | 13.0 Phase 2 | as found |
| `v130_milderBA.sbatch` | Test C (milder BA); "DO NOT run here" | 13.0 Phase 2 | as found |
| `v130_score_gate_v2.R` | Same header as root `v130_score_gate.R` | 13.0 Phase 2 | variant copy |

### phase3/

| File | What it does | Era or version | Status |
|---|---|---|---|
| `phase3_changes.md` | What changed in the v13.1 refit v2 and why (ingrowth casing crash and more) | 13.1 | not executed, not shipped |
| `v131_mort_ingrowth_refit_v2.R` | v13.1 refit v2, hierarchical mortality plus ingrowth (brms) | 13.1 | variant of root `v131_mort_ingrowth_refit.R` |
| `v131_refit_v2.sbatch` | SLURM job, runs `v131_mort_ingrowth_refit_v2.R` | 13.1 | as found |

### seven_islands/

| File | What it does | Era or version | Status |
|---|---|---|---|
| `bakuzis_v13x_traj.R` | Parameterized Bakuzis trajectory and relations harness for the v13.x candidates, selected by MODEL_TAG | v13.x candidates | as found |
| `g2_bakuzis_v131_traj.R` | Guardrail 2 (Bakuzis five relations) for the v12.11 lever configuration against its base | 12.11 | as found |
| `g2_bakuzis_v131.sbatch` | SLURM job, runs `g2_bakuzis_v131_traj.R` | 12.11 (per the script it runs) | as found |
| `build_unified_treelist_v25.R` | Assembles the v25 unified tree lists, retiring the SILC73 partial rerun | v25 | as found |
| `ingest_fvsacd_v1211_full137.R` | v25 full-coverage ingest of the v12.11 rerun (120 of 137 plots) | 12.11, v25 | as found |
| `ingest_fvsacd_v131_full137.R` | v25 ingest of the v13.1 hierarchical-posterior rerun | 13.1, v25 | as found |
| `ingest_fvsacd_v131_ship18_full137.R` | v25 ingest of the v13.1 ship18 rerun | 13.1 ship18, v25 | as found |
| `equivalence_test_v25.R` | v25 bootstrap equivalence (TOST), seven models | v25 | as found |
| `equivalence_plot_v25.R` | v25 equivalence plots | v25 | as found |
| `value_silcspec_v25.R` | v25 volume and stumpage value scorecard on Seven Islands merch specs | v25 | as found |
| `stress_cfi_extrap_v25.R` | v25 extrapolation stress test for the full-coverage candidates | v25 | as found |
| `v25_stress_coverage_check.R` | Reconstructed per-model data-QC coverage check (source of the v24 file not found) | v25 | as found |
| `build_v25_report_figs.R` | v25 report figures adding the full-137 reruns | v25 | as found |
| `build_xlsx_v25.R` | (code) Reads the v25 scorecards and writes a workbook with openxlsx | v25 | as found |
| `fix_docx_style.py` | (code) python-docx cell border helpers; docx style fix [from name] | v25 [from name] | as found |
| `extract_silc_si.R` | (code) Extracts legacy CSI and ESI at SILC plot coordinates with terra | not stated | as found |
| `stress_cfi_site.R` | Site-driver stress test: flat CSI, legacy SI, ESI, scored on BA/TPA/QMD | 12.3.9 | as found |
| `stress_cfi_horizon.R` | Site-driver stress test, long-horizon and by-horizon bias | 12.3.9 | as found |
| `stress_cfi_climate.R` | Site-driver climate panel with 2030/2060/2090 CSI | 12.3.9 | as found |

### tools/

| File | What it does | Era or version | Status |
|---|---|---|---|
| `build_prereg_index.py` | Builds `docs/preregistrations.md` from `v14.2dev/`, skipping PREV files | 14.2 | as found |

### versions/

Per `versions/README.md`, the historical and intermediate engine lineage, committed for provenance, model source only.

| File | What it does | Era or version | Status |
|---|---|---|---|
| `README.md` | Index of this archive and the version evolution note | archive | reference |
| `AcadianGYv8.1.r` | Early archived version; ran on the Seven Islands cross-version benchmark | v8.1 | archive |
| `AcadianGYv9.6.r` | Cleanest pre-v12 run on Seven Islands (BA +17 percent) | v9.6 | archive |
| `AcadianGYv10.8.r` | Archived; older SPP.func rejects some v12 species | v10.8 | archive |
| `AcadianGYv11.1.r` | Archived | v11.1 | archive |
| `AcadianGYv12.1.2.r` | Early v12 line | v12.1.2 | archive |
| `AcadianGYv12_3_0.r` | v12.3 series start | v12.3.0 | archive |
| `AcadianGYv12_3_2.R` | v12.3 series | v12.3.2 | archive |
| `AcadianGYv12_4_1.R` | v12.4 series | v12.4.1 | archive |
| `AcadianGY_12.3.6.r` | v12.3 refinement line (HRF / Seven Islands work) | 12.3.6 | duplicate: byte-identical to root copy |
| `AcadianGY_12.3.7.r` | v12.3.7 | 12.3.7 | duplicate: byte-identical to root copy |
| `AcadianGY_12.3.8.r` | acd_divergence investigation (fvs-modern) | 12.3.8 | duplicate: byte-identical to root copy |
| `AcadianGY_12.3.9.r` | v12.3.9 | 12.3.9 | duplicate: byte-identical to root copy |
| `AcadianGY_12.5.0.r` | Production refactor baseline | 12.5.0 | duplicate: byte-identical to root copy |
| `AcadianGY_12.5.0_mortcal.r` | MORTCAL empirical BA-corrector variant | 12.5.0 + MORTCAL | duplicate: byte-identical to root copy |

## v14.2dev/ (dated 14.2 refinement record)

VERSION_HISTORY Era 9: no engine file was added; the studies ran against the 14.1 benchmark record and changed no engine file, coefficient or default of 14.1. PREREG46 and the PREREG47 reading ran on October 26, 2026 (`2026-10-26/`). Each row below is one subfolder; the description is the first heading of its result, plan, README or notes file.

| Folder | What it does | Era or version | Status |
|---|---|---|---|
| `2026-09-26/pass29/` | Pass 29 (MNAP and TNC reserve frames) bundle, per its README.txt | 14.2 | record |
| `2026-09-26/pass29b/` | PREREG13b: pass 29b, MNAP split by owner | 14.2 | record |
| `2026-09-26/prereg14/` | PREREG14 steps 1 and 2: height level, volume and increment measurement study | 14.2 | record |
| `2026-09-26/prereg15/` | PREREG15: 14.1 as shipped on the pass 29b MNAP frames, with amendment r1 | 14.2 | record |
| `2026-09-26/v142htf/` | (code) PREREG11 step 1 height fix: fit of the NS height increment decay m(D) on fold A sites, with Cardinal and firebreather runners | 14.2 | record |
| `2026-09-27/prereg16/` | Symmetric height convention for benchmark volume scoring | 14.2 | result |
| `2026-09-27/prereg17/` | NS ingrowth multiplier under threshold matching, scored under C1 | 14.2 | result |
| `2026-09-28/prereg18/` | NS ingrowth multiplier refined between 1.5 and 2.25 on a held out volume criterion | 14.2 | result |
| `2026-09-28/prereg19/` | QC height anchor (QC_AFAC) recalibration scored under C1 | 14.2 | result |
| `2026-09-28/prereg20/` | A flatter NS height increment correction for trees 25 cm and over | 14.2 | result |
| `2026-09-28/prereg21/` | Why MNAP State model heights run tall | 14.2 | result |
| `2026-09-29/prereg22/` | The PREREG20 NS height form paired with the PREREG18 ingrowth setting | 14.2 | result |
| `2026-09-29/prereg23/` | QC height anchor refit on tag height increment (QC_AFAC 1.061) | 14.2 | result |
| `2026-09-29/prereg24/` | (code) Why QC stems run low and QMD runs high; diagnostic only, no model run | 14.2 | record |
| `2026-09-29/prereg25/` | NS small tree height increment below 12.7 cm is a plot program effect | 14.2 | result |
| `2026-09-30/prereg26/` | Bakuzis NS grid for the 14.2 candidate NS configuration v141LTfi | 14.2 | result |
| `2026-09-30/prereg27/` | NS long interval stem deficit is survivor loss; no interval ingrowth term | 14.2 | result |
| `2026-09-30/prereg28/` | Size dependent QC height anchor | 14.2 | result |
| `2026-09-30/prereg28b/` | QC height anchor changed for trees below 25 cm only, 0.111 kept for large trees | 14.2 | result |
| `2026-09-30/prereg29/` | What distinguishes NS_RS stands, and the PREREG20 height form refit on NS_OP | 14.2 | result |
| `2026-09-30/prereg30/` | NS long interval end of interval height and top height, v141LTf and v141LTfi against 14.1 | 14.2 | result |
| `2026-09-30/prereg31/` | Bakuzis QC grid for the QC height anchor candidate p28b_small | 14.2 | result |
| `2026-09-30/prereg32/` | Empty observed t2 stands in nb_c and three other sets | 14.2 | result |
| `2026-10-01/prereg33/` | QC height anchor reassigned from current DBH every annual step | 14.2 | result |
| `2026-10-01/prereg34/` | ns_long_fl 10 to 19 year height deficit, v141LTf against 14.1 | 14.2 | result |
| `2026-10-01/prereg35/` | Scorer revision r2 with defect, exclusion and stratum checks | 14.2 | result |
| `2026-10-01/prereg36/` | QC C2 tag identity and adoption of scorer r2 | 14.2 | result |
| `2026-10-01/prereg37/` | Structure of the 14.1 QC height increment behind the size dependent anchor | 14.2 | result |
| `2026-10-01/prereg38/` | A single QC height anchor refit on MAGPlot field tags | 14.2 | result |
| `2026-10-01/release-notes/` | 14.2 release notes for PREREG16 to PREREG37, with PREV drafts | 14.2 | draft; contains PREV copies |
| `2026-10-02/prereg39/` | Decomposing the TOPHT gate against the tag dominant cohort | 14.2 | result |
| `2026-10-02/prereg40/` | A TOPHT gate on measured heights for the frozen PREREG38 arms | 14.2 | result |
| `2026-10-02/prereg41/` | Bakuzis QC grid for the field tag QC anchor p38_fit | 14.2 | result |
| `2026-10-02/prereg42/` | Erratum for the row index height gates of PREREG23, 28, 28b and 33, PREREG19 revision 3, and the QC anchor closeout with 0.111 kept | 14.2 | result |
| `2026-10-02/release-notes/` | 14.2 release notes for PREREG16 to PREREG42, with build and trace scripts | 14.2 | draft; contains PREV copies |
| `2026-10-05/notes_20261005/` | FIA tree length measurement quality objective: confirmation record | 14.2 | record |
| `2026-10-05/notes_20261005b/` | 14.2 release notes for PREREG16 to PREREG44 | 14.2 | draft |
| `2026-10-05/notes_20261005c/` | 14.2 release notes for PREREG16 to PREREG45 | 14.2 | draft |
| `2026-10-05/notes_20261005d/` | 14.2 release notes for PREREG16 to PREREG45b | 14.2 | draft |
| `2026-10-05/prereg43/` | Provenance of the shipped 14.1 QC height anchor QC_AFAC 0.111 | 14.2 | result |
| `2026-10-05/prereg44/` | Bakuzis QC grid from measured stand lists, 1.242 against 0.111 | 14.2 | result |
| `2026-10-05/prereg45/` | A relative height multiplier for the QC height increment (revision 2) | 14.2 | result |
| `2026-10-05/prereg45b/` | A relative height multiplier for the NB height increment, stand level | 14.2 | result |
| `2026-10-11/` (README, roadmap) | PREREG46 registered, PREREG47 to 49 drafted; refinement roadmap after PREREG45 (draft) | 14.2 / 14.3 | registered, not run |
| `2026-10-11/prereg46/` | A QC height increment multiplier with a zero in relative height, for 14.3 | 14.3 | registered; run October 26 in `2026-10-26/prereg46/` |
| `2026-10-11/drafts/` | PREREG47 draft 1 (superseded), PREREG48 and PREREG49 drafts, not registered | 14.3 | draft |
| `2026-10-15/prereg47/` | Absolute Bakuzis gates for QC on the measured stand list grid, revisions 1 to 5 | 14.3 | registered; read October 26 in `2026-10-26/prereg47/` |
| `2026-10-16/release-notes/` | 14.2 release notes, revision e, for PREREG16 to PREREG45b and the October 16 cross-version benchmark | 14.2 | superseded by revision f (`2026-10-26/release-notes/`) |
| `2026-10-26/prereg46/` | PREREG46 run: qc_lz only after the qc_ez rule 1 fit stop, RESULT, deviations D0 to D5, red team records | 14.3 | RESULT: no candidate |
| `2026-10-26/prereg47/` | PREREG47 thresholds and reading r1 over qc141, p38_fit, qc_rh and qc_lz, RESULT | 14.3 | RESULT: every arm not credible on the long run |
| `2026-10-26/acdx_arms/` | 14.2 arms p38_fit and qc_rh on the three Maine acdx frames (Cardinal), identity checks against 14.1 | 14.2 | identical to 14.1 |
| `2026-10-26/zenodo_190/` | drivers and logs of the Zenodo 1.9.0 publication | deposit | published 10.5281/zenodo.23665173 |
| `2026-10-26/zen1100/` | packaging and 1.10.0 staging scripts | deposit | staged, not published |
| `2026-10-26/release-notes/` | 14.2 release notes, revision f, adding PREREG46, the PREREG47 reading and the 14.2 arms on the Maine frames | 14.2 | current release notes (VERSION_HISTORY Era 9) |
| `2026-10-26/prereg48/` | PREREG48 revision 1, registered October 26 on the laptop copy; second arm frozen qc_rh | 14.3 | registered, not run |

## Notes for readers

The engine tags inside several files do not match their filenames (for example 12.6.0 to 12.7.0 carry `AcadianV12.5.0`, the 13.0 files carry `AcadianV12.10.1`). VERSION_HISTORY records the 14.0.3 and 14.0.4 tags the same way. The filename, not the tag, is what VERSION_HISTORY and the md5 records cite. `VERSION_HISTORY.md` also cites `scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R`; no `phaseD/` folder exists on this branch.
