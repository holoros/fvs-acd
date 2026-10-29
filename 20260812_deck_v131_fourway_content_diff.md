# Content diff, FVS-ACD_Hennigar_Aug2026.pptx, 12 August 2026

Base file: `FVS-ACD_Hennigar_Aug2026.pptx` (18 slides, backed up unchanged to
`FVS-ACD_Hennigar_Aug2026_PREV_20260812.pptx` before any edit). Updated file: same path, now 20
slides. No prior slide, figure, or number was removed; every change below is additive or a stated
correction with the superseded value kept visible alongside the corrected one where it appears on
a slide the audience will read without narration.

## 1. Corrected composite numbers (Overall Summary and Master Scorecard)

Source: `figures/_data/composite_score_final_corrected.csv`, `scripts/composite_score_final_corrected.R`.

Slide 9, Overall Summary. Replaced the "without Nova Scotia (6 sources) / with Nova Scotia (7
sources)" framing and its coarse source-level bootstrap numbers with the corrected NS / NS-long
framing (both 7 common-cells sources): NS scenario base 86.2 [79.6-92.7], v12.11 76.4 [68.2-83.9],
OSM 72.4 [65.8-78.9]; NS-long scenario base 107.0 [100.3-113.4], v12.11 90.3 [82.6-97.6], OSM 89.3
[82.5-95.7]. Caption rewritten from "7-9 cluster source-level bootstrap, a floor not a ceiling" to
a plot-level cluster bootstrap disclosure (2,000 resamples, measured remeasurement-interval
stand-years weights), pointing to `composite_score_final_corrected.R`. The slide's chart image was
regenerated (`fig27_overall_bias_rmse_summary_corrected.png`) because the old image had the stale
numbers baked in as pixels; the old image is retained in `figures/` under its original name for
provenance.

Slide 10, Master Scorecard. The picture itself (`fig22_determinant_scorecard.png`) was left
unchanged, since the OODA verification confirmed every per-source, per-determinant cell reproduces
exactly; only the figure's own "Overall composite" row and NS-long alternate footnote used the old
source-level bootstrap. Rather than pixel-edit a complex 21-cell heatmap, added a new on-slide
correction line above the figure stating the corrected values and pointing to the Overall Summary
slide, and added a matching caveat to the speaker notes.

Slide 13 (was slide 11), Overall Ranking Reconciled. The visible chart is a different metric
(all-available-data ranking, 8/9 sources, mean rank plus pooled %RMSE) and was not touched, since
it was not part of the corrected common-cells composite. Its speaker notes, however, cited the old
common-cells composite directly (92.4 vs 88.3 NS-overall, 100.8 vs 100.2 NS-long, and the "seven to
nine sources... coarse cluster bootstrap" language); both were rewritten with the corrected numbers
and the plot-level bootstrap disclosure. The on-slide evidence box gained a third line with the
corrected composite for anyone reading the slide without the notes.

## 2. v13.1 added as a real fourth scored model

Source: `figures/_data/composite_score_fourway.csv`, `figures/fig28_fourway_scorecard.png`, job
13434825 (10 array tasks, Cardinal).

New slide 11, "Master Scorecard, Four-Way," inserted immediately after the existing three-way
Master Scorecard. States plainly that v13.1-shipping is essentially tied with frozen base and
trails both real competitors: NS-long composite %RMSE, v13.1 106.3, base 107.0, candidate v12.11
90.3, OSM 89.3. Discloses that SDImax onset 0.55 is not yet paired with the pending LEVER-3
survivor-increment fix, so the score is real but provisional.

Slide 17 (was slide 15), Roadmap. The v13.1 "Shipping decision" bullet is rewritten from an
unscored, optimistic framing ("Ships: ingrowth 2.5x plus r2 refit; SDImax retained, retuned onset
0.55-0.60") to the real scored result with the same numbers as the new scorecard slide, plus the
onset 0.55 / LEVER-3 caveat. The two previously-blocked configurations (3.9x ingrowth stack,
SDImax removed) are carried forward unchanged. Speaker notes gained an update paragraph flagging
that this is a materially less favorable picture than the slide previously implied.

Slide 19 (was slide 17), Verdict and Key Takeaways. Takeaway 5 rewritten from "v13.1 ships
ingrowth 2.5x plus r2, SDImax retained and retuned" to the honest scored comparison (ties base,
trails both real competitors) with the onset caveat.

## 3. Equivalence test finding

Source: `figures/_data/equivalence_tests_fourway_pairs.csv`,
`figures/_data/equivalence_tests_fourway_persource.csv`, `figures/fig29_equivalence_demeaned.png`.

New slide 12, "Equivalence," inserted immediately after the new four-way scorecard slide. States
that all three pairwise comparisons (v13.1 vs OSM, v13.1 vs v12.11, v12.11 vs OSM) are NOT
EQUIVALENT on the pooled slope test, both scenarios, then explains that source-demeaning clears
every model's intercept but the slope failure traces almost entirely to the Nova Scotia source
(slope 0.13-0.20 for all four models, including frozen base, versus sane individual slopes on the
other six sources). Framed explicitly as a question for Hennigar about the NS benchmark data, not
a v13.1-specific weakness, per the task instruction and the underlying analysis note.

## 4. Leftover fixes from the composite-verification phase

memat/medev caveat. The deck never displayed memat/medev numbers (both slides that mention the
pair already correctly disclosed "no score yet"), so there was no incorrect number to remove.
Added a caveat sentence to the speaker notes on slide 10 (Master Scorecard) and slide 13 (Overall
Ranking Reconciled) stating that any memat/medev "base" figures seen elsewhere are drawn from the
v13.1-development baseline built 5 August 2026, not frozen v12.10.1, per the Track D finding.

OSM coverage language softened. Slide 8 (Central Result) and slide 13's speaker notes both
described OSM's two missing sources (Maine FIA subplot, QC MagPlot) in a way that could read as
vendor lock. Both now state the gap is unbuilt inputs, not access: a working, licensed OSM-ACD
v2.26.0 binary exists on this project's own Cardinal account with prior runs on several of this
project's sources, so closing the gap is a tractable follow-up.

## 5. Numbers changed, at a glance

| Location | Old | New | Source |
|---|---|---|---|
| Slide 9 composite, NS | 24.2 / 22.0 (RMSE, 6-source, no bias shown together) | 86.2 / 76.4 / 72.4 (base/v12.11/OSM, 7-source) | composite_score_final_corrected.csv |
| Slide 9 composite, NS-long / with-NS | 84.6 / 82.0 | 107.0 / 90.3 / 89.3 | composite_score_final_corrected.csv |
| Slide 10 Overall row | 104.9 / 92.4 / 88.3 (flagged stale, not overwritten in the image) | 86.2 / 76.4 / 72.4 (NS); 107.0 / 90.3 / 89.3 (NS-long) | composite_score_final_corrected.csv |
| Slide 13 notes composite | 92.4 vs 88.3 (NS); 100.8 vs 100.2 (NS-long) | 76.4 vs 72.4 vs 86.2 (NS); 90.3 vs 89.3 vs 107.0 (NS-long) | composite_score_final_corrected.csv |
| v13.1 status | unscored, framed as a settled shipping decision | scored, NS-long 106.3, ties base, trails v12.11 and OSM | composite_score_fourway.csv |
| Equivalence | not previously in the deck | 3/3 pairs NOT EQUIVALENT, traced to NS source | equivalence_tests_fourway_pairs.csv, _persource.csv |

## 6. Visual pass

Rendered to PDF via LibreOffice in the sandbox (HOME/TMPDIR redirected off the full scratch
volume per standing procedure) and rasterized at 110 dpi. Slides 8, 9, 10, 11, 12, 13, 17, and 19,
every slide touched by this edit, were inspected as images, not just read as XML. Two layout
defects were caught this way and fixed before finalizing: the new four-way scorecard slide's
picture and caption overlapped the slide's bottom edge, and the Roadmap slide's lengthened v13.1
body text overflowed its card into the "ask of the group" card below it. Both were corrected by
resizing the affected shapes and re-rendering; the second render confirmed both fixed.

## 7. Files

`FVS-ACD_Hennigar_Aug2026.pptx` (20 slides, final), `FVS-ACD_Hennigar_Aug2026_PREV_20260812.pptx`
(18 slides, pre-edit backup), `figures/fig27_overall_bias_rmse_summary_corrected.png` (new),
`figures/fig28_fourway_scorecard.png` and `figures/fig29_equivalence_demeaned.png` (pre-existing,
generated on Cardinal, now embedded). No em dashes.
