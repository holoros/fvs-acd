# v13 autosubmit failure note, 2026-07-08

## v131_mort_ingrowth_refit (jobid 12255452): SLURM TIMEOUT

- State TIMEOUT, elapsed 08:00:04, batch step CANCELLED with signal 15 at 2026-07-07T19:11:43.
- .err: `JOB 12255452 ON c0009 CANCELLED AT 2026-07-07T19:11:43 DUE TO TIME LIMIT`.
- cmdstanr/brms hierarchical fit, 4 chains x 1500 iterations. Chain 3 finished at 12,250.5 s (3.4 h);
  chains 1/2/4 were at 83-90 percent of sampling when the 8 h wall hit.
- Only benign startup warning: init values set for a subset of params (z_1, z_2, z_3), normal for the
  non-centered parameterization.
- No post-processing ran: v131r_mort_convergence.csv, v131r_ingrowth_convergence.csv,
  v131r_ingrowth_byregion.csv, v131r_status.txt all absent. Four raw Stan chain CSVs remain on disk.
- Verdict: v131r_gate.R -> DEFERRED (outputs incomplete). PARKED.
- ACTION NEEDED (Aaron's call, not auto-resubmitted per the standing rule): raise walltime to 18-24 h,
  or cut iterations, or add reduce_sum within-chain threading, then rerun and gate.

## v130_joint (jobid 12255489): COMPLETED, but scorecard gate could not run

- Fit is fine: COMPLETED, all anchors + CV + domain counts written; both increments individually unbiased
  in domain. Not a failure.
- Blocker: cb_v130_results.csv was never generated. comprehensive_bench.R consumes a full AcadianGY model
  file, so v13.0 candidate predictions require an AcadianGY_13.0 variant with the two anchors injected into
  the HG and BA increment paths. That was never staged; authoring it blind through the web terminal was too
  high-risk to feed an adopt/park decision. PARKED at the scorecard step pending that reviewed variant.

## v131_refit_24h (jobid 12275867): FAILED (exit 1:0), not a timeout. Harvested 2026-07-10.

- State FAILED, elapsed 11:49:12, ran 2026-07-08T14:39:27 to 2026-07-09T02:28:39. Batch step exit 1:0.
  Well inside the 24 h wall (used ~11.8 h), so this is two code/model bugs, not resources.
- Mortality fit finished and wrote summaries, but converged badly and is not trustworthy:
  max Rhat 3.635, min bulk ESS 5.4, min tail ESS 11.5, 566 of 3000 (19 pct) divergent transitions,
  1721 of 3000 (57 pct) hit max treedepth 12, all 4 chains E-BFMI < 0.3. The four chains did not mix.
  Files present but do NOT trust: v131r_mort_convergence.csv, v131r_mort_fixef.csv, v131r_mort_varcomp.csv,
  v131r_mort_fit.rds.
- Ingrowth fit then crashed on a code bug before writing any output:
  `Error in eval(jsub, SDenv, parent.frame()) : object 'YEARS' not found`
  (data.table fifelse inside a `[` j-expression; column-casing YEARS vs years, the same class that bit v130).
  Missing: v131r_ingrowth_convergence.csv, v131r_ingrowth_byregion.csv, v131r_status.txt.
- Gate could not run (two of four gate inputs absent). Independent of that, mortality fails the convergence
  gate on every axis (Rhat < 1.05 and 0 divergences both violated), so the gate verdict is moot: PARK.
- ACTION NEEDED (Aaron's call, NOT auto-resubmitted per the standing rule): (1) fix the YEARS/years
  casing bug in the ingrowth data prep; (2) reparameterize the mortality fit (raise adapt_delta, raise
  max_treedepth, tighten or rescale priors, or revisit the non-centered z terms) before any rerun. A blind
  resubmit at 24 h would reproduce the same non-convergence. Full narrative in the results md 10 July update.
