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
| Site input | ESI via make_stand(esi=) | tracks measured site index far better than legacy CSI (R^2 0.91 vs 0.52); drop-in, no equation change. Current ESI is a placeholder pending the refined ESI |
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
| NB / NS / ME regional (270 plots) | all-region BA +3.3%, value +4.1%; 12.5.0 to 12.6.0 halved the over-prediction |
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
- Regional mortality (gate 1) advanced and localized. A regional mortality multiplier works
  two-directionally on the regional data (New Brunswick mult 0.5 nearly zeros its bias; Maine
  improves with more mortality), but even Maine mult 3.0 leaves +7.3 percent: the residual is
  structural, the stand-mortality probability cut zeros mortality on Maine stands that should
  self-thin. The release fix is a regional refit of the stand-mortality probability, not a
  multiplier. Interim: Maine mult about 1.5 to 2.0, New Brunswick about 0.5. See
  `20260629_esi_anchor_and_regional_mortality.md`.

## Path to release

12.6.1 is the documented production candidate now. The next production version should fold in the
refined ESI (with ESI-anchored dominant height) and the regional mortality recalibration, then re-run
this same validation suite (the harnesses are in `scripts/`). Documentation triad: benchmarking HTML,
user guide, variant GTR, all referencing this spec.
