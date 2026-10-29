# Hennigar deck, red team round 2, content inventory diff, 11 August 2026

Deck: FVS-ACD_Hennigar_Aug2026.pptx, Acadian G&Y Meeting, 18 August 2026. This pass responds to Aaron's
second red team request: more direct OSM comparisons throughout, a focus on v12.11 with a summary of key
updates since 2018, a dedicated ESI-versus-CSI slide, an overall bias and scoring summary, and refined
visuals for legibility. Prior version backed up as FVS-ACD_Hennigar_Aug2026_PREV11_20260811.pptx before any
edits (16 slides). Deck grows from 16 to 18 slides, still inside the 15 to 20 slide target from the first
rebuild. PDF regenerated and every slide rasterized and inspected after the edits, twice, since the first
pass caught three layout defects that a second fix-up round resolved.

## Independent red team pass

A dedicated review (not this build pass) read every slide's text against the source CSVs and flagged twelve
concrete findings, six on missing or vague OSM numbers, four on figure legibility, one confirming the
ESI-vs-CSI gap, and one confirming the overall-summary gap was real and not a duplicate of the master
scorecard. Every fix below traces to one of those findings; none introduces a new number that was not
already verified against a source file (master_scorecard_sources.csv, 20260811_final_scorecard_all_
datasets.md Table 34, 20260702_site_variable_bakeoff.md, FVS-ACD_variant_overview_GTR_v1211.md section 10).

## Final slide order (18 slides)

1. Title. 2. Context. 3. Key Updates Since 2018 (new). 4. Benchmark dataset. 5. The problem. 6. The fix.
7. Validation. 8. Central result vs OSM. 9. Overall Summary, pooled bias and %RMSE (new). 10. Master
scorecard, Overall row. 11. Overall ranking, reconciled. 12. Long-horizon biological realism (Bakuzis).
13. Nova Scotia. 14. Site productivity, now the ESI-vs-CSI comparison slide. 15. v13 roadmap. 16. AI and
reproducibility. 17. Verdict and key takeaways. 18. Questions and contact.

## What was added

Two new slides. Slide 3, Key Updates Since 2018, is a four-row table (2018 to v12.7.1, v12.9.x, v12.10.1,
v12.11) giving what changed and a headline number for each release, sourced from the GTR's version-lineage
section 10 and the v12.6.1/v12.7.1 notes in section 6. This replaces the single-line 2018 mention with the
release-by-release account Aaron asked for. Slide 9, Overall Summary, restores the pooled headline bias and
%RMSE number that a prior rebuild had cut as superseded by the master scorecard; the red team pass confirmed
that was a real gap, since the master scorecard's determinant heatmap never gives one pooled number. New
figure fig27_overall_bias_rmse_summary.png, common cells only, both the without and with Nova Scotia
scenarios, verified against Table 34.

Direct OSM numbers added to slide faces that previously stated a comparison without a number beside it.
Slide 5 (The Problem): every bias line now carries its OSM figure in parentheses (Maine FIA OSM -6.29%,
CTRN OSM -4.81%, Baxter OSM +12.37%). Slide 7 (Validation): the fourth guardrail row now names which three
of four cells beat or tied OSM (Baxter, CTRN, NB MagPlot) and which one is still open (SILC basal area).
Slide 11 (Overall Ranking): added the exact pooled %RMSE numbers under the common-cells rule (OSM 22.0 vs
v12.11 24.2 without Nova Scotia; 82.0 vs 84.6 with), the single most contestable unstated claim the red team
flagged. Slide 12 (Bakuzis): added that OSM passes 3 of 5 relations, previously only v12.11's count of 4 of
5 was stated, an undisclosed asymmetry a developer reading for fairness would catch. Slide 17 (Verdict):
bullets 2 and 4 now carry the adjacent OSM numbers (Baxter, CTRN, NB MagPlot bias; Nova Scotia long-horizon
bias) instead of leaving readers to find them on earlier slides.

Slide 14 (Site Productivity) now carries the dedicated ESI-vs-CSI comparison Aaron asked for:
fig26_esi_vs_csi_bakeoff.png, two panels (out-of-sample modeling efficiency and correlation with measured
FIA site index), all four site variables shown with ESI highlighted, numbers verified against
20260702_site_variable_bakeoff.md Results 1 and 2. This also fixed a distortion defect the red team found:
the prior figure (hennigar_site_productivity.png) was stretched to a 1.54 aspect ratio from a native 2.39,
visibly squashing the panel; the new figure is placed at its true aspect ratio.

## Figures refined for legibility

Three figures were flagged as rendering illegibly small once embedded (effective font size 3.5 to 5.5pt
after the embed shrink, against a 12pt house minimum). fig23_overall_ranking.png (slide 11) was regenerated
at a canvas matched to its achievable embed size (8.9 x 4.71in) with the same 12 to 13pt fonts already
chosen, so displayed text is now the true design size; the slide's picture also grew from 5.83x3.77in to
about 8.6x4.6in after trimming its bullet sidebar. fig22_determinant_scorecard.png (slide 10, master
scorecard) could not be shrunk to its achievable embed size without the sixteen-row, four-facet layout
overlapping (tested and reverted); it ships at its original 9x9.5in design canvas, embedded as large as a
16:9 slide allows (about 5.5x5.5in, up from 4.65x4.87in), which is a real but partial legibility gain,
disclosed rather than overstated. The Bakuzis figure (slide 12) could not be regenerated at all: its
producing script and underlying data are Cardinal-only and not archived in this repository (confirmed
against 20260723_bakuzis_longterm.md); its embed was enlarged as much as the slide geometry allows after
trimming its sidebar to two lines, and the limitation is stated in the slide's speaker notes rather than
silently accepted.

## What was cut or trimmed

Nothing was removed outright this pass. Slide 8 (Central Result) and slide 10 (Master Scorecard) both had
their bullet sidebars either trimmed or removed: Central Result's is unchanged (no sidebar to begin with,
only its own table), and Master Scorecard's Evidence text box was deleted because every claim it made
duplicates a number already printed in every cell of the enlarged figure; the deleted text is preserved
verbatim in the slide's speaker notes rather than lost.

## Two build defects caught and fixed by the required visual pass

The first render surfaced three problems the render-and-inspect step exists to catch. The new Key Updates
table overflowed its allotted height and its last row overlapped the caption text below; fixed by shortening
cell text, reducing table font to 12pt, and moving the caption down. The Validation slide's expanded
guardrail-4 cell wrapped to three lines and overlapped its caption; fixed the same way. The new Overall
Summary slide, built by duplicating the Central Result slide as a template, silently carried over Central
Result's own table and three connector lines that were never explicitly deleted, so the new picture rendered
on top of leftover Baxter and CTRN table rows from the wrong slide; fixed by deleting the four leftover
shapes and repositioning the evidence box, picture, and caption cleanly. A second render confirmed all three
fixes and caught one more: the new Overall Summary caption was positioned 0.24in below the slide's bottom
edge and read as clipped; moved up and re-verified. A separate bug in the verdict-slide edit script (bullet
text matched by startswith(), which failed silently because the bullets are stored as "2  Managed CTRN..."
with a leading number) meant the first save of the Verdict slide did not actually add the OSM numbers to
bullets 2 and 4; caught on the same visual pass and fixed with a substring match.

## Verification performed

Rendered visual pass: LibreOffice to PDF, every one of 18 pages rasterized at 100dpi and inspected directly,
across three render cycles (initial build, post-fixup, and final confirmation) because the first two cycles
each found real defects. Slide order confirmed to match the target arc by reading titles back from the saved
file. Every new number traced to a source file, none invented; the two places where a figure could not be
made fully legible (master scorecard, Bakuzis) are disclosed as partial fixes in the slide notes rather than
presented as solved. No em dashes introduced.

## Provenance

Source deck for this pass: FVS-ACD_Hennigar_Aug2026.pptx (16 slides, from the first rebuild, see
20260811_deck_rebuild_15to20_content_diff.md). Backup: FVS-ACD_Hennigar_Aug2026_PREV11_20260811.pptx.
Red team findings not separately filed as a standalone memo this pass; sourced live from a dedicated review
subagent whose findings are summarized above and fully consumed into this diff. New and modified figures:
figures/fig22_determinant_scorecard.png (regenerated, backed up as fig22_determinant_scorecard_PREV_
20260811b.png), figures/fig23_overall_ranking.png (regenerated, backed up as fig23_overall_ranking_PREV_
20260811b.png), figures/fig26_esi_vs_csi_bakeoff.png (new), figures/fig27_overall_bias_rmse_summary.png
(new). Generating scripts: figures/_data/make_fig22_overall_row.py, make_fig23_reconciled.py (both edited
in place, figure_size parameters only). Numbers sourced from figures/_data/master_scorecard_sources.csv,
20260811_final_scorecard_all_datasets.md, 20260702_site_variable_bakeoff.md, and FVS-ACD_variant_overview_
GTR_v1211.md.
