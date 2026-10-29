# FVS-ACD v13.0 kickoff, prep-and-auto-submit handoff, 7 July 2026 (afternoon)

Continues 20260707_session_handoff.md. v13.0 was kicked off but Cardinal went into an OSC maintenance reboot
(CVE-2026-23111 rolling reboot; all login nodes refusing unprivileged logins) before anything could be
submitted. Per Aaron's call, this session PREPPED everything and armed an auto-submit task, rather than
waiting. Plaintext math, no em dashes.

## What was decided and built this session

The v13.0 task is the JOINT height + basal-area re-anchor, which is new work beyond the 3 July kickoff. The
3 July run tested height ALONE and correctly parked it (the QC edge is covariate shift, ESI over-reads there,
not a functional-form problem). The parity finding reframes it: shipped v12.10.1 over-predicts top height
about +9 percent and under-predicts BA about -8 percent, and the two offset so TOTVOL is roughly unbiased.
So height cannot be corrected alone without driving volume negative; both increments must be re-anchored to
individually unbiased, base-age invariant, in-domain, so the volume identity stays unbiased. Confirmed live on
Cardinal before it went down: scorecard_five_v1210.csv shows v1210 pooled TOPHT +9.1 percent, BA -7.5 percent;
these are the two numbers the joint re-anchor must both drive toward zero without worsening TOTVOL.

Scripts written and parse-clean under sandbox R 4.6.1 (both in repos/fvs-acd/scripts/):
- v130_joint_anchor.R + v130_joint.sbatch. Height side is the 3 July M1 linear-increment and M2 monomolecular
  base-age-invariant anchor on the ME/NH/VT in-domain pairs (ne_plot_table.rds + ne_plot_esi.csv), scored by
  10-fold spatially blocked CV. BA side fits a base-age-invariant BA-increment anchor (monomolecular BAmax =
  b0 + b1*esi, plus a linear reference) from v131g_fitset.rds subset to STATECD 23/33/50, so BA increment is
  unbiased in domain. Domain mask = finite ESI AND EPA L3 in {5.3.1, 8.1.7, 8.1.8, 8.1.1}.
- v131_mort_ingrowth_refit.R + v131_refit.sbatch. Mortality refit drops the mgmt fixed effect and the
  (0+mgd|region) slope (management is a growth effect, deferred to v13.2), keeps region/eco/fortype crossed
  intercepts and the cloglog exposure. Adds an ingrowth (recruitment) hierarchical count response assembled
  from the CONUS tree pairs, negative-binomial with a log_years offset, to lift the NB 45 percent / QC 59
  percent recruitment under-prediction. Fit on recent==0; MagPlot and recent-FIA held out.

Both scripts carry clearly marked `## CONFIRM-ON-RETURN:` blocks for the few column/key names that could not
be verified while Cardinal was down (the v131g stand key and esi bridge for the BA side; the tree-pair column
names, stand key, and DBH ingrowth threshold for the recruitment assembly). The auto-submit session resolves
these against the live schema before submitting.

## The auto-submit mechanism (this is what runs next, no human needed)

Scheduled task `fvs-acd-v13-autosubmit`, hourly (top of hour), notifyOnCompletion off (quiet exits are
silent). Its complete runbook is repos/fvs-acd/_context/V130_AUTOSUBMIT_SPEC.md. State markers in
repos/fvs-acd/_context/v13_autosubmit/ (submitted.flag, scored.flag, failure.md) make it idempotent.

Flow: while Cardinal refuses logins it exits silently. When Cardinal returns it resolves the CONFIRM-ON-RETURN
markers, scp's both scripts, submits both sbatch jobs, and messages Aaron that the fits are queued. On a later
run when both jobs finish it generates candidate MagPlot predictions (cb_v130_results.csv via the verify
harness with the v13.0 anchors swapped in), scores v13.0 on the five-model scorecard against v12.10.1 in BOTH
tails, reruns Bakuzis + the plateau, checks ingrowth is undistorted, evaluates the v13.1 recruitment lift and
mortality convergence, writes a verdict-first results doc (YYYYMMDD_v130_joint_and_v131_refit_results.md),
messages Aaron the verdict, and disables itself.

## Gate (unchanged, do not relitigate)

Adopt v13.0 only if it beats or holds v12.10.1 out of sample on both tails, passes Bakuzis + the plateau, and
does not distort ingrowth. Otherwise document and PARK (a valid, expected outcome). Nothing ships into an
operational AcadianGY_*.r file automatically; shipping is a separate human-reviewed step. v12.10.1 stays the
shipped August version regardless.

## If picking this up manually instead of via the task

Same steps: follow V130_AUTOSUBMIT_SPEC.md. Check Cardinal with the SSH block in the spec; if up, resolve the
CONFIRM-ON-RETURN markers, submit, then score and gate. The 18 August Hennigar meeting is still a v12.10.1
conversation; v13 is the fall arc and is not needed for August.

## One operational note

The scheduled task uses SSH-over-bash and file tools. If its runs pause on a tool-approval prompt, run it once
manually (Scheduled sidebar, Run now) to pre-approve; after that the approvals auto-apply.

## Status update, 7 July 2026 later same day (autopilot advanced itself)

Cardinal returned and the fvs-acd-v13-autosubmit task ran on its own: the v12.10.1 operational-domain
scorecard is DONE (domain.flag; 492 of 733 stands in domain via the ecoregion join; TOTVOL bias tightened to
-1.63 percent in domain vs -3.64 all plots; numbers written into 20260707_v12101_operational_domain.md), and
BOTH v13 fits are SUBMITTED (submitted.flag): v130_joint_anchor jobid 12255489 (2h; original 12255451 failed
at 3s and was resubmitted), v131_mort_ingrowth jobid 12255452 (8h). Markers were resolved live, including a
real patch: the v130 BA section referenced lowercase `years` but v131g_fitset carries `YEARS`, so an alias was
added; the BA anchor fell back to esi-free (no PLT_CHR bridge on v131g) with random 10-fold (no LAT/LON on the
BA set); the ingrowth assembly used the recruit-flag path (TREESTATUS1/2, DBH1/2 cm, TPH2). scored.flag is not
yet set, so scoring and the gate are pending job completion.

Two tested gate harnesses were then staged so the SCORING step runs vetted code, not improvised logic:
scripts/v130_score_gate.R (five-model scorecard for v130 vs v1210 on POOLED_indomain plus ESI and QMD tails,
with the explicit both-tails pass conditions and an ADOPT_PENDING/PARK verdict) and scripts/v131r_gate.R
(mortality convergence + no-mgmt-term check, ingrowth convergence and FIA recruitment ratio, optional NB/QC
MagPlot lift vs the shipped 0.45/0.59). Both are referenced in V130_AUTOSUBMIT_SPEC.md under "Staged gate
harnesses"; the task parse-checks them on Cardinal before running. They could not be parse-checked in-session
because that Cowork sandbox lost outbound network and R after a reboot; parse-check them on Cardinal first.

Net remaining: the hourly task monitors the two jobs, generates cb_v130_results.csv via the verify harness,
runs the two staged gates plus Bakuzis, writes the dated results doc, pings Aaron the verdict, and disables
itself. Nothing ships to an operational AcadianGY_*.r automatically.
