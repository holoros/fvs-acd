# FVS-ACD v13 handoff + next-session kickoff, 7 July 2026 (evening)

For starting a fresh chat to finish v13.0 and v13.1. A local Cardinal MCP server now exists and connects, so
the next session reaches Cardinal through MCP tools (host-side ssh) rather than the Cowork sandbox SSH, which
was intermittently losing DNS. Plaintext math, no em dashes. The paste-ready prompt is the last section.

## Where things stand right now

Shipped operational model is still FVS-ACD v12.10.1 (frozen for the 18 August Hennigar meeting). v13 is the
fall arc and is NOT needed for August. Two v13 fits are running on Cardinal and one v12.10.1 refinement is done.

Done this cycle:
- v12.10.1 operational domain scorecard. The Acadian ESI + ecoregion mask was applied on top of the frozen
  config (no equation change). 492 of 733 MagPlot stands in domain via the ecoregion join
  (magp_qcnb_ecol3_v2.csv). In domain the pooled TOTVOL bias tightens to -1.63 percent (vs -3.64 all plots);
  the offsetting signature stays (TOPHT about +4 percent, BA about -9 percent). Written into
  20260707_v12101_operational_domain.md (deck/GTR ready). This was Aaron's approved August refinement:
  domain mask + freeze, v13 carries the rest.

Submitted and running on Cardinal (account PUOM0008):
- v130_joint_anchor  jobid 12255489  (~2h; v130_joint.sbatch). Status file ~/v130_joint/v130_status.txt
  becomes "fit_complete". Original 12255451 failed at 3s and was resubmitted.
- v131_mort_ingrowth jobid 12255452  (~8h; v131_refit.sbatch). Status file ~/v13_kickoff/v131r_status.txt
  becomes "fit_complete".

Live marker resolutions already applied at submit (do not redo): v130 BA section referenced lowercase `years`
but v131g_fitset carries `YEARS`, so an alias was added; the v130 BA anchor fell back to esi-free (no PLT_CHR
bridge on v131g) with random 10-fold (no LAT/LON on the BA set), while the height anchor uses esi + spatial
folds; the v131 ingrowth assembly used the recruit-flag path (TREESTATUS1/2, DBH1/2 cm, TPH2) on a stand key
byte-identical to v131g.

Not done yet: scoring and the gate for both fits (scored.flag is absent).

## What v13.0 and v13.1 are (one line each)

- v13.0 joint height + BA re-anchor. Shipped v12.10.1 over-predicts top height and under-predicts BA, offsetting
  in volume. v13.0 re-anchors BOTH increments to individually unbiased, base-age invariant, in domain, so the
  volume identity stays unbiased. Adopt only if it beats or holds v12.10.1 on the scorecard out of sample on
  BOTH tails, passes Bakuzis + the plateau, and does not distort ingrowth. Otherwise document and PARK.
- v13.1 mortality + ingrowth hierarchical refit, NO management hazard term (management is a growth effect,
  deferred to v13.2). Targets the ingrowth under-prediction (NB 45 percent, QC 59 percent of observed). Pass
  bar is convergence + a recruitment lift + no mortality-structure regression. Structural, not shipped this run.

## Key files (all in repos/fvs-acd unless noted)

- _context/V130_AUTOSUBMIT_SPEC.md   the complete runbook: state machine, SSH, CONFIRM-ON-RETURN checks,
  submit sequence, staged gate harnesses, and the full SCORING AND GATE procedure. Read this first.
- scripts/v130_joint_anchor.R (+ v130_joint.sbatch)   the v13.0 fit (running).
- scripts/v131_mort_ingrowth_refit.R (+ v131_refit.sbatch)   the v13.1 fit (running).
- scripts/v130_score_gate.R   staged v13.0 gate: v130 vs v1210 scorecard on POOLED_indomain + ESI and QMD
  tails, explicit pass conditions, ADOPT_PENDING/PARK verdict. Consumes cb_v130_results.csv + cb_v12102_results.csv.
- scripts/v131r_gate.R   staged v13.1 gate: mortality convergence + no-mgmt-term, ingrowth convergence + FIA
  recruitment ratio, optional NB/QC MagPlot lift vs 0.45/0.59.
- scripts/v12101_domain_scorecard.R   the v12.10.1 domain re-scoring (already run).
- _context/v13_autosubmit/   state markers: domain.flag (set), submitted.flag (set, holds job ids), scored.flag
  (absent), failure.md.

NOTE the two gate scripts were written but NOT parse-checked locally (that sandbox lost R after a reboot).
Parse-check both on Cardinal before running: Rscript -e 'parse("v130_score_gate.R")' and same for v131r_gate.R.

## Cardinal specifics

User crsfaaron, cluster cardinal.osc.edu, account PUOM0008, R module load order gcc/12.3.0 then
gdal/3.7.3 geos/3.12.0 proj/9.2.1 then R/4.4.0 (each on its own line). Job dirs: ~/v130_joint, ~/v13_kickoff,
~/magplot/verify. Fitted v130 anchors land at ~/v130_joint/v130_height_anchor.rds and v130_ba_anchor.rds.
The MagPlot verify harness that produces cb_*_results.csv is one of ~/magplot/verify/cardinal_magplot_insource_v17.R
or cardinal_magplot_acadgy_verify.R (read it, swap in the v130 anchors to make cb_v130_results.csv). Bakuzis is
~/magplot/verify/bakuzis_allmodels.R. FIA true coordinates never leave the node; aggregates only.

## Coordination: the scheduled task

An hourly scheduled task fvs-acd-v13-autosubmit is also set to monitor, score, and gate these jobs. If you drive
manually in the new chat, DISABLE it first (update_scheduled_task fvs-acd-v13-autosubmit enabled=false) so you do
not both write scored.flag and the results doc. Re-enable it only if you want it as a backup after you stop.

## Gate conditions (so the new session does not have to re-derive them)

v13.0 (in domain AND in each tail subset ESI_low/ESI_high/QMD_small/QMD_large): abs(TOPHT bias_v130) <=
abs(TOPHT bias_v1210); abs(BA bias_v130) <= abs(BA bias_v1210); abs(TOTVOL bias_v130) <= abs(TOTVOL bias_v1210)
+ 1.0 and TOTVOL NSE not down more than 0.02; no metric NSE regresses more than 0.03. All hold -> ADOPT_PENDING,
else PARK with the failing subset. Then Bakuzis + plateau must also pass. v13.0 baseline to beat (v12.10.1 in
domain): BA -9.20 percent, TOPHT +4.16 percent, TOTVOL -1.63 percent.

v13.1: mortality max Rhat < 1.05 and 0 divergences and no management term; ingrowth converged; FIA aggregate
predicted/observed recruitment ratio near 1.0 (0.85 to 1.20); optional NB/QC lift above 0.45/0.59.

## After the gates

Write repos/fvs-acd/YYYYMMDD_v130_joint_and_v131_refit_results.md, verdict first, in Aaron's voice (match
20260703_v13_kickoff_results.md and 20260704_v131_growthscale_results.md: verdict up front, adversarial pass,
deliverables/provenance footer). Record the scorecard deltas in both tails, the Bakuzis/plateau status, the
v13.1 recruitment lift and convergence, and the adopt-pending-or-park decision with the honest reason. Touch
_context/v13_autosubmit/scored.flag. Nothing ships to an operational AcadianGY_*.r file automatically; shipping
is a separate human-reviewed step. If a step does not clear the bar, PARK it and say so; that is a valid,
expected outcome (the 3 July height-alone refit was correctly parked).

## Forward items beyond this gate

- v13.2 (increment refit + the growth-scale management release as a hierarchical predictor + per-prediction
  credible intervals) and v13.3 (climate scenario mode, data expansion, scorecard CI gate) are the next steps
  once v13.0/v13.1 land. Sequence in 20260703_v13_execution_plan.md.
- The single biggest unblock is the August ask to Hennigar for the provincial managed remeasurement and PSP
  treatment data (draft staged: 20260702_reply_to_hennigar_DRAFT.md). It unblocks the true NB vs QC transfer
  and the data expansion in v13.2/v13.3.

## Settled, do not relitigate

Keep ESI. Keep the v12.9.x composition and ecoregion aware brms SDImax. Keep the FIA NSVB scorecard with TOST
and Bakuzis as the standing evaluation. Hold MagPlot and recent-FIA out of every fit. v12.10.1 is frozen for
August.

---

## PASTE-READY NEXT-SESSION PROMPT

Copy everything below into the new chat.

```
Select the CRSF-Cowork folder. We are finishing FVS-ACD v13.0 and v13.1. A local Cardinal MCP server is now
connected, so use its tools to reach Cardinal (discover them with ToolSearch, e.g. query the osc-cardinal
server; the hpc-cardinal skill describes the setup). Fall back to sandbox SSH only if the MCP is unavailable.

Read these first, in order:
1. repos/fvs-acd/_context/handoffs/20260707_v13_NEXT_SESSION_handoff.md  (full state, job ids, gate conditions)
2. repos/fvs-acd/_context/V130_AUTOSUBMIT_SPEC.md  (the complete runbook and SCORING AND GATE procedure)

Then do this, autonomously, using subagents for the two independent tracks (v13.0 and v13.1) once each fit is
done:

0. Take ownership: disable the scheduled task so it does not collide, update_scheduled_task
   fvs-acd-v13-autosubmit enabled=false.
1. Check job status on Cardinal: v130_joint jobid 12255489, v131_mort_ingrowth jobid 12255452 (sacct/squeue).
   Confirm ~/v130_joint/v130_status.txt and ~/v13_kickoff/v131r_status.txt.
2. v13.0 track (when v130 is complete): generate cb_v130_results.csv by wiring the fitted v130 anchors
   (~/v130_joint/v130_height_anchor.rds, v130_ba_anchor.rds) into the MagPlot verify harness
   (~/magplot/verify/cardinal_magplot_insource_v17.R or cardinal_magplot_acadgy_verify.R). Parse-check then run
   scripts/v130_score_gate.R in ~/magplot/verify, and run Bakuzis (bakuzis_allmodels.R) with the v130 trajectory
   added. Apply the v13.0 gate (both tails + Bakuzis + plateau + ingrowth-not-distorted).
3. v13.1 track (when v131 is complete): parse-check then run scripts/v131r_gate.R in ~/v13_kickoff. Check
   mortality convergence + no mgmt term, ingrowth convergence + recruitment ratio, and the NB/QC lift if a
   MagPlot recruitment file exists.
4. Write repos/fvs-acd/YYYYMMDD_v130_joint_and_v131_refit_results.md, verdict first, in my voice (match
   20260703_v13_kickoff_results.md), with the scorecard deltas in both tails, Bakuzis/plateau status, the v13.1
   recruitment lift and convergence, and the adopt-pending-or-park decision with the honest reason. Touch
   repos/fvs-acd/_context/v13_autosubmit/scored.flag.

Hard constraints: keep ESI, keep the v12.9.x brms SDImax, keep the FIA NSVB + TOST + Bakuzis scorecard, hold
MagPlot and recent-FIA out of every fit. FIA true coordinates never leave Cardinal; aggregates only. No em
dashes. Do not ship to an operational AcadianGY_*.r file; adopt-pending or park is documented, shipping is a
separate human step. If a gate is not cleared, PARK it and say so plainly. If either fit FAILED, pull the .err
tail, say what broke, and stop for my review rather than blindly resubmitting. v12.10.1 stays the shipped
August version regardless.
```
