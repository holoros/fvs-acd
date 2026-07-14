# FVS-ACD v13.0 / v13.1 auto-submit spec

Self-contained runbook for the `fvs-acd-v13-autosubmit` scheduled task. Cardinal (OSC) went into a
maintenance reboot on 7 July 2026 while v13.0 was being kicked off, so the fits could not be submitted
live. This runbook is executed on a cadence; each run is a FRESH session with no memory, so everything
needed is here. Plaintext math, no em dashes. Do the work autonomously; surface a real decision only if the
gate outcome is genuinely ambiguous.

## Goal

Run two independent Cardinal fits the moment the cluster accepts logins again, then score and gate them:

- v13.0 joint height + basal-area re-anchor. Script `scripts/v130_joint_anchor.R`, sbatch
  `scripts/v130_joint.sbatch`. The shipped v12.10.1 over-predicts top height about +9 percent and
  under-predicts BA about -8 percent; they offset so TOTVOL is roughly unbiased. v13.0 re-anchors BOTH
  increments to individually unbiased, base-age invariant, in-domain, so the volume identity stays unbiased.
- v13.1 mortality + ingrowth hierarchical refit, NO management hazard term (management is a growth effect,
  deferred to v13.2). Script `scripts/v131_mort_ingrowth_refit.R`, sbatch `scripts/v131_refit.sbatch`.
  Ingrowth is the recruitment target: shipped predicts NB 17.9 vs 39.8, QC 11.7 vs 19.7 stems ha-1 yr-1.

Settled, do not relitigate: keep ESI, keep the v12.9.x composition and ecoregion aware brms SDImax, keep the
FIA NSVB scorecard with TOST and Bakuzis as the standing evaluation, hold MagPlot and recent-FIA OUT of any
fit. v12.10.1 stays shipped unless a step clears the gate.

## State machine (idempotent, do not double-submit)

State lives in `repos/fvs-acd/_context/v13_autosubmit/`. On each run:

1. If `scored.flag` exists: everything is done. Disable this scheduled task
   (`update_scheduled_task` enabled=false) and stop.
2. Else if `submitted.flag` exists: jobs are already in the queue. Read the job ids from it, check
   `sacct`/`squeue`. If BOTH jobs COMPLETED and both status files exist on Cardinal
   (`~/v130_joint/v130_status.txt` and `~/v13_kickoff/v131r_status.txt` == "fit_complete"), run SCORING AND
   GATE below, write results, `touch scored.flag`, notify Aaron, disable the task. If still RUNNING/PENDING,
   do nothing and exit quietly. If either FAILED, pull the `.err` log, write a short failure note to
   `_context/v13_autosubmit/failure.md`, notify Aaron, and stop (do not auto-resubmit; a human should look).
3. Else (`submitted.flag` absent): try SSH. If Cardinal refuses logins (still down), exit quietly. If up, run
   SUBMIT below.

## SSH setup (run at the top of every Cardinal bash call, sandbox is isolated per call)

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
PERSIST="$(find /sessions/*/mnt -maxdepth 3 -type d -name .ssh-cardinal 2>/dev/null | head -1)"
cp "$PERSIST/id_ed25519_cardinal" ~/.ssh/id_ed25519 && chmod 600 ~/.ssh/id_ed25519
printf 'Host cardinal\n  HostName cardinal.osc.edu\n  User crsfaaron\n  IdentityFile ~/.ssh/id_ed25519\n  ConnectTimeout 15\n  StrictHostKeyChecking accept-new\n' > ~/.ssh/config; chmod 600 ~/.ssh/config
ssh -F ~/.ssh/config cardinal 'echo SSH_OK && hostname'
```
"System is going down / Unprivileged users are not permitted" or exit 255 with no SSH_OK means still down:
exit quietly. Module load order on Cardinal is mandatory and each on its own line:
`module load gcc/12.3.0`, then `module load gdal/3.7.3 geos/3.12.0 proj/9.2.1`, then `module load R/4.4.0`.

## STEP 0, independent: v12.10.1 operational domain scorecard (do this first, once Cardinal is up)

This is separate from the v13 fits and does not depend on them. Aaron approved operationalizing the domain
mask on the frozen v12.10.1 config for August (no equation change). Guard it with its own marker
`_context/v13_autosubmit/domain.flag`. If that marker is absent and Cardinal is up: scp
`scripts/v12101_domain_scorecard.R` to `~/magplot/verify/`, resolve its one CONFIRM-ON-RETURN marker (attach
per-stand EPA L3 ecoregion for the MagPlot stands if such a table exists; otherwise accept the documented
fallback, ESI-covered AND PROV != QC, consistent with Hennigar 2018 and the 3 July over-read finding), run it
(light job, a login-node `Rscript` is fine, or a 5-minute sbatch), pull `scorecard_domain_v12101.csv`, and
fill the in-domain vs all-plots pooled BA/TOPHT/TOTVOL numbers into
`repos/fvs-acd/20260707_v12101_operational_domain.md` (replace the "recomputed on Cardinal" note with the
actual table). Then `touch domain.flag` and message Aaron one line that the operational-domain scorecard is
ready. This can complete on an early run even while the v13 fits are still queued or running.

## SUBMIT (only when Cardinal is up and submitted.flag is absent)

Before submitting, resolve the CONFIRM-ON-RETURN markers in both scripts against the LIVE data, because they
depend on column and key names that could not be verified while the cluster was down. Do this by launching a
short interactive Rscript that prints the needed `names()`/`str()` and patch the scripts if a detected name
differs from the script's assumption. Do not submit a script whose assumed columns are contradicted by the
live schema.

v130_joint_anchor.R markers (all in the BA section):
- `names(readRDS("~/v13_kickoff/v131g_fitset.rds"))` and `str()`. Confirm responses gross_ba_ann, net_ba_ann,
  dq_ann and predictors rd, ln_qmd, ba, and the grouping region/eco/fortype/mgmt/recent exist.
- Confirm `region` holds STATECD and subset region in c(23,33,50) for ME/NH/VT.
- Detect the stand/plot key column; verify whether a PLT_CHR-style key exists to bridge to
  `~/bakeoff_v13/ne_plot_esi.csv` (esi by rid). If joinable, fit the BA anchor with esi (BAmax = b0 + b1*esi).
  If not, the script already falls back to the esi-free BA anchor on rd + ln_qmd + ba and tags the omission;
  accept that fallback rather than blocking.
- Confirm whether LAT/LON ride along for spatial folds; if absent the script uses random 10-fold (it warns).

v131_mort_ingrowth_refit.R markers (the ingrowth assembly block):
- `names()` of the CONUS tree pairs `~/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds`.
  Resolve the pick() candidate lists: stand key (PLT_CN_cond1, CONDID_cond1, INVYR1, INVYR2), interval
  (YEARS/REMPER), tree status (TREESTATUS1/2), DBH1/2 in cm, expansion (TPH2 or TPA2*2.47105).
- Confirm `v131g_fitset.rds` persists a `stand_key` the ingrowth counts can join on (mirror the key built in
  `scripts/v131_growth_assembly_fit.R`). If the growth set lacks a persisted key, rebuild the same key on both
  sides from PLT_CN_cond1 + CONDID_cond1 + INVYR1 + INVYR2.
- Confirm the ingrowth threshold (script uses DBH_INGROWTH_CM = 2.54; recruit = live at t2 with no qualifying
  t1 record at or above threshold). Match the FIA ingrowth convention used elsewhere in the repo.

Then stage and submit:
```bash
ssh -F ~/.ssh/config cardinal 'mkdir -p ~/v130_joint ~/v13_kickoff ~/logs'
scp -F ~/.ssh/config repos/fvs-acd/scripts/v130_joint_anchor.R repos/fvs-acd/scripts/v130_joint.sbatch cardinal:~/
scp -F ~/.ssh/config repos/fvs-acd/scripts/v131_mort_ingrowth_refit.R repos/fvs-acd/scripts/v131_refit.sbatch cardinal:~/
ssh -F ~/.ssh/config cardinal 'cd ~ && sbatch --parsable v130_joint.sbatch && sbatch --parsable v131_refit.sbatch'
```
Write both parsed job ids and the submit timestamp into `_context/v13_autosubmit/submitted.flag`. Notify Aaron
that the fits are queued. Exit; the next cadence run picks up monitoring.

## Staged gate harnesses (use these, do not improvise the gate)

Two tested gate scripts are staged in scripts/ and should be scp'd to Cardinal and run in the SCORING step
rather than writing the gate logic live:
- scripts/v130_score_gate.R -> run in ~/magplot/verify. Consumes cb_v130_results.csv + cb_v12102_results.csv,
  applies the ecoregion domain mask, builds the scorecard for v130 and v1210 on POOLED_indomain plus both
  tails (ESI/productivity low-high and QMD small-large), writes scorecard_v130.csv, v130_gate_delta.csv, and
  v130_gate_verdict.csv, and prints ADOPT_PENDING or PARK with the failing subset. Pass conditions: TOPHT bias
  and BA bias both move toward 0 versus v1210, TOTVOL bias not worse by more than 1 point and its NSE not down
  more than 0.02, and no metric NSE regresses more than 0.03, in domain AND in every tail subset. If
  cb_v130_results.csv does not exist yet it exits cleanly (gate deferred).
- scripts/v131r_gate.R -> run in ~/v13_kickoff. Checks mortality convergence (max Rhat < 1.05, 0 divergences)
  and that no management term is present, ingrowth convergence, the FIA aggregate predicted/observed
  recruitment ratio (target ~1.0), and, if a MagPlot NB/QC recruitment file exists, the province recruitment
  lift versus the shipped 0.45/0.59 baseline. Writes v131r_gate_verdict.csv with STRUCTURAL_PASS / PARK /
  DEFERRED.

Parse-check each on Cardinal (`Rscript -e 'parse(...)'`) before running. The one live prerequisite the v130
gate needs is cb_v130_results.csv itself: generate it first by wiring the fitted v130 anchors
(~/v130_joint/v130_height_anchor.rds, v130_ba_anchor.rds) into the MagPlot verify harness (STEP 1 below), then
run v130_score_gate.R. Bakuzis + plateau remain the separate bakuzis_allmodels.R check with the v130
trajectory added.

## SCORING AND GATE (when both jobs COMPLETED)

Pull the fit outputs (aggregates only, coordinates never leave the node):
`~/v130_joint/v130_height_cv.csv`, `v130_ba_cv.csv`, `v130_domain_counts.csv`;
`~/v13_kickoff/v131r_mort_*.csv`, `v131r_ingrowth_*.csv`.

v13.0 gate (adopt only if it BEATS OR HOLDS v12.10.1 out of sample on BOTH tails, passes Bakuzis + the
plateau, and does not distort ingrowth):
1. Generate candidate MagPlot predictions by wiring the fitted v13.0 height and BA anchors into the MagPlot
   verify harness. The shipped harness that produced `~/magplot/verify/cb_v12102_results.csv` is one of
   `~/magplot/verify/cardinal_magplot_insource_v17.R` / `cardinal_magplot_acadgy_verify.R`; read it, swap the
   A-from-ESI height anchor and the BA increment for the v13.0 fitted anchors, and write
   `cb_v130_results.csv` with the same columns (BA/TOPHT/TOTVOL/etc, _t1/_o/_p).
2. Score `cb_v130_results.csv` on the five-model multi-dimensional scorecard exactly as
   `scorecard_five_v1210.csv` was built (bias_pct, rmse, mae, nse, cor, tost_lvl_equiv, pai_bias,
   tost_inc_equiv), pooled and by jurisdiction, and ALSO split by tail: low vs high productivity/size
   (e.g. ESI or TOPHT_t1 median split, and a QMD split) so "both tails" is explicit. Compare v130 row-by-row
   to the v1210 rows already in `scorecard_five_v1210.csv`. The pass condition is: TOPHT bias moves toward 0
   from +9 percent AND BA bias moves toward 0 from -8 percent AND TOTVOL bias does not worsen, with NSE/TOST
   not regressing, in BOTH tails, in domain.
3. Bakuzis + plateau: rerun `~/magplot/verify/bakuzis_allmodels.R` (or the standing Bakuzis harness) with the
   v130 trajectory added; confirm the named relations (Eichhorn, Reineke self-thinning, site ordering,
   Sukachev, yield-density) still pass and the density trajectory still plateaus at the realistic maximum.
4. Ingrowth not distorted: confirm v13.0 does not change the ingrowth path (height/BA anchor is separate from
   recruitment) using the density-released ingrowth check in the harness.

v13.1 gate: from `v131r_ingrowth_byregion.csv`, confirm predicted recruitment rises toward observed for NB and
QC (target closing the 45 percent / 59 percent gap) with mortality still converged (max Rhat < 1.05, 0
divergences on the mortality fit) and no management hazard term. v13.1 is a structural refit, not shipped this
run; the pass bar is convergence + the recruitment lift + no scorecard regression on mortality-linked metrics.

If a step clears the bar, note it adopted-pending-v13.2-integration. If not, document and PARK (that is a
valid, expected outcome, exactly as the 3 July height-alone refit was parked). Either way it is not shipped
into an operational AcadianGY_*.r file by this task; shipping is a separate human-reviewed step.

## Write-up and notify

Write `repos/fvs-acd/YYYYMMDD_v130_joint_and_v131_refit_results.md` with: verdict up front, the domain-mask
counts, the height and BA in-domain CV ratios, the five-model scorecard deltas vs v12.10.1 in both tails, the
Bakuzis/plateau status, the v13.1 recruitment lift and convergence, the gate decision (adopt-pending or park)
with the honest reason, and the next concrete step. Match the voice of `20260703_v13_kickoff_results.md` and
`20260704_v131_growthscale_results.md` (verdict-first, adversarial pass, deliverables/provenance footer). Then
`touch scored.flag`, notify Aaron with a two-line summary and the results-file path, and disable this task.

## Provenance / constraints

All computation on Cardinal (~/v130_joint, ~/v13_kickoff, ~/magplot/verify); aggregates only, FIA true
coordinates never leave the node. MagPlot and recent-FIA held out of every fit. No em dashes in any deliverable.
