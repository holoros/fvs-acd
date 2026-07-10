# FVS-ACD v13.1 refit v2: what changed and why

Structural refit only. Authored 2026-07-10, not executed (no cluster access) and not shipped.
Source of the failure diagnosis: `_context/v13_autosubmit/failure.md` (jobid 12275867, FAILED exit 1:0,
~11.8 h, well inside the 24 h wall, so two code/model bugs rather than resources).

## Fix 1. Ingrowth YEARS/years casing crash (mechanical)

The ingrowth fit crashed before writing any output with
`Error in eval(jsub, SDenv, parent.frame()) : object 'YEARS' not found`, a data.table `fifelse`
inside a `[` j-expression. Cause: after the left join of the growth set to the assembled ingrowth table,
data.table suffixes a shared interval column to `YEARS.x` / `YEARS.y` and leaves no bare `YEARS`, so the
`fifelse(is.finite(YEARS) & YEARS > 0, ...)` reference had no `YEARS` column to resolve.

Changes, all in the block that follows the `merge()` into `id`:

- After reconciling a canonical `YEARS` from `YEARS.y` / `YEARS.x`, added the defensive casing guard right
  before the offending block:
  `if ("YEARS" %in% names(id) && !("years" %in% names(id))) id[, years := YEARS]` and the reverse
  `if ("years" %in% names(id) && !("YEARS" %in% names(id))) id[, YEARS := years]`. This guarantees both an
  uppercase `YEARS` and a lowercase `years` exist and agree, regardless of how the source columns were cased.
- Rewrote the interval line to reference the guaranteed lowercase column:
  `id[, ing_years := fifelse(is.finite(years) & years > 0, years, NA_real_)]`
  (was `fifelse(is.finite(YEARS) & YEARS > 0, YEARS, if ("YEARS.x" %in% names(id)) YEARS.x else NA_real_)`,
  which referenced a possibly-absent `YEARS`). The downstream last-resort constant (`ing_years := 5`) and
  the `log_years` offset are unchanged.
- Added lowercase `years` to the interval-column candidate list in `pick()` (`c("YEARS","years","REMPER","interval_years")`)
  so the assembly is robust to a lowercase source name as well.

Confirmed no other `YEARS`/`years` mismatch remains: the two aggregation blocks define `YEARS` inside the
same `.()` they use it in (internally consistent), and the merge selects `YEARS` from `ing`, which always
carries it. Everything else in the ingrowth block is byte-for-byte identical to the original.

## Fix 2. Mortality non-convergence (reparameterization)

The mortality fit ran but did not converge: max Rhat 3.64, min bulk ESS ~5, min tail ESS ~11, 566/3000 (19%)
divergent transitions, 1721/3000 (57%) hit max treedepth 12, all four chains E-BFMI < 0.3. This is a
posterior-geometry pathology (a hierarchical funnel plus poor energy mixing), not an iteration shortfall, so
the fix is reparameterization, not more sampling. Applied to the mortality `brm()` call (each tagged
`## v131fix` inline):

- Control: `adapt_delta = 0.99`, `max_treedepth = 15` (was 0.95 / 12).
- Group-level sd priors: replaced the heavy-tailed `student_t(3, 0, 1)` with weakly-informative
  half-normal `normal(0, 1)` on the log-hazard scale, set per grouping factor (`region`, `eco`, `fortype`).
  The Student-t tail let the group sds drift large and opened the funnel that produced the divergences and
  E-BFMI failures; the half-normal keeps them shrunk toward zero while still admitting real between-group
  variation. `exponential(1)` would be an equally defensible choice.
- Fixed-effect prior: `normal(0, 1)` -> `normal(0, 2)` on the standardized covariates (weakly informative).
- Intercept prior: kept centered on the physically meaningful cloglog baseline log-hazard for annual
  mortality (`normal(-4.5, ...)`, baseline hazard ~ exp(-4.5)), sd widened 1 -> 2. Retained this in place
  of a generic `normal(0, 5)` because on the cloglog scale a wide zero-centered intercept implies an
  implausible baseline hazard and keeps chains near the exposure boundary, worsening the geometry; the
  -4.5 center is the same rationale as the existing init.
- Predictors standardized before the fit: `rd_z`, `lnqmd_z`, `ba_z` are `scale()`d (mean 0, sd 1). This was
  already true in the original; it is now documented as load-bearing (poorly scaled covariates are a common
  source of E-BFMI and treedepth trouble) and the scaling constants are still written to
  `v131r_scaling.csv` for identical back-transformation.
- Non-centered parameterization: confirmed in use. It is the brms default for group-level effects, no custom
  stancode forces centering, and the harvested run reported init values for the non-centered offsets
  (z_1, z_2, z_3). No change needed beyond the tightened sd priors that make the non-centered geometry behave.
- Chains kept at 4; warmup/sampling raised modestly to 1000 / 1000 (iter 2000, warmup 1000; was 1500 / 750)
  so adaptation has more room at `adapt_delta = 0.99` without ballooning total iterations.
- Formula unchanged: no management fixed effect and no `(0 + mgd | region)` management slope (management
  acts through diameter growth, deferred to v13.2). Crossed `(1|region) + (1|eco) + (1|fortype)` intercepts
  and the cloglog exposure `offset(log_years)` are retained.

The same sd-prior tightening (`normal(0,1)` half-normal per group) and control settings
(`adapt_delta = 0.99`, `max_treedepth = 15`, 2000/1000) were mirrored on the ingrowth negative-binomial fit,
which shares the identical crossed random-effect structure and had never reached the sampler before (it
crashed in prep), so its geometry was untested. Its intercept prior stays on the log-count scale.

## Walltime

The submit script raises the wall from 8 h to 24 h (`v131_refit_v2.sbatch`). The original 8 h timeout
(jobid 12255452) was purely a wall issue; the later FAILED run used ~11.8 h of a 24 h wall, so 24 h leaves
ample margin even though `adapt_delta = 0.99` and `max_treedepth = 15` raise per-iteration cost. The
reparameterization is expected to cut the wasted deep-tree and divergent leapfrog steps that dominated cost
before, so net runtime should stay well within the wall.

## Output files (unchanged names; gate-facing)

`v131r_mort_convergence.csv`, `v131r_mort_fixef.csv`, `v131r_mort_varcomp.csv`,
`v131r_ingrowth_convergence.csv`, `v131r_ingrowth_byregion.csv`, and `v131r_status.txt`
(written `fit_complete` at the very end on success). Also retained: `v131r_scaling.csv`,
`v131r_mort_fit.rds`, `v131r_ingrowth_fit.rds`, `v131r_ingrowth_fixef.csv`,
`v131r_ingrowth_varcomp.csv`, and `v131r_ingrowth_bymgmt.csv` (when a `mgmt` column is present).

## Pass criteria for the rerun gate

- Mortality: max Rhat < 1.05 AND 0 divergent transitions AND no management hazard term in the fitted model.
- Ingrowth: converged (max Rhat < 1.05, divergences at 0, ESS healthy) and the block runs to completion and
  writes its outputs.
- FIA aggregate predicted/observed recruitment ratio in [0.85, 1.20].
- `v131r_status.txt` contains `fit_complete`.
