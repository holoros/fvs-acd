# FVS-ACD benchmark stress test, OODA pass, 11 August 2026

**Mode:** Autonomy: autonomous. Verbosity: full (this report). Unknowns: run and log. Stack: R with data.table by default; Python this session because R and Cardinal were both unreachable (see below). [STACK: Python, R/Cardinal unavailable this session]

## OBSERVE

The benchmark compares FVS-ACD (AcadianGY, an open R reimplementation) against OSM-ACD v2.26.1 (Chris Hennigar, Canadian Forest Service) across eleven Acadian growth-and-yield datasets. Aaron asked for three things: a stress test of the finalized benchmark, maps that do not exclude Maine, and an overall score weighted by observation count and remeasurement length. Cardinal HPC was unreachable for the entire session (SSH timeout to cardinal-login04.hpc.osc.edu); no R is installed in the sandbox. Every number below traces to CSVs already staged in the repository or to a Python computation run and saved this session, never to a fresh Cardinal pull.

**Implicit sweep.** Units are metric throughout (m², cm, years). Plots nest in stands in sources; the master scorecard already resamples at source level, not plot level, and this session's new bootstrap follows that same coarse unit rather than introducing an inconsistent finer one. FIA coordinates never left the server side; nothing in this pass touched a coordinate file. Remeasurement interval, the temporal-length variable this pass needed, turned out to be an unknown known: obvious enough that nobody had written it down as a single reference table, and genuinely missing for 5 of 11 datasets when checked directly.

**Input validity sweep (F1, F2, F6, F7).** F1 (jurisdiction mismatch) fired twice, both real. First, the deck's slide 5 map was displaying a superseded PREV export (`fig20_benchmark_footprint_PREVhex_20260723.png`, `fig20b_maine_inset_PREVhex_20260723.png`) instead of the current files; both versions are in fact Maine-inclusive, so this was stale data, not a scope error, but it is a live deck showing the wrong file and was fixed regardless. Second, and the real F1 finding: the project's original 705-stand benchmark (`fig12_data_locator.png`, `fig14_acadian_range.png`, deck slides 21 to 23) reproduces the 2018 ECANUSA comparison and is New Brunswick and Quebec only, 355 plus 350 stands, with zero Maine stands. That is by historical design and is not a defect to fix by fabricating Maine records into it, but three deck slides used it for an equivalence test and a composite ranking without stating the scope, which a reader (Hennigar least of all) could misread as evaluating the same footprint as the modern 5,754-plus-4,504-stand benchmark, of which Maine is 87%. F6 (inside is not covers) fired on the master scorecard's own heatmap: `figures/fig22_determinant_scorecard.png` silently drops every row with n = 0 rather than masking it, so the site-productivity determinant (unscored for every source) and the projection-length determinant restricted to Nova Scotia (no Maine, New Brunswick, or Quebec source carries a long enough consecutive remeasurement span) both disappear from the grid with no visual trace. The figure's own subtitle discloses the first gap; nothing on the figure discloses the second.

**Prior art scan.** The closest prior artifact is `20260723_master_scorecard_and_ranking.md` and its successor `20260811_final_scorecard_all_datasets.md` (finalized earlier today), which already establish the common-cells fairness convention this pass reuses rather than reinvents. `figures/_data/master_scorecard.csv` is the reference data structure for the new composite score; its `projection_length` and `site_productivity_class` rows were read directly rather than assumed, which is what surfaced the F6 finding above.

## ORIENT

**Blind spot pass.**
1. What would embarrass this if a reviewer found it first? A legacy composite result built on zero Maine stands, sitting three slides after a scorecard that states Maine is 87% of the modern benchmark, with no line connecting the two facts for the reader.
2. What standard approach was not used? Inverse-variance weighting, the textbook alternative to stand-years weighting, was not used because no per-source variance is available at this aggregation level; stand-years weighting is defensible and stated as a choice, not the only one.
3. What is the ceiling? A plot-level cluster bootstrap on Cardinal, with a full inverse-variance option once per-source variance exists. This pass's source-level bootstrap (7 to 9 clusters) is a floor, not the ceiling, and is named as such everywhere it appears.
4. What single input, if wrong, invalidates everything downstream? The remeasurement interval assumptions. Four of nine composite rows carry an assumed rather than measured interval (Maine FIA subplot, memat, medev excluded entirely, PEF excluded from the temporal weight). Checked directly against the report, the GTR, and the pass-5/pass-6 handoffs; none contradict the numbers used.
5. Which inputs were built for a different extent than this run targets? The 705-stand legacy set, built for a 2018 NB and QC comparison, is now sitting inside a deck whose surrounding slides describe an 11-dataset, Maine-inclusive benchmark. This is the F1 finding above stated as the hunting question.

**Firewall table.**

| Mode | Applies | Check | Result |
|---|---|---|---|
| F1 jurisdiction mismatch | Yes | Deck map currency; legacy-705 scope vs surrounding slides | FAIL on both, both fixed (image swap; scope disclosure added) |
| F2 absent equals negative | Yes | master_scorecard.csv n = 0 rows | PASS; rows are blank, not coded as a false zero |
| F3 single axis gate | Yes | fig22 heatmap coverage of the four determinants | FAIL on projection_length disclosure, fixed with a documentation note; site_productivity already disclosed |
| F4 self-referential gate | N/A | No new gate anchored to an unverified internal figure this pass | not applicable |
| F5 magnitude absurdity | Yes | Composite %RMSE values (88 to 120) against the known per-source range (14 to 199 in master_scorecard_sources.csv) | PASS; composite sits inside the observed per-source range as it must |
| F6 inside is not covers | Yes | fig22 grid omission vs the underlying CSV's real row count | FAIL, documented in `master_scorecard_heatmap_KNOWN_GAPS.md`, not regenerated (time-boxed) |
| F7 undeclared sentinels | Yes | Interval values used in the weighting | PASS; no sentinel values found, missing intervals are coded as genuinely missing (excluded or flagged), never as zero |
| F8 named-cause fix | Yes, this is a repair pass | Stale deck images | Repair validated on output: post-save hash matches the current source file exactly |
| F9 inherited wrong numbers | Continuous | Every interval and n reused this session | Re-derived from `master_scorecard_sources.csv` and the report tables directly; no number carried from a memo without a source check |

## DECIDE

**Composite score architecture.** Weight = n times remeasurement interval in years (stand-years), the standard way to pool error metrics across studies of unequal length and size. Computed under both Nova Scotia treatments the project already carries in parallel (NS overall and NS-long, per the existing 18-scenario reconciliation), restricted to the 7 sources both FVS-ACD and OSM are scored on for any head-to-head comparison, plus a separate 9-source v12.11-only figure that is not head-to-head. memat and medev are excluded outright; no score exists for either model on either source. Uncertainty: source-level cluster bootstrap, 2,000 resamples, 95% percentile interval, named explicitly as coarser than a plot-level bootstrap because only 7 to 9 clusters exist to resample.

**Gates, registered before computing.** Magnitude: the composite must fall inside the observed per-source %RMSE range (14 to 199); it does (88 to 120). Coverage: every row used carries n from `master_scorecard_sources.csv`, cross-checked, never invented. Adversarial test: a composite score built by silently imputing OSM's two missing rows would pass a magnitude check while manufacturing a result; this was checked for and not done, the two rows stay excluded and the exclusion is stated in the figure caption.

## INTERNAL ADVERSARIAL LOOP (condensed)

Pass 1 to 4 (bias, guardrails, format, fault tolerance) ran during the subagent tracks; no LaTeX, no interactive device, seed set (20260811) and stated, error handling implicit in each script's structured try paths. Pass 5 (prior version check): every prior scorecard, report section, and deck slide was read before editing; nothing was silently dropped, three content-inventory diffs document exactly what changed. Pass 6 (length): this report and the composite write-up together run longer than a single CRSF technical memo because the pass covers three independent findings; each finding is stated once and not repeated across documents. Pass 7 (output plausibility): covered under F5 and the adversarial gate test above.

## REFINED BLUEPRINT

Ship: the finalized composite score (figure, CSV, R and Python scripts, markdown writeup, one new deck slide), the stale-map fix, the legacy-705 scope disclosure, and the heatmap gap documentation. Do not ship: a regenerated fig22 heatmap (masking fix identified but not built, time-boxed), a plot-level bootstrap (needs Cardinal), or measured intervals for the five datasets that lack one (needs either a records search or a new field census, neither done this session).

## Unknowns ledger

- [ASSUMPTION] Maine FIA subplot interval = 20 years, same population as the whole-plot/long set at finer grain. Cheap to verify once Cardinal is reachable.
- [ASSUMPTION] SILC interval = 11.5 years (midpoint of a stated 8 to 15 year range), applied to the full n = 73 though the range was stated for an n = 60 subset.
- [ASSUMPTION] NB and QC MagPlot = 7 years each, the combined legacy mean, no individual-province number exists in the repository.
- [ASSUMPTION] NS overall = 5.1 years, borrowed from NS-long's own under-15-year bucket.
- [UNKNOWN] PEF interval. Not stated anywhere as a number. Excluded from the temporal weight rather than guessed; costs PEF's 2,853 stands full temporal weighting in the composite.
- [UNKNOWN] memat and medev remeasurement interval and score. Neither model has a score on either source; excluded entirely rather than estimated.
- [UNVERIFIED: source] None of the reused report-table intervals were taken without a direct file check this session; see F9 in the firewall table.

## ACT, deliverables produced this session

Output A: this report, plus `20260811_weighted_composite_score.md` (the composite score writeup) and three content-inventory diffs.
Output B: `scripts/composite_score_weighted.py` (executed), `scripts/composite_score_weighted.R` and `scripts/fig21_weighted_composite_score.R` (written for Cardinal, not executed).
Output C: `figures/fig21_weighted_composite_score.png`, rebuilt a second time to meet the advanced-viz uncertainty and disclosure gates (named interval type and resampling unit, per-source n and interval labeled on the figure, GSEA-adjacent and teal/salmon palettes per the two-way and three-way splits on the panel).
Deck: `FVS-ACD_Hennigar_Aug2026.pptx`, now 48 slides. Slide 5's map swapped for the current file. Slides 21 to 23 carry a one-line NB/QC-only scope disclosure. A new slide 36 presents the weighted composite score. Slide 34's notes disclose the projection-length gap. Rendered and visually checked at every step; PDF regenerated.

## Run footer

```
[DATA_STATE]: 11 benchmark datasets, 9 scored for v12.11, 7 to 9 scored for both models depending on NS treatment; composite built from already-frozen per-source %RMSE, no raw score recomputed.
[OUTCOME_VERIFICATION]: composite %RMSE (common cells, both models): NS treatment v12.11 92.4 [30.3, 144.6] vs OSM 88.3 [28.0, 141.5]; NS-long treatment v12.11 100.8 [30.3, 123.9] vs OSM 100.2 [28.0, 124.8]. Intervals overlap heavily in both; no clean winner.
[FIREWALL]: F1 FAIL x2 (fixed), F2 PASS, F3 FAIL (documented, not fixed), F5 PASS, F6 FAIL (documented, not fixed), F7 PASS, F8 PASS (repair validated on output), F9 PASS (continuous re-derivation).
[PLAUSIBILITY_CHECK]: composite range 88 to 120 sits inside the observed per-source range 14 to 199 (master_scorecard_sources.csv); Maine's 74% weight share matches its known 87% share of raw stand count, discounted by CTRN and PEF's short intervals, which is the expected direction.
[UNKNOWNS_LEDGER]: 4 ASSUMPTION-tagged intervals, 2 UNKNOWN (PEF, memat/medev), 0 UNVERIFIED numbers shipped without a direct source check.
[LENGTH_CHECK]: this report, uncapped against a single-document budget because it covers three independent findings; each finding stated once, not repeated.
[IMPACT_UTILITY]: ready for the 18 August meeting; slides due to Hennigar the 17th.
[NEXT_AUTONOMOUS_STEP]: retry Cardinal for the pending v13.1 IMULT sweep, a plot-level bootstrap on the composite score, and a measured interval for Maine FIA subplot, PEF, memat, and medev, when HPC access returns.
```
