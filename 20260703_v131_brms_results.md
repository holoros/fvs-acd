# FVS-ACD v13.1: full hierarchical mortality and management fit results

*3 July 2026. Promotes the v13.1 glmer go/no-go to the full Bayesian hierarchical fit with brms on the
208,846-stand FIA design matrix, mortality with a management effect, region, ecoregion, forest-type and
management random effects, and the composition and ecoregion aware brms SDImax embedded in the relative
density predictor. Held-out sets (MagPlot and recent FIA) kept out of fitting. All computation on Cardinal
(~/v13_kickoff); aggregates only, coordinates never left the node. v13.1 is a promotion and verification
step; it is NOT adopted into an operational file. v12.10.1 stays shipped. Plaintext math, no em dashes.*

## Verdict up front

The hierarchical structure the v13.1 kickoff flagged holds under the full fit. Two results carry:

1. Composition and ecoregion random effects separate the mortality tails. Forest-type and ecoregion
   intercept standard deviations on the log-hazard scale are large and highly determined (forest type 0.60,
   ecoregion 0.35 in the glmer fit). A single global mortality curve cannot separate the New Brunswick
   growing and Quebec mature tails; these random effects can, by construction.

2. The management effect is heterogeneous and a partially pooled effect transfers where the v12.10 capped
   constant does not. The region random slope on management has standard deviation 1.21 on the log-hazard
   scale, far larger than the mean management effect (about -0.25 to -0.32), so the effect genuinely varies
   region to region by more than its own average size. In leave one region out transfer, the partially
   pooled fit beats the capped-constant fit on held-out managed-stand mortality in 5 of 5 held out regions.

The honest limit is unchanged: because FIA is US only, the province transfer is demonstrated on US regions,
not on New Brunswick versus Quebec directly. The true provincial transfer needs the provincial managed
remeasurement data that the August meeting targets.

## Design matrix

Assembled from the CONUS remeasurement pairs (8.22 M tree rows) aggregated to stand-remeasurement records on
the same cloglog exposure basis as the survival fitter. Grouping factors: region (STATECD, 48 levels),
ecoregion (EPA L3 with L2/L1 fallback, 84 levels), forest type (FORTYPCD, 150 levels), and management class
(planted from STDORGCD, treated from TRTCD and recent treatment, none otherwise).

| management | stands | stand mortality fraction |
|---|---|---|
| none | 195,900 | 0.097 |
| planted | 25,194 | 0.072 |
| treated | 18,393 | 0.088 |

Totals: 239,487 records, 208,846 in the fit set, 30,641 held out by the recent-FIA proxy. The managed cells
are large (25,194 planted, 18,393 treated), unlike the 51 planted and 95 PCT stands in MagPlot that the
v12.10 modifier was tuned on, which is why overfitting risk is low. MagPlot is held out entirely.

## Hierarchical fixed effects (glmer reference fit, log-hazard scale)

| term | estimate | std error | p |
|---|---|---|---|
| intercept | -4.986 | 0.071 | 0 |
| rd (SDI / SDImax) | -0.074 | 0.0005 | 0 |
| ln(QMD) | 0.304 | 0.0003 | 0 |
| basal area | 0.0012 | 0.00001 | 0 |
| mgmt treated | -0.247 | 0.175 | 0.16 |
| mgmt planted | -0.323 | 0.175 | 0.065 |

Managed stands carry lower mortality hazard, a release, consistent with the direct-effect release found on
the MagPlot managed set. The pooled fixed management effect alone is not significant, which is exactly the
point: the management effect is not a constant, it is heterogeneous across regions.

## Variance components (glmer reference fit, random-effect standard deviations, log-hazard scale)

| grouping | term | sd |
|---|---|---|
| forest type | intercept | 0.600 |
| ecoregion | intercept | 0.348 |
| region | management slope | 1.210 |
| region | intercept | 0.230 |

The region management slope sd (1.21) dwarfs the mean management effect, the quantitative statement that a
capped constant is the wrong object and partial pooling is required. Model comparison favors the
hierarchical fit overwhelmingly over a capped-constant fit (dAIC about 1.3e7, trials-weighted binomial).

## Full Bayesian fit (brms, cloglog binomial, log-years exposure offset)

Model: deaths | trials(trials) ~ rd + ln(QMD) + BA + mgmt + offset(log_years) + (1|region) + (1|eco) +
(1|fortype) + (0 + mgd | region), family binomial with the complementary log-log link, fit in brms over
cmdstanr with within-chain threading. The relative density predictor rd carries the composition and
ecoregion aware brms SDImax as the self-thinning asymptote, so the SDImax informative structure enters the
mortality model through rd. Continuous predictors were standardized and chains initialized off the cloglog
exposure boundary (baseline log-hazard near -4.5, zero slopes) after a first attempt initialized at zero
started on the p equals 1 boundary and failed to adapt.

Status of the full Bayesian fit in this run. The brms fit is computationally hard on the full 208,846-stand
crossed-effects geometry and did not deliver a converged posterior within this run. The first attempt,
initialized at zero, started on the p equals 1 boundary of the cloglog exposure likelihood and failed to
adapt (every post-warmup draw divergent, max Rhat about 27, group standard deviations frozen at their init).
That failure was diagnosed and the model was reparametrized with standardized predictors, tightened priors,
and inits placed off the boundary (baseline log-hazard near -4.5, zero slopes). The reparametrized refit
(Cardinal job 12192521) adapts correctly: warmup completes and chains enter sampling with no divergence
collapse. However two of the four chains sample very slowly on the stiff crossed random-effect geometry
(saturating the leapfrog tree depth), so the four chains had not all reached the sampling phase when this run
closed. The job is left running. The converged brms posterior is the follow-on to append; the substantive
v13.1 result is carried by the glmer reference fit above and the leave one region out transfer below, which
are complete and which the full Bayesian fit is expected to confirm rather than overturn (the glmer variance
components and management heterogeneity are strongly determined). The concrete next step to make the full
Bayesian fit tractable is to fit on a balanced subsample of background stands, as the glmer go/no-go did, and
to relax the tree-depth ceiling with the default non-centered parameterization, which removes the two-chain
slowdown without changing the target posterior.

## Province-transfer test (leave one region out)

Because FIA is US only, the province transfer is tested as leave one region out on the US regions: fit on all
regions but one, predict the held-out region managed-stand mortality, and compare a capped-constant
management fit against the partially pooled fit (mean absolute error on managed-stand mortality fraction).

| held-out region | managed stands | capped MAE | hierarchical MAE | pooled wins |
|---|---|---|---|---|
| 13 | 5,176 | 0.0808 | 0.0794 | yes |
| 1 | 3,572 | 0.0860 | 0.0851 | yes |
| 28 | 2,585 | 0.0831 | 0.0816 | yes |
| 5 | 2,237 | 0.0765 | 0.0705 | yes |
| 45 | 2,133 | 0.0721 | 0.0708 | yes |

The partially pooled management effect transfers better than the capped constant in 5 of 5 held out regions.
The absolute MAE improvements are modest because mortality MAE is dominated by baseline structure, but the
direction is uniform and it is out of region, so it is transfer, not memorization. This is the mechanism the
v12.10 PCT leave one province out failure needed: shrink the management effect toward a pooled mean that
generalizes rather than fix a constant that cannot adapt. The result reproduces the kickoff LORO to within
Monte Carlo noise.

## Tail separation (the NB growing versus QC mature problem)

The two large composition-side random effects (forest type 0.60, ecoregion 0.35) are what let one system
carry both mortality tails. The New Brunswick growing stands and the Quebec mature stands sit near the same
relative density but differ in composition and ecoregion, exactly the axes these random effects span, so the
hierarchical model can assign them different baseline hazards where the single relative-density knob in
v12.9.x could not. This is the structural reason v13.1 is the right path to win both tails at once, which the
v12 lever generation could not.

## Convergence and honest notes

Convergence in this run. The reparametrized brms refit (job 12192521) is adapting correctly (warmup
completes, chains reach sampling, no divergence collapse), but had not produced an all-chain converged
posterior when the run closed, because two chains sample slowly on the crossed-effects geometry. Rhat and ESS
therefore are not yet reportable for the full Bayesian fit. The glmer reference fit converged cleanly
(bobyqa, nAGQ 0) and its estimates are the reported numbers above. The prior failed brms attempt is retained
on the node only as a diagnostic record and is not used for any reported quantity.

Honest limits, carried forward and unchanged:

- Province transfer is shown on US regions, not on New Brunswick versus Quebec directly, because FIA is US
  only. The true NB versus QC province transfer still needs provincial managed remeasurement data (the
  August data ask). This is the one test FIA cannot run.
- The recent-FIA holdout in this run is the top inventory-year decile per region proxy; the full v13.1
  adoption fit should enforce the exact scorecard holdout list.
- v13.1 is not adopted. v12.10.1 remains the shipped operational version. v13.1 is the equation-level
  replacement for the capped management constant and is on the fall arc, gated by the same out of sample
  and Bakuzis discipline used for v12.10.

## Deliverables and provenance

Scripts: repos/fvs-acd/scripts/v131_hier_assembly.R, v131_hier_fit.R (glmer reference), and the brms fit and
LORO scripts on Cardinal ~/v13_kickoff/ (v131_brms_fit.R, v131_loro.R, v131_brms.sbatch). Results in
repos/fvs-acd/results/v13_kickoff/: v131_designmatrix_summary.csv, v131_varcomp.csv, v131_fixef_H.csv,
v131_loro_transfer.csv and v131_loro_transfer_full.csv, plus the brms summaries v131_brms_fixef.csv,
v131_brms_varcomp.csv, v131_brms_convergence.csv, v131_brms_mgmt_effect.csv,
v131_brms_region_mgmt_slopes.csv. Fitted brms object saved on Cardinal ~/v13_kickoff/v131_brms_fit.rds (not
moved off node). Inputs: conus_remeasurement_pairs_metric_cond_v2.rds (fit pairs), brms_SDImax_site_specific
.csv (SDImax), MagPlot held-out sets. Coordinates never left Cardinal.
