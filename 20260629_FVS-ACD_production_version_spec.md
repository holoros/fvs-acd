# FVS-ACD production version specification: AcadianGY 12.6.1

*29 June 2026. The authoritative definition of the proposed production version, referenced by the
benchmarking HTML, the user guide, and the variant GTR. Plaintext math, no em dashes.*

## Production candidate

AcadianGY 12.6.1 (`scripts/AcadianGY_12.6.1.r`), built on the 12.5.0 production refactor, with the
12.6.x refinements. It reproduces 12.5.0 bit-for-bit when every refinement flag is in its legacy
position (verified: max difference 0 on 73 Seven Islands plots), so the refinements are cleanly
isolated and individually validated.

## Recommended operational configuration

| setting | value | rationale |
|---|---|---|
| Site input | validated ESI (Final_SI_Output.tif) via make_stand | matches measured site index (R^2 0.91) and anchors dominant height (R^2 0.804). On a controlled full-set test it matches legacy climate SI on regional volume and value (so the gain is in dominant height and biological realism, not bias); drop-in, no equation change |
| SDImax | site-independent (ops$sdimax.site.term = FALSE) | brms re-estimation shows SDImax is independent of site (r near 0); composition-driven |
| Self-thinning | ops$use.sdimort = TRUE, onset 0.55, beta 0.10, max 1.0 | SDImax-ceiling density-dependent mortality; inert below the frontier, steepens self-thinning toward Reineke where it binds |
| Ingrowth | ops$use.ingrowth = TRUE, ingrowth.thrshld = 0 (expected value), mult 1.0 | the statistically correct hurdle mean; fixes the recruitment deficit |
| MORTCAL | ops$use.mortcal = FALSE | optional empirical BA corrector; trades stem-count accuracy, off by default |
| Mortality | Weiskittel et al. (2012), regional | reverted-to baseline; flagged for regional recalibration (see residual risks) |
| Cycle length | 1 year | |
| Region | ME / NB / NS / QC | selects regional mortality and SBW parameters |

To reproduce 12.5.0 exactly: use.sdimort = FALSE, sdimax.site.term = TRUE, use.mortcal = FALSE, no
esi, ingrowth.thrshld = 0.95.

## Validation summary

| dataset | result |
|---|---|
| Seven Islands CFI (65 long-horizon pairs) | BA bias +11% (MORTCAL off) to -1% (on); self-thinning slope -1.08 to -1.24 |
| Maine FIA (694 pairs, 5-7 yr) | site a weak BA lever (legacy = ESI); stem-count deficit (TPA -8%, QMD +7%) |
| NB / NS / ME regional (full 682-plot set) | all-region BA +1.4%, value +1.5%; Maine +4.9 / +7.6; NB -1.7 / -3.3; NS +3.0 / +2.3. ESI and legacy site index identical here (controlled). The earlier +11% Maine BA was a 90/region subsample, not representative |
| Global sensitivity (N=240) | value dominated by site (SRC 0.80); ingrowth drives stems/QMD not value; self-thinning params globally minor |
| Bakuzis matrix | Eichhorn PASS (CV 5.1%); self-thinning improved but short of Reineke; height site-curves weakly separated |
| Version evolution | v9.6 +17% -> v12 line +11% -> v12.6 +3% (regional): monotone improvement |
| OSM head-to-head | large long-horizon divergence (BA 25 vs 40 at age 80); model-form uncertainty |

## Known residual risks (the next-version agenda)

1. Regional mortality is mis-calibrated: the increment-vs-mortality decomposition shows Maine
   under-grows diameter (-14.5%) yet over-predicts BA (+11%) and stems (+10%), a mortality deficit;
   New Brunswick is the mirror. Recalibrate the regional stand-mortality parameters. This is the
   single highest-leverage fix for the operational over-prediction.
2. Diameter increment has a size-form bias (over-grows < 10 cm by +14%, under-grows 30+ cm by -13%)
   and under-predicts at high density (-19% at RD 0.8+); a dDBH refit is warranted.
3. Site-curve separation is weak (height barely responds to site index); the refined ESI and the
   ESI-anchored dominant-height prototype (v12.6.2) address this.
4. Long-horizon BA carries first-order model-form uncertainty (the OSM divergence); driven by 1-3.
5. The ESI surface is a placeholder pending the refined ESI; swapping it is a data change, no code.

## Update (29 June, later): two release gates advanced

- ESI dominant-height anchor (gate 2) solved. The fitted Chapman-Richards anchor (k = 0.0039,
  p = 0.726, base age 50; ESI v8) is wired into `AcadianGY_12.6.2b_proto.r` and validated: site
  curves pass through ESI at age 50 and stay cleanly separated and ordered at all ages (site 8/14/20
  reach 7.8/14.4/20.2 m at 50, 13.7/24.4/34.5 m at 120). ESI matches measured site index for
  dominant-height prediction (R^2 0.804 vs 0.174 no-site). The next production version should adopt
  ESI as the site driver with this anchor; the placeholder caveat is retired for the anchor
  relationship.
- Regional mortality (gate 1) advanced and fully localized. Two independent regional levers were
  swept on the 270-plot data: the tree-level mortality multiplier (Maine +11.1 at 1.0 to +7.3 at 3.0)
  and a new gated stand-mortality cut scale (`ops$mort.cut.scale` in `AcadianGY_12.6.4.r`; Maine +11.1
  at 1.0 to +7.9 at 0.4). Both saturate at about +7 to +8 percent Maine BA bias and both push New
  Brunswick the wrong way. The saturation proves each lever alone cannot reach the stand basal-area
  loss Maine needs. But the levers are complementary: combining them (Maine stand cut 0.5 plus
  multiplier about 2.0) brings Maine BA from +11.1 to +2.6 and stems from +10.0 to ~0, while New
  Brunswick (mult 0.5) sits at -1.0 and Nova Scotia at baseline, so a region-specific two-lever setting
  holds all three regions within a few percent on BA and TPA at once. The gated levers (v12.6.4)
  deliver this as an interim, in-sample calibration; the release-grade fix is a cross-validated
  regional refit of the Weiskittel (2012) stand-mortality coefficients carrying the same
  admit-plus-magnitude behavior. Both levers ship gated (default off / scale 1.0 reproduces 12.6.1).
  See `20260629_esi_anchor_and_regional_mortality.md` and
  `figures/acadgy_mortality_lever_saturation.png`.

## Update (29 June, later still): validated-ESI rerun and full-set validation

Two corrections from wiring the validated ESI (`Final_SI_Output.tif`) in as the driver and running the
full 682-plot set instead of a 90-per-region subsample (see `20260629_ESI_rerun_and_fullset_validation.md`):

- ESI equals legacy climate SI on regional volume and value (controlled, identical plots: all-region
  BA +1.4 percent under both; Maine +4.9 under both). The ESI is adopted as the production driver for
  its dominant-height and biological-realism gains, not for any volume or value improvement.
- The full-set production bias is well-calibrated: all-region BA +1.4 percent, value +1.5 percent;
  Maine +4.9 / +7.6, NB -1.7 / -3.3, NS +3.0 / +2.3. The +11 percent Maine BA that drove the mortality
  investigation was an unrepresentative subsample; the stable Maine residual is +4.9 percent. The
  aggressive interim mortality setting (Maine cut 0.5 + multiplier 2.0) over-corrects on the full set
  and is withdrawn; Maine needs at most a mild multiplier (about 1.3 to 1.5), and the principled
  coefficient refit is now a modest +5 percent target. The larger Maine value residual (+7.6 percent
  vs +4.9 percent BA) is the diameter size-form bias, which is the higher-leverage remaining item.

The data-quality note `20260629_ESI_raster_data_quality_note.md` records that the AcadianSIm climate
surfaces (a separate future-climate product, not the driver) have a render bug: the 2090 file is a
byte-identical duplicate of 2030.

## Update (30 June): full-metric validation of 12.7.0 (ESI v8)

Predicted vs observed on the full 682-plot regional set, all-region percent bias: basal area +2.0,
SDI +1.6, QMD +1.0, top height +0.5, total volume +1.8, merch volume +2.2, sawlog +2.5, value +2.2.
Every operationally relevant metric is within a few percent; top height and SDI are the tightest (the
ESI anchor and self-thinning). Maine is the residual (+5 to +8, amplifying along the product chain),
New Brunswick near zero, Nova Scotia +1 to +4. Independent MAGPlot NB CFI (262 pairs): BA -2.6, R2 0.87.
OSM on the same MAGPlot plots: both near-unbiased at observed intervals (FVS-ACD -2.6, OSM -2.3). Bakuzis
on 12.7.0 projections: site ordering 0/125 inversions, Reineke -1.28 to -1.35 OK, Eichhorn moderate flag.
See `20260630_v1270_full_metric_validation.md`, `20260630_v1270_magplot_and_bakuzis.md`.

## Update (1 July): v12.9, a targeted SDImax gate for the Quebec hardwood edge

The four-model scorecard (v12.5.0, v12.7.0, v12.7.1, OSM v2.26.1, `20260701_four_model_scorecard.md`)
localized 12.7.1's one remaining structural gap: hardwood-dominated stands outside the Acadian-core
ecoregion, concentrated in Quebec. AcadianGY 12.9.0 (`scripts/AcadianGY_12.9.0.r`, built on 12.7.1) adds
a gated multiplier to the Weiskittel and Kuehne (2019) SDImax equation (section 3.5), active only when a
stand is simultaneously:

1. Province Quebec (`stand$region == "QC"`).
2. Ecoregion outside the Acadian core. Acadian core is defined as the CEC North American Level III
   ecoregions Acadian Plains and Hills and Maritime Lowlands; outside includes Northern Appalachian and
   Atlantic Maritime Highlands, Algonquin and Southern Laurentians, Central Laurentians and Mecatina
   Plateau, and Eastern Great Lakes Lowlands.
3. Forest type hardwood-dominated, by BA-weighted dominant `sp.attr$sp.grp.ingrowth` group (sugar maple,
   birch, aspen, other hardwood, American beech).

Implementation: `ops$sdimax.region.mult` (named vector by province, default all 1.0) and
`ops$sdimax.fortype.tight.mult` / `ops$sdimax.fortype.tight.groups` / `ops$sdimax.fortype.region`
(the gate, keyed on a combined province-ecobucket string, e.g. `"QC_OTHER_ECO"`). With every flag unset
or at its default, 12.9.0 reproduces 12.7.1 exactly; this is a gated, isolated refinement in the same
convention as every prior version. Recommended setting: `sdimax.fortype.tight.mult` 0.65 to 0.70,
gated on `"QC_OTHER_ECO"` for the hardwood group above.

Validation (in-domain, n = 733; independent recent Maine FIA, n = 788; full detail
`20260701_v129_full_validation.md`, `20260701_v129_ooda_stress_test.md`):

- Target cell (Quebec, outside Acadian core, hardwood-dominated, n = 163): total volume bias closes from
  +56.7 to +10.4 percent, stand value from a similar magnitude to +4.4 percent. Basal area, already
  under-predicted, deepens further (-9.3 to -18.1 percent), the same relative-density trade-off seen
  throughout this development line, now confined to exactly the population that needed correcting.
- New Brunswick: unchanged from 12.7.1 in every metric, to the decimal, since the gate structurally
  excludes it.
- Recent Maine FIA growing-stand stratum: unchanged from 12.7.1 (BA level -2.2 percent, annual increment
  -0.085 m2/ha/yr), since no Maine plot can satisfy a Quebec-only gate. This was not automatic; an
  earlier, broader gate (ecoregion alone, no province term) passed the Quebec target but measurably
  worsened this independent check (annual increment to -0.135 to -0.151 m2/ha/yr, -83 to -93 percent)
  before the province term was restored. The independent FIA cross-check is what caught this.
- Split-half robustness (163-stand target cell, two random halves): consistent correction magnitude in
  both halves, not driven by a handful of stands.

Known residual: a seeded 160-year trajectory of the corrected hardwood population plateaus at about 21
m2/ha, below the realistic 28 to 32 m2/ha target for that composition (the same composition uncorrected
plateaus at 31 to 32). A correction calibrated on a 5 to 15 year window, carried through a full rotation,
under-shoots. v12.9 is recommended for short-to-mid rotation inventory projection; 12.7.1 remains the
recommended version for carbon and old-growth work until a tapered version of the correction (relaxing
toward the true asymptote rather than a flat multiplier) is fit.

## Path to release

12.9.0 is the current recommended version for inventory-horizon use; 12.7.1 remains recommended for
long-horizon carbon and old-growth work pending the tapered correction. Documentation triad: benchmarking
report, variant GTR, and the August Hennigar deck, all now updated and referencing this spec.
