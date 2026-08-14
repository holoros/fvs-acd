# FVS-ACD v13.1, pass 16, small-tree fix rescored and plot_ba_incr pooled refit, 14 August 2026

Continuation of pass 15 (`20260814_v131_pass15_handoff_FINAL.md`). Model of record
`~/AcadianGY_13.1.r` stays UNMODIFIED throughout; all changes are overlay scripts. No em dashes.
Ran the two remaining open items as two parallel subagent tracks (small-tree rescore, plot_ba_incr
pooled refit) per standing practice, repo assembly kept serial in the main thread.

## 1. Small-tree fix rescored against total volume and basal area bias: safe to call final

Rescored the p14 small-tree candidate (r2 ddbh refit plus the SMALLMULT = 0.845 flat correction
below 5.0 cm) against total-volume and basal-area bias using the project's standard scoring
harness, `~/magplot/verify/p6ing/bench_p6.R`, across every source it scores: ME Baxter,
ME SILC/Seven Islands, ME PEF, ME CFRU CTRN, Maine FIA whole-plot, Maine FIA subplot, NB MagPlot,
QC MagPlot, NS remeasurement, and NS long CFI, ten sources from eleven generator runs. Built as a
new overlay/harness under `magplot/verify/p16smalltree_rescore/`, run as SLURM array job 13558156
(22 tasks, all completed, exit 0:0).

Every source's total-volume and BA delta (candidate minus baseline) is zero or negative; nothing
flips sign and no source's bias ranking changes. Three sources (SILC, CTRN, QC) show exactly zero
delta because they carry no sub-threshold pool in their tree lists, the correction's designed
no-op. Where a pool exists, the largest cost is Maine FIA whole-plot BA, worsening from -9.629 to
-10.804 percent (1.175 pp absolute, about 12 percent relative increase on an already-substantial
underprediction), with Maine FIA subplot and NB comparable (-1.065 and -0.806 pp BA). Total-volume
deltas are smaller everywhere, topping out at -0.373 pp on Maine FIA whole-plot. NS remeasurement
and NS long CFI, despite carrying the battery's largest baseline bias (around -38 to -41 percent),
show almost no sensitivity (under 0.06 pp), consistent with little sub-5 cm stock in those networks.

The compounding question is already answered by the harness design, not a separate multi-year run:
each stand projects over its own observed remeasurement interval, and the intervals that matter
most here are long (Maine FIA averages 20.5 years, NB 7.4, Baxter 11.0, SILC 10.4), so the reported
deltas are already compounded over multi-decade projections on the exact source the fix was
calibrated against.

Conclusion: the crossing-rate defect closure (candidate 31.30 stems ha-1 yr-1 vs observed 31.21,
excess ratio 1.003x, CI covering 1.0, pass 14) did not come at the cost of a hidden volume/BA
regression. The worst-case cost, about 1.2 pp BA at Maine FIA, is an order of magnitude smaller
than the pre-existing bias it sits inside, and is being disclosed as a stated tradeoff rather than
passed over silently, matching the project's convention for naming lever costs (e.g. the ONSET=0.55
tradeoff in `v131_shipping_array.sbatch`). Safe to fold into a combined v13.1 candidate.

## 2. plot_ba_incr pooled refit: Maine-range hypothesis refuted, sign problem still open

Extended the pass 14 reparameterization refit to a pooled Acadian benchmark: mefia_long, ns_long,
ctrn, baxter, pef, and silc_l from `multisrc/`, 8,878 stand-intervals across 3,204 physical plots
after fitting filters, csi range 10.0 to 35.2 (IQR 15.6 to 20.9), genuinely wider than Maine alone
(10.0 to 23.0, IQR 13.2 to 15.9). Built under `magplot/verify/p16pooled/p16_pool_fit.R`, SLURM job
13559192 (three earlier submissions failed on data-quality and script bugs, logged and fixed, not
routed around: 32 percent of Nova Scotia's raw tree rows and 39 percent of PEF's were duplicate
STAND,TREE keys, multiplying growth through a many-to-many join; deduplicated before matching and
applied a documented 3 m2 ha-1 yr-1 plausibility ceiling on raw annual survivor increment, which
additionally dropped 421 rows, 321 of them from Maine, about 34 percent of that arm, flagged below
as an open item rather than absorbed silently).

Both forms refit with fixed effects (gnls, matching pass 14 exactly) and with region/site as a
random effect (`nlme::lme`, plot nested in source), the latter preferred by 6,300 to 6,700 AIC
points, confirming region should be a random effect per standard hierarchical practice for pooled
multi-source stand data. On the primary response (rt_surv, fixed-EXPF survivor BA growth), a2 stays
negative and significant in all four specifications: fixed Form A -0.0976 (CI [-0.112, -0.083]),
fixed Form B -0.0916 (CI [-0.106, -0.078]), mixed Form A -0.0630 (CI [-0.081, -0.045]), mixed Form B
-0.0478 (p<0.0001). A Bakuzis-lite site-ordering check flags inverted ordering in all four: fitted
growth decreases monotonically as csi improves.

Pass 14's working hypothesis, that Maine's narrow csi range was masking a true positive site effect,
is refuted, not confirmed, by the wider pooled gradient. One real nuance did surface: the rt_lg arm
(survivor growth restricted to trees at least 12.7 cm dbh at t1) flips to positive and holds up
robustly (fixed +0.035, mixed +0.021, p<0.0001, CI [0.030, 0.040]), while rt_net stays ambiguous
(CI straddles zero). The negative site effect on the all-tree average is not an artifact of the
reparameterization or the narrow Maine gradient; it looks concentrated in the small-tree fraction of
the stand, since restricting to large trees flips the sign.

This pass closes the question of whether Maine-only data range was the problem; it was not. It does
not close the sign problem itself. Recommended next step (a pass 17): investigate whether
`plot_ba_incr`'s site term is confounded with a size-class effect not currently in the equation,
since small-tree suppression under high-csi/high-hardwood-fraction stands could be driving the
negative all-tree average even though large trees behave correctly, the same size-stratified
mechanism this session's small-tree track independently surfaced elsewhere in the model. The 34
percent Maine exclusion under the plausibility screen should be diagnosed first, since it changes
the composition of the Maine arm of the pooled sample and was not present in pass 14's Maine-only
fit.

## Ledger status after pass 16

Closed: CVX_HTCO sensitivity, memat/medev/pef reconciliation, xu25Nr2 stem budget (pass 12); Baxter
provenance, small-tree r2 measurement, calc_merch_height (pass 13); small-tree ddbh crossing-rate
defect (pass 14); Track G (pass 15); small-tree fix rescored safe against volume/BA, ten-source
battery (pass 16). Open, both routed to a pass 17: plot_ba_incr's sign problem, now narrowed to a
likely size-class confound rather than a data-range or collinearity artifact; the 34 percent Maine
exclusion rate under the pooled fit's plausibility screen, needs diagnosis before the confound
investigation proceeds.

## Next steps, priority order

1. Diagnose the 34 percent Maine exclusion rate under the pooled fit's 3 m2 ha-1 yr-1 plausibility
   ceiling: real data problems in mefia_long that pass 14 never screened for, or the ceiling cutting
   legitimate fast-growth stands.
2. Investigate a size-class confound in `plot_ba_incr`'s site term (rt_surv negative, rt_lg
   positive), likely the next real lever on the sign problem.
3. Fold the small-tree fix into the combined v13.1 candidate, with the ~1 pp BA cost at Maine FIA
   and NB stated as a disclosed tradeoff.
4. If a merchantable-volume or sawlog product is ever built on this model, source
   `p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R` after the base
   model, in that order.
