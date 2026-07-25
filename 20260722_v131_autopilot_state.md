# FVS-ACD v13.1: autopilot session state (22 July 2026)

*Consolidated state after the 22 July autopilot burst. Aggregates only; proprietary tree data and FIA
coordinates stayed on Cardinal. No em dashes.*

## Jobs in flight
- 12526556 (v131mortB): whole-plot mortality repair, re-nested eco within region. RUNNING, ~2.5 h at last
  check, 72 h wall. Outputs ~/v13_kickoff/v131r_mortB_*.
- 12528647 (v131sp_prod): subplot production fit, full grouping (1|region)+(1|region:eco)+(1|fortype)+
  (1|plot), single-NB recruitment + binomial cloglog mortality on 723,830 subplots. QUEUED, 72 h wall,
  32 cores, 128 G. Outputs ~/v13_subplot/v131sp_*. Probe estimated ~30 to 45 h.

## Converged and exported
- Whole-plot ingrowth (negbinomial): Rhat 1.006. fixef, varcomp, scaling, and now ranef exported
  (~/v13_kickoff/v131r_ingrowth_ranef.csv, 282 group intercepts: region 48, eco 84, fortype 150).

## Staged and parse-clean (not yet run against posteriors)
- v13.1 model file: ~/AcadianGY_13.1_DRAFT.r and repo scripts/AcadianGY_13.1_DRAFT.r. PARSE_OK. Byte-for-
  byte v12.11 plus a runtime posterior loader and two gated hooks. Switches ops$use.hier.ingrowth,
  ops$use.hier.mortality (both default FALSE), ops$hier.postdir (default ~/v13_kickoff). Ingrowth hook in
  calc_ingrowth replaces the flat ingrowth.mult; mortality hook multiplies the self-thinning removal
  fraction by a per-plot hazard modifier at the old management-gate site (documented alternative: absolute
  replacement). Gate-off (both FALSE) is designed to reproduce frozen v12.10.1 byte-identical.
- Bench harness: repo scripts/bench_parity_split_ms_v131_DRAFT.R. PARSE_OK. Flips the two switches, reuses
  all v12.11 NSVB/metrics machinery and OSM data, SCORECARD=1 emits the v1211 scorecard format.
- Subplot production script and sbatch: ~/v131_subplot_refit.R, ~/v131_subplot_refit.sbatch (this is what
  12528647 runs).

## Resolved this session
- Mortality non-convergence was the free crossed eco funnel; fixed by re-nesting eco within region
  (Aaron's call). Subplot probe showed mortality samples cleanly at subplot grain because (1|plot) absorbs
  within-plot correlation.
- Recruitment likelihood at the true 0.905 subplot zero fraction: single negbinomial is adequate (LOO
  elpd_diff -8.6, se 15.0 vs hurdle; zero PPC 0.9062 observed vs 0.9064 predicted). Hurdle carried only as
  a commented sensitivity.
- Full (1|plot) subplot run is tractable on one node; no need to drop the plot nesting.
- Validation battery located and dry-checked; frozen reference is ~/_scripts/AcadianGY_12.10.1.r; pin it
  explicitly (smoke1211.R currently points at 12.10.2).

## Queued v13 items (scoped, not started)
- Crown-ratio recession recalibration: coefficients and data sources mapped; gated coefficient swap.
- Lever 4 RO extension: fit directly from HRF_2015_2016 (has species, DBH, form, risk, height, red oak);
  the Castle join is infeasible (no shared key). Sub-2.5 cm height-imputation gap fix scoped, ungated,
  shippable independently.

## Next (scheduled 07:30, 23 July, and open items)
The morning harvest task drives: harvest both fits, export mortB ranef, run gate-off byte-identity
(BASE 12.10.1 vs v13.1, switches off, require 0.000e+00), then run the bench scorecard with switches on.
Known first-pass limitation: benchmark stands may resolve only coarse region, so score population-level
(fixef surface) first, match fortype where available, and treat full region/eco ranef matching as a
refinement. Real decision pending for Aaron: mortality hazard as a multiplicative modifier vs absolute
replacement.

## Notes written this session (repos/fvs-acd/)
20260722_v131_harvest_and_mort_repair.md, _stress_redteam_review.md, _validation_runbook.md,
_subplot_refit_plan.md, _subplot_fitset_build.md, _subplot_fit_feasibility.md, _crown_ratio_recal_plan.md,
_lever4_castle_join_scope.md, _model_file_plan.md, _bench_harness_plan.md, and this state file.
