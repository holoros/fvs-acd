# FVS-ACD v13.1, pass 14, three parallel tracks on the open ledger, 13 August 2026

Continuation of pass 13 (`20260813_v131_pass13_handoff_FINAL.md`). Model of record
`~/AcadianGY_13.1.r` stays UNMODIFIED throughout; all changes are overlay scripts. No em dashes.
Ran the three open ledger items as three parallel subagent tracks (small-tree ddbh, Track G search,
plot_ba_incr refit) per standing practice for independent workstreams, with repo assembly kept
serial in the main thread. `calc_merch_height`/`calc_tree_volume` (item 4) needed no action this
pass; still deployed and dormant per pass 13.

## 1. Small-tree ddbh track: closed on the crossing-rate metric

Root cause is not a separate small-tree function; it is the single Kuehne et al. (2020) `ddbh()`
equation (line 1015 of `AcadianGY_13.1.r`), applied uniformly from dbh = 1 cm up, with cr,
bal.sw, bal.hw, and csi as covariates. The r2 refit only partially closed the crossing defect
because of a real functional-form limit visible in `p4e/p4e_class.csv`: observed/model bias by
diameter class is non-monotonic, over-predicting growth by 11.9 percent at 2.54 to 5 cm but
under-predicting by 4.6 to 23 percent at every class from 7.5 cm up. A single joint three-parameter
exponential form cannot cut the bottom and lift everywhere else at once, and the fit is dominated
by the larger sample mass above 7.5 cm, diluting the sapling-tail correction to roughly -6 to -10
percent instead of the needed -12. A second effect: the crossing rate is far more sensitive than
the class-mean bias, since trees crossing 5 cm in a given year are almost all already near the
boundary at year start, so a taper barely moves the rate while a flat, uniform cut across 1 to 5 cm
produces a near-cliff response, evidence the defect concentrates in the near-boundary tail rather
than a simple scale error.

Built on Cardinal, overlay only, under `magplot/verify/p14smalltree/`: `model_smalltree.r` (wraps
`ddbh()`, r2 by default, with a flat multiplicative correction `SMALLMULT` for dbh below
`SMALLCAP` = 5.0 cm), `p14_smalltree_cross.R` (one-year native-crossing harness, copy of the
p9r2rec harness with the overlay added), and `p14_observed_bootstrap.R` /
`p14_candidate_bootstrap.R` (plot-clustered nonparametric bootstraps). Four SLURM sweeps (jobs
13498005, 13498898, 13499557, 13500283) bracketed and then pinpointed `SMALLMULT = 0.845` against
the observed rate.

Results, 920/918 plots, 5000-resample plot-clustered bootstrap: observed benchmark 31.21 stems
ha-1 yr-1, 95 percent CI [28.27, 34.26]; base v13.1, 71.33 (2.29x excess); r2 alone, 60.28 (1.93x
excess); candidate (r2 plus the p14 fix), 31.30, 95 percent CI [24.88, 38.29], excess ratio 1.003x,
95 percent CI [0.79, 1.25]. The excess-ratio CI covers 1.0: the stated 2.3x defect is closed within
what a 920-plot, one-year harness can resolve.

Caveats stated plainly. This is a behavioral calibration against the crossing-rate target, not an
independent statistical refit, and its magnitude (-15.5 percent flat) is about 6x larger than the
class-table mean bias would imply, flagged as the diagnostic signature of the tail/stochasticity
mechanism rather than a scale error. It has not yet been rescored against total-volume/BA bias on
the full seven-source battery (`p6ing/bench_p6.R`), the explicit next step before folding this into
a combined candidate. Sub-5 cm stems carry negligible standing basal area, but the correction
compounds over a 15-year projection against the 1,934 TPH sub-threshold pool, so that effect needs
measuring, not assuming.

## 2. Track G: broader search, still empty, needs Aaron directly

Broadened the search beyond `verify/` on Cardinal (already searched twice, pass 9 and pass 13) to
Gmail, Box, Dropbox, the local CRSF-Cowork workspace, and full GitHub history. Gmail turned up
nothing relevant across several term combinations. Box returned 568 hits on "Acadian" as a generic
string match, none on bias budget or Chapter 10. Dropbox returned zero. The local workspace
surfaced only this project's own pass 12 and 13 handoffs, which already document the same negative
result; pass 12 states the entry appears only as a hardcoded prior-track constant in
`c4_adversarial.R` and in restatements of the budget, never an independently computed second value.

One lead flagged, not confirmed: `figures/_data/master_scorecard.csv` (outside `verify/`, so
outside what passes 9 and 13 searched) has a row for PEF developing/managed treatments,
projection_length < 15, BASE, n = 2843, with TOTVOL_bias_pct = 1.22, and a companion doc
(`20260723_master_scorecard_and_ranking.md`) cites the overall PEF BASE bias as 1.23 (n = 2853).
Close to 1.22 but not identical, from a different data cut, and prior forensic work already
concluded the Chapter 10 constant predates and is independent of these benchmark reruns. Not
presenting this as the source; no document connects it to "Chapter 10" or "bias budget."

Recommendation unchanged from pass 13: ask Aaron directly whether 1.22 pp has a source outside this
Cardinal workspace before spending more compute searching for it.

## 3. plot_ba_incr reparameterization: refit done, sign problem not resolved

Calibration data located: `magplot/verify/multisrc/bench_mefia_long_*.csv`, the Maine FIA long
(first-to-last undisturbed) remeasurement benchmark, 933 stands, 35,495 matched survivor trees,
csi from ESI v8, rd as Curtis relative density off a composition/elevation-adjusted SDImax, with a
plot-summarized version already staged at `p9site/p9c_plotlevel.rds`. Found via a prior scoping
note, `p9site/p9_track_c_site_refit_scope.md` (12 August), which specifies the same two candidate
forms as `20260813_v131_plot_ba_incr_reparam_scoping_DRAFT.md` with byte-identical algebra.

Built on Cardinal, overlay only, under `magplot/verify/p14reparam/`: `p14_fit.R`, submitted as
SLURM job 13500307 (ran about 2 minutes). Both candidate forms fit via `nlme::gnls`, weighted by
1/interval_years, across three response definitions: `rt_surv` (fixed-EXPF survivor BA growth, all
trees, n = 899, primary), `rt_net` (net BA change including mortality/harvest, n = 899), and
`rt_lg` (survivor growth restricted to trees at least 12.7 cm dbh at t1, n = 852). Uncertainty is a
2000-replicate nonparametric cluster bootstrap.

Reparameterization worked mechanically as predicted: VIFs collapse from 1.3e10/4.7e8 in the shipped
basis to 1.05 to 1.09 in the identified basis, both forms converge cleanly, coefficients carry real
standard errors instead of ridge artifacts. But on the two response definitions that most plausibly
match what `plot_ba_incr`'s target represents, the csi coefficient stays negative and significant
after separating it from the density term. For `rt_surv` (primary), a2 = -0.126 (SE 0.047),
bootstrap 95 percent CI [-0.214, -0.043]; AIC/BIC both prefer the no-interaction form (LRT p =
0.42). The implied percent change in dba from csi 12 to 20 at the median plot is -23.6 percent
[-37.9, -8.5], almost exactly the -23.8 percent the shipped model's net coefficient implied: the
near-cancellation in the shipped equation was not masking a hidden near-zero or positive site
effect. `rt_net` tells the same story: a2 = -0.073 [-0.108, -0.039], with a marginally supported
interaction term (LRT p = 0.0085, but the interaction's own CI straddles zero, [-0.012, 0.179]).

The one response definition that flips sign is `rt_lg`: a2 = +0.034, CI [0.023, 0.045], tightly
bounded away from zero and corroborating the earlier unweighted OLS indicative estimate (+0.035)
from the original scoping script. But this definition discards recruitment into the survivor pool,
a narrower operational target than what the model's Chapter 10 proportional disaggregation
redistributes growth onto (all growing trees, not just those already above the threshold), so it is
not obviously the right thing for `plot_ba_incr` to be fit to. Its derived percent-change figure
came out at -319 to -517 percent, a ratio blowup from rt sitting near zero at csi 12 for this
response, not a real effect; the coefficient itself (+0.034) is the only trustworthy number from
that arm.

Net finding: separating the site term from the density term does not, by itself, resolve the
Bakuzis site-ordering violation. It rules out the specific hypothesis that collinearity fabricated
the wrong sign. What is left standing are the two alternatives the scoping doc already named:
either the fitting sample needs the wider pooled Acadian benchmark (NS, CTRN, Baxter, PEF, SILC,
already staged in `multisrc/`) before a2 is decision-grade, since Maine's csi range is narrow (10
to 23, IQR 13.2 to 15.9) and confounded with hardwood fraction and elevation, or the fix is
structural: stop the plot-level equation from overriding the tree-level model's own correctly-
signed site term via the Chapter 10 disaggregation, rather than trying to make the plot-level term
carry it. Coverage of the bootstrap intervals was not checked against held-out data this pass, an
open item against the standing uncertainty checklist, not a silent omission.

## Decision needed

Aaron: how to proceed on plot_ba_incr, given the refit rules out collinearity but not the sign
problem itself. (1, recommended) Bank the reparameterization and diagnostics as done, report the
sign problem as unresolved, and route the next step to the pooled multi-source refit the scoping
doc gates on before touching a2 for real. (2) Extend now to the pooled Acadian data, a bigger
Cardinal lift, before reporting anything as final. (3) Ship Form A on the `rt_lg` positive
coefficient anyway, accepting its narrower definition, since it is the only arm that passes site
ordering and its scale is in the right neighborhood of what the height-equation cross-check
implied was needed.

## Ledger status after pass 14

Closed with results: CVX_HTCO sensitivity, memat/medev/pef reconciliation, xu25Nr2 stem budget
(pass 12); Baxter provenance, small-tree r2 measurement, calc_merch_height (pass 13); small-tree
ddbh defect, closed on the crossing-rate metric pending a total-volume/BA rescore (pass 14). Open:
Track G (needs Aaron's input, not more search), plot_ba_incr sign problem (needs Aaron's choice
above), the small-tree fix's rescore against the seven-source battery.

## Next steps, priority order

1. Rescore the p14smalltree candidate against `p6ing/bench_p6.R` (total volume/BA bias, full
   seven-source battery) before treating the crossing-rate fix as final.
2. Ask Aaron directly whether the Chapter 10 1.22 pp entry has a source outside this workspace.
3. Per Aaron's decision above, either bank plot_ba_incr as scoped-and-diagnosed, extend to the
   pooled multi-source refit, or ship the `rt_lg` form.
4. If a merchantable-volume or sawlog product is ever built on this model, source
   `p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R` after the base
   model, in that order.
