# Adding the weighted-composite Overall row/column to the two scorecard figures

11 August 2026. This note documents a narrowly scoped addition: both `figures/fig22_determinant_scorecard.png`
and a new all-sites scorecard figure now carry an "Overall" row built from the stand-years-weighted composite
score finalized earlier today (`20260811_weighted_composite_score.md`, `figures/_data/composite_score_weighted.csv`).
No number was recomputed for this task; the Overall row/column in both figures is read directly from the frozen
composite CSV.

## What changed

**`figures/fig22_determinant_scorecard.png`** (rank-colored heatmap of TOTVOL %RMSE by determinant x region,
base/v12.11/OSM) gained a new top facet, "0. Overall (stand-years-weighted composite)", ahead of the existing
three determinant facets (managed status, forest group, projection length; site-productivity terciles remain
empty and omitted, unchanged from the prior figure). The three existing facets are rebuilt unchanged from
`figures/_data/master_scorecard.csv` using the same rank-coloring logic as the original build script. The new
Overall row shows all three models' composite TOTVOL %RMSE with 95% bootstrap intervals printed in the cell
(e.g., "92.4 [30.3-144.6]" for v12.11) and is deliberately filled a neutral gray rather than the green/best
-yellow/middle-red/worst rank scale used elsewhere in the figure, because the composite is an equivalence result:
v12.11's and OSM's 95% intervals overlap heavily, so no model is significantly better once stand-years
weighting and resampling uncertainty are both on the table. The figure caption states the common-cells
restriction, the bootstrap methodology and its coarseness, the equivalence framing, and the NS-long alternate
numbers. Prior file backed up to `figures/fig22_determinant_scorecard_PREV_20260811.png` before overwriting.
Build script: `figures/_data/make_fig22_overall_row.py`.

**New figure: `figures/fig25_allsites_scorecard_overall.png`** (fig23 and fig24 were already taken by
`fig23_overall_ranking.png` and `fig24_bakuzis_longterm.png`, both unrelated existing figures, so this uses the
next free number). This is a table image, not a heatmap, extending Table 30 of
`20260811_final_scorecard_all_datasets.md` (the eleven-dataset coverage matrix) with a new bottom "Overall" row.
A table was used deliberately rather than a heatmap because the all-sites view mixes real coverage gaps (OSM
missing 2 of 11 sources; the memat/medev pair missing both v12.11 and OSM entirely) with scored cells, and a
rank-colored heatmap would either hide those gaps or falsely imply a rank among cells that were never scored.
Per-source values come from `figures/_data/v1211_allsites_scorecard.csv` (8 sources) and the NS row of
`figures/_data/composite_score_weighted.csv` (Nova Scotia is scored separately from the ME/NB/QC harness).
Coverage gaps are shaded and labeled rather than left blank: gray "no score" cells mark sources a model was
never run on (OSM on Maine FIA subplot and QC MagPlot; v12.11 and OSM on memat/medev); pale-blue "not tabulated"
cells mark memat/medev's base v12.10.1 column, where base and experimental v13.1 levers were scored but no
%RMSE for that pair is tabulated anywhere in this project's scorecard documents, so a placeholder was used
instead of a fabricated number. The bottom Overall row is bold and shaded, showing all three models' composite
%RMSE with bracketed 95% intervals, consistent with fig22's Overall row. Build script:
`figures/_data/make_fig25_allsites_scorecard_overall.py`.

## Source numbers carried into both figures unchanged (common-cells, NS treatment, primary)

| Model | Composite TOTVOL %RMSE | 95% bootstrap interval |
|---|---|---|
| Base (v12.10.1) | 104.9 | [32.5, 168.0] |
| Candidate v12.11 | 92.4 | [30.3, 144.6] |
| OSM-ACD v2.26.1 | 88.3 | [28.0, 141.5] |

NS-long alternate (noted in both captions, not plotted as a second row/column): base 119.9 [32.5, 149.6],
v12.11 100.8 [30.3, 123.9], OSM 100.2 [28.0, 124.8].

Restricted to the seven common-cells sources scored by all three models (Baxter, CFRU CTRN, Maine FIA
whole-plot, PEF, SILC/Seven Islands, NB MagPlot, Nova Scotia); excludes Maine FIA subplot and QC MagPlot (OSM
never run there) and excludes memat/medev entirely (neither v12.11 nor OSM run there). 95% intervals are a
source-level cluster bootstrap (resampling unit = benchmark source, 7 clusters, n = 2,000 resamples, seed
20260811), coarser than a plot-level bootstrap. v12.11's and OSM's intervals overlap heavily in both treatments:
this is an equivalence result, not a ranking win, and both figures render it that way (muted/neutral fill
instead of a rank color, interval printed alongside the point estimate).

## Files

- `figures/fig22_determinant_scorecard.png` (overwritten; backup at `figures/fig22_determinant_scorecard_PREV_20260811.png`)
- `figures/fig25_allsites_scorecard_overall.png` (new)
- `figures/_data/make_fig22_overall_row.py` (new build script)
- `figures/_data/make_fig25_allsites_scorecard_overall.py` (new build script)
- Source data (unchanged, read only): `figures/_data/master_scorecard.csv`, `figures/_data/composite_score_weighted.csv`,
  `figures/_data/v1211_allsites_scorecard.csv`
- Reference: `20260811_weighted_composite_score.md`, `20260811_final_scorecard_all_datasets.md` (Table 30)

## Content-inventory diff

**Added:** Overall facet/row in fig22 (3 model cells + interval labels); new fig25 table (11 dataset rows +
Overall row, 5 columns, coverage-gap shading); two new build scripts; this note.
**Changed:** fig22's title (added ", with overall composite added"), subtitle (added one sentence describing
the Overall row and its non-ranked fill), and caption (new, describing the composite methodology and caveats;
the original figure had no caption).
**Removed:** nothing. All 13 previously scored determinant cells in fig22 and all figure/table content from the
prior fig22 are carried forward unchanged in value and rank coloring.
