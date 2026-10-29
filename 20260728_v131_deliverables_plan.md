# FVS-ACD v13.1 deliverables plan, revision 2: v12.11 -> v13.1 evolution and change inventory

28 July 2026. Second revision of the v13.1 deliverables plan. The prior version of record,
`20260723_v131_deliverables_plan.md` (itself carrying a `_PREV_20260724` backup), is NOT overwritten and remains
on disk as the 23 July plan. This revision opens that file as the floor, carries its complete v12.11 content
inventory forward unchanged, and updates the change plan to absorb six developments that landed or reversed
between 23 and 28 July: the whole-plot mortality timeout and resubmission, three generations of the hierarchical
recruitment submodel, a neutral first candidate scorecard, the gentle and thresholdless density signal, the
Castle red oak reversal, and the Nova Scotia in-sample status. This remains a PLANNING and scaffolding pass, not
a rebuild. No em dashes. No fabricated results. Every number still in flight is a `[[TK:]]` token rather than a
stale placeholder, and several tokens in the 23 July plan that had hardened into apparent facts are demoted back
to tokens here because the fits behind them did not land.

## 0. Placeholder-token convention (unchanged from 23 July, plus one tightening)

Every number that depends on a v13.1 fit, scorecard, or diagnostic that has not landed is written as a greppable
token so the next session can fill it deterministically:

- `[[TK: <what> | src: <file/job>]]` marks a single missing value or short phrase, naming where it will come from
  (a CSV, a fit job id, a diagnostic export).
- Grep the finalized deliverables for `[[TK:` to get the full fill-in worklist before publishing v13.1.
- Do NOT publish any v13.1 deliverable while any `[[TK:` token remains. A token left in a shipped file is a
  regression.

New tightening, 28 July. A token may only be retired by a value that traces to a landed export, not by a value
carried over from an earlier generation of the same fit. The 23 July plan asserted a converged hierarchical
recruitment posterior and a clean whole-plot mortality convergence in draft methods prose; both assertions rested
on fits that have since been superseded or failed. Any prose that would harden a token must name the job id that
produced the number, and if that job id has been superseded the token reopens.

### 0.1 Landing dependencies, current as of 28 July

The whole-plot NS-inclusive mortality posterior is the critical path. Refit job 12554985 (v131mortBNS) TIMED OUT
at its 72 h wall with no usable production output and is retired; it is resubmitted as job 12863545 with six
chains at twelve threads each, adapt_delta 0.92, maximum tree depth 12, and a 48 h wall. Outputs will land at
`~/v13_kickoff/v131r_mortBNS_*`. The fine-grain subplot mortality posterior (job 12547720, 723,830 CONUS FIA
subplots) is LANDED and converged and is the only mortality posterior currently usable. The hierarchical
recruitment posterior is on its third generation: v5 is retired for an expansion-factor assembly defect, v6 is
retired for a response-scale defect, and v7 (job 12865188) is running. The v13.1 switches-ON all-sites scorecard
against base and OSM-ACD v2.26.1 exists only in its subplot-mortality-only form (job 12624990, nine of eleven
sources); the combined recruitment-plus-mortality scorecard is not yet runnable. The Castle-derived Lever 4
hardwood term is local, complete, and gated OFF
(`repos/fvs-acd/lever4_RO_coef_castle.R`, `lever4_hw_castle_coeffs.csv`).

The gate-off byte-identity contract carries forward and has been reproven three times: job 12554203 on the DRAFT
file, job 12568080 on the integrated `~/AcadianGY_13.1.r` (0.000e+00, and the young seed stand contains sub-2.5 cm
stems so the height-gap gate was genuinely exercised), and job 12612571 after the ingrowth hook was changed from
absolute replacement to multiplicative modifier (still 0.000e+00). Job 12612571 is the contract of record for
v13.1 and is the job id to cite in the report methods and the GTR. The retired claim from 23 July stands retired:
"byte-identical BASE reuse" is FALSE, the frozen `base_*_results.csv` rows are provenance-ambiguous, and BASE must
be regenerated with the v13.1 harness gated OFF (`v131base_*`, `BASE_PREFIX=v131base`). The regenerated BASE has
now been validated against the v12.11 references (whole-plot Maine FIA -16.53 against -16.1, subplot -24.68 against
-24.8, OSM -6.29 against -6.3), which is the check the 23 July plan could only promise. See
`20260724_v131_base_parity_diagnosis.md` and `20260725_v131_ooda_synthesis.md`.

## 1. Version framing (revised, carry into all three deliverables)

The 23 July framing sentence assumed both hierarchical components would land as fitted replacements for both hand
levers. That framing survives in outline but needs two honest amendments: the mortality component is real but
gentle, and the recruitment component is the actual bias lever and is still being corrected. The revised
one-sentence framing to reuse verbatim across report, GTR, and deck:

"Version 13.1 supersedes the v12.11 flat ingrowth multiplier (`ingrowth.mult` about 2.5) and the
management-gated self-thinning attenuation (`mort.dens.scale`) with fitted hierarchical recruitment and mortality
submodels, the mortality component fitted with the Nova Scotia CFI record folded in and entering as a
multiplicative hazard modifier that preserves the Reineke self-thinning ramp and the density plateau, and the
recruitment component entering as a multiplicative modifier on the same construction. The gate-off byte-identity
contract to the shipped 12.10.1 is preserved at 0.000e+00."

The second framing sentence, new for this revision and required wherever the v13.1 headline is stated:

"The fitted mortality hazard is directionally consistent with the v12.11 hand gate but far gentler and without a
threshold, and on its own it is close to neutral for stand-level volume; the recruitment component, not the
mortality component, is the lever on the developing-plot volume deficit."

---

## 2. Content inventory of the finalized v12.11 deliverables (the floor)

Carried forward from the 23 July plan verbatim and in full. Everything below is carried into v13.1 unless
Section 3 states an explicit, reasoned change. Nothing is removed silently.

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

## 3. v12.11 -> v13.1 change plan, per deliverable (revised 28 July)

Guiding rule (CLAUDE.md iterative-deliverable discipline): start from the finalized v12.11 file as the floor,
carry every section, table, figure, and analysis forward, add v13.1 findings on top, and record any deliberate
removal explicitly. Back up each finalized file as `_PREV_YYYYMMDD` before the first v13.1 edit. Produce a
content-inventory diff at the end of the v13.1 build and check it against this plan.

### 3.1 Cross-cutting substantive changes (apply consistently in all three)

Item 1, carried and amended. Levers 1 and 2 are superseded by fitted posteriors. Recruitment: the flat
`ingrowth.mult` about 2.5 is replaced by the hierarchical recruitment model. Mortality: the management-gated
`mort.dens.scale` attenuation is replaced by the hierarchical mortality model entering as a MULTIPLICATIVE hazard
modifier that preserves the Reineke ramp and the plateau. This remains an ADD (new methods) plus a REVISE
(Section 3 lever narrative in the report, GTR sections 5 and 6) with the v12.11 lever description retained as
version-lineage history, not deleted. AMENDMENT, 28 July: the recruitment hook was also changed from an ABSOLUTE
replacement of the ingrowth prediction to a MULTIPLICATIVE modifier equal to unity at training-mean covariates,
so both fitted components now enter by the same construction. This is a structural choice that Aaron owes a
ratification on (decision 1 in `20260728_v131_decisions_brief.md`) and it must be documented in the methods of
both the report and the GTR, because it changes what the posterior means at runtime. Gate-off byte-identity was
re-verified after the change at 0.000e+00 (job 12612571).

Item 2, carried and hardened. Nova Scotia moves from independent benchmark to partly in-sample for the whole-plot
mortality component. This is the single most important disclosure of the cycle and it touches every place NS is
currently called an "independent-province validation." NS CFI is folded into the whole-plot mortality fit
(managed emphasis, native weight, 3,922 NS whole-plot stands, whole-plot grain, fitset 212,768 rows, 3,426 in-fit
after the NS-only recent-decile holdout). NS therefore can no longer be described as a fully independent
validation of the mortality component; it remains independent for the components not refit on it. This must be
stated, not smoothed. See Section 3.5 for the exact reframe, Section 5.2 for the deck treatment, and Section 5.3
for the new NS-holdout sensitivity slide.

Item 3, carried and amended. Subplot-grain mortality posterior added as the fine-grain complement (723,830
CONUS-FIA subplots, job 12547720; `(1|plot)` absorbs within-plot correlation). Whole-plot posterior
(NS-inclusive) is the coarse-grain complement. Report both grains; state the CONUS-FIA-only scope of the subplot
fit (NS has no subplots). AMENDMENT: as of 28 July only the subplot grain has landed, so the two-grain
presentation is provisional and the whole-plot half of every two-grain table is a token.

Item 4, carried. Castle red oak finding materially reverses the modeled RO height penalty. See Section 3.2
item C, which is expanded in this revision.

Item 5, carried. Two gated fixes staged (default OFF): sub-2.5 cm height-imputation gap, and crown-ratio
recession recalibration. Both preserve gate-off byte-identity only because they are gated; the height-gap fix
breaks byte-identity if ungated, so it MUST stay gated. Report as staged/gated, not as shipped defaults.

Item 6, carried and updated. Gate-off byte-identity to shipped 12.10.1 is preserved. Carry the contract statement
forward verbatim and update the job id to 12612571, the post-ingrowth-hook-fix verification, which supersedes
12554203 (DRAFT file) and 12568080 (integrated file, pre-hook-fix).

Item 7, NEW. The mortality result is honestly neutral on volume and must be reported that way. The first v13.1
candidate scorecard (job 12624990, subplot mortality ON at population level, recruitment OFF, nine of eleven
sources) moved Maine FIA whole-plot TOTVOL bias from a BASE of -16.53% to a CANDIDATE of -16.49%, a change of
+0.04 percentage points, against an OSM-ACD v2.26.1 reference of -6.29%. Every scored source moved less than
0.4 percentage points from base. The hazard genuinely bites, in the sense that candidate and base are not
identical, but it is too gentle to move stand-level volume. Population-level subplot mortality alone is not the
lever for the developing-plot bias. This is a headline-level finding that changes the v13.1 story from "the
hierarchical fits fix the bias" to "the hierarchical mortality replaces a hand gate with a defensible gentle
effect, and recruitment is where the bias lever is," and it must appear in the report verdict, the GTR version
lineage, and the deck.

Item 8, NEW. The fitted density signal is gentle and thresholdless and this is a scientific finding, not a
footnote. The subplot mortality posterior is directionally consistent with the v12.11 hand gate, in that higher
relative density lowers the hazard, but the fitted hazard falls only about 11% across relative density 0.10 to
0.80, against the v12.11 hand gate's roughly 86% near-step at RD0 0.38. The data want a gentle, continuous
density effect, not a steep hand-tuned attenuation with a threshold. Caveat to carry: the relative-density term is
marginal net of ln QMD and basal area, which covary with it. This finding retires the v12.11 hand gate on
evidence rather than on preference and belongs in report Section 3 and GTR Section 5 with a figure comparing the
two response surfaces. `[[TK: figure number and path for the hand-gate vs fitted-hazard comparison | src: v13.1
diagnostic figure build]]`.

Item 9, NEW. The recruitment submodel's three-generation history is part of the record and is disclosed, not
hidden. Generation v5 carried an expansion-factor assembly defect: `recruit_tph` was bound to stand density TPH2
(median 1466) rather than the per-tree microplot constant 185.243 ha⁻¹, an over-expansion of 18.4x per tree and
19.2x globally (313.7 corrected to 16.339 stems ha⁻¹ yr⁻¹). Because stand TPH scales roughly as QMD⁻², the defect
wrote a mechanical -2 ln QMD term into the response and inflated the fitted `lnqmd_z` to -2.368, of which roughly
40% was mechanical. Generation v6 (job 12649942) corrected the constant, passed its sanity gate, and converged,
but FAILED PEF verification: it predicted a mean ingrowth of 33.60 stems ha⁻¹ yr⁻¹ against a PEF base of 13.39
and an acceptance band of 10 to 20. Its root cause is a response-scale defect rather than an assembly defect: the
response was the microplot count already multiplied by 185.243, so the negative binomial shape absorbed the
inflation (shape 0.0559, variance-to-mean ratio about 1627 at the mean count) and the fit performed ratio
matching rather than mean matching, overpredicting the population marginal mean by +32.2%. Generation v7 (job
12865188, running) models the raw microplot count with log(185.243) folded into the offset. Report this as a data
assembly and response scale correction sequence in the methods, with all three generations named, because the
fitted `lnqmd_z` moved materially across them (-2.368 in v5, -1.245 in the corrected pre-fit preview) and a reader
comparing v13.1 coefficients to any earlier memo will otherwise be unable to reconcile them.

### 3.2 Benchmark report: added / revised / removed

ADDED (new content on top of the v12.11 floor):

- New Section 3 subsections (or a new methods block) for the fitted hierarchical recruitment and hierarchical
  mortality, replacing the Lever 1 and Lever 2 hand-fit narrative as the operative description while retaining
  the v12.11 lever text as lineage. Draft prose is in `20260728_v131_methods_prose.md`.
- New Section 3 subsection on the hand gate versus the fitted hazard: the roughly 86% near-step at RD0 0.38
  against the fitted roughly 11% decline across RD 0.10 to 0.80, with the marginal-net-of-covariates caveat.
- New results: the v13.1 switches-ON all-sites scorecard against base and OSM v2.26.1. The subplot-mortality-only
  arm has landed for nine of eleven sources and can be reported now as an intermediate result; the combined
  recruitment-plus-mortality arm is a token. `[[TK: v13.1 combined-candidate all-sites TOTVOL %RMSE and bias by
  source | src: v131_allsites_scorecard.csv after the combined candidate array]]`,
  `[[TK: subplot-mortality-only candidate rows for mefia_subp and ns_long_unmanaged | src: job 12624990 tasks 4
  and 11]]`.
- New subsection on the two mortality grains (whole-plot NS-inclusive against subplot CONUS-FIA), with convergence
  diagnostics. Subplot diagnostics have landed: mortality maximum Rhat 1.015, recruitment maximum Rhat 1.0161,
  minimum bulk ESS 723, minimum tail ESS 1517, zero divergent transitions, zero maximum-treedepth saturations,
  E-BFMI 0.76 to 0.80, and a variance ladder of plot 0.947, forest type 0.411, region 0.241, region-by-ecoregion
  0.232 with a lower 95% bound of 0.205 so the nested funnel is cured at subplot grain. Whole-plot diagnostics are
  a token: `[[TK: whole-plot Rhat, bulk and tail ESS, divergences, treedepth saturation | src: job 12863545
  export]]`.
- New subsection, NEW in this revision, on the whole-plot fit's first attempt and why it was retired. Job 12554985
  ran to its 72 h wall without usable output. The post-mortem is that it was wall-limited rather than stalled: it
  saturated maximum tree depth 15 on 86 to 100% of draws with ZERO divergent transitions, so adapt_delta 0.99 was
  pure cost and bought nothing. More seriously the posterior was multimodal, with one of four chains sitting about
  27,900 log-units below the other three and cross-chain Rhat running 1.32 to 3.03; 485 usable draws were
  recovered, which is not enough to score against. The resubmission (job 12863545) uses six chains at twelve
  threads, adapt_delta 0.92, and maximum tree depth 12 on a 48 h wall, trading step-size conservatism for
  wall-clock and adding chains to diagnose rather than hide multimodality. This belongs in the report because a
  reader is entitled to know that the coarse-grain posterior required two attempts and why.
- New Castle red oak finding subsection (see item C below). Local, no Cardinal dependency, drafted and ready.
- New watch-item entries in Section 10 for the two gated fixes (height-gap, crown-ratio recalibration) with their
  caveats and default-OFF status, plus a new watch item for the recruitment response-scale correction.
- Convergence and posterior-predictive figures for the fits: `[[TK: fig numbers and paths | src: v13.1 diagnostic
  figure build]]`.

REVISED (existing content updated in place, prior kept as lineage where it is a version story):

- Section 1 verdict up front: rewrite the headline to carry item 7 above. The v13.1 verdict is not "the fits close
  the bias"; it is that mortality is replaced defensibly and neutrally and recruitment is the lever.
  `[[TK: v13.1 verdict numbers | src: combined candidate scorecard]]`.
- Section 3 lever table and narrative: Levers 1 and 2 reframed as superseded-by-fit; Lever 4 hardwood
  coefficients updated for the Castle re-anchor (Table 2). Lever 3 and Lever 5 carry forward.
- Section 4 guardrail battery (Table 3, Table 4): rerun for v13.1. `[[TK: v13.1 guardrail bias and RMSE, all rows
  | src: v13.1 guardrail run]]`. Gate-off no-regression row: byte-identity holds at 0.000e+00 (job 12612571).
- Section 5 all-sites (Table 5) and Section 6 forest-group (Table 6): reissued for v13.1, now that NS is in the
  whole-plot fit; state which cells are affected by NS-in-fit. The subplot-mortality-only intermediate is
  available and reportable: Baxter 9.09 base to 8.71 candidate against OSM 12.37; CTRN -9.78 to -9.46 against
  -4.81; Maine FIA whole-plot -16.53 to -16.49 against -6.29; PEF 1.24 to 1.24 against 0.26; SILC -6.37 to -6.44
  against -18.07; NB MagPlot -11.83 to -11.96 against -8.07; QC MagPlot 1.27 to 1.24; NS remeasurement -38.44 to
  -38.30 against -29.22. `[[TK: v13.1 combined all-sites and forest-group scorecard | src: combined candidate
  array]]`.
- Section 8 long-horizon Bakuzis (Table 30) and Table 24: rescored for v13.1 (does the multiplicative hazard still
  pass the five relations, and does the plateau hold). `[[TK: v13.1 Bakuzis five-relation verdict and plateau BA |
  src: g2_bakuzis_v131 and g3_plateau_v131 runs]]`.
- Section 10 watch items: the two v12.11 watch items are unaggravated by the subplot-mortality-only candidate
  (QC volume +1.24 against a base of +1.27, SILC BA +5.24 against a base of +5.31) and this can be stated now;
  recheck under the combined candidate. Table 25 (ingrowth predicted against observed) is reissued with the
  corrected recruitment. `[[TK: v13.1 ingrowth predicted vs observed, PEF and all sources | src: v7 recruitment
  verification]]`.
- Section 11 Nova Scotia: retitle and reframe from "an independent-province validation" to reflect NS now folded
  into the whole-plot mortality fit (see 3.5). Tables 26 to 29 reissued with in-sample and out-of-sample status
  labeled per component. This is a REVISE, not a removal; all four tables and all five subsections carry forward.
- Section 12 master scorecard and overall ranking (Tables 31 to 34, Figures 22 and 23): the reconciliation in
  `20260723_master_scorecard_and_ranking.md` already fixed the triple-counted-NS artifact and remains the
  authoritative basis. For v13.1 the ranking is recomputed with the v13.1 posterior AND with NS's changed status.
  Retain the six-scenario, two-inclusion-rule, three-NS-treatment structure; add v13.1 as a fourth model and add a
  fourth NS treatment, "NS held out of the mortality fit," as the sensitivity. `[[TK: v13.1 mean rank, sources
  won, pooled %RMSE, pooled bias under each scenario | src: rebuilt build_reconciled_ranking.py with v13.1
  scores]]`. Do NOT describe v13.1 as the overall winner without the same qualifications the v12.11 memo requires.
- Section 13 methods: update the candidate model file to `AcadianGY_13.1.r`, the config to the v13.1 switch set
  (three gated hooks default OFF, two hierarchical hooks ON), the fit job ids (12863545 whole-plot NS-inclusive,
  12547720 subplot, 12865188 recruitment, with 12554985, 12649942 and the v5 recruitment fit named as retired
  generations), the gate-off contract job id 12612571, and replace the "no v13.1 scorecard numbers reported here"
  sentence with the v13.1 results now in-document. Also record that BASE was regenerated with the v13.1 harness
  gated OFF under `BASE_PREFIX=v131base` and that the stale `base_*` rows are retired.
- Appendix A: add a dated v13.1 update block and a content-inventory diff against the finalized v12.11 report.

REMOVED: nothing. If any v12.11 section, table, or figure is dropped, it must be a stated decision in the
Appendix A diff with a reason. Flag now: none is planned. The only candidate for retitling, not removal, is
Section 11's "independent-province" label.

Item C, Castle red oak (drafted, no landing number needed, expanded in this revision):
The real Castle data (`VOLUME_TREES_CLEAN.csv`, red oak n = 618, 100% complete for height, form, risk and
diameter) show that high-risk red oak are NOT shorter at a given diameter; they are marginally taller (risk high
+3.9%, p = 0.017, form-adjusted, confirmed independently in R at +0.0384, p = 0.018). R3 and R4 risk in
*Quercus rubra* L. is stem defect on large dominant stems, not height suppression. The Castle `spp.coeff.risk` for
*Q. rubra* is +0.1764, implying a `dht.hw.mod` of about 1.039, which is no penalty and does not bind the
[0.5, 1.2] clamp. This contradicts every prior red oak estimate: the placeholder 0.0220, the FIA-proxy 0.0759, and
the actual in-model value of -0.1520 (FIA GRM, red oak n = 1, never field-fit). The earlier "0.0220 placeholder"
was in fact the *Betula alleghaniensis* Britton value, a bookkeeping mixup now corrected and disclosed. The
companion Castle coefficients are red maple *Acer rubrum* L. -0.0170 (p = 0.209, n = 355), sugar maple
*Acer saccharum* Marshall -0.0490 (p = 0.005, n = 314), and yellow birch -0.0496 (p = 0.008, n = 199), so sugar
maple and yellow birch retain a height deficit at high risk but a weaker one than the earlier Smith fit. Table 2
and the Lever 4 narrative are revised accordingly. Two caveats carry: Castle is merchantable-only at diameter at
breast height of 25 cm and above (observed range 25.4 to 82.0 cm), so the term is not anchored below about 25 cm;
and paper birch *Betula papyrifera* Marshall is absent from the Castle file, so the reference `base.risk.coeff`
of -0.1380 cannot be re-estimated from Castle, which is exactly why the snippet carries both a primary table
(Castle deficits differenced against the FIA-derived paper birch base, cross-source) and a re-anchor table
(Castle-only, base 0, each species using its own coefficient). The Castle-derived term is staged gated OFF
(`repos/fvs-acd/lever4_RO_coef_castle.R`, `lever4_hw_castle_coeffs.csv`, with the re-anchor table wired active in
`~/AcadianGY_13.1.r` behind `ops$use.dht.hw.mod.castle`). Land-versus-hold and primary-versus-re-anchor is
decision 3 in `20260728_v131_decisions_brief.md`.

### 3.3 Variant overview GTR: added / revised / removed

ADDED:

- Section 5 (Mortality Model): a new subsection documenting the v13.1 hierarchical mortality model, its grouping
  structure, the multiplicative-hazard form, the NS CFI inclusion, and the two grains (whole-plot against
  subplot). Draft prose in `20260728_v131_methods_prose.md`. NEW in this revision: the subsection must also carry
  the gentle-and-thresholdless density result and the honest statement that the fitted hazard is close to neutral
  for stand-level volume, because a GTR that describes the component without its magnitude invites a user to
  expect a bias correction it does not deliver.
- Section 6 (Regeneration and Ingrowth): a new subsection documenting the v13.1 hierarchical recruitment model,
  replacing the flat expected-value calibration multiplier as the operative default while retaining the 12.6.1
  and 12.7.1 lineage. NEW: the subsection carries the offset construction (raw microplot count with
  log(185.243 ha⁻¹) in the offset) explicitly, because the offset is the difference between v6 and v7 and a user
  refitting the component needs it.
- Section 10: a new subsection 10.11 (or renumber) "v13.1: fitted hierarchical mortality and recruitment, Nova
  Scotia folded in" mirroring the report's headline results. `[[TK: v13.1 headline scorecard | src: combined
  candidate array]]`.
- Appendix B: new or revised parameter tables. B.5 and B.6 (mortality) gain the hierarchical mortality posterior
  summaries; B.8 (ingrowth) gains the hierarchical recruitment posterior. Subplot recruitment fixed effects have
  landed and can be tabulated now (intercept -4.557, `lnqmd_z` -1.207, `ba_z` +0.240, `rd_z` -0.046), flagged as
  the subplot-grain generation superseded by v7. `[[TK: v7 recruitment fixed effects and group SDs | src: job
  12865188 export]]`, `[[TK: whole-plot mortality fixed effects and group SDs | src: job 12863545 export]]`.
  B.5 hardwood height risk coefficients (cross-referenced from report Table 2) updated for the Castle re-anchor.
- Appendix D validation tables: add v13.1 rows alongside v12.11.

REVISED:

- Section 3.5 (maximum density and SDImax): note that the v13.1 mortality hazard is multiplicative and preserves
  the SDImax-anchored Reineke ramp and plateau (no change to the SDImax machinery, but the hazard now scales it).
- Section 4.3 (crown ratio and crown recession): add the staged, gated crown-ratio recession recalibration as a
  candidate (default OFF, pending Acadian PSP cross-check; FIA ME, NH and VT basis; crown-ratio definition
  caveat).
- Section 10.7 Nova Scotia: reframe to note NS is now in the whole-plot mortality fit (parallels report 3.5).
- Fix the duplicate "10.7 Planned v13" heading (numbering artifact) as part of the v13.1 pass.
- Quick Guide to Default Settings: update to the v13.1 default switch set (three gated hooks OFF, two
  hierarchical hooks ON, gate-off preserved). NEW: the guide must state that both hierarchical hooks enter
  multiplicatively and equal unity at training-mean covariates, so a user who switches one on without a posterior
  directory gets an identity modifier rather than a silent absolute replacement.

REMOVED: nothing planned. The duplicate-heading fix is a correction, not a content removal.

### 3.4 Deck: added / revised / removed

ADDED:

- One to three v13.1 result slides in the results arc: a v13.1 against base against OSM scorecard slide, and a
  "what changed from v12.11: hand levers to fitted hierarchy" method slide.
  `[[TK: v13.1 headline numbers | src: combined candidate array]]`.
- A Castle red oak finding callout (high-risk red oak not shorter), either its own slide or an addition to the
  hardwood and Lever 4 slide.
- NEW in this revision: an NS-holdout sensitivity slide, specified in Section 5.3 below.

REVISED:

- Slides 34 (master scorecard), 35 (overall ranking), 36 (Bakuzis): v13.1 EXTENDS these, it does not supersede
  the framing. Full specification in Section 5.1 below.
- Roadmap slide: move v13.1 from "in flight" to "landed" once results are in; restate the no-v12.12 decision.
- Central Result slide 13: recheck the qualified headline against the v13.1 scorecard so it does not clash.
- NEW: every Nova Scotia slide in the deck's Nova Scotia arc is relabeled per Section 5.2.

REMOVED: nothing. All 41 slides carry forward, and the deck grows.

### 3.5 The Nova Scotia reframe (exact language, ready to drop in)

Prior v12.11 framing: "Nova Scotia: an independent-province validation." v13.1 requires this reworded wherever it
appears. Ready-to-drop sentence, house style, no em dashes, carried forward from the 23 July plan and extended
with the holdout sentence:

"In v12.11 Nova Scotia served as a fully independent province-scale validation, contributing no data to the fit.
In v13.1 the Nova Scotia CFI record is folded into the whole-plot mortality fit under a managed emphasis and its
native per-stand weight, so Nova Scotia is now partly in-sample for the mortality component and can no longer be
read as a fully independent test of that component. It remains independent for every component not refit on it
(the volume and taper system, the height-diameter and increment relationships, the recruitment grain that draws
only on CONUS FIA), and the subplot-grain mortality posterior remains CONUS-FIA only, since Nova Scotia has no
subplots. A Nova-Scotia-only recent-decile holdout was reserved at fit time, so 3,426 of the 3,922 Nova Scotia
stands are in-fit and the most recent decile is held out; that holdout is the basis of the sensitivity reported
alongside the main Nova Scotia results. Where a Nova Scotia benchmark result is reported for v13.1, its in-sample
or out-of-sample status for the component in question is labeled rather than left implicit."

This also means the master-scorecard ranking (report Section 12, GTR 10.8) must relabel NS's role for v13.1: the
reconciliation memo's per-source ranking counted NS once as an independent source; for v13.1 the mortality-driven
portion of NS's score is no longer independent, so the ranking gains both a footnote and a companion "NS
out-of-fit holdout" sensitivity. `[[TK: v13.1 ranking with NS in-fit disclosed, and the NS-holdout sensitivity |
src: rebuilt build_reconciled_ranking.py]]`.

---

## 4. Methods prose (moved out of this plan)

The 23 July plan carried draft methods prose in its Section 4. That prose is superseded and has been rewritten
and expanded into a standalone file, `20260728_v131_methods_prose.md`, covering the hierarchical mortality and
recruitment submodels and their grouping structure, the Nova Scotia inclusion and what it does and does not
license, the three-generation recruitment history as a data assembly and response scale correction, and the
Castle red oak subsection. Three specific corrections were made against the 23 July draft, and they are the
reason it could not simply be carried forward verbatim:

The 23 July draft stated that both fits "converged with no divergent-transition or boundary-funnel pathology
after the region-within-region re-nesting and the tightened group-scale prior (adapt_delta 0.99, maximum tree
depth 15)." For the subplot grain that statement is true and is retained. For the whole-plot grain it is now false
in every particular: that configuration timed out, was multimodal, and has been replaced by adapt_delta 0.92 and
maximum tree depth 12 across six chains. The new prose states the whole-plot convergence as a token and records
the first attempt honestly.

The 23 July draft stated that recruitment "converged" and cited a Rhat token against a single recruitment fit
export. That fit is generation v5 and is retired for the expansion-factor defect. The new prose narrates three
generations and holds the coefficient values as tokens against job 12865188.

The 23 July draft described the recruitment hook as entering the model without specifying its basis. The new
prose states the multiplicative construction explicitly, matched to mortality.

---

## 5. Deck specifications for v13.1 (Task B, written as build-ready slide specs)

The three slides the earlier task list called outstanding (master scorecard, reconciled ranking, long-term
Bakuzis) are NOT outstanding for v12.11. They were built and red-teamed on 23 July 2026 and are in the finalized
41-slide deck as slides 34, 35, and 36, verified in `20260723_deck_content_inventory_diff.md` (validate.py
passed, three framing fixes applied, no numbers changed). They are complete for v12.11. For v13.1 the decision is
EXTEND, not supersede. Nothing on any of the three is removed. What follows specifies exactly what changes.

### 5.1 Extending slides 34 to 36

Slide 34, MASTER SCORECARD. The slide's figure is `fig22_determinant_scorecard.png`, a rank-colored heatmap of
the four-determinant cross-tab in report Tables 31 to 33, currently three model columns (base, v12.11 candidate,
OSM-ACD v2.26.1) by thirteen populated determinant rows (managed and unmanaged for ME/NB/QC pooled and for NS;
softwood, mixedwood and hardwood for ME/NB/QC pooled and for NS; under 15 yr, 15 to 30 yr and over 30 yr for NS;
plus the two unpopulated rows for ME/NB/QC projection length and for site-index tercile, which stay in the figure
as explicit no-data rows and are NOT dropped). The v13.1 change is a fourth model COLUMN, v13.1, added to the
right of OSM in the same rank-colour scheme, populated for all thirteen rows, with the winner attribution in each
row recomputed across four models rather than three. Row structure, row order, and the two no-data rows are
unchanged. The left evidence column currently carries four determinant findings (OSM leads managed and softwood;
v12.11's specific clean wins in NS hardwood, NS mixedwood and both shorter NS horizons; base edges the single
over-30-year NS cell; terciles unscored) plus the bridge clause to slide 13 about per-source bias and pooled
%RMSE being different lenses. All of those are retained verbatim. Two items are added to that column: a fifth
finding stating where v13.1 changes a winner attribution and where it does not
(`[[TK: v13.1 per-cell values and revised winner attributions, 13 rows | src: rebuilt master_scorecard.csv]]`),
and a one-line in-sample flag reading that the four Nova Scotia rows in this table are partly in-sample for
v13.1's mortality component and are therefore not a fully independent test of v13.1 in the way they are of
v12.11 and OSM. The assertion title is re-tested against the four-model table and rewritten only if v13.1 changes
which model sweeps the managed and softwood cells; if it does not, the existing title stands.

Slide 35, OVERALL RANKING (RECONCILED). The slide's figure is `fig23_overall_ranking.png`, which currently plots
the all-available-data inclusion rule on two metrics (equal-per-source mean rank and pooled TOTVOL %RMSE) for
three models, in two panels, without Nova Scotia and with Nova Scotia. The v13.1 change is a fourth model SERIES,
v13.1, added to both metrics in both panels, and a third panel added for the new NS treatment described in 5.3, so
the figure goes from two panels to three. The underlying six-scenario table (report Table 34, two inclusion rules
times three NS treatments, eighteen rows) gains a fourth model in every scenario block, taking it from eighteen
to twenty-four rows, and gains a fourth NS treatment (NS scored out-of-fit against the reserved recent-decile
holdout), taking it to thirty-two rows.
`[[TK: v13.1 mean rank, sources won, pooled TOTVOL %RMSE and pooled bias in all eight scenario blocks | src:
rebuilt build_reconciled_ranking.py]]`. The evidence column retains verbatim the three honest framings the red
team installed: that neither model is a clean overall winner, that the earlier v12.11-wins-overall headline was a
triple-counted-Nova-Scotia artifact and is superseded, and that OSM has no score at all for two of the eight
ME/NB/QC sources (Maine FIA subplot, n = 2,858, and QC MagPlot, n = 378). One framing line is added: that Nova
Scotia is partly in-sample for v13.1's mortality component, so v13.1's Nova Scotia contribution to this ranking
is not independent in the way base's, v12.11's and OSM's are, and the NS-holdout scenario is the row to read for
an apples-to-apples comparison. No "v13.1 wins overall" phrasing may appear anywhere on this slide, under the
same rule that governs v12.11.

Slide 36, LONG-HORIZON BIOLOGICAL REALISM. The slide's figure is `fig24_bakuzis_longterm.png` and its left column
is the five-relation verdict matrix (Eichhorn, Reineke self-thinning, site ordering, yield-density, Sukachev) with
a per-model PASS or FLAG, currently three models, v12.11 passing four of five and OSM flagging Eichhorn and site
ordering. The v13.1 change is a fourth model ROW in the verdict matrix and a fourth trajectory series in the
figure, plus a refresh of the two quantitative anchors the slide carries: the plateau basal area range, currently
31.6 to 36.1 m² ha⁻¹, gains a v13.1 value, and the Eichhorn coefficient of variation, currently 26.3% for OSM's
flag, gains a v13.1 value. `[[TK: v13.1 five-relation PASS/FLAG verdict, plateau BA, Eichhorn CV, site-ordering
inversion counts | src: g2_bakuzis_v131_relations.csv and g3_plateau_v131_traj.csv]]`. The two interpretive
caveats are retained verbatim: that the Bakuzis battery is a falsification check read alongside the accuracy
scorecard and not instead of it, and that OSM's Eichhorn and site-ordering flags come from real, previously
disturbed SILC and CFI stands rather than a controlled synthetic gradient, so part of the flag may reflect stand
history rather than model behaviour. One sentence is added, and it is the scientific point of extending this
slide at all: because the v13.1 mortality posterior enters as a multiplicative modifier on the frozen Reineke
ramp rather than as a replacement of it, the self-thinning and plateau relations are preserved by construction,
and the purpose of rescoring is to confirm that the fitted hazard's level does not break the relations the
construction was designed to protect.

### 5.2 The Nova Scotia relabel: wording and every location it must change

The wording to use, everywhere, is that Nova Scotia is "partly in-sample" for v13.1. The short form for slide
headers, table footnotes and figure captions is: "Nova Scotia, partly in-sample for v13.1 mortality." The medium
form for evidence columns and table notes is: "Nova Scotia is partly in-sample for v13.1: its CFI record is
folded into the whole-plot mortality fit, so Nova Scotia is not an independent test of that component, though it
remains independent for every component not refit on it." The long form, for section intros and methods, is the
paragraph given in Section 3.5 above. The forbidden phrasings, which must not survive anywhere in a v13.1
deliverable, are "independent-province validation," "fully independent," "contributes no data to the fit," and
"independent province-scale benchmark" when used of v13.1. Where those phrases describe v12.11 in a
version-lineage passage they may remain, but only with an explicit "in v12.11" or "through v12.11" qualifier in
the same sentence.

The locations where the old framing currently appears and must change are as follows. In the benchmark report:
the Section 11 title, which reads "Nova Scotia: an independent-province validation" and becomes "Nova Scotia:
province-scale validation, partly in-sample for v13.1"; the Section 11 opening paragraph; subsection 11.1
(managed-stand levers generalize), whose generalization claim rests on independence and must be requalified;
subsection 11.2 (site index basis and transferability caveat), which gains a sentence noting that the
transferability argument is now partly circular for the mortality component; subsection 11.4 (the OSM v2.26.1
head-to-head), where a head-to-head against a model that did not see Nova Scotia is no longer symmetric for
v13.1; subsection 11.5 (methods and open items), which gains the fitset counts and the holdout; Tables 26 to 29,
each of which gains an in-sample or out-of-sample status label per component; Section 12 and Table 34, where the
per-source ranking text describes Nova Scotia as counted once as an independent source; Section 2 and Table 1,
where the coverage table's source descriptions distinguish fit data from benchmark data; Section 13 methods,
where the fitset description now includes Nova Scotia; and the two dated Nova Scotia update blocks in
Appendix A, which are historical records of the v12.11 state and therefore keep their wording but gain a pointer
to the v13.1 change. In the GTR: subsection 10.7, titled "Nova Scotia independent-province validation," which is
retitled on the same pattern; Section 5, where the mortality model's fitting data are described; Section 10.8,
the master scorecard and ranking; and Appendix D's validation tables. In the deck: the Nova Scotia arc, which
runs from the start of the Nova Scotia section through the Nova Scotia OSM head-to-head slide and ends
immediately before slide 34, so its slide numbers are approximately 30 to 33 and must be confirmed rather than
assumed (`[[TK: exact deck slide numbers of the Nova Scotia arc | src: markitdown of
FVS-ACD_Hennigar_Aug2026.pptx]]`); the framing lines on slides 34 and 35 as specified in 5.1; and the Roadmap
slide, which currently describes folding Nova Scotia into the v13.1 fitting as a recommendation and must be moved
to the past tense. In the supporting memos, which are internal but are cited by the deliverables and should not
be left contradicting them: `20260723_master_scorecard_and_ranking.md` Sections 1, 3, 4, 5 and 7, and
`20260722_ns_benchmark_philosophy_pass.md` throughout.

### 5.3 New slide: Nova Scotia holdout sensitivity

A new slide is added immediately after slide 35 (overall ranking), so that it reads as the sensitivity on the
ranking rather than as a Nova Scotia result in its own right. Its eyebrow is the results-arc eyebrow used by
slides 34 to 36. Its assertion title states the outcome of the sensitivity rather than its existence, and is
therefore written once the numbers land: `[[TK: assertion title, of the form "Scored only on the Nova Scotia
stands it never saw, v13.1 <holds / loses / gains> <x> percentage points" | src: NS-holdout scorecard]]`.

What the slide shows. The left evidence column carries the fitset arithmetic in three numbers that a reader can
check: 3,922 Nova Scotia whole-plot stands entered the v13.1 whole-plot mortality fitset of 212,768 rows, of
which 924 are managed or treated and 2,998 are unmanaged; a Nova-Scotia-only recent-decile holdout reserved the
most recent decile, leaving 3,426 stands in-fit of which 812 are managed; and Nova Scotia enters at its native
per-stand binomial weight, roughly one-eighth the per-stand weight of an FIA record, because it carries no FIA
population expansion. The right panel is a paired-bar figure with two groups, in-fit Nova Scotia stands and
held-out Nova Scotia stands, and within each group four bars for base, v12.11, v13.1 and OSM-ACD v2.26.1, on
TOTVOL percent RMSE, with a companion small-multiple on bias.
`[[TK: NS in-fit and NS held-out TOTVOL %RMSE and bias for all four models | src: NS-holdout scorecard run]]`.
The interpretive line beneath states the decision rule agreed in advance: if v13.1's advantage over base on the
held-out Nova Scotia stands is materially smaller than its advantage on the in-fit stands, the in-sample gain is
partly optimism and the Nova Scotia result must be reported with that discount; if the two are close, the gain
transfers and Nova Scotia can be cited as evidence of generalization even though it is partly in-sample.

Why this slide is now scientifically necessary. Nova Scotia is the single largest non-CONUS benchmark in this
project and it carried most of the weight in the v12.11 overall ranking; the reconciliation memo already had to
correct a triple-counting artifact that inflated its influence. Through v12.11 the honest defence of that weight
was that Nova Scotia was entirely out of sample, so a good Nova Scotia score was pure generalization. That
defence no longer holds for v13.1's mortality component, and without a holdout there is no way to separate
genuine transfer from in-sample fit on the province that dominates the benchmark. Presenting the Nova Scotia
result for v13.1 without this sensitivity would be presenting an in-sample score as if it were an out-of-sample
one, in front of an audience (Hennigar) whose own model was fitted on different data and did not see Nova
Scotia at all. The holdout was reserved at fit time precisely so that this slide could be built, so building it
costs nothing beyond the scoring run and not building it would waste a design decision already paid for.

---

## 6. Provenance and build order for the v13.1 pass (revised)

The build order below replaces the 23 July Section 6 and reflects the current critical path. Step 1 is now two
independent landings rather than one, and step 2 has an added verification gate that did not exist on 23 July.

First, land the posteriors. Confirm convergence and export random effects for the whole-plot NS-inclusive fit
(job 12863545), checking specifically for the multimodality that killed job 12554985: compare per-chain mean
log-posterior across all six chains before reading any Rhat, since a chain sitting tens of thousands of
log-units below the others makes a pooled Rhat meaningless. The subplot fit (job 12547720) has landed and its
diagnostics are in hand. Land the v7 recruitment fit (job 12865188) and fill the Section 4 diagnostic tokens.
Symlink `v131r_mortBNS_*` to the hook-expected `v131r_mortB_*` names, as was done for the subplot posterior.

Second, verify recruitment before scoring it. Run the staged PEF verification and require the predicted mean
ingrowth to land inside the 10 to 20 stems ha⁻¹ yr⁻¹ acceptance band against the PEF base of 13.39. Generation v6
converged and still failed this gate at 33.60, so convergence is not sufficient evidence that the recruitment
component is usable. Do not run a recruitment-ON candidate scorecard until the PEF gate passes.

Third, run the v13.1 switches-ON all-sites scorecard against base and OSM v2.26.1, in three arms so the
components can be attributed: mortality-only, recruitment-only, and combined. The mortality-only arm at subplot
grain has already run (job 12624990) and is near-neutral; rerun it at whole-plot grain once job 12863545 lands.
Fill the scorecard, forest-group, guardrail, and Bakuzis tokens. Finish the two outstanding subplot candidate
rows (tasks 4 and 11) and rerun the aggregator.

Fourth, run the Nova Scotia holdout scoring so slide 5.3 and the ranking's fourth NS treatment can be filled.

Fifth, rebuild the master scorecard and reconciled ranking with v13.1 scores, the fourth model column, the fourth
NS treatment, and the NS-in-fit disclosure, via a v13.1 edition of `build_reconciled_ranking.py`; preserve the
v12.11 outputs as `_PREV`.

Sixth, for each deliverable: back up the finalized v12.11 file as `_PREV_YYYYMMDD`, open it as the floor, apply
the adds and revisions in Section 3, drop in the methods prose from `20260728_v131_methods_prose.md` and the
Section 3.5 Nova Scotia reframe, apply the Section 5.2 relabel at every listed location, fill every `[[TK:]]`
token, and produce a content-inventory diff against the v12.11 floor listing added, changed and removed (removed
should be empty; flag any exception).

Seventh, re-verify gate-off byte-identity after any further model-file integration (all three staged hooks
default OFF), and confirm the contract sentence and job id 12612571 in the report methods and the GTR.

Eighth, run a reviewer pass whose explicit job includes checking for lost content against the finalized v12.11
deliverables, not only auditing the new v13.1 content, and which also checks that no forbidden Nova Scotia
phrasing from Section 5.2 survives.

Hard constraints honored in this plan: no v12.11 deliverable is overwritten and no prior planning artifact is
overwritten (the 23 July plan and its `_PREV_20260724` backup both remain on disk); FIA true coordinates and
proprietary tree records stay on Cardinal and appear in no deliverable, with the no-coordinates assertion in the
Nova Scotia fitset made at read, at build and on re-verification; Nova Scotia and any JDI-adjacent data are
reported as aggregates only; the raw Castle tree records stay local and only fitted coefficients are published.

---

## 7. Content-inventory diff: 28 July plan against the 23 July plan

Base (floor): `20260723_v131_deliverables_plan.md`, 31,767 bytes, last written 25 July 06:23, itself carrying
`20260723_v131_deliverables_plan_PREV_20260724.md`. Output: `20260728_v131_deliverables_plan.md`, a NEW file. The
23 July file is not overwritten, not edited, and remains the prior version of record.

ADDED. Section 0.1, a dedicated landing-dependency block reflecting the current job set, replacing the
inline dependency list. A tightening rule in Section 0 stating that a token may only be retired by a value
tracing to a landed export. A second framing sentence in Section 1 carrying the neutral-mortality and
recruitment-is-the-lever finding. Six new cross-cutting items in Section 3.1: item 7 (mortality scores neutral on
volume), item 8 (the density signal is gentle and thresholdless), item 9 (the three-generation recruitment
history), plus amendments to items 1, 2 and 3. Four new report subsections in Section 3.2: the hand-gate versus
fitted-hazard comparison, the whole-plot first-attempt post-mortem, the recruitment response-scale watch item,
and a rewritten Section 1 verdict instruction. Landed intermediate numbers now reportable in the report Section 5
revision (the nine-source subplot-mortality-only scorecard) and in GTR Appendix B (subplot recruitment fixed
effects). A wholly new Section 5, replacing the 23 July Section 5's two paragraphs with three build-ready deck
specifications: 5.1 slide-by-slide extension of slides 34 to 36 naming the specific columns, rows, panels and
series added; 5.2 the Nova Scotia relabel with three levels of wording, a forbidden-phrasing list, and an
enumeration of roughly twenty locations across report, GTR, deck and memos; and 5.3 a new Nova Scotia holdout
sensitivity slide with its content, its figure design, its decision rule and its scientific justification. An
expanded Castle red oak item C carrying the companion species coefficients, the sample sizes and p-values, the
diameter range, and the paper birch reference problem. A revised eight-step build order in Section 6 with two new
gates (per-chain log-posterior comparison before Rhat, and a PEF acceptance gate on recruitment before scoring).
This content-inventory diff, Section 7, which the 23 July plan did not contain.

CHANGED. The Section 0 landing dependencies: the whole-plot mortality job moves from 12554985 to 12863545 with
the timeout recorded; the recruitment dependency moves from a single converged fit to a three-generation history
with job 12865188 pending; the gate-off contract job id moves from 12554203 to 12612571. The Section 1 framing
sentence is rewritten to name both hierarchical components as multiplicative and to add the honest second
sentence. Section 3.5's Nova Scotia paragraph gains the holdout sentence and the 3,426-of-3,922 arithmetic.
Section 4 changes from carrying draft methods prose to pointing at `20260728_v131_methods_prose.md`, with the
three specific corrections against the 23 July draft stated in place so the change is not silent. Section 3.2's
scorecard tokens are split into a landed subplot-mortality-only arm and a pending combined arm. Section 3.3's
GTR additions gain the offset construction and the neutrality statement. The report Section 12 and deck slide 35
ranking structure changes from three Nova Scotia treatments to four, and from three models to four.

REMOVED, with reasons, and nothing removed silently. The 23 July Section 4 draft methods prose is removed FROM
THIS FILE and relocated, not deleted: it is superseded by `20260728_v131_methods_prose.md`, and the three
assertions in it that are now false (whole-plot clean convergence, adapt_delta 0.99 and treedepth 15 as the
whole-plot configuration, recruitment converged on a single fit) are corrected there and the corrections are
listed in Section 4 of this file. The claim in the 23 July Section 0 that the hierarchical recruitment posterior
had "converged (per pass-2 status)" is removed because the fit it referred to is generation v5, which is retired
for the expansion-factor defect; it is replaced by the three-generation history. The 23 July statement that the
whole-plot posterior would come from job 12554985 is removed because that job timed out; it is replaced by job
12863545 and the post-mortem. No section, table, figure, or slide from the v12.11 content inventory in Section 2
is removed, and Section 2 is carried forward verbatim and in full.

Nothing in the v12.11 floor was dropped. The three deliverables still comprise a 14-section report with Tables 1
to 34 and figures 1 to 24, a GTR with sections 1 to 12 and Appendices A to D, and a 41-slide deck, and under this
revision all three grow: the report gains at least five subsections and a fourth model column in Tables 31 to 34,
the GTR gains subsections in Sections 5, 6 and 10 plus rows in Appendices B and D, and the deck gains at least
three slides and grows from 41 to at least 44.
