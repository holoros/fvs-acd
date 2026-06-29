# FVS-ACD site-driver modernization: workstream charter

*Opened 27 June 2026. This work grew out of the BGI/CSPI independent validation and has become its own effort: replacing the 15-year-old ACD_CSI climate site index that drives the Acadian variant of FVS with the modern unified-target ESI, and doing it through a robust hierarchical site sub-model. Documented here so it can run as a dedicated session rather than continuing to drift inside the CSPI manuscript work.*

## Why this is its own workstream

The CSPI manuscript asks whether forest productivity is multi-dimensional and validates the surfaces as site potential. That question is essentially answered. The FVS-ACD question is different and operational: given a better modern site surface, where and how should it enter a production growth-and-yield model. The two share data and the ESI surface but have different deliverables, audiences (a journal vs the FVS code base and its users), and timelines. Keeping them separate keeps each clean.

## What is already established (carried over from the CSPI session)

1. **Tree-level growth carries no usable site signal beyond size and competition.** Across ~216,000 trees, neither ACD_CSI nor any modern surface (ESI, BGI, Asym) adds more than 0.001 to the adjusted R^2 of individual-tree diameter or height increment once DBH or height plus BAL and CCFL are present. So the migration should not touch the tree-level growth equations, and a tree-level site modifier is not warranted.
2. **The modern ESI predicts measured site index far better than ACD_CSI.** Head-to-head against measured site index: ESI R^2 0.91, RMSE 1.4 m; ACD_CSI R^2 0.52, RMSE 3.2 m (small matched sample, n = 49; realistic out-of-sample ESI is the spatially blocked 0.46 to 0.55, still at or above ACD_CSI).
3. **An ESI-anchored dominant-height curve works as well as one anchored on measured site index.** A base-age Chapman-Richards fit on 337,680 site-tree records explains 80 percent of dominant-height variance with ESI as the anchor (RMSE 2.45 m), identical to the measured-SI anchor and far above a no-site guide curve (R^2 0.17). The anamorphic single-shape fit leaves a systematic age-residual trend (under-prediction near mid-rotation, over-prediction in old stands), which signals the production form should be polymorphic.

The supporting memos and scripts are in `bgi-cspi-conus/v5/maine_cfi/` (fvsacd_site_migration_finding.md, esi_anchored_height_result.md, acdcsi_vs_esi_headtohead.csv, and the R scripts).

## The model: hierarchical, the robust approach

Per the preference for hierarchical random effects, the production dominant-height sub-model is a GADA (generalized algebraic difference) Chapman-Richards with the modern ESI as the site anchor and crossed random effects for **species** and **ecoregion**:

- Fixed form: a polymorphic Chapman-Richards in which the site variable enters both asymptote and rate, with the modern ESI providing the site level.
- Random effects: species (fvs_ne_var / SPCD) and Level 3 ecoregion on the shape parameters, so the curve shape varies by species and by region while the level is set by ESI. Fit with nlme (nested) or lme4/nlmer (crossed) on the harmonized height-age data.
- Validation: spatially blocked (one-degree or ecoregion blocks) out-of-sample R^2, RMSE, and projection-bias by horizon, plus a Bakuzis-style biological-realism check (site ordering, no curve crossing). The present fit is in-sample because ESI was trained on the same compilation, so the blocked validation is required before adoption.

## Implementation path into FVS-ACD

- Target: the Acadian (ACD) variant of FVS in `github.com/MidgardNaturalResources/ForestVegetationSimulator` (a Fortran fork of USDAForestService/ForestVegetationSimulator; the June 2026 PR "FVS interface updates for ADK, ACD and HI" shows the variant is actively maintained toward the summer 2026 release).
- Where it enters: the dominant-height / site-index routines of the ACD variant, not the diameter-growth routines. The migration re-anchors the height trajectory and the site-index input; the large-tree and small-tree diameter-growth equations are left unchanged.
- Form of the change: replace the ACD_CSI site-index input with the ESI-derived site index, and update the dominant-height curve coefficients to the new hierarchical fit. If backward compatibility is needed, a mapping from ACD_CSI to the new ESI site index can be published as a transition aid.

## Recommended next steps for the dedicated session

1. Assign Level 3 ecoregion to every plot (point-in-polygon against `NA_Eco_L3` on Cardinal) and attach species, to build the hierarchical fitting frame.
2. Fit the hierarchical GADA Chapman-Richards (species and ecoregion random effects, ESI anchor); compare to the anamorphic baseline and to ACD_CSI-anchored.
3. Spatially blocked out-of-sample validation and projection-bias-by-horizon; Bakuzis realism check.
4. Translate the fitted curve into ACD-variant coefficients and draft the code change against the Midgard FVS fork.
5. Coordinate with David Diaz (Midgard) on the upstream PR timing, since he holds the fork and the active ACD interface work.

## Status

Workstream opened and documented. First analysis (hierarchical fit) staged in this session. Decision for Aaron: run this as a dedicated FVS-ACD session going forward rather than inside the CSPI thread.
