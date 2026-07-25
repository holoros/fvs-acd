# FVS-ACD v13.1 model file plan: posteriors to gated stand equations

*22 July 2026. Documents the v13.1 draft model file `scripts/AcadianGY_13.1_DRAFT.r`, which extends the
v12.11 engine so the fitted hierarchical posteriors REPLACE v12.11's two hand-tuned levers: the flat
ingrowth multiplier (`ops$ingrowth.mult`, pooled about 2.5x) and the management-gated mortality
attenuation (`ops$mort.dens.scale`, fmin 0.13, k 12.4, RD0 0.38). Draft and syntax-checked only. No FVS
projection, no SLURM job, nothing in `~/v13_kickoff` touched. Coefficients are read at runtime, never
hardcoded. Aggregates only. No em dashes.*

## What the file is

`AcadianGY_13.1_DRAFT.r` is a byte-for-byte copy of the frozen-canon v12.11 engine
(`scripts/AcadianGY_12.11.r`, identical to the Cardinal `~/_scripts/AcadianGY_12.11.r`) with the version
tag changed to `AcadianV13.1` and three additions, all gated OFF by default:

1. a runtime posterior loader block inserted near the top of the file, inert unless a switch is on;
2. one hook in `calc_ingrowth()` where the flat `ops$ingrowth.mult` was applied;
3. one hook in the SDImax self-thinning mortality block where the v12.11 management gate attenuated the
   removal fraction.

Every v12.11 lever, its `V1211_*` environment wiring, `make_ops()`, and `validate_ops()` are preserved
unchanged. The two new switches are added alongside them.

## The ops interface (contract, stable)

The sibling bench harness is written against these exact names. They will not change.

| ops field | type | default | meaning |
|---|---|---|---|
| `use.hier.ingrowth` | logical | `FALSE` | ON => stand recruitment comes from the negbinomial ingrowth posterior instead of the flat `ingrowth.mult` |
| `use.hier.mortality` | logical | `FALSE` | ON => the self-thinning removal fraction carries the management-free cloglog hazard modifier instead of the v12.11 management gate |
| `hier.postdir` | character | `~/v13_kickoff` | directory the posterior CSVs are read from; point at `~/v13_subplot` for the subplot-grain posteriors |

Three optional supporting fields carry the fit-grain grouping identity of the stand for the random-effect
match. They are not part of the minimal contract and default to unset (population-level prediction):
`hier.region`, `hier.eco`, `hier.fortype`. They are needed because the FVS-ACD `stand` object only holds
the coarse `stand$region` in {ME, NB, NS, QC}, which is not the 48-level fit region, the 84-level eco, or
the fit fortype. When any is unset (`NA`), that grouping's random intercept is 0, which is the correct
partial-pooling population-level value for an unobserved group.

`make_ops()` gains `use.hier.ingrowth = FALSE`, `use.hier.mortality = FALSE`, `hier.postdir =
'~/v13_kickoff'` so the harness `base_ops()` can be extended with the OFF defaults in one place. The hooks
themselves read every ops field defensively through `tryCatch`, so the file is safe even when called with a
bare v12.11-style ops that lacks these fields.

**Gate-off definition.** Gate-off = `use.hier.ingrowth` FALSE and `use.hier.mortality` FALSE and no v12.11
lever set. Under gate-off the file reproduces frozen v12.10.1 byte for byte.

## Runtime-load design (coefficients never hardcoded)

A small loader block sits near the top of the file. It reads the fixef, varcomp, and scaling CSVs written
by the Cardinal refit (`v131_mort_ingrowth_refit.R` for ingrowth; `v131_mort_repair_v6.R` for the re-nested
mortality) and returns a compact list of scalars plus an optional random-effect table. The load is memoized
in a private environment keyed on (submodel, postdir), so the files are read once per projection, not every
annual cycle.

Files read, by submodel:

| submodel | family / link | fixef | varcomp | scaling | ranef (optional) |
|---|---|---|---|---|---|
| ingrowth | negbinomial / log | `v131r_ingrowth_fixef.csv` | `v131r_ingrowth_varcomp.csv` | `v131r_scaling.csv` | `v131r_ingrowth_ranef.csv` |
| mortality | binomial / cloglog | `v131r_mortB_fixef.csv` | `v131r_mortB_varcomp.csv` | `v131r_mortB_scaling.csv` | `v131r_mortB_ranef.csv` |

Column contract, taken from the refit scripts that write them:

- fixef: first column is the term name, column `Estimate` is the point value. Terms are `Intercept`,
  `rd_z`, `lnqmd_z`, `ba_z` (the loader also accepts `(Intercept)`, `rd`, `ln_qmd`, `ba` as aliases).
- scaling: rows `var` in {`rd`, `ln_qmd`, `ba`}, columns `mean` and `sd`, the training-set centering and
  scaling used to standardize the predictors.
- varcomp: columns `grouping`, `term`, `sd_est`, ... . Loaded for structure and the random-effect SDs; the
  point predictions use the fixef plus the matched random intercepts.
- ranef (optional, not yet written by the fit): columns `grouping`, `level`, `Estimate`, the per-group
  random intercepts (BLUPs). When the file is present, the stand's `hier.region` / `hier.eco` /
  `hier.fortype` levels are matched and their intercepts summed. When absent or a level is unseen, the
  random contribution is 0. Confirm-on-return item: add a ranef export to the fit (or supply the group
  means through the bench harness) to activate the crossed random effects; until then predictions are
  population-level. The mortality nested group is tried under both label forms, `region:eco` matched on the
  interaction level `region_eco` and on the bare `eco`, to be robust to the brms level naming.

If a required fixef or scaling file is missing, the loader stops with a clear message naming the file and
the postdir, rather than silently falling back. This is deliberate: a hier switch turned on without its
posterior present is an operator error, not a default.

## Posterior to equation translation (exact formulae)

Let the saved standardization be z(x) = (x - mean_x) / sd_x for x in {rd, ln qmd, ba}, read from the
scaling CSV. Let the stand's matched random intercepts sum to u = u_region + u_eco + u_fortype (ingrowth)
or u = u_region + u_(region:eco) + u_fortype (mortality), with any unmatched term contributing 0.

### Ingrowth (negbinomial, log link) SWITCH A

The linear predictor deviation from the reference stand is

  eta_dev = b_rd z(rd) + b_lnqmd z(ln qmd) + b_ba z(ba) + u

and the predicted recruits per hectare per year is

  ingrowth.ph = exp( Intercept + eta_dev )

The negbinomial log-link mean over the interval is exp(linear predictor + offset log_years). The engine
runs at a 1-year cycle, so log_years = log(1) = 0 and the mean is already per year. Covariates are taken
per plot from the engine state: rd = `plot.data$rd.mod` (SDI/SDImax), ba = `plot.data$ba.plot` (m² ha⁻¹),
qmd = `plot.data$qmd` (cm), ln qmd = log(qmd). The predicted value SETS `plot.data$ingrowth.ph`, replacing
whatever the base `prob_ingrowth()` produced, and the flat `ops$ingrowth.mult` is not applied in this case.
Plots with no basis (qmd or ba not finite or not positive) keep the base prediction to avoid a NaN, which
matters for empty or single-tree plots. The downstream density-release logistic
(`ops$use.ingrowth.release`, frozen-base, default ON) and the species-composition split are unchanged and
still apply on top of the posterior level.

Fitted ingrowth fixef (job 12470707 v5, from `20260722_v131_harvest_and_mort_repair.md`): Intercept 3.93,
lnqmd_z -2.37 (dominant, +1 SD QMD multiplies recruitment by about exp(-2.37) = 0.09), ba_z +0.77 (+1 SD BA
multiplies by about exp(0.77) = 2.16 at fixed QMD), rd_z +0.01 (ns). Random intercept SDs fortype 0.54, eco
0.16, region 0.12. These are read at runtime, listed here only to show the direction the equation encodes:
recruitment high in low-QMD, high-BA developing stands and near zero in mature closed stands, the varying
recruitment a single flat multiplier could not represent.

### Mortality (binomial, cloglog link, management-free) SWITCH B

The cloglog model with an offset log_years gives an annual complementary-log-log hazard. Writing the full
linear predictor eta = Intercept + eta_dev, the annual mortality probability is

  m_ann = 1 - exp( -exp(eta) )

and the per-year hazard rate is exp(eta). The v13.1 hook enters at the exact point the v12.11 management
gate sat, as a management-free multiplicative hazard modifier on the self-thinning removal fraction:

  g = exp( eta_dev ) = exp( b_rd z(rd) + b_lnqmd z(ln qmd) + b_ba z(ba) + u )

  sdm_mfrac <- sdm_mfrac * g

The Intercept and the log_years offset cancel in the ratio, so g is the fitted cloglog hazard-rate ratio of
this stand relative to the mean-covariate, population-level reference, and g = 1 exactly at the reference
stand (mean covariates, zero random effects). Covariates are computed per plot from the post-growth tree
list: rd = SDI/SDImax with SDI = sum over trees with dbh >= 10 cm of (dbh/25.4)^1.6 expf and SDImax from
`plot.smry$sdi.max`; ba = sum of pi dbh² / 40000 expf (m² ha⁻¹, dbh in cm); qmd = sqrt( sum(dbh² expf) /
sum(expf) ) (cm). g is clamped to be finite and non-negative; a non-finite value falls back to 1.

The frozen-base self-thinning ramp (onset, break, gentle and steep beta) is untouched, so Reineke
self-thinning and the long-horizon density plateau are preserved; only the managed-stand attenuation is
replaced. This matches the design instruction that the fitted management-free hazard plus the crossed random
effects replace the hand-tuned gate. The re-nested mortality grouping is
`(1|region)+(1|region:eco)+(1|fortype)` with no management term, per the 22 July decision recorded in
`20260722_v131_harvest_and_mort_repair.md`.

Recommended candidate config: `use.hier.mortality` ON with `ops$mort.dens.scale` OFF, so the v12.11 gate
factor is 1 and only the posterior modifier g applies. If both are set they stack, which is not recommended
and is flagged in the model-file comment.

Confirm-on-return notes on the mortality translation, to settle with the bench harness once job 12526556
lands: (a) the rd definition in the fit (the mortality lever used RD = SDI/1200 as its fit basis; the hier
fit's `rd` column definition must be matched, and the loader standardizes with whatever mean and sd the fit
saved, so the requirement is only that the engine feeds the same rd construction the fit used); (b) whether
the posterior should instead REPLACE the removal fraction absolutely (sdm_mfrac <- m_ann) rather than modify
it multiplicatively. The multiplicative form was chosen for the draft because it enters exactly where the
management gate it replaces sat, preserves the frozen self-thinning ramp and plateau, and is a clean
generalization of the gate (g = 1 at reference). The absolute form is left as a documented alternative for
the harness to test without a further model-file edit.

## Gate-off byte-identity plan

The contract is: with `use.hier.ingrowth` FALSE, `use.hier.mortality` FALSE, and no v12.11 lever set, the
build reproduces frozen v12.10.1 to 0.000e+00 max abs diff on dbh, ht, and expf over a 20-year projection of
a young and a mature stand. The draft preserves this by construction:

- Ingrowth hook. The new posterior branch runs only when `use.hier.ingrowth` is TRUE. When it is FALSE the
  `else` branch executes the original v12.11 statement `plot.data$ingrowth.ph <- plot.data$ingrowth.ph *
  .ing_mult` verbatim, so the computation is line-for-line the frozen one.
- Mortality hook. When `use.hier.mortality` is FALSE the per-plot modifier table is built with
  `mort_hier_g = 1.0` (numeric one) for every plot. The only change to the frozen mutate is that
  `sdm_mfrac` is multiplied by `mort_hier_g`. Multiplying an IEEE double by exactly 1.0 returns the same
  double, so `sdm_mfrac` is bit-identical. The extra join column is dropped in the same `select` that drops
  the other scratch columns, and `left_join` preserves the left row order, so no downstream value or
  ordering changes.
- The loader block and helper functions are pure definitions; none run unless a switch calls them.
- `make_ops()` gains three fields but `validate_ops()` is unchanged; it checks a subset of fields by
  `setdiff` for missing ones and tolerates extra columns, so it still passes.

Verification when Cardinal returns: `smoke1211.R` with `BASE <- ~/_scripts/AcadianGY_12.10.1.r`, `NEW <-
~/_scripts/AcadianGY_13.1.r`, and `base_ops()` extended with the three OFF defaults, asserting
`GATE_OFF_BYTE_IDENTICAL: TRUE`. This is item 1 of `20260722_v131_validation_runbook.md` and is the
prerequisite that gates the rest of the battery. Do not proceed past a non-zero gate-off.

Syntax check status: the file passed an R-aware bracket, string, and comment balance check with zero errors
across 4715 lines. The definitive `Rscript -e 'invisible(parse("AcadianGY_13.1_DRAFT.r"))'` under
gcc/12.3.0 R/4.4.0 is pending Cardinal availability (the connector was timing out at drafting time); the
base v12.11 file parses cleanly and every addition is self-contained and uses idioms already present in the
engine.

## How this addresses the two v12.11 managed flags (QC volume, SILC BA)

Both open managed flags trace to the v12.11 hand-tuned management gate. The QC total-volume over-correction
(about +9.5 under v12.11) and the SILC basal-area widening arise because the gate attenuates the
self-thinning removal for managed stands with a single fitted logistic in RD (fmin 0.13, k 12.4, RD0 0.38)
applied uniformly wherever a stand is flagged managed, with no regional or compositional structure and a
binary managed/natural switch. `use.hier.mortality` replaces that gate with the fitted management-free
cloglog hazard whose region, region-within-eco, and fortype random effects carry the spatial and
compositional variation the single gate could not. Because the QC over-removal correction was doing the work
of an unmodeled regional and compositional hazard deviation, moving that variation into fitted crossed
random effects is expected to resolve the QC over-correction without the SILC-side widening the blunt gate
produced. This is a hypothesis to be confirmed by items 2 and 3 of the runbook (the maturity gradient with
Baxter held out, and the all-sites ME/NB/QC comparison against frozen base and OSM v2.26.1); the model file
provides the structure, and the bench harness plus the validation battery test whether it delivers. The red
team's caveat is carried forward: the stand-level ingrowth posterior is the principled recruitment component
but does not by itself close the Maine FIA subplot developing gap, which is a grain and patchiness problem
for the task-3 subplot refit; `hier.postdir` is the switch that later points the same file at the
subplot-grain posteriors.

## Files

- Model file draft: `scripts/AcadianGY_13.1_DRAFT.r`
- This plan: `20260722_v131_model_file_plan.md`
- Posterior CSV schemas taken from: `scripts/v131_mort_ingrowth_refit.R` (ingrowth + first mortality) and
  the re-nest resubmit `v131_mort_repair_v6.R` (mortality of record, job 12526556, prefix `v131r_mortB_`)
