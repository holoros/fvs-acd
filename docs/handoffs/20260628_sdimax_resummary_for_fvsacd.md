# Updating FVS-ACD max SDI from the brms estimates: resummary for northern New England

*28 June 2026. The Bakuzis assessment flagged a self-thinning slope that is too shallow and a
persistent stem-count under-prediction, and SDImax is the density ceiling that governs both. This
memo resummarizes the plot-level brms SDImax (metric) for the Acadian region (northern New England:
Maine, New Hampshire, Vermont; MA, CT, RI excluded) by ecoregion, FIA forest-type group, and site
index (CSI and ESI), and compares to the current AcadianGY SDImax. Plaintext math, no em dashes.*

## Data and method

The uploaded brms plot-level SDImax (brms.SDImax.1-27-24.csv, posterior mean and median per FIA
plot, metric SDI) was filtered to STATECD in {Maine 23, New Hampshire 33, Vermont 50}, trimmed to
50 to 3000, and joined to the FIA PLOT table (coordinates) and COND table (forest type), then
attributed with Level 3 ecoregion, ESI, legacy ClimateNA CSI, and 2030 CSI at the plot
coordinates. 5,385 plots. The median (robust to the long right tail) is reported.

## Overall

| metric | value |
|---|---|
| SDImax median | 955 |
| SDImax mean | 989 |
| p25 to p75 | 777 to 1172 |

## By FIA forest-type group (the meaningful axis)

| forest-type group | n | SDImax median | p25 | p75 |
|---|---|---|---|---|
| Pine | 454 | 1096 | 898 | 1339 |
| Spruce-fir | 1292 | 1057 | 844 | 1279 |
| Oak-pine | 153 | 1010 | 826 | 1218 |
| Aspen-birch | 402 | 1004 | 778 | 1190 |
| Oak-hickory | 222 | 930 | 768 | 1115 |
| Northern hardwood | 2426 | 896 | 747 | 1079 |
| Elm-ash-cottonwood | 103 | 750 | 618 | 1027 |

Forest type is where SDImax actually varies: the softwood types (pine, spruce-fir) sit near 1050
to 1100, northern hardwood near 896, and the wet elm-ash type near 750. A single SDImax for all
types is too high for hardwood stands and too low for softwood stands.

## By Level 3 ecoregion (modest variation)

| ecoregion | n | SDImax median |
|---|---|---|
| Northeastern Coastal Zone | 259 | 986 |
| Acadian Plains and Hills | 1730 | 964 |
| Northern Appalachian and Atlantic Maritime Highlands | 3245 | 952 |
| Eastern Great Lakes Lowlands | 36 | 793 |

Ecoregion adds only a modest second-order signal (about 950 to 990 across the three big Acadian
ecoregions), much smaller than the forest-type spread.

## The key result: SDImax does not depend on site index

The brms SDImax is essentially uncorrelated with site index: correlation with CSI is -0.02 and
with ESI is -0.08, and the median is flat across CSI and ESI quartiles (915 to 997). This matters
for the model form. The current AcadianGY SDImax (Weiskittel and Kuehne 2019) is

    SDImax = 475.21 - 1.5908*ba.perc.hw - 236.91*log(meansg) + 50.33*sqrt(dbh.range)
             + 13.52*spp.div + 0.0685*elev - 2.8537*sqrt(elev) + 222.78/csi

which includes a +222.78/csi term that lowers SDImax as the climate site index rises. The brms
data does not support a site-index dependence in SDImax. The term is small (about 16 SDI units at
CSI = 14), so it is not a large bias, but the principled move is to drop or shrink it: SDImax is a
function of species and structure, not of site.

## Comparison to the current function and recommendation

For a typical Acadian spruce-fir stand the current Weiskittel-Kuehne function returns roughly 1000
to 1100 metric SDI, which matches the brms spruce-fir median of 1057, so the overall level is
sound. The gains from the brms resummary are in stratification, not in the average:

1. Set FVS-ACD metric SDImax by forest-type group, using the brms medians: about 1096 for pine,
   1057 for spruce-fir, 1004 for aspen-birch, 1010 for oak-pine, 930 for oak-hickory, 896 for
   northern hardwood, 750 for elm-ash. This lets hardwood-dominated stands self-thin at a lower
   ceiling than softwood stands, which is exactly the direction the Bakuzis self-thinning flag and
   the stem-count under-prediction point. A single ceiling under-thins hardwood stands.
2. Optionally add a small ecoregion adjustment (about plus or minus 30 SDI across the three big
   Acadian ecoregions). Second order; can be deferred.
3. Drop or shrink the 222.78/csi site-index term in the SDImax function. The brms data show SDImax
   is independent of CSI and ESI (r near 0); SDImax should be driven by composition and structure.

This is a model-development change to the SDImax inputs, complementary to the MORTCAL growth-bias
fix. A forest-type-specific, site-independent SDImax is the most defensible update and is the
lever most likely to help the density and stem-count realism that MORTCAL alone does not fully
resolve.

## Caveats

- FIA's own SDIMAX_RMRS field is not populated for the Northeast (all missing in ME/NH/VT COND),
  so no FIA-internal SDImax cross-check was possible; the comparison is brms vs the AcadianGY
  function.
- This covers the United States Acadian region (northern New England). The Canadian Acadian
  (NB and Nova Scotia PSP, already present in the DBHout compilation) is not in the FIA-keyed brms
  file; a parallel SDImax estimate from the NB/NS PSP self-thinning frontier would extend the
  resummary across the full Acadian region and is a clean follow-up.

## Files

- Script: `scripts/sdimax_resummary.R`
- Tables: `results/sdimax/sdimax_by_fortype.csv`, `sdimax_by_ecoregion.csv`, `sdimax_by_ESIq.csv`
