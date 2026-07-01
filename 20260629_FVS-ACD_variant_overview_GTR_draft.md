# Acadian (ACD) Variant Overview of the Forest Vegetation Simulator

**DRAFT variant overview / General Technical Report scaffold. 29 June 2026.**

*Structured after the USDA Forest Service Northeast (NE) Variant Overview (FVS Staff 2008, rev.
August 2023) so it can become the official FVS-ACD variant documentation. Equation content is drawn
from the Acadian GY Model Documentation (Weiskittel and team, 2025-05-20) and the AcadianGY 12.9.0
source, built on the 12.7.1 development line. AcadianGY 12.5.0 remains the current operational and
production version; 12.9.0 is the recommended forward version documented here, pending adoption.
Sections marked [POPULATE] need the full parameter tables or team text before publication. Plaintext
math, no em dashes; this draft will be rendered to a formatted Word/PDF GTR. Updated 1 July 2026 with
the three-model independent scorecard (v12.5.0, v12.9.0, OSM-ACD) and the v12.9.0 refinement.*

## Authors and Contributors

Aaron Weiskittel and the University of Maine Cooperative Forestry Research Unit (CFRU) developed the
Acadian growth-and-yield model. Ben Rice (Midgard Natural Resources) maintains the FVS-ACD
implementation and benchmarking. Component equations are credited to their authors throughout
(Kuehne, Russell, Rijal, Li, Chen, Castle, Cen, and others; see Literature Cited). This overview
documents the FVS-ACD variant as implemented in AcadianGY 12.9.0.

Suggested citation: Weiskittel, A., Rice, B., and contributors. 2026. Acadian (ACD) Variant Overview
- Forest Vegetation Simulator. CFRU / University of Maine, Orono, ME. [pages].

## Table of Contents

1. Introduction
2. Geographic Range
3. Control Variables (region codes, species, ecoregion, site index, maximum density)
4. Growth Relationships (height-diameter, bark, crown ratio and recession, crown width, CCF,
   diameter increment, height increment, stand basal-area increment)
5. Mortality Model
6. Regeneration and Ingrowth
7. Volume and Taper
8. Modifiers (thinning, spruce budworm, hardwood form and risk)
9. Model Application (site index rasters, cycle length, usage)
10. Version 12.6.x Refinements
11. Literature Cited
12. Appendices (species list, parameter tables)

## Quick Guide to Default Settings

| Parameter | Default |
|---|---|
| Projection cycle length | 1 year (FVS reporting frequency user-selectable) |
| Region code | ME (northern New England); also NB, NS, QC |
| Site productivity | Climate Site Index (CSI, m); modern ESI accepted in the same input (12.6.x) |
| Maximum stand density index | Composition-based, Weiskittel and Kuehne (2019); see 3.5 |
| Species | 37 Acadian species codes plus OH (other hardwood) and OS (other softwood) |
| Minimum DBH | 2.5 cm for height prediction; ingrowth threshold DBH user-set |
| Units | Metric internally (DBH cm, height m, BA m2/ha, TPH per ha) |
| Volume | Kozak variable-exponent taper; Westfall and Scott |

## 1. Introduction

The Acadian forest region comprises northern New England and Atlantic Canada, a transitional
mixed conifer and hardwood type between the northern hardwood forests to the south and the boreal
forest to the north (Loo and Ives 2003). The Acadian growth-and-yield model, developed by the CFRU
team led by Aaron Weiskittel, is the regionally specific model for this setting, and FVS-ACD is its
implementation in the Forest Vegetation Simulator framework. FVS-ACD differs from the FVS Northeast
(NE) variant in that its core growth, mortality, height, crown, ingrowth, and taper relationships
were fit on Acadian data (the Kuehne et al. 2022 increment equations alone used more than 2.5
million diameter and a million height observations), and it is driven by a climate-based site index
rather than a traditional site index. FVS-ACD is a one-year-cycle, individual-tree,
distance-independent model and, like other variants, supports the FVS extensions.

## 2. Geographic Range

The Acadian variant applies to northern New England (Maine, New Hampshire, Vermont) and Atlantic
Canada (New Brunswick, Nova Scotia) plus southern Quebec, the region for which the component
equations were fit. Region codes select the regional mortality and modifier parameters (ME, NB, NS,
QC). [POPULATE: range map figure, analogous to FVSne figure 2.0.1.]

## 3. Control Variables

### 3.1 Region codes

ME (default, northern New England), NB (New Brunswick), NS (Nova Scotia), QC (Quebec). Region selects
the regional parameter sets for stand and tree mortality and the spruce budworm modifier.

### 3.2 Species codes

37 Acadian species are parameterized (AB, AS, BA, BC, BF, BP, BS, BT, EC, EH, GA, GB, HH, JP, NS, PB,
PC, PR, QA, RB, RM, RN, RO, RP, RS, SB, SM, ST, TA, WA, WC, WP, WS, YB, plus OH other hardwood and OS
other softwood). Species not in the parameter set map to OH or OS by softwood/hardwood type.
[POPULATE: full species code table with scientific names, specific gravity, shade tolerance, and the
crown, increment, and mortality parameter sets, from sp.attr and the parameter tribbles.]

### 3.3 Habitat / ecological unit

FVS-ACD does not use habitat type codes; site productivity enters through the climate site index
(3.4). Level 3 ecoregion is available as an optional stratifier for maximum density (3.5).

### 3.4 Site index

The Acadian model uses Climate Site Index (CSI, m), a climate-and-soil-driven productivity surface
(Weiskittel et al. 2011), fit by random forest on seven climatic variables (most important: mean
temperature of the warmest month, the warmest-to-coldest month temperature difference, and the
growing-season-to-annual precipitation ratio). CSI is a user input and is available as raster
surfaces for current and future (2030, 2060, 2090) climate normals. CSI enters total height,
diameter increment, stand basal-area increment, height increment, mortality, ingrowth, and maximum
SDI.

Operational note (12.7.0): the production model uses the validated modern Ecological Site Index (ESI)
as the site driver, supplied through the same input slot. ESI tracks measured site index well
(R^2 0.91). A controlled full-set test showed ESI and the legacy climate site index give the same
regional volume and value (all-region basal-area bias +1.4 percent under both), so the ESI gain is not
in volume or value bias but in dominant-height behavior and biological realism: ESI anchors the stand
dominant height onto a fitted Chapman-Richards curve (k = 0.0039, p = 0.726, base age 50; section 4.1
note), which removes the Bakuzis height site-ordering inversions. The ESI surface is supplied as a
raster (Acadian ESI v8). The earlier AcadianSIm climate surfaces are a separate future-climate product,
not the operational site driver.

### 3.5 Maximum density (maximum SDI)

Stand density index is additive at the plot level, SDI = sum over trees of (DBH/25.4)^1.6 * TPH, with
DBH in cm and TPH per ha. Maximum SDI follows Weiskittel and Kuehne (2019), a composition- and
structure-based function:

    SDImax = 475.2079 - 1.5908*HW.ba.percent - 236.9051*log(meanSG) + 50.3299*sqrt(DBHrange)
             + 13.5202*spp.div + 0.0685*Elev - 2.8537*sqrt(Elev) + 222.7836*(1/CSI)

where HW.ba.percent is percent hardwood basal area, meanSG is basal-area-weighted mean specific
gravity (capped at 0.80), DBHrange is the plot DBH range, spp.div is species count, and Elev is
elevation (m). A fallback SDImax2 = 1347.445 - 1003.870*meanSG is used where the primary function is
undefined. Relative density is SDI/SDImax.

Version 12.6.x note: a brms re-estimation of plot-level SDImax across northern New England found
SDImax is essentially independent of site index (correlation with CSI and ESI near 0) and is
primarily a function of forest type (softwood ceilings near 1050 to 1100, northern hardwood near
900, wet hardwood near 750), which the composition terms above already approximate through mean
specific gravity. A site-independent SDImax (dropping the 222.78/CSI term, recentred) is available
behind a flag.

Version 12.9.0 note: a CONUS-scale brms re-estimation (independent of the northern New England one
above) confirmed forest type dominates the variance in plot-level maximum SDI (R-squared 0.21) far more
than site index alone (R-squared 0.02), and that a localized, forest-type-and-ecoregion-aware maximum
predicts observed self-thinning roughly twice as well as a generic species-table constant. Applied to
AcadianGY, the diagnostic finding was that the Weiskittel-Kuehne SDImax equation above already handles
composition well through the percent-hardwood and specific-gravity terms, but under-corrects specifically
for hardwood-dominated stands in Quebec outside the Acadian-core ecoregion (CEC North American Level III:
Acadian Plains and Hills, Maritime Lowlands). v12.9.0 adds a gated multiplier to SDImax
(`ops$sdimax.fortype.tight.mult`, default 0.65 to 0.70), active only when a stand is simultaneously
Quebec, outside the Acadian core, and hardwood-dominated by BA-weighted dominant species group. See
section 10 and `20260701_v129_full_validation.md` for the full derivation and validation.

## 4. Growth Relationships

### 4.1 Height-diameter (total tree height)

HTPred, after Rijal et al. (2012a) modified for additional species:

    ht = 1.37 + ((c0 + c0.spp) + CSI^c1) * (1 - exp(-c2*DBH))^(c3 + c3.spp + c4*log(CCF+1) + c5*BAL)

CSI enters the asymptote (the CSI^c1 term). c0 to c5 are fixed; c0.spp and c3.spp are species random
effects. Used to fill missing or invalid heights. [POPULATE: parameter table.]

### 4.2 Bark ratio

DOBtoDIB (Weiskittel and Li 2012) converts diameter outside to inside bark. [POPULATE: form and
parameters.]

### 4.3 Crown ratio and crown recession

Height to crown base, HCBPred (Rijal et al. 2012b, refit with species random effect, Weiskittel et
al. 2013):

    hcb = HT / (1 + exp((a0 + a0.spp) + a1*DBH + a2*HT + a3*DHR + a4*log(CCF+1) + a5*(BAL+1)))

Crown recession, dHCB (Russell et al. 2014):

    dHCB = (CL + dHT) / (1 + exp(b1 + b2*log(CR+0.01) + b3*log(CCF+1) + b4*log(1.01-CR)
           + b5*shade^2 + b6*log(shade*CR)))

[POPULATE: parameter tables.]

### 4.4 Crown width

Maximum crown width mcw = a1*DBH^a2 (open-grown, Russell and Weiskittel 2011, 99th-quantile);
largest crown width lcw = mcw / (b1*DBH^b2) for forested conditions. [POPULATE: species parameters.]

### 4.5 Crown competition factor

CCF is the sum of tree maximum crown areas per plot, used in height, height-to-crown-base, crown
recession, increment, and ingrowth.

### 4.6 Diameter increment

dDBH, Kuehne et al. (2022), species as a random effect, fit on > 2.5 million observations:

    dDBH = exp((b0+b0.SPP) + b1*log(DBH) + (b2+b2.SPP)*DBH + (b3+b3.SPP)*log(CR)
           + (b4+b4.SPP)*log(BAL.SW+0.1) + b5*BAL.HW + b8*log(CSI))

Fixed-effect coefficients (Kuehne et al. 2022, Table 6): b0 = -1.64234, b1 (ln DBH) = 0.376978,
b2 (DBH) = -0.025684, b3 (ln CR) = 0.713456, b4 (ln BAL.SW+0.1) = -0.065750, b5 (BAL.HW) = -0.017740,
b8 (ln CSI) = 0.135377. Species random effects apply to the intercept, DBH, ln(CR), and ln(BAL.SW+0.1).
Competition is one-sided and asymmetric (basal area in larger softwoods and hardwoods); two-sided
metrics (SDI, relative density) were no more effective. On independent FIA data the equation is nearly
unbiased (mean bias -1.2 percent) and improves on the prior FVS-ACD diameter and basal-area increment
submodels by 11 to 13 percent in mean absolute bias. Tree diameter increment is constrained by the
stand basal-area increment (4.8). Full species random-effect tables in Kuehne et al. (2022) Table S3.

### 4.7 Height increment

dHT, Kuehne et al. (2022), more conservative than the earlier Russell et al. (2014) form (addresses
the FVS-NE over-prediction expectation):

    dHT = exp((b0+b0.SPP) + b1*log(HT) + (b2+b2.SPP)*HT + b3*CR + b4*(CCFL/100) + b7*CSI^2)

Fixed-effect coefficients (Kuehne et al. 2022, Table 8): b0 = -2.19445, b1 (ln HT) = 0.426404,
b2 (HT) = -0.064710, b3 (CR) = 0.394837, b4 (CCFL/100) = -0.011430, b7 (CSI^2) = 0.000294. Species
random effects apply to the intercept and HT. The new dHT improves on the prior Russell et al. (2014)
submodel substantially (mean absolute bias down 41 to 74 percent), the largest accuracy gain of the
two increment refits. Full species random-effect tables in Kuehne et al. (2022) Table S5.

### 4.8 Stand basal-area increment

Chen et al. (in prep.), added at v12.3.0, applied at the stand level as a cap on summed tree
diameter increment:

    dBA = rt*Ba*(1 - Ba/k);  rt = q0 + q1*log(RD+1e-6) + q2*log(CSI) + q3*log(pHW.ba*100+1e-6)
          + q4*log(CSI*RD+1e-6)

Applied only when summed predicted tree BA increment exceeds the stand prediction, and capped at
0.227 percent of plot BA (5th percentile, Maine FIA). RD is relative density SDI/SDImax. This is the
density-dependent brake on growth.

## 5. Mortality Model

Stand- and tree-level mortality, Weiskittel et al. (2012). The multi-stage approach of Chen et al.
(2023) was evaluated in beta and was not superior, so the model uses the 2012 formulation (see the
v12 history memo).

Stand mortality probability: prob = exp(k)/(1+exp(k)), k = b0 + b1*BA + b2*BA^2 + b3*BAG + b4*QMD +
b5*BA.BF + b6*BA.IH. Stand mortality basal area: BA.mort = (b0 + b1*pBA.bf + b2*pBA.ih)*BA^(b3 +
b4*BAG); BF.mort = b5*BA.BF^b6 + b7*(QMD.BF/QMD). Tree survival: logistic in DBH and DBH^2. Stand
mortality is distributed across trees in proportion to tree mortality probability. Region-specific
parameters (ME, NB, NS, QC). [POPULATE: regional parameter tables.]

Operational note: the production model uses the 2012 stand and tree mortality with SDImax-ceiling
self-thinning (ops$use.sdimort) active, a density-frontier mortality that holds post-step SDI at or
below SDImax and improves the Bakuzis self-thinning slope. A size-dependent MORTCAL corrector
(ops$use.mortcal) is available but trades stem-count accuracy and ships off. The principled
next-version fix is a regional refit of the 2012 stand-mortality coefficients.

Coupled self-thinning and density-released ingrowth (12.7.1). The 12.7.0 self-thinning used a single
slope above a relative-density onset, which on long-horizon projection never plateaued (basal area
climbed past 36 m2/ha and was still rising at age 120). Version 12.7.1 replaces it with a coupled
two-segment relative-density mortality. Let RD = SDI/SDImax. Mortality is zero below RD 0.30, rises on
a gentle slope from 0.30 to a break at 0.62 (ops$sdimort.onset, ops$sdimort.break, ops$sdimort.beta.gentle),
and rises on a steep slope above the break (ops$sdimort.beta.steep), so a fully stocked stand self-thins
along the SDImax line. It is coupled with a density-released ingrowth (section 6): recruitment is
suppressed at high RD and released below about RD 0.58, through a logistic in RD. The biological rationale
is the build, self-thin, and rebound dynamic of a stand that grows to its maximum, self-thins along the
density frontier, and rebounds as ingrowth releases when density falls, the process underlying a
shifting-mosaic steady state. On a 160-year projection of a young dense spruce-fir stand across the site
gradient, basal area builds and plateaus at about 33 to 34 m2/ha by mid-rotation and then levels, inside
the realistic fully-stocked Acadian spruce-fir range (about 28 to 34), replacing the 12.7.0 runaway
climb. The decline-and-rebound is critically damped at the single-stand deterministic scale. Because
mature Quebec-edge stands and moderately dense New Brunswick stands overlap in relative density, this
relative-density lever reduces the mature-stand over-prediction while modestly deepening the
growing-stand under-prediction; separating the two is the next-version regional and composition-aware
mortality target.

Regional and composition-aware SDImax gate (12.9.0). The 12.7.1 mature-stand residual, on closer
diagnosis, is not a Quebec-wide phenomenon but is concentrated in hardwood-dominated Quebec stands
outside the Acadian-core ecoregion; softwood-dominated Quebec stands and all of New Brunswick were
already close to unbiased. v12.9.0 adds a gated multiplier to the SDImax term used by this self-thinning
mechanism (section 3.5), active only when a stand is simultaneously province Quebec, ecoregion outside
the Acadian core, and hardwood-dominated. This raises the effective self-thinning intensity for that
specific population, closing the target cell's total-volume bias from +56.7 to +10.4 percent with no
effect on New Brunswick or on the independent recent Maine FIA growing-stand check (see section 10). The
mechanism is additive to, not a replacement for, the coupled self-thinning above: it scales SDImax before
the RD = SDI/SDImax ratio that drives the two-segment mortality curve.

## 6. Regeneration and Ingrowth

Full ingrowth model, Li et al. (2011), for ten species groups (BCH birch, BF, RM, SPR spruce, WP,
OH, AB, QA, SM, WC). A hurdle model: occurrence probability P(occur) and count E[count] = exp(eta),
both functions of BA, percent hardwood, TPH, CSI, minimum DBH, and QMD. The occurrence is gated by
a cut-point (CutPoint, default 0.95). FVS-ACD also retains FVS resprouting after simulated harvest.

Version 12.6.1 note: the 0.95 occurrence gate suppresses recruitment on most plot-years and is the
source of the under-recruitment behind the stem-count deficit. v12.6.1 makes the statistically
correct expected-value recruitment the default, E[ingrowth] = P(occur) * E[count] (set CutPoint to
0), with a calibration multiplier. This is the dominant lever on stem count and QMD but, by global
sensitivity analysis, does not materially change stand value (the recruits are small).

Version 12.7.1 note (density-released ingrowth): observed recruitment, tree-ID matched on the raw
MagPlot records, is about 40 stems per ha per year in New Brunswick and about 20 in Quebec. v12.7.1
couples the expected-value recruitment to relative density through a logistic in RD (ops$use.ingrowth.release,
ops$ingrowth.rd.center 0.58, ops$ingrowth.rd.k): recruitment is suppressed at high relative density and
released below about RD 0.58. Coupled with the two-segment self-thinning mortality (section 5), this
produces the build, self-thin, and rebound stand dynamic.

## 7. Volume and Taper

Stem taper: Kozak variable-exponent taper and Westfall and Scott (Li et al. 2012, Weiskittel and Li
2012). Bark thickness via DOBtoDIB. Merchantable volume and product specifications follow the FVS
volume framework; for value work, sawlog (International 1/4-inch board feet) and pulp (cords) are
split by species and size. [POPULATE: taper parameters and volume specification table.]

Operational note (12.7.x): all volume and biomass in the benchmarking and validation are reported on
the FIA National Scale Volume and Biomass (NSVB) system, applied through an emulator that predicts the
NSVB responses (gross cubic volume, net merchantable volume, net sawlog volume, and aboveground dry
biomass) from log(DIA squared times HT) by species group with Duan smearing, with R-squared 0.96 to
0.99 against the FIA NSVB outputs. This puts observed and predicted tree lists on a single, current
volume-and-biomass currency and replaces the earlier single form-factor merchantable volume used for
increment scoring.

## 8. Modifiers

Thinning (Kuehne et al. 2016): diameter growth, mortality, height growth, and crown recession
modifiers keyed on removal intensity and timing. Spruce budworm (Cen et al. 2018): balsam fir and
spruce mortality, diameter and height growth, keyed on cumulative defoliation, region ME and NB.
Hardwood form and risk (Castle et al. 2018): mortality and diameter growth modifiers for selected
hardwoods. [POPULATE: parameter tables.]

## 9. Model Application

CSI is supplied by the user or sampled from the raster surfaces (current and 2030/2060/2090 climate
normals); recent testing finds the 2030 surface reasonable. Cycle length is one year. The model is
run from a tree list through the FVS interface or the AcadianGY R driver (make_stand, make_acd_tree,
make_ops, AcadianGYOneStand). [POPULATE: keyword and database usage, analogous to Essential FVS.]

## 10. Recommended version (12.9.0) and validation

AcadianGY 12.5.0 is the current operational and production version. AcadianGY 12.9.0 is the recommended
forward version, which integrates this development cycle's refinements into one file, built directly on
12.7.1, and is documented here as the candidate to replace 12.5.0. The recommended configuration is: the Kuehne et al. (2022) diameter
and height increment equations (4.6, 4.7) as the growth base; the validated ESI v8 as the site driver
with the fitted ESI-anchored dominant height (3.4, 4.1); FIA NSVB volume and biomass (7); expected-value
ingrowth, density-released (6); the coupled two-segment SDImax self-thinning (5); and the regional and
composition-aware SDImax gate for the Quebec hardwood edge (5, 3.5). Every refinement is gated, and with
the flags in their legacy position the build reproduces 12.5.0 bit for bit, so each is individually
isolated and validated. 12.9.0 with its own gate unset reproduces 12.7.1 exactly.

Refinements, in order of development:
1. ESI site input (12.6.0), drop-in through the site slot; ESI v8 30 m surface adopted (12.7.0).
2. Site-independent SDImax (12.6.0), from the brms re-estimation.
3. SDImax-ceiling self-thinning (12.6.0), the density-frontier mortality.
4. Expected-value ingrowth (12.6.1), fixing the under-recruitment stem-count deficit.
5. ESI-anchored dominant height (12.7.0), fitted Chapman-Richards anchor (k 0.0039, p 0.726, base 50),
   which removes the Bakuzis height site-ordering inversions (25 to 0).
6. FIA NSVB volume and biomass through the emulator (12.7.x), R-squared 0.96 to 0.99 against FIA NSVB.
7. Coupled two-segment relative-density self-thinning and density-released ingrowth (12.7.1), which
   makes the long-horizon basal-area trajectory plateau at the biologically correct Acadian maximum
   (about 33 m2/ha) instead of running away, and reduces the mature-stand volume and biomass
   over-prediction.
8. Regional and composition-aware SDImax gate (12.9.0), which closes the remaining mature-stand
   over-prediction specifically in hardwood-dominated Quebec stands outside the Acadian-core ecoregion,
   with an independent recent-FIA cross-check confirming zero effect on New Brunswick or Maine.

### 10.1 Four-model independent scorecard (1 July 2026)

A multi-dimensional scorecard (quantitative bias, RMSE, modeling efficiency, and periodic annual
increment; qualitative Bakuzis biological realism, long-horizon trajectory shape, transparency, data
requirements, usability, and uncertainty characterization) was run on AcadianGY 12.5.0, 12.7.0, 12.7.1,
and the current OSM-ACD release (v2.26.1, confirmed current against the OSM-Contributors GitHub
organization and the Forus Research download page), on identical independent in-domain data. The full
scorecard is `20260701_four_model_scorecard.md`; figures `five_model_scorecard_heatmap.png` and
`five_model_scorecard_radar.png` (v12.9.0 added as a fifth model, section 10.2).

Headline finding: OSM-ACD has the lowest pooled level bias of the four models on every metric, but
negative Nash-Sutcliffe modeling efficiency on every metric, meaning its stand-level predictions are less
accurate than simply predicting the observed mean; its favorable aggregate bias is population-level
cancellation of large individual over- and under-predictions, not per-stand skill. All three AcadianGY
versions explain 55 to 78 percent of out-of-sample variance on every metric. AcadianGY 12.5.0 fails the
Bakuzis self-thinning check outright (long-horizon basal area still climbing past 62 m2/ha at age 120
with several thousand stems per hectare still alive) and is not recommended for mature-stand or
long-horizon use. AcadianGY 12.7.1 is the best FVS-ACD version on the combined quantitative and
qualitative profile prior to the 12.9.0 refinement below.

### 10.2 v12.9.0: a targeted SDImax correction for the Quebec hardwood edge

The scorecard in 10.1 localized 12.7.1's remaining structural gap to a specific population: stands that
are simultaneously Quebec (province), outside the Acadian-core ecoregion (CEC North American Level III:
Acadian Plains and Hills, Maritime Lowlands are the core; Northern Appalachian and Atlantic Maritime
Highlands, Algonquin and Southern Laurentians, Central Laurentians and Mecatina Plateau, and Eastern
Great Lakes Lowlands are outside it), and hardwood-dominated (BA-weighted dominant species group sugar
maple, birch, aspen, other hardwood, or American beech). Softwood-dominated Quebec stands, and every New
Brunswick stand regardless of composition, were already close to unbiased and are untouched by the
v12.9.0 gate.

Development process, briefly (full derivation `20260701_v129_full_validation.md`,
`20260701_v129_ooda_stress_test.md`): a region-only multiplier was tried first and found to be a pure
trade-off (fixing basal area worsened volume and vice versa, with no setting fixing both). An ESI-based
spatial cluster was tried and found weak, because ESI v8 coverage of Quebec is patchy. Forest type
(BA-weighted dominant species group) located the real signal. True ecoregion sharpened it further. An
ecoregion-only gate (no province term) closed the Quebec target as well as the final version, but an
independent cross-check against the recent Maine FIA growing-stand stratum caught a real regression: the
correction leaked onto Maine's own hardwood stands sharing the same ecoregion as the Quebec problem
stands, worsening the FIA annual-increment check from -52 to -83 to -93 percent. Restoring province as a
third gate dimension eliminated this by construction, since no Maine plot can ever satisfy a Quebec-only
gate.

Validation, in-domain MagPlot (n = 733) and independent recent Maine FIA (n = 788), predicted versus
observed t2 level bias:

- Target cell (Quebec, outside Acadian core, hardwood-dominated, n = 163): total volume +56.7 to +10.4
  percent, stand value to +4.4 percent. Basal area, already under-predicted in 12.7.1, deepens further
  (-9.3 to -18.1 percent), the SDImax-driven trade-off confined now to exactly the population needing it.
- New Brunswick: unchanged from 12.7.1 in every metric.
- Recent Maine FIA: unchanged from 12.7.1 (basal-area level -2.2 percent, annual increment -0.085
  m2/ha/yr), confirming the gate cannot affect Maine plots.
- A stand-level split-half robustness check (163 target-cell stands, two random halves) confirmed the
  correction is not driven by a handful of outlier stands.

Known residual: a seeded 160-year trajectory of the corrected hardwood population plateaus at about 21
m2/ha, below the realistic 28 to 32 m2/ha target for that composition (the same composition, uncorrected,
plateaus at 31 to 32). A correction calibrated on a 5 to 15 year remeasurement window, carried through a
full rotation, under-shoots the long-horizon asymptote. v12.9.0 is recommended for short-to-mid rotation
inventory projection; v12.7.1 remains the recommended version for carbon and old-growth applications on
this specific population until a tapered version of the correction, relaxing toward the true asymptote
rather than applying a flat multiplier throughout the rotation, is fit.

Independent validation. On genuinely independent, in-domain data, the full FIA NSVB metric set,
predicted versus observed t2 level bias, New Brunswick (n=355) and the ESI-covered Quebec edge (n=378),
12.7.0 to 12.7.1:

- New Brunswick total volume -3.9 to -9.8 percent, biomass -1.4 to -7.3, value -4.5 to -10.2; basal
  area -3.5 to -8.5, top height +6.9 to +6.8.
- Quebec edge total volume +23.3 to +14.4 percent, biomass +19.1 to +10.2, value +27.3 to +18.3; basal
  area -2.1 to -9.3, top height +12.9 to +12.5.

The coupled self-thinning reduces the mature-stand Quebec-edge volume and biomass over-prediction by
roughly a third to a half. New Brunswick and Quebec stands overlap in relative density, so the same
relative-density mortality that self-thins the dense Quebec stands also deepens the moderately dense New
Brunswick under-prediction; the two are ends of one lever and are the next-version regional and
composition-aware mortality target.

Recent Maine FIA (post-2010, independent in time, n=788): basal-area level bias +0.7 percent in 12.7.0
to -2.2 percent in 12.7.1 (still near-unbiased); annual basal-area increment +11 percent (over) in
12.7.0 to 52 percent under (still positive net growth) in 12.7.1. On independent New Brunswick MagPlot,
the v12.7 generation is +0.05 m3/ha/yr on a shared form-factor volume harness, near zero and at least as
good as the 2018 OSM-ACD (-0.23) and FVS-ACD v10.6 (-0.18); the 2018 conclusion that OSM clearly beat
FVS-ACD does not hold for v12.7 on independent New Brunswick data.

Biological realism (Bakuzis matrix): site ordering clean (0 of 125 inversions, the dominant-height
anchor), Reineke self-thinning slopes -1.28 to -1.35, one moderate Eichhorn flag. Observed ingrowth
about 40 stems per ha per year in New Brunswick and 20 in Quebec, matched by the density-released form.

The regional and composition-aware stand-mortality refit called for here is v12.9.0 (section 10.2): it
closes the Quebec mature-stand over-prediction for the specific hardwood-dominated, outside-Acadian-core
population, without reopening the New Brunswick under-prediction, since the gate excludes New Brunswick
by construction. Two items bound the next development cycle. First, a tapered version of the v12.9.0
correction for long-horizon carbon and old-growth work, since the current flat multiplier under-shoots
the realistic basal-area plateau for the corrected population when run past the short-interval calibration
window (section 10.2). Second, the long-horizon OSM comparison: on the Seven Islands stands the two agree
at the start and then diverge, FVS-ACD self-thinning and OSM accumulating, first-order model-form
uncertainty with no observed truth at that horizon, which localizes to stand mortality; the four-model
scorecard (10.1) confirms this pattern holds on independent data at shorter, observed intervals as well
(OSM's negative modeling efficiency versus AcadianGY's positive efficiency on every metric).

## 11. Literature Cited

[POPULATE with full references: Loo and Ives 2003; Weiskittel et al. 2011, 2012, 2013; Weiskittel and
Li 2012; Weiskittel and Kuehne 2019; Rijal et al. 2012a,b; Russell and Weiskittel 2011; Russell et
al. 2014; Kuehne et al. 2016, 2022; Li et al. 2011, 2012; Chen et al. (in prep., 2023); Cen et al.
2018; Castle et al. 2018; Jiang et al. 2014; Leary 1997 (Bakuzis); Dixon 2002 (Essential FVS).]

## 12. Appendices

[POPULATE: A. Species code and attribute table. B. Component parameter tables (height, HCB, crown
width, diameter increment, height increment, stand BA increment, mortality by region, ingrowth,
taper). C. Keyword reference. D. Validation tables and figures from the benchmarking report.]
