# FVS-ACD v13.1: refit harvest, mortality diagnosis, and repair resubmit

*22 July 2026. Harvest of Cardinal job 12470707 (v131refit_v5), diagnosis of the mortality
non-convergence, the re-nest decision, and the resubmit as job 12526556. Aggregates only; proprietary
tree records and coordinates stayed on the node. No em dashes.*

## Harvest outcome (job 12470707)

The job COMPLETED (exit 0, 22.7 h wall, no timeout this run). It did not time out; both submodels ran to
the end. The result splits cleanly.

Ingrowth (negbinomial, log link) converged: max Rhat 1.006, min bulk ESS 784, min tail ESS 1491, 0
divergent. Usable posterior.

Mortality (binomial, cloglog link) did NOT converge: max Rhat 3.81, min bulk ESS 6.3, min tail ESS 13.8,
0 divergent. Zero divergences with a catastrophic Rhat and near-zero ESS is the signature of chains
sitting in different regions, not a sampler step problem and not wall time. The gamma_lpdf and
neg_binomial_2 precision exceptions in the .err are from the ingrowth NB shape during warmup and are
benign (ingrowth converged).

## Mortality diagnosis

The free crossed `(1 | eco)` intercept funnels to the zero boundary: sd_est 0.308 but sd_l95 1.7e-7. The
chains disagree about whether an ecoregion-level hazard deviation exists at all, which drives the Rhat to
3.81. eco is redundant in the hazard with the two well-identified crossed intercepts, region (sd 0.186,
l95 0.092) and fortype (sd 0.446, l95 0.233). eco funneled the same way in the earlier job 12275867, and
the v5 boundary-avoiding gamma(2,3) sd prior (Aaron present, 20 July) did not close it. eco stays
identifiable in the ingrowth model (sd 0.164, l95 0.109), so the problem is specific to the mortality
likelihood, not the eco factor itself.

## Decision (Aaron, 22 July): re-nest the grouping

Nest eco within region for mortality: `(1 | region) + (1 | region:eco) + (1 | fortype)`, replacing the
free crossed `(1 | eco)`. eco deviations are now partial-pooled toward each region mean rather than
competing globally with the region intercept for the same mass. fortype stays crossed. Prior on the
nested `region:eco` sd is gamma(2,4) (zero density at 0, mode 0.25, smaller than a marginal-eco prior as
befits a within-region deviation). max_treedepth restored to 15, adapt_delta 0.99. Mortality-only refit;
the good v5 ingrowth fit is not touched. 84 eco levels sit within 48 regions, so the nesting is well
posed; get_prior confirmed the region:eco group binds.

## Resubmit

Job 12526556 (v131mortB), RUNNING as of 11:25, 22 July. Script ~/v131_mort_repair_v6.R, sbatch
~/v131_mort_repair_v6.sbatch (72 h wall, 16 cpus, 48 G, R/4.4.0 to match the v5 toolchain). Outputs use
the v131r_mortB_ prefix: v131r_mortB_fit.rds, _fixef.csv, _varcomp.csv, _convergence.csv, _scaling.csv.
The failed v5 mort fit (v131r_mort_*) is preserved for the record.

## Ingrowth posterior vs v12.11 flat multiplier (task 2, ingrowth half)

The converged ingrowth posterior is the principled replacement for v12.11's flat `ingrowth.mult 2.5`.
Standardized fixed effects (predictors centered and scaled; scaling in v131r_scaling.csv):

| term | estimate | interpretation |
|---|---|---|
| Intercept | 3.93 | log recruits at mean covariates over the interval |
| lnqmd_z | -2.37 | dominant lever: +1 SD QMD multiplies recruitment by about exp(-2.37) = 0.09 |
| ba_z | +0.77 | +1 SD basal area multiplies recruitment by about exp(0.77) = 2.16 at fixed QMD |
| rd_z | +0.01 (ns) | relative density adds nothing once QMD and BA are in |

Random intercept SDs: fortype 0.54 (composition matters most), eco 0.16, region 0.12.

The substance: recruitment is not a constant 2.5x. It is high in low-QMD, high-BA developing stands and
near zero in mature closed stands, which is exactly the spatially and structurally varying recruitment a
stand-level flat multiplier could not represent at subplot grain (the v12.11 developing-end gap). The
within-sample pred/obs ratios (none 1.47, treated 1.62, planted 1.42, region range 0.8 to 2.9) are a
posterior-mean-vs-observed diagnostic that overshoots because summed NB conditional means exceed the
arithmetic mean of a zero-heavy response; they are NOT the production multiplier. The operational lift
must be computed by scoring the hierarchical predictions through FVS against the shipped ingrowth
routine. The mortality half of this comparison waits on job 12526556.

## Next (blocked on 12526556)

1. Harvest v131mortB; confirm Rhat < 1.01 and healthy ESS on the nested structure. Read the mortality
   posterior and finish the task-2 comparison to the v12.11 management-gated mortality lever (fmin 0.13,
   k 12.4, RD0 0.38).
2. Subplot-grain refit against ~/magplot/verify/multisrc/bench_mefia_subp_* (2858 units) for the
   developing-end recruitment.
3. Address the QC volume over-correction and SILC BA widening in the refit structure.
4. Validate as v12.11 was: gate-off parity, maturity gradient (Baxter out), all-sites ME/NB/QC vs base
   and OSM v2.26.1, Bakuzis, plateau, red-team.
