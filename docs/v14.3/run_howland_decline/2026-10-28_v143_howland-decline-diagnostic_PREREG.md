# Pre-registration: Howland decline diagnostic, for 14.3

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine. Written 28 October 2026 on OSC Cardinal in `~/howland_decline_20261028/`. Registered when the md5 of this file and the time are written to `logs/prereg_md5.txt`, before any script that reads an outcome of this study runs. Nothing here changes any release; it informs 14.3. Every open choice takes the recommended option, as pre-approved.

## 1. Background and what is already known

The 93 DigiSylva 2.0 Howland Research Forest plots (live trees of 10 cm DBH and larger, 250 m² plots, unmanaged) were projected 50 yr at ESI 12, 15 and 18 m. Frozen outcomes already read before this plan (so they are not predictions of this study): at ESI 15, biomass change by year 50 is −11.0% under 14.0.4 L2 and −8.3% under 14.1 (L on), +8.3% under 13.1h after an early drop, and about +30% under 12.3.6 (Jenkins AGB, CSI); basal area falls from 41.5 to about 31 m² ha⁻¹ under 14.x and 55 to 67 of 93 plots lose biomass (sources: `~/howland_xver_20261026/fig/2026-10-26_howland-fvsacd-crossversion_table.csv`; `results/howland_20261023/v141L_summary.csv` inside `~/fvsacd_fetch_20261026/howland_20261023_from_8b6b670_DATA.tgz`).

Facts about the inputs established before registration from input files only (no outcome of this study read):

1. `howland_tree_t2.csv` is not a remeasurement. The frozen input builder (`v141_check/build_inputs.R`, the heredoc in `howland_v141_array.slurm`) writes it as a copy of the initial tree list with YEAR set to 2075, and the pairs frame gives every stand a 50 yr interval from 2025 to 2075.
2. In DigiSylva `trees.tab` every one of the 93 Howland plots carries exactly one measurement year (2024, 2025 or 2026). The 12 DBH_2010 to DBH_2026 columns are complete for every row, never decrease, and carry values for the 60 snags; the ratio (DBH_2012 − DBH_2010)/(DBH_2013 − DBH_2012) has median exactly 2, which is a constant annual increment. These columns are a reconstruction, not repeat measurements, and contain no mortality or ingrowth.
3. The "repeat ALS" statement in the 23 October README cites no source. A candidate source is on Cardinal: the ORNL DAAC 2490 version 2 maps (Wei et al. 2026, Aboveground Biomass Maps for Howland Research Forest, Maine, 2012 to 2025, doi:10.3334/ORNLDAAC/2490; `HRF_v2maps/Howland_AGB_*.tif`, guide.txt) and the independent reproduction `HRF_v2maps/repro_out/summary.json` (map means and trend rate in Mg C ha⁻¹). Whether it is the README's source cannot be confirmed; it will be reported as the located candidate.
4. The engines contain no random number calls (grep of the 13.1, 14.0.4, 14.1 and b0b1b2 files), so byte identical reproduction is expected if the harness is right.

## 2. Questions

Q1. Decompose the 14.1 50 yr biomass change into survivor growth, mortality and ingrowth, per year and cumulative, with plot bootstrap intervals, and compare with 13.1h and 14.0.4 L2 on the same runner.

Q2. Hindcast 14.1, 14.0.4 L2 and 13.1h against the observed Howland remeasurement, with the cross-version benchmark metrics. Gated (G0 below).

Q3. Is the projected 14.1 decline driven by the linked mortality lever (the 14.0.x stand decrement) or by diameter growth, tested with switches that already exist in the runner and engine. Diagnostic arms only, never adopted.

## 3. Arms

All arms use the 279 stand rows (93 plots by three ESI values) of the frozen v141L inputs read in place (md5s checked against `~/howland_xver_20261026/logs/input_md5s.txt`), 50 yr, through `scripts/2026-10-28_hd_runner.R`. That runner is the frozen long200 runner (md5 3d05cbad) with one header comment and one changed line, the hooks source, which points at `scripts/2026-10-28_hd_trajhooks_fx.R`: the frozen hooks file byte for byte followed by an appended block that wraps the hook functions, calls each frozen function first and then records per year biomass fluxes to `<prefix>_flux.csv`. The build script verifies both facts and refuses otherwise. Launcher: `scripts/howland_decline_array.slurm`, a copy of `howland_xver_array.slurm` (the frozen file is not edited), 60 tasks, 6 arms by 10 chunks of 28 stand rows.

| Arm | Role | Environment |
|:--|:--|:--|
| v141L | reference, 14.1 L on | as `howland_v141_array.slurm` of 23 October: 14.0.4 L2 engine plus 14.1 overlay, LSDG_V141=1, THIN_V141=0 |
| v141off | reference, 14.0.4 L2 | as the v141off branch of `howland_xver_array.slurm` |
| v131h | reference, 13.1h | as the v131h branch of `howland_xver_array.slurm` |
| d141L_linkoff | diagnostic | v141L with LINKED=0: the linked three stage mortality is off, so the runner's existing non-linked path applies (13.1 base mortality with the SDImax self-thinning block, onset 0.55) |
| d141L_L1 | diagnostic | v141L with LINKED_MODE=L1: the mortality floor hazard applies only where top height increment is not positive, instead of as a minimum everywhere (L2) |
| d141L_nocon | diagnostic | v141L with NOCON=1 and the LEV3 variables unset: the Chapter 10 stand basal area increment constraint on survivor diameter increment is disabled (the runner's existing P6 switch) |

No engine file, coefficient or default of 14.1 is edited, L and T are not re-estimated, and no diagnostic arm is a candidate for release. Logs and per stand outputs carry stand names and are named `_SERVERONLY`; only identifier free aggregates leave the server.

## 4. Flux definitions (Q1)

For each stand and projection year, with e the expansion factor (stems ha⁻¹), b the runner's NSVB aboveground dry biomass per stem (Mg), and l the indicator of a live stem at or above the scoring threshold (5 cm, the runner's SCORE_MINDBH_OBS): survivor growth G = Σ e₂(b₂l₂ − b₁l₁) over stems present at the start of the year, split into the initial cohort and earlier recruits; mortality M = Σ (e₁ − e₂)b₁l₁; ingrowth I = biomass of stems new in the year at or above the threshold. Then B_end − B_start = G − M + I exactly. Survivor growth includes the step change from imputed to engine heights in the first year, because the runner's biomass does. Units Mg ha⁻¹ yr⁻¹ (annual) and Mg ha⁻¹ (cumulative).

## 5. Statistics

Plot bootstrap: the 93 plots are resampled with replacement, B = 2000, seed 20261028, the same draws for every arm and ESI (paired), percentile 95% intervals of the mean. Only stands that ran (RUN_OK = 1) in all six arms are used, and their count is reported. Percent biomass change is 100 (mean B_t / mean B_0 − 1), the definition of the 26 October table.

## 6. Decision rule, applied in this order

Step 1, harness. H1: for each reference arm and each of the 10 chunks, the seven frozen output kinds (results, traj, pd_t1, pd_t2, pred_t2_tree, pred_yr1_tree, t1_split_tree) must be md5 identical to the frozen files (v141L: `v141_check/out/`, OSC job 15795712; v141off and v131h: `~/howland_xver_20261026/out/`, job 15888501), 210 comparisons, tolerance zero (provenance: the task instruction to reproduce exactly). The overlay counter files carry their own path and are not compared. H2: in every arm the flux identity residual, the year to year continuity of B, and the difference between the flux biomass and the trajectory BIOMASS at years 0, 5, ..., 50 are all at most 1e-6 Mg ha⁻¹, and no tree identifier is duplicated within a stand year [choice, no record]. If H1 or H2 fails, that is the outcome: the aggregates are still written but labelled not interpretable, no Q1 or Q3 attribution is issued, and nothing is tweaked to pass.

Step 2, hindcast (Q2). Gate G0: an observed remeasurement must exist, meaning at least one Howland plot with more than one field measurement year and a t2 tree list that is not a copy of t1. Given facts 1 and 2 above, G0 is expected to fail; the assembly re-derives it from the files and records it. If G0 fails, the registered verdict for all three versions is NOT SCOREABLE, no bias, equivalence or mortality and ingrowth rate is computed against the placeholder t2, and the reconstructed DBH series are not used as observations, because they are a model output without mortality or ingrowth. The tolerances that would have applied are those of the cross-version benchmark (`docs/benchmarks/2026-10-16_cross-version/README.md` and `2026-10-16_acdx_analyze_r1.R`: bias 100 (mean predicted / mean observed − 1) with a 95% stand bootstrap interval; equivalence of observed on predicted with the intercept region ±25% of the observed mean and the slope region 1 ± 0.25 on 90% bootstrap intervals). If G0 unexpectedly passes, no hindcast is run in this study; that would be a new registration. The figure panel planned for the hindcast is replaced by the Q3 panel.

Step 3, attribution. Q1 rule: for the contrast 14.1 (v141L) minus 13.1h at ESI 15, cumulative to year 50, each component's contribution to the difference in net change (survivor growth, minus mortality, ingrowth) is divided by that difference; the decline is attributed to the component with the largest share if that share is at least 0.5 [choice, no record]; otherwise no single component is named. The contrasts v141off minus v131h and v141L minus v141off are reported in the same form. Q3 rule: at ESI 15, the share of the v141L decline removed by a diagnostic arm is S = (Δ_arm − Δ_ref) / |Δ_ref|, with Δ the year 50 percent change. The decline is attributed to the linked mortality lever if S(linkoff) ≥ 0.5 and S(linkoff) > S(nocon), to the diameter growth constraint if S(nocon) ≥ 0.5 and S(nocon) > S(linkoff), and otherwise to neither alone [threshold 0.5, choice, no record]. The L1 arm is reported as the floor sub-component of the lever, without a verdict. ESI 12 and 18 are reported, not ruled on.

## 7. Descriptive context, no verdict

The ALS map means and trend rate from `repro_out/summary.json` are set beside each reference version's mean annual net biomass change over projection years 1 to 13 at ESI 15, converted with a carbon fraction of 0.5 [choice, no record]. The periods do not overlap (ALS 2012 to 2025, projections start 2024 to 2026), the map is wall to wall at 10 m and mixes leaf on and leaf off sensors, and the engine biomass is NSVB, not the Jenkins based field AGB the maps were trained on. This is context only.

## 8. Outputs

`agg/` (identifier free CSVs, screened for HL_, HOWLAND__, STAND, PLT_CN, LAT, LON and em dashes), `fig/2026-10-28_howland-decline_fig.png` and `.pdf` (a: cumulative survivor growth, mortality, ingrowth and net change over 50 yr by reference version at ESI 15 with 95% bands; b: biomass change of v141L and the three diagnostic arms with bands), `2026-10-28_v143_howland-decline-diagnostic_RESULT.md`, `DEVIATIONS.md`. Script md5s go to `logs/launch_md5s.txt` before the array starts; the assembly md5 is in the same file before it runs.

## 9. Red team pass (fresh re-read of sections 1 to 8) and the fixes made

1. The Q1 rule is a contrast, not an absolute cause. Within one version the net change is G − M + I and a negative net only says M exceeds G + I, so a share of a decline is not defined inside a version. Fix: the rule is stated on the contrast with 13.1h (the version that gains on the same runner), and the RESULT must say that the shares explain why 14.1 differs from 13.1h, not why 14.1 loses biomass in an absolute sense. Shares may exceed 1 or be negative when components offset; the rule (largest share, at least 0.5) is still defined, and offsetting components are reported, not hidden.
2. LINKED=0 is not "no mortality". It swaps the linked system for the runner's existing non-linked path. Fix: S(linkoff) is interpreted as the decline removed by replacing the lever with the 13.1 base mortality and SDImax self-thinning, and the RESULT says so.
3. NOCON. The runner labels it "Ch10 BA CONSTRAINT DISABLED" and implements it by setting the activation fractions to 5; this study relies on that label and on the runner code, and does not verify inside the engine that the constraint never activates. Stated as a limit.
4. H1 can fail for a reason unrelated to the engine: the frozen v141L launcher did not unset environment variables, so a variable set in the submitting shell on 23 October would not be reproduced. If H1 fails for v141L only, that is still a harness failure under the rule; the max numeric difference per file is written to help diagnosis, and nothing is rerun to pass.
5. The brief asked for a figure panel of hindcast observed against predicted. It cannot be drawn without observations (G0). The replacement by the Q3 panel is a departure from the brief, so it is listed in DEVIATIONS as well as here.
6. Bootstrap intervals of shares can be unstable when the denominator is near zero. At ESI 15 the frozen net changes put the 14.1 minus 13.1h difference near −30 Mg ha⁻¹, far from zero, so the percentile intervals are reported as computed, with no trimming.
7. Identifier handling in this study before registration: one scouting command printed the first two data rows of the pairs file, which carry two Howland plot keys, to the session transcript. No file outside the server holds them. Recorded in DEVIATIONS.
8. Checked and unchanged: chunk boundaries match the frozen runs (28 rows, 10 chunks, 279 rows); TIMELIM 20000 as frozen; the flux block cannot alter outputs, because it runs after each frozen hook and writes only to its own environment, and any error in it would fail a stand and so fail H1, which is the intended detection.

The registered md5 is of this file including section 9.
