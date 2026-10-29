# FVS-ACD v13.1 next-session prompt

Paste this to start the next session.

---

Focus this session on FVS-ACD v13.1, the hierarchical mortality and ingrowth refit, picking up from the
finalized v12.11 candidate. Read repos/fvs-acd/20260722_session_handoff.md,
20260722_v1211_allsites_and_redteam_reframes.md, and 20260721_v1211_candidate_report.md first for where v12.11
landed. v12.11 is a finalized candidate; v12.10.1 stays shipped. Connect to Cardinal via hpc-cardinal. No em
dashes, aggregates only, proprietary tree data stays on the node, use subagents for independent tracks.

Why v13.1: v12.11 closed the managed and mature gaps (beats OSM on CTRN, NB, Baxter) but the developing Maine
FIA end is still under-predicted (whole-plot -16.1 vs OSM -6.3) and does not improve at subplot grain (-24.9 to
-24.8), because a stand-level ingrowth multiplier cannot represent patchy subplot recruitment. Two managed
flags remain (QC volume over-correction, SILC BA widening). These are recruitment and mortality structure
problems that a hierarchical refit addresses principledly.

First steps:
1. Harvest the running v13.1 hierarchical refit, Cardinal job 12470707 (v131refit_v5, the prior resubmit with
   6-day wall time). Check sacct, read ~/logs/v131refit_v5_*.out, and if it converged read the saved brms
   objects and the outputs v131r_ingrowth_byregion.csv, v131r_ingrowth_bymgmt.csv, v131r_status.txt. The fit
   script is ~/_scripts/v131_mort_ingrowth_refit.R. If it timed out again, diagnose the within-chain
   bottleneck (chain 3 took about 2.84 days for 2000 iterations) and consider reducing iterations, tightening
   priors or inits, reducing the data, or within-chain threading before resubmitting.
2. Read the converged stand-level recruitment and mortality posteriors and compare them to the v12.11 interim
   lever magnitudes (ingrowth about 2.5x, management-gated mortality fmin 0.13 k 12.4 RD0 0.38). The posteriors
   are the principled source for the v13.1 stand equations.
3. Refit at the FIA subplot grain, not whole plot. The subplot benchmark is built
   (~/magplot/verify/multisrc/bench_mefia_subp_*, 2858 units, per the fia-subplot-hex conventions). Fit the
   hierarchical recruitment and mortality at subplot scale so the developing-end recruitment is represented at
   the grain Aaron prefers.
4. Address the two v12.11 managed flags in the refit: the QC volume over-correction from the management gate,
   and the SILC basal-area widening.

Also queued for v13 era, not blocking: recalibrate the crown-ratio recession coefficients (Russell, Weiskittel
and Kershaw 2014) weighted to young high-CCF developing stands (crown ratio feeds ddbh and dht, see
20260721_crown_ratio_investigation.md); and extend the Lever 4 hardwood height correction to more species via
the Castle Master form/risk to HRF_INVENTORY height join on Google Drive (the RO coefficient was capped pending
this). Fix the sub-2.5 cm height-imputation gap.

Validate v13.1 the same way v12.11 was: byte-identical gate-off against the frozen model, the multi-source
maturity gradient holding Baxter out, the all-sites Maine, NB, Quebec comparison against base and OSM v2.26.1,
the Bakuzis five relations, the long-horizon plateau, and a red-team pass. Route deliverables through the same
report, GTR, and deck.
