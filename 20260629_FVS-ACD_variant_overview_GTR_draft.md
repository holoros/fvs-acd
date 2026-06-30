# Acadian (ACD) Variant Overview of the Forest Vegetation Simulator

**DRAFT variant overview / General Technical Report scaffold. 29 June 2026.**

*Structured after the USDA Forest Service Northeast (NE) Variant Overview (FVS Staff 2008, rev.
August 2023) so it can become the official FVS-ACD variant documentation. Equation content is drawn
from the Acadian GY Model Documentation (Weiskittel and team, 2025-05-20) and the AcadianGY 12.6.x
source. Sections marked [POPULATE] need the full parameter tables or team text before publication.
Plaintext math, no em dashes; this draft will be rendered to a formatted Word/PDF GTR.*

## Authors and Contributors

Aaron Weiskittel and the University of Maine Cooperative Forestry Research Unit (CFRU) developed the
Acadian growth-and-yield model. Ben Rice (Midgard Natural Resources) maintains the FVS-ACD
implementation and benchmarking. Component equations are credited to their authors throughout
(Kuehne, Russell, Rijal, Li, Chen, Castle, Cen, and others; see Literature Cited). This overview
documents the FVS-ACD variant as implemented in AcadianGY 12.6.x.

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
self-thinning (ops$use.sdimort) active, a standard density-frontier mortality that holds post-step SDI
at or below SDImax and improves the Bakuzis self-thinning slope (-1.08 to -1.24). On the full regional
set Maine basal area is over-predicted by about +5 percent, a modest residual. Two gated interim
correctors target it, off by default: a regional stand-mortality cut scale (ops$mort.cut.scale) and a
tree-level multiplier; sweeps show each saturates near +7 to +8 percent alone but the two are
complementary, and a mild combination removes most of the Maine residual. A size-dependent MORTCAL
corrector (ops$use.mortcal) is also available but trades stem-count accuracy. The principled
next-version fix is a regional refit of the 2012 stand-mortality coefficients; the interim correctors
bound rather than close the gap.

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

## 7. Volume and Taper

Stem taper: Kozak variable-exponent taper and Westfall and Scott (Li et al. 2012, Weiskittel and Li
2012). Bark thickness via DOBtoDIB. Merchantable volume and product specifications follow the FVS
volume framework; for value work, sawlog (International 1/4-inch board feet) and pulp (cords) are
split by species and size. [POPULATE: taper parameters and volume specification table.]

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

## 10. Operational version (12.7.0) and validation

The operational release is AcadianGY 12.7.0, which integrates this development cycle's refinements into
one file. The recommended configuration is: the Kuehne et al. (2022) diameter and height increment
equations (4.6, 4.7) as the growth base; the validated ESI as the site driver with the fitted
ESI-anchored dominant height (3.4, 4.1); expected-value ingrowth (6); and SDImax-ceiling self-thinning
(5). Every refinement is gated, and with the flags in their legacy position the build reproduces
12.5.0 bit for bit, so each is individually isolated and validated.

Refinements, in order of development:
1. ESI site input (12.6.0), drop-in through the site slot.
2. Site-independent SDImax (12.6.0), from the brms re-estimation.
3. SDImax-ceiling self-thinning (12.6.0), the principled density-frontier mortality.
4. Expected-value ingrowth (12.6.1), fixing the under-recruitment stem-count deficit.
5. ESI-anchored dominant height (12.7.0), fitted Chapman-Richards anchor (k 0.0039, p 0.726, base 50),
   which removes the Bakuzis height site-ordering inversions (25 to 0).
6. Gated interim correctors, off by default: a regional stand-mortality cut scale, a size-form diameter
   modifier (tested and not adopted, see below), and MORTCAL.

Validation, full regional remeasurement set (682 NB/NS/ME intervals, 5 to 15 years): all-region basal
area bias +1.4 percent, volume and value +1.5 percent; Maine +4.9 percent basal area and +7.6 percent
value, New Brunswick -1.7 and -3.3, Nova Scotia +3.0 and +2.3. The model is well calibrated overall,
with Maine the largest residual at about +5 percent basal area. Supporting analyses: the full Bakuzis
matrix (Eichhorn passes; self-thinning slope improved; site ordering fixed by the dominant-height
anchor), and a global sensitivity analysis (value dominated by the site variable; ingrowth drives
structure not value; self-thinning parameters globally minor).

Two findings bound the next development cycle. First, the diameter increment: the Kuehne (2022) base is
robust and nearly unbiased in the mean, with a residual size-form attenuation (over-predicts small
trees, under-predicts large, and under-predicts at high density). An interim size-form multiplier was
built and tested; it worsens projection bias in every region because increment compounds over the
horizon and the Maine residual is mortality-driven, so it is not adopted. A full diameter-increment
refit with a density term and attenuation-aware fitting, needing new data, is the eventual path.
Second, the long-horizon comparison against the Open Stand Model (OSM v2.26.1) on the same Seven
Islands stands: the two agree at the start (basal area 31.4 versus 31.9 m2/ha) and then diverge, with
FVS-ACD self-thinning (basal area 33 to 27 m2/ha by age 60) and OSM accumulating (32 to 42), a
35-percent gap by age 60. This is first-order model-form uncertainty with no observed truth at that
horizon, and it localizes to stand mortality, the component flagged for the regional coefficient refit.

## 11. Literature Cited

[POPULATE with full references: Loo and Ives 2003; Weiskittel et al. 2011, 2012, 2013; Weiskittel and
Li 2012; Weiskittel and Kuehne 2019; Rijal et al. 2012a,b; Russell and Weiskittel 2011; Russell et
al. 2014; Kuehne et al. 2016, 2022; Li et al. 2011, 2012; Chen et al. (in prep., 2023); Cen et al.
2018; Castle et al. 2018; Jiang et al. 2014; Leary 1997 (Bakuzis); Dixon 2002 (Essential FVS).]

## 12. Appendices

[POPULATE: A. Species code and attribute table. B. Component parameter tables (height, HCB, crown
width, diameter increment, height increment, stand BA increment, mortality by region, ingrowth,
taper). C. Keyword reference. D. Validation tables and figures from the benchmarking report.]
