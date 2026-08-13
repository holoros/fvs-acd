# Red-team memo: FVS-ACD v12.10.1 August benchmark materials

*10 July 2026. Adversarial review of the benchmark report, the GTR draft, the Hennigar deck, the freeze
note, and the scorecard data behind the figures, ahead of the 18 August 2026 Acadian Growth and Yield
meeting. Read-only on the deck and GTR; only clearly-safe non-numeric caveats were applied to the benchmark
report, listed at the end. No em dashes.*

## Verdict

Ready with fixes. The strategic story is honest and defensible: OSM is modestly ahead on pooled precision,
FVS-ACD wins the managed cell out of sample and on biological realism, and the offsetting-bias and ingrowth
limits are disclosed rather than buried. That message survives the red team. But the materials were
finalized on the same day the Phase 1 baseline correction landed, and the correction did not propagate into
the flagship pooled scorecard table, the figure data, or one provenance paragraph. As a result the report
currently shows a total-volume bias of the wrong sign in its headline table, OSM modeling-efficiency numbers
that contradict the corrected run, and points at a canonical baseline file that does not exist in the repo.
None of these change the conclusion, but all three are visible to a careful reader like Hennigar and must be
reconciled before the deck and report go out. Fix the three blockers, apply the should-fix caveats, and this
is meeting-ready.

## What is already strong

The honest-limits discipline is genuinely good. The report and deck both lead with OSM ahead on the
operational domain, state the volume near-parity as an offsetting cancellation rather than independent
accuracy, disclose the ingrowth under-prediction with the exact ratios, and declare the Quebec edge as a
stated boundary rather than a scored win. The management-cell headline is the best-supported part of the
package: the in-sample class-bias table and the mgmt_scorecard_byclass_robust.csv tie out exactly (planted
BA -23.6 to -3.2, PCT +0.3, managed -17.6 to -1.0), the gate-off byte-identity claim is checked, and the
out-of-sample battery uses leave-one-installation-out, leave-one-province-out, and a split-half, which is
the right way to earn the managed claim. The offsetting-bias framing is honest and correctly tagged as the
v13.0 target, not a strength. The v13 program is consistently labeled in progress and not gated across all
three documents. The QMD advantage, transparency, and ESI-driver points are fair and not overstated. The
deck slide 9 transparency point is measured (it concedes OSM's diameter-growth RF table is exposed and only
mortality/ingrowth are not source-visible), so the "we are transparent" contrast is not oversold.

## BLOCKER

### B1. The pooled five-way scorecard table is the pre-correction run; total-volume bias has the wrong sign

Location: benchmark report, "Pooled five-way scorecard" section (the level-bias table and the summary
rollup), and every downstream sentence that cites +9 top height or +4 total volume for FVS-ACD.

Problem. The report table gives v12.10.1 pooled top height about +9.1 percent and total volume about +4.1
percent (over-prediction). The corrected frozen model output (cb_1210chk, the actual 12.10.1.r) gives top
height +4.21 and total volume -4.41 (under-prediction) on the same 733 stands, and the report's own
operational-domain table gives +4.02 and -3.64. Restricting to in domain does not move top height from +4 to
+9 (the report's own in-domain top height is +4.16), so the +9.1 cannot be a subset effect. It is the 1 July
run, before the ESI-anchor and merge corrections. The consequence that matters for the meeting: the headline
table shows total volume biased positive (over) while the verdict prose, the operational-domain table, the
freeze note, and the raw model output all show it biased slightly negative (under). That is a sign flip on
the single most-scrutinized number in the deck.

Fix. Re-derive the entire pooled five-way level-bias table and the summary rollup from the corrected
single-keyed-merge run (the same run that already produced the report's corrected OSM row), so that FVS-ACD
top height reads about +4 and total volume reads about -4, consistent with the operational-domain table.
This is a numeric change and is left for Aaron. Expect the v12.10.1 pooled mean absolute bias to rise
somewhat once basal area reads about -10 rather than -7.5 and volume flips sign, which widens the gap to OSM
slightly; that is more honest, not less, and does not change the "OSM modestly ahead on pooled" message.

### B2. The figure data file still contains the OSM index-join artifact the report says is fixed

Location: figures/_data/five_way_scorecard.csv, feeding Figure 1 (scorecard heatmap of bias and modeling
efficiency) and Figure 5 (offsetting bias).

Problem. Every POOLED OSM row in five_way_scorecard.csv has negative Nash-Sutcliffe efficiency (basal area
-0.64, total volume -0.82, and so on) and an RMSE for total volume of about 132 m3/ha. That is exactly the
index-join misalignment the report says (Methods and the pooled section) is resolved, and it is not the OSM
row the report table reports (RMSE 48.5, NSE 0.75). Any figure regenerated from this file will render OSM
with negative modeling efficiency and inflated RMSE, directly contradicting the report text on the same page.

Fix. Replace five_way_scorecard.csv in figures/_data with the corrected single-keyed-merge output before
rendering, and confirm Figures 1 and 5 are built from the corrected file. Numeric, left for Aaron.

### B3. The named canonical baseline file does not exist in the repo

Location: freeze note ("the corrected canonical baseline is cb_v12101_results.csv") and the implied v13 gate
(scripts/v130_score_gate.R compares cb_v130 against cb_v12101).

Problem. There is no cb_v12101_results.csv anywhere in the repo. What exists is cb_1210chk_results.csv (which
the freeze note says the baseline was "adopted from") and cb_v12102_results.csv (the superseded 12.9.2
approximation). A v13.0 gate told to load cb_v12101 will fail, and any reader trying to reproduce the base
scorecard cannot find the file by its stated name.

Fix. Commit cb_1210chk_results.csv as cb_v12101_results.csv (or update every reference, including the freeze
note and the gate script, to the actual filename). Also note that in both cb files every row is flagged
esi_cov TRUE with Quebec n=378, so the "705 ESI-covered, Quebec n=350" denominator cited for the pooled set
is not reconstructable from these files; pin the exact 705-stand subset definition. Numeric/provenance, left
for Aaron.

## SHOULD-FIX

### S1. The GTR still describes OSM as having negative modeling efficiency on every metric

Location: GTR section 10.1, headline finding ("OSM-ACD has the lowest pooled level bias ... but negative
Nash-Sutcliffe modeling efficiency on every metric ... its favorable aggregate bias is population-level
cancellation").

Problem. This is the pre-correction framing that the report explicitly retracts as an index-join artifact.
If Hennigar reads the GTR and the report together, they directly contradict each other on whether OSM has
skill. The GTR was not edited here per instruction.

Fix (for Aaron, in the GTR). Update section 10.1 to the corrected OSM result (positive NSE 0.70 to 0.75,
most accurate on the pooled domain), matching the report and deck.

### S2. Pooled precision claims carry no uncertainty and no multiplicity control

Location: report pooled summary rollup and Honest Limits; deck slides 4 and 16 ("OSM leads pooled 3.2 vs
5.0, modeling efficiency 0.75 vs 0.71, TOST 8 of 9 vs 7 of 9").

Problem. The three-headline gap is stated as a ranking with no confidence interval and no formal paired
difference test, and the mean absolute bias difference of a couple of points sits on top of stand-level RMSE
near 50 m3/ha, so it is not obvious the pooled gap is distinguishable from sampling noise on n about 705. The
nine TOST equivalences per model are counted across nine correlated NSVB metrics with no multiplicity
adjustment noted, so "8 of 9 versus 7 of 9" is a headline built on nine uncorrected tests. A caveat sentence
was added to the report (see edits) framing the pooled gap as close and un-tested; the deck should carry the
same one-line caveat.

Fix (for Aaron, in the deck). Add a half-line on slides 4 and 16 noting the pooled differences are small and
not accompanied by a formal difference test, and that the TOST counts are per-metric. Optional but cheap: a
bootstrap CI on the mean-absolute-bias difference would let the deck say whether 3.2 vs 5.0 is real.

### S3. The Bakuzis "only model that passes" claim is not like-for-like with OSM

Location: report verdict and biological-realism section; deck slides 6 and 16 ("the only model that plateaus
at the realistic maximum and passes the Bakuzis relations"); report Bakuzis table OSM column.

Problem. bakuzis_relations.csv scores only v125, v1270, v1271, and v129x. OSM is not in it. The report's
Bakuzis table nonetheless carries an OSM column with flag entries on Reineke and yield-density, and the
verdict calls FVS-ACD "the only entrant that passes all five." OSM's non-plateau is real but comes from the
separate Seven Islands matched-stand trajectory, not from the identical seeded-gradient Bakuzis battery, so
the OSM flags are inferred from a different test than the FVS-ACD passes. A caveat was added to the report
biological-realism section. The verdict superlative and the deck wording should be softened the same way.

Fix (for Aaron, verdict line and deck slides 6 and 16). Change "the only model that plateaus at the realistic
maximum and passes the Bakuzis relations" to something like "plateaus at the realistic maximum and passes all
five Bakuzis relations; on the matched-stand long-horizon test OSM does not plateau," which is exactly true
and drops the unearned "only ... passes the Bakuzis relations" against a model that was not run through the
matrix.

### S4. Managed out-of-sample wins rest on thin planted and PCT samples; say so next to the number

Location: report "Management class, the headline"; deck slides 11, 12, 16.

Problem. The out-of-sample managed win (1.3 versus OSM 8.3) and the planted win (4.0 versus 16.7) rest on
planted n=51 and PCT n=95, and the leave-one-province-out transfer leans on a handful of managed
installations per province. The deck's own slide 15 concedes this ("the managed calibration still leans on
thin planted and PCT samples"), but the headline slides state the win without the caveat beside it, and the
report states it without the thin-sample flag. A caveat sentence was added to the report. Under leave-one-
province-out the PCT number (4.1) is marginally behind OSM (3.7), which the report states honestly.

Fix (for Aaron, deck slides 12 and 16). Add the thin-sample qualifier next to the managed and planted
out-of-sample numbers, consistent with slide 15, so the win and its caveat travel together.

### S5. The operational-domain "all plots" row is computed from the superseded 12.9.2 approximation

Location: report operational domain table, the "all plots" rows.

Problem. The all-plots row (basal area -10.63, top height +4.02, total volume -3.64) reproduces cb_v12102
(the 12.9.2 approximation) exactly, not the frozen 12.10.1.r, which gives -11.28, +4.21, -4.41. The freeze
note itself says the difference is under one point on every metric and the story is intact, so this is minor,
but it should be recomputed from the corrected baseline for consistency, and the Methods paragraph should stop
calling the reconciliation "pending" (it is done per the freeze note). The in-domain row the deck and report
headline (-9.2, +4.16, -1.63) is blessed by the freeze note as the correct figure to cite and does not need
to change.

Fix (for Aaron). Recompute the all-plots row from cb_v12101 and update the Methods provenance paragraph from
"pending a file reconciliation" to the resolved status. Numeric plus provenance, left for Aaron because it
touches numbers and a status claim.

## NICE-TO-HAVE

- N1. The pooled denominator is stated three ways across the materials: report says n=705, deck slide 3 says
  733 pooled with 705 for the managed breakdown, and the cb files carry 733 with Quebec n=378. Pick one story
  and state it once. This is cosmetic but a sharp reader will notice.
- N2. The by-jurisdiction total-volume table does not tie to five_way_scorecard.csv (OSM Quebec reads +9.8 in
  the report versus +4.45 in the file; v12.9.x New Brunswick -6.9 versus -9.82). It is probably from the
  corrected run, but it should be re-derived from the same single source as the pooled table so all three
  tables trace to one run.
- N3. In the pooled scorecard, FVS-ACD is scored with the management gate off while OSM carries its
  management term always on, so on the managed stands inside the pooled set the comparison mixes gate-off
  FVS-ACD against management-on OSM. The report is upfront that the modifier ships off, and the managed cell
  is scored separately with the modifier on, so this is defensible; one sentence noting it would close the
  loop for a skeptical reader.
- N4. OSM's headline precision numbers (NSE 0.75, RMSE total volume 48.5) are not reproducible from any file
  in figures/_data (the OSM per-stand file osm_h2h_metrics.csv is referenced but not present, and the OSM
  rows that are present are the broken run). Ship the corrected OSM per-stand file with the figure data so the
  OSM column is reproducible.

## Top 5 punch-list, in priority order

1. Re-derive the pooled five-way level-bias table and summary rollup from the corrected merge run, so FVS-ACD
   total volume reads about -4 (under), not +4 (over), and top height reads about +4, not +9. (B1)
2. Replace figures/_data/five_way_scorecard.csv with the corrected data before rendering, so OSM does not
   render with negative modeling efficiency and RMSE 132. (B2)
3. Create cb_v12101_results.csv (commit cb_1210chk under that name) or update every reference and the v13 gate
   to the real filename, and pin the exact 705-stand subset. (B3)
4. Update GTR section 10.1 so OSM is no longer described as having negative modeling efficiency on every
   metric, matching the corrected report. (S1)
5. Soften the "only model that passes the Bakuzis relations" superlative in the verdict and deck to reflect
   that OSM was assessed for plateau on the matched-stand test, not the Bakuzis battery, and add the pooled-
   uncertainty and thin-sample one-liners to the deck. (S3, S2, S4)

## Edits applied to the benchmark report

Only clearly-safe, non-numeric caveat sentences were added. No number, table value, deck, or GTR was changed.

1. Biological-realism section: added a sentence clarifying that OSM is not scored in the seeded-gradient
   Bakuzis battery and that its non-plateau finding comes from the matched-stand Seven Islands test, so the
   Bakuzis passes are a direct FVS-ACD result while OSM enters through the matched-stand trajectory.
2. Honest Limits, pooled-precision paragraph: added a caveat that the pooled differences are small relative to
   stand-level RMSE, are reported without a formal paired difference test or multiplicity adjustment across the
   nine metrics, and should be read as OSM modestly ahead rather than a decisive pooled gap.
3. Management-class section: added a caveat that the out-of-sample managed and planted wins, and the province
   transfer, rest on thin planted and PCT samples, consistent with the v13 data ask.
