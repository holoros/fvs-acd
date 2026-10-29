# Hennigar deck update, content inventory diff, 11 August 2026 (third pass)

Deck: FVS-ACD_Hennigar_Aug2026.pptx, Acadian G&Y Meeting, 18 August 2026.
Prior version backed up as FVS-ACD_Hennigar_Aug2026_PREV10_20260811.pptx (48 slides minus this
one, i.e. 47, matching the state after the reproducibility and map-scope passes earlier today).
New version: 48 slides. Nothing removed. Slide numbers from 36 onward shift up by one relative to
every earlier note written today; cross-references in those notes to slide numbers 36 and higher
are now off by one and should be read accordingly.

## Added, one slide, inserted at position 36, directly after OVERALL RANKING (RECONCILED)

| # | kicker | title claim |
|---|---|---|
| 36 | WEIGHTED COMPOSITE SCORE | Stand-years weighting favors v12.11 but the intervals overlap |

Built by duplicating slide 35's shape structure (white background, Eyebrow/Title/Picture/Evidence
layout) rather than hand-building new shapes, so font, color, and spacing match exactly. Embeds
`figures/fig21_weighted_composite_score.png`, the new stand-years-weighted composite %RMSE figure
(weight = n x remeasurement interval), built earlier in this session and then rebuilt a second time
to meet the advanced-viz uncertainty and disclosure gates (named interval type, resampling unit,
resample count, per-source n and interval annotated on the figure itself).

Five body lines, all carrying a number: the weighting formula and Maine's 74% weight share, the
common-cells composite numbers under both Nova Scotia treatments (v12.11 92.4 vs OSM 88.3 %RMSE
under NS; 100.8 vs 100.2 under NS-long), the overlapping-interval finding stated as a finding and
not a win, the coarse bootstrap-unit limitation, and the assumed-interval limitation naming which
four datasets (Maine FIA subplot, memat, medev, PEF) lack a measured remeasurement interval.

Speaker notes state the same content in full sentences, plus the two things to name if Chris asks
where the number is soft: the source-cluster (not plot-level) bootstrap, and the assumed intervals.

## Changed, one slide's speaker notes

**Slide 34 (MASTER SCORECARD).** Appended one disclosure: the projection-length facet in this
slide's own figure (`figures/fig22_determinant_scorecard.png`) shows Nova Scotia buckets only, and
does not state on its face that this is because no Maine, New Brunswick, or Quebec source carries a
long enough consecutive remeasurement span to populate that determinant, not a choice not to look.
Confirms the site-productivity gap is already disclosed correctly in the figure's own subtitle, so
that half needed no fix. Full technical detail in the new file
`figures/_data/master_scorecard_heatmap_KNOWN_GAPS.md`, cross-checked against
`20260811_final_scorecard_all_datasets.md` Table 33 so the two documents do not contradict each
other.

## Removed

Nothing.

## Verification performed

Rendered visual pass: LibreOffice to PDF (regenerated FVS-ACD_Hennigar_Aug2026.pdf, now 48 pages),
slides 34 through 36 rasterized at 110 dpi and inspected directly. New slide 36 renders cleanly in
house style: white background, sage kicker, dark green Cambria title, five body lines in the
established grey-green Calibri, figure legible at slide scale. No em dashes. No house-style
violation found.
