# Comprehensive plan for the August 18 Acadian G&Y meeting with Hennigar

*2 July 2026. Plan for Aaron's contribution to the NRCan CFS Acadian growth-and-yield meeting on 18 August,
built around Chris Hennigar's stated agenda, and the analysis build-out needed to support it. Plaintext
math, no em dashes.*

## The meeting (from Hennigar's 2 July email)

Date 18 August 2026, hosted by CFS, in person at Fredericton with a Teams virtual option. Informal, open
agenda, focused on recent G&Y R&D regionally (Acadian) and nationally, with Aaron's US work and recent CFS
work featured. Confirmed attendees: Aaron Weiskittel (UMaine, in person), Chris Hennigar and Adam Dick
(CFS, in person), Rob O'Keefe (NS), Muhammad Usman (NL, virtual), Jereme Frank (Maine, tentative); invited
also NB (Beth Brooks) and PE (Mangus). This is the provincial-and-federal Acadian G&Y community, the same
audience as the 2018 ECANUSA benchmark.

Chris's named agenda topics, and where Aaron's work maps:
1. Site productivity -> the ESI vs BGI vs CPSI vs CSI site-variable bake-off (the top-height diagnostic
   showing ESI runs high is a direct, concrete contribution here).
2. Data harmonization -> harmonizing FIA, MagPlot (QC and NB), SILC, and NB/NS PSP into one comparable
   frame on FIA NSVB volume and biomass; this benchmark IS a harmonization exercise.
3. New approaches for calibrating models -> the multi-dimensional scorecard, Bayesian brms SDImax, the
   composition and ecoregion-aware self-thinning, the independent OSM vs FVS re-derivation.
4. Integrating climate into G&Y -> ESI 2030 and time-varying site as an explicit forward scenario, the
   v13 climate driver.
5. AI to increase productivity -> the Cowork-driven workflow that produced this benchmark and the
   refinements is itself a demonstration Aaron can speak to.

ACTION (time-sensitive): Aaron must confirm in-person attendance to Chris; CFS clearance for US citizens is
more involved and takes lead time. Reply and confirm soon.

## Deliverable 1: Enhanced multi-dimensional scorecard

Extend the scorecard (GY_model_evaluation_scorecard.md) with the two additions Aaron wants and a
forest-type cut:
- Equivalence testing. Add the two one-sided tests (TOST) with a stated region of equivalence (for example
  plus or minus 10 percent for level, wider for increment), after Robinson and Froese (2004) and Reynolds
  (1984), reporting for each model and metric whether predictions are statistically EQUIVALENT to observed
  within the region, not merely not-significantly-different. This is the rigorous way to make the "is it
  good enough" claim and is more defensible than a bias p-value. Report the equivalence result alongside
  bias, RMSE, and modeling efficiency.
- Explicit Bakuzis relations. Report the named law-like relationships individually per model, not just a
  pass/flag summary: Eichhorn (volume a near-unique function of mean height), Reineke self-thinning slope
  (target near -1.6), site ordering (better sites not overtaken), yield-density, and Sukachev. Give the
  quantitative criterion and the pass or flag for each, per model, from the long-horizon trajectories and
  the bakuzis-assessment skill.
- By forest type. Break every quantitative metric out by forest type (softwood, mixedwood, hardwood, and
  the finer ecobucket types already defined) in addition to by jurisdiction, since the benchmark showed the
  bias is composition-dependent (hardwood-rich QC stands drive the over-prediction).

## Deliverable 2: Build out the OSM vs FVS deck

Extend FVS-ACD_v1271_Hennigar_Aug2026.pptx into the meeting deck:
- The five-way scorecard (v12.5.0, v12.7.0, v12.7.1/12.9.x, OSM) heatmap and radar, with the headline that
  FVS v12.9.x has both low bias and the best precision (modeling efficiency) while OSM has near-zero bias
  but negative NSE (imprecise).
- Performance by forest type: a panel showing bias and equivalence by softwood, mixedwood, hardwood for
  each model, which is where the models differ most and is directly useful to the provincial managers.
- Equivalence and Bakuzis slides: a clean equivalence-region plot per metric, and a Bakuzis relations
  pass/flag table.
- Site productivity slide: the top-height diagnostic (ESI runs high, increment 1.7x NB and 8.9x QC too
  fast) and the site-variable bake-off framing (ESI vs BGI vs CPSI), which speaks straight to agenda item 1.
- A short methods slide on the NSVB harmonization (agenda item 2) and one on the AI-assisted workflow
  (agenda item 5), kept light.

## Deliverable 3: Pre-meeting input for Chris

Chris asked for input toward the meeting. Prepare a concise 2 to 3 page brief (or an annotated version of
the deck) summarizing: the independent re-derivation result (v12.7 matches or beats 2018 OSM on NB; OSM
imprecise), the site-productivity finding (ESI over-predicts height, bake-off underway), the harmonization
approach (NSVB), and the open questions Aaron wants the group's input on (site metric choice, the QC edge
and domain, data sharing). Send it to Chris a week or two ahead so he can fold it into the agenda.

## Sequence and timing

Aug 18 is six-plus weeks out, so there is room to do this properly. Order:
1. Now to mid-July: finish v12.9.x (the 7:15 finalization run) and the site-variable bake-off (the 10:45
   run); these produce the numbers the deck needs.
2. Mid-July: enhance the scorecard (equivalence testing, explicit Bakuzis relations, by-forest-type) and
   re-score all models.
3. Late July: build out the deck with the forest-type, equivalence, and Bakuzis panels and the site and
   AI slides.
4. Early August: write the pre-meeting brief and send to Chris; confirm attendance and clearance well
   before then.

## Open questions to raise with the group (agenda-aligned)

- Site productivity: is BGI or CPSI a better regional site driver than ESI, and can the provinces share the
  layers and the plots to fit them.
- Data harmonization: can MagPlot, the provincial PSPs, and FIA be pooled under one harmonized schema with
  NSVB volume and biomass as the common currency.
- Calibration: is the multi-dimensional scorecard (with equivalence and Bakuzis) a standard the group would
  adopt for comparing OSM, FVS-ACD, and CFS national models.
- Climate: how to represent climate change in the site metric without breaking the validated base.
