# FVS-ACD v13.1, pass 12, pass 9 ledger cleanup, 13 August 2026

Continuation of pass 9 (`20260812_v131_pass9_handoff.md`) and pass 11 (Track E fix, closed
earlier today). Model of record `~/AcadianGY_13.1.r` stays UNMODIFIED throughout. No em dashes.
Aggregates only, no coordinates left any node. Triggered by Aaron's "push forward with all
recommendations on autopilot," working through the pass 9 open-items ledger.

## Results

Three SLURM jobs submitted and completed clean (rc=0 on all). Rescored on Cardinal with
`p4d/p4d_head.R`'s `bp()` formula, same methodology as the rest of the pass 9/11 record.

**Job 13462600** (`p5cvx/p9g_cvx_htfrozen.sbatch`), the CVX_HTCO=FALSE sensitivity Track F flagged
as unverified. Reproduces Track F's array task A=3 (CFG=cvxq, mefia_l, quad mode, the BASE_B
coefficients) exactly except `CVX_HTCO=FALSE` instead of `TRUE`, height held fixed rather than
co-moving with the smeared diameter. mefia_l is not in Track F's HTFIX set, so TOTVOL bias is
`bp(TOTVOL_o, TOTVOL_p)` directly from the results file, no separate height-correction pass needed.
Base gate-off TOTVOL bias -16.531 percent. With CVX_HTCO=TRUE (Track F's original refit),
-12.664 percent, a +3.867 pp gain, matching the recorded 3.866 pp entry. With CVX_HTCO=FALSE (this
run), -14.870 percent, a +1.661 pp gain. Track F's calibration-population estimate predicted the
effect would scale from 3.866 to roughly 1.74 pp (ratio 0.451, from 6.347 to 2.862 percent);
observed scaling is 1.661 pp (ratio 0.430). The prediction holds to within about 5 percent relative,
direction and rough magnitude confirmed. Basal area bias is unchanged between CVX_HTCO=TRUE and
FALSE (+2.146 pp both ways), as expected since BA depends on DBH only and the convexity correction's
height term only touches volume. **Conclusion: the 3.866 pp convexity/second-moment budget entry is
height-co-moving-dependent. With height frozen the true, more conservative contribution is 1.661 pp.
Recommend the published bias budget carry both figures and state which one it is using**, since the
gap between them (2.2 pp) is large enough to matter for anyone auditing the total budget.

**Job 13462616** (`p9g_base_reconcile.sbatch`, 3-task array), the "memat, medev and pef standing
levels do not reproduce" item. Regenerated the v131base gate-off cell on current inputs for all
three sources, same method pass 10 used to catch and fix the stale Baxter baseline, into
`p9g_base_<src>_results.csv` for byte-level comparison before promoting anything.

memat: no `v131base_memat_results.csv` ever existed (confirmed, matching pass 10's finding). New
baseline: n=1757, TOTVOL bias -7.378 percent, BA bias -7.871 percent. Promoted directly to
`v131base_memat_results.csv` (no `_PREV` needed, nothing to preserve).

medev: standing file (`p5m/v131base_medev_results.csv`, 5 August) and the regenerated file are
**byte-identical on the predicted columns**, all 1759 of 1759 rows, max abs diff 0. TOTVOL -5.895
percent, BA -4.625 percent both ways. Standing level does reproduce; not stale, nothing to promote.

pef: standing file (`v131base_pef_results.csv`, 25 July) and the regenerated file are also
**byte-identical**, all 2853 of 2853 rows, max abs diff 0. TOTVOL +1.242 percent, BA -6.326 percent
both ways. Standing level does reproduce; not stale, nothing to promote.

**Conclusion: the ledger item's premise was only half right.** memat genuinely had no baseline on
record (now fixed). medev and pef were never actually stale, unlike Baxter in pass 10; both
reproduce exactly on current inputs despite the date gaps that made them look suspicious. Worth
noting for the ledger's own credibility: "does not reproduce" was true for one of three sources, not
all three, and a date check alone would have wrongly flagged medev and pef as risks. The
regenerate-and-diff was the right call, same as pass 10 concluded.

**Job 13462623** (`p6ing/p9g_xu25Nr2_stembudget.sbatch`), the "xu25Nr2 stem-budget stress test
still not run" item. xu25Nr2 (IMULT 2.5x, r2 refit, SDImax OFF via NOSDI=1) was flagged in
`p6ing/p8_track_a_bias_closeout.md` as carrying the same disabled-SDImax risk as pass 6 config bN,
which alone produced a +6.43 percent stem bias blowup, a risk never directly reverified because no
tree-level output existed for it. This run reproduced the original recipe (recovered from
`p6ing/p7comb_13340586_4.out`'s printed config) with `TREE_OUT` set, writing
`p9g_xu25Nr2_pred_yr1_tree.csv` and `p9g_xu25Nr2_pred_t2_tree.csv` for the first time. Aggregate
reproducibility check against the original pass 7 run: TOTVOL -8.104 vs -8.103 percent, BA -1.335 vs
-1.335 percent, essentially exact, confirming the recipe reconstruction was correct before trusting
the new tree-level numbers.

Stem count (sum of EXPF, trees per unit area) at t2: mean observed 3256.9, mean predicted 2872.3,
bias -11.809 percent (`bp()` on the matched 918 stands). Mean initial (t1) stem count 3353.3, so the
model under-predicts the surviving/recruited stem count by nearly 12 percent over the projection
interval. **This is not the bN-style blowup that was feared.** bN's problem was a +6.43 percent
over-prediction from disabled self-thinning ceiling allowing stand density to run away upward.
xu25Nr2's stem-count bias is the opposite sign and larger in magnitude: an under-prediction, not an
over-prediction. The mechanism is different from what was flagged, so the specific risk named in the
ledger (self-thinning-driven stem inflation) does not reproduce, but a real and larger stem-count
bias exists in the other direction. **Recommend flagging this as an open finding, not a closed risk**:
xu25Nr2 should not ship without understanding why it under-predicts stem count by ~12 percent, likely
worth checking whether the r2 refit's ingrowth or mortality components are removing too many stems
once the self-thinning ceiling is no longer constraining growth the other way.

## Items scoped but deliberately not attempted this pass

**The Chapter 10 1.22 pp bias-budget entry has no derivation file anywhere under `verify`.** Track
F (pass 9) needed a dedicated multi-hour forensic pass to re-derive and correctly rename the
companion 3.87 pp convexity entry, tracing a six-link provenance chain back to the exact script,
job, and log that produced it. The 1.22 pp entry has no equivalent starting point: it "appears only
as a hardcoded prior-track constant in `c4_adversarial.R` and in restatements of the budget," per
pass 9. A search this pass for any script that isolates a "Chapter 10 constraint" contribution to
volume bias (checked `p5con/`, which turned out to be the Baxter self-thinning-frontier k-parameter
work, a different Chapter 10 finding, not this budget entry) did not turn one up. Re-deriving 1.22
properly needs the same kind of dedicated Track F/G forensic pass, not a quick job submission, and
attempting it in the time available this pass risked exactly the kind of unverified number the
firewall discipline exists to prevent. Recommend scoping a Track G in a future pass with the same
budget Track F got.

**`calc_merch_height`'s unpatched silent `try(silent = TRUE)` around `optimize()`.** Pass 9 was
explicit that converting this to a hard stop "is an edge-tree policy call rather than a defect fix,"
because it could abort production runs on genuinely degenerate edge trees. This needs Aaron's
decision on edge-tree policy, not autonomous action. Not attempted.

**The `plot_ba_incr` reparameterization.** Pass 9 Track C found the site gradient in this function
is inverted, not inert (net coefficients -0.03265 on log(rd), -0.01602 on log(csi), collapsing
toward zero as relative density rises via the shared rt term), and that the equation is rank
deficient, but stopped short of building a reparameterized replacement. This is a model-design
task requiring a decision on functional form, not a mechanical fix. Not attempted.

## Firewall notes carried forward

BASE_PREFIX is always v131base. A job or task status carried in a handoff is subject to F9 and
must be re-queried live; do not trust the job states recorded above once time has passed. Do not
enable lever 3a. Client-side MCP timeouts on `cardinal_submit_job` or `cardinal_job_status` do NOT
mean the operation failed; confirmed repeatedly this session, reissue the query rather than
escalate.

## Pass 9 ledger, updated status

Of the seven items still open at the start of this pass: three are now closed with results
(CVX_HTCO sensitivity, memat/medev/pef reconciliation, xu25Nr2 stem budget), one closed as a
new baseline write (memat), two remain genuinely open pending Aaron's judgment
(`calc_merch_height`, `plot_ba_incr`), and one remains open for lack of any derivation to start from
(Chapter 10 1.22 pp). The small-tree 5.0 cm excess-flow defect and the standing +8.765 Baxter
number's provenance were not touched this pass and remain open from pass 9.

## Next steps, priority order

1. Decide whether the published bias budget should report the convexity/second-moment entry as
   3.866 pp (height co-moving) or 1.661 pp (height frozen), or both with a caveat. Recommend both,
   labeled.
2. Open a tracked concern for xu25Nr2's -11.8 percent stem-count under-prediction; this is a
   different defect than the one the ledger flagged, and should not be closed alongside the bN-style
   risk it was checked against.
3. Scope a Track G for the Chapter 10 1.22 pp entry as a dedicated pass, not a quick follow-up.
4. Take `calc_merch_height` edge-tree policy and the `plot_ba_incr` reparameterization to Aaron as
   decisions before any further work on either.
5. Pass 9's remaining untouched items (Baxter +8.765 provenance, small-tree 5.0 cm excess flow)
   still need a pass of their own.
