# Hennigar deck rebuild, 48 to 16 slides, content inventory diff, 11 August 2026

Deck: FVS-ACD_Hennigar_Aug2026.pptx, Acadian G&Y Meeting, 18 August 2026. This pass rebuilds the deck from
48 slides down to 16, for a broad audience, with Chris Hennigar (OSM-ACD's developer) in the room. Slides
are due to him by the 17th. Full prior version preserved unedited as
FVS-ACD_Hennigar_Aug2026_FULL_TECHNICAL_20260811.pptx before any changes; the ten existing
_PREVn_20260811.pptx backups were left alone. PDF regenerated and every slide rasterized and inspected
after the rebuild; no overflow, no broken fields, no stale images.

## Final slide order (16 slides)

1. Title. 2. Context. 3. Benchmark dataset (modern footprint). 4. The problem (maturity bias). 5. The fix
(five gated levers). 6. Validation. 7. Central result vs OSM. 8. Master scorecard, with an Overall row.
9. Overall ranking, reconciled, with the composite number on the slide face. 10. Long-horizon biological
realism (Bakuzis), key finding only. 11. Nova Scotia, condensed. 12. Site productivity and climate,
condensed to one slide. 13. v13 roadmap, with the v13.1 shipping decision only. 14. AI and reproducibility,
kept as is. 15. Verdict and key takeaways. 16. Questions and contact.

## What was added

Slide 8 (Master Scorecard) now carries a new Overall row, the stand-years-weighted composite score,
computed under the common-cells restriction (the seven sources where base, v12.11, and OSM all have a
score), with a 95% source-cluster bootstrap interval and a caption disclosing the coarseness of a 7-cluster
resample. The row is filled neutral gray rather than the green/yellow/red rank scale used on the other three
determinants, because v12.11's and OSM's intervals overlap heavily: an equivalence result, not a ranking
win. Figure: figures/fig22_determinant_scorecard.png, rebuilt this session (backed up as
fig22_determinant_scorecard_PREV_20260811.png). A companion table image, figures/fig25_allsites_scorecard_
overall.png, extends the eleven-dataset coverage matrix with the same Overall row and marks true coverage
gaps (OSM never run on Maine FIA subplot or QC MagPlot; neither model scored on memat/medev) rather than
silently dropping them; it is referenced in the source note but not placed on a slide face, since slide 8
already carries the headline figure.

Slide 9 (Overall Ranking, Reconciled) now states the composite number directly on the slide face: v12.11
92.4 [30.3, 144.6] vs OSM 88.3 [28.0, 141.5] %RMSE under the NS treatment (100.8 vs 100.2 under NS-long),
common cells, 7 sources, with the overlapping-interval caveat stated in the same line. This replaces the
former standalone Weighted Composite Score slide (old slide 36); its content now lives here and in the
scorecard graphics on slide 8, per the standing decision.

Slide 7 (Central Result) gained one line on its existing caption: OSM still leads developing Maine FIA at
either grain, the acknowledged v13.1 target. This merges the second central-result slide (old slide 14)
into the first (old slide 13), so the win and the open gap sit on one slide together.

Slide 11 (Nova Scotia) rewrote its third numbered item into a synthesis of three cut slides: the OSM
head-to-head result (managed essentially tied, long horizon the clearest separation), the site-index basis
confirmation, and the cut-detection bug that was caught and fixed before shipping.

Slide 12 (Site Productivity) gained one line merging the climate slide's content: ESI v8 current and 2030
surfaces, RCP4.5 magnitude, and the rule that climate is validated on observed data only and never
benchmarked on the projected surface.

Slide 13 (Roadmap) rewrote its v13.1 item into the shipping decision only, per the standing instruction:
ships ingrowth 2.5x plus r2 refit, SDImax retained and retuned (onset 0.55 to 0.60); two configurations
blocked on biological realism, the full 3.9x ingrowth stack (a Bakuzis gain-reversal failure) and SDImax
removed (fails on level). The v13.0 height/domain item and the ask of the group are unchanged.

Slide 6 (Validation) gained one bullet folding in the former standalone Engineering Rigor slide and the
Red Team slide's headline: gate off reproduces v12.10.1 bit for bit, max abs diff 0.000e+00, reconfirmed
after every red-team fix.

Slide 3 (Benchmark Dataset) gained one caption line with the eight-source count breakdown (PEF 2,853, CTRN
1,086, Maine FIA 918, Baxter 91, SILC 73, NB 355, QC 378), condensed from the two cut Data Footprint detail
slides.

## What was cut, and why

Legacy 705-stand, 2018 NB and QC only benchmark (old slides 3, 4, 21, 22, 23: Data Harmonization, Benchmark
Dataset, Legacy Validation Pre-v12.11, Region of Equivalence, Overall Composite). Folded into the single
2018 ECANUSA context line already on the context slide, per the standing decision to lead with the modern,
Maine-inclusive, 11-dataset benchmark and not give the legacy comparison its own slides.

Data Footprint detail and Multi-Source Benchmark (old slides 6, 7). Source-count and bias-by-source detail
condensed into one caption line on the modern benchmark-dataset slide (slide 3) and into that slide's
speaker notes; no longer separate slides.

Decomposition (old slide 9). Three-error-to-three-lever mapping folded into the fix slide's speaker notes,
not the face; the five-lever list on slide 5 already states the same levers.

Engineering Rigor (old slide 11) and Red Team (old slide 19). Cut as standalone slides per the standing
decision; both folded into one bullet plus notes on the validation slide (slide 6).

All-Sites Scorecard, Forest-Group Performance x2, Overall Across All Datasets (old slides 15, 16, 17, 18).
Superseded by the master scorecard's determinant heatmap (slide 8, by managed status, forest group, and
projection length) and by the reconciled ranking and composite numbers (slide 9); repeating the same
determinant cross-tab as its own slides was redundant at 16-slide length.

Accuracy and Precision (old slide 20). A methods aside (percent bias vs %RMSE) that does not carry new
results; dropped for space, no numbers lost since %RMSE is the metric used throughout the rest of the deck.

Biological Realism self-thinning (old slide 24) and Self-Thinning Timing (old slide 25). Folded into the
Bakuzis slide's speaker notes (slide 10); the Bakuzis slide's own face is condensed to its two headline
relations (Eichhorn, site ordering) per the standing decision to keep only the key finding.

Chapter-11 lever detail, Modifier Closes Managed Gap, Managed and Planted Gains Hold Out of Sample (old
slides 27, 28, 29). Folded into the fix slide's notes (Chapter-11 mechanism) and already represented on the
face by the central-result and validation slides' out-of-sample numbers; kept as notes rather than slides
since the headline numbers already appear elsewhere.

Nova Scotia detail slides 2 to 4 (old slides 31, 32, 33: site index basis, cut-detection bug, OSM head to
head). Synthesized into a single third item on the Nova Scotia slide (slide 11); full text retained in that
slide's speaker notes.

Weighted Composite Score (old slide 36). Per the standing decision, this slide is replaced: its content now
lives on the slide face of the Overall Ranking slide (slide 9) and in the new Overall row on the master
scorecard (slide 8).

Integrating Climate (old slide 38). Folded into the site-productivity slide (slide 12) as one caption line
and into that slide's notes in full.

V13.1 Where the Bias Lives, The Bias Budget, Demography, Self Correction, Bakuzis Assessment, and Benchmark
Integrity (old slides 41 through 46). Per the standing decision, all six v13.1 in-progress development
slides are consolidated into the single shipping-decision line on the roadmap slide (slide 13). The
Benchmark Integrity slide's headline (no published number changes, ordering durable) is retained in the
verdict slide's speaker notes (slide 15) rather than dropped outright.

## What was kept unchanged

Title (slide 1), Context (slide 2), The Fix (slide 5, face unchanged, only notes gained detail),
Reproducibility and AI (slide 14, kept as is per the standing instruction), Verdict and Key Takeaways
(slide 15, face unchanged), and Questions and Contact (slide 16) all carry forward with no face edits
beyond the notes additions logged above.

## Verification performed

Rendered visual pass: LibreOffice to PDF (FVS-ACD_Hennigar_Aug2026.pdf regenerated, 16 pages), every page
rasterized at 100 dpi and inspected directly, image by image. No text overflow, no broken PowerPoint
fields, no stale or mismatched figures; the master-scorecard picture confirmed as the rebuilt fig22 with
the Overall row visible and legible. Slide order confirmed to match the target arc exactly by reading
titles back from the saved file. No em dashes introduced.

## Provenance

Source deck: FVS-ACD_Hennigar_Aug2026.pptx (48 slides, as of this morning's composite-score pass, see
20260811_ooda_stress_test_report.md). Full technical backup: FVS-ACD_Hennigar_Aug2026_FULL_TECHNICAL_
20260811.pptx. New figures: figures/fig22_determinant_scorecard.png (overwritten, backed up as
fig22_determinant_scorecard_PREV_20260811.png) and figures/fig25_allsites_scorecard_overall.png (new),
both documented in 20260811_scorecard_overall_row_column_addition.md. Composite numbers sourced from
figures/_data/composite_score_weighted.csv and 20260811_weighted_composite_score.md; nothing recomputed
in this pass.
