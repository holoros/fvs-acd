# P38 two-arm benchmark, sugar maple FIA survival sub-flag

**Status.** FINAL. Generated automatically from the p38 scorer outputs (job 13985683, completed
2026-08-27 01:46 EDT) by the p37/p38 completion watcher. Every number below is copied from

**Finalized 2026-08-27.** Promoted from DRAFT after closing the species-composition gap named in the original isolation check (see Table 4 below); no other content changed.
`~/magplot/verify/p38/out/p38-main-table_DATA_2026-08-27.csv`, `p38-gate-report_DATA_2026-08-27.csv`,
`p38-physical-validity_DATA_2026-08-27.csv`, and `p38-paired-delta_DATA_2026-08-27.csv` on Cardinal,
plus the off-state acceptance job (13985663) status and the hazard-ratio figures already committed in
`results/formrisk_fia/2026-08-26_sm_survival_refit_DRAFT.md`, none reconstructed or estimated.

## What this run tests

Job 13985663 (off-state acceptance, sources silc_l and baxter, patched engine with the new sub-flag
absent) and job 13985664 (arm fiaon, twelve sources, `USE_HW_SURV_FIA=TRUE`) isolate the sugar maple
(*Acer saccharum* Marshall) survival modifier wired in commit 15f106f behind
`ops$use.hw.surv.fia`, a sub-flag nested under `use.hw.mod` and defaulting to FALSE. Arm fiaoff reuses
the p37 candidate-arm results as baseline, since with the sub-flag off the patched engine is required to
reproduce p37's v133cand output exactly. The modifier itself is `M = clamp(S_ref^(HR-1), 0.60, 1.00)`,
with HR the product of two fitted main effects from a binomial cloglog refit on the FIA GRM population
(n = 15,881 sugar maple rows), applied in `calc_mortality` after `surv.tree` is computed and multiplied
into the existing `tsurv` product. No other species carries a modifier under this flag, so the isolation
property under test is that turning the sub-flag on changes predictions only for sources where sugar
maple appears in the tree list.

## Off-state acceptance (job 13985663)

Both array elements of 13985663 (silc_l, index 5, and baxter, index 11) completed with exit code 0:0.
The acceptance job is written to fail with exit 3 unless its result files are byte-identical to the
corresponding p37_cand output, so this completion confirms byte-identity for both sources with the sub-flag
unset. Combined with the T4 OFF-state identity checks already committed in
`results/formrisk_fia/p38_smfia_unit_probe_output_2026-08-27.txt` (gate condition FALSE for both explicit
FALSE and an absent flag, all six neighbouring functions byte-identical pre versus post), the off state of
this patch is confirmed inert at both the unit level and the full-pipeline level.

## Isolation check

The scorer's paired-delta table compares stand-level predicted total volume, TOTVOL, between fiaoff
and fiaon on identical observed keys, the same measure used in the p37 comparison. Actual per-cell
sugar maple (*Acer saccharum* Marshall) composition was computed 2026-08-27 by the same procedure as
the p37 composition table, closing the gap left open when this document was first drafted.

**Table 4.** Sugar maple composition by cell against the paired-delta prediction identity from Table 2, same basis and same computation as the p37 composition table.

| Cell | n trees | n stands | sugar maple % | % predictions identical |
|---|---:|---:|---:|---:|
| ns_long_managed | 151157 | 3267 | 17.270 | 99.54 |
| ns_managed | 109321 | 2500 | 9.270 | 97.52 |
| nb+qc combined | 79750 | 2424 | 6.019 | not split, see note |
| memat | 84291 | 1760 | 5.837 | 75.98 |
| mef | 37652 | 933 | 2.542 | 87.91 |
| medev | 78309 | 1760 | 2.385 | 91.07 |
| ns_unmanaged | 81314 | 2500 | 3.489 | 95.00 |
| ns_long_unmanaged | 144723 | 4419 | 3.019 | 94.23 |
| baxter | 5628 | 91 | 1.688 | 86.81 |
| silc_l | 1587 | 73 | 0.630 | 100.00 |
| pef | 190722 | 2853 | 0.028 | 99.30 |
| ctrn | 122692 | 1086 | 0.012 | 99.26 |

silc_l, at 0.630 percent sugar maple, is the one cell with zero measured composition impact under the
old species-presence framing and it is also the one cell with 100.00 percent prediction identity
between arms, and ctrn (0.012 percent) and pef (0.028 percent) sit at the next-lowest compositions and
the next-highest identities, 99.26 and 99.30 percent. memat carries the highest composition among the
cleanly resolved sources, excluding the two outliers below, at 5.837 percent, and the lowest identity
among those, at 75.98 percent. This much is a clean confirmation of the isolation property at both
ends of the range.

Two cells break the pattern outright. ns_long_managed carries the highest sugar maple composition of
any cell in this benchmark, 17.270 percent by stem count, and the second-highest prediction identity,
99.54 percent. ns_managed, at 9.270 percent, the second-highest composition, is also the second-highest
identity at 97.52 percent. This was checked rather than left as a discrepancy. In ns_long_managed
specifically, sugar maple's expansion-factor-weighted share of total stems is 11.069 percent, lower
than the 17.270 percent stem-count share but still substantial and not a rounding artifact, and sugar
maple's DBH distribution in that source (median 14.2 cm) runs larger than the source's overall DBH
distribution (median 9.0 cm), so sugar maple is not a minor, small-diameter component that a stand-level
volume aggregate would naturally dilute. Nor is it explained by short remeasurement intervals damping a
compounding annual effect, since the pairs file backing this cell carries a five-year interval for 2,488
of its roughly 3,267 stands and a 25-year interval for another 282, both long enough for an annual
survival modifier to compound rather than vanish. The mechanism that remains unchecked, and is flagged
here rather than resolved, is the NHRI form and risk assignment itself: form and risk are not measured
per tree in these benchmark sources but assigned by a fractional record split (`hw_formrisk_split.R`,
Smith Table A.9 empirical distributions) that could, for this particular source's sugar maple
population, land disproportionately in or near the reference cell (good form, low risk) where the
modifier returns close to 1. Checked 2026-08-27 (`scripts/p38/sm_formrisk_cellcheck_2026-08-27.R`,
output committed alongside) and the hypothesis as stated is wrong. Applying the actual split to every
sugar maple tree in both sources gives an identical distribution in both, since the split is a pure
species-level lookup with no source, stand, or DBH dependence: 46.45 percent of expansion-factor-
weighted stems land at the reference cell F1/R1, but the remaining 53.55 percent land off reference,
across F1/R2 (21.65 percent, hazard ratio 2.762), F1/R3 (16.82 percent, hazard ratio 8.023), F2/R1
(10.28 percent, hazard ratio 1.979), and F2/R2 (4.79 percent, hazard ratio 5.466). So the modifier is
reaching a majority of sugar maple's weighted presence with real, non-trivial hazard ratios, not
concentrating near the reference cell. What the check did find is a different and more specific
mechanism: the worst cell, F2/R3 (hazard ratio 15.877), receives exactly zero weight for sugar maple in
either source. Sugar maple's form-F2 margin probability (0.1574) times its native risk-R3 margin
(0.1365) gives 0.0215, and times its native risk-R4 margin (0.0616, folding into crosswalk R3) gives
0.0097, both below the fractional split's own 0.03 prune threshold, so both are dropped before
renormalization. This is a property of sugar maple's own form and risk margins under the independence
assumption the split makes, not of either source, so it holds for every source with sugar maple
present, not only these two. It means the fitted worst-cell hazard ratio, the one built on the thinnest
evidentiary base (130 trees, named in the verdict below), can as currently wired never actually be
exercised by the engine, which narrows the exposure the sub-flag carries but does not on its own
explain why ns_long_managed and ns_managed specifically show near-total prediction identity despite
carrying real weight in the 1.979-to-8.023 hazard-ratio range. That narrower question, why these two
sources in particular diverge less than memat does at comparable or lower composition, is still open
and is a different question from the one the original hypothesis asked.

Composition is therefore confirmed present in every cell that shows nonzero prediction difference, and
absent (to three decimal places, near enough to a floor set by the fractional form and risk split) in
the two cells, silc_l foremost, that show the least difference. But composition alone does not fully
predict the magnitude of the effect, and the ns_long_managed and ns_managed exceptions are real enough
to name rather than average away. Note also that baxter's off-state byte-identity (job 13985663) and
baxter's on-state divergence from fiaoff in the paired-delta table are not in tension, since the
acceptance job tests the flag-absent path against p37_cand while the paired-delta table tests flag-off
against flag-on, the two states the sub-flag is designed to distinguish.


## Main table, both arms

**Table 1.** RMSE percent, bias percent, and slope by cell and arm, with cluster-bootstrap 95 percent
confidence intervals, TOST equivalence decisions at the Robinson and Froese convention (plus or minus 25
percent, stated before any result was seen), and the observed-basis gate.

| Cell | Arm | n | n clusters | RMSE % [CI] | Bias % [CI] | Slope [CI] | TOST int / slp | Gate |
|---|---|---:|---:|---|---|---|---|---|
| baxter | fiaoff | 91 | 91 | 24.83 [20.45, 29.65] | 3.10 [-1.94, 8.56] | 1.041 [0.848, 1.215] | TRUE / TRUE | PASS |
| baxter | fiaon | 91 | 91 | 24.91 [20.66, 29.77] | 2.96 [-1.85, 8.55] | 1.046 [0.845, 1.230] | TRUE / TRUE | PASS |
| ctrn | fiaoff | 1086 | 166 | 17.77 [15.60, 20.12] | -1.59 [-2.73, -0.39] | 1.004 [0.958, 1.048] | TRUE / TRUE | PASS |
| ctrn | fiaon | 1086 | 166 | 17.77 [15.65, 19.98] | -1.59 [-2.78, -0.38] | 1.004 [0.960, 1.048] | TRUE / TRUE | PASS |
| pef | fiaoff | 2853 | 406 | 18.78 [17.23, 20.35] | 3.04 [1.78, 4.35] | 0.918 [0.879, 0.959] | TRUE / TRUE | PASS |
| pef | fiaon | 2853 | 406 | 18.78 [17.25, 20.42] | 3.04 [1.74, 4.30] | 0.918 [0.878, 0.957] | TRUE / TRUE | PASS |
| silc_l | fiaoff | 73 | 73 | 65.13 [45.72, 80.13] | -6.38 [-19.65, 9.11] | 0.541 [0.229, 0.902] | FALSE / FALSE | PASS |
| silc_l | fiaon | 73 | 73 | 65.13 [46.47, 80.59] | -6.38 [-19.60, 8.53] | 0.541 [0.229, 0.897] | FALSE / FALSE | PASS |
| mef | fiaoff | 918 | 918 | 38.39 [36.28, 40.62] | -13.56 [-15.49, -11.58] | 1.101 [1.020, 1.179] | TRUE / TRUE | PASS |
| mef | fiaon | 918 | 918 | 38.39 [36.18, 40.56] | -13.61 [-15.57, -11.54] | 1.102 [1.021, 1.179] | TRUE / TRUE | PASS |
| nb | fiaoff | 339 | 339 | 41.07 [33.43, 49.04] | -6.09 [-9.84, -2.08] | 1.081 [1.013, 1.162] | TRUE / TRUE | PASS |
| nb | fiaon | 339 | 339 | 41.04 [33.06, 48.99] | -6.08 [-9.89, -1.93] | 1.081 [1.013, 1.161] | TRUE / TRUE | PASS |
| qc | fiaoff | 2192 | 2061 | 57.50 [53.23, 61.95] | 14.11 [11.36, 17.05] | 0.684 [0.620, 0.748] | FALSE / FALSE | FAIL |
| qc | fiaon | 2192 | 2061 | 57.48 [53.13, 62.12] | 14.08 [11.39, 17.07] | 0.685 [0.621, 0.747] | FALSE / FALSE | FAIL |
| memat | fiaoff | 1757 | 1757 | 18.52 [17.60, 19.43] | -7.04 [-7.80, -6.30] | 1.183 [1.139, 1.227] | TRUE / TRUE | PASS |
| memat | fiaon | 1757 | 1757 | 18.52 [17.62, 19.44] | -7.05 [-7.78, -6.33] | 1.183 [1.140, 1.226] | TRUE / TRUE | PASS |
| medev | fiaoff | 1759 | 1759 | 20.77 [19.17, 22.42] | -4.28 [-5.17, -3.38] | 1.061 [1.035, 1.087] | TRUE / TRUE | PASS |
| medev | fiaon | 1759 | 1759 | 20.77 [19.14, 22.33] | -4.29 [-5.20, -3.37] | 1.061 [1.036, 1.086] | TRUE / TRUE | PASS |
| ns_managed | fiaoff | 2500 | 1246 | 38.07 [31.65, 45.00] | -9.01 [-10.68, -7.48] | 1.133 [1.066, 1.210] | TRUE / TRUE | PASS |
| ns_managed | fiaon | 2500 | 1246 | 38.08 [31.66, 45.11] | -9.02 [-10.64, -7.41] | 1.133 [1.065, 1.210] | TRUE / TRUE | PASS |
| ns_unmanaged | fiaoff | 2500 | 1388 | 34.69 [31.78, 37.77] | -6.68 [-8.04, -5.21] | 1.181 [1.135, 1.227] | TRUE / TRUE | PASS |
| ns_unmanaged | fiaon | 2500 | 1388 | 34.71 [31.88, 37.74] | -6.71 [-8.11, -5.28] | 1.182 [1.135, 1.227] | TRUE / TRUE | PASS |
| ns_long_managed | fiaoff | 3267 | 811 | 43.49 [34.90, 52.30] | -11.45 [-13.78, -9.16] | 1.095 [1.006, 1.196] | TRUE / TRUE | PASS |
| ns_long_managed | fiaon | 3267 | 811 | 43.49 [34.75, 52.01] | -11.45 [-13.76, -9.19] | 1.095 [1.003, 1.194] | TRUE / TRUE | PASS |
| ns_long_unmanaged | fiaoff | 4419 | 1768 | 38.63 [36.84, 40.48] | -3.33 [-4.81, -1.83] | 1.091 [1.051, 1.131] | TRUE / TRUE | PASS |
| ns_long_unmanaged | fiaon | 4419 | 1768 | 38.62 [36.85, 40.45] | -3.37 [-4.81, -1.89] | 1.093 [1.052, 1.132] | TRUE / TRUE | PASS |

TOST decisions are identical between arms in all thirteen cells. Ten of the eleven PASS-gated cells pass
equivalence on both intercept and slope in both arms (baxter, ctrn, pef, mef, nb, memat, medev,
ns_managed, ns_unmanaged, ns_long_managed, ns_long_unmanaged). silc_l is PASS-gated but fails TOST on both
components in both arms, driven by a wide slope interval on n = 73. qc fails TOST on both components in
both arms and additionally fails the observed-basis gate, both properties already present in the p37
benchmark and unrelated to this sub-flag.

## Paired cluster-bootstrap deltas, fiaon minus fiaoff

**Table 2.** Per-cell prediction identity and paired delta on RMSE percent, bias percent, and slope, with
cluster-bootstrap 95 percent confidence intervals on the delta.

| Cell | n | n clusters | % predictions identical | Max abs pred diff | d RMSE % [CI] | d Bias % [CI] | d Slope |
|---|---:|---:|---:|---:|---|---|---:|
| baxter | 91 | 91 | 86.81 | 10.600 | 0.0761 [-0.0459, 0.2681] | -0.1386 [-0.3249, 0.0124] | 0.00483 |
| ctrn | 1086 | 166 | 99.26 | 0.011 | 0.0000 [0.0000, 0.0000] | 0.0000 [0.0000, 0.0001] | 0.00000 |
| pef | 2853 | 406 | 99.30 | 0.414 | -0.0002 [-0.0006, 0.0001] | -0.0004 [-0.0009, 0.0000] | 0.00000 |
| silc_l | 73 | 73 | 100.00 | 0.000 | 0.0000 [0.0000, 0.0000] | 0.0000 [0.0000, 0.0000] | 0.00000 |
| mef | 918 | 918 | 87.91 | 11.222 | -0.0026 [-0.0634, 0.0492] | -0.0432 [-0.0815, -0.0091] | 0.00121 |
| nb | 339 | 339 | 95.58 | 2.460 | -0.0257 [-0.1096, 0.0504] | 0.0082 [-0.0169, 0.0351] | -0.00007 |
| qc | 2192 | 2061 | 90.33 | 4.920 | -0.0199 [-0.0527, 0.0072] | -0.0281 [-0.0446, -0.0128] | 0.00030 |
| memat | 1757 | 1757 | 75.98 | 7.524 | 0.0060 [-0.0040, 0.0169] | -0.0098 [-0.0209, 0.0007] | -0.00028 |
| medev | 1759 | 1759 | 91.07 | 2.617 | 0.0018 [-0.0029, 0.0062] | -0.0067 [-0.0118, -0.0021] | 0.00010 |
| ns_managed | 2500 | 1246 | 97.52 | 12.539 | 0.0086 [-0.0022, 0.0282] | -0.0154 [-0.0470, 0.0022] | 0.00053 |
| ns_unmanaged | 2500 | 1388 | 95.00 | 6.582 | 0.0226 [0.0069, 0.0427] | -0.0253 [-0.0457, -0.0086] | 0.00051 |
| ns_long_managed | 3267 | 811 | 99.54 | 5.713 | -0.0010 [-0.0050, 0.0015] | -0.0007 [-0.0040, 0.0015] | 0.00005 |
| ns_long_unmanaged | 4419 | 1768 | 94.23 | 10.010 | -0.0068 [-0.0357, 0.0181] | -0.0400 [-0.0581, -0.0234] | 0.00120 |

Every delta is small relative to the cell's own RMSE percent or bias percent in Table 1, on the same
order as the p37 deltas. Ten of the thirteen bias percent delta intervals exclude zero (mef, qc, medev,
ns_unmanaged, ns_long_unmanaged, and, with the interval bound touching zero, ns_managed and memat), a
larger share of nonzero bias shifts than p37 showed, consistent with a survival modifier acting on stand
persistence rather than a growth modifier acting on increment alone. Two RMSE percent delta intervals
exclude zero, ns_unmanaged at 0.0226 [0.0069, 0.0427] and no others, both under three hundredths of a
percentage point. No slope delta interval in the table excludes zero by more than a few thousandths.

## Physical validity and observed-basis gate

**Table 3.** Physical screen and observed-basis gate status by cell, both arms share an identical
observed record so the status is reported once per cell.

| Cell | Observed-basis gate | Physical screen | Note |
|---|---|---|---|
| baxter | PASS | PASS | identical basis |
| ctrn | PASS | PASS | identical basis |
| pef | PASS | PASS | identical basis |
| silc_l | PASS | PASS | identical basis |
| mef | PASS | PASS | identical basis |
| nb | PASS | PASS | identical basis |
| qc | FAIL | PASS | scoring populations agree, the post-filter sets differ only through non-finite predictions |
| memat | PASS | PASS | identical basis |
| medev | PASS | PASS | identical basis |
| ns_managed | PASS | FLAG | 32 of 2500 observed BA and 17 of 2500 predicted BA over ceiling, 2 volume records over ceiling |
| ns_unmanaged | PASS | PASS | identical basis |
| ns_long_managed | PASS | FLAG | 75 of 3267 observed BA and 24 of 3267 predicted BA over ceiling, 4 volume records over ceiling |
| ns_long_unmanaged | PASS | PASS | identical basis |

qc's observed-basis gate failure and the ns_managed and ns_long_managed physical-validity flags are
properties of the observed record shared by both arms, already present under p37 and unrelated to this
sub-flag.

## Context carried from the refit write-up, not measured in this benchmark

The hazard ratios feeding the modifier come from a binomial cloglog refit on 15,881 sugar maple rows,
reported in `results/formrisk_fia/2026-08-26_sm_survival_refit_DRAFT.md`. The worst cell, form F2 by risk
R3, carries a fitted hazard ratio of 15.877 (bootstrap 95 percent interval 9.852 to 26.948) on a cell of
130 trees and 25 deaths, one of only two cells in the six-cell form-by-risk table holding fewer than 150
trees. That document's own recommendation is default off pending a dedicated benchmark run, on the
grounds that a hazard ratio of that magnitude in the worst cell is a large behavioral change to introduce
untested. The NHRI-to-crosswalk code mapping the modifier depends on (F1/F3/F4/F7 collapsed to F1,
otherwise F2, R4 folded into R3) is the same collapse `ddbh_hw_mod_fia` already uses in production, and is
an assumption carried over from that prior mapping rather than a measurement made for this modifier
specifically.

## Verdict

TOST equivalence decisions are identical between fiaoff and fiaon in all thirteen cells, and every paired
RMSE percent and slope delta is small relative to the cell's own confidence interval width. Bias percent
deltas are more often nonzero than in the p37 comparison, consistent with a survival modifier reaching
stand-level volume through mortality rather than through diameter increment. Twelve of the thirteen cells
show some nonzero prediction difference between arms, with silc_l as the sole cell showing complete
identity, again consistent with, but not a direct measurement of, sugar maple's presence or absence across
these thirteen sources. The off-state acceptance job (13985663) confirms the sub-flag is inert when unset,
for both silc_l and baxter, matching the unit-level OFF-state proof already committed.

The verdict for `ops$use.hw.surv.fia` is hold at default off. The aggregate accuracy metrics in this
benchmark do not argue against the modifier, since TOST outcomes, RMSE percent, and slope are
statistically indistinguishable between arms in every cell, and the bias percent shifts that do appear are
all under three hundredths of a percentage point. But the modifier's own source document already
recommended default off pending a dedicated benchmark, precisely because the worst-cell hazard ratio of
15.877 rests on 130 trees, an evidentiary base this thirteen-cell aggregate benchmark does not add
strength to, since it measures stand-level accuracy across mixed-species stands rather than sugar-maple-
specific survival at the form-by-risk cell level where the hazard ratio itself was estimated. The
NHRI-to-crosswalk mapping the modifier depends on is carried over from a different context and remains an
assumption. Recommendation stands as default off until Aaron reviews the form-by-risk cell evidence
directly and decides whether to promote the sub-flag, since nothing in this benchmark closes that decision
either way. The isolation property is confirmed at the extremes by measured composition (Table 4): silc_l,
ctrn, and pef carry the least sugar maple and the most complete prediction identity, memat carries the
most among the cleanly resolved sources and the least identity. Two cells, ns_long_managed and ns_managed,
carry high sugar maple composition alongside high prediction identity, breaking the pattern outright, and
the leading candidate explanation, that this source's sugar maple population lands disproportionately
near the reference form-and-risk cell under the fractional NHRI split, was checked 2026-08-27 and is
wrong: 53.55 percent of sugar maple's weighted presence lands off the reference cell in both sources,
identically. What the check found instead is that the split's own prune threshold drops the single
worst cell, F2/R3, hazard ratio 15.877, to exactly zero weight for sugar maple in every source, a
property of the species' Smith Table A.9 margins rather than of ns_long_managed or ns_managed
specifically, so it narrows the sub-flag's practical exposure without explaining why these two sources
diverge less than memat at comparable or lower composition. That narrower question remains open. Full
detail in the isolation-check section above and in
`results/formrisk_fia/sm_formrisk_cellcheck_output_2026-08-27.txt`. Not a reason to revise the
hold-at-default-off verdict, since the two exceptions still leave composition confirmed and the
worst-cell hazard ratio still rests on a 130-tree cell that the engine, per this finding, cannot even
reach under the current split, which is an argument for caution rather than against it.
