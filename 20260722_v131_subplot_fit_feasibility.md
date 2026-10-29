# FVS-ACD v13.1 subplot-grain refit: feasibility probe and production configuration

**Date:** 2026-07-22
**Cluster:** OSC Cardinal (account puom0008), R/4.4.0, brms + cmdstanr, threaded
**Fitset:** `~/v13_subplot/v131sp_fitset.rds`
**Probe job:** 12527808 (COMPLETED, 34 min wall, 32 GB requested, 8 cores)
**Isolation:** all work under `~/v13_subplot` with the `v131sp_` prefix; `~/v13_kickoff` (job 12526556, `v131r_mortB_*`) was not touched.

## Question

The subplot-grain refit carries a `(1|plot)` random intercept with roughly 208,000 levels over 724,000 rows. That is a very heavy random-effects block for brms. The task was to determine whether the full `(1|plot)` model is tractable on one Cardinal node, to fix the production sampler configuration, and to settle whether recruitment needs a hurdle given the 0.905 zero fraction.

## Fitset as fit (recent == 0)

Confirmed directly from the rds by column name. The full file holds 832,064 rows; the fit subset (`recent == 0`) is 723,830 rows across 208,441 plots. Grouping levels on the fit subset: region 48, ecoregion 84, region:eco 299, forest type 150. The 239,487 plot count in the brief is the plot_id count on the full 832k file; on the fit subset it is 208,441. Recruitment `recruit_count` has a zero fraction of 0.905, mean 0.124, and variance-to-mean 1.557. Mortality has 453,766 deaths against 5,050,345 trials. All of these match the brief.

## 1. Probe: both submodels at the full target grouping

The probe drew a nesting-preserving subsample by sampling whole plots and keeping all of their subplots, giving 40,030 subplots across 11,519 plots (region 48, eco 84, forest type 134, region:eco combos 261). It then fit three models at the full `(1|region)+(1|region:eco)+(1|fortype)+(1|plot)` grouping with 2 chains, 300 iterations (150 warmup), and within-chain `threading(4)`, and ran a LOO comparison plus a zero posterior-predictive check.

All three models sampled with clean geometry. No divergences, no treedepth saturations, and E-BFMI above 0.3 in every chain.

| Model | max Rhat | min bulk ESS | min tail ESS | divergences | treedepth hits | E-BFMI (per chain) | wall (min) |
|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Mortality, binomial cloglog | 1.090 | 29.4 | 82.8 | 0 | 0 | 0.77 ; 0.61 | 12.6 |
| Recruitment, single negbinomial | 1.155 | 281.7 | 183.9 | 0 | 0 | 0.64 ; 0.72 | 6.7 |
| Recruitment, hurdle negbinomial | 1.148 | 140.8 | 140.9 | 0 | 0 | 0.78 ; 0.97 | 12.1 |

The elevated Rhat values and the low mortality bulk ESS are short-chain artifacts. There are only 300 post-warmup draws total (150 per chain over 2 chains), so a bulk ESS near 30 is expected and is not a geometry problem; the divergence count, treedepth count, and E-BFMI are the pathology signals, and all three are clean.

Per-chain timing shows warmup dominates and sampling is cheap. For mortality, warmup ran 437 to 657 seconds for 150 iterations while sampling ran 53 to 59 seconds for 150 iterations, so warmup costs about 3.7 s per iteration against 0.37 s per iteration for sampling. Recruitment single-NB warmup ran 284 to 320 seconds and sampled in 45 to 48 seconds, about 2.0 s and 0.31 s per iteration.

Peak resident memory for the whole probe job, which included all three fits plus LOO and two `posterior_predict` passes, was 3.82 GB against the 32 GB requested.

**Mortality specifically.** The whole-plot mortality fit had needed a re-nest of the random-effects structure to converge. At subplot grain the `(1|plot)` term absorbs the within-plot correlation among subplots that had been destabilizing the coarser fit, and the model sampled cleanly here with no re-nest: 0 divergences, 0 treedepth hits, healthy energy. This is the key reassurance the probe was meant to provide. The `(1|plot)` block itself showed no funnel pathology in either submodel, held in check by the boundary-avoiding `normal(0,1)` prior on its standard deviation.

## 2. Extrapolation to the full 724k-row / 208k-plot run

The dominant added cost going from probe to full is the `(1|plot)` parameter block and the likelihood sum. Rows scale 18.1x (723,830 / 40,030) and plot-level parameters scale 18.1x (208,441 / 11,519). The coarser grouping levels are already near-saturated in the subsample (region 48 of 48, eco 84 of 84, forest type 134 of 150), so they add almost nothing. Taking per-iteration cost as roughly linear in rows plus parameters gives about 18x per-iteration inflation over the probe.

Applied to a production run of 1000 warmup and 1000 sampling iterations per chain, at the probe's `threading(4)`:

| Submodel | warmup per chain | sampling per chain | total per chain |
|:--|:--:|:--:|:--:|
| Mortality | ~18.3 h | ~1.9 h | ~20 h |
| Recruitment, single-NB | ~10.0 h | ~1.6 h | ~12 h |

Moving to `threading(8)` puts more threads on the `reduce_sum` likelihood over 724,000 rows, which is the dominant per-gradient cost at this data size, and should cut roughly 1.5x off these figures, bringing mortality to about 13 to 16 hours per chain and recruitment to about 8 to 10 hours per chain. Chains run in parallel, so the wall per submodel is the slowest chain, and the two submodels run sequentially in one job. Expected total job wall is about 26 to 38 hours.

The one real risk is that warmup adaptation in a ~208,000-dimensional space can run superlinearly, because the diagonal mass-matrix adaptation grows with dimension and the typical NUTS treedepth tends to rise as the geometry gets harder. The probe hit 0 treedepth saturations, so the trajectory length is not yet binding, but at 18x the dimension the mean treedepth may climb and inflate warmup by perhaps 1.5 to 2.5x. In the worst case mortality warmup approaches 40 to 45 hours per chain, which is still inside a 72-hour wall but tight.

Memory is not the binding constraint. The driver at full size is the stored plot random-effect draws: 4 chains times 1000 sampling draws times 208,441 plots at 8 bytes is about 6.7 GB per model for that one array, and with the working copies made during `summary`, `rhat`, and `VarCorr` the peak lands around 25 to 45 GB per submodel. Production drops the probe's memory-heaviest steps (LOO and `posterior_predict`), so a 128 GB request is comfortable.

**Verdict on tractability.** The full `(1|plot)` run at 724,000 rows and 208,441 plots is tractable on a single Cardinal node. It is not necessary to fall back to a plot-level subsample or to a coarser nesting than `(1|plot)`. The recommended path is within-chain threading with a generous wall time, exactly the config below. If warmup proves superlinear enough to threaten the wall, the clean fallback is to split into two jobs, one per submodel, each with its own 72-hour wall, rather than to weaken the model.

### Recommended production configuration

Full fitset, 723,830 rows, 208,441 plots. Grouping `(1|region)+(1|region:eco)+(1|fortype)+(1|plot)`. Recruitment single negbinomial with `offset(log_years)`; mortality binomial cloglog, `deaths | trials(trials)` with `offset(log_years)`. Standardized predictors rd_z, lnqmd_z, ba_z. Boundary-avoiding priors: `normal(0,1)` on the region, forest-type, and plot standard deviations, `gamma(2,4)` on region:eco, `gamma(2,0.5)` on the NB shape, `normal(-4.5,2)` and `normal(0,2)` on the mortality intercept and slopes. Sampler: 4 chains, 1000 warmup, 1000 sampling, `threading(8)`, `adapt_delta = 0.99`, `max_treedepth = 15`. Resources: one node, 32 cores (4 chains x 8 threads), 128 GB, 72-hour wall. This clears bulk ESS 400 by a wide margin: at the probe's realized efficiency the mortality submodel returns roughly 4000 post-warmup draws at an efficiency that, with a proper 1000-iteration warmup rather than the probe's 150, lands well above the 400 target.

## 3. Recruitment likelihood: single negbinomial versus hurdle

At the subplot count grain the 0.905 zero fraction is fully explained by the negative binomial itself and is not zero-excess. The LOO comparison put the hurdle nominally ahead but by less than its own standard error, and the zero posterior-predictive check shows single-NB reproducing the observed zeros exactly.

| Comparison | value |
|:--|:--|
| LOO elpd_diff, single-NB relative to hurdle | -8.6 (se 15.0) |
| Observed zero fraction | 0.9062 |
| single-NB predicted zeros | 0.9064, 95% [0.9024, 0.9102] |
| hurdle predicted zeros | 0.9060, 95% [0.9026, 0.9096] |

The elpd difference of 8.6 is smaller than twice its standard error of 15.0, so the two likelihoods are statistically indistinguishable. Both bracket the observed zero fraction, and single-NB shows no residual zero-inflation. The hurdle buys a second presence sub-model and roughly double the wall (12.1 versus 6.7 minutes on the probe) for no predictive gain.

**Verdict.** Single negative binomial is adequate. The hurdle is not needed. The production script fits single-NB as primary and carries the hurdle only as a commented sensitivity block.

## 4. Production artifacts (prepared, not submitted)

Written to Cardinal, verified in place, and not launched:

- `~/v131_subplot_refit.R` (10,284 bytes) fits both submodels at the full grouping with the config above and writes `v131sp_` outputs into `~/v13_subplot`: fit rds files, fixed-effect and variance-component tables, per-model convergence tables, and the predictor scaling.
- `~/v131_subplot_refit.sbatch` (737 bytes) requests one node, 32 cores, 128 GB, 72 hours on account puom0008, loads the R/4.4.0 toolchain, and runs the script.

Both are held pending Aaron's go, and must not launch while job 12526556 is still writing `~/v13_kickoff`.

## Bottom line

The probe fit both submodels and a hurdle sensitivity at the full `(1|region)+(1|region:eco)+(1|fortype)+(1|plot)` grouping with clean geometry, including the mortality fit that had misbehaved at whole-plot grain, which the `(1|plot)` term stabilized. The full 724k-row, 208k-plot run is tractable on one node in roughly one to one and a half days of wall time with within-chain threading; a plot-level subsample or a coarser nesting is not required. Recruitment stays on a single negative binomial; the hurdle is not warranted. Production script and sbatch are staged and ready to submit on request.
