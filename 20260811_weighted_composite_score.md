# Stand-years-weighted overall composite score: FVS-ACD v12.11 vs OSM-ACD v2.26.1 vs base v12.10.1

11 August 2026. This document answers a question the existing scorecard does not: a single
overall benchmark number that pools across datasets and is weighted by both how many plots each
dataset contributes and how long each dataset's remeasurement interval is. It builds directly on
`20260811_final_scorecard_all_datasets.md`, the canonical 11-dataset coverage matrix finalized
earlier today, and changes no number in it. `[STACK: Python, R/Cardinal unavailable this
session]`. Cardinal SSH timed out and no R installation is reachable in this sandbox, so the
numbers below were computed in Python (`scripts/composite_score_weighted.py`, executed and
verified this session). The canonical production script, `scripts/composite_score_weighted.R`,
is written and ready to run on Cardinal (data.table) the next time that access returns, as a
verification pass against the same two source CSVs; I expect an exact match to the Python
numbers since both use the same weighting formula, row set, seed, and bootstrap count.

## Weighting formula

I weight each dataset by stand-years of observation, n times interval_years, the standard way
to pool an error metric across studies that differ in both sample size and remeasurement length.
More stand-years means more information in two distinct senses: more plots contribute more
independent residuals, and a longer interval is a harder, more informative test of a growth
model's long-horizon behavior than a short one, since compounding growth and mortality error is
much easier to hide over one year than over twenty. This is a chosen weighting scheme, not the
only defensible one. Inverse-variance weighting is the standard meta-analytic alternative and
would be preferable in principle, but it requires a per-source variance estimate for TOTVOL
%RMSE, and at this aggregation level I only have the already-pooled source-level point estimate,
not the underlying plot-level residuals needed to compute one. That is a real limitation of what
follows, not a detail to gloss over.

## Composite results

Restricted to the seven sources where all three models have a score (excluding Maine FIA
subplot and QC MagPlot, where OSM has never been run, following the same common-cells
methodology the finalized scorecard already uses), the stand-years-weighted composite TOTVOL
%RMSE is:

Under the NS treatment (Nova Scotia's overall scorecard, n = 4,504, assumed 5.1-year interval):
base 104.9 [32.5, 168.0], candidate v12.11 92.4 [30.3, 144.6], OSM-ACD v2.26.1 88.3 [28.0,
141.5]. All intervals are 95% source-cluster bootstrap intervals (2,000 resamples, seed
20260811). Composite bias runs base −25.9% [−37.5, −1.8], v12.11 −20.4% [−27.6, −0.1], OSM
−16.4% [−26.7, −1.5].

Under the NS-long treatment (Nova Scotia's all-consecutive-pairs scorecard, n = 5,348, pooled
interval 12.0 years, computed as the n-weighted mean of NS-long's own three stated
projection-length buckets), the composite RMSE is: base 119.9 [32.5, 149.6], v12.11 100.8 [30.3,
123.9], OSM 100.2 [28.0, 124.8]. Composite bias: base −31.8% [−38.4, −1.8], v12.11 −24.9%
[−29.3, −0.1], OSM −24.2% [−30.9, −1.5].

Both treatments put v12.11 and OSM within roughly four RMSE points of each other, well inside
either model's own bootstrap interval, which is an equivalence result rather than a ranking one:
neither model's composite interval excludes the other's point estimate, so I would not describe
either as decisively better once stand-years weighting and the resampling uncertainty are both
on the table. Base trails both by a wider, still-overlapping margin. This is a materially
different picture from the unweighted equal-per-source mean rank in the finalized scorecard,
which gave v12.11 the edge in five of six scenarios; stand-years weighting pulls the composite
toward the largest datasets (see below), which changes which comparison is doing the work.

v12.11 also has a fuller-coverage figure that cannot be set against OSM head-to-head, since OSM
is missing two of the nine rows v12.11 has. Across all nine sources v12.11 has data for (adding
Maine FIA subplot back in), the composite RMSE is 70.1 [37.9, 131.6] under the NS treatment and
81.2 [37.9, 119.6] under NS-long, with bias −22.0% [−25.9, −2.5] and −24.2% [−28.1, −2.5]
respectively. This number is legitimate context, not a comparison; it drops when Maine FIA
subplot enters because that dataset alone carries 57,160 of the roughly 109,000 total v12.11
stand-years in the NS scenario, over half the total weight by itself, and that source scores
worse than v12.11's overall average (51.3% RMSE against a composite in the 70s-80s). I flag that
because it means the fuller nine-source composite is not simply "more generous" to v12.11 than
the seven-source one; it is dominated by the one large developing-stand source OSM has never
been run against.

## What is driving the composite

Figure 21 (`figures/fig21_weighted_composite_score.png`) shows both the bar-and-interval panel
above and, alongside it, the stand-years weight each source contributes. Maine sources (Baxter,
CFRU CTRN, both Maine FIA grains, PEF, SILC/Seven Islands) supply 74% of total stand-years
weight under the NS treatment, driven almost entirely by the two 20-year Maine FIA intervals and
by Maine FIA subplot's large n. Nova Scotia's own weight (23,000 stand-years under NS treatment)
is real but is not the largest single contributor once the Maine FIA sources are combined, even
though NS alone has more raw plots than any single Maine source. That is the interval term doing
its job: a 5.1-year NS interval weighs less per plot than a 20-year Maine FIA interval, by
design, because the formula treats a longer remeasurement span as a harder test.

## Coverage caveat

OSM-ACD has never been scored on Maine FIA subplot (n = 2,858) or QC MagPlot (n = 378); both are
excluded from every head-to-head number above, exactly as the finalized scorecard's common-cells
rule already handles this gap. Separately, neither v12.11 nor OSM has a score on the memat/medev
mature-and-control pair (n = 1,757 and n = 1,759), a v13.1-track dataset built after the v12.11
freeze; I excluded it from the composite entirely rather than impute a score, since a weighted
composite cannot weight a number that does not exist. Both gaps are stated here, not buried,
following the finalized scorecard's own house rule against silent omission.

Nova Scotia and NS-long are two overlapping representations of the same plot network, not two
independent datasets, so I never combine them into one composite; I report the composite under
both treatments as parallel scenarios, following the same precedent the finalized scorecard uses
for its six-scenario reconciliation. NS-long's own bucket-level RMSE by model (<15 yr, 15-30 yr,
>30 yr) is recoverable from `figures/_data/master_scorecard.csv` and is listed separately in
`figures/_data/composite_score_weighted.csv`; NS-long's bucket-level bias is not present in that
file. Rather than build an inconsistent composite that uses three rows for RMSE and one pooled
row for bias, I used the single pooled NS-long row for both metrics, which keeps the bootstrap
cluster count identical across the two statistics. That inconsistency between what is and is not
decomposable is itself a finding, not just a methods footnote.

## Interval assumptions

Several interval-years values are assumptions, not stated numbers, and each is tagged in
`figures/_data/composite_score_weighted.csv`: Maine FIA subplot's 20-year interval assumes it is
the same underlying population as the whole-plot/long dataset at a finer grain; SILC/Seven
Islands' 11.5-year interval is the midpoint of a range stated for a 60-plot subset, applied here
to the full 73-plot set without confirming the subset is identical; NB and QC MagPlot's 7-year
intervals both borrow the combined NB+QC legacy mean, which I judged a reasonable transfer since
it is the same physical network disaggregated by province; and NS overall's 5.1-year interval
borrows NS-long's own <15-year bucket mean on the strength of pass-6 handoff language placing NS
overall in that band. PEF's interval is a genuine unknown, not a range to split the difference
on: I excluded it from temporal weighting rather than borrow the NB/QC mean, because PEF is a
distinct plot system with no documented remeasurement kinship to the NB/QC legacy network, and
importing a number from an unrelated network struck me as worse than being honest that PEF's
weight here is n-only. None of these are large enough individually to flip the ranking above,
but PEF and Maine FIA subplot's true intervals would meaningfully sharpen the composite if
confirmed.

## Bootstrap-unit limitation

Every interval above is a source-level cluster bootstrap: I resampled the seven or nine included
datasets with replacement, 2,000 times, and took the 2.5th and 97.5th percentile of the
recomputed weighted composite each time. That is a genuinely coarser resampling unit than the
plot-level bootstrap my usual practice calls for, since fewer than a dozen clusters exist in any
scenario here, and the wide intervals above (roughly 30 to 40 points of RMSE on either side of
most point estimates) are partly an artifact of that small cluster count rather than a claim
about how much the underlying plot-level uncertainty truly is. A proper plot-level bootstrap on
Cardinal would resample individual stand-pairs within each source rather than whole sources, and
would need the row-level scored output (per-stand residuals, in the style of
`cb_v12102_results.csv`) for each of the seven to nine included datasets rather than the
already-aggregated per-source RMSE/bias this sandbox has access to. That is the concrete next
step, and it belongs on Cardinal, not here.

## What closing the remaining gaps would take

Confirming Maine FIA subplot's assumed 20-year interval, scoring memat and medev against v12.11
and OSM, pinning down PEF's actual remeasurement interval, and splitting the NB/QC combined
7-year mean into its two provinces individually all require either the original plot metadata
(interval confirmation) or new Cardinal runs (the memat/medev and OSM-on-Maine-FIA-subplot and
OSM-on-QC-MagPlot scoring), none of which this sandbox can do. All four are tracked as open
items and none is fixable until Cardinal access returns.

*Data: `figures/_data/composite_score_weighted.csv` (row detail, weights, composite results,
NS-long bucket table). Figure: `figures/fig21_weighted_composite_score.png`. Scripts:
`scripts/composite_score_weighted.py` (executed this session), `scripts/composite_score_weighted.R`
(canonical, unexecuted, for Cardinal). Source data unchanged: `figures/_data/master_scorecard_sources.csv`,
`figures/_data/master_scorecard.csv`.*
