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

## Path to release

12.6.1 is the documented production candidate now. The next production version should fold in the
refined ESI (with ESI-anchored dominant height) and the regional mortality recalibration, then re-run
this same validation suite (the harnesses are in `scripts/`). Documentation triad: benchmarking HTML,
user guide, variant GTR, all referencing this spec.
