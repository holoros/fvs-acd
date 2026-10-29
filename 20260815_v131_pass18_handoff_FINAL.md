# FVS-ACD pass 18: OSM rescore on corrected staging, downstream refresh, red team, and the Tuesday deck finalized, 15 August 2026

Continuation of pass 17 (`20260814_v131_pass17_handoff_FINAL.md`). Model of record `~/AcadianGY_13.1.r`
unmodified; no frozen result file edited in place; all new Cardinal outputs under
`~/magplot/verify/p18osm/`. Run under the autonomous-ooda-manager loop, LARGE budget, three subagent
tracks (Cardinal rescore, downstream composite refresh, adversarial red team) with deck assembly in
the main thread. No em dashes.

## 1. Pass 17 item 2 closed: the three-region OSM rescore on corrected survivor staging

Rebuilt observed inputs and OSM treelists for ME_FIA_L, Baxter, and SILC_L from the corrected
survivor matching, rescored all three regions for base v12.10.1, candidate v12.11, and OSM v2.26.1
on a path-moved copy of the frozen NSVB scoring harness (methodology parity verified by code read).
Result, from `p18osm/p18_old_vs_new.csv`:

| Region | Outcome |
|---|---|
| ME_FIA_L (n = 918) | Reproduces exactly. Observed t2 bit-identical; all published entries stand, including OSM -6.29% |
| SILC_L (n = 73/69) | Reproduces exactly |
| Baxter (n = 91) | Moves. Observed mean TOTVOL 181.11 to 176.08 m³ ha⁻¹. Base +9.12 to +13.56, cand +6.92 to +11.28, OSM +12.37 to +16.85 (bias %); RMSE improves about 19 pp for all three (28.72 / 28.47 / 32.22). BA bias +7.63 / +6.34 / +15.36. No winner flips |

The scope determination held: canonical entries are level-scored against observed t2 stand totals,
which do not pass through the survivor join, so ME_FIA_L and SILC_L were never contaminated at the
scorecard level; Baxter moved because its staged t2 list itself was rebuilt from the raw persistent
tags. The survivor-growth medians confirm the pass 17 diagnosis (`p18_survivor_medians.csv`).

## 2. Downstream artifacts refreshed with corrected Baxter (Cardinal job 13615789)

Composite (3-way and 4-way), equivalence (pooled and demeaned TOST), and figures fig27/28/29
rerun with the p18 Baxter rows; everything else untouched. Nothing flips: all composite orderings
hold, all 12 equivalence verdicts hold, changes are second-decimal (Baxter is 91 stands, weight
1,001 stand-years, in pools of about 10,000). Current headline composite: NS 85.9 / 76.1 / 72.1
%RMSE, NS-long 106.8 / 90.1 / 89.1 (base / v12.11 / OSM). One real finding: the frozen fourway and
equivalence Baxter cells mixed observed bases across models (v13.1 was already on corrected
observed, the other three were not), which manufactured v13.1's apparent Baxter %RMSE lead; on the
common corrected basis Baxter ranks cand 28.5, base 28.7, v13.1 30.6, OSM 32.2. Table 34 ranking
rerun locally (`figures/_data/p18/overall_ranking_p18.csv`): every mean rank and sources-won count
unchanged; pooled %RMSE shifts at most 0.33 pp (OSM common-cells without NS 22.0 to 21.6, with NS
82.0 to 81.9; v12.11 24.2 to 23.9 and 84.6 to 84.4). Local copies in `results/p18osm/`.

## 3. Red team and deck finalization

Adversarial review (`20260815_pretuesday_redteam_REVIEW.md`): verdict go with edits; 18 flagged
entries across 10 slides; 16 of 18 spot-checked numbers traced exactly to named CSVs. All 12 edit
items executed plus the rescore propagation; see `20260815_deck_p18_content_diff.md` for the full
inventory. Deck `FVS-ACD_Hennigar_Aug2026.pptx` (20 slides) and its PDF are final for Tuesday;
backups `_PREV_20260815.pptx/.pdf`. Validated, rendered, and visually inspected page by page.

## 4. Unknowns ledger, deviations, and open items carried forward

Deviations logged this pass: fig23 not regenerated (archived generator predates the current
overall_ranking.csv schema; disclosed on the slide face, shifts 0.3 pp or less); fig15 Baxter
panel and fig22 pooled cells stale with on-slide correction notes (regeneration needs Cardinal
decomp and determinant pipelines, judged not load-bearing); an accidental rerun of
build_reconciled_ranking.py rewrote the frozen overall_ranking outputs in figures/_data, verified
byte-equivalent recomputation of identical inputs before proceeding; fig27 p18 is a faithful
ggplot2 reimplementation (the plotnine original was never saved to Cardinal); p18's ME_FIA OSM
rescore shows tiny predicted-side rerun drift (max per-stand dTOTVOL_p 0.86 m³ ha⁻¹, observed
identical), moot since the frozen file is kept; `p18_survivor_medians.csv` computes the broken
ME_FIA median differently from pass 17's memo figure (-0.273 vs 2.026), the corrected value 0.561
matches exactly, discrepancy noted, not load-bearing.

Open items, priority order (inherits pass 17 and red team):

1. ship18 composite rerun (the one number the deck states as pending).
2. The csi-by-size-class interaction refit for the inverted BA-increment site gradient (pass 16
   item, unblocked on clean data).
3. SILC_L EXPF discrepancy (12.3553 in use vs 24.7105 implied by the Access database
   INV_PLOT_SIZE); scoped as its own check.
4. QC MagPlot rescore under the validated fitted-height treatment; memat/medev baseline
   reconciliation (neither frozen model scored there).
5. Regenerate fig15, fig22, fig23 from corrected data when the Cardinal pipelines are next open,
   retiring the three disclosed on-slide staleness notes.
6. rt_net gnls convergence failure (unresolved sensitivity arm, low priority).
7. Housekeeping: pass 14, 15, 16 handoffs do not exist as files anywhere (searched Cardinal home,
   magplot, verify); only `P14_SMALLTREE_NOTES.md` existed and is now copied to this repo.

## 5. Files this pass

Cardinal `~/magplot/verify/p18osm/`: rescore scripts and results (p18base/p18cand/p18_osm_score
per region), p18_old_vs_new.csv, p18_observed_check.csv, p18_survivor_medians.csv, refreshed
pipelines (p18_composite_final.R, p18_composite_fourway.R, p18_equivalence.R), their CSVs, figure
scripts, and the three p18 PNGs. Local repo: results/p18osm/ (CSVs and PNGs),
figures/fig27/28/29_*_p18.png, figures/_data/p18/ (corrected allsites input, ranking outputs,
generator), P14_SMALLTREE_NOTES.md, 20260815_pretuesday_redteam_REVIEW.md,
20260815_deck_p18_content_diff.md, the finalized deck and PDF with _PREV_20260815 backups, and
this handoff.
