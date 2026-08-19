# Content diff, FVS-ACD_Hennigar_Aug2026.pptx, 15 August 2026 (pass 18 finalization)

Base file: `FVS-ACD_Hennigar_Aug2026.pptx` (20 slides, 12 August vintage), backed up unchanged to
`FVS-ACD_Hennigar_Aug2026_PREV_20260815.pptx` before any edit. Updated file: same path, still 20
slides. The rendered PDF was refreshed alongside it; the prior PDF is
`FVS-ACD_Hennigar_Aug2026_PREV_20260815.pdf`. Nothing was removed; every change is an update to a
corrected number, a staleness fix against passes 13 to 18, or a red-team edit from
`20260815_pretuesday_redteam_REVIEW.md`. No em dashes.

## 1. Corrected Baxter after the survivor-matching fix (pass 17 defect, pass 18 rescore)

Source of truth: `results/p18osm/p18_old_vs_new.csv` (Cardinal `~/magplot/verify/p18osm/`).
ME_FIA_L and SILC_L reproduce their frozen entries exactly (observed t2 bit-identical); Baxter
legitimately moved with the corrected staging. No winner flips anywhere.

| Baxter, n = 91 | Old bias / RMSE | New bias / RMSE | Old BA bias | New BA bias |
|---|---|---|---|---|
| Base v12.10.1 | +9.12 / 48.28 | +13.56 / 28.72 | +5.74 | +7.63 |
| Candidate v12.11 | +6.92 / 48.14 | +11.28 / 28.47 | +4.47 | +6.34 |
| OSM-ACD v2.26.1 | +12.37 / 50.81 | +16.85 / 32.22 | +13.28 | +15.36 |

Propagated to: slide 5 (face ladder, caption note on the stale Baxter panel of Figure 1, notes),
slide 8 (table row, face footnote, notes), slide 19 (bullet 2). Every affected slide carries the
15 Aug data-fix note; Maine FIA and SILC are stated as verified unchanged.

## 2. Refreshed pooled artifacts (composite, fourway, equivalence, Table 34 ranking)

Composite (slide 9 face, slide 10 correction line, slide 13 evidence box): NS scenario
85.9/76.1/72.1 %RMSE (was 86.2/76.4/72.4), bias -20.1/-15.8/-12.7; NS-long 106.8/90.1/89.1 (was
107.0/90.3/89.3), bias -27.6/-21.6/-21.0. Source `results/p18osm/p18_composite_score_final.csv`,
2,000-rep plot-level cluster bootstrap rerun on Cardinal (job 13615789). All equivalence verdicts
unchanged (12 of 12 NOT EQUIVALENT; `p18_equivalence_pairs.csv`). Table 34 ranking rerun locally
(`figures/_data/p18/overall_ranking_p18.csv`): every mean rank and sources-won count unchanged,
pooled %RMSE shifts of at most 0.33 pp; slide 13 now cites OSM 21.6 vs v12.11 23.9 (without NS)
and 81.9 vs 84.4 (with NS).

Three embedded figures replaced with p18 versions generated on Cardinal:
`fig27_overall_bias_rmse_summary_p18.png` (slide 9), `fig28_fourway_scorecard_p18.png` (slide
11), `fig29_equivalence_demeaned_p18.png` (slide 12). The old images survive in `figures/` under
their original names. Note on fig28: the frozen fourway figure mixed observed bases on Baxter
(frozen July observed for base/cand/OSM against corrected observed for v13.1), which manufactured
v13.1's apparent Baxter %RMSE lead; the p18 figure restores a common corrected basis (Baxter now
ranks cand 28.5, base 28.7, v13.1 30.6, OSM 32.2) and this is disclosed in slide 11's notes.

## 3. v13.1 story brought current (passes 9 to 18)

Slides 11, 17, and 19 no longer describe the LEVER-3 pairing as pending. ship18 (onset 0.55 +
LEVER-3b + ingrowth 2.5x + r2 refit) is stated as built and scored on all ten sources (Maine FIA
+4.06 pp at a Baxter cost of 0.004 pp; PEF worsens +1.24 to +2.83), designated the shipping
candidate on 12 August. The 106.3 NS-long composite is explicitly relabeled as the pre-pairing
configuration; ship18's composite rerun is stated as pending, not invented. Aaron's 12 August
disclosed-tradeoff decision is now on the roadmap card and verdict notes: Bakuzis Reineke softwood
slope -1.80, exactly on the acceptance boundary, single seed, mechanism identified; plus the pass
16 small-tree fix's roughly 1.2 pp BA cost at Maine FIA. Stale lines deleted from slide 17 notes:
"running under job 12470707", "has now run six passes" (now seventeen). A status paragraph through
pass 18 with the prioritized open items was added to slide 17 notes.

## 4. Red-team edits (framing, equivalence language, audience)

Slide 19 bullet 2 now carries both load-bearing qualifications (OSM leads common-cells pooled
%RMSE; OSM unscored on two of eight sources), closing the verdict slide's one-sidedness. Slide 1
subtitle and notes carry the same balance. Slide 9 replaces "statistically equivalent" with
"statistically indistinguishable on the composite" and bridges to the failing TOST; slide 12
carries the mirror clause and rewords "a question for Hennigar" to a data-vintage question about
the NS benchmark data. Slide 4's source count is settled (seven pooled ME/NB/QC sources, NS the
eighth). Slide 3 drops its duplicate gate-off line and gains a provenance note on the v12.9.x
"bias 4.9" legacy cell. Slide 16 notes gain the prepared answer on the inverted BA-increment site
gradient (a2 = -0.0487 [-0.0593, -0.0394] on corrected data, positive +0.0072 at or above 12.7 cm,
fix path the plot_ba_incr reparameterization). Slide 18 face and notes add the survivor-matching
fix as the newest review-process example plus the two open integrity items. Script filenames and
job IDs moved off faces into notes. Title footer now reads "Canadian Forest Service, Acadian
Growth & Yield Meeting".

## 5. Known disclosed staleness (deliberate, not silent)

Slide 5's Figure 1 Baxter panel and slide 10's fig22 heatmap pooled cells predate the fix; both
carry on-slide correction notes (regenerating them requires the Cardinal decomp and determinant
pipelines and was judged not load-bearing given the disclosed deltas). Slide 13's fig23 chart
shows pre-fix values (shifts 0.3 pp or less, no rank moves, disclosed on the face); the archived
`make_fig22_23_scorecard_ranking.py` predates the current overall_ranking.csv schema and could not
regenerate it faithfully this session. Slide 17 notes' height-treatment sensitivity numbers for
Baxter predate the fix and now say so.

## 6. Verification

`validate.py --original` passes. Full 20-slide render to PDF via LibreOffice and page-by-page
raster inspection of every edited slide (1, 3, 4, 5, 8, 9, 10, 11, 12, 13, 17, 19): no overflow,
no collisions, figures match on-slide text. markitdown sweep confirms no stale Baxter value
survives on any slide face; remaining pre-fix values exist only in notes passages explicitly
marked as predating the fix.
