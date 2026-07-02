# Pre-meeting brief: FVS-ACD and OSM on harmonized Acadian data

*For Chris Hennigar and the Acadian growth-and-yield group, ahead of the 18 August 2026 meeting at CFS
Fredericton. Aaron Weiskittel, University of Maine. Plaintext math, no em dashes. This brief carries
aggregates only; plot coordinates stayed on the analysis cluster.*

## Purpose

Chris asked for input toward the agenda. This is a short summary of where the FVS-ACD work stands against
OSM, what an independent re-derivation of the 2018 benchmark shows, the site-productivity finding, the
harmonization approach, and the open questions I would like the group to weigh in on. The fuller version is
the deck (FVS-ACD_Hennigar_Aug2026.pptx).

## 1. The independent re-derivation

I was never fully confident in the 2018 ECANUSA benchmark, so I rebuilt it as an independent re-derivation
rather than a reproduction, on data that is independent of the model training. The frame is deliberately
even-handed: independent in-domain MagPlot New Brunswick and Quebec remeasurement pairs (n=705, NB 355, QC
350) plus recent Maine FIA (n=788, out of time from the 1999 to 2005 training FIA); every volume and biomass
metric put on FIA NSVB; and one metric-computing function applied identically to observed and to every
model. Five models are scored: FVS-ACD v12.5.0 (the incumbent), v12.7.0, v12.7.1, v12.9.x (the operational
version), and OSM v2.26.1.

Headline: pooled level bias and out-of-sample modeling efficiency (Nash-Sutcliffe) are close for the two
mature models. On total volume, OSM is +1.6 percent (NSE 0.75) and FVS-ACD v12.9.x is +2.7 percent (NSE
0.71). On the New Brunswick core (the in-domain growing and managed stands), FVS-ACD v12.9.x matches or
slightly beats OSM on the integrators: total volume -7 vs OSM -8, biomass -4 vs -6, value -7 vs -9. The 2018
conclusion that OSM clearly beat FVS-ACD does not replicate on independent in-domain data scored with a
common volume system.

One honest correction to my own earlier read. An interim scorecard reported OSM with negative modeling
efficiency (which would have meant OSM was imprecise). On a clean, aligned data merge that was a join
artifact: OSM's true NSE is positive (0.70 to 0.75) and its short-interval accuracy is genuine. I want the
group to have the corrected version, not the flattering one. It does not change the recommendation, but it
changes the reason: FVS-ACD's advantage over OSM is not precision.

Where FVS-ACD does differ, and why it matters:
- Quadratic mean diameter. OSM over-predicts QMD by about 11 percent (it grows diameters too fast and
  under-recruits small trees). FVS-ACD holds QMD to about 1 percent.
- Biological realism. On seeded 160-year projections across a site gradient, v12.7.1 and v12.9.x pass all
  five Bakuzis relations, including a Reineke self-thinning slope of -1.59 (target near -1.6) and a basal
  area that plateaus at the realistic Acadian maximum. v12.5.0 never self-thins (basal area runs to 65
  m2/ha). OSM also does not plateau (Seven Islands matched stands climb 32 to 42 m2/ha over 60 years).
- Transparency and climate-readiness. FVS-ACD is open R, uses FIA NSVB, and is driven by the validated ESI
  site surface, which gives a defensible forward-climate path.

The fair verdict: on the operational inventory domain the two models are close, so choose by use. For
short-rotation inventory accuracy, OSM or FVS-ACD v12.7.0 are strong. For long-horizon carbon, old-growth,
and climate work, FVS-ACD v12.9.x is the better tool because it is the only one that is biologically
realistic over a rotation. The cost of v12.9.x is a mild under-prediction of basal area on fast-growing
stands (-6 to -9 percent) and a top-height anchor that still runs about 9 percent high.

I also added two rigor upgrades the group may find useful as a shared standard. Equivalence testing (two
one-sided tests, Robinson and Froese 2004) asks whether predictions are statistically equivalent to observed
within a stated region (level plus or minus 10 percent, increment plus or minus 25 percent), which is a
stronger claim than a non-significant bias. Within plus or minus 10 percent on the nine level metrics, OSM
is equivalent on 8, v12.9.x and v12.7.1 on 6, and the older versions on 3. And the Bakuzis relations are now
reported individually per model with a quantitative pass or flag, not just a summary.

## 1b. The Chapter-11 management modifiers (the lever to close the operational gap)

A source-level comparison this week made the reason for OSM's residual edge concrete. OSM ships as a
compiled binary, but its diameter-growth model is exposed on disk as a table whose own input columns are
Species, Age, BA, BAL, DBH, IsManaged, IsGoodSite. That IsManaged column is verified at the source level:
OSM carries an explicit management covariate in diameter growth, and FVS-ACD v12 has no management term
anywhere (only the gated commercial-thinning and budworm modifiers, off in the benchmark). The independent
benchmark is heavily managed, so that one term is the specific reason OSM is competitive there.

I built the FVS analogue as a principled modifier, not a black-box dummy, following the framework in our own
book chapter (Weiskittel, Hann, Kershaw and Vanclay 2011, Ch 11, Modeling Silvicultural Treatments). The
base untreated equations already carry the indirect structural effect of a treatment (lower BAL, RD and BA),
so the modifier isolates only the direct effect, by the multi-step method (Wang 1990): predict the untreated
increment from each managed stand's own predictors and calibrate on observed minus predicted. Planted origin
is a Type 2 sustained response (a sustained diameter-growth multiplier); precommercial thinning is a Type 1
transient response (a multiplicative boost that decays with time since treatment). Mortality deliberately
does not get a multiplicative modifier, which would distort the logistic asymptote.

Scored by management class on the independent MagPlot set, the modifiers (v12.10) close the managed-stand
gap to OSM. Managed total-volume level bias goes from -9.9 percent (v12.9.x) to -1.6 percent (OSM -7.4), and
mean absolute bias across nine metrics from 10.2 to 4.8 (OSM 8.3). On planted stands v12.10 clearly beats
OSM (total volume -4 vs OSM -20). Unmanaged stands are untouched, so this is a targeted lever, not a global
mortality bump. The modifier is gated and default off, so v12.10 with the gate off is identical to v12.9.x.
Caveat for the group: the managed calibration data are thin (planted n=51, PCT n=95) and the PCT decay rate
is a nominal Type-1 value rather than a cleanly fitted one, so this is a defensible near-term lever that a
shared managed-remeasurement set (FIA TRTCD and STDORGCD, the provincial PSPs) would let us firm up.

## 2. Site productivity (agenda item 1)

I ran a site-variable bake-off, ESI vs BGI vs CPSI vs legacy CSI, isolating the site term with identical data
and model form and scoring out of sample with spatially blocked cross validation. Two clean results.
Diameter growth is insensitive to the site metric (all four within 0.01 modeling efficiency), so there is no
case to switch on DG grounds. For the dominant-height anchor, ESI wins (anchor EF 0.335, and it tracks
measured site index best, correlation 0.667 vs 0.488 for CSI, 0.156 CPSI, 0.020 BGI). BGI and CPSI carry
essentially no dominant-height signal and are the wrong scale to drive a multiplicative height anchor.

The concrete diagnostic I want to put in front of the group is that the ESI-driven anchor over-predicts
dominant height at the domain edge: the height increment runs about 1.9 times too fast in New Brunswick and
6.4 times too fast in the Quebec edge, where old near-asymptote stands sit on the steep part of the curve.
This is an anchor extrapolation problem, not a property of ESI as a predictor, and no alternative metric
fixes it. The fix is domain restriction plus an increment-consistent anchor recalibration (v13), not a
metric swap.

## 3. Data harmonization (agenda item 2)

The benchmark is itself a harmonization exercise. Recent Maine FIA, MagPlot QC and NB, NB and NS PSP, and
SILC are reduced to one comparable frame, and every model's tree list is scored with the same FIA NSVB
emulator so that differences are model differences, not volume-equation or schema differences. NSVB volume
and biomass are a natural common currency across the US and Canadian data. My question for the group is
whether we can formalize this: pool MagPlot, the provincial PSPs, and FIA under one harmonized schema with
NSVB as the shared metric.

## 4. Open questions I would like the group to discuss

- Site metric. Is a shared regional site driver feasible (ESI, or a provincial alternative), and can the
  provinces share the layers and the plots to fit and validate it across the border?
- Harmonization. Can MagPlot, the provincial PSPs, and FIA be pooled under one schema with NSVB volume and
  biomass as the common currency?
- Calibration standard. Would the group adopt a multi-dimensional scorecard (bias, precision, equivalence,
  Bakuzis relations) as the standard for comparing OSM, FVS-ACD, and the CFS national models, rather than a
  single bias number?
- Domain and the Quebec edge. Should we formally report the non-Acadian-core Quebec edge as out of domain,
  as the 2018 benchmark did by excluding Quebec?
- Climate. How should climate enter the site metric without breaking the validated base? My current view is
  a parametric, climate-sensitive dominant-height form rather than a random forest surface, which
  extrapolates poorly outside its training climate.

## 5. Logistics

I plan to attend in person. If CFS clearance for US citizens needs lead time, tell me what you need from me
and I will get it started.
