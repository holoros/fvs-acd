# Acadian (ACD) Variant Overview of the Forest Vegetation Simulator

**DRAFT variant overview / General Technical Report scaffold. 29 June 2026, updated 7 July 2026.**

*Structured after the USDA Forest Service Northeast (NE) Variant Overview (FVS Staff 2008, rev.
August 2023) so it can become the official FVS-ACD variant documentation. Equation content is drawn
from the Acadian GY Model Documentation (Weiskittel and team, 2025-05-20) and the AcadianGY source,
built on the 12.7.1 development line. AcadianGY 12.10.1 is the current operational and production
version, documented here. Sections still marked [POPULATE] need team-written text before publication
(the geographic range map figure, the keyword and database usage reference, the full Literature Cited
list, and the Appendix C/D validation and keyword material); the species and component parameter tables
(Appendices A and B) are populated directly from the AcadianGY source and are unchanged from v12.9.0
through v12.10.1, since the later refinements touch mortality, ingrowth, self-thinning, and the
management modifiers, not the species-level growth, crown, taper, or volume parameters. Plaintext math,
no em dashes; this draft will be rendered to a formatted Word/PDF GTR. Updated 7 July 2026 to document
v12.10.1 as the operational version, with the version lineage through 12.5.0, 12.7.0/12.7.1, 12.9.x,
and 12.10.1, the five-way independent scorecard and honest scorecard position, the Bakuzis
biological-realism pass, the disclosed ingrowth limit, and the planned v13 program.*

## Authors and Contributors

Aaron Weiskittel and the University of Maine Cooperative Forestry Research Unit (CFRU) developed the
Acadian growth-and-yield model. Ben Rice (Midgard Natural Resources) maintains the FVS-ACD
implementation and benchmarking. Component equations are credited to their authors throughout
(Kuehne, Russell, Rijal, Li, Chen, Castle, Cen, and others; see Literature Cited). This overview
documents the FVS-ACD variant as implemented in AcadianGY 12.10.1, the current operational version.

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
10. Version Lineage, Current Operational Version (12.10.1), and Validation
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

37 rows are parameterized in `sp.attr` (35 distinct named species plus the OH other-hardwood and OS
other-softwood composite groups, and a `99` fallback row). Species not in the parameter set map to OH
or OS by softwood/hardwood type. Full species code table with scientific names, FIA and PLANTS codes,
specific gravity, and shade/drought/waterlog tolerance in Appendix A; component parameter tables
(height, HCB, crown width, bark ratio, mortality, modifiers, ingrowth, taper, volume) by
`sp.grp.ingrowth` and by individual species in Appendix B.

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
effects. Used to fill missing or invalid heights. Species parameter table in Appendix B.1.

### 4.2 Bark ratio

DOBtoDIB (Weiskittel and Li 2012) converts diameter outside to inside bark. Form and species
parameters in Appendix B.4.

### 4.3 Crown ratio and crown recession

Height to crown base, HCBPred (Rijal et al. 2012b, refit with species random effect, Weiskittel et
al. 2013):

    hcb = HT / (1 + exp((a0 + a0.spp) + a1*DBH + a2*HT + a3*DHR + a4*log(CCF+1) + a5*(BAL+1)))

Crown recession, dHCB (Russell et al. 2014):

    dHCB = (CL + dHT) / (1 + exp(b1 + b2*log(CR+0.01) + b3*log(CCF+1) + b4*log(1.01-CR)
           + b5*shade^2 + b6*log(shade*CR)))

HCB species random-effect table (a0.spp) in Appendix B.2. The crown-recession equation uses fixed
parameters for all species (no separate species table in the source); shade tolerance is read from
Appendix A.

### 4.4 Crown width

Maximum crown width mcw = a1*DBH^a2 (open-grown, Russell and Weiskittel 2011, 99th-quantile);
largest crown width lcw = mcw / (b1*DBH^b2) for forested conditions. Species parameters in Appendix B.3.

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
parameters (ME, NB, NS, QC) in Appendix B.6; tree-level background mortality species parameters (the
DBH/DBH^2 survival logistic and the Weibull-form diameter-jump term) in Appendix B.5.

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
Composition and occurrence-probability parameters by species group in Appendix B.8.

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
split by species and size. Kozak and Westfall-Scott taper species parameters in Appendix B.9, legacy
Honer volume species parameters in Appendix B.10, bark ratio in Appendix B.4.

Operational note (12.7.x): all volume and biomass in the benchmarking and validation are reported on
the FIA National Scale Volume and Biomass (NSVB) system, applied through an emulator that predicts the
NSVB responses (gross cubic volume, net merchantable volume, net sawlog volume, and aboveground dry
biomass) from log(DIA squared times HT) by species group with Duan smearing, with R-squared 0.96 to
0.99 against the FIA NSVB outputs. This puts observed and predicted tree lists on a single, current
volume-and-biomass currency and replaces the earlier single form-factor merchantable volume used for
increment scoring.

## 8. Modifiers

Thinning (Kuehne et al. 2016; note the source code header instead credits Weiskittel, Hennigar, and
Kershaw 2015 for this modifier, a citation discrepancy to reconcile before publication): diameter
growth, mortality, height growth, and crown recession modifiers keyed on removal intensity and timing.
Spruce budworm (Cen et al. 2018): balsam fir and spruce mortality, diameter and height growth, keyed on
cumulative defoliation, region ME and NB. Hardwood form and risk (Castle et al. 2018): mortality and
diameter growth modifiers for selected hardwoods. All parameter tables in Appendix B.7.

Direct-effect management modifiers (12.10.1). The current operational version adds the Chapter 11
direct-effect management modifiers as gated additive releases on planted and precommercial-thinning
(PCT) stands. Rather than a diameter-growth multiplier pinned to a guard clamp, the release is expressed
as a robust additive term on the class of per-stand observed minus predicted-untreated increment (planted
+3.83 m² ha⁻¹ basal area, PCT +2.41 m² ha⁻¹, with proportional releases in the other metrics). It is
gated by ops$use.mgmt.mod and applies only to planted and PCT stands, so the gate-off run is byte
identical to v12.9.x on unmanaged stands. The release is a diameter-growth term, not a mortality term,
is physically bounded within the unmanaged density envelope, and does not break the self-thinning
plateau. See section 10.3 for the fit and validation.

## 9. Model Application

CSI is supplied by the user or sampled from the raster surfaces (current and 2030/2060/2090 climate
normals); recent testing finds the 2030 surface reasonable. Cycle length is one year. The model is
run from a tree list through the FVS interface or the AcadianGY R driver (make_stand, make_acd_tree,
make_ops, AcadianGYOneStand). [POPULATE: keyword and database usage, analogous to Essential FVS.]

## 10. Version lineage, current operational version (12.10.1), and validation

AcadianGY 12.10.1 is the current operational and production version and is frozen as the operational
release for the 18 August 2026 Acadian Growth and Yield meeting; v13 is in progress but no v13 version is
gated, so nothing in the v13 program below is a claimed result. v12.10.1 is the endpoint of a single
development line that began with 12.5.0 and added one gated refinement at a time, each individually
isolated so that with its flag in the legacy position the build reproduces the prior version bit for
bit. The operational configuration is the Kuehne et al. (2022) diameter and height increment equations
(4.6, 4.7) as the growth base; the validated ESI v8 as the site driver with the fitted ESI-consistent
dominant-height anchor recalibration active (3.4, 4.1), which delivers the clean Bakuzis site ordering
(10.2); a further top-height anchor-level parity correction available behind a gate but shipping off in
the current config, deferred to v13.0 (see 10.3); FIA NSVB volume and biomass (7); expected-value,
density-released ingrowth (6); the
coupled two-segment relative-density self-thinning (5); the regional and composition-aware SDImax gate
for the Quebec hardwood edge (5, 3.5); and the Chapter 11 direct-effect management modifiers as gated
additive releases on planted and precommercial-thinning stands (8, and section 10.3 below).

The version lineage, in order of development:

1. 12.5.0, the prior operational and production base. Kuehne et al. (2022) increment equations, climate
   site index, and the 2012 stand and tree mortality. On long-horizon projection it does not self-thin,
   with basal area climbing past 62 m² ha⁻¹ at age 120, and is not recommended for mature-stand or
   long-horizon use.
2. 12.7.0 and 12.7.1. The 12.7.x line added the validated ESI v8 site driver and the ESI-anchored
   dominant height, FIA NSVB volume and biomass through the emulator (R-squared 0.96 to 0.99 against
   FIA NSVB), the coupled two-segment relative-density self-thinning, and the density-released ingrowth.
   Together these make the long-horizon basal-area trajectory plateau at the biologically correct
   Acadian maximum (about 33 to 34 m² ha⁻¹) rather than running away, couple recruitment to relative
   density so that a stand builds, self-thins along the density frontier, and rebounds as ingrowth
   releases, and put observed and predicted tree lists on a single current volume and biomass currency.
3. 12.9.x. A CONUS-scale brms re-estimation of plot-level maximum SDI (independent of the earlier
   northern New England one) confirmed that composition and ecoregion, not site index, dominate the
   variance in the self-thinning ceiling. v12.9.x adds a gated multiplier to SDImax active only when a
   stand is simultaneously Quebec, outside the Acadian-core ecoregion, and hardwood-dominated. This
   closes the remaining mature-stand over-prediction in exactly that population, with an independent
   recent-FIA cross-check confirming zero effect on New Brunswick or Maine (the province term in the
   gate excludes Maine by construction).
4. 12.10.1. Chapter 11 direct-effect management modifiers, expressed as gated additive releases on
   planted and precommercial-thinning (PCT) stands (section 10.3). The modifier is gated by
   ops$use.mgmt.mod and touches only planted and PCT stands; the gate-off run is byte identical to
   v12.9.x on the 266 unmanaged stands. This is the current operational version.

Every refinement is gated, and with the flags in their legacy position the build reproduces the base
bit for bit, so each is individually isolated and validated. v12.10.1 with its management gate off
reproduces v12.9.x exactly, and v12.9.x with its own gate unset reproduces 12.7.1 exactly.

Provenance note on the operational build. The operational scorecard baseline documented in this section was
produced from the AcadianGY_12.9.2.r source plus the recorded operational ops recipe, the gated management
release applied through make_ops on the v12.9.x engine. A standalone AcadianGY_12.10.1.r script that folds
that recipe into the source now exists in the repository and carries the AcadianV12.10.1 version tag; it is
being reconciled against the recipe-driven baseline to confirm it reproduces the scored results byte for
byte before it supersedes the recipe as the canonical operational file.

### 10.1 Four-model independent scorecard (1 July 2026)

A multi-dimensional scorecard (quantitative bias, RMSE, modeling efficiency, and periodic annual
increment; qualitative Bakuzis biological realism, long-horizon trajectory shape, transparency, data
requirements, usability, and uncertainty characterization) was run on AcadianGY 12.5.0, 12.7.0, 12.7.1,
and the current OSM-ACD release (v2.26.1, confirmed current against the OSM-Contributors GitHub
organization and the Forus Research download page), on identical independent in-domain data. The full
scorecard is `20260701_four_model_scorecard.md`; figures `five_model_scorecard_heatmap.png` and
`five_model_scorecard_radar.png` (v12.9.0 added as a fifth model, section 10.2).

Headline finding: OSM-ACD has the lowest pooled level bias of the four models on every metric and, once
it is scored on all nine NSVB metrics through the same emulator harness as FVS-ACD, also carries the
highest pooled modeling efficiency. An earlier read that showed a negative Nash-Sutcliffe efficiency for
OSM on every metric was an index-join artifact, OSM output matched to the observed tree lists on a
mismatched key rather than a real lack of per-stand skill; rescoring OSM through the common NSVB harness
resolves it, and OSM's pooled modeling efficiency is positive and leads the set. Where FVS-ACD leads OSM
is biological realism, the climate-ready site driver, and quadratic mean diameter, not pooled level bias
or modeling efficiency. All three AcadianGY versions explain 55 to 78 percent of out-of-sample variance
on every metric. AcadianGY 12.5.0 fails the
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

### 10.3 v12.10.1: direct-effect management modifiers, the current operational version

v12.10.1 adds the Chapter 11 direct-effect management modifiers as gated additive releases on planted
and precommercial-thinning (PCT) stands, the current operational version. Relative to the v12.10.0
prototype, the planted and PCT diameter-growth multipliers no longer pin to the old 0.7 to 1.6 guard
clamp. The direct effect is re-expressed as a robust additive release, planted +3.83 m² ha⁻¹ basal area
and PCT +2.41 m² ha⁻¹ (ten percent trimmed means over the class of per-stand observed minus
predicted-untreated increment, with proportional releases in the other metrics), which is equivalent to
a net multiplier of about 3.0 planted and 2.3 PCT, above the old 1.6 ceiling, which is why the clamped
version still under-predicted planted. The modifier is gated by ops$use.mgmt.mod and applies only to
planted and PCT stands; the gate-off run is byte identical to v12.9.x on the 266 unmanaged stands. The
additive fold coefficients move with the data (planted basal-area release 3.57 to 4.14, PCT 2.28 to 2.57
across cross-validation folds), so it is a fitted release, not a clamped constant. It is physically
bounded: managed predicted SDI stays inside the unmanaged envelope, the release is a diameter-growth
term rather than a mortality term, and the self-thinning plateau holds at every amplitude tested.

The honest scorecard position. A five-way independent benchmark (v12.5.0, v12.7.0, v12.9.x, v12.10.1,
and OSM v2.26.1) on the identical held-out in-domain data (MagPlot New Brunswick n=355 and ESI-covered
Quebec n=350, plus recent Maine FIA for the growing-stand cross-check) places v12.10.1 level with v12.9.x
on the pooled operational domain, both behind OSM there, and ahead of both on the managed cell. Because
the frozen operational harness fully specifies the operational ops, v12.7.1, v12.9.x, and v12.10.1 are
byte identical on the pooled base scorecard and differ only in the managed cells; the five-way therefore
resolves to three distinct pooled engines, v12.5.0, v12.7.0, and the shared v12.7.1, v12.9.x, and
v12.10.1 operational line.

**Table 10.1.** Pooled operational scorecard, v12.10.1 versus the comparison models (nine NSVB metrics).

| model | mean absolute level bias (%) | mean modeling efficiency | TOST level equivalences (of 9) |
|---|---|---|---|
| v12.5.0 | 7.1 | 0.71 | 4 |
| v12.7.0 | 8.0 | 0.73 | 2 |
| v12.9.x | 4.9 | 0.71 | 7 |
| v12.10.1 | 4.9 | 0.71 | 7 |
| OSM v2.26.1 | 3.2 | 0.75 | 8 |

OSM keeps the best pooled level bias (3.2 versus 4.9), the best mean modeling efficiency (0.75 versus
0.71), and the most TOST level equivalences (8 versus 7 of 9, against four of nine for v12.5.0 and two
of nine for v12.7.0). On the frozen harness every model's top height lands in a tight +3.7 to +4.6
percent band, so the apparent top-height over-prediction once read into the older 12.5.0 and 12.7.0
lines was an artifact of the pre-freeze basis and does not survive re-benching; the two older engines
separate instead on volume, v12.5.0 a strong total-volume over-predictor (+9.3 percent, mean absolute
level bias 7.1) and v12.7.0 a volume under-predictor (-8.3 percent, mean absolute level bias 8.0).
v12.10.1 does not claim pooled parity.
The point of v12.10.1 is the managed cell. The Chapter 11 gate closes the managed gap sharply in
absolute basal-area bias, planted from -24.9 to -4.4 percent, PCT from -15.6 to -1.3 percent, and the
managed class as a whole from -19.0 to -2.5 percent, and v12.10.1 beats OSM on every managed class in
absolute basal-area bias (managed 2.5 versus 11.2, planted 4.4 versus 20.9, PCT 1.3 versus 5.4). One
frozen-basis caveat to flag: gate-on planted total volume now sits at -10.8 percent, because the frozen
anchor lowers untreated planted-stand volume so the fixed additive release closes less of the volume
gap; the basal-area releases themselves are unchanged. On the pooled
domain v12.10.1 and v12.9.x are identical to one decimal, because the modifier touches only managed stands
and those are a small share of the in-domain pool, so pooled mean absolute bias (4.9), RMSE, and modeling
efficiency all carry over from v12.9.x unchanged and the modifier's effect appears only in the managed
cell. On the pooled domain the FVS-ACD advantage is quadratic mean diameter (about +1 percent versus OSM
+11 percent), biological realism, transparency, and a climate-ready site driver, not pooled precision.

Biological realism (Bakuzis pass). v12.10.1 inherits the v12.9.x self-thinning machinery and, on seeded
160-year projections across the ESI gradient, passes all five relations on the modified Bakuzis matrix
(Leary 1997): Eichhorn (volume a function of height), Reineke self-thinning slope (fitted -1.59 against a
-1.6 target), site ordering with no overtaking, the yield-density plateau (about 36 m² ha⁻¹), and
Sukachev (size versus density). With the management modifier on, a seeded planted-softwood projection
still plateaus at every amplitude tested (standard deviation of basal area over the last 20 years about
0.21, flat), and the ceiling rises smoothly with amplitude because basal area at the Reineke limit rises
with tree size. By contrast v12.5.0 fails self-thinning outright in the same seeded battery. OSM is not
scored in this seeded-gradient battery and enters the comparison only through the matched-stand
trajectory, so the Bakuzis pass is a statement about FVS-ACD's seeded-gradient behavior rather than a
five-way ranking.

Disclosed ingrowth limit. Observed MagPlot recruitment, tree-id matched across remeasurements, is 39.8
stems ha⁻¹ yr⁻¹ in New Brunswick and 19.7 in Quebec. The shipped expected-value ingrowth hurdle predicts
17.9 and 11.7 stems ha⁻¹ yr⁻¹, about 45 percent of observed in New Brunswick and 59 percent in Quebec.
Recruitment responds in the correct direction to density and management (planted and PCT stands, which
carry lower residual density, recruit more than unmanaged), and the expected-value hurdle lifted
recruitment well off the near-zero floor of the classic 2018 too-infrequent FVS-ACD problem, but a
residual under-prediction of the absolute level remains. This is neither the 2018 near-zero failure nor
an inflated recruitment; it is a real, moderate under-prediction, disclosed as a limit and a target for
the v13 ingrowth refit. It does not change the shipped version and does not touch the managed-cell
scorecard, which is a volume and basal-area result on the tag threshold.

Pooled parity was tested and deferred. A top-height anchor-level correction was tested as a reach for
pooled parity with OSM and deferred to v13.0. In the shipped config a top-height over-prediction of about
+4 percent only partly offsets a basal-area under-prediction of about -10 percent, so FVS-ACD total
volume sits modestly under observed on the unmanaged core, about -4 percent, rather than near zero.
Correcting top height alone removes the offsetting positive term and drives total volume further below
observed rather than toward zero, widening rather than closing the pooled mean absolute bias gap to OSM.
True parity therefore needs a joint re-anchor of dominant height and basal area together, recorded as the
v13.0 domain-plus-increment refit. The gated lever exists in the source (neutral factor reproduces
v12.10.1) but is not adopted for the operational version.

### 10.4 Planned v13

The v13 program addresses the disclosed limits above rather than the operational cell v12.10.1 already
wins. It moves from gated levers on fixed equations to refitted, site-driven, region-and-composition-aware
component equations with uncertainty, each step gated by the same multi-dimensional scorecard against the
prior version and OSM. The program is planned in four releases and none is gated as of this writing, so
nothing below is a result. It is the roadmap, not a claim.

The first release, v13.0, is a joint dominant-height and basal-area re-anchor. The model is masked to its
calibrated Acadian domain and dominant height and the increment are re-anchored together on the expanded
remeasurement data, so the top-height over-prediction and the basal-area under-prediction are corrected in
one step rather than left to partly offset each other. This addresses the partial error cancellation that
currently leaves total volume modestly under observed on the unmanaged core (section 10.3), which the
one-sided top-height lever tested this cycle showed cannot be corrected alone without driving volume
further negative.

The second release, v13.1, is a Bayesian hierarchical refit of mortality and ingrowth with region,
ecoregion, and forest-type random effects and the brms maximum-SDI posterior as the self-thinning asymptote.
Fitting the two components as a system with shared random effects estimates directly the regional and
composition structure now carried by the gated SDImax multiplier and the two-segment relative-density knob,
so the growing and mature tails become separable by construction, and it targets the disclosed ingrowth
limit (section 10.3) by matching observed recruitment (about 40 stems ha⁻¹ yr⁻¹ in New Brunswick, 20 in
Quebec) rather than under-predicting it. The hierarchical fits carry parameter and residual uncertainty into
prediction intervals, a scorecard dimension v12 does not satisfy.

The third release, v13.2, carries management as a growth-scale release estimated per tree, so the additive
stand-level release of v12.10.1 (section 10.3) is reproduced through the full engine by a fitted per-tree
amplitude rather than a post-hoc net release applied at the stand level.

The fourth release, v13.3, adds a climate-scenario mode driven by the current and future site-productivity
surfaces, kept separate from the validated base so that projections can be run under alternative climate
normals without ever benchmarking on a projected surface.

Until v13 is gated, v12.10.1 is the recommended operational version for inventory projection, with v12.7.1
retained for long-horizon carbon and old-growth work on the specific hardwood population where the v12.9.x
flat multiplier under-shoots the realistic plateau.

## 11. Literature Cited

[POPULATE with full references: Loo and Ives 2003; Weiskittel et al. 2011, 2012, 2013; Weiskittel and
Li 2012; Weiskittel and Kuehne 2019; Rijal et al. 2012a,b; Russell and Weiskittel 2011; Russell et
al. 2014; Kuehne et al. 2016, 2022; Li et al. 2011, 2012; Chen et al. (in prep., 2023); Cen et al.
2018; Castle et al. 2018; Jiang et al. 2014; Leary 1997 (Bakuzis); Dixon 2002 (Essential FVS).]

## 12. Appendices

Appendices A and B below are populated directly from the AcadianGY 12.9.0 source
(`scripts/AcadianGY_12.9.0.r`), extracted programmatically from the working parameter tables so the
values match the running model exactly. Appendix C (keyword reference) and Appendix D (validation
tables and figures) are not yet populated: C needs team-written usage documentation analogous to the
Essential FVS keyword reference (Dixon 2002), and D should pull the final tables and figures directly
from the companion benchmarking report (`FVS-ACD_12.9_benchmark_report.md`) once that report is
finalized, rather than duplicating numbers here. Formatting note: several Appendix B tables have 9 to
12 columns and render narrow in a portrait Word layout (see rendered docx); the final typeset GTR
should set these in landscape orientation or a smaller table font rather than leaving them
word-wrapped as in this draft.

## Appendix A. Species Code and Attribute Table

Alpha species codes as parameterized in AcadianGY 12.9.0 (`sp.attr`), with common and scientific names, FIA species code, PLANTS symbol, type (HW = hardwood, SW = softwood), specific gravity (`sg`), green wood density (`wd`, g per cm3), and shade, drought, and waterlog tolerance scores (0 to 5 scale, internal Acadian model compilation). `sp.grp.ingrowth` is the crown, ingrowth, and background-mortality parameter group the species maps to in Appendix B. 37 rows total: 35 distinct named species plus the OH (other hardwood) and OS (other softwood) composite groups, and a final `99` fallback row used when an input species code matches none of the above. RN and PC are retained aliases, not distinct species: RN is the FVS-NE alpha code for red pine (identical parameters to RP), and PC and PR are both carried as pin cherry with identical parameters, an inherited duplicate kept in the source table for input compatibility.

| Code | Common name | Scientific name | FIA code | PLANTS | Type | sg | wd | Shade | Drought | Waterlog | sp.grp.ingrowth |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AB | American beech | Fagus grandifolia | 531 | FAGR | HW | 0.64 | 0.56 | 4.75 | 1.5 | 1.5 | AB |
| AS | Ash (unspecified) | Fraxinus spp. | 540 | FRAXI | HW | 0.57 | 0.51 | 2.84 | 2.74 | 3.02 | OH |
| BA | Black ash | Fraxinus nigra | 543 | FRNI | HW | 0.5 | 0.45 | 2.96 | 2 | 3.5 | OH |
| BC | Black cherry | Prunus serotina | 762 | PRSE2 | HW | 0.5 | 0.47 | 2.46 | 3.02 | 1.06 | OH |
| BF | Balsam fir | Abies balsamea | 12 | ABBA | SW | 0.35 | 0.33 | 5.01 | 1 | 2 | BF |
| BP | Balsam poplar | Populus balsamifera | 741 | POBA2 | HW | 0.34 | 0.31 | 1.27 | 1.77 | 2.63 | OH |
| BS | Black spruce | Picea mariana | 95 | PIMA | SW | 0.46 | 0.38 | 4.08 | 2 | 2 | SPR |
| BT | Bigtooth aspen | Populus grandidentata | 743 | POGR4 | HW | 0.39 | 0.36 | 1.21 | 2.5 | 2 | OH |
| EC | Eastern cottonwood | Populus deltoides | 742 | PODE3 | HW | 0.4 | 0.37 | 1.76 | 1.57 | 3.03 | OH |
| EH | Eastern hemlock | Tsuga canadensis | 261 | TSCA | SW | 0.4 | 0.38 | 4.83 | 1 | 1.25 | OS |
| GA | Green ash | Fraxinus pennsylvanica | 544 | FRPE | HW | 0.56 | 0.53 | 3.11 | 3.85 | 2.98 | OH |
| GB | Gray birch | Betula populifolia | 379 | BEPO | HW | 0.48 | 0.45 | 1.5 | 2.34 | 1 | BCH |
| HH | Eastern hophornbeam | Ostrya virginiana | 701 | OSVI | HW | 0.78 | 0.63 | 4.58 | 3.25 | 1.07 | OH |
| JP | Jack pine | Pinus banksiana | 105 | PIBA2 | SW | 0.43 | 0.4 | 1.36 | 4 | 1 | OS |
| NS | Norway spruce | Picea abies | 91 | PIAB | SW | 0.43 | 0.3702 | 4.45 | 1.75 | 1.22 | OS |
| OH | Other hardwood (group) | n/a (composite group) | 998 | n/a | HW | 0.5121 | 0 | 2.29 | 0 | 0 | OH |
| OS | Other softwood (group) | n/a (composite group) | 298 | n/a | SW | 0.445 | 0 | 2.27 | 0 | 0 | OS |
| PB | Paper birch | Betula papyrifera | 375 | BEPA | HW | 0.55 | 0.48 | 1.54 | 2.02 | 1.25 | BCH |
| PC | Pin cherry [alias of PR] | Prunus pensylvanica | 761 | PRPE2 | HW | 0.38 | 0.36 | 2.26 | 0 | 0 | OH |
| PR | Pin cherry | Prunus pensylvanica | 761 | PRPE2 | HW | 0.38 | 0.36 | 2.26 | 0 | 0 | OH |
| QA | Quaking aspen | Populus tremuloides | 746 | POTR5 | HW | 0.38 | 0.35 | 1.21 | 1.77 | 1.77 | QA |
| RB | River birch | Betula nigra | 373 | BENI | HW | 0.62 | 0.49 | 1.45 | 1.53 | 2.85 | BCH |
| RM | Red maple | Acer rubrum | 316 | ACRU | HW | 0.54 | 0.49 | 3.44 | 1.84 | 3.08 | RM |
| RP | Red pine | Pinus resinosa | 125 | PIRE | SW | 0.46 | 0.41 | 1.89 | 3 | 1 | OS |
| RN | Red pine [FVS-NE alias of RP] | Pinus resinosa | 125 | PIRE | SW | 0.46 | 0.41 | 1.89 | 3 | 1 | OS |
| RO | Northern red oak | Quercus rubra | 833 | QURU | HW | 0.63 | 0.56 | 2.75 | 2.88 | 1.12 | OH |
| RS | Red spruce | Picea rubens | 97 | PIRU | SW | 0.4 | 0.37 | 4.39 | 2.5 | 2 | SPR |
| SB | Sweet birch | Betula lenta | 372 | BELE | HW | 0.65 | 0.6 | 2.58 | 3 | 1 | BCH |
| SM | Sugar maple | Acer saccharum | 318 | ACSA3 | HW | 0.63 | 0.56 | 4.76 | 2.25 | 1.09 | SM |
| ST | Striped maple | Acer pensylvanicum | 315 | ACPE | HW | 0.46 | 0.44 | 3.56 | 2 | 1 | OH |
| TA | Tamarack (eastern larch) | Larix laricina | 71 | LALA | SW | 0.53 | 0.49 | 0.98 | 2 | 3 | OS |
| WA | White ash | Fraxinus americana | 541 | FRAM2 | HW | 0.6 | 0.55 | 2.46 | 2.38 | 2.59 | OH |
| WC | Northern white cedar | Thuja occidentalis | 241 | THOC2 | SW | 0.31 | 0.29 | 3.45 | 2.71 | 1.46 | WC |
| WP | Eastern white pine | Pinus strobus | 129 | PIST | SW | 0.35 | 0.34 | 3.21 | 2.29 | 1.03 | WP |
| WS | White spruce | Picea glauca | 94 | PIGL | SW | 0.4 | 0.33 | 4.15 | 2.88 | 1.02 | SPR |
| YB | Yellow birch | Betula alleghaniensis | 371 | BEAL2 | HW | 0.62 | 0.55 | 3.17 | 3 | 2 | BCH |
| 99 | Other (unmatched-species fallback) | n/a | n/a | n/a | HW | 0.3 | 0.3 | 3 | 0 | 0 | OH |

Specific gravity and green wood density source Miles and Smith (2009), USDA FS-NRS-38, as compiled in the Acadian parameter set.


### A.1 sp.grp.ingrowth groups

| Group | Description |
|---|---|
| AB | American beech group |
| BF | Balsam fir |
| BCH | Birch group (paper, gray, river, sweet, yellow) |
| OH | Other hardwood (composite) |
| OS | Other softwood (composite) |
| QA | Quaking aspen |
| RM | Red maple |
| SM | Sugar maple |
| SPR | Spruce group (black, red, white) |
| WC | Northern white cedar |
| WP | Eastern white pine |

## Appendix B. Component Parameter Tables

All tables below are extracted directly from the AcadianGY 12.9.0 R source (`scripts/AcadianGY_12.9.0.r`) and correspond one-to-one with the working parameter objects the model uses at runtime (`sp.attr`, `mcw.spp`, `ht.pred.spp`, etc., named in each subsection). Species-level diameter increment and height increment random effects (section 4.6, 4.7) are not reproduced here; the fixed-effect coefficients are given in the main text and the full species random-effect tables are published in Kuehne et al. (2022) Tables S3 and S5.


### B.1 Height-diameter species parameters (section 4.1, `ht.pred.spp`)

Species random-effect terms c0.spp and c3.spp added to the fixed c0 and c3 in the total height equation (Rijal et al. 2012a); nomatch defaults to OH. Fixed parameters: c0 = 12.44847305, c1 = 0.801705832, c2 = 0.043617034, c3 = 1.048674338, c4 = 0.011483716, c5 = -0.007550999.

| Code | Common name | c0.spp | c3.spp |
|---|---|---|---|
| AB | American beech | -1.633 | -0.1238 |
| AE | American elm | -0.692 | 0.03461 |
| AH | American hornbeam | -5.98 | -0.03278 |
| AI | Ailanthus (tree-of-heaven) | -6.45 | -0.0984 |
| AP | Apple spp. | -12.07 | -0.476 |
| AS | Ash (unspecified) | 6.698 | -0.1253 |
| BA | Black ash | -1.617 | -0.1416 |
| BC | Black cherry | -4.527 | -0.1726 |
| BE | Boxelder | -1.606 | -0.4246 |
| BF | Balsam fir | 1.775 | 0.1572 |
| BL | Black willow | -9.828 | -0.2926 |
| BN | Butternut | 0.8612 | -0.1032 |
| BO | Black oak | 1.17 | -0.04312 |
| BP | Balsam poplar | 2.522 | -0.06336 |
| BR | Bur oak | 5.443 | 0.3544 |
| BS | Black spruce | 3.886 | 0.1887 |
| BT | Bigtooth aspen | 5.283 | -0.06706 |
| BW | American basswood | 2.525 | 0.1539 |
| EC | Eastern cottonwood | 7.088 | 0.1821 |
| EH | Eastern hemlock | 0.06435 | 0.2607 |
| EL | Elm spp. (other) | -0.4602 | 0.1942 |
| GA | Green ash | -1.473 | -0.07439 |
| GB | Gray birch | -1.039 | -0.2387 |
| HH | Eastern hophornbeam | -2.454 | -0.1764 |
| HK | Hackberry | -0.1392 | -0.1071 |
| HT | Hackberry/hickory (unresolved short code) | -0.4984 | 0.0005085 |
| JP | Jack pine | 12.2 | 0.5071 |
| NC | Non-commercial hardwood / northern white cedar fallback (context-dependent) | -0.1548 | 0.05067 |
| NS | Norway spruce | 10.76 | 0.7615 |
| OH | Other hardwood (group) | -0.1523 | -0.07739 |
| OP | Other pine species | -1.252 | 0.197 |
| OS | Other softwood (group) | 6.644 | 0.155 |
| PB | Paper birch | 2.856 | -0.05313 |
| PI | Other spruce species | 6.119 | 0.3962 |
| PL | Pin oak (short-code variant, unresolved) | -12.58 | -0.3544 |
| PP | Pitch pine | -2.035 | 0.02845 |
| PR | Pin cherry | -5.279 | -0.2767 |
| PY | Swamp cottonwood | 2.4 | -0.03028 |
| QA | Quaking aspen | 5.285 | -0.01669 |
| RC | Eastern redcedar | -13.36 | -0.365 |
| RL | Slippery elm | -13.46 | -0.3733 |
| RM | Red maple | 1.134 | -0.1249 |
| RN | Red pine [FVS-NE alias of RP] | 2.354 | 0.4332 |
| RO | Northern red oak | 0.5672 | 5.492e-05 |
| RS | Red spruce | 3.289 | 0.1978 |
| SB | Sweet birch | 5.059 | 0.2633 |
| SC | Scotch pine (short-code variant of SP) | -1.777 | 0.273 |
| SE | Sourwood (unresolved short code, context sweetgum/sourwood group) | -1.204 | -0.2175 |
| SH | Shagbark hickory | 3.424 | 0.008524 |
| SM | Sugar maple | 1.831 | -0.1509 |
| SO | Scarlet oak | -0.3376 | 0.002666 |
| ST | Striped maple | -4.215 | -0.1585 |
| SV | Silver maple | -1.668 | -0.1804 |
| SW | Swamp white oak (short-code variant) | 1.308 | 0.03166 |
| TA | Tamarack (eastern larch) | 3.039 | -0.07014 |
| WA | White ash | 1.586 | -0.1526 |
| WC | Northern white cedar | -2.638 | 0.1571 |
| WO | White oak | -0.1796 | 0.05001 |
| WP | Eastern white pine | 1.892 | 0.2179 |
| WS | White spruce | 2.831 | 0.2849 |
| YB | Yellow birch | -1.135 | -0.1796 |

### B.2 Height-to-crown-base species parameters (section 4.3, `hcb.pred.spp`)

Species random-effect term a0.spp added to the fixed intercept in the HCB equation (Rijal et al. 2012b, refit with species random effect per Weiskittel et al. 2013); nomatch defaults to OH. Fixed parameters: a0 = 0.29070, a1 = 0.00636, a2 = -0.02288, a3 = 0.08232, a4 = -0.03086, a5 = -0.01701. The crown-recession equation (dHCB, Russell et al. 2014) uses the same fixed parameters for all species (no species-specific table in the source); shade tolerance from Appendix A enters the shade term directly.

| Code | Common name | a0.spp |
|---|---|---|
| AB | American beech | -0.2184 |
| AI | Ailanthus (tree-of-heaven) | 0.08171 |
| AP | Apple spp. | 0.1775 |
| BA | Black ash | 0.1127 |
| BC | Black cherry | -0.1988 |
| BF | Balsam fir | 0.09359 |
| BP | Balsam poplar | -0.1367 |
| BR | Bur oak | 0.0156 |
| BS | Black spruce | -0.2278 |
| BT | Bigtooth aspen | 0.01004 |
| EC | Eastern cottonwood | 0.5073 |
| EH | Eastern hemlock | 0.4039 |
| GB | Gray birch | -0.1816 |
| HK | Hackberry | 0.1146 |
| JP | Jack pine | -0.2708 |
| NC | Non-commercial hardwood / northern white cedar fallback (context-dependent) | -0.2051 |
| NS | Norway spruce | 0.9556 |
| OH | Other hardwood (group) | -0.04289 |
| OP | Other pine species | -0.718 |
| PB | Paper birch | -0.1809 |
| PI | Other spruce species | 0.5486 |
| PR | Pin cherry | -0.2709 |
| QA | Quaking aspen | 0.06083 |
| RM | Red maple | -0.2025 |
| RN | Red pine [FVS-NE alias of RP] | -0.1505 |
| RO | Northern red oak | -0.3702 |
| RS | Red spruce | -0.1213 |
| SC | Scotch pine (short-code variant of SP) | 0.2442 |
| SE | Sourwood (unresolved short code, context sweetgum/sourwood group) | 0.243 |
| SM | Sugar maple | -0.1638 |
| TA | Tamarack (eastern larch) | -0.304 |
| WA | White ash | -0.1483 |
| WC | Northern white cedar | 0.4196 |
| WO | White oak | 0.1672 |
| WP | Eastern white pine | -0.1467 |
| WS | White spruce | 0.1003 |
| YB | Yellow birch | 0.003235 |

### B.3 Crown width species parameters (section 4.4, `mcw.spp`, `lcw.spp`)

Maximum crown width mcw = a1 * DBH^a2 (open-grown, 99th-quantile) and largest crown width lcw = mcw / (b1 * DBH^b2), Russell and Weiskittel (2011), 15 species plus NC, OH, OS, and a `99` fallback. RB shares BF, GB, and RO's grouped coefficients where noted; nomatch defaults to `99`.

| Code | Common name | a1 (mcw) | a2 (mcw) | b1 (lcw) | b2 (lcw) |
|---|---|---|---|---|---|
| BF | Balsam fir | 1.37 | 0.572 | 1.49 | 0.105 |
| BS | Black spruce | 0.535 | 0.742 | 1 | 0.174 |
| EH | Eastern hemlock | 2.44 | 0.408 | 1.9 | -0.057 |
| WP | Eastern white pine | 1.24 | 0.585 | 1 | 0.147 |
| NC | Non-commercial hardwood / northern white cedar fallback (context-dependent) | 1.63 | 0.436 | 2.19 | -0.08 |
| RS | Red spruce | 1.8 | 0.461 | 4.33 | -0.264 |
| WS | White spruce | 1.5 | 0.496 | 2.09 | -0.069 |
| AB | American beech | 2.93 | 0.434 | 1 | 0.194 |
| GB | Gray birch | 2.24 | 0.382 | 3.1 | -0.214 |
| RB | River birch | 2.24 | 0.382 | 3.1 | -0.214 |
| RO | Northern red oak | 4.08 | 0.31 | 4.1 | -0.272 |
| PB | Paper birch | 1.48 | 0.623 | 2.1 | -0.035 |
| QA | Quaking aspen | 1.31 | 0.586 | 2.65 | 0.157 |
| RM | Red maple | 2.17 | 0.491 | 2.63 | -0.132 |
| SM | Sugar maple | 3.31 | 0.356 | 1 | 0.161 |
| YB | Yellow birch | 4.04 | 0.308 | 4.23 | -0.264 |
| OH | Other hardwood (group) | 4.04 | 0.308 | 2.65 | 0.157 |
| OS | Other softwood (group) | 1.597 | 0.514 | 2.328 | 0.02784 |
| 99 | Other (unmatched-species fallback) | 2.243 | 0.4627 | 2.793 | -0.09011 |

### B.4 Bark ratio / DOB-to-DIB species parameters (section 4.2, `bark.ratio.spp`)

Weiskittel and Li (2012). Where pcnt.bark > 0, DIB = DOB * (1 - pcnt.bark/100) (fixed percent-bark species); otherwise DIB = b0 * DOB^b1.

| Code | Common name | pcnt.bark | b0 | b1 |
|---|---|---|---|---|
| AB | American beech | 7 | 1 | 1 |
| BC | Black cherry | 10 | 1 | 1 |
| BF | Balsam fir | 0 | 0.878 | 1.025 |
| BP | Balsam poplar | 0 | 0.8737 | 1.012 |
| BA | Black ash | 0 | 0.8499 | 1.041 |
| BS | Black spruce | 0 | 0.871 | 1.026 |
| BT | Bigtooth aspen | 15 | 1 | 1 |
| EH | Eastern hemlock | 0 | 0.8916 | 1.012 |
| GA | Green ash | 13 | 1 | 1 |
| GB | Gray birch | 12 | 1 | 1 |
| JP | Jack pine | 0 | 0.916 | 1.01 |
| NS | Norway spruce | 0 | 0.8558 | 1.036 |
| PB | Paper birch | 0 | 0.8969 | 1.018 |
| QA | Quaking aspen | 0 | 0.8449 | 1.033 |
| RM | Red maple | 0 | 0.9214 | 1.012 |
| RO | Northern red oak | 11 | 1 | 1 |
| RP | Red pine | 0 | 0.928 | 0.999 |
| RS | Red spruce | 0 | 0.864 | 1.029 |
| SB | Sweet birch | 12 | 1 | 1 |
| SM | Sugar maple | 0 | 0.9383 | 1.006 |
| TL | Tamarack (alias of TA in taper table) | 0 | 1.511 | 0.8134 |
| TA | Tamarack (eastern larch) | 0 | 1.511 | 0.8134 |
| WA | White ash | 0 | 0.8834 | 1.019 |
| WC | Northern white cedar | 0 | 0.7797 | 1.057 |
| NC | Non-commercial hardwood / northern white cedar fallback (context-dependent) | 0 | 0.7797 | 1.057 |
| WP | Eastern white pine | 0 | 0.926 | 1 |
| WS | White spruce | 0 | 0.886 | 1.022 |
| YB | Yellow birch | 0 | 0.8688 | 1.028 |
| OH | Other hardwood (group) | 0 | 0.8923 | 1.019 |
| OS | Other softwood (group) | 0 | 0.8873 | 1.019 |
| 99 | Other (unmatched-species fallback) | 0 | 0.8898 | 1.019 |

### B.5 Tree-level background mortality species parameters (section 5, `tree.mort.spp`)

Weiskittel et al. (2012). Tree survival is logistic in DBH and DBH^2 (b0, b1, b2); d.jump, scale, and shape parameterize the associated Weibull-form diameter-jump term. This table is broader than Appendix A (48 rows) because several species collapse to shared coefficient sets across related taxa (for example AH, BE, NM, SH, SV all share the generic hardwood-group coefficients).

| Code | Common name | b0 | b1 | b2 | d.jump | scale | shape |
|---|---|---|---|---|---|---|---|
| AB | American beech | 2.153 | -0.02698 | 0.0002203 | 41 | 20 | 4.5 |
| AE | American elm | 2.948 | -0.1018 | 0.001828 | 22.5 | 40 | 2 |
| AH | American hornbeam | 4.552 | -0.4627 | 0.0126 | 12 | 15 | 4.5 |
| AP | Apple spp. | 5.643 | -0.4645 | 0.01327 | 16 | 10.6 | 4.1 |
| BA | Black ash | 1.718 | 0.0393 | -0.002351 | 39 | 37 | 4.25 |
| BC | Black cherry | 4.863 | -0.3696 | 0.01098 | 9.2 | 31 | 3.63 |
| BE | Boxelder | 4.552 | -0.2313 | 0.0126 | 14 | 20 | 4.5 |
| BF | Balsam fir | 2.574 | -0.08519 | 0.001597 | 53 | 40.6 | 1.51 |
| BL | Black willow | -3.518 | 0.5008 | -0.01144 | 10 | 10 | 2 |
| BN | Butternut | 9.614 | -0.8619 | 0.02159 | 15 | 27.5 | 1.5 |
| BO | Black oak | 2.74 | -0.04031 | 0.001485 | 40 | 40 | 2 |
| BP | Balsam poplar | 1.88 | -0.3915 | 0.0298 | 33 | 33.6 | 4.75 |
| BS | Black spruce | 1.957 | 0.05354 | -0.001038 | 34 | 22 | 3.75 |
| BT | Bigtooth aspen | 2.179 | -0.01254 | 0.000853 | 40 | 30 | 3 |
| BW | American basswood | -1.415 | 0.3205 | -0.002971 | 15 | 30 | 3 |
| CC | Choke cherry | 4.863 | -0.3696 | 0.01098 | 10 | 20 | 3.63 |
| EC | Eastern cottonwood | -0.4585 | 0.1993 | -0.002845 | 40.6 | 11 | 4.28 |
| EH | Eastern hemlock | 4.521 | -0.06704 | 0.001204 | 50 | 40 | 3.5 |
| GA | Green ash | 7.206 | -0.224 | 0.007037 | 34 | 39.6 | 3.41 |
| GB | Gray birch | 0.1923 | 0.1517 | -0.003927 | 16 | 8.2 | 3.83 |
| HH | Eastern hophornbeam | 2.967 | -0.101 | 0.007167 | 18 | 24 | 2 |
| JP | Jack pine | -0.4488 | 0.194 | -0.001954 | 30 | 20 | 3 |
| NM | Norway maple | 4.552 | -0.2313 | 0.0126 | 24 | 40 | 4.5 |
| NS | Norway spruce | 17.48 | -1.809 | 0.0617 | 15 | 35 | 2 |
| OH | Other hardwood (group) | 4.552 | -0.5205 | 0.0126 | 12 | 10 | 4.5 |
| PB | Paper birch | 2.586 | -0.05185 | 0.002185 | 26.4 | 41.2 | 1.88 |
| PP | Pitch pine | 12.16 | -1.048 | 0.02331 | 25.8 | 41.6 | 4.41 |
| PR | Pin cherry | -1.217 | 0.3211 | -0.009715 | 10 | 40 | 2 |
| QA | Quaking aspen | -0.4585 | 0.1993 | -0.002845 | 60.6 | 11 | 4.28 |
| RM | Red maple | 2.167 | 0.05573 | -0.001044 | 60.2 | 40.6 | 4.38 |
| RO | Northern red oak | 3.12 | -0.04129 | 0.002298 | 41 | 40.4 | 3.27 |
| RP | Red pine | 1.136 | 0.1436 | 0.001844 | 30 | 30 | 3 |
| RS | Red spruce | 2.042 | 0.04257 | -0.0004902 | 41 | 32 | 4.8 |
| SB | Sweet birch | 44.26 | -2.425 | 0.1388 | 22 | 35.6 | 4.57 |
| SH | Shagbark hickory | 4.552 | -0.2313 | 0.0126 | 15 | 10 | 4.5 |
| SM | Sugar maple | 2.707 | 0.008626 | 0.0007235 | 54.4 | 42 | 1.33 |
| SP | Shortleaf pine (context) / scotch pine (bark table context) | 5 | -0.3 | 0.01 | 20 | 40 | 3 |
| ST | Striped maple | 4.552 | -0.4627 | 0.0126 | 4.4 | 24.4 | 4.51 |
| SV | Silver maple | 4.552 | -0.2313 | 0.0126 | 24 | 40 | 4.5 |
| TA | Tamarack (eastern larch) | 1.427 | 0.08863 | -0.002123 | 30 | 33.6 | 4.5 |
| WA | White ash | 1.004 | 0.1654 | -0.0005815 | 21 | 40 | 4 |
| WC | Northern white cedar | 3.648 | -0.06067 | 0.0008508 | 40 | 45 | 5 |
| WL | Willow spp. | -3.518 | 0.5008 | -0.01144 | 10 | 10 | 2 |
| WO | White oak | -4.864 | 0.6251 | -0.006442 | 18 | 40 | 4 |
| WP | Eastern white pine | 3.338 | -0.02945 | 0.0009562 | 61.2 | 41.2 | 2.87 |
| WS | White spruce | 0.5438 | 0.1052 | 0.0006333 | 19 | 54 | 2 |
| YB | Yellow birch | 2.697 | -0.001251 | 0.0007521 | 48 | 60 | 2 |
| 99 | Other (unmatched-species fallback) | 2.697 | -0.001251 | 0.0007521 | 48 | 60 | 2 |

### B.6 Regional stand-mortality parameters (section 5, `stand.mort.prob.region`, `stand.mort.ba.region`)

Weiskittel et al. (2012), region-specific coefficients (ME, NB, NS, QC). Stand mortality probability: prob = exp(k)/(1+exp(k)), k = b0 + b1*BA + b2*BA^2 + b3*BAG + b4*QMD + b5*BA.BF + b6*BA.IH, evaluated against the region's `cut` threshold. Stand mortality basal area: BA.mort = (b0 + b1*pBA.bf + b2*pBA.ih) * BA^(b3 + b4*BAG); BF.mort = b5*BA.BF^b6 + b7*(QMD.BF/QMD).

Stand mortality probability:

| Region | b0 | b1 | b2 | b3 | b4 | b5 | b6 | cut |
|---|---|---|---|---|---|---|---|---|
| ME | 0.6907 | 0.1492 | -0.001856 | -2.557 | -0.05508 | 0.06415 | 0.04327 | 0.872 |
| NB | 0.6991 | 0.1251 | -0.001856 | -2.557 | -0.05508 | 0.06415 | 0.04327 | 0.7268 |
| NS | 0.2757 | 0.1499 | -0.001856 | -2.557 | -0.05508 | 0.06415 | 0.04327 | 0.9148 |
| QC | 1.047 | 0.1617 | -0.001856 | -2.557 | -0.05508 | 0.06415 | 0.04327 | 0.7352 |

Stand mortality basal area:

| Region | b0 | b1 | b2 | b3 | b4 | b5 | b6 | b7 |
|---|---|---|---|---|---|---|---|---|
| ME | 0.1858 | 0.2315 | 0.0202 | 0.5674 | -2.037 | 0.06815 | 0.3345 | 0.09951 |
| NB | 0.5988 | 0.2315 | 0.0202 | 0.1889 | -2.037 | 0.1461 | 0.3285 | 0.09951 |
| NS | 0.1302 | 0.2315 | 0.0202 | 0.5894 | -2.037 | 0.08678 | 0.2244 | 0.09951 |
| QC | 0.1068 | 0.2315 | 0.0202 | 0.681 | -2.037 | 0.01172 | 0.4941 | 0.09951 |

### B.7 Modifiers (section 8)

**Thinning.** Post-commercial-thinning diameter-increment modifier, Weiskittel, Hennigar, and Kershaw (2015) (the source code cites this reference; the main-text section 8 citation of Kuehne et al. 2016 for the same modifier should be reconciled against the code header before final publication). Defined only for BF and RS (all other species: modifier = 1). ddbh.thin.mod = 1 + exp(y0 + y1/((100*ba.perc.rmv*qmd.ratio)+0.01)) * y2^tst * y3^... (tst = years since thinning).

| Species | y0 | y1 | y2 | y3 |
|---|---|---|---|---|
| BF | -0.2566 | -22.7609 | 0.7745 | 1.0511 |
| RS | -0.5010 | -20.1147 | 0.8067 | 1.1905 |

**Spruce budworm** (Cen et al. 2018), region ME and NB only. Plot SBW mortality modifier region parameters:

| Region | b1 | b2 | b3 | b4 |
|---|---|---|---|---|
| ME | -2.638 | 0.0114 | -0.0076 | 0.0074 |
| NB | -3.089 | 0.0071 | -0.0037 | 0 |

Tree SBW survival modifier, region-species parameters (BF, BS, RS, WS by region):

| Region | Code | b1 | b2 | b3 | b4 | b5 | b6 | b7 | b8 |
|---|---|---|---|---|---|---|---|---|---|
| ME | BF | -6.521 | -0.4866 | -0.0355 | 0.0316 | 1.509 | -0.0175 | 0.0274 | 0.004 |
| ME | BS | -6.521 | -0.4866 | -0.1231 | 0.0316 | 1.509 | -0.0175 | 0.0274 | 0.0056 |
| ME | RS | -6.521 | -0.4866 | -0.1231 | 0.0316 | 1.509 | -0.0175 | 0.0274 | 0.0056 |
| ME | WS | -6.521 | -0.4866 | -0.1755 | 0.0316 | 1.509 | -0.0175 | 0.0274 | 0.0207 |
| NB | BF | -6.831 | 0 | -0.2285 | 0.2025 | 2.17 | 0 | 0 | 0.0029 |
| NB | BS | -6.831 | 0 | -0.2285 | 0.2025 | 2.081 | 0 | 0 | 0.0101 |
| NB | RS | -6.831 | 0 | -0.2285 | 0.2025 | 2.081 | 0 | 0 | 0.0101 |
| NB | WS | -6.831 | 0 | -0.2285 | 0.2025 | 1.58 | 0 | 0 | 0.0021 |

**Hardwood form and risk** (Castle et al. 2017/2018), four species (RO, SM, YB, RM) plus OH default (no modifier). Form prediction parameters (straight-tree merchantability, log-sweep, major-stem-type, and log-form probabilities):

| Code | stm.b0 | stm.b1 | stm.b2 | lsw.b0 | lsw.b1 | lsw.b2 | mst.b0 | mst.b2 | lf.b0 | lf.b1 | lf.b2 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RO | -0.9491 | 0.0174 | -0.2826 | -1.114 | -0.0322 | 0.791 | -0.411 | -0.5009 | -4.068 | 0.0322 | 0.1139 |
| SM | -0.9491 | 0.0174 | 0.7541 | -1.114 | -0.0322 | -0.2325 | -0.411 | -1.135 | -4.068 | 0.0322 | 0.6278 |
| YB | -0.9491 | 0.0174 | -0.0208 | -1.114 | -0.0322 | 0.298 | -0.411 | -0.7557 | -4.068 | 0.0322 | 1.068 |
| RM | -0.9491 | 0.0174 | 0 | -1.114 | -0.0322 | 0 | -0.411 | 0 | -4.068 | 0.0322 | 0 |
| OH | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Risk (defect/decay) prediction parameters:

| Code | hr.b0 | hr.b1 | hr.b2 | hr.b3 |
|---|---|---|---|---|
| RO | -0.6886 | -0.0001 | -0.0184 | -0.0393 |
| SM | -0.6886 | -0.0001 | -0.1513 | -0.0164 |
| YB | -0.6886 | -0.0001 | -0.9851 | 0.0196 |
| RM | -0.6886 | -0.0001 | 0 | 0 |
| OH | 0 | 0 | 0 | 0 |

Hardwood form/risk survival modifier species parameters (`tsurv.hw.spp`):

| Code | b0 | b1 |
|---|---|---|
| QA | -2.791 | 0.0791 |
| RM | -3.981 | 0.8343 |
| RO | -0.7937 | 0.8944 |
| YB | 5.253 | 0.1528 |
| PB | 0 | 0 |

### B.8 Ingrowth parameters (section 6)

Li et al. (2011), ten sp.grp.ingrowth groups. Composition (count) model:

| Group | b0 | b1 | b2 | b3 | b4 |
|---|---|---|---|---|---|
| BCH | -2.564 | 0.002 | 2.662 | -0.001 | -0.0127 |
| BF | -3.029 | 0.0027 | 2.778 | 0.0211 | 0.0221 |
| RM | -0.6566 | 0.0123 | 1.767 | -0.0421 | -0.0283 |
| SPR | -1.25 | -0.0132 | 2.047 | -0.0514 | 0.0351 |
| WP | -5.107 | -0.0117 | 3.882 | 0.0501 | 0.0726 |
| OH | -2.983 | -0.002 | 2.484 | 0.0673 | -0.0167 |
| OS | -4.718 | 0.007 | 3.227 | 0.1 | 0.0188 |
| AB | -2.983 | -0.002 | 2.484 | 0.0673 | -0.0167 |
| QA | -2.983 | -0.002 | 2.484 | 0.0673 | -0.0167 |
| SM | -2.983 | -0.002 | 2.484 | 0.0673 | -0.0167 |
| WC | -4.718 | 0.007 | 3.227 | 0.1 | 0.0188 |

Occurrence probability model parameters (two candidate model forms retained, GNLS and NLME; production default noted in `ops$ingrowth.model.type`):

| Model | a1 | a2 | a3 | a4 | a5 | a6 | a7 | b1 | b2 | b3 | b4 | b5 | b6 | b7 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GNLS | -0.2116 | -0.0255 | -0.1396 | -0.0054 | 0.0433 | 0.0409 | 0 | 3.898 | -0.0257 | -0.3668 | 0.0002 | 0.0216 | -0.0514 | 0 |
| NLME | -0.08217 | 0.1113 | -1.24 | -0.2319 | 0.03673 | -0.7745 | -0.1301 | 2.847 | -0.03114 | -0.2891 | 0.00335 | 0.2248 | -0.08223 | -0.03548 |

### B.9 Taper species parameters (section 7)

**Kozak variable-exponent taper** (Li et al. 2012, conifers; Weiskittel and Li 2012, hardwoods), separate outside-bark (ob) and inside-bark (ib) coefficient sets where both exist; nomatch defaults to ib/OS.

| Bark | Code | a0 | a1 | a2 | b1 | b2 | b3 | b4 | b5 | b6 | b7 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| ob | AB | 1.0694 | 0.9975 | -0.012828 | 0.3921 | -1.0546 | 0.77584 | 4.1035 | 0.1186 | -1.0807 | 0 |
| ob | BC | 0.98022 | 0.99008 | 0.021502 | 0.60928 | -0.54627 | 0.52219 | 1.6561 | 0.040879 | -0.30281 | 0 |
| ib | BF | 0.88075 | 1.0149 | 0.019588 | 0.41952 | -0.67233 | 0.5433 | 1.4818 | 0.064704 | -0.34685 | 0 |
| ob | BF | 0.87046 | 0.99815 | 0.058482 | 0.30254 | -0.60579 | 0.58886 | 0.88266 | 0.10328 | -0.57433 | 0 |
| ob | BP | 1.0036 | 0.74425 | 0.28764 | 0.6634 | -2.0048 | 0.7508 | 3.9248 | 0.027679 | -0.13093 | 0 |
| ob | BA | 1.0036 | 0.74425 | 0.28764 | 0.6634 | -2.0048 | 0.7508 | 3.9248 | 0.027679 | -0.13093 | 0 |
| ib | BS | 0.80473 | 1.008 | 0.056011 | 0.35534 | -0.4132 | 0.41527 | 1.1165 | 0.099017 | -0.40992 | 0.11395 |
| ob | BS | 0.89638 | 0.97916 | 0.070704 | 0.28821 | -0.30358 | 0.43523 | 0.28709 | 0.086104 | -0.40775 | 0.37111 |
| ob | BT | 1.0201 | 1.0055 | -0.011031 | 0.51045 | -1.3264 | 0.55687 | 7.2108 | 0.07115 | -0.57184 | 0 |
| ib | EH | 0.96024 | 1.0082 | -0.025168 | 0.82526 | 1.9625 | 0.41523 | -5.0616 | 0.0098395 | -0.095533 | 0 |
| ob | EH | 0.84641 | 0.98432 | 0.080752 | 0.44544 | -0.67147 | 0.50495 | 2.4894 | 0.12415 | -0.72295 | 0 |
| ob | GA | 1.0852 | 1.1862 | -0.22619 | 0.51988 | 1.4303 | -0.34945 | 3.1953 | 0.13917 | -0.29672 | 0 |
| ob | GB | 1.0264 | 0.88356 | 0.13075 | 0.61135 | -0.11419 | 0.28832 | 2.6574 | 0.059005 | -0.17513 | 0 |
| ib | JP | 0.93155 | 1.0082 | -0.0041774 | 0.4313 | -0.86367 | 0.5117 | 2.2325 | 0.059865 | -0.3319 | 0.039631 |
| ob | JP | 0.84248 | 0.9928 | 0.073943 | 0.37222 | -0.72323 | 0.45343 | 1.3375 | 0.073373 | -0.31053 | 0.3964 |
| ib | NS | 0.93088 | 0.97361 | 0.035229 | 0.65078 | -0.30356 | 0.37833 | 1.1882 | 0.031116 | -0.031728 | 0 |
| ob | NS | 0.95095 | 0.99162 | 0.035718 | 0.50748 | -0.44047 | 0.40586 | 1.285 | 0.014396 | -0.078589 | 0.16973 |
| ib | PB | 0.71612 | 0.98112 | 0.13825 | 0.47822 | 0.30915 | 0.32663 | -0.30206 | 0.085859 | -0.27866 | 0 |
| ob | PB | 0.71612 | 0.98112 | 0.13825 | 0.47822 | 0.30915 | 0.32663 | -0.30206 | 0.085859 | -0.27866 | 0 |
| ob | QA | 0.5587 | 0.90478 | 0.30751 | 0.71313 | -0.58835 | 0.4292 | 2.8516 | 0.038161 | -0.13426 | 0 |
| ib | RM | 0.74583 | 1.0092 | 0.089093 | 0.58616 | -0.86591 | 0.65392 | 3.0604 | 0.082762 | -0.6486 | 0 |
| ob | RM | 0.74583 | 1.0092 | 0.089093 | 0.58616 | -0.86591 | 0.65392 | 3.0604 | 0.082762 | -0.6486 | 0 |
| ob | RO | 1.1751 | 1.0225 | -0.069889 | 0.45057 | -0.90288 | 0.58125 | 3.6267 | 0.16561 | -1.1143 | 0 |
| ib | RP | 0.97179 | 1.0011 | -0.015979 | 0.51143 | -0.974 | 0.25844 | 4.7532 | 0.058462 | -0.12372 | 0 |
| ob | RP | 1.0647 | 0.9949 | -0.012383 | 0.45896 | -1.0458 | 0.36145 | 4.0005 | 0.054337 | -0.12803 | 0 |
| ib | RS | 0.89798 | 1.0058 | 0.016673 | 0.49501 | -0.63375 | 0.38363 | 1.4138 | 0.08867 | -0.29754 | 0.15192 |
| ob | RS | 0.88689 | 0.99543 | 0.054137 | 0.41116 | -0.65802 | 0.41821 | 1.0911 | 0.10238 | -0.40367 | 0.10484 |
| ob | SB | 0.84711 | 0.98754 | 0.076969 | 0.93226 | -0.95458 | 0.48554 | 3.0295 | 0.076761 | -0.2384 | 0 |
| ob | SM | 1.0517 | 0.9613 | 0.038604 | 0.85564 | -0.24972 | 0.41494 | 1.2548 | 0.0413 | -0.1135 | 0 |
| ob | TL | 0.76298 | 0.97932 | 0.12279 | 0.24594 | -0.5649 | 0.66679 | -0.072878 | 0.14365 | -0.79119 | 0 |
| ob | TA | 0.76298 | 0.97932 | 0.12279 | 0.24594 | -0.5649 | 0.66679 | -0.072878 | 0.14365 | -0.79119 | 0 |
| ob | WA | 0.85507 | 0.97689 | 0.077036 | 0.78191 | -0.79176 | 0.4767 | 3.5004 | 0.085904 | -0.48797 | 0 |
| ib | WC | 0.86119 | 0.98152 | 0.05682 | 0.40718 | -0.054826 | 0.47809 | -1.3251 | 0.15385 | -0.53688 | 0 |
| ib | NC | 0.86119 | 0.98152 | 0.05682 | 0.40718 | -0.054826 | 0.47809 | -1.3251 | 0.15385 | -0.53688 | 0 |
| ob | WC | 0.87698 | 0.97219 | 0.090503 | 0.31964 | -0.49578 | 0.54661 | -0.054012 | 0.13167 | -0.45477 | 0 |
| ob | NC | 0.87698 | 0.97219 | 0.090503 | 0.31964 | -0.49578 | 0.54661 | -0.054012 | 0.13167 | -0.45477 | 0 |
| ib | WP | 1.0488 | 1.0078 | -0.045954 | 0.38085 | -0.85956 | 0.34381 | 4.6084 | 0.11185 | -0.55232 | 0 |
| ob | WP | 0.96198 | 0.98598 | 0.033318 | 0.38342 | -0.75366 | 0.39253 | 3.4224 | 0.1006 | -0.48562 | 0 |
| ib | WS | 0.75826 | 0.98482 | 0.099562 | 0.36505 | -0.51501 | 0.55914 | 0.75846 | 0.070119 | -0.44928 | 0.0783 |
| ob | WS | 0.72506 | 0.99993 | 0.11891 | 0.28603 | -0.41705 | 0.58123 | -0.56275 | 0.10138 | -0.56377 | 0.096122 |
| ob | YB | 1.1264 | 0.94851 | 0.037132 | 0.76625 | -0.028148 | 0.2334 | 4.857 | 0.075318 | -0.20505 | 0 |
| ob | OH | 0.94721 | 0.97135 | 0.063182 | 0.63361 | -0.54916 | 0.43901 | 3.1876 | 0.079154 | -0.41278 | 0 |
| ob | OS | 0.88048 | 0.98853 | 0.066079 | 0.36555 | -0.60725 | 0.48683 | 1.2824 | 0.09412 | -0.44738 | 0 |
| ib | OS | 0.89648 | 1.0019 | 0.020707 | 0.39152 | -0.39564 | -0.011787 | 1.3351 | 0.076312 | -0.28699 | 0 |

**Westfall and Scott taper** (Westfall and Scott 2010), alternate taper system; nomatch defaults to `99` (all-species composite).

| Code | th1 | th2 | a1 | a2 | gm1 | gm2 | phi | lmd | bet1 | bet2 |
|---|---|---|---|---|---|---|---|---|---|---|
| SM | 6.579 | 0.0111 | 1.0682 | 1.1833 | 0.1031 | 0.2624 | 0.1516 | 1.1482 | 0.6637 | 3.0996 |
| YB | 7.5437 | 0.0103 | 0.9961 | 1.1042 | 0.1313 | 0.3539 | 0.2091 | 0.9478 | 0.5995 | 3.4205 |
| PB | 7.5437 | 0.0103 | 0.9961 | 1.1042 | 0.1313 | 0.3539 | 0.2091 | 0.9478 | 0.5995 | 3.4205 |
| GB | 7.5437 | 0.0103 | 0.9961 | 1.1042 | 0.1313 | 0.3539 | 0.2091 | 0.9478 | 0.5995 | 3.4205 |
| SB | 7.5437 | 0.0103 | 0.9961 | 1.1042 | 0.1313 | 0.3539 | 0.2091 | 0.9478 | 0.5995 | 3.4205 |
| RM | 7.5707 | 0.0105 | 1.5273 | 0.7684 | 0.0931 | 0.4223 | 0.1441 | 1.391 | 0.6453 | 4.0737 |
| GA | 3.3085 | 0.0276 | 1.2634 | 0.9088 | 0.1098 | 0.5198 | 0.184 | 1.7842 | 0.6719 | 5.1178 |
| WA | 3.3085 | 0.0276 | 1.2634 | 0.9088 | 0.1098 | 0.5198 | 0.184 | 1.7842 | 0.6719 | 5.1178 |
| BT | 3.3085 | 0.0276 | 1.2634 | 0.9088 | 0.1098 | 0.5198 | 0.184 | 1.7842 | 0.6719 | 5.1178 |
| QA | 3.3085 | 0.0276 | 1.2634 | 0.9088 | 0.1098 | 0.5198 | 0.184 | 1.7842 | 0.6719 | 5.1178 |
| BP | 3.3085 | 0.0276 | 1.2634 | 0.9088 | 0.1098 | 0.5198 | 0.184 | 1.7842 | 0.6719 | 5.1178 |
| AB | 8.9843 | 0.0107 | 0.7621 | 1.3734 | 0.0956 | 0.165 | 0.1924 | 1.2237 | 0.4626 | 1.0954 |
| RO | 12.834 | 0.0125 | 0.9038 | 1.095 | 0.0935 | 0.3971 | 0.2038 | 1.0457 | 0.5508 | 3.4681 |
| BC | 3.2042 | 0.0479 | 1.2507 | 0.8075 | 0.08 | 0.417 | 0.2227 | 2.7226 | 0.7065 | 4.6476 |
| BF | 5.3693 | 0.0171 | 1.4212 | 0.3003 | 0.089 | 0.6485 | 0.1916 | 1.8873 | 0.4764 | 2.6383 |
| RS | 6.8745 | 0.011 | 1.1241 | 0.4107 | 0.1376 | 0.4842 | 0.2038 | 1.2598 | 0.4986 | 2.7865 |
| BS | 6.8745 | 0.011 | 1.1241 | 0.4107 | 0.1376 | 0.4842 | 0.2038 | 1.2598 | 0.4986 | 2.7865 |
| WS | 6.8745 | 0.011 | 1.1241 | 0.4107 | 0.1376 | 0.4842 | 0.2038 | 1.2598 | 0.4986 | 2.7865 |
| WP | 7.1438 | 0.0123 | 0.8978 | 0.7872 | 0.0989 | 0.4985 | 0.2049 | 0.9247 | 0.5715 | 2.0482 |
| TA | 5.2913 | 0.0411 | 1.1291 | 0.6831 | 0.0745 | 0.5798 | 0.1896 | 1.5776 | 0.6616 | 6.0645 |
| NS | 5.2913 | 0.0411 | 1.1291 | 0.6831 | 0.0745 | 0.5798 | 0.1896 | 1.5776 | 0.6616 | 6.0645 |
| JP | 5.2913 | 0.0411 | 1.1291 | 0.6831 | 0.0745 | 0.5798 | 0.1896 | 1.5776 | 0.6616 | 6.0645 |
| WC | 5.4 | 0.0256 | 1.9295 | 0.8142 | 0.0943 | 0.9642 | 0.2761 | 1.8605 | 1.3432 | 1.3438 |
| RP | 7.6044 | 0.0148 | 1.2379 | 0.3304 | 0.0759 | 0.6611 | 0.3008 | 1.1569 | 0.5462 | 3.0627 |
| EH | 7.2442 | 0.0152 | 1.4008 | 0.8306 | 0.0856 | 0.4724 | 0.2011 | 1.5776 | 0.6616 | 6.0645 |
| OH | 9.0505 | 0.0241 | 1.298 | 0.7684 | 0.0684 | 0.4555 | 0.1769 | 1.6684 | 0.5408 | 4.1821 |
| OS | 6.4182 | 0.019586 | 1.3058 | 0.59379 | 0.093686 | 0.61553 | 0.22399 | 1.4626 | 0.68527 | 2.8423 |
| 99 | 7.115 | 0.016837 | 1.1484 | 0.85719 | 0.10123 | 0.46091 | 0.19561 | 1.3514 | 0.63404 | 3.3026 |

### B.10 Honer volume species parameters (section 7)

Legacy total-tree cubic-volume equation, retained for cross-checking against the taper-integrated and NSVB-emulator volumes; columns p1.ht through p3.d are carried in the source table but not used in the current volume calculation.

| Code | Common name | a | b | b2 |
|---|---|---|---|---|
| WP | Eastern white pine | 0.691 | 363.7 | 0.184 |
| RP | Red pine | 0.71 | 355.6 | 0.184 |
| JP | Jack pine | 0.897 | 348.5 | 0.184 |
| TA | Tamarack (eastern larch) | 0.897 | 348.5 | 0.184 |
| LP | Loblolly pine (Honer volume table only, out of Acadian range) | 0.694 | 343.9 | 0.184 |
| BS | Black spruce | 1.588 | 333.4 | 0.184 |
| RS | Red spruce | 1.226 | 315.8 | 0.184 |
| WS | White spruce | 1.44 | 342.2 | 0.184 |
| BF | Balsam fir | 2.139 | 301.6 | 0.184 |
| NC | Non-commercial hardwood / northern white cedar fallback (context-dependent) | 4.167 | 244.9 | 0.184 |
| WC | Northern white cedar | 4.167 | 244.9 | 0.184 |
| EH | Eastern hemlock | 1.112 | 350.1 | 0.184 |
| QA | Quaking aspen | -0.312 | 436.7 | 0.184 |
| BP | Balsam poplar | 0.42 | 394.6 | 0.184 |
| BT | Bigtooth aspen | 0.42 | 394.6 | 0.184 |
| PB | Paper birch | 2.222 | 300.4 | 0.184 |
| GB | Gray birch | 2.222 | 300.4 | 0.184 |
| SB | Sweet birch | 2.222 | 300.4 | 0.184 |
| YB | Yellow birch | 1.449 | 344.8 | 0.184 |
| RM | Red maple | 1.046 | 384 | 0.184 |
| SM | Sugar maple | 1.046 | 384 | 0.184 |
| BW | American basswood | 0.948 | 401.5 | 0.184 |
| AB | American beech | 0.959 | 334.8 | 0.184 |
| WA | White ash | 0.959 | 334.8 | 0.184 |
| BC | Black cherry | 0.033 | 393.3 | 0.184 |
| RO | Northern red oak | 1.512 | 336.5 | 0.184 |
| OH | Other hardwood (group) | 1.512 | 336.5 | 0.184 |
