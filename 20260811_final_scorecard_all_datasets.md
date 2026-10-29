# Final scorecard, all eleven datasets: BASE vs CANDIDATE v12.11 vs OSM-ACD v2.26.1

11 August 2026. Finalization pass. **This file is now the canonical scorecard for FVS-ACD v12.11 versus
OSM-ACD v2.26.1.** It supersedes `20260723_master_scorecard_and_ranking.md`, which is retained as a provenance
record only (its content is preserved unchanged in `20260723_master_scorecard_and_ranking_PREV_20260811.md`; the
live file now carries a pointer stub to this document). No new Cardinal runs were made for this pass, no frozen
number was altered, and no edit was made to `AcadianGY_12.11.r` or any scoring harness. This is a compilation and
presentation pass over already-scored, already-frozen data. No em dashes.

## 1. Why this pass exists and what changed

Cardinal HPC access is currently down, so no new OSM-ACD v2.26.1 runs are possible this week. Two of the
project's eleven benchmark sources have never been scored for OSM: Maine FIA subplot (n = 2,858) and QC MagPlot
(n = 378). That gap cannot be closed this cycle. Rather than wait or approximate a missing score, this pass
finalizes the scorecard now, using only already-scored, already-frozen data, and documents the coverage gap
transparently as part of the deliverable rather than as a footnote to be discovered later. Chris Hennigar, OSM's
developer, will see this document, so the coverage accounting below is deliberately exhaustive: every one of the
eleven sources this project has ever staged is listed, with an honest yes-or-no for each of the two frozen model
builds compared here, not just the two gaps already known.

Three things are new in this pass relative to `20260723_master_scorecard_and_ranking.md`, and none of them change
a previously published number:

First, a coverage matrix (Section 2, Table 30) spanning all eleven staged sources, which the prior master
scorecard's Section 3 ranking implicitly used but never tabulated on its own. Second, confirmation, found while
building that matrix, of a third and previously undocumented coverage gap: the Maine FIA mature/control pair
(`memat`, n = 1,757; `medev`, n = 1,759), built during the v13.1 development pass on 5 August 2026, has **no
score for either v12.11 or OSM**, only for the frozen base and a set of experimental v13.1 self-thinning and
ingrowth levers. This pair was never part of the eight-source ME/NB/QC set the existing ranking (Section 4,
Table 34) is built on, so its absence changes nothing about that ranking; it is disclosed here because the task
was to audit coverage across every staged source, not only the two already flagged. Third, the two open items
from `20260804_benchmark_integrity_caveat.md`, QC MagPlot managed never rescored under the validated height
treatment and the Baxter v12.11 reproduction control failing at 750 against a 5e-13 target, are both still open
as of this pass and are restated in Section 9 rather than claimed resolved.

Everything else, the four-determinant cross-tab (Section 3), the eight-source and common-cells overall ranking
under all six scenarios (Section 4), the honest conclusion (Section 6), and every caveat in the prior master
scorecard, is carried forward without change. Nothing is dropped.

## 2. Coverage matrix: all eleven staged benchmark sources

**Table 30.** Coverage of FVS-ACD v12.11 and OSM-ACD v2.26.1 across every benchmark source this project has
staged, headline metric total-volume percent RMSE (TOTVOL %RMSE) and total-volume level bias, NSVB currency
throughout. n reported per model where it differs (imputation and matching exclude a handful of stands from some
sources' OSM runs). House table standard applies: contents centered, header row bold, rule above header, rule
below header, rule below last row, no vertical or interior rules; units in the header, not repeated per cell.

| **Dataset** | **n (base / v12.11 / OSM)** | **FVS-ACD v12.11** | **OSM-ACD v2.26.1** | **Coverage note** |
|---|---|---|---|---|
| Maine FIA whole-plot (= 20-yr long remeasurement chain) | 918 / 918 / 918 | Scored: 38.6% RMSE, -16.1% bias | Scored: 31.9% RMSE, -6.3% bias | Both scored. Same physical n = 918 stand-pair set carried under two labels across project history (whole-plot grain; the ~20-year long-interval chain); reconciled here to one row rather than counted twice |
| Maine FIA subplot | 2,858 / 2,858 / -- | Scored: 51.3% RMSE, -24.8% bias | **No score** | Gap 1 of 2. Finer (about 0.017 ha) grain; does not transfer from the whole-plot fit |
| Maine FIA mature (memat) | 1,757 (base only) | **No score** | **No score** | v13.1-track dataset built 5 Aug 2026, after v12.11 was frozen. Scored only against base v12.10.1 and experimental v13.1 levers. Newly documented in this pass |
| Maine FIA control (medev) | 1,759 (base only) | **No score** | **No score** | Paired with memat, same status |
| PEF | 2,853 / 2,853 / 2,853 | Scored: 17.9% RMSE, +1.4% bias | Scored: 14.7% RMSE, +0.3% bias | Both scored. Measured-height coverage only 4.0%; near-zero bias is largely a height-imputation artifact, not evidence of an unbiased developing-stand fit (Section 2.1 of the benchmark report) |
| CFRU CTRN (managed) | 1,086 / 1,086 / 1,033 | Scored: 18.1% RMSE, -2.2% bias | Scored: 20.5% RMSE, -4.8% bias | Both scored. Measured-height coverage 52.0%; height-treatment sensitivity tested directly and the managed win is unchanged in ordering |
| SILC / Seven Islands (calibration, managed) | 73 / 73 / 69 | Scored: 64.2% RMSE, -5.7% bias | Scored: 63.0% RMSE, -18.1% bias | Both scored |
| Baxter SFMA CFI (mature, held out) | 91 / 91 / 91 | Scored: 48.1% RMSE, +6.9% bias | Scored: 50.8% RMSE, +12.4% bias | Both scored. Measured-height coverage 18.5%; v12.11's reproduction control on the rebuilt tree list still fails at 750 against a 5e-13 target (open item, Section 9) |
| NB MagPlot (managed) | 355 / 355 / 355 | Scored: 41.9% RMSE, -6.0% bias | Scored: 43.8% RMSE, -8.1% bias | Both scored. Measured-height coverage 32.8% (combined NB/QC extract) |
| QC MagPlot (managed) | 378 / 378 / -- | Scored: 58.5% RMSE, +9.5% bias | **No score** | Gap 2 of 2. Managed rescore under the validated fitted-height treatment also still open (Section 9) |
| Nova Scotia (independent benchmark, not pooled into ME/NB/QC) | 4,504 / 4,504 / 4,499 | Scored: 156.7% RMSE, -30.6% bias | Scored: 153.1% RMSE, -29.2% bias | Both scored |

*Data: `figures/_data/v1211_allsites_scorecard.csv`, `figures/_data/master_scorecard_sources.csv`,
`figures/_data/bench_ns_scorecard.csv`, `20260805_v131_pass5_handoff.md` and
`20260805_v131_pass6_handoff.md` (memat/medev status), `scripts/osm_score_ns.R` (confirms OSM's NS coverage is
built by a dedicated script separate from the eight-source ME/NB/QC harness), and Table 5a of
`FVS-ACD_v12.11_benchmark_report.md` Section 2.1 (the eleven-source measured-height coverage census, SLURM job
13305450, which independently enumerates the same eleven sources).*

**Reading the matrix.** Of the eleven staged sources, FVS-ACD v12.11 is scored on nine (all except memat and
medev). OSM-ACD v2.26.1 is scored on seven (all except Maine FIA subplot, QC MagPlot, memat, and medev).
Restricted to the eight ME/NB/QC sources that form the frozen non-overlapping ranking basis in Section 4 (Baxter,
CTRN, Maine FIA whole-plot, Maine FIA subplot, PEF, SILC, NB MagPlot, QC MagPlot), OSM is scored on six of eight,
missing Maine FIA subplot and QC MagPlot, exactly the two-source gap this pass exists to document. The memat and
medev gap is a separate, third finding: neither frozen model being compared in this report has a score there, so
it changes no ranking, but it is disclosed because it was found in the course of this coverage audit and the
house rule against silent omission applies to newly discovered gaps as much as to previously known ones.

## 3. Master scorecard by determinant (carried forward unchanged, re-verified in this pass)

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
table as a rank-colored heatmap. Unchanged from the 23 July master scorecard; read on its own terms (each row an
independent cross-tab, not an overall ranking), OSM wins every managed-status and softwood/mixedwood cell in both
regions; v12.11's clean wins are hardwood and mixedwood in NS and both of NS's shorter projection-length buckets;
base wins only the over-30-year NS bucket. This table should not be mean-ranked or pooled directly across its 13
populated rows for an overall ranking, because doing so triple-counts NS (Section 4).*

## 4. Overall ranking, non-overlapping per-source basis, both weightings, both inclusion rules

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
`master_scorecard_sources.csv` (the 28-row non-overlapping per-source input table underlying this ranking, now
cross-referenced against the eleven-source coverage matrix in Table 30). Bold marks the better model on each
metric within each scenario row-pair; a tie is bolded on both. This table is unchanged from the 23 July master
scorecard; only Table 30 above and the coverage-gap accounting are new.*

**Reading the table.** v12.11 has the better (lower) equal-per-source mean rank in five of the six scenario
blocks and ties OSM exactly in the sixth (common-cells-only, with NS, original scorecard: 1.571 for both). v12.11
never finishes with the worse mean rank in any scenario tested. OSM has the better (lower) pooled %RMSE in four
of the six scenario blocks; v12.11 has the better pooled %RMSE only when Nova Scotia is included and the
all-available-data rule is used, which is also the version most favorable to v12.11, because it lets v12.11 use
its full eight-source ME/NB/QC average against OSM's easier six-source one (Table 30 makes that asymmetry
explicit for the first time). Under the strictest, fairest rule (common-cells-only, where every model is scored
on exactly the same stands), OSM leads pooled %RMSE in every NS treatment and either ties or leads mean rank,
though only by 0 to 4 sources out of 6 or 7, never a rout. Base is a clear third on every metric in every scenario
without exception.

## 5. What this means and does not mean

This scorecard supports three claims and no more. First, v12.11 is the more consistent of the two candidate
models: it is the more accurate model, or tied, on the equal-per-source mean-rank composite under every tested
combination of inclusion rule and Nova Scotia treatment, and it never finishes clearly last on any metric. Second,
OSM-ACD v2.26.1 is the more accurate model on the fairest, apples-to-apples comparison this project can currently
run, the common-cells-only pooled %RMSE, in every Nova Scotia scenario, and it sweeps every managed-status and
softwood/mixedwood cell in the determinant cross-tab. Third, and this is the qualification that both of the first
two claims depend on, OSM has never been scored on two of the eight ME/NB/QC sources that make up that
comparison, Maine FIA subplot and QC MagPlot, so its wins are wins on an easier six-source subset, not on the
full set v12.11 and base are held to. That gap is now compounded, in this pass's coverage audit, by a third,
previously undocumented gap on the memat/medev mature pair, where neither model has a score at all.

None of this is closeable this cycle. Cardinal HPC access is currently down, and running OSM on the two missing
ME/NB/QC sources, closing the Baxter reproduction control, or rescoring QC MagPlot under the validated height
treatment all require the analysis cluster. This is the single largest limitation of the comparison presented
here, and it should be stated as plainly to this audience as it is stated in this document: do not describe
v12.11 as the overall winner without noting that OSM's fairest-comparison lead holds where the two models are
scored on the same stands, and do not describe OSM as the overall winner without noting it has no score at all
for two, soon to be disclosed as arguably three if memat/medev are counted, of this project's benchmark sources.
Both qualifications are load-bearing. Reporting only one of them would misstate what this scorecard shows, in
either direction, and this document is written on the premise that OSM's own developer will check it against his
own model's results, not merely read the headline.

## 6. Honest conclusion

Neither model is a clean overall winner, and the ranking genuinely depends on the weighting, the inclusion rule,
and now, explicitly, the coverage gap. v12.11 is the most *consistent* of the two candidates: it is the more
accurate model, or tied, on the equal-per-source mean-rank composite under every tested combination of inclusion
rule and Nova Scotia treatment, it never finishes clearly last on any metric, and it leads the pooled %RMSE
specifically once Nova Scotia and the full ME/NB/QC source set are both included. OSM-ACD v2.26.1 is the more
*decisive* winner where it wins: it leads the fairest, apples-to-apples pooled %RMSE comparison (common-cells-
only) in every Nova Scotia scenario, and on the determinant cross-tab (Tables 31 to 33) it sweeps every
managed-status cell in both regions and every softwood and mixedwood ME/NB/QC cell, a broad and reproducible
advantage on managed and softwood/mixedwood stands, not a narrow one. The determinant data on disk does **not**
show v12.11 leading on managed status or on the long-horizon bucket: OSM wins managed status outright in both
regions, and base, not v12.11, wins the single long-horizon (over-30-year) NS cell. What the data does support is
that v12.11's clearest wins are hardwood and mixedwood in Nova Scotia and the two shorter NS projection-length
buckets, and that v12.11 posts a materially lower bias magnitude than OSM in only one of the six scenario blocks
and is otherwise the more biased of the two in most scenarios, so bias does not cleanly favor either model. The
defensible summary for report language, unchanged from the 23 July version and sharpened by the coverage matrix
above: **v12.11 is the more consistent performer and the model to prefer if the goal is minimizing worst-case
error across the full available benchmark including Nova Scotia; OSM-ACD v2.26.1 is the more accurate model on
the fairest common-cells comparison and on managed and softwood/mixedwood strata specifically. Do not describe
v12.11 as the overall winner without that qualification, and do not describe OSM as the overall winner without
noting it has no score at all for two of the eight ME/NB/QC benchmark sources, and, separately, no score at all
on the memat/medev pair that neither frozen model has been run against.**

## 7. Consistency with the rest of this report

This is not a reversal of anything already stated elsewhere in this report; it sharpens the same picture Section
11.4 of the benchmark report already gave for Nova Scotia alone (OSM "the more accurate model on short-interval
unmanaged stands," v12.11 "essentially tied" with OSM on managed stands there, v12.11 "clearly wins" only at the
longest horizon within NS specifically under one NS scorecard version, not the other). It is also consistent with
Section 2.1 and Section 10.5.1's measured-height coverage accounting: PEF and Baxter's near-zero and mature
over-prediction readings, and the managed CTRN and MagPlot results, all carry a disclosed height-imputation
exposure that moves levels but not model ordering, as documented there and restated in Table 30's coverage notes.
Section 7's separate, broader-metric legacy five-way scorecard (Tables 7 and 8 of the benchmark report, n = 705,
NB and ESI-covered QC only) is not recomputed here and remains not directly comparable, since it draws on a
different, legacy five-model benchmark set and folds in bias and value weighting; it is cited in this pass only
to confirm that OSM's pooled advantage there, mean absolute bias 3.2 versus v12.10.1's 4.9%, mean NSE 0.75 versus
0.71, is the same direction and rough magnitude as this scorecard's common-cells finding, which is a useful
independent cross-check, not new evidence.

## 8. Verification

Every number in Table 34 was produced by `figures/_data/build_reconciled_ranking.py`, which reads
`v1211_allsites_scorecard.csv`, `bench_ns_scorecard.csv`, and `bench_ns_long_scorecard.csv` directly (no
retyping) and writes `master_scorecard_sources.csv`, `overall_ranking.csv`, `overall_ranking_summary.csv`, and
`overall_ranking_detail.csv`. Spot check, reproduced from the 23 July pass: the NS-included, all-available-data
pooled %RMSE for v12.11 (76.6) equals the n-weighted average of its eight ME/NB/QC source RMSEs (n = 8,612,
weighted mean 34.68) and its NS overall RMSE (n = 4,504, RMSE 156.69): (8612 x 34.68 + 4504 x 156.69) / 13116 =
76.58. Table 30's coverage matrix was independently built and cross-checked in this pass against three sources:
`v1211_allsites_scorecard.csv` and `master_scorecard_sources.csv` (which model rows exist per source, confirming
the presence or absence of an OSM row for each of the eight ME/NB/QC sources), the eleven-source measured-height
coverage census in `FVS-ACD_v12.11_benchmark_report.md` Section 2.1 Table 5a (SLURM job 13305450, an independent
enumeration of the same eleven staged sources by a different pipeline, coverage percentages not RMSE), and
`20260805_v131_pass5_handoff.md` / `20260805_v131_pass6_handoff.md` for the memat/medev status, where the scored
columns (base, r2, ramp off, s20, s08, b75, r2 + off) were checked by name against the v12.11 and OSM naming
convention used everywhere else in this project and confirmed to contain neither.

## 9. Provenance and open items

`figures/_data/master_scorecard.csv` (determinant cross-tab, Tables 31 to 33) and
`figures/_data/overall_ranking.csv` and its companions (Table 34) are unchanged from the 23 July pass and remain
correct for what they show. `figures/_data/master_scorecard_sources.csv` was cross-referenced, not rebuilt, for
Table 30. No frozen number changed in this pass. Table 30 (Section 2) is new to this document.

Two items remain open exactly as recorded in `20260804_benchmark_integrity_caveat.md` and are restated here
rather than claimed resolved. First, QC MagPlot managed has not been rescored under the validated fitted-height
treatment; its v12.11 result file is not present under the expected names, only v12.5, v12.7.0, and OSM exist for
that extract's height-sensitivity variant. This is the highest-value remaining test on the Quebec hardwood
finding. Second, the Baxter v12.11 reproduction control fails at 750 against the 5e-13 the Baxter-specific
harness achieves elsewhere, because the staged Baxter tree list was rebuilt during the staging repair and no
longer aligns with results scored before it; closing this requires the `baxfix_main2.R` rebuild path pointed at
`cand_baxter_results.csv`. Neither item is fixable this week without Cardinal access.

A third item is new to this pass. The memat/medev mature-and-control pair (Section 2, Table 30) exists as a
built, staged dataset but has never been scored against either v12.11 or OSM, only against base and a set of
experimental v13.1 self-thinning and ingrowth levers documented in the 5 August pass 5 and pass 6 handoffs. This
is out of scope for the v12.11-vs-OSM comparison this scorecard reports (it postdates the v12.11 freeze and
belongs to the v13.1 development track), but it is disclosed here because a coverage audit that stopped at the
two already-known gaps would not have been exhaustive, and the house rule against silent omission covers newly
found gaps as much as previously known ones.

The site-productivity determinant remains entirely unscored (no dataset in this project bins stands by
site-index tercile). The projection-length determinant remains NS-only. The two Nova Scotia scorecards
(`bench_ns_scorecard.csv` and `bench_ns_long_scorecard.csv`) disagree narrowly on which model NS itself favors
(OSM by 2.4% relative on the original scorecard; v12.11 by 0.8% relative on the long scorecard); reconciling
those two into one canonical NS benchmark remains a genuine follow-on, out of scope here. All four open items
above, the two carried from 4 August and the two new to this pass, require Cardinal HPC access to close and are
tracked for the next session in which that access is restored.

## 10. Canonical status

This file, `20260811_final_scorecard_all_datasets.md`, is the canonical scorecard for FVS-ACD v12.11 versus
OSM-ACD v2.26.1 as of 11 August 2026. `20260723_master_scorecard_and_ranking.md` is superseded and now carries a
pointer to this file; its original content is preserved unchanged at
`20260723_master_scorecard_and_ranking_PREV_20260811.md` for provenance. `20260804_benchmark_integrity_caveat.md`
remains the canonical correction record for the height-imputation finding and is unaffected by this pass. Every
number in this document traces to a file under `figures/_data/` or to `FVS-ACD_v12.11_benchmark_report.md`
Sections 2.1, 7, and 10.5.1; none was recomputed for this pass.
