# FVS-ACD site-driver modernization: full handoff

*27 June 2026. Self-contained handoff for a dedicated session. Goal: migrate the Acadian variant of FVS (FVS-ACD) from its 15-year-old ACD_CSI climate site index to the modern unified-target ESI, implemented as a robust hierarchical (and ideally spatially explicit) dominant-height site sub-model. Includes a ready-to-paste task prompt at the end.*

## 1. Scope and why it is separate

This grew out of the BGI/CSPI independent-validation work but is a distinct, operational effort: it targets the FVS-ACD model code and its users, not a journal. Keep it separate from the CSPI manuscript. The CSPI session has refocused on North American BGI and CSPI.

## 2. What is established (do not re-derive)

1. **Tree-level growth carries no usable site signal.** Across ~216,000 trees, neither ACD_CSI nor any modern surface (ESI, BGI, Asym) adds more than 0.001 to adjusted R^2 of individual-tree diameter or height increment once DBH/height + BAL + CCFL are present. So do not modify the tree-level growth equations and do not build a tree-level site modifier.
2. **Modern ESI beats ACD_CSI at predicting measured site index:** R^2 0.91 vs 0.52, RMSE 1.4 vs 3.2 m (matched n = 49; realistic out-of-sample ESI is the spatially blocked 0.46 to 0.55, still at or above ACD_CSI).
3. **An ESI-anchored dominant-height curve works as well as a measured-SI-anchored one:** base-age Chapman-Richards on 337,680 site-tree records, R^2 0.804, RMSE 2.45 m with ESI as anchor, identical to measured SI, vs 0.17 for a no-site guide curve. The anamorphic single-shape fit leaves a systematic age-residual trend (under-prediction near mid-rotation, over-prediction in old stands), which signals the production form must be polymorphic.

Memos and scripts: `bgi-cspi-conus/v5/maine_cfi/` (fvsacd_site_migration_finding.md, esi_anchored_height_result.md, the R scripts and result CSVs). This folder (`fvs-acd-site-update/`) holds the charter and the hierarchical script.

## 3. Data assets (all on Cardinal at /fs/scratch/PUOM0008/crsfaaron/maine_cfi unless noted)

- `AllEastSIPred.csv` (337k site trees: SOURCE, SPCD, fvs_ne_var, AGEDIA, HT, measured SI, SIPred = modern ESI, LAT, LON, climate). The height-age fitting frame.
- `DBHout.csv` (1.05M tree records: real coords, growth, BAL/CCFL/SDI/RD, climatesi = ACD_CSI). Source: `~/Documents/MAINE/DATA/Analysis/AFVS/`.
- `PlotLocations.csv` (Source/Stand/Plot to real lat/long; fixes the placeholder Pacific coordinates in the harmonized spreadsheet).
- Modern surfaces: `cspi_v7/cspi_v2_aligned/BGI_on_esi_grid.tif`, `Asym_on_esi_grid.tif` (30 m, CONUS); `canada/magplot/na_surface/NorthAmerica_ESI.tif` (4 km, covers Canada).
- Level 3 ecoregion polygons: `~/SiteIndex/NA_Eco_L3_WGS84.shp`.

Data-quality flag to fix upstream: the harmonized `AllAcadianPlotSummaryData.xlsx` carries placeholder Pacific coordinates (lat 45, lon -124/-129) for PEF and CTRN; repair from `PlotLocations.csv`.

## 4. The model plan (hierarchical, and a spatial option)

Production dominant-height sub-model: a polymorphic (GADA) Chapman-Richards with the modern ESI as the site anchor and random effects for **species** and **ecoregion** on the shape parameters. Two routes:

- **Frequentist nested random effects (nlme):** `HT ~ SI_anchor*((1-exp(-k*age))/(1-exp(-k*50)))^p`, random `k+p | eco/spp`. A first fit is staged in `hierarchical_esi_height.R`. Note: the first run (job 12073115, 120k-obs subsample, nested eco/species random effects) was cancelled at about 10 minutes without converging, confirming that nlme struggles at this scale and graph complexity. For the dedicated session, either subsample harder and simplify the random structure (species only, ecoregion as fixed), or go straight to the stLMM Bayesian route below, which is better suited to the spatial and areal structure here.
- **Bayesian spatial LMM (stLMM, Andrew Finley):** https://finleya.github.io/stLMM/ and github.com/finleya/stLMM. Strongly worth exploring. It fits Bayesian LMMs with iid grouped effects plus structured spatial/areal terms (NNGP point-referenced, CAR/DAGAR areal) via a collapsed sparse-precision sampler, with WAIC for model comparison and prediction to arbitrary supports. The right use here: model the dominant-height **level / site-index anchor** as a structured LMM, predicting it from ESI with `iid(species)`, an ecoregion `car()`/`dagar()` areal term, and an `nngp()` spatial term, with proper uncertainty. The nonlinear age trajectory (the Chapman-Richards shape) sits outside a linear model, so handle it either by (a) fitting the shape (k, p) separately or per species and using stLMM for the level, or (b) linearizing via a base-age difference (ADA) transform so the response is approximately linear in the site level, then applying stLMM's spatial/areal/iid terms. stLMM's stated comfortable scale (up to a few hundred thousand NNGP nodes) fits this data. It also gives a clean, uncertainty-aware site surface that could feed FVS-ACD directly.

Validation for either route: spatially blocked (one-degree or ecoregion) out-of-sample R^2, RMSE, projection-bias by horizon; Bakuzis biological-realism check (site ordering, no curve crossing). The current fits are in-sample because ESI was trained on the same compilation, so blocked validation is required before adoption.

## 5. Implementation into FVS-ACD

- Repo: `github.com/MidgardNaturalResources/ForestVegetationSimulator` (David Diaz's Fortran fork of USDAForestService/ForestVegetationSimulator). His June 2026 PR "FVS interface updates for ADK, ACD and HI" shows the Acadian variant is actively maintained toward the summer 2026 release.
- Where it enters: the dominant-height / site-index routines of the ACD variant. Replace the ACD_CSI site-index input with the ESI-derived site index and update the dominant-height coefficients to the new hierarchical fit. Leave the diameter-growth equations unchanged.
- Backward compatibility: publish an ACD_CSI to ESI-site-index mapping as a transition aid.
- Coordinate with David Diaz on PR timing, since he holds the fork and the active ACD interface work.

## 6. Recommended next steps for the dedicated session

1. Capture the staged nlme result; if it did not converge cleanly, refit (subsample or simplify) and/or move to stLMM for the level model.
2. Install and trial stLMM on the level/site-index model (iid species + ecoregion CAR/DAGAR + NNGP spatial), compare by WAIC to the nested nlme.
3. Add polymorphism (species-specific shapes) to remove the mid-rotation age bias.
4. Spatially blocked out-of-sample validation + projection-bias-by-horizon + Bakuzis realism.
5. Translate the fitted curve to ACD-variant coefficients; draft the code change against the Midgard fork; coordinate the PR with David Diaz.

---

## 7. Ready-to-paste task prompt for the dedicated session

> You are continuing the FVS-ACD site-driver modernization. Read `active-projects/fvs-acd-site-update/HANDOFF_FVS-ACD.md` and `CHARTER.md` first. Established and not to be re-derived: tree-level growth carries no site signal beyond size and competition (do not touch the diameter-growth equations or build a tree-level modifier); the modern unified-target ESI predicts measured site index far better than the legacy ACD_CSI (R^2 0.91 vs 0.52); and an ESI-anchored Chapman-Richards dominant-height curve matches a measured-SI-anchored one (R^2 0.80). Connect to Cardinal via /hpc-cardinal. Goal: produce a robust, validated, ESI-anchored dominant-height site sub-model for the Acadian variant of FVS and a drafted code change.
>
> Tasks, in order: (1) capture the staged nlme fit at `/fs/scratch/PUOM0008/crsfaaron/maine_cfi/hier_esi_height_summary.csv`; refit if it did not converge. (2) Explore Andrew Finley's stLMM (https://finleya.github.io/stLMM, github.com/finleya/stLMM): install it, and fit the dominant-height level / site-index anchor as a Bayesian structured LMM predicting the site level from ESI with iid(species), an ecoregion CAR or DAGAR areal term, and an NNGP spatial term; handle the nonlinear Chapman-Richards age shape separately or via an ADA difference transform; compare models by WAIC. (3) Add species-specific (polymorphic) shapes to remove the mid-rotation age-residual bias. (4) Validate out-of-sample with one-degree or ecoregion spatial blocking, report R^2, RMSE, and projection-bias by horizon, and run a Bakuzis realism check. (5) Translate the fitted curve into FVS-ACD variant coefficients and draft the code change against github.com/MidgardNaturalResources/ForestVegetationSimulator (the ACD variant dominant-height/site-index routines), and prepare a note to David Diaz to coordinate the upstream PR. Data assets and paths are listed in the handoff. Use R with data.table/nlme/stLMM, run heavy fits as SLURM jobs, keep figures to r-analysis/advanced-viz conventions, no em dashes, plaintext math. Document results as dated memos in this folder.

---

## Update 2026-07-03: management-modifier robust re-fit (v12.10.1), red-team clamp resolved

The one weakness the 3 July red team flagged (planted and PCT diameter-growth multipliers pinned to the 1.6
guard clamp, an effective capped constant) is fixed in AcadianGY_12.10.1.r.

- Diagnosis: the modifier was the ratio of class-mean NET increments; the mean predicted-untreated net
  increment is near zero on mature managed stands (planted 1.06, PCT 0.26 m2/ha) because self-thinning
  declines cancel gross growth (about 25 pct of stands have negative predicted-untreated net increment), so
  the ratio blew up (5.2, 10.2) and pinned to the clamp.
- Fix: re-fit the direct effect as a robust ADDITIVE direct-effect release (10 pct trimmed mean of per-stand
  observed-minus-predicted-untreated increment, per metric). Fitted BA release planted +3.8, PCT +2.4 m2/ha.
  Clamp-free; fold coefficients now move (planted BA release 3.6 to 4.1 across folds). Equivalent net
  multiplier about 3.0 planted / 2.3 PCT, i.e. ABOVE the old clamp, which is why the capped version still
  under-predicted planted.
- Out of sample (same red-team battery): leave-one-installation-out managed MAE 1.4, leave-one-province 1.5,
  200-fold managed split-half 5.6 beating OSM in 76 pct of reps. PCT now transfers across the NB<->QC
  province block (4.1 vs OSM 3.7, was 7.3) and the PCT BA residual closes (+0.3 vs OSM -5.4). Unmanaged and
  growing stands untouched (additive only on PLANTED/PCT). Long-horizon plateau holds at every amplitude
  (self-thinning caps; 160-yr smoke test); engine planted amplitude set to 2.0, ceiling about +20 pct.
  Gate-off byte-identical to v12.9.x (max dbh diff 0.0e+00); legacy path reproduces v12.5.0.
- Files: scripts/AcadianGY_12.10.1.r (model), 20260703_management_modifier_robust_refit.md (full memo),
  results/mgmt/mgmt_gap_closure_robust.csv, mgmt_scorecard_byclass_robust.csv, mgmt_modifier_coefs_robust.rds.
  Deck FVS-ACD_Hennigar_Aug2026.pptx (slides 10, 11, verdict) and the pre-meeting brief, Hennigar reply, and
  Ben Rice email drafts all reconciled to the robust numbers. Cardinal ~/magplot/verify: mgmt_diagnose.R,
  mgmt_cv_robust.R, mgmt_finalfit.R, mgmt_plateau_sweep.R, hennigar_figs_robust.R. Aggregates only;
  coordinates never left the node.
- Open item for v13: pin the exact per-tree engine amplitude that reproduces the additive net release via a
  full engine re-projection, inside the hierarchical mortality/ingrowth refit with management as a predictor.

---

## Update 2026-07-03 (v13 kickoff: v13.0 height + v13.1 hierarchical mortality/management)

Autonomous OODA run executing the first two v13 workstreams. v12.10 stays shipped; nothing adopted.

v13.0 height. Domain mask defined (finite ESI AND EPA L3 in {5.3.1, 8.1.7, 8.1.8, 8.1.1}); US in-domain
13,894 of 14,206 pairs. Base-age-invariant increment anchors (M1 linear, M2 monomolecular) fit unbiased in
domain (US spatial-CV increment ratio 1.00) but do NOT transfer to the MagPlot edge: NB 1.89 -> 2.6, QC 6.99
-> 6.1. Matched-state diagnosis: at equal topht1 and ESI, QC increment is negative while ESI reads 18-19
(implied asymptote ~36 m vs stands topping ~22 m). Cause is ESI over-reading productivity at the QC edge
plus an unidentified asymptote on US-only data, not functional form. Verdict: mask GO, refit NO-GO on
current data; next step is the mature-Acadian data refit (NB/NS PSP, MagPlot managed, SILC) = the August
ask.

v13.1 hierarchical mortality/management. Design matrix built: 208,846 fit stands (MagPlot + recent-FIA proxy
held out), 48 regions, 84 ecoregions, 150 forest types; planted 25,194 / treated 18,393 / none 195,900. Fast
glmer cloglog hierarchical fit: forest-type RE sd 0.60 and ecoregion RE sd 0.35 separate the mortality tails;
region management random-slope sd 1.21 shows the management effect is strongly heterogeneous, so a capped
constant is structurally wrong. Leave-one-region-out: the partially pooled management effect beats the capped
constant in 5 of 5 held-out regions. Verdict: hierarchical structure GO; NB/QC province verification pending
provincial data. Next step: full brms/Stan fit with SDImax asymptote prior + ingrowth, exact recent-FIA
holdout, then provincial transfer test.

Deliverable: 20260703_v13_kickoff_results.md. Scripts scripts/v130_height_anchor.R, v131_hier_assembly.R,
v131_hier_fit.R. Results results/v13_kickoff/. Fitted objects on Cardinal ~/v13_kickoff/. Coordinates never
left the node.
