# FVS-ACD v13.1: subplot-grain recruitment and mortality refit plan

*22 July 2026. Planning and drafting only, nothing submitted. Empirical checks run read-only on the
Cardinal login node against the ME_FIA_S subplot benchmark and ME_TREE.csv. Aggregates only, proprietary
tree records and FIA coordinates stayed on the node. No em dashes.*

## Why this refit

v12.11 closed the managed and mature gaps, but the developing Maine FIA end stayed under-predicted and did
not improve at subplot grain (-24.9 to -24.8 percent), because a stand-level ingrowth multiplier cannot
represent patchy subplot recruitment. The whole-plot v13.1 fit (converged ingrowth, re-nested mortality in
job 12526556) is a stand-level component and, on the red-team evidence, does not by itself close the
subplot developing gap. This refit moves recruitment and mortality to the FIA subplot grain, where a
subplot is one condition rather than a heterogeneity-straddling whole plot.

## 1. Benchmark contents (what the four files carry, and what they do not)

The subplot benchmark lives at `~/magplot/verify/multisrc/bench_mefia_subp_*` and was built read-only by
`build_mefia_subp_bench.R` (job 12500717) from the same clean, undisturbed and untreated Maine FIA
remeasurement chains as the whole-plot ME_FIA_L benchmark. Four files, 2858 subplot units:

| file | columns | rows | role |
|---|---|---|---|
| bench_mefia_subp_pairs.csv | STAND, SITE, PROV, interval_years, ELEV | 2858 | unit key, interval, elevation |
| bench_mefia_subp_site_esi.csv | SITE, esi8 | 2858 | site productivity index |
| bench_mefia_subp_tree_init.csv | STAND, PLOT, TREE, SP, DBH, HT, EXPF, YEAR | 35865 | t1 tree list |
| bench_mefia_subp_tree_t2.csv | STAND, PLOT, TREE, SP, DBH, HT, EXPF, YEAR | 43976 | t2 tree list |

Unit structure. STAND is the subplot, coded `ME_S_<first_cn>_<SUBP>`, so the plot id is the STAND string
with the trailing `_SUBP` removed (equals the FIA chain root `first_cn`). There are 886 plots behind the
2858 subplots, mean 3.23 subplots per plot (100 plots with 1, 104 with 2, 178 with 3, 504 with all 4). The
`PLOT` column inside the tree files is always 1 (the FVS-internal plot slot) and carries no grouping
information, so the nesting plot id must come from the STAND string. PROV is uniformly `ME_FIA_S`;
interval_years is mostly 20 (2196 units) and 25 (479), and esi8 and ELEV are carried per chain.

Directly available. Subplot key (STAND), plot id (STAND minus `_SUBP`), interval_years for the exposure
offset, esi8 and ELEV as site covariates, and the full t1 and t2 tree lists (SP, DBH, HT, EXPF, YEAR) from
which the design predictors rd, ln_qmd and ba are computed at t1.

What is missing and where it comes from.

- Persistent tree key, so no death or recruit response from these files. TREE is a positional index
  renumbered `seq_len(.N)` in each snapshot (both files are 100 percent sequential, and matching by
  (STAND, TREE) agrees on species only 51.9 percent of the time with 31 percent of matches jumping more
  than 10 cm in DBH). The gross recruitment and mortality responses therefore cannot be built from the
  four benchmark CSVs. They are re-derived from `~/fia_data/ME_TREE.csv` on the later measurement (last_cn),
  keyed by (PLT_CN, SUBP), using the canonical FIA remeasurement fields: RECONCILECD (1 and 2 = ingrowth)
  for recruitment, and PREV_STATUS_CD with STATUSCD for mortality. Those fields exist and are populated
  (PREV_TRE_CN 59.5 percent, PREV_STATUS_CD transitions clean), they were simply dropped when the benchmark
  CSVs were written.
- region: single-valued (all ME) in this benchmark. A real region factor needs a CONUS subplot fitset.
- eco: not present. Requires a coordinate-based ecoregion assignment, which stays server-side.
- fortype: not present. Joined from `ME_COND.csv` FORTYPCD by PLT_CN (bucketed to forest-type group).
- mgmt: degenerate. The chains are undisturbed AND untreated by construction, so mgmt is single-valued and
  is dropped, not fit.

## 2. Response construction and the empirical recruitment diagnostics

All responses were built read-only from ME_TREE.csv restricted to the exact 2858 benchmark units (mapped
first_cn to last_cn via the same PREV_PLT_CN pointer-jump the benchmark used, all 2858 mapped).

Mortality. trials = trees live at t1 (PREV_STATUS_CD == 1); deaths = live at t1 and dead at t2
(PREV_STATUS_CD == 1 and STATUSCD == 2). Result: 43215 trials, 4216 deaths, pooled per-interval mortality
0.098, annualized about 0.0048 per year, mean 15.1 trials per subplot. 40 units have no live t1 tree in
ME_TREE at last_cn and are dropped from the mortality fit (2818 usable). Exposure is offset(log_years).

Recruitment. Gross ingrowth via the FIA RECONCILECD ingrowth flag (codes 1 and 2), the canonical
definition, which avoids imposing an ad hoc DBH threshold. Per-subplot count over the interval, with
offset(log_years) carrying the annualization.

Empirical recruitment distribution at subplot grain (2858 units):

| quantity | value |
|---|---|
| zero fraction | 0.356 |
| mean | 1.565 |
| variance | 3.332 |
| variance / mean | 2.13 |
| max | 12 |
| method-of-moments NB theta | 1.39 |
| NB-implied zero fraction (theta/(theta+mu))^theta | 0.351 |
| Poisson-implied zero fraction exp(-mu) | 0.209 |
| nonzero part (n = 1841) | mean 2.43, var/mean 1.26 |

## Recommended recruitment likelihood: single negbinomial (primary)

The single negbinomial reproduces the observed zeros almost exactly: NB-implied zero fraction 0.351 versus
observed 0.356, a 0.5 percentage-point gap, while a Poisson would predict only 0.209 and badly under-fit
the zeros. Because theta was fit by moments, the NB simultaneously reproduces the mean (1.565), the
variance (3.33 predicted, 3.33 observed) and the zero fraction. There is no zero-excess beyond what the
negbinomial overdispersion already delivers, and the overdispersion itself is modest (theta 1.39,
variance about mu + 0.72 mu squared), not extreme.

This overturns the stand-level red-team lean toward a hurdle or zero-inflated form. That lean rested on the
72.4 percent zeros and shape 0.042 measured on the whole-plot response, but that response was EXPANDED
recruits per hectare (mean 1705, median 0, max about 430,000), a heavy-tailed continuous expansion, not a
count. Modeling the subplot recruitment as the tree COUNT it actually is removes almost all of the
pathology. So:

- PRIMARY: single negbinomial, log link, offset(log_years).
- SENSITIVITY: hurdle_negbinomial, adopted only if a posterior-predictive zero check (pp_check bars) or a
  LOO comparison shows the single NB under-fitting the zeros. On these diagnostics it should not. The draft
  script fits the single NB and carries the hurdle as a commented, ready-to-run alternative with a LOO stub.
- REJECTED: zero-inflated NB. Its structural-versus-sampling zero split is not identifiable here and is not
  warranted, since the single NB already matches the zero mass.

Decision to confirm: fit single NB as the production recruitment likelihood (recommended), or fit both NB
and hurdle and select by LOO before committing. The draft supports either with a one-line uncomment.

## 3. Exact grouping structure

Target structure, mirroring the whole-plot v6 re-nest plus the subplot nesting:

```
recruits ~ rd_z + lnqmd_z + ba_z + offset(log_years) + (1 | region) + (1 | region:eco) + (1 | fortype) + (1 | plot)
deaths_i | trials(trials_i) ~ rd_z + lnqmd_z + ba_z + offset(log_years) + (1 | region) + (1 | region:eco) + (1 | fortype) + (1 | plot)
```

The (1 | plot) intercept is the subplot-grain addition: subplots nest within plot, so a plot-level
intercept absorbs the shared plot signal and gives correct within-plot variance (the benchmark build note
flags exactly this non-independence, up to four subplots per plot sharing site, ownership and region).

On the ME-only benchmark this structure is guarded and reduces. region is single-valued, so (1 | region)
drops and (1 | region:eco) collapses to (1 | eco); eco itself is a single placeholder level until a
server-side ecoregion assignment is joined. mgmt is single-valued and is not in the formula. What actually
binds on the ME benchmark today is (1 | fortype) + (1 | plot). The draft builds the random-effect terms
programmatically, including a factor only when it has two or more levels, so the identical script yields the
full four-term structure on a CONUS subplot fitset and the reduced two-term structure on the ME benchmark
without edits.

Priors are weakly-informative and boundary-avoiding, matching the v5/v6 rationale: normal(0, 2) on the
standardized fixed effects, normal(-4.5, 2) on the mortality cloglog intercept (annual baseline hazard
about exp(-4.5)), normal(0, 2) on the recruitment log-count intercept, gamma(2, 0.5) on the NB shape (mode
about 2, covering the empirical theta 1.4), gamma(2, 4) on the nested region:eco sd (zero density at 0,
mode 0.25) and half-normal(0, 1) on the region, fortype and plot sds. Sampler controls are adapt_delta 0.99
and max_treedepth 15, as in v6.

## Blocker

The full re-nested (1 | region) + (1 | region:eco) + (1 | fortype) + (1 | plot) is not identifiable on the
ME-only benchmark. To fit it as specified, a CONUS subplot-grain fitset is needed, the subplot analogue of
`~/v13_kickoff/v131_fitset.rds`, built by pulling FIA subplot tree lists nationally with the same
RECONCILECD ingrowth and PREV_STATUS_CD mortality responses, joining region, eco (ecoregion, server-side)
and fortype, and holding the ME, NB and QC subplot benchmarks out (fit on recent == 0), exactly as the
whole-plot fit did. That fitset does not yet exist and is the gating build for the complete subplot refit.
Two paths:

- A. Fit now on the ME subplot benchmark alone, structure reduced to (1 | fortype) + (1 | plot). Immediately
  runnable once the responses, fortype join and rd are assembled. Good for a subplot-grain proof and a
  Maine-specific recruitment and mortality signal, but no cross-region pooling.
- B. Build the CONUS subplot fitset first, then fit the full re-nested structure with ME/NB/QC held out.
  The scientifically complete route and the one that matches the whole-plot design. More assembly work.

Recommended: A as an immediate subplot-grain check while B is assembled in parallel.

Two secondary items to reconcile before a scored run. The rd predictor in the draft is a Reineke SDI
relative density with a placeholder SDImax; it must be reconciled to the exact rd definition in
v131_fitset.rds so the subplot and whole-plot fits are on the same density scale. And fortype is currently
the plot-dominant FORTYPCD bucket; refine to the subplot CONDID forest type if the subplot condition
differs from the plot.

## Planned SLURM resources (not submitted)

Mirror the v6 mortality repair job. Account puom0008, 1 node, 16 cpus, 48 G, R/4.4.0 with the gcc/gdal/geos/
proj module stack to match the v5/v6 cmdstanr toolchain, brms with threading(4) across 4 chains, iter 2500
and warmup 1500. Wall time 48 h is a safe ceiling: the ME subplot data are small (2858 rows) but the
(1 | plot) term adds 886 group levels and the two submodels run in one job. If path B is taken, keep 72 h to
match the CONUS-scale whole-plot fits. Outputs use the v131sp_ prefix written to a new `~/v13_subplot`
directory so nothing collides with the running v131r_mortB_ job or the whole-plot v131r_ outputs. Do not
submit while job 12526556 is writing `~/v13_kickoff`.

## Deliverables

- This plan: `20260722_v131_subplot_refit_plan.md`.
- Unsubmitted draft script: `scripts/v131_subplot_refit_DRAFT.R` (assembles the subplot fitset from
  ME_TREE.csv plus the benchmark CSVs, guarded grouping, single-NB recruitment with a commented hurdle
  sensitivity, cloglog mortality, boundary-avoiding priors, adapt_delta 0.99, max_treedepth 15, v131sp_
  outputs).
