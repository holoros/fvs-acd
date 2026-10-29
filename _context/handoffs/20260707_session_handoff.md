# FVS-ACD session handoff, 7 July 2026

Final state going into the 18 August Acadian G&Y meeting with Chris Hennigar. Plaintext math, no em dashes.

## Where the model landed

The shipped operational version is FVS-ACD v12.10.1 (scripts/AcadianGY_12.10.1.r). It carries the Chapter 11
direct-effect management modifiers as gated additive releases (planted +3.8 m2 ha-1 basal area, PCT +2.4,
clamp-free), on top of the v12.9.x composition and ecoregion aware brms SDImax, the v12.7.1 coupled
two-segment self-thinning with density-released ingrowth, and FIA NSVB volume and biomass throughout. Gate off
reproduces v12.9.x; legacy flags reproduce v12.5.0.

## The honest scorecard position (this is the August story, do not overclaim)

Managed: FVS-ACD wins. Out of fold managed mean absolute bias 1.3 vs OSM 8.3; planted 4.0 vs OSM 16.7; PCT
transfers NB to QC 4.1 vs OSM 3.7. Leave-one-province 1.5; managed split-half beats OSM in most reps.

Pooled unmanaged: OSM leads, honestly. Mean absolute bias 3.2 vs 5.0, modeling efficiency 0.75 vs 0.71, TOST
equivalence 8 of 9 vs 7 of 9. FVS-ACD does not claim pooled parity; its edge is biological realism and
transparency (only model that plateaus at the realistic maximum and passes the Bakuzis relations).

Two disclosed limits, both v13 targets, both on the biological-realism slide:
1. Ingrowth under-prediction. Predicted vs observed NB 17.9 vs 39.8, QC 11.7 vs 19.7 stems ha-1 yr-1
   (about 45 percent NB, 59 percent QC). Direction correct, responds to density and management, level low.
2. Pooled parity was tested and not shipped. A top-height anchor level correction was quantified
   (topht_recal_diag.R). In the shipped config a +9 percent top-height over-prediction offsets a -8 percent
   basal-area under-prediction, so correcting height alone drives volume negative. True parity needs a joint
   height and basal-area re-anchor. Deferred to v13.0.

## Deliverables updated this session (all in repos/fvs-acd)

- FVS-ACD_Hennigar_Aug2026.pptx: final v12.10.1 deck (managed win, pooled honesty, ingrowth limit added,
  parity-deferral reason stated, v13 fall-arc closing, provincial-data ask).
- FVS-ACD_variant_overview_GTR.docx and 20260629_..._GTR_draft.md: rebuilt to v12.10.1 (version lineage,
  Chapter 11 modifiers, Bakuzis pass, ingrowth limit, planned v13).
- 20260703_v12101_full_benchmark.md: Bakuzis, ingrowth-validation, and pooled-parity subsections added.
- 20260704_v12101_stress_and_parity.md: the red-team + full stress test (Bakuzis + ingrowth + sensitivity)
  + parity reach. Verdict: keep v12.10.1, defer parity to v13.0.
- 20260702_reply_to_hennigar_DRAFT.md: refreshed; explicit managed-database ask added.
- 20260703_email_to_ben_rice_v1210_DRAFT.md: the Ben narrative.

## Gmail drafts staged (Aaron sends)

- To christopher.hennigar@nrcan-rncan.gc.ca, "Re: Acadian G&Y Meeting", id r5674647696970173893.
- To midgard.natural.resources@gmail.com, "FVS-ACD 12.10.1 ...", id r-4763101236119887359.
  ACTION: the body says the code is attached; attach scripts/AcadianGY_12.10.1.r (193 KB) before sending,
  since the staged draft cannot carry the binary from here.

## v13 is the fall arc

v13.1 is already resolved and redirected: the management effect is a diameter-growth release, not a mortality
effect (growth scale cleanly identified and poolable, hazard scale negligible and unidentified). So management
moves into the v13.2 growth refit as a hierarchical predictor; the v13.1 mortality/ingrowth refit proceeds
without a management hazard term. Design matrix and both fits built (20260704_v131_growthscale_results.md;
v131g_fitset.rds on Cardinal). Full sequence in 20260703_v13_execution_plan.md. Start with v13.0 (height and
domain), the highest single-metric leverage and independent of the rest. Kickoff prompt in the file below.
