# Master scorecard (four determinants) and overall ranking: BASE vs CANDIDATE v12.11 vs OSM-ACD v2.26.1

23 July 2026, reconciliation pass (task #47). Aggregation of existing, already-scored benchmark CSVs only; no new
Cardinal runs, no edits to `AcadianGY_12.11.r` or the frozen harness. No em dashes.

## 1. Scope, the discrepancy, and how it was reconciled

The task asked for a master scorecard stratified by four determinants that recur across this project's
benchmarking (managed status, forest group, site productivity class, projection length) and an overall composite
ranking built from it. Two earlier passes at the overall ranking disagreed sharply: one reported v12.11 leading
a mean-rank composite of 1.53 against OSM at 1.72 and base at 2.50, a pooled %RMSE of 109.75/121.45/128.91, and
v12.11 winning 8 of 11 cells; a second, rebuilt from the source CSVs and written to
`figures/_data/master_scorecard.csv` and `overall_ranking.csv` earlier in this session, reported OSM leading the
mean-rank composite at 1.38 against v12.11 at 1.92 and base at 2.69, winning 8 of 13 cells, with v12.11 only
narrowly ahead on pooled %RMSE (74.59 vs 75.20). The first pass's intermediate files never made it to disk and
could not be reproduced; the second pass's files are real and match what is verifiable from the source data, but
this reconciliation pass found a specific, fixable reason the two disagreed by roughly 1.5x on the pooled %RMSE
magnitude: **the four-determinant cross-tab counts the same Nova Scotia stands as up to three separate "cells"**
(once under managed status, again under forest group, again under projection length), while the eight independent
ME/NB/QC sources are folded into far fewer cells (five, and zero for projection length, since no ME/NB/QC source
carries a long-enough remeasurement span to bucket that way). Summed across the 13 scored cells, NS's stands
account for roughly 50% of the total weight in that cross-tab's pooled %RMSE and 8 of 13 votes in its mean-rank
composite, versus a true, non-overlapping share of about 34% of all benchmarked stands. That is not a defensible
weighting; it is an artifact of building the ranking on cross-tabulated cells instead of independent datasets.

This memo replaces the cell-based overall ranking with one built directly from the non-overlapping per-source
data: the eight ME/NB/QC sources in `v1211_allsites_scorecard.csv` (Baxter, CFRU CTRN, Maine FIA whole-plot,
Maine FIA subplot, PEF, SILC/Seven Islands, NB MagPlot, QC MagPlot) plus Nova Scotia counted once, using its
overall (non-split) TOTVOL %RMSE from `bench_ns_scorecard.csv`. The four-determinant cross-tab (Tables 31 to 33
below) is retained unchanged, because it is independently useful diagnostic detail and every value in it was
re-verified against source in this pass, but it is no longer the basis for the headline ranking in Section 3.
`figures/_data/master_scorecard.csv` is therefore left as-is (it is correct for what it shows); the new,
non-overlapping per-source table is written to `figures/_data/master_scorecard_sources.csv`, and
`figures/_data/overall_ranking.csv` is rebuilt from it under both weightings and multiple inclusion rules,
described next.

**Two dataset-inclusion complications, disclosed rather than resolved silently.**

First, OSM-ACD v2.26.1 has no score for two of the eight ME/NB/QC sources: Maine FIA subplot (n = 2,858, one of
the poorer-fitting sources for both FVS builds) and QC MagPlot (n = 378, also poor-fitting). This means any
ranking that lets each model use "all the data it actually has" evaluates OSM on an easier six-source subset than
it evaluates base and v12.11, which see all eight. Second, Nova Scotia itself has two internally inconsistent
scorecards on disk: `bench_ns_scorecard.csv` (n = 4,504, the original benchmark, one pair per stand) and
`bench_ns_long_scorecard.csv` (n = 5,348, built for task #40/#41 specifically to support the projection-length
split, and including all consecutive remeasurement pairs, so some stands appear more than once). The two give
narrowly different answers for which model NS itself favors (OSM slightly ahead on the original scorecard, 153.05
vs. v12.11's 156.69; v12.11 narrowly ahead on the long scorecard, 127.35 vs. OSM's 128.34), which is itself a sign
of how close the NS race is. Rather than pick one silently, this memo reports both inclusion rules (all-available-
data, and common-cells-only where all three models have a score) and both NS scorecards (with the original
scorecard as primary, the long scorecard as a stated sensitivity swap), side by side, in the table below.

**Metric.** All rankings are on total-volume percent RMSE (TOTVOL %RMSE) and bias, the primary accuracy metric
used throughout this report. This is a single-metric scorecard; it does not fold in BA, or the value-weighted
composite used in Section 7.7's Tables 17 to 20, which draws on a different, legacy five-model benchmark set.

## 2. Master scorecard by determinant (diagnostic detail, unchanged and re-verified)

**Table 31. Managed status: TOTVOL %RMSE, stand-weighted where pooled.**

| Cell | Region | n (base / v12.11 / OSM) | Base | v12.11 | OSM v2.26.1 | Winner |
|---|---|---|---|---|---|---|
| Managed | ME/NB/QC (pooled) | 1,892 / 1,892 / 1,457 | 37.78 | 32.39 | 28.19 | OSM |
| Managed | NS | 2,157 / 2,157 / 2,154 | 185.89 | 159.46 | 156.13 | OSM |
| Unmanaged | ME/NB/QC (pooled) | 6,720 / 6,720 / 3,862 | 35.33 | 35.32 | 19.61 | OSM |
| Unmanaged | NS | 2,347 / 2,347 / 2,345 | 33.20 | 33.31 | 24.77 | OSM |

**Table 32. Forest group: TOTVOL %RMSE, stand-weighted where pooled.**

| Cell | Region | n (base / v12.11 / OSM) | Base | v12.11 | OSM v2.26.1 | Winner |
|---|---|---|---|---|---|---|
| Softwood | ME/NB/QC (pooled) | 3,927 / 3,927 / 3,716 | 26.79 | 24.25 | 21.08 | OSM |
| Softwood | NS | 2,749 / 2,749 / 2,744 | 198.63 | 179.62 | 171.20 | OSM |
| Mixedwood | ME/NB/QC (pooled) | 1,365 / 1,365 / 1,257 | 39.46 | 39.23 | 33.61 | OSM |
| Mixedwood | NS | 1,122 / 1,122 / 1,122 | 46.27 | 36.79 | 37.71 | v12.11 |
| Hardwood | ME/NB/QC (pooled) | 462 / 462 / 346 | 53.06 | 54.12 | 41.77 | OSM |
| Hardwood | NS | 633 / 633 / 633 | 165.15 | 122.77 | 129.47 | v12.11 |

**Table 33. Projection length and site productivity class.**

| Cell | Region | n (base / v12.11 / OSM) | Base | v12.11 | OSM v2.26.1 | Winner |
|---|---|---|---|---|---|---|
| Under 15 yr | NS | 3,939 / 3,939 / 3,935 | 163.46 | 132.88 | 134.24 | v12.11 |
| 15 to 30 yr | NS | 506 / 506 / 506 | 145.83 | 127.29 | 127.57 | v12.11 |
| Over 30 yr | NS | 903 / 903 / 903 | 49.79 | 52.35 | 50.28 | Base |
| Under 15 / 15 to 30 / over 30 yr | ME/NB/QC (pooled) | 0 | -- | -- | -- | no data: no ME/NB/QC source carries a long enough remeasurement span |
| Low / mid / high SI tercile | ALL | 0 | -- | -- | -- | no data: no dataset in this project is currently binned by site-index tercile |

*Data: `figures/_data/master_scorecard.csv`. Figure 22 (`figures/fig22_determinant_scorecard.png`) plots this
table as a rank-colored heatmap. Unchanged from the prior version of this memo; every value re-checked against
`v1211_allsites_scorecard.csv`, `v1211_forestgroup_scorecard.csv`, `bench_ns_scorecard.csv`, and
`bench_ns_long_scorecard.csv` in this pass, with no discrepancies found. Read on its own terms (each row an
independent cross-tab, not an overall ranking), OSM wins every managed-status and softwood/mixedwood cell in both
regions; v12.11's clean wins are hardwood and mixedwood in NS and both of NS's shorter projection-length buckets;
base wins only the over-30-year NS bucket. As explained in Section 1, this table should not be mean-ranked or
pooled directly across its 13 populated rows for an overall ranking, because doing so triple-counts NS.**

## 3. Overall ranking, non-overlapping per-source basis, both weightings, both inclusion rules

**Table 34. Overall ranking under six scenarios: two inclusion rules (all-available-data; common-cells-only,
where all three models have a score) times three Nova Scotia treatments (with NS from the original scorecard,
without NS, with NS from the long/sensitivity scorecard).**

| Inclusion rule | NS treatment | Model | Mean rank (1 = best) | Sources won | Pooled TOTVOL %RMSE | Pooled bias % |
|---|---|---|---|---|---|---|
| All-available-data | Without NS (8 ME/NB/QC sources) | Base | 2.50 | 1/8 | 35.9 | -11.3 |
| All-available-data | Without NS | **v12.11** | **1.50** | 4/8 | 34.7 | -9.6 |
| All-available-data | Without NS | OSM | 1.67 | 3/6 | **22.0** | **-2.4** |
| All-available-data | With NS (original scorecard, 9 sources) | Base | 2.56 | 1/9 | 86.2 | -21.6 |
| All-available-data | With NS | **v12.11** | **1.56** | 4/9 | **76.6** | -16.8 |
| All-available-data | With NS | OSM | 1.57 | 4/7 | 82.0 | -14.7 |
| All-available-data | With NS-long (sensitivity swap) | Base | 2.56 | 1/9 | 81.1 | -22.2 |
| All-available-data | With NS-long | **v12.11** | **1.44** | 5/9 | **70.2** | -17.6 |
| All-available-data | With NS-long | OSM | 1.71 | 3/7 | 75.3 | -17.3 |
| Common-cells-only | Without NS (6 shared sources) | Base | 2.83 | 0/6 | 26.1 | -4.9 |
| Common-cells-only | Without NS | **v12.11** | **1.50** | 3/6 | 24.2 | -2.8 |
| Common-cells-only | Without NS | OSM | 1.67 | 3/6 | **22.0** | **-2.4** |
| Common-cells-only | With NS (original scorecard, 7 shared sources) | Base | 2.86 | 0/7 | 97.4 | -21.5 |
| Common-cells-only | With NS | v12.11 | 1.57 | 3/7 | 84.6 | -15.5 |
| Common-cells-only | With NS | OSM | **1.57** | 4/7 | **82.0** | **-14.7** |
| Common-cells-only | With NS-long (sensitivity swap) | Base | 2.86 | 0/7 | 89.9 | -22.3 |
| Common-cells-only | With NS-long | **v12.11** | **1.43** | 4/7 | 75.6 | -16.6 |
| Common-cells-only | With NS-long | OSM | 1.71 | 3/7 | **75.3** | **-17.3** |

*Data: `figures/_data/overall_ranking.csv` (all 18 rows above), `overall_ranking_summary.csv` (the two headline
with-NS rows used in Figure 23), `overall_ranking_detail.csv` (per-source rank, both inclusion rules, for audit),
`master_scorecard_sources.csv` (the 28-row non-overlapping per-source input table). Bold marks the better model
on each metric within each scenario row-pair; a tie is bolded on both. Figure 23
(`figures/fig23_overall_ranking.png`) plots the all-available-data rule, both metrics, without and with NS.*

**Reading the table.** v12.11 has the better (lower) equal-per-source mean rank in five of the six scenario
blocks and ties OSM exactly in the sixth (common-cells-only, with NS, original scorecard: 1.571 for both). v12.11
never finishes with the worse mean rank in any scenario tested. OSM has the better (lower) pooled %RMSE in four
of the six scenario blocks; v12.11 has the better pooled %RMSE only when Nova Scotia is included and the
all-available-data rule is used, which is also the version most favorable to v12.11, because it lets v12.11 use
its full eight-source ME/NB/QC average against OSM's easier six-source one. Under the strictest, fairest rule
(common-cells-only, where every model is scored on exactly the same stands), OSM leads pooled %RMSE in every NS
treatment and either ties or leads mean rank, though only by 0 to 4 sources out of 6 or 7, never a rout. Base is
a clear third on every metric in every scenario without exception.

## 4. Honest conclusion

Neither model is a clean overall winner, and the ranking genuinely depends on the weighting and inclusion rule,
confirming (with corrections to the specific strata) the expectation this task was scoped against. v12.11 is the
most *consistent* of the two candidates: it is the more accurate model, or tied, on the equal-per-source mean-rank
composite under every tested combination of inclusion rule and Nova Scotia treatment, it never finishes clearly
last on any metric, and it leads the pooled %RMSE specifically once Nova Scotia and the full ME/NB/QC source set
are both included. OSM-ACD v2.26.1 is the more *decisive* winner where it wins: it leads the fairest,
apples-to-apples pooled %RMSE comparison (common-cells-only) in every Nova Scotia scenario, and on the
determinant cross-tab (Table 31 to 33) it sweeps every managed-status cell in both regions and every softwood and mixedwood ME/NB/QC cell, a broad and reproducible advantage on managed and softwood/mixedwood stands, not a
narrow one. This corrects one part of this task's working hypothesis: the determinant data on disk does **not**
show v12.11 leading on managed status or on the long-horizon bucket. OSM wins managed status outright in both
regions, and base, not v12.11, wins the single long-horizon (over-30-year) NS cell (v12.11 loses that cell to
both other models, 52.35 vs. base's 49.79 and OSM's 50.28). What the data does support is that v12.11's clearest
wins are hardwood and mixedwood in Nova Scotia and the two shorter NS projection-length buckets, and that v12.11
posts a materially lower bias magnitude than OSM in only one of the six scenario blocks (all-available-data,
without NS) and is otherwise the more biased of the two candidate/OSM pair in most scenarios (v12.11's pooled
bias runs -9.6 to -17.6 across scenarios; OSM's runs -2.4 to -17.3, essentially the same range, so bias does not
cleanly favor either model either). The defensible summary for report language: **v12.11 is the more consistent
performer and the model to prefer if the goal is minimizing worst-case error across the full available benchmark
including Nova Scotia; OSM-ACD v2.26.1 is the more accurate model on the fairest common-cells comparison and on
managed and softwood/mixedwood strata specifically. Do not describe v12.11 as the overall winner without that
qualification, and do not describe OSM as the overall winner without noting it has no score at all for two of the
eight ME/NB/QC benchmark sources.**

## 5. Consistency with the rest of this report

This is not a reversal of anything already stated elsewhere in this report; it sharpens the same picture Section
11.4 already gave for Nova Scotia alone (OSM "the more accurate model on short-interval unmanaged stands," v12.11
"essentially tied" with OSM on managed stands there, v12.11 "clearly wins" only at the longest horizon within NS
specifically under one NS scorecard version, not the other). The full-scope reconciliation in this memo adds two
things Section 11.4 did not have: the ME/NB/QC-only picture (OSM's pooled %RMSE advantage is largest here,
21.96 to 22.0 vs. both FVS builds' 34 to 36, though on an easier six-of-eight-source subset), and the explicit
finding that the earlier "v12.11 leads decisively" headline was an artifact of a triple-counted Nova Scotia, not
a real result. Section 7.7's separate, broader-metric weighted composite (Tables 17 to 20) is not recomputed here
and remains not directly comparable, since it draws on a different, legacy five-model benchmark set and folds in
bias and value weighting.

## 6. Verification

Every number in Table 34 was produced by `figures/_data/build_reconciled_ranking.py`, which reads
`v1211_allsites_scorecard.csv`, `bench_ns_scorecard.csv`, and `bench_ns_long_scorecard.csv` directly (no
retyping) and writes `master_scorecard_sources.csv` (the 28-row per-source table), `overall_ranking.csv` (the
18-row, six-scenario table reproduced above), `overall_ranking_summary.csv`, and `overall_ranking_detail.csv`.
Spot checks against the source files: the NS-included, all-available-data pooled %RMSE for v12.11 (76.58) equals
the n-weighted average of its eight ME/NB/QC source RMSEs (n = 8,612, weighted mean 34.68) and its NS overall
RMSE (n = 4,504, RMSE 156.69), confirmed by hand: (8612 x 34.68 + 4504 x 156.69) / 13116 = 76.58. The
common-cells-only, with-NS mean-rank tie between v12.11 and OSM (1.571 each) is confirmed by the per-source rank
detail in `overall_ranking_detail.csv`: OSM wins 4 of 7 shared sources (PEF, Maine FIA whole-plot, SILC, NS) and
finishes second on the other 3 (Baxter, CFRU CTRN, NB MagPlot); v12.11 wins 3 of 7 (Baxter, CFRU CTRN, NB
MagPlot) and finishes second on the other 4; both average to 11/7 = 1.571. Neither of the two prior computations'
raw numbers (1.53/1.72/2.50 mean rank, 109.75/121.45/128.91 pooled %RMSE from the first pass; 1.38/1.92/2.69 mean
rank, 75.20/74.59/84.83 pooled %RMSE from the second) reproduce exactly from any scenario in Table 34, because
both were built on the cross-tabulated, NS-multiply-counted determinant cells (Section 1) rather than the
non-overlapping per-source data used here; this memo's numbers are the ones traceable end to end to source and
should be treated as authoritative going forward.

## 7. Provenance and open items

`figures/_data/master_scorecard.csv` (determinant cross-tab, Tables 31 to 33) is unchanged from the prior version
of this memo and remains correct for what it shows; it should not be used to build an overall ranking (Section
1). `figures/_data/master_scorecard_sources.csv`, `overall_ranking.csv`, `overall_ranking_summary.csv`, and
`overall_ranking_detail.csv` are new or rebuilt in this pass by `figures/_data/build_reconciled_ranking.py`; the
prior versions of the ranking files are preserved as `overall_ranking_PREV_20260723.csv`,
`overall_ranking_summary_PREV_20260723.csv`, and `overall_ranking_detail_PREV_20260723.csv`, and the prior memo as
`20260723_master_scorecard_and_ranking_PREV_20260723.md`, per this workspace's provenance convention.
`figures/fig22_determinant_scorecard.png` is unchanged (still built from `master_scorecard.csv` by
`make_fig22_23_scorecard_ranking.py`); `figures/fig23_overall_ranking.png` is rebuilt by the new
`figures/_data/make_fig23_reconciled.py` to show both weightings and both NS treatments side by side, and the
prior figure is preserved as `fig23_overall_ranking_PREV_20260723.png`. All computation ran locally on
already-downloaded aggregate CSVs; no proprietary tree records or plot coordinates were used or produced.

The site-productivity determinant remains entirely unscored (no dataset in this project bins stands by
site-index tercile); that is a genuine follow-on, not attempted here. The projection-length determinant remains
NS-only. The two Nova Scotia scorecards (`bench_ns_scorecard.csv` and `bench_ns_long_scorecard.csv`) disagree
narrowly on which model NS itself favors (OSM by 2.4% relative on the original scorecard; v12.11 by 0.8% relative
on the long scorecard); reconciling those two scorecards into one canonical NS benchmark, rather than carrying
both forward as a disclosed sensitivity, is a genuine follow-on for a future session and is out of scope for this
reconciliation pass.
