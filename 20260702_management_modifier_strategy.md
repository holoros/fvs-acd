# Strategic plan for FVS-ACD management modifiers, grounded in the G&Y book Chapter 11

*2 July 2026. How to build the management (planted, PCT) modifiers strategically per Weiskittel, Hann,
Kershaw and Vanclay (2011), Forest Growth and Yield Modeling, Chapter 11 (Modeling Silvicultural
Treatments), rather than as a crude treatment dummy. FVS-ACD never had these; they were meant to be a
shared project but the managed calibration data was never shared, so they are built here from the data
Aaron holds (FIA treatment and stand-origin codes, MagPlot management group, the PSPs). Plaintext math, no
em dashes.*

## The three principles from Chapter 11 that govern this

1. Direct versus indirect effect (Miller and Tarrant 1983). A treatment produces a direct effect (the
   response due to the treatment itself) and an indirect effect (the response due to the altered stand
   structure the treatment created). The base FVS-ACD equations already capture the indirect effect,
   because after a PCT the stand carries lower BAL, RD, and BA and the untreated equations respond to that.
   The modifier must characterize only the DIRECT effect, or it double counts. This is the central design
   rule.
2. Use the modifier approach, multi-step (approaches 3 and the multi-step method, Wang 1990). Keep the
   existing untreated FVS-ACD equations fixed. For the managed benchmark stands, predict the untreated
   diameter growth, height growth, and mortality from the treated stand's own predictors, take the
   difference between observed managed response and predicted untreated response, and fit the modifier on
   that difference. This isolates the direct effect, avoids re-fitting and ill-conditioning the base
   equations, and is the recommended route when treatment data are limited. It also mirrors the code
   architecture, which already has gated thinning and budworm modifiers; those are the template.
3. Classify each treatment Type 1 or Type 2 (Snowdon 2002; Nilsson and Allen 2003). This decides the
   modifier form:
   - PCT (precommercial thinning) is a Type 1 response: a transient release and thinning shock whose direct
     effect decays with time since treatment. Model it with a DURATION term (years since treatment, or
     accumulated top-height or increment since treatment), so the direct boost fades and the stand returns
     to the untreated trajectory as the indirect density effect takes over. A modifier with no duration term
     wrongly assumes the effect is permanent.
   - Planted origin and any genetic gain is a Type 2 response: a sustained productivity change. Model it as
     a site-index or dominant-height modifier, or a sustained multiplier, carried through the whole
     projection (Chapter 11.2: modify site index after Nance and Wells 1981, or a genetic-gain multiplier
     after Carson 1999 and Gould 2008).

## Modifier form by component

- Diameter growth and height growth: multiplicative modifier on the untreated increment. For PCT, m_pct =
  f(time since treatment) that starts above 1 and decays to 1 (Type 1). For planted, either a sustained
  site-index bump (Type 2) or a small sustained multiplier. Calibrate on the difference-from-predicted-
  untreated response.
- Mortality: do NOT apply a multiplicative modifier to the logistic mortality function; the chapter warns
  this distorts the asymptotic behavior. Instead incorporate the management indicator (and time since PCT)
  as a predictor inside the mortality model, or apply the direct effect as an additive hazard adjustment.
  PCT lowers density-independent mortality briefly then returns to baseline.
- Ingrowth: managed stands (planted, PCT) recruit differently; a management term on the ingrowth rate,
  consistent with the observed managed recruitment.

## Data Aaron can use without Hennigar's shared set

- FIA: TRTCD (treatment codes, includes thinning and site prep) and STDORGCD (stand origin, planted vs
  natural), plus remeasurement, give managed-versus-unmanaged pairs across ME, NH, VT.
- MagPlot: the management group field (None, Partial Cut, Recent Clearcut, PCT, Planted) already used in
  the benchmark strata.
- NB and NS PSPs and the PEF study installations carry treatment histories.
These give enough managed pairs to fit a direct-effect modifier by the multi-step method, independent of
the data that was never shared.

## Strategy toward the meeting

Build the PCT (Type 1, duration-decaying, multiplicative) and planted (Type 2, sustained) modifiers by the
multi-step direct-effect method, add them to v12.9.x as gated ops modifiers alongside the existing thinning
and SBW modifiers, and re-score. This is the principled version of the OSM management term, and it is
defensible in the meeting precisely because it follows the framework in Aaron's own book chapter rather
than a black-box dummy. If the direct-effect fit is data-limited for a given treatment, fall back to the
third-approach fixed-untreated modifier calibrated on whatever managed pairs exist, and say so.

## Note

The thinning and fertilization sections of Chapter 11 (later in the chapter) give the specific model forms
for the PCT duration decay and should be consulted when fitting; the framework above (direct effect,
multi-step, Type 1 versus Type 2, multiplicative for growth and predictor-embedded for mortality) is the
strategic core.
