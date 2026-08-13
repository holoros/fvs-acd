# FVS-ACD v13.1, pass 12, pass 9 ledger cleanup, 13 August 2026

Continuation of pass 9 (`20260812_v131_pass9_handoff.md`) and pass 11 (Track E fix, closed
earlier today). Model of record `~/AcadianGY_13.1.r` stays UNMODIFIED throughout. No em dashes.
Aggregates only, no coordinates left any node. Triggered by Aaron's "push forward with all
recommendations on autopilot," working through the pass 9 open-items ledger.

## Launched this pass, results pending

Three SLURM jobs submitted, all confirmed running or queued as of this writing. Results to be
filled in once they land; do not treat any number below as final until then.

**Job 13462600** (`p5cvx/p9g_cvx_htfrozen.sbatch`), the CVX_HTCO=FALSE sensitivity Track F flagged
as unverified. Reproduces Track F's array task A=3 (CFG=cvxq, mefia_l, quad mode, the BASE_B
coefficients) exactly except `CVX_HTCO=FALSE` instead of `TRUE`, i.e. height held fixed rather than
co-moving with the smeared diameter. Track F's calibration-population estimate: freezing height
should drop the effect from 6.347 to 2.862 percent, which would scale the 3.866 pp convexity/
second-moment budget entry to roughly 1.74 pp. Output `p5cvx/p9g_cvxq_htfrozen_mefia_l_results.csv`.
Once it lands, rescore against `v131base_mefia_l_results.csv` with the same `bp()` formula
(`p4d/p4d_head.R` line 32) Track F used, and record whether the roughly-1.74 pp prediction holds.

**Job 13462616** (`p9g_base_reconcile.sbatch`, 3-task array), the "memat, medev and pef standing
levels do not reproduce" item. Regenerates the v131base gate-off cell on current inputs for all
three sources, same method pass 10 used to catch and fix the stale Baxter baseline: writes to
`p9g_base_<src>_results.csv`, not directly over the standing file, so a byte-identity or
level-delta comparison can be made before anything is promoted. Found before launching: no
`v131base_memat_results.csv` exists anywhere (matches pass 10's finding that memat has no v131base
on record at all); `p5m/v131base_medev_results.csv` exists (5 August, postdates its own inputs by
about 30 minutes, not obviously stale by date); `v131base_pef_results.csv` exists at repo root
(25 July, postdates its multisrc inputs which are dated 16 July). Date order alone did not predict
the Baxter staleness either, so all three still need the actual regenerate-and-diff, not just a
date check.

**Job 13462623** (`p6ing/p9g_xu25Nr2_stembudget.sbatch`), the "xu25Nr2 stem-budget stress test
still not run" item. xu25Nr2 (IMULT 2.5x, r2 refit, SDImax OFF via NOSDI=1) was flagged in
`p6ing/p8_track_a_bias_closeout.md` as carrying the same disabled-SDImax risk as pass 6 config bN,
which alone produced a +6.43 percent stem bias blowup, a risk "not directly reverified for
xu25Nr2." No tree-level output was ever written for it (only the mefia_l aggregate). This run
reproduces the original recipe (recovered from `p6ing/p7comb_13340586_4.out`'s printed config:
`MODEL_FILE=p4e/model_b0b1b2.r`, r2 coefficients B0/B1/B2, IMULT=2.50, NOSDI=1) with `TREE_OUT` set
so `pred_yr1_tree.csv` and `pred_t2_tree.csv` exist this time and stem-count bias can finally be
computed and compared against the observed ceiling.

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

## Next steps, priority order

1. Poll jobs 13462600, 13462616 (3 tasks), 13462623. Once each lands, compute and record the
   actual numbers in place of the predictions above.
2. If any of memat/medev/pef prove stale (as Baxter did in pass 10), promote the regenerated file
   over the standing one, preserving the old as `_PREV_20260813`, same discipline pass 10 used.
3. If the CVX_HTCO=FALSE run confirms roughly 1.74 pp, update the bias budget's convexity/
   second-moment entry with both the height-co-moving (3.866) and height-frozen (~1.74) figures
   and note which one the published budget should use.
4. If xu25Nr2's stem-count bias reproduces the bN-style blowup, xu25Nr2 should not ship without
   further work; if it does not, the open risk flag can be closed.
5. Scope a Track G for the Chapter 10 1.22 pp entry as a dedicated pass, not a quick follow-up.
6. Take `calc_merch_height` edge-tree policy and the `plot_ba_incr` reparameterization to Aaron as
   decisions before any further work on either.

[NEXT_AUTONOMOUS_STEP]: poll the three launched jobs; once all three land, fill in this handoff's
pending sections with real numbers, promote any stale baselines the same way pass 10 did for
Baxter, and flip this handoff from WIP to FINAL.
