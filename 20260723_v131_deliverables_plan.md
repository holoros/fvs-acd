# FVS-ACD v13.1 deliverables plan: v12.11 -> v13.1 evolution and change inventory

23 July 2026. Deliverables-planning track of the v13.1 autopilot. This is a PLANNING and scaffolding pass,
not a rebuild. The landing numbers (v13.1 posterior, convergence diagnostics, switches-ON scorecard, updated
ranking and Bakuzis) are not in yet, so this document inventories the finalized v12.11 deliverables as the
floor, specifies exactly what is added, revised, and removed for v13.1, and marks every landing number with a
placeholder token for the next session to fill from the scorecard. No em dashes. No fabricated results.

## 0. Placeholder-token convention

Every number that depends on a v13.1 fit, scorecard, or diagnostic that has not landed is written as a
greppable token so the next session can fill it deterministically:

- `[[TK: <what> | src: <file/job>]]` marks a single missing value or short phrase, naming where it will come
  from (a CSV, a fit job id, a diagnostic export).
- Grep the finalized deliverables for `[[TK:` to get the full fill-in worklist before publishing v13.1.
- Do NOT publish any v13.1 deliverable while any `[[TK:` token remains. A token left in a shipped file is a
  regression.

Landing dependencies (the fits and exports every token traces back to):
- Whole-plot mortality posterior, NS-inclusive: refit job 12554985 (v131mortBNS), outputs
  `~/v13_kickoff/v131r_mortBNS_*`. Fine-grain mortality posterior: subplot job 12547720 (723,830 subplots).
- Hierarchical recruitment posterior: converged (per pass-2 status); ranef export pending.
- v13.1 switches-ON all-sites scorecard vs base and OSM v2.26.1: task #4, not yet run (blocked on posterior).
- Castle-derived Lever 4 hardwood term: local, done, gated OFF (`repos/fvs-acd/lever4_RO_coef_castle.R`,
  `lever4_hw_castle_coeffs.csv`).
- Gate-off byte-identity: job 12554203, GATE_OFF_BYTE_IDENTICAL TRUE (already proven, carries forward as-is).
  NOTE (24 Jul): this is MODEL-LEVEL gate-off only (the equations reproduce 12.10.1 byte for byte, reconfirmed at
  stand level by job 12568080, 0.000e+00). Any "byte-identical BASE reuse" claim, that the frozen `base_*_results.csv`
  rows can be reused directly as the v13.1 BASE arm, is RETIRED: a gated-off v13.1 harness run differs from frozen
  `base_pef_results.csv` by 3.39e+03 in the predicted columns, a harness/provenance drift, not a model-equation
  difference. BASE must be REGENERATED with the v13.1 harness gated OFF (`v131base_*`, `BASE_PREFIX=v131base`). See
  `20260724_v131_base_parity_diagnosis.md`.

## 1. Version framing (carry into all three deliverables)

v13.1 replaces the v12.11 hand-fitted lever block with fitted hierarchical posteriors. The one-sentence framing
to reuse verbatim across report, GTR, and deck: v13.1 supersedes the v12.11 flat ingrowth multiplier
(`ingrowth.mult` about 2.5) and the management-gated self-thinning attenuation (`mort.dens.scale`) with a
converged hierarchical recruitment model and a hierarchical mortality model, the latter fitted with Nova Scotia
CFI folded in and entering as a multiplicative hazard modifier that preserves the Reineke self-thinning ramp and
the density plateau. The gate-off byte-identity contract to the shipped 12.10.1 is preserved.

---

## 2. Content inventory of the finalized v12.11 deliverables (the floor)

Everything below is carried forward into v13.1 unless Section 3 states an explicit, reasoned change. Nothing
is removed silently.

### 2.1 Benchmark report: `FVS-ACD_v12.11_benchmark_report.md` (and `.docx`, `.pdf`)

14 numbered sections plus a content-inventory appendix. Tables 1 to 34 (numbering is non-contiguous in places,
carried as-is), figures fig1 to fig24 (referenced by `figures/fig*.png` path), five dated update blocks in
Appendix A.

Section map (with the tables and figures each owns):

- Table of Contents
- 1. Verdict up front
- 2. Benchmark scope and data coverage. Table 1 (all-sites stand counts by source, region, forest group);
  coverage/footprint map figures.
- 3. Version and configuration: the five gated levers. Table 2 (Lever 4 fitted hardwood height risk
  coefficients). Prose on Lever 1 recruitment (`ingrowth.mult` ~2.5), Lever 2 mortality
  (`mort.dens.scale`, management-gated), Lever 3 survivor diameter increment (stand constraint, QMD floor),
  Lever 4 hardwood height on form and risk, Lever 5 crown ratio (found already active).
- 4. Validation: the guardrail battery. Table 3 (guardrail summary), Table 4 (managed out-of-sample bias/RMSE).
- 5. All-sites comparison: ME, NB, QC vs base and OSM v2.26.1. Table 5. "The honest headline" subsection.
- 6. Forest-group performance: hardwood, mixedwood, softwood. Table 6.
- 7. Legacy five-way scorecard and forest-type detail. 7.1 version/config; 7.2 pooled five-way scorecard
  (Table 7, 8); 7.3 operational domain (Table 9); 7.4 by jurisdiction and forest type (Tables 10 to 14);
  7.5 percent RMSE (Table 15); 7.6 observed-on-predicted regression and equivalence (Table 16); 7.7 weighted
  composite (Tables 17 to 20); 7.8 species composition over time (Table 21); 7.9 management class headline
  (Tables 22, 23).
- 8. Biological realism and long-horizon behavior. Table 24 (Bakuzis legacy five-model). 8.1 long-horizon
  Bakuzis across gradient (Table 30).
- 9. Red-team reframes: corrected claims.
- 10. Watch items, honest limits, and the v13.1 handoff. Table 25 (ingrowth pred vs obs).
- 11. Nova Scotia: an independent-province validation. Tables 26 to 29. 11.1 managed-stand levers generalize;
  11.2 site index basis and transferability caveat; 11.3 long-interval disturbance-contamination artifact
  (corrected); 11.4 OSM v2.26.1 head-to-head; 11.5 methods and open items.
- 12. Master scorecard and overall ranking. Tables 31 to 34. Figure 22 (determinant scorecard heatmap),
  Figure 23 (overall ranking).
- 13. Methods and provenance. (Names the v13.1 refit as job 12470707, gated, "no v13.1 scorecard numbers
  reported here." That handoff sentence is where v13.1 results attach.)
- 14. Appendix A. Content-inventory diff and build note. Five dated update blocks (22 Jul; 23 Jul NS; 23 Jul
  NS long-interval; 23 Jul OSM head-to-head; 23 Jul master scorecard/ranking/Bakuzis; 23 Jul reconciliation).

Figure inventory (by path, the newest three are the scorecard block): the report references `figures/fig*.png`
at many points; the three most recent and load-bearing are `fig22_determinant_scorecard.png`,
`fig23_overall_ranking.png`, and `fig24_bakuzis_longterm.png`. Earlier figures (coverage map, per-source bias,
forest-group, RMSE, regression, composition-over-time) carry forward unchanged unless a v13.1 number on them
moves.

### 2.2 Variant overview GTR: `FVS-ACD_variant_overview_GTR_v1211.md` (and `.docx`, `.pdf`)

Reference-document structure (sections 1 to 12 plus Appendices A to D):

- Authors and Contributors; Table of Contents; Quick Guide to Default Settings.
- 1. Introduction; 2. Geographic Range.
- 3. Control Variables: 3.1 region codes, 3.2 species codes, 3.3 habitat/ecological unit, 3.4 site index,
  3.5 maximum density (SDImax).
- 4. Growth Relationships: 4.1 height-diameter, 4.2 bark ratio, 4.3 crown ratio and crown recession,
  4.4 crown width, 4.5 CCF, 4.6 diameter increment, 4.7 height increment, 4.8 stand basal-area increment.
- 5. Mortality Model. Weiskittel et al. (2012) stand and tree mortality; SDImax-ceiling self-thinning;
  coupled two-segment relative-density mortality (12.7.1); regional and composition-aware SDImax gate (12.9.0).
- 6. Regeneration and Ingrowth. Li et al. (2011) hurdle model; expected-value recruitment (12.6.1);
  density-released ingrowth (12.7.1).
- 7. Volume and Taper; 8. Modifiers; 9. Model Application.
- 10. Version lineage, current operational version (12.10.1), and validation. Subsections 10.1 four-model
  scorecard; 10.2 v12.9.0 SDImax correction; 10.3 v12.10.1 management modifiers (10.3.1 species composition);
  10.4 v12.11 candidate; 10.5 all-sites validation; 10.6 forest-group performance; 10.7 Nova Scotia
  independent-province validation; 10.8 master scorecard and overall ranking; 10.9 long-horizon Bakuzis;
  10.10 red-team review and watch items. (Note: a duplicate "10.7 Planned v13" heading exists in the source,
  a numbering artifact to fix on the v13.1 pass.)
- 11. Literature Cited; 12. Appendices.
- Appendix A. Species Code and Attribute Table (A.1 sp.grp.ingrowth groups).
- Appendix B. Component Parameter Tables: B.1 height-diameter, B.2 height-to-crown-base, B.3 crown width,
  B.4 bark ratio, B.5 tree-level background mortality, B.6 regional stand-mortality, B.7 modifiers,
  B.8 ingrowth, B.9 taper, B.10 Honer volume.
- Appendix C. Keyword and Database Usage (C.1 to C.5).
- Appendix D. Validation Tables.

### 2.3 Deck: `FVS-ACD_Hennigar_Aug2026.pptx`

41 slides (per `20260723_deck_content_inventory_diff.md`). Assertion-evidence layout, CRSF palette (dark forest
green 1A3D28 titles, moss 5E8C61 eyebrows). The three newest slides, inserted at positions 34 to 36:

- Slide 34 MASTER SCORECARD. Figure `fig22_determinant_scorecard.png`; determinant findings (OSM sweeps managed
  and softwood; v12.11 clean wins in NS hardwood, mixedwood, and shorter horizons; base edges the one over-30-yr
  NS cell; terciles unscored).
- Slide 35 OVERALL RANKING (RECONCILED). Figure `fig23_overall_ranking.png`; the "neither is a clean overall
  winner" framing, the triple-counted-NS-artifact disclosure, OSM missing two of eight sources.
- Slide 36 LONG-HORIZON BIOLOGICAL REALISM. Figure `fig24_bakuzis_longterm.png`; five-relation verdict matrix
  (Eichhorn, Reineke, site ordering, yield-density, Sukachev), v12.11 4/5, OSM flags Eichhorn and site ordering.
- Slide 13 CENTRAL RESULT (qualified headline: "On the managed and mature sources it targets, v12.11 halves
  bias and beats OSM v2.26.1").
- A Roadmap slide that currently carries the v13.1 direction (hierarchical mortality and ingrowth refit in
  flight) and the "no v12.12" recommendation.

---

## 3. v12.11 -> v13.1 change plan, per deliverable

Guiding rule (CLAUDE.md iterative-deliverable discipline): start from the finalized v12.11 file as the floor,
carry every section, table, figure, and analysis forward, add v13.1 findings on top, and record any deliberate
removal explicitly. Back up each finalized file as `_PREV_YYYYMMDD` before the first v13.1 edit. Produce a
content-inventory diff at the end of the v13.1 build and check it against this plan.

### 3.1 Cross-cutting substantive changes (apply consistently in all three)

1. Levers 1 and 2 are superseded by fitted posteriors. Recruitment: the flat `ingrowth.mult` about 2.5 is
   replaced by the converged hierarchical recruitment model. Mortality: the management-gated `mort.dens.scale`
   attenuation is replaced by the hierarchical mortality model entering as a MULTIPLICATIVE hazard modifier that
   preserves the Reineke ramp and the plateau. This is an ADD (new methods) plus a REVISE (Section 3 lever
   narrative in the report, GTR sections 5 and 6) with the v12.11 lever description retained as version-lineage
   history, not deleted.
2. Nova Scotia moves from independent benchmark to partly in-sample for the whole-plot mortality component.
   This is the single most important disclosure of the cycle and it touches every place NS is currently called
   an "independent-province validation." NS CFI is now folded into the whole-plot mortality fit (managed
   emphasis, native weight, 3,922 NS stands, whole-plot grain, fitset 212,768 rows). NS therefore can no longer
   be described as a fully independent validation of the mortality component; it remains independent for the
   components not refit on it. This must be stated, not smoothed. See Section 3.5 for the exact reframe.
3. Subplot-grain mortality posterior added as the fine-grain complement (723,830 CONUS-FIA subplots, job
   12547720; `(1|plot)` absorbs within-plot correlation). Whole-plot posterior (NS-inclusive) is the coarse-grain
   complement. Report both grains; state the CONUS-FIA-only scope of the subplot fit (NS has no subplots).
4. Castle red oak finding materially reverses the modeled RO height penalty. See Section 3.2 item C.
5. Two gated fixes staged (default OFF): sub-2.5 cm height-imputation gap, and crown-ratio recession
   recalibration. Both preserve gate-off byte-identity only because they are gated; the height-gap fix breaks
   byte-identity if ungated, so it MUST stay gated. Report as staged/gated, not as shipped defaults.
6. Gate-off byte-identity to shipped 12.10.1 is preserved (job 12554203, TRUE). Carry the contract statement
   forward verbatim; update the job id.

### 3.2 Benchmark report: added / revised / removed

ADDED (new content on top of the v12.11 floor):

- New Section 3 subsections (or a new methods block) for the fitted hierarchical recruitment and hierarchical
  mortality, replacing the Lever 1 and Lever 2 hand-fit narrative as the operative description while retaining
  the v12.11 lever text as lineage. Draft prose ready in Section 4 below.
- New results: the v13.1 switches-ON all-sites scorecard vs base and OSM v2.26.1. Numbers all `[[TK:]]`.
  `[[TK: v13.1 all-sites TOTVOL %RMSE and bias by source | src: task #4 scorecard CSV]]`.
- New subsection on the two mortality grains (whole-plot NS-inclusive vs subplot CONUS-FIA), with convergence
  diagnostics. `[[TK: whole-plot Rhat/ESS, divergences | src: 12554985 export]]`,
  `[[TK: subplot Rhat/ESS | src: 12547720 export]]`.
- New Castle red oak finding subsection (see item C). Local, no Cardinal dependency; can be drafted now.
- New watch-item entries in Section 10 for the two gated fixes (height-gap, crown-ratio recal) with their
  caveats and default-OFF status.
- Convergence and posterior-predictive figures for the two fits: `[[TK: fig numbers and paths | src: v13.1
  diagnostic figure build]]`.

REVISED (existing content updated in place, prior kept as lineage where it is a version story):

- Section 3 lever table and narrative: Levers 1 and 2 reframed as superseded-by-fit; Lever 4 hardwood
  coefficients updated for the Castle re-anchor (Table 2). Lever 3 and Lever 5 carry forward.
- Section 4 guardrail battery (Table 3, Table 4): rerun for v13.1. `[[TK: v13.1 guardrail bias/RMSE, all rows |
  src: v13.1 guardrail run]]`. Gate-off no-regression row: byte-identity holds (job 12554203).
- Section 5 all-sites (Table 5) and Section 6 forest-group (Table 6): reissued for v13.1, now that NS is in the
  whole-plot fit; state which cells are affected by NS-in-fit. `[[TK: v13.1 all-sites and forest-group
  scorecard | src: task #4]]`.
- Section 8 long-horizon Bakuzis (Table 30) and Table 24: rescored for v13.1 (does the multiplicative hazard
  still pass 5/5, and does the plateau hold). `[[TK: v13.1 Bakuzis five-relation verdict and plateau BA |
  src: v13.1 long-bakuzis run]]`.
- Section 11 Nova Scotia: retitle and reframe from "an independent-province validation" to reflect NS now
  folded into the whole-plot mortality fit (see 3.5). Tables 26 to 29 reissued with in-sample/out-of-sample
  status labeled. This is a REVISE, not a removal; all four tables and all five subsections are carried forward.
- Section 12 master scorecard and overall ranking (Tables 31 to 34, Figures 22 and 23): the reconciliation in
  `20260723_master_scorecard_and_ranking.md` already fixed the triple-counted-NS artifact and is the
  authoritative basis. For v13.1, the ranking is recomputed with the v13.1 posterior AND with NS's changed
  status (NS partly in-sample changes what "independent per-source" means for the mortality component). Retain
  the six-scenario, two-inclusion-rule, two-NS-treatment structure; add a v13.1 column or a v13.1 companion
  table. `[[TK: v13.1 mean rank, sources won, pooled %RMSE, pooled bias under each scenario | src: rebuilt
  build_reconciled_ranking.py with v13.1 scores]]`. Do NOT describe v13.1 as the overall winner without the
  same qualifications the v12.11 memo requires.
- Section 13 methods: update the candidate model file to `AcadianGY_13.1.r`, the config to the v13.1 switch
  set (with the three gated hooks default OFF), the fit job ids (12554985 whole-plot NS-inclusive, 12547720
  subplot, plus the recruitment job), and replace the "no v13.1 scorecard numbers reported here" sentence with
  the v13.1 results now in-document.
- Appendix A: add a dated v13.1 update block and a content-inventory diff against the finalized v12.11 report.

REMOVED: nothing. If any v12.11 section, table, or figure is dropped, it must be a stated decision in the
Appendix A diff with a reason. Flag now: none is planned. The only candidate for retitling (not removal) is
Section 11's "independent-province" label.

Item C, Castle red oak (drafted now, no landing number needed):
The real Castle data (`VOLUME_TREES_CLEAN.csv`, RO n = 618, 100% complete height/form/risk) show high-risk red
oak are NOT shorter at a given diameter; they are marginally taller (risk high +3.9%, p = 0.017, form-adjusted).
R3/R4 risk in *Quercus rubra* L. is stem defect on large dominant stems, not height suppression. The Castle
`spp.coeff.risk` for *Q. rubra* is +0.1764, implied `dht.hw.mod` about 1.039 (no penalty, the clamp does not
bind). This contradicts every prior RO estimate: the placeholder 0.0220, the FIA-proxy 0.0759, and the actual
in-model value which is -0.1520 (FIA GRM, RO n = 1, never field-fit; the earlier "0.0220 placeholder" was in
fact the *Betula alleghaniensis* Britton value, a bookkeeping mixup now corrected). Table 2 and the Lever 4
narrative are revised accordingly. Caveat carried: Castle is merchantable-only (dbh >= 25 cm), so the term is
not anchored below about 25 cm. The Castle-derived hardwood term (re-anchored, single-source per-species) is
staged gated OFF (`repos/fvs-acd/lever4_RO_coef_castle.R`, `lever4_hw_castle_coeffs.csv`); land-vs-hold and
primary-vs-re-anchor is an integration decision for the next session.

### 3.3 Variant overview GTR: added / revised / removed

ADDED:

- Section 5 (Mortality Model): a new subsection documenting the v13.1 hierarchical mortality model, its grouping
  structure, the multiplicative-hazard form, the NS CFI inclusion, and the two grains (whole-plot vs subplot).
  Draft in Section 4 below.
- Section 6 (Regeneration and Ingrowth): a new subsection documenting the v13.1 hierarchical recruitment model,
  replacing the flat expected-value calibration multiplier as the operative default while retaining the
  12.6.1/12.7.1 lineage.
- Section 10: a new subsection 10.11 (or renumber) "v13.1: fitted hierarchical mortality and recruitment,
  Nova Scotia folded in" mirroring the report's headline results. `[[TK: v13.1 headline scorecard | src: task #4]]`.
- Appendix B: new or revised parameter tables. B.5, B.6 (mortality) gain the hierarchical mortality posterior
  summaries; B.8 (ingrowth) gains the hierarchical recruitment posterior. `[[TK: posterior means and group SDs
  for mortality and recruitment ranefs | src: 12554985, 12547720, recruitment fit exports]]`. B.5 hardwood
  height risk coefficients (cross-referenced from report Table 2) updated for the Castle re-anchor.
- Appendix D validation tables: add v13.1 rows alongside v12.11.

REVISED:

- Section 3.5 (maximum density / SDImax): note that the v13.1 mortality hazard is multiplicative and preserves
  the SDImax-anchored Reineke ramp and plateau (no change to the SDImax machinery, but the hazard now scales it).
- Section 4.3 (crown ratio and crown recession): add the staged, gated crown-ratio recession recalibration as a
  candidate (default OFF, pending Acadian PSP cross-check; FIA ME/NH/VT basis; CR-definition caveat).
- Section 10.7 Nova Scotia: reframe to note NS is now in the whole-plot mortality fit (parallels report 3.5).
- Fix the duplicate "10.7 Planned v13" heading (numbering artifact) as part of the v13.1 pass.
- Quick Guide to Default Settings: update to the v13.1 default switch set (three gated hooks OFF, hierarchical
  fits ON, gate-off preserved).

REMOVED: nothing planned. The duplicate-heading fix is a correction, not a content removal.

### 3.4 Deck: added / revised / removed (see also Section 5 on the three-slide block)

ADDED:

- One to three v13.1 result slides in the results arc: a v13.1 vs base vs OSM scorecard slide, and a "what
  changed from v12.11: hand levers to fitted hierarchy" method slide. `[[TK: v13.1 headline numbers | src:
  task #4]]`.
- A Castle red oak finding callout (high-risk RO not shorter), either its own slide or an addition to the
  hardwood/Lever 4 slide.

REVISED:

- Slides 34 (master scorecard), 35 (overall ranking), 36 (Bakuzis): v13.1 EXTENDS these, it does not supersede
  the framing. Refresh the numbers and add a v13.1 column/series; keep the honest framing (neither a clean
  overall winner; triple-counted-NS artifact disclosed; OSM missing two sources; NS now partly in-sample must
  be added to slide 34/35 framing). `[[TK: v13.1 determinant, ranking, and Bakuzis values | src: rebuilt CSVs]]`.
- Roadmap slide: move v13.1 from "in flight" to "landed" once results are in; restate the no-v12.12 decision.
- Central Result slide 13: recheck the qualified headline against the v13.1 scorecard so it does not clash.

REMOVED: nothing. All 41 slides carry forward.

### 3.5 The Nova Scotia reframe (exact language, ready to drop in)

Prior v12.11 framing: "Nova Scotia: an independent-province validation." v13.1 requires this reworded wherever it
appears (report Section 11 title and intro, GTR 10.7, deck slides 34 and 35 framing, master-scorecard memo).
Ready-to-drop sentence, house style, no em dashes:

"In v12.11 Nova Scotia served as a fully independent province-scale validation, contributing no data to the
fit. In v13.1 the Nova Scotia CFI record is folded into the whole-plot mortality fit under a managed emphasis
and its native per-stand weight, so Nova Scotia is now partly in-sample for the mortality component and can no
longer be read as a fully independent test of that component. It remains independent for every component not
refit on it (the volume and taper system, the height-diameter and increment relationships, the recruitment
grain that draws only on CONUS FIA), and the subplot-grain mortality posterior remains CONUS-FIA only, since
Nova Scotia has no subplots. Where a Nova Scotia benchmark result is reported for v13.1, its in-sample or
out-of-sample status for the component in question is labeled rather than left implicit."

This also means the master-scorecard ranking (report Section 12, GTR 10.8) must relabel NS's role for v13.1: the
reconciliation memo's per-source ranking counted NS once as an independent source; for v13.1 the mortality-driven
portion of NS's score is no longer independent, so the ranking gains a footnote or a companion "NS out-of-fit
holdout" sensitivity. `[[TK: v13.1 ranking with NS in-fit disclosed, and an NS-holdout sensitivity | src:
rebuilt build_reconciled_ranking.py]]`.

---

## 4. Draft Methods prose (v13.1, ready to drop in, no landing numbers required)

House style applied: species names italic with authority at first use, SI units with true superscripts, prose
not bullets, no em dashes. Bracketed tokens mark the few spots that need a landed value.

### 4.1 Hierarchical mortality (report Section 3 / GTR Section 5)

Version 13.1 replaces the v12.11 management-gated attenuation of the self-thinning removal fraction
(`ops$mort.dens.scale`) with a fitted hierarchical mortality model. Where v12.11 damped a fixed self-thinning
curve by a hand-fitted logistic in relative density that was switched on only for managed sources, v13.1
estimates mortality directly as a Bayesian hierarchical hazard and lets that posterior scale the existing
density-frontier self-thinning rather than replace it. The mortality contribution enters as a multiplicative
hazard modifier: the frozen Reineke self-thinning ramp and the SDImax-anchored density plateau are retained
intact, and the fitted hazard multiplies the per-period removal, so the biological self-thinning behavior that
the Bakuzis battery certified in v12.11 is preserved by construction while the level and the source-to-source
structure of mortality are now data-driven rather than gated. Absolute replacement of the self-thinning curve
was considered and rejected in favor of the multiplicative form for exactly this reason.

The model is fitted at two grains that complement rather than duplicate each other. The whole-plot fit uses
consecutive remeasurement pairs at stand grain and, for the first time, folds in the Nova Scotia CFI record
(Section 4.3), yielding the coarse-grain posterior used for stand-level projection. The subplot fit uses
[[TK: n subplots, confirm 723,830 | src: 12547720]] CONUS FIA subplots with a plot-level random effect that
absorbs within-plot correlation, yielding a fine-grain posterior whose within-plot term is why mortality
samples cleanly at subplot grain. The grouping structure is a nested random-effects hierarchy on region,
ecoregion within region, forest type, and plot. Both fits converged with [[TK: Rhat and bulk-ESS summary,
whole-plot and subplot | src: 12554985 and 12547720 diagnostic exports]] and no divergent-transition or
boundary-funnel pathology after the region-within-region re-nesting and the tightened group-scale prior
(region-by-ecoregion standard-deviation prior moved from a gamma with mode 0.25 to a gamma with mode 0.5,
non-centered parameterization, adapt_delta 0.99, maximum tree depth 15). The posterior enters the model file
gated so that with the v13.1 switches off the projection reproduces the shipped 12.10.1 baseline byte for byte,
a contract independently verified (maximum absolute difference in diameter, height, and expansion factor of
0.000e+00 over a 20-year projection of seeded young and mature stands).

### 4.2 Hierarchical recruitment (report Section 3 / GTR Section 6)

Version 13.1 replaces the v12.11 flat basal-area-anchored ingrowth multiplier (`ops$ingrowth.mult`, about 2.5x)
with a converged hierarchical recruitment model. The v12.11 multiplier corrected a pooled recruitment deficit
with a single constant and relied on a separate always-on density-release logistic to keep it from over-seeding
closed stands; v13.1 estimates recruitment hierarchically so that the deficit correction, the density
dependence, and the between-region and between-forest-type structure are all carried by the fitted posterior
rather than by a constant plus a guard. Recruitment retains its hurdle structure, an occurrence probability and
a conditional count, but both stages now draw on the hierarchical estimates. The model converged with
[[TK: recruitment Rhat and ESS summary | src: recruitment fit export]]; its zero-recruitment fraction on the
subplot fitset is [[TK: confirm 0.9048 | src: fitset build note]]. As with mortality, recruitment is gated so
that gate-off reproduces the frozen baseline exactly, and the recruitment grain draws only on CONUS FIA.

### 4.3 Nova Scotia inclusion in the fit (report Section 3 / Section 11; GTR Section 5)

The Nova Scotia CFI record, used through v12.11 only as an independent province-scale benchmark, is folded into
the v13.1 whole-plot mortality fit. Nova Scotia is stand or whole-plot grain with no FIA subplots, so it enters
the whole-plot fit only; the subplot mortality posterior stays CONUS FIA. The whole-plot fitset grows to
[[TK: confirm 212,768 | src: v131_fitset_NS.rds]] rows, of which [[TK: confirm 3,922 | src: same]] are Nova
Scotia stands (consecutive remeasurement pairs only, roughly [[TK: 924 | src: same]] managed or treated and
[[TK: 2,998 | src: same]] unmanaged, with a Nova-Scotia-only recent-decile holdout). Nova Scotia enters under a
managed emphasis and at its native per-stand binomial weight, roughly one-eighth the per-stand weight of an FIA
record because it carries no FIA population expansion and uses the native expansion factor only; it is not
upweighted unilaterally. Because Nova Scotia carries no ecoregion field, it is represented as a single nested
bucket, and its forest type and SDImax are borrowed through a dominant-species-to-FIA-code crosswalk and a
forest-type mean SDImax. No plot coordinates are contained in the fitset, asserted at read, at build, and on
re-verification. The consequence for validation is stated plainly in Section 11: Nova Scotia is now partly
in-sample for the mortality component and is no longer a fully independent test of it, while remaining
independent for every component not refit on it.

---

## 5. The outstanding v12.11 deck item (three slides) and v13.1's treatment

Status: the three slides the task references (master scorecard, reconciled ranking, long-term Bakuzis) are NOT
outstanding for v12.11. They were built and red-teamed on 23 July 2026 and are in the finalized 41-slide deck
as slides 34, 35, and 36, verified in `20260723_deck_content_inventory_diff.md` (validate.py passed, three
framing fixes applied, no numbers changed). They are complete for v12.11.

For v13.1 the decision is EXTEND, not supersede. The three slides keep their assertion-evidence layout, their
honest framing (neither model a clean overall winner, the triple-counted-NS artifact disclosed and superseded,
OSM missing two of eight sources, the Bakuzis falsification-check-not-accuracy-scorecard caveat), and their
figures. v13.1 refreshes the numbers with the v13.1 posterior and adds a v13.1 series or column, and it adds to
slides 34 and 35 the new disclosure that Nova Scotia is now partly in-sample so its per-source contribution is no
longer fully independent. The Bakuzis slide (36) is re-run to confirm the multiplicative hazard still passes the
five relations and the plateau holds. All three source figures are rebuilt from the updated CSVs:
`fig22_determinant_scorecard.png`, `fig23_overall_ranking.png`, `fig24_bakuzis_longterm.png`. Nothing on the
three slides is removed. `[[TK: v13.1 values for all three slides | src: rebuilt master_scorecard.csv,
overall_ranking_summary.csv, bakuzis_longterm.csv]]`.

---

## 6. Provenance and build order for the v13.1 pass (next session)

1. Land the posteriors: confirm convergence and export ranefs for the whole-plot NS-inclusive fit (12554985)
   and the subplot fit (12547720), and the recruitment fit. Fill the Section 4 `[[TK:]]` diagnostic tokens.
2. Run the v13.1 switches-ON all-sites scorecard vs base and OSM v2.26.1 (task #4). Fill the scorecard,
   forest-group, guardrail, and Bakuzis tokens.
3. Rebuild the master scorecard and reconciled ranking with v13.1 scores and the NS-in-fit disclosure via a
   v13.1 edition of `build_reconciled_ranking.py`; preserve the v12.11 outputs as `_PREV`.
4. For each deliverable: back up the finalized v12.11 file as `_PREV_YYYYMMDD`, open it as the floor, apply the
   adds and revises in Section 3, drop in the Section 4 methods prose and the Section 3.5 NS reframe, fill every
   `[[TK:]]` token, and produce a content-inventory diff against the v12.11 floor listing added / changed /
   removed (removed should be empty; flag any exception).
5. Re-verify gate-off byte-identity after the model-file integration of the three gated hooks (all default OFF),
   and confirm the contract sentence and job id in the report methods.
6. Run a reviewer pass whose explicit job includes checking for lost content against the finalized v12.11
   deliverables, not only auditing the new v13.1 content.

Hard constraints honored in this plan: no v12.11 deliverable is overwritten (all edits go through `_PREV`
backups); this is a new planning artifact; FIA true coordinates and proprietary tree records stay on Cardinal
and appear in no deliverable; Nova Scotia and any JDI-adjacent data are reported as aggregates only.
