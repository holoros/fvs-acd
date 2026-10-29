# Cardinal stress test and red team review, FVS-ACD v12.11 benchmark

12 August 2026. Autonomous OODA run, four parallel Cardinal tracks (A through D) plus a synthesis
track (E), triggered once Cardinal HPC access returned. Target: verify the composite score in
`20260811_weighted_composite_score.md`, replace its coarse source-level bootstrap with a genuine
plot-level one, resolve five assumed remeasurement intervals, and check three disclosed coverage
gaps for tractability. `[STACK: R/data.table on Cardinal, module purge; module load gcc/12.3.0
R/4.5.2]`. Decision on scope: Aaron chose to update the deck's headline composite numbers to the
corrected result below rather than footnote or defer it.

## Track A: R verification of the existing Python composite score

Reran `composite_score_weighted.R` on Cardinal against the same source data as
`composite_score_weighted.py`. Point estimates matched to under 0.01 on every cell, as expected
since both are deterministic weighted means. Bootstrap CI endpoints diverged by up to about 2
points, traced to Mersenne Twister (R) versus PCG64 (numpy) drawing different resamples under the
same integer seed, a known cross-language limitation rather than a defect. One bug fixed in the
Cardinal working copy only: `sys.frame(1)$ofile` fails under plain `Rscript`; replaced with the
standard `commandArgs()` idiom. No qualitative conclusion changed. R environment: 4.5.2,
data.table 1.18.4, already present in the personal library, no install needed.

## Track B: genuine plot-level bootstrap

Built `scripts/composite_score_plotlevel_bootstrap.R`, resampling stand rows within each of the 7
common-cells sources (not whole sources), using per-stand TOTVOL observed/predicted files found in
`~/magplot/verify/` on Cardinal. Row counts and recomputed point RMSE matched
`master_scorecard_sources.csv` to two decimals for all 21 source-model cells, confirming these are
the correct harness outputs. Intervals came in 5.5 to 8x narrower than the coarse source-level
bootstrap, point estimates unchanged. The v12.11-versus-OSM equivalence result held, on firmer
ground. Base separated cleanly from both under the NS-long treatment, a distinction the old wide
intervals had masked.

## Track C: remeasurement interval reconciliation

All five previously assumed interval-years values were traced to primary Cardinal plot metadata.
Maine FIA subplot (20.41 vs assumed 20.0) and Nova Scotia short (5.00 vs 5.1) confirmed the
assumption closely. SILC/Seven Islands came in lower than assumed (10.37 vs 11.5). NB and QC
MagPlot, previously forced to share one 7.0-year value, diverged sharply once measured separately:
NB 4.90 years, QC 9.76 years. Most consequential, PEF's interval, previously treated as a genuine
unknown and excluded from temporal weighting, was recovered at 5.61 years from
`PEF_CompartmentStudy_ActivityDates_INV_TREE.csv`, a file outside the location the original search
checked.

## Track D: coverage gap feasibility

Neither gap fully closed, but the investigation corrected a mischaracterization. The memat/medev
"base" numbers already circulating in project handoffs were found to come from a v13.1-development
baseline, not frozen v12.10.1 as labeled; the true v12.10.1/v12.11 scoring input for memat/medev no
longer exists in Cardinal scratch and would need to be rebuilt from raw FIA staging, beyond this
session. Separately, a working, licensed OSM-ACD v2.26.0 binary was found on this account with
prior successful runs against several of this project's own sources, contradicting the deck's
framing that OSM can only be run by Hennigar. Closing the OSM-on-Maine-FIA-subplot and
OSM-on-QC-MagPlot gaps needs a new OSM input built from those tree lists, a tractable follow-up not
completed this session.

## Track E: corrected composite score (synthesis)

Reran the plot-level bootstrap with Track C's measured intervals substituted into the weight
formula (weight = n x interval_years), most consequentially raising PEF's weight roughly 5.6x
since its placeholder interval of 1.0 year is replaced by the measured 5.61. PEF is the
lowest-RMSE source in the set (14.7 to 18.0%), so correcting its weight pulls every composite down
substantially, 11 to 19 RMSE points depending on scenario and model, far more than the roughly 2
point shift interval corrections alone would suggest. Verified: point estimates recomputed from the
corrected script reproduce the per-source RMSE values in `master_scorecard_sources.csv` exactly,
and PEF's weight is the only large mover (QC's corrected interval was not applied, since QC lacks
an OSM score and stays outside the 7-source common-cells set exactly as before).

Final numbers, TOTVOL %RMSE, 95% plot-level bootstrap interval, common cells (7 sources):

| Scenario | Base v12.10.1 | Candidate v12.11 | OSM-ACD v2.26.1 |
|---|---|---|---|
| NS | 86.2 [79.6, 92.7] | 76.4 [68.2, 83.9] | 72.4 [65.8, 78.9] |
| NS-long | 107.0 [100.3, 113.4] | 90.3 [82.6, 97.6] | 89.3 [82.5, 95.7] |

Both conclusions from the coarse version survive and sharpen. Candidate and OSM remain equivalent,
each point estimate sitting inside the other's interval under both scenarios. Base separates
cleanly from both under NS-long (non-overlapping intervals) and remains close but distinguishable
under NS.

## What changes in the deck

The Overall Summary and Overall Ranking Reconciled slides get the table above in place of the
current source-level bootstrap numbers, with the caption updated from "7-9 cluster source-level
bootstrap, a floor not a ceiling" to a plot-level cluster bootstrap disclosure, and the composite
methodology note pointing to `composite_score_final_corrected.R` rather than the Python script.
The memat/medev row, wherever it appears, needs a mislabel caveat rather than removal: state
plainly that the existing base figures are a v13.1-development baseline, not v12.10.1. OSM coverage
language should soften from implying vendor lock to stating the gap is unbuilt inputs, tractable on
a future Cardinal session. The reproducibility slide can add one line: composite score numbers now
independently verified in R on Cardinal.

## Status: deck edit blocked

The Cowork sandbox went unrecoverable (scratch volume full, `no space left on device` on every bash
call) partway through this run, after the numbers above were already downloaded into the repo and
verified. The pptx edit, PDF render, and rasterized visual pass all require the sandbox
(python-pptx, LibreOffice) and could not be completed this session. Restarting the session should
provision a fresh sandbox; the deck edit is then a direct, low-risk mechanical step since every
number above is already verified and the slide-level changes are scoped in the section above.

## Part 2: v13.1 inclusion, four-way comparison, corrected equivalence tests

12 August 2026, continuation. Aaron asked for v13.1 to be included in the deck as a real scored
model, rebuilt on Cardinal via `hpc-cardinal`, stress tested, red teamed, and for the scorecard's
overall row/column to be weighted toward longer projections per `weiskittel-modeling-philosophy`.

**v13.1 had never actually been scored in its disclosed shipping configuration.** Everything
sitting in Cardinal scratch under a v131 name was either a different architecture (hierarchical
GLMM ingrowth and mortality posteriors), the explicitly blocked 3.9x ingrowth stack, or an
unrelated diameter-increment tweak. Locating the true shipping configuration required resolving
two ambiguities with Aaron directly rather than guessing: the "r2" parameter turned out to be a
diameter-increment reshape spec (b0 -1.88366, b1 0.49788, b2 -0.0293426, from `model_b0b1b2.r`),
not the density-release knob `ops$ingrowth.rd.k` an initial reading suggested, and SDImax onset
0.55 was confirmed as the value to score even though the project's own 11 August notes flag it as
not yet paired with a still-pending survivor-increment fix ("LEVER 3"). Aaron approved scoring at
onset 0.55 with that caveat disclosed rather than smoothed over.

Job 13434825 (10 array tasks, about 3h15m) scored v13.1-shipping across all 7 common-cells sources.
One real data-quality catch: the shipping run's Nova Scotia output initially came in at 5000 and
5753 stands against a reference of 4504 and 5348, traced to a missing `INDOMAIN=1` filter (the
reference run drops stands without valid ESI8 site-index coverage; the shipping sbatch omitted
that flag). Fixed by applying the same filter post hoc; corrected counts match the reference
exactly.

**Four-way composite (n=9880 NS / 10724 NS-long, plot-level bootstrap, stand-years weighting
unchanged, n x interval_years, already the long-projection-weighted formula Aaron asked for):**

| Model | NS RMSE% | NS bias% | NS-long RMSE% | NS-long bias% |
|---|---|---|---|---|
| Base v12.10.1 | 86.2 [79.6, 92.7] | -20.2 [-21.5, -18.7] | 107.0 [100.1, 113.8] | -27.7 [-29.2, -26.0] |
| Candidate v12.11 | 76.4 [68.2, 83.9] | -15.8 [-17.1, -14.5] | 90.3 [82.1, 97.7] | -21.6 [-23.0, -20.1] |
| v13.1 shipping | 85.3 [79.0, 91.9] | -17.5 [-18.9, -16.1] | 106.3 [99.3, 113.1] | -24.9 [-26.5, -23.2] |
| OSM-ACD v2.26.1 | 72.4 [65.5, 79.2] | -12.8 [-14.1, -11.5] | 89.3 [82.8, 95.7] | -21.1 [-22.5, -19.7] |

v13.1-shipping sits close to base and clearly behind both v12.11 and OSM on the composite. This is
a materially less favorable picture than the roadmap slide's framing and should not be softened
before it reaches the deck.

**Equivalence tests (TOST, region +/-25% of mean(obs) for the intercept, +/-0.25 around 1 for the
slope, both the literature default, disclosed as such rather than decision-derived) needed a real
methodological fix.** The first pooled attempt (all 7 sources together) returned an implausible
v13.1 intercept near +79 and slope near 0.56, a between-source confound rather than a real
attenuation signal, caught by comparing against a per-source spot check. Demeaning each source by
its own mean before pooling resolved the intercept completely (every model comes back at
approximately 0, inside the region) but exposed a second, sharper finding: the slope failure that
remains is concentrated almost entirely in Nova Scotia (slope near 0.13 to 0.2 for every model,
including frozen base), while the other 6 sources individually look sane for all four models. Since
the anomaly appears in base as much as in the newer versions, this reads as a Nova Scotia
data-domain issue (restricted variance or leverage points in that benchmark set) rather than a
v13.1 weakness, and is worth raising with Hennigar as a question about the NS data itself, not
folded into a v13.1 critique. All three pairwise verdicts (v13.1 vs OSM, v13.1 vs v12.11, v12.11 vs
OSM) remain NOT EQUIVALENT on the pooled slope test once NS is included; this should be reported
plainly rather than passed off as resolved.

Figures generated headless on Cardinal (ggplot2, sandbox unavailable for rendering):
`figures/fig28_fourway_scorecard.png` (4-model x 7-source heatmap plus the weighted Overall row,
both scenarios) and `figures/fig29_equivalence_demeaned.png` (demeaned observed-vs-predicted with
1:1 line, fitted slope CI, and the equivalence region, three pairs, both scenarios).

## Provenance

New files this session: `figures/_data/composite_score_final_corrected.csv`,
`scripts/composite_score_final_corrected.R`, `figures/_data/composite_score_plotlevel.csv`,
`scripts/composite_score_plotlevel_bootstrap.R`, `figures/_data/composite_score_weighted_R_VERIFY.csv`.
Sources: `figures/_data/master_scorecard_sources.csv`, `20260811_weighted_composite_score.md`,
`20260811_final_scorecard_all_datasets.md`, and primary Cardinal plot metadata cited per track
above. No deck, figure, or previously shipped number was altered by this run; all edits are staged
for the next session.

Part 2 new files: `figures/_data/v131_shipping/v131ship_*_results.csv` (9 sources, Cardinal job
13434825), `scripts/composite_score_fourway.R`, `figures/_data/composite_score_fourway.csv`,
`scripts/equivalence_tests_fourway_demeaned.R`, `figures/_data/equivalence_tests_fourway_demeaned.csv`,
`figures/_data/equivalence_tests_fourway_persource.csv`,
`figures/_data/equivalence_tests_fourway_demeaned_pointdata.csv`, `figures/fig28_fourway_scorecard.png`,
`figures/fig29_equivalence_demeaned.png`, `figures/_data/make_fig28_fourway_scorecard.R`,
`figures/_data/make_fig29_equivalence_demeaned.R`. v13.1 shipping configuration confirmed with
Aaron directly (r2 parameter identity, SDImax onset value) rather than inferred, per F9 discipline.
