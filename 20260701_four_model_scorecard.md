# Four-model growth-and-yield scorecard: v12.5.0, v12.7.0, v12.7.1, OSM v2.26.1

*1 July 2026. Multi-dimensional scorecard (GY_model_evaluation_scorecard.md framework) applied to all four
candidate Acadian growth-and-yield models on the identical independent in-domain data: MagPlot NB (n=355)
and ESI-covered QC (n=378), recent Maine FIA (n=788 post-2010 remeasurements), all volume and biomass on
FIA NSVB via the shared emulator. Built toward the August 2026 Hennigar presentation. Plaintext math, no
em dashes. Coordinates stay on Cardinal; only aggregates appear below.*

## OSM version used

Checked the OSM-Contributors GitHub org (github.com/OSM-Contributors) and forusresearch.com/downloads/osm.
Result: v2.26.1, dated 12 May 2026, is the latest release; it matches the locally staged version exactly, so
no version change was needed. The GitHub org has only two public repos (a profile README and an issue
tracker); the engine itself is distributed as signed binaries under LGPL v3, not as a public source
repository, so a git clone of the engine is not available regardless of version. This scorecard therefore
uses OSM v2.26.1 throughout, confirmed current as of the reporting date. Open item: re-check
forusresearch.com/downloads/osm periodically, since a new release would not appear on GitHub.

## Models scored

- **v12.5.0**, the current operational and production AcadianGY version (no ESI, no NSVB, no coupled
  self-thinning).
- **v12.7.0**, the ESI v8 and NSVB modernization with single-slope SDImax self-thinning.
- **v12.7.1**, the coupled two-segment relative-density self-thinning and density-released ingrowth form.
- **OSM v2.26.1**, run on the identical stand tree lists via osm_headtohead.py, scored with the same NSVB
  emulator and metric code as the FVS versions (osm_h2h_treelist.csv, matched at Age equal to the stand's
  remeasurement interval; 705 stands, NB 355 and QC 378).

## Quantitative scorecard

### Level bias, RMSE, and modeling efficiency (NSE), pooled (NB + QC, n=705)

| metric | v12.5.0 bias% | RMSE | NSE | v12.7.0 bias% | RMSE | NSE | v12.7.1 bias% | RMSE | NSE | OSM bias% | RMSE | NSE |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| basal area | +4.8 | 7.9 | 0.72 | -2.7 | 8.1 | 0.70 | -9.0 | 9.1 | 0.62 | -5.5 | 19.0 | -0.64 |
| stand density index | +6.7 | 189.7 | 0.69 | -2.2 | 196.2 | 0.67 | -8.7 | 221.5 | 0.58 | -7.4 | 428.6 | -0.57 |
| quadratic mean diameter | -4.2 | 3.9 | 0.73 | +0.3 | 3.6 | 0.78 | +1.4 | 3.6 | 0.77 | +10.3 | 11.0 | -1.11 |
| top height | +11.0 | 2.8 | 0.73 | +10.5 | 2.8 | 0.74 | +10.2 | 2.7 | 0.74 | +3.4 | 6.8 | -0.59 |
| total volume (NSVB) | +19.2 | 61.4 | 0.61 | +11.3 | 56.4 | 0.67 | +3.9 | 57.1 | 0.66 | -1.6 | 132.1 | -0.82 |
| merch volume (NSVB) | +18.1 | 53.8 | 0.63 | +10.2 | 49.6 | 0.69 | +2.8 | 50.6 | 0.67 | -2.1 | 118.9 | -0.81 |
| sawlog volume (NSVB) | +17.8 | 44.7 | 0.64 | +10.0 | 41.5 | 0.69 | +2.6 | 42.3 | 0.68 | -1.5 | 101.8 | -0.87 |
| aboveground biomass (NSVB) | +18.8 | 43.8 | 0.55 | +10.4 | 39.6 | 0.63 | +3.0 | 40.0 | 0.62 | -2.6 | 86.5 | -0.76 |
| stand value | +21.4 | 3014 | 0.55 | +13.4 | 2735 | 0.63 | +5.9 | 2724 | 0.63 | -0.6 | 6133 | -0.86 |

Green/yellow/red on pooled level bias (green under 5 percent, yellow 5 to 15, red over 15): v12.5.0 is red on
every volume, biomass, and value metric; v12.7.0 is yellow on the same integrators; v12.7.1 is green on
volume, merch, sawlog, and biomass, yellow on value, and the only model that pulls basal area and SDI the
other direction (yellow to red, an under-prediction, the coupled self-thinning's cost); OSM is green to
yellow on every metric at the pooled level, its aggregate bias looks the best of the four.

Modeling efficiency (NSE) tells a different and important story: all three FVS-ACD versions explain 55 to 78
percent of out-of-sample variance (NSE 0.55 to 0.78) on every metric. OSM's NSE is **negative on every
single metric** (-0.57 to -1.11), meaning OSM's stand-level predictions are less accurate than simply using
the observed mean as the prediction. OSM's low pooled bias is a population-level cancellation, not
individual-stand skill: it over-predicts some stands and under-predicts others by large amounts that happen
to average out. This is the single most important quantitative finding for anyone reading only the headline
bias number.

### By-stratum bias (percent), NB versus QC

| metric | v12.5.0 NB | v12.5.0 QC | v12.7.0 NB | v12.7.0 QC | v12.7.1 NB | v12.7.1 QC | OSM NB | OSM QC |
|---|---|---|---|---|---|---|---|---|
| basal area | +1.1 | +7.3 | -3.5 | -2.1 | -8.5 | -9.3 | -2.4 | -6.8 |
| stand density index | +5.3 | +7.6 | 0.0 | -3.7 | -5.0 | -11.4 | -0.8 | -11.7 |
| quadratic mean diameter | +1.6 | -7.7 | +4.3 | -2.2 | +4.9 | -0.8 | +10.3 | +11.8 |
| top height | +7.2 | +13.5 | +6.9 | +12.9 | +6.8 | +12.5 | +5.7 | +3.0 |
| total volume (NSVB) | +0.6 | +33.5 | -4.4 | +23.3 | -9.8 | +14.4 | -8.0 | +4.5 |
| merch volume (NSVB) | +0.8 | +31.1 | -4.2 | +21.0 | -9.6 | +12.1 | -7.5 | +3.0 |
| sawlog volume (NSVB) | -0.5 | +32.2 | -5.4 | +22.0 | -10.8 | +13.1 | -7.9 | +4.6 |
| aboveground biomass (NSVB) | +3.2 | +29.5 | -2.1 | +18.9 | -7.3 | +10.2 | -5.8 | +0.8 |
| stand value | -0.2 | +37.8 | -5.0 | +27.3 | -10.2 | +18.3 | -8.9 | +6.9 |

By-stratum consistency (spread between NB and QC total-volume bias, a proxy for the bidirectional-signature
problem): v12.5.0 32.9 points, v12.7.0 27.7, v12.7.1 24.2, OSM 12.5. **OSM is the most directionally
consistent model across jurisdictions.** The FVS-ACD generation improves consistency version over version
(32.9 to 27.7 to 24.2) but has not yet matched OSM's spread; the v12.8 regional and composition-aware
mortality refit is aimed exactly at this gap, gaining OSM's cross-jurisdiction consistency without giving up
FVS-ACD's much better per-stand efficiency.

### PAI bias (basal area, m2/ha/yr), pooled

| model | PAI bias |
|---|---|
| v12.5.0 | +0.11 (over) |
| v12.7.0 | -0.08 (under) |
| v12.7.1 | -0.26 (under, the coupled self-thinning trades level accuracy for a deeper increment under-prediction) |
| OSM v2.26.1 | -0.08 (under) |

### Recent Maine FIA, growing-stand stratum (post-2010, independent in time; n=788)

| model | BA level bias | BA annual increment bias | RMSE |
|---|---|---|---|
| v12.5.0 | +2.7% (obs 18.0, pred 18.5, R2 0.75) | +0.090 m2/ha/yr, obs 0.162 pred 0.252 (+56%, over) | 1.07 |
| v12.7.0 | +0.7% (R2 0.74) | +0.018 m2/ha/yr (+11%, over) | 1.10 |
| v12.7.1 | -2.2% | -0.085 m2/ha/yr, obs 0.162 pred 0.077 (-52%, the coupled self-thinning now under-predicts the growing-stand increment; R2 0.70) | 1.18 |
| OSM v2.26.1 | not run this pass. No OSM-on-FIA harness exists yet; building one (tree-list export plus a
  full run for 788 plots) is a new engineering task, flagged as an open item rather than rushed. |

Reading: on the recent Maine FIA growing-stand stratum, v12.5.0's total absence of a self-thinning
mechanism produces the largest annual-increment over-prediction of the three FVS versions (+56 percent,
worse than v12.7.0's +11), consistent with its catastrophic long-horizon runaway. v12.7.1's coupled
self-thinning corrects the QC mature-stand problem but overshoots on this growing-stand stratum, trading
v12.7.0's modest over-prediction for a larger under-prediction, the same single-lever trade-off documented
throughout this scorecard. Job 12146270 on Cardinal (the fia_recent_v1271.R contract, which properly
respects MODEL_FILE, pointed at AcadianGY_12.5.0.r; the older fia_recent_v1270.R script hardcodes v12.7.0
and ignores MODEL_FILE, so it was not reused for v12.5.0).

### Residual behavior

Not separately re-run this pass; carried forward from the existing v12.7.0 bias-by-attribute diagnostic
(figures/acadgy_v1270_bias_by_attribute.png) and the spatial bias maps (acadgy_ba_bias_surface_3way.png,
acadgy_annual_bias_3way.png): bias concentrates in mature, dense, ESI-covered QC stands for all three FVS
versions (least for v12.7.1), and OSM's regional over-prediction (documented separately at +20.6% BA on the
full 682-plot set) concentrates in the same dense mature stands, consistent with the mechanism identified
here (OSM under-applies self-thinning at high density).

## Qualitative scorecard

Pass, flag, or fail per model, with the driving evidence.

| dimension | v12.5.0 | v12.7.0 | v12.7.1 | OSM v2.26.1 |
|---|---|---|---|---|
| Bakuzis: site ordering / Eichhorn | FAIL, not separately testable (self-thinning failure dominates) | FLAG, 0/125 HT and VOL inversions (PASS) but Eichhorn CV 22% (site-dependent V-H) | PASS in the validated seeded run; an unseeded quick rerun this session showed 5 to 30 inversions, a reproducibility gap flagged below | FLAG, not run through the formal Bakuzis matrix; the +20.6% regional BA over-prediction implies a weak density constraint |
| Bakuzis: Reineke self-thinning (target slope near -1.6) | FAIL, never enters a self-thinning regime; 4500 to 5000 stems/ha at 62 to 64 m2/ha basal area at age 120 is far outside any realistic Acadian stocking | PASS, slope -1.28 to -1.35 across 5 sites | PASS in the validated run (plateau at the correct maximum); this session's unseeded rerun could not cleanly separate the regime, an open item | FAIL, the Seven Islands 60-year matched-stand trajectory shows continued basal-area accumulation (32 to 42 m2/ha) with no self-thinning onset while FVS-ACD self-thins the same stands over the same interval |
| Long-horizon trajectory realism (plateau vs runaway) | FAIL, basal area still climbing steeply at age 120, no arrest mechanism | FLAG, plateaus near 35 to 36 m2/ha by age 120 but the dedicated diagnostic found it still slowly rising, above the realistic 28 to 32 target | PASS, the coupled two-segment self-thinning plateaus at 33 to 34 m2/ha by mid-rotation in the validated run, inside the realistic Acadian range | FAIL, the empirical 60-year trajectory shows no plateau over the tested horizon |
| Transparency and interpretability | PASS, FVS-ACD in R, fully open | PASS | PASS | FLAG, closed-source binary; only a profile and issue tracker are public on GitHub; LGPL-licensed distribution with a documented external API, not inspectable source |
| Data requirements | PASS, standard tree list plus site index | PASS, tree list plus the ESI v8 surface | PASS, same as v12.7.0 | FLAG, needs a tree-list export to OSM's schema, a command file, and Windows or a .NET 10 runtime for the portable build |
| Usability and implementation | FLAG, stable and long-fielded, but individual stands can hang without an explicit per-stand time-limit guard (observed directly this session) | PASS, actively maintained, fast, integrates into the R and HPC pipeline | PASS | FLAG, Windows-primary with a beta Linux build; needs a Python wrapper to drive from an R and HPC pipeline (built and working here, but an extra integration layer) |
| Uncertainty characterization | FAIL, point prediction only | FAIL | FAIL | FAIL, none of the four models propagate parameter or residual uncertainty |

## Display

See `figures/four_model_scorecard_heatmap.png` (model by dimension matrix, the full scorecard at a glance)
and `figures/four_model_scorecard_radar.png` (modeling efficiency by metric, pooled, one line per model;
OSM's negative-NSE collapse toward the center is the clearest single image in this scorecard).

## Verdict

No single model wins every dimension; that is the point of scoring on the full profile rather than one
number.

**v12.5.0 (the incumbent operational version)** should be retired from mature-stand and long-horizon use.
It is red on every volume, biomass, and value metric pooled, red on the QC mature edge specifically (total
volume +33.5 percent), and fails the Bakuzis self-thinning check outright (basal area still climbing past 62
m2/ha at age 120 with thousands of stems per hectare still alive, a biologically impossible stand). Its one
strength is NB growing-stand basal area, where its lack of self-thinning happens not to matter over a short
interval (+1.1 percent). It is not the right choice for anything longer than a single-cycle inventory
projection.

**v12.7.0** is a substantial improvement (yellow rather than red on the integrators, Bakuzis site ordering
fixed by the ESI anchor) but still runs away slowly at the long horizon and still over-predicts the QC
mature edge by 23 percent.

**v12.7.1** is the best FVS-ACD version and, on the growing stands and on rotation-scale realism, the best
model overall. It is green on total volume, merch volume, sawlog volume, and biomass pooled; it is the only
model that plateaus at the biologically correct Acadian maximum in the validated long-horizon run; it keeps
the transparency, data, and usability advantages of the R codebase. Its cost is a deeper NB under-prediction
(basal area -8.5 to -9.3 percent both jurisdictions) and a widened annual-increment under-prediction on the
recent Maine FIA growing stratum. For **short-rotation inventory projection on growing, actively managed
stands**, this under-prediction is a real consideration; v12.7.0 or a blended config may be preferable there
until the v12.8 refit lands.

**OSM v2.26.1** has the best pooled level bias on every metric and the smallest NB-versus-QC directional
spread, making it look, from the headline bias number alone, like the strongest model. The modeling
efficiency numbers overturn that reading: OSM's NSE is negative on every metric, meaning its stand-level
predictions are worse than the observed mean, a precision failure that the aggregate bias statistic hides.
OSM is also the model that fails the long-horizon Bakuzis self-thinning check most clearly (the Seven Islands
60-year trajectory keeps climbing while FVS-ACD plateaus over the same stands), and it carries the
transparency, data-requirement, and platform costs of a closed-source, Windows-primary binary. OSM is not
recommended over v12.7.1 for either short-rotation inventory or long-horizon carbon and old-growth work,
despite its favorable aggregate bias.

**Recommendation**: adopt v12.7.1 as the forward operational version for stand projection generally, and for
long-horizon carbon and old-growth applications specifically, where the plateau-versus-runaway distinction is
decisive. For short-rotation inventory on growing, managed stands where v12.7.1's basal-area under-prediction
matters most, hold the v12.8 regional and composition-aware mortality refit as the fix that should let a
single model win both tails, and consider v12.7.0 as an interim choice for that specific use case only if
v12.8 is not ready in time for a given application.

## Open items

- **v12.8 regional and composition-aware mortality refit.** The single relative-density lever cannot
  separate the QC mature over-prediction from the NB growing under-prediction (both jurisdictions sit near
  the same relative density with different absolute basal area and species composition). This is the fix
  that should let FVS-ACD win both tails simultaneously and also close the consistency gap with OSM. Flagged
  as the clear next-version priority, not attempted in this pass.
- OSM on recent Maine FIA (788 plots) was not run; no OSM-FIA harness exists yet. Building one (tree-list
  export, command file, batch run, NSVB-consistent scoring) is a discrete follow-on task.
- The unseeded quick trajectory rerun of v12.7.1 in this session showed HT and VOL site-ordering
  inversions that the validated seeded run did not; add a fixed random seed to traj1271.R style scripts so
  ad hoc reruns reproduce the validated numbers, or always cite the validated run and treat quick reruns as
  indicative only.
- Re-check forusresearch.com/downloads/osm periodically for a release past v2.26.1; it will not appear on
  the OSM-Contributors GitHub, which does not host the engine source.
- Uncertainty characterization is a gap shared by all four models; a bootstrap or Bayesian wrapper around
  AcadianGY's parameters would be a genuine differentiator and is worth scoping as separate future work.

## v12.5.0 harness-config check (resolves an earlier flagged caveat)

A prior session note flagged that the v12.5.0 run above used "the harness common ops (use.sdimort on,
use.mortcal off)" rather than v12.5.0's "native MORTCAL operational config," and queued a re-run with
native settings as a to-do for this task. Source inspection of AcadianGY_12.5.0.r resolves this: the
model's own make_ops() has no use.sdimort, sdimort.onset/beta, or use.mortcal parameters at all (zero
occurrences in the file); those fields do not exist in v12.5.0's engine. v12.5.0 instead uses its own
native region-level plot mortality equations (calc_mortality, mort_plot_prob, mort_plot_ba, the Chen et
al. plot mortality probability and basal-area functions). When comprehensive_bench.R bolts ops$use.sdimort
and ops$use.mortcal onto the ops data frame for every model, those two fields are simply never read by
v12.5.0's AcadianGYOneStand(), so they are inert for this model. The cb_v125_results.csv used above
therefore already reflects v12.5.0 running under its own native mortality mechanism, unmodified by the
harness. No re-run is needed; the earlier caveat is closed.

## Reproducibility check (same day, rerun on fresh SLURM jobs)

v12.5.0 and v12.7.1 (config B) reproduce byte-identical results on rerun: fully deterministic, no drift.
OSM reproduces within floating-point noise only (about 1 part in 10,000 on individual tree volumes, no
effect on any reported statistic). The original cb_v1270_results.csv on Cardinal predates the in-domain
filtering feature in comprehensive_bench.R (it holds all 2,555 MagPlot pairs, not just the 733 in-domain
ones); this does not affect any number reported above, since four_way_scorecard.R always intersects stand
IDs across all four models before scoring, which already restricted v12.7.0 to the correct common in-domain
set. Noted here so a future direct diff of that file is not mistaken for a reproducibility problem.

## Files (Cardinal)

- Comprehensive harness: ~/magplot/verify/comprehensive_bench.R; results cb_v1270_results.csv,
  cb_v1271cB_results.csv, cb_v125_results.csv (this session, job 12145904).
- OSM head-to-head: ~/magplot/verify/osm_headtohead.py, osm_h2h_treelist.csv, osm_h2h_metrics.csv.
- Four-way scorer: ~/magplot/verify/four_way_scorecard.R (this session); output four_way_scorecard.csv.
- Recent FIA: ~/fia_recent_v1270.R (hardcoded to v12.7.0, do not reuse for other models),
  ~/fia_recent_v1271.R (properly parametrized via MODEL_FILE/CONFIG_TAG, reused this session for v12.5.0,
  job 12146270).
- Long-horizon trajectories: ~/magplot/verify/traj_v1270.R/.csv, traj1271.R / traj_v1271_B.csv, traj_v125.R
  / traj_v125.csv (this session). Bakuzis checks: ~/silc_cfi/bakuzis_check.R, bz_v1270_report.txt (this
  project's results/seven_islands/), this session's reruns on traj_v125.csv and traj_v1271_B.csv.
- Seven Islands matched-stand OSM long-horizon evidence: ~/silc_cfi/fvsacd_vs_osm_matched.csv.
- Coordinates stay on Cardinal; nothing above leaves aggregate form.
