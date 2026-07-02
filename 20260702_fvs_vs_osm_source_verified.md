# FVS-ACD vs OSM: source-level verification of the component differences

*2 July 2026. Follow-on to 20260702_fvs_vs_osm_component_comparison.md, promoting the inferred component
table to what is verifiable at the source level against both code trees. FVS-ACD is fully readable R
(AcadianGY_12.9.0.r / 12.10.r). OSM v2.26.1 is distributed as a compiled binary, not open source, so the
OSM side is verified from the one exposed model artifact plus its documentation and its projection
behavior. Plaintext math, no em dashes. Aggregates only; coordinates stayed on Cardinal.*

## What OSM actually ships as

OSM v2.26.1 (~/OSM/v2.26.1/OSMv2.26.1_Linux64) is a compiled .NET console application (OSM.ConsoleApp,
SQLite.Interop.dll), not source code. There is no public OSM-Contributors source tree to clone for the
component equations; the equation logic is inside the compiled binary. One model artifact is exposed on
disk as a plain CSV:

  DiameterGrowth/DBHGrowthModel_NL_CRH2024_RF_GoodSite_2024Feb06.csv

This single file is decisive for the central question, because its columns are the model's own inputs.

## The verified finding: OSM carries an explicit management covariate; FVS-ACD does not

The OSM diameter-growth table has exactly these columns (15,681 rows):

  Species, Age, BA, BAL, DBH, IsManaged, IsGoodSite, Response

Three source-level facts follow directly, no inference:

1. OSM diameter growth carries an explicit binary management covariate, IsManaged. This is the management
   term we hypothesized. It is present in OSM and absent from every base equation in FVS-ACD v12. Verified
   on both sides: the OSM column exists; a full grep of AcadianGY finds no management or stand-origin
   predictor in the diameter-growth, height, mortality, or ingrowth base equations (only the gated
   commercial-thinning and spruce-budworm modifiers, which are off in the benchmark).
2. OSM diameter growth is a tabulated Random Forest (the file name carries RF, and the 15,681-row
   Species x Age x BA x BAL x DBH x IsManaged x IsGoodSite grid returning a Response is a discretized RF
   surface), i.e. a black box. FVS-ACD diameter growth is the parametric Kuehne et al. 2022 equation
   (coefficients match Table 6 exactly). This is the transparency contrast, now source-confirmed.
3. OSM handles site in diameter growth as a binary IsGoodSite class. FVS-ACD uses a continuous ESI site
   term. OSM's site signal in diameter growth is coarser; FVS-ACD's is continuous and climate-ready.
   (Consistent with the bake-off finding that the site metric barely moves diameter growth: a binary split
   captures most of the small diameter-growth site signal.)

The table is labeled CRH2024 (Hennigar 2024), newer than the 2010 to 2014 vintage of the FVS-ACD base
components, confirming the calibration-vintage gap as well.

## Verified component table

| component | FVS-ACD v12 (R source, verified) | OSM v2.26.1 (verified where marked) | management covariate |
|---|---|---|---|
| diameter growth | parametric Kuehne 2022; predictors DBH, CR, BAL, pBAL.SW, BA, RD, ESI; no mgmt term | tabulated Random Forest; predictors Species, Age, BA, BAL, DBH, IsManaged, IsGoodSite (SOURCE-VERIFIED) | OSM yes (verified), FVS no (verified) |
| height (H-D) | parametric; DBH, BAL, CCF, ESI (Rijal 2012); no mgmt term, no local-calib | documented: Zone, DBH, BA, QMD, BAL, plus a local-observation calibration routine and management (documentation, not source-exposed) | OSM yes (documented), FVS no (verified) |
| height growth | parametric; HT, CR, BAL.SW, BAL.HW, BA, ESI (Russell 2014) | deduced from DBH growth and H:D (documentation) | not exposed |
| mortality | Zone, BA, dBA, QMD, BA.BF, BA.IH, DBH; no mgmt term (verified) | documented: Zone, DBH, BA, QMD, BAL, management (not source-exposed) | OSM yes (documented), FVS no (verified) |
| ingrowth | BA.species, HWBAR, TPH, QMD, ESI; no mgmt term (verified) | documented: same plus management and density modifiers (not source-exposed) | OSM yes (documented), FVS no (verified) |
| self-thinning | v12.9 composition- and ecoregion-aware coupled SDImax, two-segment RD mortality (verified in R) | documented Woodall 2005 BA-weighted wood-specific-gravity max stocking; not source-exposed | n/a |

Two claims are now source-verified on both sides (the management covariate in diameter growth, present in
OSM and absent in FVS-ACD; and the RF-versus-parametric transparency contrast). The management terms in
OSM height, mortality, and ingrowth are documented in Hennigar and Weiskittel 2018 and consistent with the
verified diameter-growth column, but the compiled binary does not expose those tables, so they are marked
documentation-level rather than source-verified. Honest labeling for the meeting.

## Local-observation calibration (height)

OSM's height model includes a routine that nudges predictions toward local observations (documented; not
source-exposed in the binary). FVS-ACD has no such hook in the base. This is the second OSM operational
advantage and motivates the optional local-calibration hook in the v13 roadmap (off by default, so the
base benchmark is unaffected).

## Self-thinning and long horizon (behavioral verification)

The binary exposes no self-thinning table, but the long-horizon behavior is verified empirically from the
matched Seven Islands run: OSM does not plateau (matched stands climb basal area 32 to 42 m2/ha over 60
years with no self-thinning), while FVS-ACD v12.9.x self-thins to a realistic Acadian maximum and passes
the Bakuzis relations. On the operational short-interval domain the two agree; the divergence is a
long-horizon phenomenon driven by self-thinning, exactly as the component reading predicts.

## Bottom line for the meeting

At the source level, the single most important difference is confirmed: OSM carries a management covariate
(IsManaged) in its diameter-growth model and FVS-ACD v12 does not. This is the specific, verifiable reason
OSM is competitive on the heavily managed operational benchmark, and it is precisely the gap the Chapter-11
strategic management modifiers in v12.10 are built to close (see 20260702_management_modifier_scorecard.md).
OSM's edge is a management term and a coarse-but-effective site split plus a local-calibration hook, not a
better growth engine; FVS-ACD keeps the transparent parametric core, the continuous climate-ready site
driver, biological realism, and QMD.
