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

## v131refit_v4 (jobid 12410391): STILL RUNNING at 2026-07-20 harvest, no verdict. Rescheduled 12h.

- Not a failure yet. RUNNING on c0010, started 2026-07-17 10:08:12, 72h wall. At harvest 2026-07-20 08:01 ET:
  elapsed 2-21:52, TIME_LEFT 2:07:08 (wall ~2026-07-20 10:08 ET).
- Mortality fit 4 chains x 2000 iter (1000 warmup / 1000 sampling). Only Chain 3 finished (245624 s, ~68.2 h).
  Trailing at harvest: Chain 1 ~1300/2000, Chain 2 ~1600/2000, Chain 4 ~1200/2000. Ingrowth NOT started.
- No gate inputs yet (v131r_mort_convergence.csv, v131r_ingrowth_convergence.csv, v131r_status.txt all absent).
  Gate correctly NOT run. Only .err content is the benign non-centered init notice (z_1/z_2/z_3), as before.
- ACTION TAKEN: NOT resubmitted (standing rule). Harvest rescheduled to 2026-07-20 20:05 ET (~12h out) to catch
  COMPLETED or TIMEOUT.
- STRUCTURAL FLAG: one chain alone burned ~68 of 72 wall hours; mortality (4x2000) + ingrowth cannot fit a 72h wall.
  Likely TIMEOUT before ingrowth at next harvest. If so, fix is NOT a longer wall alone: cut iterations, add
  within-chain reduce_sum threading, or split mortality and ingrowth into two jobs. Science unchanged: no mgmt
  hazard term (management = growth release), region + composition random effects only.
- Verdict this pass: PARK (in progress, nothing to gate). v12.10.1 stays shipped. FIA true coords stayed on node.

## v131refit_v4 (jobid 12410391): SLURM TIMEOUT at 72h. Harvested 2026-07-20 (Aaron present).

- State TIMEOUT, elapsed 3-00:00:14, batch step CANCELLED signal 15 at 2026-07-20T10:08:26 on c0010. Exactly the wall.
- v4 produced NO new outputs beyond v131r_scaling.csv (Jul 17 10:08). The v131r_mort_*.csv on disk are STALE from
  12275867 (Jul 9); do not attribute them to v4. Only 1 of 4 mortality chains finished (Chain 3, 245624 s ~68.2 h);
  ingrowth never started; no v131r_status.txt. Gate not runnable, not run.
- ROOT CAUSE = sampler settings, not resources. Resources were correct (16 cpus = 4 chains x threading(4)).
  v3 script raised adapt_delta 0.95->0.99 and max_treedepth 12->15. Treedepth 15 allows 2^15 leapfrog steps/iter
  (8x deeper than 12), so per-chain time went ~11.8 h (v2, finished) to ~68 h+ (v4), blowing the 72 h wall.
- REAL DISEASE (from the 12275867 varcomp on disk): the `eco` random-intercept sd funnels to the boundary
  (sd_est 0.328, sd_l95 1.28e-07). That funnel drives the 566 divergences + treedepth hits (max Rhat 3.64,
  min bulk ESS 5.4). `region` (sd 0.173) and `fortype` (sd 0.479) are well identified. Cranking adapt_delta/
  treedepth crawls through the funnel instead of removing it. Fixed effects are clean and sensible.
- Verdict: PARK. v12.10.1 stays shipped. NOT auto-resubmitted (standing rule); moving forward with Aaron on a v5
  structural fix (see results md 20 Jul TIMEOUT section). FIA true coords stayed on the node.
