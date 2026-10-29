# v13.1 harvest run status, 23 July 2026 (~07:30 ET scheduled run)

Both in-flight jobs are still RUNNING. Nothing was harvestable this pass, so per the
runbook I did not run the gate-off smoke test or the all-sites scorecard (both depend on
a converged mortB posterior that does not exist yet), and I did not resubmit or touch
either job.

## Job 12526556 (v131mortB, whole-plot mortality repair, eco re-nested within region)
- State RUNNING on c0026, elapsed 20h06m at check. Wall TimeLimit 72h, EndTime 25 Jul 11:25.
- 4 chains, 2500 iterations each. Per-chain warmup progress at check:
  chain 1 = 1000/2500 (40%), chain 2 = 700/2500 (28%), chain 3 = 600/2500 (24%),
  chain 4 = 1100/2500 (44%). All still in Warmup.
- Slowest chain (3) rate is ~30 iter/hr; chains 1/4 ~50 to 55 iter/hr.
- .err shows 52 gamma_lpdf "random variable is 0, must be positive finite" rejection
  messages over 20h. These are the Informational warmup rejections the runbook flags as
  benign when sporadic; 52 across 4 chains of warmup is not pathological, but the gamma
  (line 115) is the mortality hazard term to watch on the varcomp/Rhat read.
- Wall risk: if the slowest chain holds ~30 iter/hr, finishing 2500 needs ~63h more while
  only ~52h of wall remain. Post-warmup sampling is usually much faster than warmup, so a
  finish is plausible but not assured. This is the one real decision this pass.

## Job 12547720 (v131sp_prod, subplot production fit, resubmit after the brmsprior NULL-seed fix)
- State RUNNING on separate node, elapsed 1h17m. Wall 72h. Healthy start.
- 723,830 subplots, 208,441 plots, recruit zero frac 0.9048.
- Grouping confirmed: (1|region)+(1|region:eco)+(1|fortype)+(1|plot) for both recruitment
  (single negbinomial) and mortality.
- Recruitment fit warmup at iteration 1 at check; no crash, the NULL-seed bug did not recur.
- ETA per the runbook 30 to 45h, i.e. roughly 24 to 25 July. On track.

## Already banked (context, not this pass)
- v12.11 is the finalized candidate; v12.10.1 stays shipped.
- Whole-plot ingrowth posterior converged (Rhat 1.006), ranef exported at
  ~/v13_kickoff/v131r_ingrowth_ranef.csv.

## Next pass
- Re-check 12526556 first. If COMPLETED: read convergence/fixef/varcomp, require max Rhat
  < 1.01 and region:eco nested sd l95 > 0, export ranef to v131r_mortB_ranef.csv, then run
  gate-off byte-identity and the switches-ON scorecard.
- Re-check 12547720 for completion or a firmer ETA.
